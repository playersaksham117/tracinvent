import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

// GET /api/pos/sales - Get all sales/invoices
export async function GET(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const searchParams = request.nextUrl.searchParams
    const status = searchParams.get('status')
    const customerId = searchParams.get('customer_id')
    const from = searchParams.get('from')
    const to = searchParams.get('to')
    const limit = searchParams.get('limit')

    let query = supabase
      .from('sales')
      .select('*, sale_items(*), customers(*)')
      .order('completed_at', { ascending: false })

    if (status) {
      query = query.eq('status', status)
    }

    if (customerId) {
      query = query.eq('customer_id', customerId)
    }

    if (from) {
      query = query.gte('completed_at', from)
    }

    if (to) {
      query = query.lte('completed_at', to)
    }

    if (limit) {
      query = query.limit(parseInt(limit))
    }

    const { data, error } = await query

    if (error) {
      console.error('Error fetching sales:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error in GET /api/pos/sales:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/pos/sales - Create a new sale/invoice
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

    // Validate required fields
    if (!body.items || body.items.length === 0) {
      return NextResponse.json({ error: 'Sale must have at least one item' }, { status: 400 })
    }

    // Calculate totals
    const subtotal = body.items.reduce((sum: number, item: any) => 
      sum + (item.unit_price * item.quantity), 0)
    
    const tax_amount = body.items.reduce((sum: number, item: any) => 
      sum + ((item.unit_price * item.quantity * (item.tax_rate || 0)) / 100), 0)
    
    const discount_amount = body.discount_amount || 0
    const total_amount = subtotal + tax_amount - discount_amount

    // Create sale record
    const saleData = {
      tenant_id: tenant.id,
      customer_id: body.customer_id,
      customer_name: body.customer_name,
      customer_phone: body.customer_phone,
      customer_email: body.customer_email,
      subtotal,
      tax_amount,
      discount_amount,
      total_amount,
      amount_paid: body.amount_paid || total_amount,
      change_amount: (body.amount_paid || total_amount) - total_amount,
      payment_method: body.payment_method || 'cash',
      payment_status: body.payment_status || 'paid',
      status: body.status || 'completed',
      notes: body.notes,
      cashier_id: user.id,
      shift_id: body.shift_id,
      completed_at: new Date().toISOString(),
    }

    const { data: sale, error: saleError } = await supabase
      .from('sales')
      .insert(saleData)
      .select()
      .single()

    if (saleError) {
      console.error('Error creating sale:', saleError)
      return NextResponse.json({ error: saleError.message }, { status: 500 })
    }

    // Create sale items
    const saleItems = body.items.map((item: any) => ({
      tenant_id: tenant.id,
      sale_id: sale.id,
      product_id: item.product_id,
      product_name: item.product_name || item.name,
      quantity: item.quantity,
      unit_price: item.unit_price || item.price,
      tax_rate: item.tax_rate || 0,
      discount: item.discount || 0,
      subtotal: item.unit_price * item.quantity,
      total: (item.unit_price * item.quantity) * (1 + (item.tax_rate || 0) / 100) - (item.discount || 0),
    }))

    const { error: itemsError } = await supabase
      .from('sale_items')
      .insert(saleItems)

    if (itemsError) {
      console.error('Error creating sale items:', itemsError)
      // Rollback sale if items fail
      await supabase.from('sales').delete().eq('id', sale.id)
      return NextResponse.json({ error: itemsError.message }, { status: 500 })
    }

    // Create payment transaction record
    if (body.amount_paid > 0) {
      await supabase.from('payment_transactions').insert({
        tenant_id: tenant.id,
        sale_id: sale.id,
        amount: body.amount_paid,
        payment_method: body.payment_method || 'cash',
        reference_number: body.reference_number,
        status: 'completed',
      })
    }

    // Update product stock quantities
    for (const item of body.items) {
      if (item.product_id) {
        await supabase.rpc('update_product_stock', {
          p_product_id: item.product_id,
          p_quantity: -item.quantity
        })
      }
    }

    // Fetch complete sale with items
    const { data: completeSale } = await supabase
      .from('sales')
      .select('*, sale_items(*)')
      .eq('id', sale.id)
      .single()

    return NextResponse.json(completeSale, { status: 201 })
  } catch (error) {
    console.error('Error in POST /api/pos/sales:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
