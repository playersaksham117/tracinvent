import { redirect } from 'next/navigation'
import { requireAuth, getCurrentUser } from '@/lib/auth/session'
import { getUserOrganizations } from '@/lib/organization'
import { DashboardNav } from '@/components/dashboard/dashboard-nav'
import { OrganizationSwitcher } from '@/components/dashboard/organization-switcher'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const session = await requireAuth()
  const user = await getCurrentUser()

  if (!user) {
    redirect('/auth/signin')
  }

  const organizations = await getUserOrganizations(user.id)

  // If no organizations, redirect to onboarding
  if (organizations.length === 0) {
    redirect('/onboarding')
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Top Navigation */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-50">
        <div className="px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center gap-4">
              <h1 className="text-xl font-bold text-gray-900">SpendSight</h1>
              <OrganizationSwitcher organizations={organizations} />
            </div>

            <div className="flex items-center gap-4">
              <span className="text-sm text-gray-600 hidden sm:inline">
                {user.email}
              </span>
              <form action="/auth/signout" method="post">
                <button
                  type="submit"
                  className="text-sm text-gray-600 hover:text-gray-900"
                >
                  Sign Out
                </button>
              </form>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex">
        {/* Sidebar Navigation */}
        <aside className="hidden lg:block w-64 bg-white border-r border-gray-200 min-h-[calc(100vh-4rem)]">
          <DashboardNav />
        </aside>

        {/* Page Content */}
        <main className="flex-1">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}
