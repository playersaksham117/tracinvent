import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { 
  ArrowRight,
  Zap,
  Users,
  Calculator,
  Package,
  TrendingUp,
  DollarSign,
  ShoppingBag,
  Activity,
  Star
} from 'lucide-react'

export default function DashboardPage() {
  const apps = [
    {
      id: 'pos',
      name: 'RT-POS',
      icon: Zap,
      description: 'Real-Time Point of Sale System',
      gradient: 'from-blue-500 to-cyan-500',
      bgGradient: 'from-blue-50 to-cyan-50',
      url: '/apps/pos',
      stats: { label: 'Today\'s Sales', value: '$2,450' }
    },
    {
      id: 'crm',
      name: 'EASECRM',
      icon: Users,
      description: 'Customer Relationship Management',
      gradient: 'from-purple-500 to-pink-500',
      bgGradient: 'from-purple-50 to-pink-50',
      url: '/apps/crm',
      stats: { label: 'Active Leads', value: '47' }
    },
    {
      id: 'accounts',
      name: 'ACCOUNTS+',
      icon: Calculator,
      description: 'Advanced Accounting & Finance',
      gradient: 'from-green-500 to-emerald-500',
      bgGradient: 'from-green-50 to-emerald-50',
      url: '/apps/accounts',
      stats: { label: 'This Month', value: '$18,920' }
    },
    {
      id: 'inventory',
      name: 'TRACINVENT',
      icon: Package,
      description: 'Inventory Tracking & Management',
      gradient: 'from-orange-500 to-red-500',
      bgGradient: 'from-orange-50 to-red-50',
      url: '/apps/inventory',
      stats: { label: 'Items in Stock', value: '1,234' }
    }
  ]

  const quickStats = [
    { label: 'Revenue', value: '$45,231', change: '+12.5%', icon: DollarSign, color: 'text-green-600' },
    { label: 'Orders', value: '356', change: '+8.2%', icon: ShoppingBag, color: 'text-blue-600' },
    { label: 'Customers', value: '2,340', change: '+15.3%', icon: Users, color: 'text-purple-600' },
    { label: 'Growth', value: '23.5%', change: '+4.1%', icon: TrendingUp, color: 'text-orange-600' }
  ]

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">
      {/* Navigation */}
      <nav className="border-b bg-white/80 backdrop-blur-md sticky top-0 z-50 shadow-sm">
        <div className="container mx-auto px-4">
          <div className="flex h-16 items-center justify-between">
            <Link href="/" className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-500 bg-clip-text text-transparent">
              BillEase
            </Link>
            
            <div className="hidden md:flex items-center space-x-6">
              <Link href="/dashboard" className="text-sm font-semibold text-primary">
                Dashboard
              </Link>
              <Link href="/products" className="text-sm font-medium text-slate-600 hover:text-primary transition-colors">
                Products
              </Link>
              <Link href="/pricing" className="text-sm font-medium text-slate-600 hover:text-primary transition-colors">
                Pricing
              </Link>
            </div>

            <div className="flex items-center space-x-4">
              <div className="hidden md:flex items-center gap-2 px-3 py-1.5 bg-blue-50 rounded-full">
                <Star className="w-4 h-4 text-blue-600 fill-blue-600" />
                <span className="text-sm font-medium text-blue-700">Demo Account</span>
              </div>
              <Link href="/api/auth/logout">
                <Button variant="ghost" size="sm">Logout</Button>
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <div className="container mx-auto px-4 py-8">
        {/* Welcome Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold mb-2">Welcome back, Demo User! 👋</h1>
          <p className="text-xl text-slate-600">Here's what's happening with your business today</p>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {quickStats.map((stat, i) => {
            const Icon = stat.icon
            return (
              <Card key={i} className="p-6 hover:shadow-lg transition-shadow">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-slate-600">{stat.label}</span>
                  <Icon className={`w-5 h-5 ${stat.color}`} />
                </div>
                <div className="flex items-end justify-between">
                  <span className="text-3xl font-bold">{stat.value}</span>
                  <span className="text-sm font-medium text-green-600">{stat.change}</span>
                </div>
              </Card>
            )
          })}
        </div>

        {/* Your Apps */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold">Your Applications</h2>
            <Link href="/products">
              <Button variant="outline">
                View All Products <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {apps.map((app) => {
              const Icon = app.icon
              return (
                <Card key={app.id} className={`relative overflow-hidden hover:shadow-xl transition-all group`}>
                  <div className={`absolute inset-0 bg-gradient-to-br ${app.bgGradient} opacity-50 group-hover:opacity-70 transition-opacity`} />
                  
                  <div className="relative p-6">
                    <div className="flex items-start justify-between mb-4">
                      <div className={`w-14 h-14 rounded-2xl bg-gradient-to-br ${app.gradient} flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform`}>
                        <Icon className="w-7 h-7 text-white" />
                      </div>
                      <Link href={app.url}>
                        <Button size="sm" className={`bg-gradient-to-r ${app.gradient}`}>
                          Open App
                        </Button>
                      </Link>
                    </div>
                    
                    <h3 className="text-2xl font-bold mb-2">{app.name}</h3>
                    <p className="text-slate-600 mb-4">{app.description}</p>
                    
                    <div className="flex items-center justify-between pt-4 border-t border-slate-200">
                      <span className="text-sm text-slate-500">{app.stats.label}</span>
                      <span className="text-lg font-bold">{app.stats.value}</span>
                    </div>
                  </div>
                </Card>
              )
            })}
          </div>
        </div>

        {/* Recent Activity */}
        <Card className="p-6">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
              <Activity className="w-5 h-5 text-blue-600" />
            </div>
            <h2 className="text-2xl font-bold">Recent Activity</h2>
          </div>
          
          <div className="space-y-4">
            {[
              { action: 'Sale completed', detail: 'Invoice #1234 - $245.00', time: '5 minutes ago', color: 'blue' },
              { action: 'New customer added', detail: 'John Smith - ABC Corp', time: '15 minutes ago', color: 'purple' },
              { action: 'Stock updated', detail: 'Product A - Qty: 50 units', time: '1 hour ago', color: 'orange' },
              { action: 'Payment received', detail: 'Invoice #1233 - $890.00', time: '2 hours ago', color: 'green' }
            ].map((activity, i) => (
              <div key={i} className="flex items-center gap-4 p-4 bg-slate-50 rounded-lg hover:bg-slate-100 transition-colors">
                <div className={`w-2 h-2 rounded-full bg-${activity.color}-500`} />
                <div className="flex-1">
                  <p className="font-semibold text-slate-900">{activity.action}</p>
                  <p className="text-sm text-slate-600">{activity.detail}</p>
                </div>
                <span className="text-sm text-slate-500">{activity.time}</span>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  )
}
