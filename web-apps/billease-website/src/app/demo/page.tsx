import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { 
  ArrowLeft,
  ArrowRight,
  DollarSign,
  Zap,
  Users,
  Calculator,
  Package,
  CheckCircle2
} from 'lucide-react'

export const metadata = {
  title: 'Try Demo | BillEase Suite',
  description: 'Experience BillEase Suite with interactive demos',
}

export default function DemoPage() {
  const apps = [
    {
      name: 'SpendSight',
      description: 'Smart income & expense management with budgeting and analytics',
      icon: DollarSign,
      color: 'from-blue-500 to-cyan-500',
      href: '/demo/spendsight',
      available: true
    },
    {
      name: 'Point of Sale',
      description: 'Lightning-fast POS with receipt printing and cash management',
      icon: Zap,
      color: 'from-green-500 to-emerald-500',
      href: '/demo/pos',
      available: false
    },
    {
      name: 'CRM System',
      description: 'Manage customers, suppliers, leads, and interactions',
      icon: Users,
      color: 'from-purple-500 to-pink-500',
      href: '/demo/crm',
      available: false
    },
    {
      name: 'Accounting',
      description: 'Complete accounting with journal entries and financial statements',
      icon: Calculator,
      color: 'from-indigo-500 to-blue-500',
      href: '/demo/accounts',
      available: false
    },
    {
      name: 'Inventory',
      description: 'Track stock levels, movements, and serial numbers',
      icon: Package,
      color: 'from-orange-500 to-red-500',
      href: '/demo/inventory',
      available: false
    }
  ]

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">
      {/* Header */}
      <nav className="border-b bg-white/80 backdrop-blur-md sticky top-0 z-50 shadow-sm">
        <div className="container mx-auto px-4">
          <div className="flex h-16 items-center justify-between">
            <Link href="/" className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-500 bg-clip-text text-transparent">
              BillEase Suite
            </Link>
            <div className="flex items-center gap-4">
              <Link href="/">
                <Button variant="ghost">
                  <ArrowLeft className="mr-2 h-4 w-4" />
                  Back to Home
                </Button>
              </Link>
              <Link href="/auth/signup">
                <Button className="bg-gradient-to-r from-blue-600 to-cyan-500 hover:from-blue-700 hover:to-cyan-600">
                  Start Free Trial
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </nav>

      <div className="container mx-auto px-4 py-16">
        {/* Hero Section */}
        <div className="text-center mb-16">
          <div className="inline-flex items-center px-4 py-2 bg-blue-50 rounded-full text-blue-700 text-sm font-semibold mb-6">
            No Credit Card Required • No Installation
          </div>
          <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6">
            Try Our Apps <span className="bg-gradient-to-r from-blue-600 to-cyan-500 bg-clip-text text-transparent">Risk-Free</span>
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Experience the power of BillEase Suite with interactive demos. No signup required.
          </p>
        </div>

        {/* Apps Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 mb-16">
          {apps.map((app, i) => {
            const Icon = app.icon
            return (
              <Card key={i} className={`group relative overflow-hidden border-2 transition-all duration-300 hover:shadow-2xl hover:-translate-y-2 ${
                app.available ? 'hover:border-blue-500' : 'opacity-60'
              }`}>
                <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-500/10 to-transparent rounded-bl-full" />
                <div className="p-6 relative">
                  <div className="flex items-center justify-between mb-4">
                    <div className={`w-14 h-14 bg-gradient-to-br ${app.color} rounded-2xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform`}>
                      <Icon className="h-7 w-7 text-white" />
                    </div>
                    {app.available && (
                      <span className="px-3 py-1 bg-green-100 text-green-700 text-xs font-semibold rounded-full flex items-center gap-1">
                        <CheckCircle2 className="h-3 w-3" />
                        Available
                      </span>
                    )}
                    {!app.available && (
                      <span className="px-3 py-1 bg-gray-100 text-gray-600 text-xs font-semibold rounded-full">
                        Coming Soon
                      </span>
                    )}
                  </div>
                  <h3 className="text-2xl font-bold mb-3 text-gray-900">{app.name}</h3>
                  <p className="text-gray-600 mb-6 leading-relaxed">
                    {app.description}
                  </p>
                  {app.available ? (
                    <Link href={app.href}>
                      <Button className="w-full bg-gradient-to-r from-blue-600 to-cyan-500 hover:from-blue-700 hover:to-cyan-600">
                        Try Demo <ArrowRight className="ml-2 h-4 w-4" />
                      </Button>
                    </Link>
                  ) : (
                    <Button className="w-full" variant="outline" disabled>
                      Demo Coming Soon
                    </Button>
                  )}
                </div>
              </Card>
            )
          })}
        </div>

        {/* Features Section */}
        <Card className="p-8 bg-gradient-to-r from-blue-50 to-cyan-50 border-2 border-blue-200">
          <h2 className="text-3xl font-bold text-gray-900 mb-8 text-center">What You'll Get with Full Access</h2>
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              'Multi-tenant organization support',
              'Real-time data synchronization',
              'Advanced analytics & reports',
              'Mobile & desktop apps',
              'Hardware integration (POS)',
              'AI chatbot assistance',
              'Recurring transactions',
              'Data export & import',
              'Email notifications',
              'Priority support',
              'Custom integrations',
              'Regular feature updates'
            ].map((feature, i) => (
              <div key={i} className="flex items-center gap-3">
                <CheckCircle2 className="h-5 w-5 text-green-600 flex-shrink-0" />
                <span className="text-gray-700">{feature}</span>
              </div>
            ))}
          </div>
          <div className="text-center mt-8">
            <Link href="/auth/signup">
              <Button size="lg" className="bg-gradient-to-r from-blue-600 to-cyan-500 hover:from-blue-700 hover:to-cyan-600 text-lg px-8">
                Start 14-Day Free Trial
              </Button>
            </Link>
            <p className="text-sm text-gray-600 mt-4">No credit card required • Cancel anytime</p>
          </div>
        </Card>
      </div>
    </div>
  )
}
