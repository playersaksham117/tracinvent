'use client'

import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { ArrowLeft, Calculator, TrendingUp, DollarSign, FileText } from 'lucide-react'

export default function AccountsAppPage() {
  return (
    <div className="min-h-screen bg-slate-50">
      <div className="bg-white border-b sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center gap-4">
            <Link href="/dashboard">
              <Button variant="ghost" size="sm">
                <ArrowLeft className="w-4 h-4 mr-2" />
                Back to Dashboard
              </Button>
            </Link>
            <h1 className="text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-500 bg-clip-text text-transparent">
              ACCOUNTS+ • Advanced Accounting
            </h1>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-600">Total Revenue</span>
              <DollarSign className="w-5 h-5 text-green-600" />
            </div>
            <p className="text-3xl font-bold text-green-600">$45,231</p>
            <p className="text-sm text-green-600">+12.5% from last month</p>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-600">Expenses</span>
              <TrendingUp className="w-5 h-5 text-red-600" />
            </div>
            <p className="text-3xl font-bold text-red-600">$18,420</p>
            <p className="text-sm text-slate-500">+5.2% from last month</p>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-600">Net Profit</span>
              <Calculator className="w-5 h-5 text-blue-600" />
            </div>
            <p className="text-3xl font-bold text-blue-600">$26,811</p>
            <p className="text-sm text-blue-600">+15.8% margin</p>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-600">Invoices</span>
              <FileText className="w-5 h-5 text-purple-600" />
            </div>
            <p className="text-3xl font-bold text-purple-600">156</p>
            <p className="text-sm text-slate-500">23 pending</p>
          </Card>
        </div>

        <Card className="p-8 text-center">
          <Calculator className="w-16 h-16 text-green-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold mb-2">ACCOUNTS+ Module</h2>
          <p className="text-slate-600 mb-6">
            Advanced accounting features including:
            <br />
            Chart of Accounts, Journal Entries, Financial Reports, Tax Management, and more.
          </p>
          <div className="inline-flex gap-3">
            <Button className="bg-gradient-to-r from-green-600 to-emerald-500">
              View Reports
            </Button>
            <Button variant="outline">Manage Accounts</Button>
          </div>
        </Card>
      </div>
    </div>
  )
}
