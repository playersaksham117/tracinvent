'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

interface TransactionFormProps {
  organizationId: string
  userId: string
  categories: any[]
  accounts: any[]
  currency: string
}

export function TransactionForm({
  organizationId,
  userId,
  categories,
  accounts,
  currency,
}: TransactionFormProps) {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [formData, setFormData] = useState({
    type: 'expense' as 'income' | 'expense',
    amount: '',
    category_id: '',
    account_id: '',
    transaction_date: new Date().toISOString().split('T')[0],
    description: '',
    notes: '',
    payment_method: 'cash',
    status: 'completed',
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      const supabase = createClient()

      const { error: insertError } = await supabase.from('transactions').insert({
        organization_id: organizationId,
        created_by: userId,
        type: formData.type,
        amount: parseFloat(formData.amount),
        currency,
        category_id: formData.category_id || null,
        account_id: formData.account_id || null,
        transaction_date: formData.transaction_date,
        description: formData.description || null,
        notes: formData.notes || null,
        payment_method: formData.payment_method,
        status: formData.status,
      })

      if (insertError) throw insertError

      router.push('/dashboard/transactions')
      router.refresh()
    } catch (err: any) {
      setError(err.message || 'Failed to create transaction')
    } finally {
      setLoading(false)
    }
  }

  const incomeCategories = categories.filter((c) => c.type === 'income')
  const expenseCategories = categories.filter((c) => c.type === 'expense')
  const currentCategories =
    formData.type === 'income' ? incomeCategories : expenseCategories

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Type Toggle */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Transaction Type
        </label>
        <div className="grid grid-cols-2 gap-4">
          <button
            type="button"
            onClick={() => setFormData({ ...formData, type: 'income', category_id: '' })}
            className={`py-3 px-4 rounded-md border-2 font-medium transition-colors ${
              formData.type === 'income'
                ? 'border-green-600 bg-green-50 text-green-700'
                : 'border-gray-300 text-gray-700 hover:bg-gray-50'
            }`}
          >
            💰 Income
          </button>
          <button
            type="button"
            onClick={() => setFormData({ ...formData, type: 'expense', category_id: '' })}
            className={`py-3 px-4 rounded-md border-2 font-medium transition-colors ${
              formData.type === 'expense'
                ? 'border-red-600 bg-red-50 text-red-700'
                : 'border-gray-300 text-gray-700 hover:bg-gray-50'
            }`}
          >
            💸 Expense
          </button>
        </div>
      </div>

      {/* Amount */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Amount ({currency})
        </label>
        <input
          type="number"
          step="0.01"
          required
          value={formData.amount}
          onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          placeholder="0.00"
        />
      </div>

      {/* Date */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Date
        </label>
        <input
          type="date"
          required
          value={formData.transaction_date}
          onChange={(e) =>
            setFormData({ ...formData, transaction_date: e.target.value })
          }
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      {/* Category */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Category
        </label>
        <select
          value={formData.category_id}
          onChange={(e) =>
            setFormData({ ...formData, category_id: e.target.value })
          }
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">Select a category</option>
          {currentCategories.map((cat) => (
            <option key={cat.id} value={cat.id}>
              {cat.name}
            </option>
          ))}
        </select>
      </div>

      {/* Account */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Account
        </label>
        <select
          value={formData.account_id}
          onChange={(e) =>
            setFormData({ ...formData, account_id: e.target.value })
          }
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">Select an account</option>
          {accounts.map((acc) => (
            <option key={acc.id} value={acc.id}>
              {acc.name} ({acc.type})
            </option>
          ))}
        </select>
      </div>

      {/* Description */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Description
        </label>
        <input
          type="text"
          value={formData.description}
          onChange={(e) =>
            setFormData({ ...formData, description: e.target.value })
          }
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          placeholder="What was this transaction for?"
        />
      </div>

      {/* Notes */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Notes (Optional)
        </label>
        <textarea
          value={formData.notes}
          onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
          rows={3}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          placeholder="Add any additional details..."
        />
      </div>

      {/* Payment Method */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Payment Method
        </label>
        <select
          value={formData.payment_method}
          onChange={(e) =>
            setFormData({ ...formData, payment_method: e.target.value })
          }
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="cash">Cash</option>
          <option value="card">Card</option>
          <option value="upi">UPI</option>
          <option value="bank_transfer">Bank Transfer</option>
          <option value="cheque">Cheque</option>
          <option value="other">Other</option>
        </select>
      </div>

      {/* Buttons */}
      <div className="flex gap-4 pt-4">
        <button
          type="submit"
          disabled={loading}
          className="flex-1 bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {loading ? 'Creating...' : 'Create Transaction'}
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
