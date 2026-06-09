import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

// GET - Fetch admin dashboard stats
export async function GET(request: NextRequest) {
  try {
    const supabase = createClient()

    // Get customer stats
    const { data: customers, count: customerCount } = await supabase
      .from('admin_customers')
      .select('status, created_at, total_spent', { count: 'exact' })

    // Get subscription stats
    const { data: subscriptions } = await supabase
      .from('admin_subscriptions')
      .select('status, price, billing_cycle, created_at')

    // Get license stats
    const { data: licenses } = await supabase
      .from('desktop_licenses')
      .select('status, created_at')

    // Get recent activity
    const { data: recentActivity } = await supabase
      .from('admin_activities')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(10)

    // Calculate stats
    const activeCustomers = customers?.filter(c => c.status === 'active').length || 0
    const activeSubs = subscriptions?.filter(s => s.status === 'active') || []
    const activeLicenses = licenses?.filter(l => l.status === 'active').length || 0

    // Calculate MRR
    const mrr = activeSubs.reduce((acc, s) => {
      return acc + (s.billing_cycle === 'monthly' ? s.price : s.price / 12)
    }, 0)

    // Calculate growth (last 30 days vs previous 30 days)
    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
    const sixtyDaysAgo = new Date()
    sixtyDaysAgo.setDate(sixtyDaysAgo.getDate() - 60)

    const newCustomersLast30 = customers?.filter(c => 
      new Date(c.created_at) >= thirtyDaysAgo
    ).length || 0

    const newCustomersPrevious30 = customers?.filter(c => 
      new Date(c.created_at) >= sixtyDaysAgo && new Date(c.created_at) < thirtyDaysAgo
    ).length || 0

    const customerGrowth = newCustomersPrevious30 > 0 
      ? ((newCustomersLast30 - newCustomersPrevious30) / newCustomersPrevious30) * 100 
      : newCustomersLast30 * 100

    // Total revenue
    const totalRevenue = customers?.reduce((acc, c) => acc + (c.total_spent || 0), 0) || 0

    // Subscription distribution
    const { data: plans } = await supabase
      .from('admin_subscriptions')
      .select('plan_name')
      .eq('status', 'active')

    const planCounts: Record<string, number> = {}
    plans?.forEach(p => {
      planCounts[p.plan_name] = (planCounts[p.plan_name] || 0) + 1
    })

    const totalActivePlans = Object.values(planCounts).reduce((a, b) => a + b, 0)
    const subscriptionDistribution = Object.entries(planCounts).map(([plan, count]) => ({
      plan,
      count,
      percentage: totalActivePlans > 0 ? Math.round((count / totalActivePlans) * 100) : 0
    }))

    return NextResponse.json({
      stats: {
        totalCustomers: customerCount || 0,
        activeCustomers,
        activeSubscriptions: activeSubs.length,
        activeLicenses,
        mrr: Math.round(mrr * 100) / 100,
        arr: Math.round(mrr * 12 * 100) / 100,
        totalRevenue: Math.round(totalRevenue * 100) / 100,
        customerGrowth: Math.round(customerGrowth * 10) / 10,
      },
      subscriptionDistribution,
      recentActivity: recentActivity?.map(a => ({
        id: a.id,
        type: a.action_type,
        action: a.action,
        resourceName: a.resource_name,
        time: a.created_at
      })) || []
    })
  } catch (error) {
    console.error('Error in GET /api/admin/stats:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
