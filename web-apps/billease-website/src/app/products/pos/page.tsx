import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { 
  ArrowRight, 
  ArrowLeft,
  Zap, 
  CheckCircle2,
  Smartphone,
  Cloud,
  Lock,
  BarChart3,
  ShoppingCart,
  Printer,
  CreditCard,
  Users,
  Package,
  TrendingUp,
  Clock,
  DollarSign
} from 'lucide-react'

export default function POSPage() {
  const features = [
    {
      icon: ShoppingCart,
      title: 'Quick Checkout',
      description: 'Lightning-fast sales processing with barcode scanning and product search'
    },
    {
      icon: Printer,
      title: 'Receipt Printing',
      description: 'Print or email receipts instantly with customizable templates'
    },
    {
      icon: CreditCard,
      title: 'Multiple Payments',
      description: 'Accept cash, card, mobile payments, and split payments'
    },
    {
      icon: Users,
      title: 'Customer Management',
      description: 'Track customer purchases and build loyalty programs'
    },
    {
      icon: Package,
      title: 'Inventory Sync',
      description: 'Real-time stock updates with every sale'
    },
    {
      icon: BarChart3,
      title: 'Sales Reports',
      description: 'Detailed analytics and reports for business insights'
    },
    {
      icon: Clock,
      title: 'Shift Management',
      description: 'Track cash drawer and manage multiple shifts'
    },
    {
      icon: DollarSign,
      title: 'Multi-Currency',
      description: 'Support for multiple currencies and tax configurations'
    }
  ]

  const pricing = [
    { name: 'Starter', price: '$29', features: ['1 Location', 'Up to 1,000 products', 'Basic reports', 'Email support'] },
    { name: 'Business', price: '$79', features: ['3 Locations', 'Unlimited products', 'Advanced analytics', 'Priority support'] },
    { name: 'Professional', price: '$149', features: ['Unlimited locations', 'API access', 'Custom integrations', '24/7 support'] }
  ]

  return (
    <div className="flex min-h-screen flex-col bg-gradient-to-b from-slate-50 to-white">
      {/* Navigation */}
      <nav className="border-b bg-white/80 backdrop-blur-md sticky top-0 z-50 shadow-sm">
        <div className="container mx-auto px-4">
          <div className="flex h-16 items-center justify-between">
            <Link href="/" className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-500 bg-clip-text text-transparent">
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
                <Button className="bg-gradient-to-r from-blue-600 to-cyan-500 hover:from-blue-700 hover:to-cyan-600 shadow-lg shadow-blue-500/30">
                  Get Started <ArrowRight className="ml-2 h-4 w-4" />
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="py-20 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-50 via-cyan-50 to-blue-100 opacity-70" />
        <div className="absolute inset-0 bg-grid-slate-900/[0.04] bg-[size:40px_40px]" />
        
        <div className="container mx-auto px-4 relative">
          <Link href="/products" className="inline-flex items-center text-blue-600 hover:text-blue-700 mb-6 group">
            <ArrowLeft className="w-4 h-4 mr-2 group-hover:-translate-x-1 transition-transform" />
            Back to Products
          </Link>

          <div className="max-w-5xl mx-auto">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-20 h-20 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-3xl flex items-center justify-center shadow-2xl">
                <Zap className="w-10 h-10 text-white" />
              </div>
              <div>
                <h1 className="text-5xl md:text-6xl font-bold">Point of Sale</h1>
                <p className="text-2xl text-blue-600 font-semibold mt-2">Lightning-fast sales processing</p>
              </div>
            </div>
            
            <p className="text-xl text-slate-600 mb-8 leading-relaxed max-w-3xl">
              Modern POS system designed for retail and hospitality businesses. Process sales quickly, 
              manage inventory, and delight customers with seamless checkout experiences.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 mb-8">
              <Link href="/signup">
                <Button size="lg" className="w-full sm:w-auto text-lg h-14 px-8 bg-gradient-to-r from-blue-600 to-cyan-500 hover:from-blue-700 hover:to-cyan-600 shadow-xl shadow-blue-500/30">
                  Start Free Trial <ArrowRight className="ml-2 h-5 w-5" />
                </Button>
              </Link>
              <Button size="lg" variant="outline" className="w-full sm:w-auto text-lg h-14 px-8 border-2">
                Watch Demo
              </Button>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {[
                { icon: Smartphone, text: 'Works on tablets' },
                { icon: Cloud, text: 'Cloud synced' },
                { icon: Lock, text: 'Secure payments' },
                { icon: BarChart3, text: 'Real-time reports' }
              ].map((item, i) => {
                const Icon = item.icon
                return (
                  <div key={i} className="flex items-center gap-2 text-sm text-slate-600">
                    <Icon className="w-5 h-5 text-blue-600" />
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
            <h2 className="text-4xl font-bold mb-4">Powerful Features</h2>
            <p className="text-xl text-slate-600">Everything you need to run your retail business</p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map((feature, i) => {
              const Icon = feature.icon
              return (
                <Card key={i} className="p-6 hover:shadow-xl transition-all hover:-translate-y-1">
                  <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-xl flex items-center justify-center mb-4">
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
              <Card key={i} className={`p-8 ${i === 1 ? 'border-2 border-blue-500 shadow-2xl scale-105' : ''}`}>
                {i === 1 && (
                  <div className="text-center mb-4">
                    <span className="bg-blue-500 text-white px-4 py-1 rounded-full text-sm font-semibold">
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
                  <Button className={`w-full ${i === 1 ? 'bg-gradient-to-r from-blue-600 to-cyan-500' : ''}`}>
                    Get Started
                  </Button>
                </Link>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 bg-gradient-to-br from-blue-600 to-cyan-500 text-white">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-4xl font-bold mb-4">Ready to boost your sales?</h2>
          <p className="text-xl mb-8 opacity-90">Start your 14-day free trial today</p>
          <Link href="/signup">
            <Button size="lg" className="bg-white text-blue-600 hover:bg-slate-50">
              Get Started Now <ArrowRight className="ml-2 h-5 w-5" />
            </Button>
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-slate-900 text-slate-300 py-12">
        <div className="container mx-auto px-4">
          <div className="text-center">
            <Link href="/" className="text-2xl font-bold bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent">
              BillEase
            </Link>
            <p className="mt-4 text-sm">&copy; 2026 BillEase Suite. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}
