'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

interface BudgetFormProps {
  organizationId: string
  userId: string
  categories: any[]
  currency: string
}

export function BudgetForm({
  organizationId,
  userId,
  categories,
  currency,
}: BudgetFormProps) {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [formData, setFormData] = useState({
    name: '',
    description: '',
    period_type: 'monthly' as 'monthly' | 'quarterly' | 'yearly' | 'custom',
    start_date: new Date().toISOString().split('T')[0],
    end_date: '',
    total_amount: '',
    alert_threshold: '80',
    alert_enabled: true,
    status: 'active',
  })

  const [categoryAllocations, setCategoryAllocations] = useState<
    Record<string, string>
  >({})

  // Auto-calculate end date based on period type
  const updateEndDate = (startDate: string, periodType: string) => {
    const start = new Date(startDate)
    let end = new Date(start)

    switch (periodType) {
      case 'monthly':
        end.setMonth(end.getMonth() + 1)
        break
      case 'quarterly':
        end.setMonth(end.getMonth() + 3)
        break
      case 'yearly':
        end.setFullYear(end.getFullYear() + 1)
        break
    }

    return end.toISOString().split('T')[0]
  }

  const handlePeriodChange = (periodType: string) => {
    const endDate =
      periodType !== 'custom'
        ? updateEndDate(formData.start_date, periodType)
        : formData.end_date

    setFormData({
      ...formData,
      period_type: periodType as any,
      end_date: endDate,
    })
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      const supabase = createClient()

      // Create budget
      const { data: budget, error: budgetError } = await supabase
        .from('budgets')
        .insert({
          organization_id: organizationId,
          created_by: userId,
          name: formData.name,
          description: formData.description || null,
          period_type: formData.period_type,
          start_date: formData.start_date,
          end_date: formData.end_date,
          total_amount: parseFloat(formData.total_amount),
          currency,
          alert_threshold: parseInt(formData.alert_threshold),
          alert_enabled: formData.alert_enabled,
          status: formData.status,
        })
        .select()
        .single()

      if (budgetError) throw budgetError

      // Create category allocations
      const allocations = Object.entries(categoryAllocations)
        .filter(([_, amount]) => amount && parseFloat(amount) > 0)
        .map(([categoryId, amount]) => ({
          budget_id: budget.id,
          category_id: categoryId,
          allocated_amount: parseFloat(amount),
        }))

      if (allocations.length > 0) {
        const { error: allocError } = await supabase
          .from('budget_categories')
          .insert(allocations)

        if (allocError) throw allocError
      }

      router.push('/dashboard/budgets')
      router.refresh()
    } catch (err: any) {
      setError(err.message || 'Failed to create budget')
    } finally {
      setLoading(false)
    }
  }

  const totalAllocated = Object.values(categoryAllocations).reduce(
    (sum, amount) => sum + (parseFloat(amount) || 0),
    0
  )

  const budgetAmount = parseFloat(formData.total_amount) || 0
  const remaining = budgetAmount - totalAllocated

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Basic Info */}
      <div className="space-y-4">
        <h3 className="text-lg font-medium text-gray-900">Basic Information</h3>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Budget Name
          </label>
          <input
            type="text"
            required
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="e.g., Monthly Household Budget"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Description (Optional)
          </label>
          <textarea
            value={formData.description}
            onChange={(e) =>
              setFormData({ ...formData, description: e.target.value })
            }
            rows={2}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Add budget details..."
          />
        </div>
      </div>

      {/* Period */}
      <div className="space-y-4 pt-6 border-t border-gray-200">
        <h3 className="text-lg font-medium text-gray-900">Budget Period</h3>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Period Type
          </label>
          <select
            value={formData.period_type}
            onChange={(e) => handlePeriodChange(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="monthly">Monthly</option>
            <option value="quarterly">Quarterly</option>
            <option value="yearly">Yearly</option>
            <option value="custom">Custom</option>
          </select>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Start Date
            </label>
            <input
              type="date"
              required
              value={formData.start_date}
              onChange={(e) => {
                const newStartDate = e.target.value
                const endDate =
                  formData.period_type !== 'custom'
                    ? updateEndDate(newStartDate, formData.period_type)
                    : formData.end_date
                setFormData({
                  ...formData,
                  start_date: newStartDate,
                  end_date: endDate,
                })
              }}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              End Date
            </label>
            <input
              type="date"
              required
              value={formData.end_date}
              onChange={(e) =>
                setFormData({ ...formData, end_date: e.target.value })
              }
              disabled={formData.period_type !== 'custom'}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
            />
          </div>
        </div>
      </div>

      {/* Amount */}
      <div className="space-y-4 pt-6 border-t border-gray-200">
        <h3 className="text-lg font-medium text-gray-900">Budget Amount</h3>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Total Budget ({currency})
          </label>
          <input
            type="number"
            step="0.01"
            required
            value={formData.total_amount}
            onChange={(e) =>
              setFormData({ ...formData, total_amount: e.target.value })
            }
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="0.00"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Alert Threshold (%)
          </label>
          <input
            type="number"
            min="1"
            max="100"
            value={formData.alert_threshold}
            onChange={(e) =>
              setFormData({ ...formData, alert_threshold: e.target.value })
            }
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <p className="text-xs text-gray-500 mt-1">
            You&apos;ll be alerted when spending reaches this percentage
          </p>
        </div>
      </div>

      {/* Category Allocations */}
      {budgetAmount > 0 && (
        <div className="space-y-4 pt-6 border-t border-gray-200">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-medium text-gray-900">
              Category Allocations (Optional)
            </h3>
            <div className="text-sm">
              <span className="text-gray-600">Remaining: </span>
              <span
                className={`font-semibold ${
                  remaining < 0 ? 'text-red-600' : 'text-green-600'
                }`}
              >
                {currency} {remaining.toFixed(2)}
              </span>
            </div>
          </div>

          <div className="space-y-3 max-h-96 overflow-y-auto">
            {categories.map((category) => (
              <div
                key={category.id}
                className="flex items-center gap-3 py-2 px-3 bg-gray-50 rounded-md"
              >
                <div
                  className="w-4 h-4 rounded-full"
                  style={{ backgroundColor: category.color }}
                />
                <span className="flex-1 text-sm font-medium text-gray-700">
                  {category.name}
                </span>
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  value={categoryAllocations[category.id] || ''}
                  onChange={(e) =>
                    setCategoryAllocations({
                      ...categoryAllocations,
                      [category.id]: e.target.value,
                    })
                  }
                  className="w-32 px-2 py-1 border border-gray-300 rounded text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="0.00"
                />
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Buttons */}
      <div className="flex gap-4 pt-6">
        <button
          type="submit"
          disabled={loading || (budgetAmount > 0 && remaining < 0)}
          className="flex-1 bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {loading ? 'Creating...' : 'Create Budget'}
        </button>
        <button
          type="button"
          onClick={() => router.back()}
          className="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 transition-colors"
        >
          Cancel
        </button>
      </div>
    </form>
  )
}
