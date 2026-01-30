import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { 
  ArrowRight, 
  Zap, 
  Users, 
  Calculator, 
  Package,
  CheckCircle2,
  Smartphone,
  Cloud,
  Lock,
  BarChart3
} from 'lucide-react'

export default function ProductsPage() {
  const products = [
    {
      id: 'pos',
      name: 'Point of Sale',
      icon: Zap,
      tagline: 'Lightning-fast sales processing',
      description: 'Modern POS system designed for retail and hospitality businesses. Process sales quickly, manage inventory, and delight customers with seamless checkout experiences.',
      gradient: 'from-blue-600 to-cyan-500',
      features: [
        'Quick product lookup with barcode scanning',
        'Multiple payment methods (cash, card, mobile)',
        'Receipt printing & email receipts',
        'Real-time inventory updates',
        'Cash drawer management',
        'Sales analytics & reporting',
        'Multi-location support',
        'Customer display integration'
      ],
      capabilities: [
        { icon: Smartphone, text: 'Works on tablets & mobile' },
        { icon: Cloud, text: 'Cloud-based, always in sync' },
        { icon: Lock, text: 'Secure payment processing' },
        { icon: BarChart3, text: 'Real-time sales insights' }
      ]
    },
    {
      id: 'crm',
      name: 'Customer Relationship Management',
      icon: Users,
      tagline: 'Build lasting customer relationships',
      description: 'Comprehensive CRM to manage customers, suppliers, leads, and communications. Track interactions, close deals, and grow your business with data-driven insights.',
      gradient: 'from-purple-600 to-pink-500',
      features: [
        'Customer & supplier database',
        'Lead tracking & conversion',
        'Interaction history (calls, emails, meetings)',
        'Deal pipeline management',
        'Contact person management',
        'Sales forecasting',
        'Email & SMS campaigns',
        'Customer segmentation'
      ],
      capabilities: [
        { icon: Smartphone, text: 'Mobile CRM access' },
        { icon: Cloud, text: 'Centralized data hub' },
        { icon: Lock, text: 'Privacy compliant' },
        { icon: BarChart3, text: 'Conversion analytics' }
      ]
    },
    {
      id: 'accounts',
      name: 'Accounting & Finance',
      icon: Calculator,
      tagline: 'Professional bookkeeping made easy',
      description: 'Complete double-entry accounting system with automated posting, financial statements, and compliance features. Keep your books accurate and tax-ready.',
      gradient: 'from-green-600 to-emerald-500',
      features: [
        'Chart of accounts setup',
        'Journal entries & posting',
        'General ledger management',
        'Trial balance & financial reports',
        'Profit & loss statements',
        'Balance sheet generation',
        'Bank reconciliation',
        'Budget planning & tracking'
      ],
      capabilities: [
        { icon: Smartphone, text: 'Access anywhere' },
        { icon: Cloud, text: 'Automated backups' },
        { icon: Lock, text: 'Audit trail logging' },
        { icon: BarChart3, text: 'Financial insights' }
      ]
    },
    {
      id: 'inventory',
      name: 'Inventory Management',
      icon: Package,
      tagline: 'Track every item, everywhere',
      description: 'Multi-location inventory tracking with serial numbers, batch management, and automated stock alerts. Never run out of stock or lose track of your products.',
      gradient: 'from-orange-600 to-red-500',
      features: [
        'Multi-location stock tracking',
        'Serial number & batch tracking',
        'Stock movement history',
        'Purchase & sales orders',
        'Stock transfers between locations',
        'Low stock alerts & reordering',
        'Physical stock counts',
        'Expiry date management'
      ],
      capabilities: [
        { icon: Smartphone, text: 'Mobile stock takes' },
        { icon: Cloud, text: 'Real-time sync' },
        { icon: Lock, text: 'Access control' },
        { icon: BarChart3, text: 'Stock analytics' }
      ]
    }
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
      <section className="py-20 md:py-28 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50 opacity-50" />
        <div className="absolute inset-0 bg-grid-slate-900/[0.04] bg-[size:40px_40px]" />
        
        <div className="container mx-auto px-4 relative">
          <div className="max-w-4xl mx-auto text-center">
            <div className="inline-flex items-center px-4 py-2 bg-blue-100 rounded-full text-blue-700 text-sm font-semibold mb-6">
              <Zap className="w-4 h-4 mr-2" />
              Four Powerful Apps, One Platform
            </div>
            
            <h1 className="text-5xl md:text-7xl font-bold tracking-tight mb-6">
              Complete Business Suite
              <span className="block mt-2 bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
                Built for Growth
              </span>
            </h1>
            
            <p className="text-xl md:text-2xl text-slate-600 mb-10 max-w-3xl mx-auto leading-relaxed">
              Everything you need to manage sales, customers, finances, and inventory — 
              all seamlessly integrated and accessible from anywhere.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link href="/signup">
                <Button size="lg" className="w-full sm:w-auto text-lg h-14 px-8 bg-gradient-to-r from-blue-600 to-cyan-500 hover:from-blue-700 hover:to-cyan-600 shadow-xl shadow-blue-500/30">
                  Start Free Trial <ArrowRight className="ml-2 h-5 w-5" />
                </Button>
              </Link>
              <Link href="/pricing">
                <Button size="lg" variant="outline" className="w-full sm:w-auto text-lg h-14 px-8 border-2 hover:bg-slate-50">
                  View Pricing
                </Button>
              </Link>
            </div>
            
            <p className="mt-6 text-sm text-slate-500 flex items-center justify-center gap-2">
              <CheckCircle2 className="w-4 h-4 text-green-500" />
              14-day free trial • No credit card required • Cancel anytime
            </p>
          </div>
        </div>
      </section>

      {/* Products Grid */}
      <section className="py-20">
        <div className="container mx-auto px-4">
          {products.map((product, index) => {
            const Icon = product.icon
            return (
              <div 
                key={product.id}
                className={`mb-32 last:mb-0 ${index % 2 === 1 ? 'lg:flex-row-reverse' : ''}`}
              >
                <div className="grid lg:grid-cols-2 gap-12 items-center">
                  {/* Content */}
                  <div className={index % 2 === 1 ? 'lg:pl-12' : 'lg:pr-12'}>
                    <div className={`inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br ${product.gradient} shadow-lg mb-6`}>
                      <Icon className="w-8 h-8 text-white" />
                    </div>
                    
                    <h2 className="text-4xl md:text-5xl font-bold mb-4">
                      {product.name}
                    </h2>
                    
                    <p className="text-xl text-slate-600 mb-4">
                      {product.tagline}
                    </p>
                    
                    <p className="text-lg text-slate-600 mb-8 leading-relaxed">
                      {product.description}
                    </p>

                    {/* Capabilities */}
                    <div className="grid grid-cols-2 gap-4 mb-8">
                      {product.capabilities.map((capability, i) => {
                        const CapIcon = capability.icon
                        return (
                          <div key={i} className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-lg bg-slate-100 flex items-center justify-center flex-shrink-0">
                              <CapIcon className="w-5 h-5 text-slate-600" />
                            </div>
                            <span className="text-sm font-medium text-slate-700">
                              {capability.text}
                            </span>
                          </div>
                        )
                      })}
                    </div>

                    <Link href={`/products/${product.id}`}>
                      <Button 
                        size="lg" 
                        className={`bg-gradient-to-r ${product.gradient} hover:shadow-xl transition-all`}
                      >
                        Explore {product.name} <ArrowRight className="ml-2 h-5 w-5" />
                      </Button>
                    </Link>
                  </div>

                  {/* Features Card */}
                  <div>
                    <Card className="p-8 shadow-2xl border-0 bg-white">
                      <h3 className="text-2xl font-bold mb-6 flex items-center gap-3">
                        <div className={`w-2 h-2 rounded-full bg-gradient-to-r ${product.gradient}`} />
                        Key Features
                      </h3>
                      
                      <ul className="space-y-4">
                        {product.features.map((feature, i) => (
                          <li key={i} className="flex items-start gap-3 group">
                            <CheckCircle2 className={`w-5 h-5 mt-0.5 flex-shrink-0 bg-gradient-to-r ${product.gradient} bg-clip-text text-transparent`} />
                            <span className="text-slate-700 group-hover:text-slate-900 transition-colors">
                              {feature}
                            </span>
                          </li>
                        ))}
                      </ul>
                    </Card>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      </section>

      {/* Integration Section */}
      <section className="py-20 bg-gradient-to-br from-slate-900 to-slate-800 text-white relative overflow-hidden">
        <div className="absolute inset-0 bg-grid-white/[0.05] bg-[size:40px_40px]" />
        
        <div className="container mx-auto px-4 relative">
          <div className="max-w-4xl mx-auto text-center">
            <h2 className="text-4xl md:text-5xl font-bold mb-6">
              Seamlessly Integrated
            </h2>
            <p className="text-xl text-slate-300 mb-12">
              All four apps work together perfectly. Data flows automatically between POS, CRM, 
              Accounts, and Inventory — giving you a complete view of your business.
            </p>
            
            <div className="grid md:grid-cols-4 gap-6 mb-12">
              {[
                { icon: Zap, text: 'Real-time Sync' },
                { icon: Cloud, text: 'Cloud Based' },
                { icon: Lock, text: 'Bank-level Security' },
                { icon: BarChart3, text: 'Unified Analytics' }
              ].map((item, i) => {
                const ItemIcon = item.icon
                return (
                  <div key={i} className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
                    <ItemIcon className="w-8 h-8 mb-3 mx-auto text-cyan-400" />
                    <p className="font-semibold">{item.text}</p>
                  </div>
                )
              })}
            </div>

            <Link href="/signup">
              <Button 
                size="lg" 
                className="text-lg h-14 px-8 bg-white text-slate-900 hover:bg-slate-100"
              >
                Get Started Today <ArrowRight className="ml-2 h-5 w-5" />
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-slate-900 text-slate-300 py-12">
        <div className="container mx-auto px-4">
          <div className="grid md:grid-cols-4 gap-8 mb-8">
            <div>
              <h3 className="text-white font-bold text-xl mb-4">BillEase</h3>
              <p className="text-sm">
                All-in-one business management platform for modern businesses.
              </p>
            </div>
            
            <div>
              <h4 className="text-white font-semibold mb-4">Products</h4>
              <ul className="space-y-2 text-sm">
                <li><Link href="/products/pos" className="hover:text-white transition-colors">Point of Sale</Link></li>
                <li><Link href="/products/crm" className="hover:text-white transition-colors">CRM</Link></li>
                <li><Link href="/products/accounts" className="hover:text-white transition-colors">Accounting</Link></li>
                <li><Link href="/products/inventory" className="hover:text-white transition-colors">Inventory</Link></li>
              </ul>
            </div>
            
            <div>
              <h4 className="text-white font-semibold mb-4">Company</h4>
              <ul className="space-y-2 text-sm">
                <li><Link href="/about" className="hover:text-white transition-colors">About Us</Link></li>
                <li><Link href="/pricing" className="hover:text-white transition-colors">Pricing</Link></li>
                <li><Link href="/contact" className="hover:text-white transition-colors">Contact</Link></li>
              </ul>
            </div>
            
            <div>
              <h4 className="text-white font-semibold mb-4">Legal</h4>
              <ul className="space-y-2 text-sm">
                <li><Link href="/privacy" className="hover:text-white transition-colors">Privacy Policy</Link></li>
                <li><Link href="/terms" className="hover:text-white transition-colors">Terms of Service</Link></li>
              </ul>
            </div>
          </div>
          
          <div className="border-t border-slate-800 pt-8 text-center text-sm">
            <p>&copy; 2026 BillEase Suite. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}
