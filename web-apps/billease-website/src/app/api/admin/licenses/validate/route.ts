import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

// Validate a license (called from desktop app)
export async function POST(request: NextRequest) {
  try {
    const supabase = createClient()
    const body = await request.json()

    const { license_key, hardware_id, machine_name, os_info } = body

    if (!license_key || !hardware_id) {
      return NextResponse.json({ 
        valid: false, 
        error: 'License key and hardware ID are required' 
      }, { status: 400 })
    }

    // Find the license
    const { data: license, error } = await supabase
      .from('desktop_licenses')
      .select('*')
      .eq('license_key', license_key)
      .single()

    if (error || !license) {
      return NextResponse.json({ 
        valid: false, 
        error: 'Invalid license key' 
      }, { status: 404 })
    }

    // Check if license is revoked
    if (license.status === 'revoked') {
      return NextResponse.json({ 
        valid: false, 
        error: 'This license has been revoked' 
      })
    }

    // Check if license is expired
    if (license.expires_on && new Date(license.expires_on) < new Date()) {
      // Update status to expired
      await supabase
        .from('desktop_licenses')
        .update({ status: 'expired' })
        .eq('id', license.id)

      return NextResponse.json({ 
        valid: false, 
        error: 'This license has expired',
        expires_on: license.expires_on
      })
    }

    // Check if hardware ID is already activated
    const isAlreadyActivated = license.hardware_ids?.includes(hardware_id)

    if (!isAlreadyActivated) {
      // Check if max activations reached
      if (license.activations >= license.max_activations) {
        return NextResponse.json({ 
          valid: false, 
          error: 'Maximum activations reached',
          activations: license.activations,
          max_activations: license.max_activations
        })
      }

      // Add new activation
      const newHardwareIds = [...(license.hardware_ids || []), hardware_id]
      
      await supabase
        .from('desktop_licenses')
        .update({ 
          hardware_ids: newHardwareIds,
          activations: license.activations + 1,
          status: 'active',
          activated_on: license.activated_on || new Date().toISOString(),
          last_checked: new Date().toISOString()
        })
        .eq('id', license.id)

      // Log activation
      await supabase.from('license_activations').insert({
        license_id: license.id,
        hardware_id,
        machine_name,
        os_info,
        ip_address: request.headers.get('x-forwarded-for') || 'unknown',
        activated_at: new Date().toISOString(),
        is_active: true,
        metadata: {}
      })
    } else {
      // Update last checked
      await supabase
        .from('desktop_licenses')
        .update({ last_checked: new Date().toISOString() })
        .eq('id', license.id)
    }

    return NextResponse.json({
      valid: true,
      license: {
        product: license.product,
        product_code: license.product_code,
        license_type: license.license_type,
        expires_on: license.expires_on,
        customer_name: license.customer_name,
        activations: isAlreadyActivated ? license.activations : license.activations + 1,
        max_activations: license.max_activations
      }
    })
  } catch (error) {
    console.error('Error validating license:', error)
    return NextResponse.json({ 
      valid: false, 
      error: 'Internal server error' 
    }, { status: 500 })
  }
}

// Deactivate a license on a specific machine
export async function DELETE(request: NextRequest) {
  try {
    const supabase = createClient()
    const { searchParams } = new URL(request.url)
    const license_key = searchParams.get('license_key')
    const hardware_id = searchParams.get('hardware_id')

    if (!license_key || !hardware_id) {
      return NextResponse.json({ 
        success: false, 
        error: 'License key and hardware ID are required' 
      }, { status: 400 })
    }

    // Find the license
    const { data: license, error } = await supabase
      .from('desktop_licenses')
      .select('*')
      .eq('license_key', license_key)
      .single()

    if (error || !license) {
      return NextResponse.json({ 
        success: false, 
        error: 'Invalid license key' 
      }, { status: 404 })
    }

    // Remove hardware ID from activations
    const newHardwareIds = (license.hardware_ids || []).filter((id: string) => id !== hardware_id)
    
    await supabase
      .from('desktop_licenses')
      .update({ 
        hardware_ids: newHardwareIds,
        activations: Math.max(0, license.activations - 1)
      })
      .eq('id', license.id)

    // Update activation record
    await supabase
      .from('license_activations')
      .update({ 
        is_active: false,
        deactivated_at: new Date().toISOString()
      })
      .eq('license_id', license.id)
      .eq('hardware_id', hardware_id)

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error deactivating license:', error)
    return NextResponse.json({ 
      success: false, 
      error: 'Internal server error' 
    }, { status: 500 })
  }
}
