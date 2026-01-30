import { requireAuth, getCurrentUser } from '@/lib/auth/session'
import { getUserOrganizations } from '@/lib/organization'
import { createClient } from '@/lib/supabase/server'
import { TransactionList } from '@/components/transactions/transaction-list'
import { TransactionFilters } from '@/components/transactions/transaction-filters'
import Link from 'next/link'

export default async function TransactionsPage({
  searchParams,
}: {
  searchParams: { type?: string; category?: string; account?: string }
}) {
  await requireAuth()
  const user = await getCurrentUser()

  if (!user) return null

  const organizations = await getUserOrganizations(user.id)
  const currentOrg = organizations[0]

  if (!currentOrg) return null

  const supabase = await createClient()

  // Build query
  let query = supabase
    .from('transactions')
    .select(`
      *,
      category:categories(id, name, color, icon),
      account:accounts(id, name, type)
    `)
    .eq('organization_id', currentOrg.id)
    .order('transaction_date', { ascending: false })

  // Apply filters
  if (searchParams.type) {
    query = query.eq('type', searchParams.type)
  }
  if (searchParams.category) {
    query = query.eq('category_id', searchParams.category)
  }
  if (searchParams.account) {
    query = query.eq('account_id', searchParams.account)
  }

  const { data: transactions } = await query.limit(50)

  // Get categories and accounts for filters
  const { data: categories } = await supabase
    .from('categories')
    .select('*')
    .eq('organization_id', currentOrg.id)
    .eq('is_active', true)
    .order('name')

  const { data: accounts } = await supabase
    .from('accounts')
    .select('*')
    .eq('organization_id', currentOrg.id)
    .eq('is_active', true)
    .order('name')

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Transactions</h1>
          <p className="text-gray-600 mt-1">
            Track all your income and expenses
          </p>
        </div>
        <Link
          href="/dashboard/transactions/new"
          className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition-colors"
        >
          + New Transaction
        </Link>
      </div>

      <TransactionFilters
        categories={categories || []}
        accounts={accounts || []}
        currentFilters={searchParams}
      />

      <TransactionList
        transactions={transactions || []}
        currency={currentOrg.currency}
      />
    </div>
  )
}
