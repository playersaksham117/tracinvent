'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'

interface ExpenseChartProps {
  organizationId: string
}

export function ExpenseChart({ organizationId }: ExpenseChartProps) {
  const [data, setData] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchData() {
      const supabase = createClient()
      const today = new Date()
      const last30Days = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000)

      const { data: transactions } = await supabase
        .from('transactions')
        .select('amount, type, transaction_date, category:categories(name, color)')
        .eq('organization_id', organizationId)
        .eq('status', 'completed')
        .gte('transaction_date', last30Days.toISOString().split('T')[0])
        .order('transaction_date', { ascending: true })

      if (transactions) {
        // Group by category
        const grouped = transactions.reduce((acc: any, t: any) => {
          const category = t.category?.name || 'Uncategorized'
          if (!acc[category]) {
            acc[category] = {
              name: category,
              amount: 0,
              color: t.category?.color || '#6B7280',
            }
          }
          if (t.type === 'expense') {
            acc[category].amount += t.amount
          }
          return acc
        }, {})

        setData(Object.values(grouped))
      }

      setLoading(false)
    }

    fetchData()
  }, [organizationId])

  if (loading) {
    return (
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Expense Breakdown (Last 30 Days)
        </h3>
        <div className="h-64 flex items-center justify-center">
          <p className="text-gray-500">Loading...</p>
        </div>
      </div>
    )
  }

  const total = data.reduce((sum, item) => sum + item.amount, 0)

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">
        Expense Breakdown (Last 30 Days)
      </h3>

      {data.length === 0 ? (
        <div className="h-64 flex items-center justify-center">
          <p className="text-gray-500 text-sm">No expense data available</p>
        </div>
      ) : (
        <div className="space-y-3">
          {data.map((item) => {
            const percentage = ((item.amount / total) * 100).toFixed(1)
            return (
              <div key={item.name}>
                <div className="flex items-center justify-between text-sm mb-1">
                  <div className="flex items-center gap-2">
                    <div
                      className="w-3 h-3 rounded-full"
                      style={{ backgroundColor: item.color }}
                    />
                    <span className="font-medium text-gray-700">{item.name}</span>
                  </div>
                  <span className="text-gray-600">{percentage}%</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className="h-2 rounded-full"
                    style={{
                      width: `${percentage}%`,
                      backgroundColor: item.color,
                    }}
                  />
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
