'use client'

import { formatCurrency, formatDate } from '@/lib/utils'

interface BudgetListProps {
  budgets: any[]
  currency: string
}

export function BudgetList({ budgets, currency }: BudgetListProps) {
  if (budgets.length === 0) {
    return (
      <div className="bg-white rounded-lg border border-gray-200 p-12 text-center">
        <div className="text-gray-400 text-6xl mb-4">🎯</div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">
          No budgets created yet
        </h3>
        <p className="text-gray-600 mb-6">
          Start tracking your spending by creating a budget
        </p>
        <a
          href="/dashboard/budgets/new"
          className="inline-block bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700 transition-colors"
        >
          Create Budget
        </a>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {budgets.map((budget) => {
        const progress = (budget.spent_amount / budget.total_amount) * 100
        const isOverBudget = progress > 100
        const isNearLimit =
          progress >= budget.alert_threshold && progress <= 100

        return (
          <div
            key={budget.id}
            className="bg-white rounded-lg border border-gray-200 p-6"
          >
            <div className="flex items-start justify-between mb-4">
              <div>
                <h3 className="text-lg font-semibold text-gray-900">
                  {budget.name}
                </h3>
                <p className="text-sm text-gray-600 mt-1">
                  {formatDate(budget.start_date, 'short')} -{' '}
                  {formatDate(budget.end_date, 'short')}
                </p>
              </div>
              <span
                className={`px-2 py-1 text-xs font-medium rounded-full ${
                  budget.status === 'active'
                    ? 'bg-green-100 text-green-700'
                    : budget.status === 'completed'
                    ? 'bg-gray-100 text-gray-700'
                    : 'bg-yellow-100 text-yellow-700'
                }`}
              >
                {budget.status}
              </span>
            </div>

            {budget.description && (
              <p className="text-sm text-gray-600 mb-4">{budget.description}</p>
            )}

            <div className="space-y-4">
              {/* Overall Progress */}
              <div>
                <div className="flex items-center justify-between text-sm mb-2">
                  <span className="font-medium text-gray-700">
                    Overall Progress
                  </span>
                  <span
                    className={`font-semibold ${
                      isOverBudget
                        ? 'text-red-600'
                        : isNearLimit
                        ? 'text-yellow-600'
                        : 'text-green-600'
                    }`}
                  >
                    {progress.toFixed(1)}%
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-3">
                  <div
                    className={`h-3 rounded-full transition-all ${
                      isOverBudget
                        ? 'bg-red-600'
                        : isNearLimit
                        ? 'bg-yellow-500'
                        : 'bg-green-500'
                    }`}
                    style={{ width: `${Math.min(progress, 100)}%` }}
                  />
                </div>
              </div>

              {/* Amount Details */}
              <div className="flex items-center justify-between py-3 border-t border-gray-100">
                <div>
                  <p className="text-xs text-gray-500">Spent</p>
                  <p className="text-lg font-semibold text-gray-900">
                    {formatCurrency(budget.spent_amount, currency)}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-xs text-gray-500">Budget</p>
                  <p className="text-lg font-semibold text-gray-900">
                    {formatCurrency(budget.total_amount, currency)}
                  </p>
                </div>
              </div>

              {/* Remaining */}
              <div className="py-2 px-4 bg-gray-50 rounded-md">
                <p className="text-xs text-gray-500">Remaining</p>
                <p
                  className={`text-base font-semibold ${
                    isOverBudget ? 'text-red-600' : 'text-green-600'
                  }`}
                >
                  {formatCurrency(
                    Math.max(0, budget.total_amount - budget.spent_amount),
                    currency
                  )}
                </p>
              </div>

              {/* Categories Preview */}
              {budget.budget_categories &&
                budget.budget_categories.length > 0 && (
                  <div className="pt-3 border-t border-gray-100">
                    <p className="text-xs font-medium text-gray-500 uppercase mb-2">
                      Categories ({budget.budget_categories.length})
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {budget.budget_categories.slice(0, 3).map((bc: any) => (
                        <div
                          key={bc.id}
                          className="flex items-center gap-1 text-xs"
                        >
                          <div
                            className="w-2 h-2 rounded-full"
                            style={{ backgroundColor: bc.category?.color }}
                          />
                          <span className="text-gray-600">
                            {bc.category?.name}
                          </span>
                        </div>
                      ))}
                      {budget.budget_categories.length > 3 && (
                        <span className="text-xs text-gray-500">
                          +{budget.budget_categories.length - 3} more
                        </span>
                      )}
                    </div>
                  </div>
                )}

              {/* Actions */}
              <div className="flex gap-2 pt-2">
                <a
                  href={`/dashboard/budgets/${budget.id}`}
                  className="flex-1 text-center py-2 px-4 bg-blue-50 text-blue-600 rounded-md hover:bg-blue-100 transition-colors text-sm font-medium"
                >
                  View Details
                </a>
                <a
                  href={`/dashboard/budgets/${budget.id}/edit`}
                  className="flex-1 text-center py-2 px-4 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 transition-colors text-sm font-medium"
                >
                  Edit
                </a>
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}
