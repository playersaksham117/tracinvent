import { createClient } from '@/lib/supabase/server'
import { formatCurrency, formatDate } from '@/lib/utils'

interface RecentTransactionsProps {
  organizationId: string
}

export async function RecentTransactions({ organizationId }: RecentTransactionsProps) {
  const supabase = await createClient()

  const { data: transactions } = await supabase
    .from('transactions')
    .select(`
      *,
      category:categories(name, color),
      account:accounts(name)
    `)
    .eq('organization_id', organizationId)
    .eq('status', 'completed')
    .order('transaction_date', { ascending: false })
    .limit(5)

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">
        Recent Transactions
      </h3>

      {!transactions || transactions.length === 0 ? (
        <p className="text-gray-500 text-sm text-center py-8">
          No transactions yet. Create your first transaction to get started.
        </p>
      ) : (
        <div className="space-y-4">
          {transactions.map((transaction: any) => (
            <div
              key={transaction.id}
              className="flex items-center justify-between py-3 border-b border-gray-100 last:border-0"
            >
              <div className="flex items-center gap-3">
                <div
                  className="w-10 h-10 rounded-full flex items-center justify-center text-white text-sm font-medium"
                  style={{
                    backgroundColor: transaction.category?.color || '#6B7280',
                  }}
                >
                  {transaction.type === 'income' ? '↓' : '↑'}
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    {transaction.description || transaction.category?.name}
                  </p>
                  <p className="text-xs text-gray-500">
                    {formatDate(transaction.transaction_date, 'short')} • {transaction.account?.name}
                  </p>
                </div>
              </div>
              <div className="text-right">
                <p
                  className={`text-sm font-semibold ${
                    transaction.type === 'income'
                      ? 'text-green-600'
                      : 'text-red-600'
                  }`}
                >
                  {transaction.type === 'income' ? '+' : '-'}
                  {formatCurrency(transaction.amount, transaction.currency)}
                </p>
              </div>
            </div>
          ))}
        </div>
      )}

      <a
        href="/dashboard/transactions"
        className="block text-center text-sm text-blue-600 hover:text-blue-700 font-medium mt-4"
      >
        View All Transactions →
      </a>
    </div>
  )
}
