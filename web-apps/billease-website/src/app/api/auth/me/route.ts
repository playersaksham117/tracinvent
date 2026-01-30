import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function GET(request: NextRequest) {
  try {
    const supabase = createClient()

    const { data: { user }, error } = await supabase.auth.getUser()

    if (error || !user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      )
    }

    // Fetch user details from database
    const { data: userData, error: dbError } = await supabase
      .from('users')
      .select('*')
      .eq('id', user.id)
      .single()

    if (dbError) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      )
    }

    // Fetch active subscriptions
    const { data: subscriptions } = await supabase
      .from('subscriptions')
      .select('*, subscription_plans(*)')
      .eq('user_id', user.id)
      .eq('status', 'active')

    // Fetch app access
    const { data: appAccess } = await supabase
      .from('app_access')
      .select('*')
      .eq('user_id', user.id)
      .eq('has_access', true)

    return NextResponse.json({
      user: userData,
      subscriptions,
      appAccess,
    })
  } catch (error) {
    console.error('Get user error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
