import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

// GET /api/pos/stock - Get stock levels and inventory
export async function GET(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const searchParams = request.nextUrl.searchParams
    const lowStock = searchParams.get('low_stock') === 'true'
    const productId = searchParams.get('product_id')

    let query = supabase
      .from('products')
      .select('*')
      .eq('is_active', true)
      .order('name')

    if (lowStock) {
      query = query.filter('stock_quantity', 'lte', 'reorder_level')
    }

    if (productId) {
      query = query.eq('id', productId)
    }

    const { data, error } = await query

    if (error) {
      console.error('Error fetching stock:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error in GET /api/pos/stock:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/pos/stock/adjust - Adjust stock levels
export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()
    
    if (!body.product_id || !body.adjustment_type || body.quantity_change === undefined) {
      return NextResponse.json({ 
        error: 'product_id, adjustment_type, and quantity_change are required' 
      }, { status: 400 })
    }

    // Get current product
    const { data: product, error: productError } = await supabase
      .from('products')
      .select('*')
      .eq('id', body.product_id)
      .single()

    if (productError || !product) {
      return NextResponse.json({ error: 'Product not found' }, { status: 404 })
    }

    // Calculate new stock quantity
    let newQuantity = product.stock_quantity
    
    if (body.adjustment_type === 'set') {
      newQuantity = body.quantity_change
    } else if (body.adjustment_type === 'add') {
      newQuantity += body.quantity_change
    } else if (body.adjustment_type === 'remove') {
      newQuantity -= body.quantity_change
    }

    // Update product stock
    const { data: updatedProduct, error: updateError } = await supabase
      .from('products')
      .update({ stock_quantity: newQuantity })
      .eq('id', body.product_id)
      .select()
      .single()

    if (updateError) {
      console.error('Error updating stock:', updateError)
      return NextResponse.json({ error: updateError.message }, { status: 500 })
    }

    // Log adjustment
    await supabase.from('stock_adjustments').insert({
      tenant_id: product.tenant_id,
      product_id: body.product_id,
      adjustment_type: body.adjustment_type,
      quantity_before: product.stock_quantity,
      quantity_change: body.quantity_change,
      quantity_after: newQuantity,
      reason: body.reason,
      adjusted_by: user.id,
    })

    return NextResponse.json(updatedProduct)
  } catch (error) {
    console.error('Error in POST /api/pos/stock/adjust:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
