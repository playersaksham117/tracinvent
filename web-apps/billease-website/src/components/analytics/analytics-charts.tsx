'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'

interface AnalyticsChartsProps {
  organizationId: string
  currency: string
}

export function AnalyticsCharts({ organizationId, currency }: AnalyticsChartsProps) {
  const [categoryData, setCategoryData] = useState<any[]>([])
  const [trendData, setTrendData] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchData() {
      const supabase = createClient()
      const today = new Date()
      const last6Months = new Date(today.getFullYear(), today.getMonth() - 6, 1)

      // Category breakdown
      const { data: transactions } = await supabase
        .from('transactions')
        .select('amount, type, category:categories(name, color)')
        .eq('organization_id', organizationId)
        .eq('status', 'completed')
        .gte('transaction_date', last6Months.toISOString().split('T')[0])

      if (transactions) {
        const grouped = transactions.reduce((acc: any, t: any) => {
          const key = `${t.type}-${t.category?.name || 'Uncategorized'}`
          if (!acc[key]) {
            acc[key] = {
              name: t.category?.name || 'Uncategorized',
              type: t.type,
              amount: 0,
              color: t.category?.color || '#6B7280',
            }
          }
          acc[key].amount += t.amount
          return acc
        }, {})

        setCategoryData(Object.values(grouped))
      }

      setLoading(false)
    }

    fetchData()
  }, [organizationId])

  if (loading) {
    return <div className="animate-pulse">Loading charts...</div>
  }

  const incomeData = categoryData.filter((d) => d.type === 'income')
  const expenseData = categoryData.filter((d) => d.type === 'expense')

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Income Breakdown */}
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Income by Category (Last 6 Months)
        </h3>
        {incomeData.length === 0 ? (
          <p className="text-gray-500 text-center py-12">No income data</p>
        ) : (
          <div className="space-y-3">
            {incomeData.map((item) => {
              const total = incomeData.reduce((sum, d) => sum + d.amount, 0)
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
                      className="h-2 rounded-full bg-green-500"
                      style={{ width: `${percentage}%` }}
                    />
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>

      {/* Expense Breakdown */}
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Expenses by Category (Last 6 Months)
        </h3>
        {expenseData.length === 0 ? (
          <p className="text-gray-500 text-center py-12">No expense data</p>
        ) : (
          <div className="space-y-3">
            {expenseData.map((item) => {
              const total = expenseData.reduce((sum, d) => sum + d.amount, 0)
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
    </div>
  )
}
