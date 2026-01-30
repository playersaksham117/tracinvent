import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

// GET /api/pos/discounts - Get all discounts
export async function GET(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const searchParams = request.nextUrl.searchParams
    const code = searchParams.get('code')
    const active = searchParams.get('active')

    let query = supabase
      .from('discounts')
      .select('*')
      .order('created_at', { ascending: false })

    if (code) {
      query = query.eq('code', code)
    }

    if (active === 'true') {
      query = query.eq('is_active', true)
    }

    const { data, error } = await query

    if (error) {
      console.error('Error fetching discounts:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error in GET /api/pos/discounts:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/pos/discounts/validate - Validate a discount code
export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()
    const { code, purchase_amount } = body

    if (!code) {
      return NextResponse.json({ error: 'Discount code required' }, { status: 400 })
    }

    // Get discount
    const { data: discount, error } = await supabase
      .from('discounts')
      .select('*')
      .eq('code', code)
      .eq('is_active', true)
      .single()

    if (error || !discount) {
      return NextResponse.json({ 
        valid: false, 
        error: 'Invalid or expired discount code' 
      }, { status: 200 })
    }

    // Check validity period
    const now = new Date()
    const validFrom = new Date(discount.valid_from)
    const validUntil = discount.valid_until ? new Date(discount.valid_until) : null

    if (now < validFrom || (validUntil && now > validUntil)) {
      return NextResponse.json({ 
        valid: false, 
        error: 'Discount code has expired' 
      }, { status: 200 })
    }

    // Check usage limit
    if (discount.usage_limit && discount.usage_count >= discount.usage_limit) {
      return NextResponse.json({ 
        valid: false, 
        error: 'Discount code usage limit reached' 
      }, { status: 200 })
    }

    // Check minimum purchase amount
    if (purchase_amount && purchase_amount < discount.min_purchase_amount) {
      return NextResponse.json({ 
        valid: false, 
        error: `Minimum purchase amount of $${discount.min_purchase_amount} required` 
      }, { status: 200 })
    }

    // Calculate discount amount
    let discountAmount = 0
    if (discount.discount_type === 'percentage') {
      discountAmount = (purchase_amount * discount.discount_value) / 100
    } else {
      discountAmount = discount.discount_value
    }

    // Apply max discount limit
    if (discount.max_discount_amount && discountAmount > discount.max_discount_amount) {
      discountAmount = discount.max_discount_amount
    }

    return NextResponse.json({
      valid: true,
      discount: {
        ...discount,
        calculated_discount: discountAmount,
      }
    })
  } catch (error) {
    console.error('Error in POST /api/pos/discounts/validate:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
