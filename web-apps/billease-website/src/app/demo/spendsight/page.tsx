import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { 
  ArrowLeft,
  DollarSign,
  TrendingUp,
  TrendingDown,
  PieChart,
  Calendar,
  CreditCard,
  Receipt
} from 'lucide-react'

export const metadata = {
  title: 'SpendSight Demo | BillEase Suite',
  description: 'Try SpendSight - Income & Expense Management',
}

export default function SpendSightDemoPage() {
  // Demo data
  const stats = [
    { label: 'Total Balance', value: '₹45,250', icon: DollarSign, color: 'text-blue-600', bg: 'bg-blue-50' },
    { label: 'Monthly Income', value: '₹85,000', icon: TrendingUp, color: 'text-green-600', bg: 'bg-green-50' },
    { label: 'Monthly Expenses', value: '₹39,750', icon: TrendingDown, color: 'text-red-600', bg: 'bg-red-50' },
    { label: 'Savings Rate', value: '53%', icon: PieChart, color: 'text-purple-600', bg: 'bg-purple-50' },
  ]

  const recentTransactions = [
    { id: 1, type: 'income', description: 'Salary', category: 'Salary', amount: 85000, date: '2026-01-01' },
    { id: 2, type: 'expense', description: 'Grocery Shopping', category: 'Food', amount: -3200, date: '2026-01-05' },
    { id: 3, type: 'expense', description: 'Electricity Bill', category: 'Bills', amount: -1500, date: '2026-01-06' },
    { id: 4, type: 'expense', description: 'Fuel', category: 'Transportation', amount: -2500, date: '2026-01-07' },
    { id: 5, type: 'income', description: 'Freelance Project', category: 'Freelancing', amount: 15000, date: '2026-01-08' },
  ]

  const budgets = [
    { category: 'Food', allocated: 10000, spent: 3200, color: 'bg-orange-500' },
    { category: 'Transportation', allocated: 5000, spent: 2500, color: 'bg-blue-500' },
    { category: 'Bills', allocated: 8000, spent: 1500, color: 'bg-purple-500' },
    { category: 'Entertainment', allocated: 3000, spent: 800, color: 'bg-pink-500' },
  ]

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">
      {/* Header */}
      <nav className="border-b bg-white/80 backdrop-blur-md sticky top-0 z-50 shadow-sm">
        <div className="container mx-auto px-4">
          <div className="flex h-16 items-center justify-between">
            <div className="flex items-center gap-4">
              <Link href="/" className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-500 bg-clip-text text-transparent">
                BillEase Suite
              </Link>
              <span className="px-3 py-1 bg-blue-100 text-blue-700 text-xs font-semibold rounded-full">
                DEMO MODE
              </span>
            </div>
            <div className="flex items-center gap-4">
              <Link href="/">
                <Button variant="ghost">
                  <ArrowLeft className="mr-2 h-4 w-4" />
                  Back to Home
                </Button>
              </Link>
              <Link href="/auth/signup?app=spendsight">
                <Button className="bg-gradient-to-r from-blue-600 to-cyan-500 hover:from-blue-700 hover:to-cyan-600">
                  Start Free Trial
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </nav>

      <div className="container mx-auto px-4 py-8">
        {/* Demo Banner */}
        <div className="bg-gradient-to-r from-blue-50 to-cyan-50 border-2 border-blue-200 rounded-lg p-6 mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 mb-2 flex items-center gap-3">
                <DollarSign className="h-8 w-8 text-blue-600" />
                SpendSight Demo
              </h1>
              <p className="text-gray-600">
                This is a demo with sample data. Sign up to start tracking your real finances!
              </p>
            </div>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {stats.map((stat, i) => {
            const Icon = stat.icon
            return (
              <Card key={i} className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <div className={`w-12 h-12 ${stat.bg} rounded-lg flex items-center justify-center`}>
                    <Icon className={`h-6 w-6 ${stat.color}`} />
                  </div>
                </div>
                <p className="text-sm text-gray-600 mb-1">{stat.label}</p>
                <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
              </Card>
            )
          })}
        </div>

        <div className="grid lg:grid-cols-3 gap-8 mb-8">
          {/* Recent Transactions */}
          <Card className="lg:col-span-2 p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
                <Receipt className="h-5 w-5" />
                Recent Transactions
              </h2>
              <Button variant="outline" size="sm" disabled>
                + Add Transaction
              </Button>
            </div>
            <div className="space-y-4">
              {recentTransactions.map((transaction) => (
                <div key={transaction.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                  <div className="flex items-center gap-4">
                    <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                      transaction.type === 'income' ? 'bg-green-100' : 'bg-red-100'
                    }`}>
                      {transaction.type === 'income' ? (
                        <TrendingUp className="h-5 w-5 text-green-600" />
                      ) : (
                        <TrendingDown className="h-5 w-5 text-red-600" />
                      )}
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900">{transaction.description}</p>
                      <p className="text-sm text-gray-600">{transaction.category} • {transaction.date}</p>
                    </div>
                  </div>
                  <p className={`font-bold ${transaction.type === 'income' ? 'text-green-600' : 'text-red-600'}`}>
                    {transaction.type === 'income' ? '+' : ''}₹{Math.abs(transaction.amount).toLocaleString('en-IN')}
                  </p>
                </div>
              ))}
            </div>
          </Card>

          {/* Budget Overview */}
          <Card className="p-6">
            <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center gap-2">
              <PieChart className="h-5 w-5" />
              Budget Overview
            </h2>
            <div className="space-y-4">
              {budgets.map((budget, i) => {
                const percentage = (budget.spent / budget.allocated) * 100
                return (
                  <div key={i}>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-medium text-gray-700">{budget.category}</span>
                      <span className="text-sm text-gray-600">
                        ₹{budget.spent.toLocaleString('en-IN')} / ₹{budget.allocated.toLocaleString('en-IN')}
                      </span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div
                        className={`${budget.color} h-2 rounded-full transition-all`}
                        style={{ width: `${Math.min(percentage, 100)}%` }}
                      />
                    </div>
                    <p className="text-xs text-gray-500 mt-1">{percentage.toFixed(0)}% used</p>
                  </div>
                )
              })}
            </div>
          </Card>
        </div>

        {/* Features Showcase */}
        <Card className="p-8 bg-gradient-to-r from-blue-50 to-cyan-50 border-2 border-blue-200">
          <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">Full Features Available in Paid Version</h2>
          <div className="grid md:grid-cols-3 gap-6">
            <div className="text-center">
              <div className="w-12 h-12 bg-blue-600 rounded-lg flex items-center justify-center mx-auto mb-3">
                <DollarSign className="h-6 w-6 text-white" />
              </div>
              <h3 className="font-bold mb-2">Multi-Tenant Support</h3>
              <p className="text-sm text-gray-600">Manage multiple organizations from one account</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-green-600 rounded-lg flex items-center justify-center mx-auto mb-3">
                <Calendar className="h-6 w-6 text-white" />
              </div>
              <h3 className="font-bold mb-2">Recurring Transactions</h3>
              <p className="text-sm text-gray-600">Automate your regular income and expenses</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-purple-600 rounded-lg flex items-center justify-center mx-auto mb-3">
                <CreditCard className="h-6 w-6 text-white" />
              </div>
              <h3 className="font-bold mb-2">Multiple Accounts</h3>
              <p className="text-sm text-gray-600">Track multiple bank accounts, cards, and wallets</p>
            </div>
          </div>
          <div className="text-center mt-8">
            <Link href="/auth/signup?app=spendsight">
              <Button size="lg" className="bg-gradient-to-r from-blue-600 to-cyan-500 hover:from-blue-700 hover:to-cyan-600">
                Start Free Trial - No Credit Card Required
              </Button>
            </Link>
          </div>
        </Card>
      </div>
    </div>
  )
}
