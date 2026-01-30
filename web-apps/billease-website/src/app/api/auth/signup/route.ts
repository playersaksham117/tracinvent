import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(request: NextRequest) {
  try {
    const { email, password, full_name, company_name, phone } = await request.json()

    // Validate input
    if (!email || !password || !full_name) {
      return NextResponse.json(
        { error: 'Email, password, and full name are required' },
        { status: 400 }
      )
    }

    // Validate password strength
    if (password.length < 8) {
      return NextResponse.json(
        { error: 'Password must be at least 8 characters long' },
        { status: 400 }
      )
    }

    const supabase = createClient()

    // Sign up with Supabase
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name,
          company_name,
          phone,
        },
      },
    })

    if (authError) {
      return NextResponse.json(
        { error: authError.message },
        { status: 400 }
      )
    }

    if (!authData.user) {
      return NextResponse.json(
        { error: 'Failed to create user' },
        { status: 500 }
      )
    }

    // Create user record in main database
    const { error: dbError } = await supabase.from('users').insert({
      id: authData.user.id,
      email,
      full_name,
      company_name,
      phone,
      role: 'user',
      status: 'active',
    })

    if (dbError) {
      console.error('Database error:', dbError)
      // Continue anyway - the user is created in auth
    }

    // Log audit trail
    await supabase.from('audit_logs').insert({
      user_id: authData.user.id,
      action: 'signup',
      status: 'success',
      metadata: {
        method: 'password',
        user_agent: request.headers.get('user-agent'),
      },
    })

    return NextResponse.json({
      user: authData.user,
      session: authData.session,
      message: 'Account created successfully',
    })
  } catch (error) {
    console.error('Signup error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
