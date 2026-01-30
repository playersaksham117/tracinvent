import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { SignUpForm } from '@/components/auth/signup-form'

export const metadata = {
  title: 'Sign Up | SpendSight',
  description: 'Create your SpendSight account',
}

export default async function SignUpPage() {
  const supabase = await createClient()
  const { data: { session } } = await supabase.auth.getSession()

  if (session) {
    redirect('/dashboard')
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">SpendSight</h1>
          <p className="text-gray-600">Start managing your finances today</p>
        </div>
        
        <div className="bg-white rounded-lg shadow-xl p-8">
          <h2 className="text-2xl font-semibold text-gray-900 mb-6">Create Account</h2>
          <SignUpForm />
        </div>

        <p className="text-center text-sm text-gray-600 mt-6">
          Already have an account?{' '}
          <a href="/auth/signin" className="text-blue-600 hover:text-blue-700 font-medium">
            Sign in
          </a>
        </p>
      </div>
    </div>
  )
}
