import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'
import crypto from 'crypto'

// Generate a unique license key
function generateLicenseKey(productCode: string): string {
  const randomPart = crypto.randomBytes(8).toString('hex').toUpperCase()
  const segments = [
    productCode.toUpperCase(),
    randomPart.slice(0, 4),
    randomPart.slice(4, 8),
    randomPart.slice(8, 12),
    randomPart.slice(12, 16)
  ]
  return segments.join('-')
}

// GET - Fetch all licenses with pagination and filters
export async function GET(request: NextRequest) {
  try {
    const supabase = createClient()
    const { searchParams } = new URL(request.url)
    
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '10')
    const search = searchParams.get('search') || ''
    const status = searchParams.get('status') || 'all'
    const product = searchParams.get('product') || 'all'
    const licenseType = searchParams.get('type') || 'all'

    const offset = (page - 1) * limit

    // Build query
    let query = supabase
      .from('desktop_licenses')
      .select('*', { count: 'exact' })

    // Apply search filter
    if (search) {
      query = query.or(`license_key.ilike.%${search}%,customer_name.ilike.%${search}%,customer_email.ilike.%${search}%`)
    }

    // Apply status filter
    if (status !== 'all') {
      query = query.eq('status', status)
    }

    // Apply product filter
    if (product !== 'all') {
      query = query.eq('product', product)
    }

    // Apply license type filter
    if (licenseType !== 'all') {
      query = query.eq('license_type', licenseType)
    }

    // Apply sorting and pagination
    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1)

    const { data: licenses, error, count } = await query

    if (error) {
      console.error('Error fetching licenses:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    // Get stats
    const { data: allLicenses } = await supabase
      .from('desktop_licenses')
      .select('status')

    const stats = {
      total: allLicenses?.length || 0,
      active: allLicenses?.filter(l => l.status === 'active').length || 0,
      expired: allLicenses?.filter(l => l.status === 'expired').length || 0,
      pending: allLicenses?.filter(l => l.status === 'pending').length || 0,
      revoked: allLicenses?.filter(l => l.status === 'revoked').length || 0
    }

    return NextResponse.json({
      licenses,
      stats,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit)
      }
    })
  } catch (error) {
    console.error('Error in GET /api/admin/licenses:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST - Generate a new license
export async function POST(request: NextRequest) {
  try {
    const supabase = createClient()
    const body = await request.json()

    const licenseKey = generateLicenseKey(body.product_code || 'BE')

    const { data: license, error } = await supabase
      .from('desktop_licenses')
      .insert({
        license_key: licenseKey,
        customer_id: body.customer_id,
        customer_name: body.customer_name,
        customer_email: body.customer_email,
        product: body.product,
        product_code: body.product_code,
        license_type: body.license_type || 'perpetual',
        status: 'pending',
        activations: 0,
        max_activations: body.max_activations || 1,
        expires_on: body.expires_on,
        hardware_ids: [],
        metadata: body.metadata || {}
      })
      .select()
      .single()

    if (error) {
      console.error('Error creating license:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    // Update customer license count
    if (body.customer_id) {
      await supabase.rpc('increment_customer_license_count', { 
        customer_id: body.customer_id 
      })
    }

    // Log activity
    await supabase.from('admin_activities').insert({
      admin_id: body.admin_id,
      action_type: 'license',
      action: 'Generated new license',
      resource_id: license.id,
      resource_name: licenseKey,
      details: `Product: ${body.product}`,
      metadata: {}
    })

    return NextResponse.json({ license }, { status: 201 })
  } catch (error) {
    console.error('Error in POST /api/admin/licenses:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// PUT - Update license (activate, revoke, reset activations)
export async function PUT(request: NextRequest) {
  try {
    const supabase = createClient()
    const body = await request.json()
    const { id, action, ...updateData } = body

    if (!id) {
      return NextResponse.json({ error: 'License ID is required' }, { status: 400 })
    }

    let updates: Record<string, any> = { updated_at: new Date().toISOString() }

    switch (action) {
      case 'revoke':
        updates.status = 'revoked'
        break
      case 'activate':
        updates.status = 'active'
        updates.activated_on = new Date().toISOString()
        break
      case 'reset_activations':
        updates.activations = 0
        updates.hardware_ids = []
        break
      case 'extend':
        updates.expires_on = updateData.expires_on
        break
      default:
        updates = { ...updates, ...updateData }
    }

    const { data: license, error } = await supabase
      .from('desktop_licenses')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Error updating license:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ license })
  } catch (error) {
    console.error('Error in PUT /api/admin/licenses:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// DELETE - Delete a license
export async function DELETE(request: NextRequest) {
  try {
    const supabase = createClient()
    const { searchParams } = new URL(request.url)
    const id = searchParams.get('id')

    if (!id) {
      return NextResponse.json({ error: 'License ID is required' }, { status: 400 })
    }

    // Get license to get customer_id
    const { data: license } = await supabase
      .from('desktop_licenses')
      .select('customer_id')
      .eq('id', id)
      .single()

    const { error } = await supabase
      .from('desktop_licenses')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Error deleting license:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    // Update customer license count
    if (license?.customer_id) {
      await supabase.rpc('decrement_customer_license_count', { 
        customer_id: license.customer_id 
      })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error in DELETE /api/admin/licenses:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
