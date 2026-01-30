import { requireAuth, getCurrentUser } from '@/lib/auth/session'
import { getUserOrganizations } from '@/lib/organization'
import { createClient } from '@/lib/supabase/server'
import { BudgetList } from '@/components/budgets/budget-list'
import Link from 'next/link'

export default async function BudgetsPage() {
  await requireAuth()
  const user = await getCurrentUser()

  if (!user) return null

  const organizations = await getUserOrganizations(user.id)
  const currentOrg = organizations[0]

  if (!currentOrg) return null

  const supabase = await createClient()

  const { data: budgets } = await supabase
    .from('budgets')
    .select(`
      *,
      budget_categories(
        id,
        allocated_amount,
        spent_amount,
        category:categories(name, color)
      )
    `)
    .eq('organization_id', currentOrg.id)
    .order('created_at', { ascending: false })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Budgets</h1>
          <p className="text-gray-600 mt-1">
            Create and manage your spending budgets
          </p>
        </div>
        <Link
          href="/dashboard/budgets/new"
          className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition-colors"
        >
          + New Budget
        </Link>
      </div>

      <BudgetList budgets={budgets || []} currency={currentOrg.currency} />
    </div>
  )
}
