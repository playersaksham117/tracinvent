import { requireAuth, getCurrentUser } from '@/lib/auth/session'
import { getUserOrganizations } from '@/lib/organization'
import { createClient } from '@/lib/supabase/server'
import { AnalyticsCharts } from '@/components/analytics/analytics-charts'
import { AnalyticsStats } from '@/components/analytics/analytics-stats'

export default async function AnalyticsPage() {
  await requireAuth()
  const user = await getCurrentUser()

  if (!user) return null

  const organizations = await getUserOrganizations(user.id)
  const currentOrg = organizations[0]

  if (!currentOrg) return null

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Analytics</h1>
        <p className="text-gray-600 mt-1">
          Detailed insights into your financial performance
        </p>
      </div>

      <AnalyticsStats organizationId={currentOrg.id} currency={currentOrg.currency} />
      
      <AnalyticsCharts organizationId={currentOrg.id} currency={currentOrg.currency} />
    </div>
  )
}
