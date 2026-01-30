import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

// GET /api/pos/payment-methods - Get all payment methods
export async function GET(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { data, error } = await supabase
      .from('payment_methods')
      .select('*')
      .eq('is_active', true)
      .order('name')

    if (error) {
      console.error('Error fetching payment methods:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json(data || [])
  } catch (error) {
    console.error('Error in GET /api/pos/payment-methods:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/pos/payment-methods - Create default payment methods for tenant
export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Get tenant_id for the user
    const { data: tenant } = await supabase
      .from('tenants')
      .select('id')
      .eq('user_id', user.id)
      .single()

    if (!tenant) {
      return NextResponse.json({ error: 'No tenant found' }, { status: 404 })
    }

    const defaultPaymentMethods = [
      { tenant_id: tenant.id, name: 'Cash', code: 'cash', icon: '💵', is_active: true, requires_reference: false },
      { tenant_id: tenant.id, name: 'Credit/Debit Card', code: 'card', icon: '💳', is_active: true, requires_reference: true },
      { tenant_id: tenant.id, name: 'UPI', code: 'upi', icon: '📱', is_active: true, requires_reference: true },
      { tenant_id: tenant.id, name: 'Digital Wallet', code: 'wallet', icon: '👛', is_active: true, requires_reference: true },
      { tenant_id: tenant.id, name: 'Bank Transfer', code: 'bank_transfer', icon: '🏦', is_active: true, requires_reference: true },
    ]

    const { data, error } = await supabase
      .from('payment_methods')
      .insert(defaultPaymentMethods)
      .select()

    if (error) {
      console.error('Error creating payment methods:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json(data, { status: 201 })
  } catch (error) {
    console.error('Error in POST /api/pos/payment-methods:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
