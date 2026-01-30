'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { formatCurrency } from '@/lib/utils'

interface AnalyticsStatsProps {
  organizationId: string
  currency: string
}

export function AnalyticsStats({ organizationId, currency }: AnalyticsStatsProps) {
  const [stats, setStats] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchStats() {
      const supabase = createClient()
      const today = new Date()
      
      // Current month
      const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1)
      const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0)
      
      // Last month
      const startOfLastMonth = new Date(today.getFullYear(), today.getMonth() - 1, 1)
      const endOfLastMonth = new Date(today.getFullYear(), today.getMonth(), 0)

      // Current month transactions
      const { data: currentMonthIncome } = await supabase
        .from('transactions')
        .select('amount')
        .eq('organization_id', organizationId)
        .eq('type', 'income')
        .eq('status', 'completed')
        .gte('transaction_date', startOfMonth.toISOString().split('T')[0])
        .lte('transaction_date', endOfMonth.toISOString().split('T')[0])

      const { data: currentMonthExpense } = await supabase
        .from('transactions')
        .select('amount')
        .eq('organization_id', organizationId)
        .eq('type', 'expense')
        .eq('status', 'completed')
        .gte('transaction_date', startOfMonth.toISOString().split('T')[0])
        .lte('transaction_date', endOfMonth.toISOString().split('T')[0])

      // Last month transactions
      const { data: lastMonthIncome } = await supabase
        .from('transactions')
        .select('amount')
        .eq('organization_id', organizationId)
        .eq('type', 'income')
        .eq('status', 'completed')
        .gte('transaction_date', startOfLastMonth.toISOString().split('T')[0])
        .lte('transaction_date', endOfLastMonth.toISOString().split('T')[0])

      const { data: lastMonthExpense } = await supabase
        .from('transactions')
        .select('amount')
        .eq('organization_id', organizationId)
        .eq('type', 'expense')
        .eq('status', 'completed')
        .gte('transaction_date', startOfLastMonth.toISOString().split('T')[0])
        .lte('transaction_date', endOfLastMonth.toISOString().split('T')[0])

      const currentIncome = currentMonthIncome?.reduce((sum, t) => sum + t.amount, 0) || 0
      const currentExpense = currentMonthExpense?.reduce((sum, t) => sum + t.amount, 0) || 0
      const lastIncome = lastMonthIncome?.reduce((sum, t) => sum + t.amount, 0) || 0
      const lastExpense = lastMonthExpense?.reduce((sum, t) => sum + t.amount, 0) || 0

      const incomeChange = lastIncome > 0 ? ((currentIncome - lastIncome) / lastIncome) * 100 : 0
      const expenseChange = lastExpense > 0 ? ((currentExpense - lastExpense) / lastExpense) * 100 : 0
      const netChange = currentIncome - currentExpense
      const savingsRate = currentIncome > 0 ? ((netChange / currentIncome) * 100).toFixed(1) : '0'

      setStats({
        currentIncome,
        currentExpense,
        incomeChange: incomeChange.toFixed(1),
        expenseChange: expenseChange.toFixed(1),
        netChange,
        savingsRate,
      })

      setLoading(false)
    }

    fetchStats()
  }, [organizationId])

  if (loading || !stats) {
    return <div className="animate-pulse">Loading stats...</div>
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <p className="text-sm font-medium text-gray-600">This Month Income</p>
        <p className="text-2xl font-bold text-gray-900 mt-2">
          {formatCurrency(stats.currentIncome, currency)}
        </p>
        <div className="flex items-center gap-1 mt-2">
          <span className={`text-sm ${parseFloat(stats.incomeChange) >= 0 ? 'text-green-600' : 'text-red-600'}`}>
            {parseFloat(stats.incomeChange) >= 0 ? '↑' : '↓'} {Math.abs(stats.incomeChange)}%
          </span>
          <span className="text-sm text-gray-500">vs last month</span>
        </div>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <p className="text-sm font-medium text-gray-600">This Month Expenses</p>
        <p className="text-2xl font-bold text-gray-900 mt-2">
          {formatCurrency(stats.currentExpense, currency)}
        </p>
        <div className="flex items-center gap-1 mt-2">
          <span className={`text-sm ${parseFloat(stats.expenseChange) >= 0 ? 'text-red-600' : 'text-green-600'}`}>
            {parseFloat(stats.expenseChange) >= 0 ? '↑' : '↓'} {Math.abs(stats.expenseChange)}%
          </span>
          <span className="text-sm text-gray-500">vs last month</span>
        </div>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <p className="text-sm font-medium text-gray-600">Net Cash Flow</p>
        <p className={`text-2xl font-bold mt-2 ${stats.netChange >= 0 ? 'text-green-600' : 'text-red-600'}`}>
          {formatCurrency(stats.netChange, currency)}
        </p>
        <p className="text-sm text-gray-500 mt-2">
          {stats.netChange >= 0 ? 'Positive' : 'Negative'} cash flow
        </p>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <p className="text-sm font-medium text-gray-600">Savings Rate</p>
        <p className="text-2xl font-bold text-gray-900 mt-2">{stats.savingsRate}%</p>
        <p className="text-sm text-gray-500 mt-2">
          Of total income
        </p>
      </div>
    </div>
  )
}
