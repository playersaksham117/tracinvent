import { requireAuth, getCurrentUser } from '@/lib/auth/session'
import { getUserOrganizations } from '@/lib/organization'
import { createClient } from '@/lib/supabase/server'
import { TransactionForm } from '@/components/transactions/transaction-form'

export default async function NewTransactionPage() {
  await requireAuth()
  const user = await getCurrentUser()

  if (!user) return null

  const organizations = await getUserOrganizations(user.id)
  const currentOrg = organizations[0]

  if (!currentOrg) return null

  const supabase = await createClient()

  // Get categories
  const { data: categories } = await supabase
    .from('categories')
    .select('*')
    .eq('organization_id', currentOrg.id)
    .eq('is_active', true)
    .order('name')

  // Get accounts
  const { data: accounts } = await supabase
    .from('accounts')
    .select('*')
    .eq('organization_id', currentOrg.id)
    .eq('is_active', true)
    .order('name')

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">New Transaction</h1>
        <p className="text-gray-600 mt-1">
          Record a new income or expense transaction
        </p>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <TransactionForm
          organizationId={currentOrg.id}
          userId={user.id}
          categories={categories || []}
          accounts={accounts || []}
          currency={currentOrg.currency}
        />
      </div>
    </div>
  )
}
