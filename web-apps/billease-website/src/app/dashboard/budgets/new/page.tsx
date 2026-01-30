import { requireAuth, getCurrentUser } from '@/lib/auth/session'
import { getUserOrganizations } from '@/lib/organization'
import { createClient } from '@/lib/supabase/server'
import { BudgetForm } from '@/components/budgets/budget-form'

export default async function NewBudgetPage() {
  await requireAuth()
  const user = await getCurrentUser()

  if (!user) return null

  const organizations = await getUserOrganizations(user.id)
  const currentOrg = organizations[0]

  if (!currentOrg) return null

  const supabase = await createClient()

  // Get expense categories only
  const { data: categories } = await supabase
    .from('categories')
    .select('*')
    .eq('organization_id', currentOrg.id)
    .eq('type', 'expense')
    .eq('is_active', true)
    .order('name')

  return (
    <div className="max-w-3xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Create Budget</h1>
        <p className="text-gray-600 mt-1">
          Set spending limits and track your expenses
        </p>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <BudgetForm
          organizationId={currentOrg.id}
          userId={user.id}
          categories={categories || []}
          currency={currentOrg.currency}
        />
      </div>
    </div>
  )
}
