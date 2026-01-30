import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json()

    // Validate input
    if (!email || !password) {
      return NextResponse.json(
        { error: 'Email and password are required' },
        { status: 400 }
      )
    }

    // Demo account for testing (bypass Supabase)
    if (email === 'demo1' && password === 'demo123') {
      const demoUser = {
        id: 'demo-user-id',
        email: 'demo1@billease.com',
        user_metadata: {
          full_name: 'Demo User',
          company: 'Demo Company'
        }
      }
      
      return NextResponse.json({
        user: demoUser,
        session: {
          access_token: 'demo-token',
          user: demoUser
        },
        demo: true
      })
    }

    const supabase = createClient()

    // Sign in with Supabase
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      return NextResponse.json(
        { error: error.message },
        { status: 401 }
      )
    }

    // Log audit trail
    if (data.user) {
      await supabase.from('audit_logs').insert({
        user_id: data.user.id,
        action: 'login',
        status: 'success',
        metadata: {
          method: 'password',
          user_agent: request.headers.get('user-agent'),
        },
      })
    }

    return NextResponse.json({
      user: data.user,
      session: data.session,
    })
  } catch (error) {
    console.error('Login error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
