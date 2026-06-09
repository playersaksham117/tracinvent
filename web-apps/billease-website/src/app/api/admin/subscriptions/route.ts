import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

// GET - Fetch all subscriptions with pagination and filters
export async function GET(request: NextRequest) {
  try {
    const supabase = createClient()
    const { searchParams } = new URL(request.url)
    
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '10')
    const search = searchParams.get('search') || ''
    const status = searchParams.get('status') || 'all'
    const plan = searchParams.get('plan') || 'all'

    const offset = (page - 1) * limit

    // Build query
    let query = supabase
      .from('admin_subscriptions')
      .select('*', { count: 'exact' })

    // Apply search filter
    if (search) {
      query = query.or(`customer_name.ilike.%${search}%,customer_email.ilike.%${search}%,company.ilike.%${search}%`)
    }

    // Apply status filter
    if (status !== 'all') {
      query = query.eq('status', status)
    }

    // Apply plan filter
    if (plan !== 'all') {
      query = query.eq('plan_name', plan)
    }

    // Apply sorting and pagination
    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1)

    const { data: subscriptions, error, count } = await query

    if (error) {
      console.error('Error fetching subscriptions:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    // Calculate MRR and stats
    const { data: allSubs } = await supabase
      .from('admin_subscriptions')
      .select('status, price, billing_cycle')

    const activeSubs = allSubs?.filter(s => s.status === 'active') || []
    const mrr = activeSubs.reduce((acc, s) => {
      return acc + (s.billing_cycle === 'monthly' ? s.price : s.price / 12)
    }, 0)

    const stats = {
      mrr: Math.round(mrr * 100) / 100,
      arr: Math.round(mrr * 12 * 100) / 100,
      active: allSubs?.filter(s => s.status === 'active').length || 0,
      trialing: allSubs?.filter(s => s.status === 'trialing').length || 0,
      past_due: allSubs?.filter(s => s.status === 'past_due').length || 0,
      canceled: allSubs?.filter(s => s.status === 'canceled').length || 0,
      total: allSubs?.length || 0
    }

    return NextResponse.json({
      subscriptions,
      stats,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit)
      }
    })
  } catch (error) {
    console.error('Error in GET /api/admin/subscriptions:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST - Create a new subscription
export async function POST(request: NextRequest) {
  try {
    const supabase = createClient()
    const body = await request.json()

    const startDate = new Date()
    let nextBillingDate = new Date()
    if (body.billing_cycle === 'monthly') {
      nextBillingDate.setMonth(nextBillingDate.getMonth() + 1)
    } else {
      nextBillingDate.setFullYear(nextBillingDate.getFullYear() + 1)
    }

    const { data: subscription, error } = await supabase
      .from('admin_subscriptions')
      .insert({
        customer_id: body.customer_id,
        customer_name: body.customer_name,
        customer_email: body.customer_email,
        company: body.company,
        plan_id: body.plan_id,
        plan_name: body.plan_name,
        price: body.price,
        billing_cycle: body.billing_cycle || 'monthly',
        status: body.status || 'active',
        start_date: startDate.toISOString(),
        next_billing_date: nextBillingDate.toISOString(),
        payment_method: body.payment_method,
        payment_method_last4: body.payment_method_last4,
        stripe_subscription_id: body.stripe_subscription_id,
        stripe_customer_id: body.stripe_customer_id,
        metadata: body.metadata || {}
      })
      .select()
      .single()

    if (error) {
      console.error('Error creating subscription:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    // Update customer subscription info
    if (body.customer_id) {
      await supabase
        .from('admin_customers')
        .update({
          subscription_id: subscription.id,
          subscription_plan: body.plan_name
        })
        .eq('id', body.customer_id)
    }

    // Log activity
    await supabase.from('admin_activities').insert({
      admin_id: body.admin_id,
      action_type: 'subscription',
      action: 'Created new subscription',
      resource_id: subscription.id,
      resource_name: `${body.customer_name} - ${body.plan_name}`,
      metadata: {}
    })

    return NextResponse.json({ subscription }, { status: 201 })
  } catch (error) {
    console.error('Error in POST /api/admin/subscriptions:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// PUT - Update subscription (cancel, pause, reactivate, change plan)
export async function PUT(request: NextRequest) {
  try {
    const supabase = createClient()
    const body = await request.json()
    const { id, action, ...updateData } = body

    if (!id) {
      return NextResponse.json({ error: 'Subscription ID is required' }, { status: 400 })
    }

    let updates: Record<string, any> = { updated_at: new Date().toISOString() }

    switch (action) {
      case 'cancel':
        updates.status = 'canceled'
        updates.canceled_at = new Date().toISOString()
        updates.cancel_reason = updateData.cancel_reason
        break
      case 'pause':
        updates.status = 'paused'
        break
      case 'reactivate':
        updates.status = 'active'
        updates.canceled_at = null
        // Calculate new billing date
        const nextBilling = new Date()
        if (updateData.billing_cycle === 'monthly') {
          nextBilling.setMonth(nextBilling.getMonth() + 1)
        } else {
          nextBilling.setFullYear(nextBilling.getFullYear() + 1)
        }
        updates.next_billing_date = nextBilling.toISOString()
        break
      case 'change_plan':
        updates.plan_id = updateData.plan_id
        updates.plan_name = updateData.plan_name
        updates.price = updateData.price
        break
      case 'retry_payment':
        // In production, this would trigger a Stripe payment retry
        updates.status = 'active'
        break
      default:
        updates = { ...updates, ...updateData }
    }

    const { data: subscription, error } = await supabase
      .from('admin_subscriptions')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Error updating subscription:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ subscription })
  } catch (error) {
    console.error('Error in PUT /api/admin/subscriptions:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// DELETE - Delete a subscription
export async function DELETE(request: NextRequest) {
  try {
    const supabase = createClient()
    const { searchParams } = new URL(request.url)
    const id = searchParams.get('id')

    if (!id) {
      return NextResponse.json({ error: 'Subscription ID is required' }, { status: 400 })
    }

    const { error } = await supabase
      .from('admin_subscriptions')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Error deleting subscription:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error in DELETE /api/admin/subscriptions:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
