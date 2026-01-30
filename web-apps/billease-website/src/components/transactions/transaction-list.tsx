'use client'

import { formatCurrency, formatDate } from '@/lib/utils'

interface TransactionListProps {
  transactions: any[]
  currency: string
}

export function TransactionList({ transactions, currency }: TransactionListProps) {
  if (transactions.length === 0) {
    return (
      <div className="bg-white rounded-lg border border-gray-200 p-12 text-center">
        <div className="text-gray-400 text-6xl mb-4">💰</div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">
          No transactions found
        </h3>
        <p className="text-gray-600 mb-6">
          Start by creating your first transaction
        </p>
        <a
          href="/dashboard/transactions/new"
          className="inline-block bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700 transition-colors"
        >
          Create Transaction
        </a>
      </div>
    )
  }

  return (
    <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Date
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Description
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Category
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Account
            </th>
            <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Amount
            </th>
            <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {transactions.map((transaction) => (
            <tr key={transaction.id} className="hover:bg-gray-50">
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {formatDate(transaction.transaction_date, 'short')}
              </td>
              <td className="px-6 py-4 text-sm text-gray-900">
                <div>
                  <p className="font-medium">
                    {transaction.description || 'No description'}
                  </p>
                  {transaction.notes && (
                    <p className="text-gray-500 text-xs mt-1">
                      {transaction.notes}
                    </p>
                  )}
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm">
                {transaction.category && (
                  <div className="flex items-center gap-2">
                    <div
                      className="w-3 h-3 rounded-full"
                      style={{ backgroundColor: transaction.category.color }}
                    />
                    <span className="text-gray-900">
                      {transaction.category.name}
                    </span>
                  </div>
                )}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                {transaction.account?.name || '-'}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-right font-medium">
                <span
                  className={
                    transaction.type === 'income'
                      ? 'text-green-600'
                      : 'text-red-600'
                  }
                >
                  {transaction.type === 'income' ? '+' : '-'}
                  {formatCurrency(transaction.amount, currency)}
                </span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-right text-sm">
                <a
                  href={`/dashboard/transactions/${transaction.id}`}
                  className="text-blue-600 hover:text-blue-700 mr-3"
                >
                  Edit
                </a>
                <button className="text-red-600 hover:text-red-700">
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
