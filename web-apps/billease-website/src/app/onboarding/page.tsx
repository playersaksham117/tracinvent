import { redirect } from 'next/navigation'
import { requireAuth, getCurrentUser } from '@/lib/auth/session'
import { getUserOrganizations } from '@/lib/organization'
import { OnboardingForm } from '@/components/onboarding/onboarding-form'

export default async function OnboardingPage() {
  const session = await requireAuth()
  const user = await getCurrentUser()

  if (!user) {
    redirect('/auth/signin')
  }

  const organizations = await getUserOrganizations(user.id)

  // If user already has organizations, redirect to dashboard
  if (organizations.length > 0) {
    redirect('/dashboard')
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
      <div className="w-full max-w-2xl">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">
            Welcome to SpendSight! 🎉
          </h1>
          <p className="text-gray-600">
            Let&apos;s set up your first organization to get started
          </p>
        </div>

        <div className="bg-white rounded-lg shadow-xl p-8">
          <OnboardingForm userId={user.id} />
        </div>
      </div>
    </div>
  )
}
