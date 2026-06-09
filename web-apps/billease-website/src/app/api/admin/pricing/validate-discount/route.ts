import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

// Validate a discount code (for checkout)
export async function POST(request: NextRequest) {
  try {
    const supabase = createClient()
    const body = await request.json()

    const { code, purchase_amount, product_type } = body

    if (!code) {
      return NextResponse.json({ 
        valid: false, 
        error: 'Discount code is required' 
      }, { status: 400 })
    }

    // Find the discount code
    const { data: discount, error } = await supabase
      .from('discount_codes')
      .select('*')
      .eq('code', code.toUpperCase())
      .single()

    if (error || !discount) {
      return NextResponse.json({ 
        valid: false, 
        error: 'Invalid discount code' 
      }, { status: 404 })
    }

    // Check if discount is active
    if (!discount.is_active) {
      return NextResponse.json({ 
        valid: false, 
        error: 'This discount code is no longer active' 
      })
    }

    // Check if discount has expired
    if (discount.valid_until && new Date(discount.valid_until) < new Date()) {
      return NextResponse.json({ 
        valid: false, 
        error: 'This discount code has expired' 
      })
    }

    // Check if discount hasn't started yet
    if (discount.valid_from && new Date(discount.valid_from) > new Date()) {
      return NextResponse.json({ 
        valid: false, 
        error: 'This discount code is not yet valid' 
      })
    }

    // Check usage limit
    if (discount.max_uses !== -1 && discount.used_count >= discount.max_uses) {
      return NextResponse.json({ 
        valid: false, 
        error: 'This discount code has reached its usage limit' 
      })
    }

    // Check minimum purchase amount
    if (purchase_amount && discount.min_purchase_amount > 0 && purchase_amount < discount.min_purchase_amount) {
      return NextResponse.json({ 
        valid: false, 
        error: `Minimum purchase amount of $${discount.min_purchase_amount} required` 
      })
    }

    // Check product type applicability
    if (discount.applicable_to !== 'all' && product_type && discount.applicable_to !== product_type) {
      return NextResponse.json({ 
        valid: false, 
        error: `This discount code is only valid for ${discount.applicable_to} products` 
      })
    }

    // Calculate discount amount
    let discountAmount = 0
    if (purchase_amount) {
      if (discount.discount_type === 'percentage') {
        discountAmount = (purchase_amount * discount.discount_value) / 100
      } else {
        discountAmount = discount.discount_value
      }

      // Apply max discount cap
      if (discount.max_discount_amount && discountAmount > discount.max_discount_amount) {
        discountAmount = discount.max_discount_amount
      }
    }

    return NextResponse.json({
      valid: true,
      discount: {
        id: discount.id,
        code: discount.code,
        name: discount.name,
        discount_type: discount.discount_type,
        discount_value: discount.discount_value,
        calculated_discount: Math.round(discountAmount * 100) / 100,
        final_amount: purchase_amount ? Math.round((purchase_amount - discountAmount) * 100) / 100 : null
      }
    })
  } catch (error) {
    console.error('Error validating discount:', error)
    return NextResponse.json({ 
      valid: false, 
      error: 'Internal server error' 
    }, { status: 500 })
  }
}

// Apply/Use a discount code (after successful purchase)
export async function PUT(request: NextRequest) {
  try {
    const supabase = createClient()
    const body = await request.json()

    const { code, order_id } = body

    if (!code) {
      return NextResponse.json({ 
        success: false, 
        error: 'Discount code is required' 
      }, { status: 400 })
    }

    // Increment usage count
    const { data, error } = await supabase.rpc('increment_discount_usage', {
      discount_code: code.toUpperCase()
    })

    if (error) {
      // Fallback if RPC doesn't exist
      const { data: discount } = await supabase
        .from('discount_codes')
        .select('used_count')
        .eq('code', code.toUpperCase())
        .single()

      if (discount) {
        await supabase
          .from('discount_codes')
          .update({ used_count: discount.used_count + 1 })
          .eq('code', code.toUpperCase())
      }
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error applying discount:', error)
    return NextResponse.json({ 
      success: false, 
      error: 'Internal server error' 
    }, { status: 500 })
  }
}
