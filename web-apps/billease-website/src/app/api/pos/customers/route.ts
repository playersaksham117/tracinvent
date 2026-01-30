import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

// GET /api/pos/customers - Get all customers
export async function GET(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const searchParams = request.nextUrl.searchParams
    const search = searchParams.get('search')
    const group = searchParams.get('group')
    const active = searchParams.get('active')

    let query = supabase
      .from('customers')
      .select('*')
      .order('created_at', { ascending: false })

    if (search) {
      query = query.or(`name.ilike.%${search}%,phone.ilike.%${search}%,email.ilike.%${search}%`)
    }

    if (group) {
      query = query.eq('customer_group', group)
    }

    if (active === 'true') {
      query = query.eq('is_active', true)
    }

    const { data, error } = await query

    if (error) {
      console.error('Error fetching customers:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error in GET /api/pos/customers:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/pos/customers - Create a new customer
export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()
    
    // Get tenant_id for the user
    const { data: tenant } = await supabase
      .from('tenants')
      .select('id')
      .eq('user_id', user.id)
      .single()

    if (!tenant) {
      return NextResponse.json({ error: 'No tenant found' }, { status: 404 })
    }

    const customerData = {
      tenant_id: tenant.id,
      name: body.name,
      email: body.email,
      phone: body.phone,
      address: body.address,
      city: body.city,
      state: body.state,
      postal_code: body.postal_code,
      country: body.country || 'US',
      tax_id: body.tax_id,
      customer_group: body.customer_group || 'regular',
      notes: body.notes,
      is_active: body.is_active ?? true,
    }

    const { data, error } = await supabase
      .from('customers')
      .insert(customerData)
      .select()
      .single()

    if (error) {
      console.error('Error creating customer:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json(data, { status: 201 })
  } catch (error) {
    console.error('Error in POST /api/pos/customers:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// PUT /api/pos/customers/:id - Update a customer
export async function PUT(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()
    const customerId = body.id

    if (!customerId) {
      return NextResponse.json({ error: 'Customer ID required' }, { status: 400 })
    }

    const updateData: any = {}
    
    if (body.name) updateData.name = body.name
    if (body.email !== undefined) updateData.email = body.email
    if (body.phone !== undefined) updateData.phone = body.phone
    if (body.address !== undefined) updateData.address = body.address
    if (body.city !== undefined) updateData.city = body.city
    if (body.state !== undefined) updateData.state = body.state
    if (body.postal_code !== undefined) updateData.postal_code = body.postal_code
    if (body.country !== undefined) updateData.country = body.country
    if (body.tax_id !== undefined) updateData.tax_id = body.tax_id
    if (body.customer_group !== undefined) updateData.customer_group = body.customer_group
    if (body.notes !== undefined) updateData.notes = body.notes
    if (body.is_active !== undefined) updateData.is_active = body.is_active

    const { data, error } = await supabase
      .from('customers')
      .update(updateData)
      .eq('id', customerId)
      .select()
      .single()

    if (error) {
      console.error('Error updating customer:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error in PUT /api/pos/customers:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
