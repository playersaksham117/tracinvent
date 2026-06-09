import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

// GET - Fetch all pricing data (plans, desktop pricing, discounts)
export async function GET(request: NextRequest) {
  try {
    const supabase = createClient()
    const { searchParams } = new URL(request.url)
    const type = searchParams.get('type') || 'all'

    const response: Record<string, any> = {}

    if (type === 'all' || type === 'plans') {
      const { data: plans, error: plansError } = await supabase
        .from('pricing_plans')
        .select('*')
        .order('monthly_price', { ascending: true })

      if (plansError) {
        console.error('Error fetching plans:', plansError)
      }
      response.plans = plans || []
    }

    if (type === 'all' || type === 'desktop') {
      const { data: desktopPricing, error: desktopError } = await supabase
        .from('desktop_product_pricing')
        .select('*')
        .order('product', { ascending: true })

      if (desktopError) {
        console.error('Error fetching desktop pricing:', desktopError)
      }
      response.desktopPricing = desktopPricing || []
    }

    if (type === 'all' || type === 'discounts') {
      const { data: discounts, error: discountsError } = await supabase
        .from('discount_codes')
        .select('*')
        .order('created_at', { ascending: false })

      if (discountsError) {
        console.error('Error fetching discounts:', discountsError)
      }
      response.discounts = discounts || []
    }

    return NextResponse.json(response)
  } catch (error) {
    console.error('Error in GET /api/admin/pricing:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST - Create new pricing item (plan, desktop pricing, or discount)
export async function POST(request: NextRequest) {
  try {
    const supabase = createClient()
    const body = await request.json()
    const { type, ...data } = body

    let result

    switch (type) {
      case 'plan':
        const { data: plan, error: planError } = await supabase
          .from('pricing_plans')
          .insert({
            name: data.name,
            slug: data.slug || data.name.toLowerCase().replace(/\s+/g, '-'),
            description: data.description,
            monthly_price: data.monthly_price,
            yearly_price: data.yearly_price,
            features: data.features || [],
            max_users: data.max_users || 1,
            max_licenses: data.max_licenses || 1,
            is_popular: data.is_popular || false,
            is_active: true,
            metadata: data.metadata || {}
          })
          .select()
          .single()

        if (planError) throw planError
        result = { plan }
        break

      case 'desktop':
        const { data: desktop, error: desktopError } = await supabase
          .from('desktop_product_pricing')
          .insert({
            product: data.product,
            product_code: data.product_code,
            perpetual_price: data.perpetual_price,
            subscription_monthly: data.subscription_monthly,
            subscription_yearly: data.subscription_yearly,
            is_active: true,
            metadata: data.metadata || {}
          })
          .select()
          .single()

        if (desktopError) throw desktopError
        result = { desktopPricing: desktop }
        break

      case 'discount':
        const { data: discount, error: discountError } = await supabase
          .from('discount_codes')
          .insert({
            code: data.code.toUpperCase(),
            name: data.name,
            description: data.description,
            discount_type: data.discount_type,
            discount_value: data.discount_value,
            min_purchase_amount: data.min_purchase_amount || 0,
            max_discount_amount: data.max_discount_amount,
            max_uses: data.max_uses || -1,
            used_count: 0,
            applicable_to: data.applicable_to || 'all',
            applicable_plans: data.applicable_plans,
            applicable_products: data.applicable_products,
            valid_from: data.valid_from || new Date().toISOString(),
            valid_until: data.valid_until,
            is_active: true,
            metadata: data.metadata || {}
          })
          .select()
          .single()

        if (discountError) throw discountError
        result = { discount }
        break

      default:
        return NextResponse.json({ error: 'Invalid type' }, { status: 400 })
    }

    // Log activity
    await supabase.from('admin_activities').insert({
      admin_id: body.admin_id,
      action_type: 'pricing',
      action: `Created new ${type}`,
      resource_name: data.name || data.code || data.product,
      metadata: {}
    })

    return NextResponse.json(result, { status: 201 })
  } catch (error: any) {
    console.error('Error in POST /api/admin/pricing:', error)
    return NextResponse.json({ error: error.message || 'Internal server error' }, { status: 500 })
  }
}

// PUT - Update pricing item
export async function PUT(request: NextRequest) {
  try {
    const supabase = createClient()
    const body = await request.json()
    const { type, id, ...updateData } = body

    if (!id) {
      return NextResponse.json({ error: 'ID is required' }, { status: 400 })
    }

    let tableName: string
    switch (type) {
      case 'plan':
        tableName = 'pricing_plans'
        break
      case 'desktop':
        tableName = 'desktop_product_pricing'
        break
      case 'discount':
        tableName = 'discount_codes'
        break
      default:
        return NextResponse.json({ error: 'Invalid type' }, { status: 400 })
    }

    const { data, error } = await supabase
      .from(tableName)
      .update({
        ...updateData,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error(`Error updating ${type}:`, error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ [type]: data })
  } catch (error) {
    console.error('Error in PUT /api/admin/pricing:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// DELETE - Delete pricing item
export async function DELETE(request: NextRequest) {
  try {
    const supabase = createClient()
    const { searchParams } = new URL(request.url)
    const type = searchParams.get('type')
    const id = searchParams.get('id')

    if (!type || !id) {
      return NextResponse.json({ error: 'Type and ID are required' }, { status: 400 })
    }

    let tableName: string
    switch (type) {
      case 'plan':
        tableName = 'pricing_plans'
        break
      case 'desktop':
        tableName = 'desktop_product_pricing'
        break
      case 'discount':
        tableName = 'discount_codes'
        break
      default:
        return NextResponse.json({ error: 'Invalid type' }, { status: 400 })
    }

    const { error } = await supabase
      .from(tableName)
      .delete()
      .eq('id', id)

    if (error) {
      console.error(`Error deleting ${type}:`, error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error in DELETE /api/admin/pricing:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
