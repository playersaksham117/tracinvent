import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { 
  ArrowRight, 
  ArrowLeft,
  Calculator, 
  CheckCircle2,
  Smartphone,
  Cloud,
  Lock,
  BarChart3,
  FileText,
  BookOpen,
  PieChart,
  Receipt,
  Banknote,
  TrendingUp,
  Calendar,
  Shield
} from 'lucide-react'

export default function AccountsPage() {
  const features = [
    {
      icon: BookOpen,
      title: 'Chart of Accounts',
      description: 'Flexible account structure with hierarchical organization'
    },
    {
      icon: FileText,
      title: 'Journal Entries',
      description: 'Double-entry bookkeeping with automated posting'
    },
    {
      icon: Receipt,
      title: 'General Ledger',
      description: 'Complete transaction history with audit trails'
    },
    {
      icon: PieChart,
      title: 'Financial Reports',
      description: 'Balance sheet, P&L, and cash flow statements'
    },
    {
      icon: Banknote,
      title: 'Bank Reconciliation',
      description: 'Match bank transactions with your records'
    },
    {
      icon: TrendingUp,
      title: 'Budget Planning',
      description: 'Create budgets and track actual vs planned'
    },
    {
      icon: Calendar,
      title: 'Fiscal Periods',
      description: 'Manage multiple fiscal years and periods'
    },
    {
      icon: Shield,
      title: 'Compliance Ready',
      description: 'Tax-ready reports and audit logs'
    }
  ]

  const pricing = [
    { name: 'Starter', price: '$29', features: ['1 Company', 'Basic reports', 'Email support', 'Mobile access'] },
    { name: 'Business', price: '$79', features: ['3 Companies', 'Advanced reports', 'Priority support', 'Multi-currency'] },
    { name: 'Professional', price: '$149', features: ['Unlimited companies', 'Custom reports', 'API access', 'Dedicated support'] }
  ]

  return (
    <div className="flex min-h-screen flex-col bg-gradient-to-b from-slate-50 to-white">
      {/* Navigation */}
      <nav className="border-b bg-white/80 backdrop-blur-md sticky top-0 z-50 shadow-sm">
        <div className="container mx-auto px-4">
          <div className="flex h-16 items-center justify-between">
            <Link href="/" className="text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-500 bg-clip-text text-transparent">
              BillEase
            </Link>
            
            <div className="hidden md:flex items-center space-x-8">
              <Link href="/products" className="text-sm font-semibold text-primary">
                Products
              </Link>
              <Link href="/pricing" className="text-sm font-medium text-slate-600 hover:text-primary transition-colors">
                Pricing
              </Link>
              <Link href="/about" className="text-sm font-medium text-slate-600 hover:text-primary transition-colors">
                About
              </Link>
              <Link href="/contact" className="text-sm font-medium text-slate-600 hover:text-primary transition-colors">
                Contact
              </Link>
            </div>

            <div className="flex items-center space-x-4">
              <Link href="/login">
                <Button variant="ghost" className="font-medium">Login</Button>
              </Link>
              <Link href="/signup">
                <Button className="bg-gradient-to-r from-green-600 to-emerald-500 hover:from-green-700 hover:to-emerald-600 shadow-lg shadow-green-500/30">
                  Get Started <ArrowRight className="ml-2 h-4 w-4" />
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="py-20 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-green-50 via-emerald-50 to-green-100 opacity-70" />
        <div className="absolute inset-0 bg-grid-slate-900/[0.04] bg-[size:40px_40px]" />
        
        <div className="container mx-auto px-4 relative">
          <Link href="/products" className="inline-flex items-center text-green-600 hover:text-green-700 mb-6 group">
            <ArrowLeft className="w-4 h-4 mr-2 group-hover:-translate-x-1 transition-transform" />
            Back to Products
          </Link>

          <div className="max-w-5xl mx-auto">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-20 h-20 bg-gradient-to-br from-green-500 to-emerald-500 rounded-3xl flex items-center justify-center shadow-2xl">
                <Calculator className="w-10 h-10 text-white" />
              </div>
              <div>
                <h1 className="text-5xl md:text-6xl font-bold">Accounting & Finance</h1>
                <p className="text-2xl text-green-600 font-semibold mt-2">Professional bookkeeping made easy</p>
              </div>
            </div>
            
            <p className="text-xl text-slate-600 mb-8 leading-relaxed max-w-3xl">
              Complete double-entry accounting system with automated posting, financial statements, 
              and compliance features. Keep your books accurate and tax-ready.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 mb-8">
              <Link href="/signup">
                <Button size="lg" className="w-full sm:w-auto text-lg h-14 px-8 bg-gradient-to-r from-green-600 to-emerald-500 hover:from-green-700 hover:to-emerald-600 shadow-xl shadow-green-500/30">
                  Start Free Trial <ArrowRight className="ml-2 h-5 w-5" />
                </Button>
              </Link>
              <Button size="lg" variant="outline" className="w-full sm:w-auto text-lg h-14 px-8 border-2">
                Watch Demo
              </Button>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {[
                { icon: Smartphone, text: 'Access anywhere' },
                { icon: Cloud, text: 'Auto backups' },
                { icon: Lock, text: 'Audit trails' },
                { icon: BarChart3, text: 'Financial insights' }
              ].map((item, i) => {
                const Icon = item.icon
                return (
                  <div key={i} className="flex items-center gap-2 text-sm text-slate-600">
                    <Icon className="w-5 h-5 text-green-600" />
                    <span>{item.text}</span>
                  </div>
                )
              })}
            </div>
          </div>
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-20 bg-white">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold mb-4">Comprehensive Accounting</h2>
            <p className="text-xl text-slate-600">All the tools you need for professional bookkeeping</p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map((feature, i) => {
              const Icon = feature.icon
              return (
                <Card key={i} className="p-6 hover:shadow-xl transition-all hover:-translate-y-1">
                  <div className="w-12 h-12 bg-gradient-to-br from-green-500 to-emerald-500 rounded-xl flex items-center justify-center mb-4">
                    <Icon className="w-6 h-6 text-white" />
                  </div>
                  <h3 className="text-lg font-bold mb-2">{feature.title}</h3>
                  <p className="text-slate-600 text-sm">{feature.description}</p>
                </Card>
              )
            })}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section className="py-20 bg-gradient-to-b from-slate-50 to-white">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold mb-4">Simple Pricing</h2>
            <p className="text-xl text-slate-600">Choose the plan that fits your business</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            {pricing.map((plan, i) => (
              <Card key={i} className={`p-8 ${i === 1 ? 'border-2 border-green-500 shadow-2xl scale-105' : ''}`}>
                {i === 1 && (
                  <div className="text-center mb-4">
                    <span className="bg-green-500 text-white px-4 py-1 rounded-full text-sm font-semibold">
                      Most Popular
                    </span>
                  </div>
                )}
                <h3 className="text-2xl font-bold mb-2">{plan.name}</h3>
                <div className="mb-6">
                  <span className="text-4xl font-bold">{plan.price}</span>
                  <span className="text-slate-600">/month</span>
                </div>
                <ul className="space-y-3 mb-8">
                  {plan.features.map((feature, j) => (
                    <li key={j} className="flex items-center gap-2">
                      <CheckCircle2 className="w-5 h-5 text-green-500" />
                      <span className="text-slate-600">{feature}</span>
                    </li>
                  ))}
                </ul>
                <Link href="/signup">
                  <Button className={`w-full ${i === 1 ? 'bg-gradient-to-r from-green-600 to-emerald-500' : ''}`}>
                    Get Started
                  </Button>
                </Link>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 bg-gradient-to-br from-green-600 to-emerald-500 text-white">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-4xl font-bold mb-4">Ready to simplify your accounting?</h2>
          <p className="text-xl mb-8 opacity-90">Start your 14-day free trial today</p>
          <Link href="/signup">
            <Button size="lg" className="bg-white text-green-600 hover:bg-slate-50">
              Get Started Now <ArrowRight className="ml-2 h-5 w-5" />
            </Button>
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-slate-900 text-slate-300 py-12">
        <div className="container mx-auto px-4">
          <div className="text-center">
            <Link href="/" className="text-2xl font-bold bg-gradient-to-r from-green-400 to-emerald-400 bg-clip-text text-transparent">
              BillEase
            </Link>
            <p className="mt-4 text-sm">&copy; 2026 BillEase Suite. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}
