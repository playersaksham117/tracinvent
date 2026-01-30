import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { 
  ArrowRight, 
  CheckCircle2, 
  Zap, 
  Shield, 
  TrendingUp,
  Users,
  Calculator,
  Package,
  Star,
  Globe,
  Lock,
  Cloud,
  Smartphone,
  DollarSign,
  PieChart,
  MessageSquare,
  Monitor,
  Tablet,
  HardDrive
} from 'lucide-react'

export default function HomePage() {
  return (
    <div className="flex min-h-screen flex-col bg-gradient-to-b from-white to-slate-50">
      {/* Navigation */}
      <nav className="border-b bg-white/80 backdrop-blur-md sticky top-0 z-50 shadow-sm">
        <div className="container mx-auto px-4">
          <div className="flex h-16 items-center justify-between">
            <Link href="/" className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-500 bg-clip-text text-transparent">
              BillEase Suite
            </Link>
            
            <div className="hidden md:flex items-center space-x-8">
              <Link href="#features" className="text-sm font-medium text-slate-600 hover:text-primary transition-colors">
                Features
              </Link>
              <Link href="#pricing" className="text-sm font-medium text-slate-600 hover:text-primary transition-colors">
                Pricing
              </Link>
              <Link href="#about" className="text-sm font-medium text-slate-600 hover:text-primary transition-colors">
                About
              </Link>
            </div>

            <div className="flex items-center space-x-4">
              <Link href="/auth/signin">
                <Button variant="ghost" className="font-medium">Login</Button>
              </Link>
              <Link href="/auth/signup">
                <Button className="bg-gradient-to-r from-blue-600 to-cyan-500 hover:from-blue-700 hover:to-cyan-600 shadow-lg shadow-blue-500/30">
                  Get Started <ArrowRight className="ml-2 h-4 w-4" />
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="py-20 md:py-32 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-50 via-cyan-50 to-purple-50 opacity-70" />
        <div className="absolute inset-0 bg-grid-slate-900/[0.04] bg-[size:40px_40px]" />
        
        <div className="container mx-auto px-4 relative">
          <div className="max-w-5xl mx-auto text-center">
            <div className="inline-flex items-center px-4 py-2 bg-gradient-to-r from-blue-100 to-cyan-100 rounded-full text-blue-700 text-sm font-semibold mb-6 shadow-lg">
              <Star className="w-4 h-4 mr-2 fill-blue-600" />
              Smart Financial Management Made Simple
            </div>
            
            <h1 className="text-5xl md:text-7xl font-bold tracking-tight mb-6 leading-tight">
              All-in-One Business
              <span className="block mt-2 bg-gradient-to-r from-blue-600 via-cyan-500 to-purple-600 bg-clip-text text-transparent">
                Management Suite
              </span>
            </h1>
            
            <p className="text-xl md:text-2xl text-slate-600 mb-10 max-w-3xl mx-auto leading-relaxed">
              Powerful POS, Income/Expense Management, CRM, Accounting, and Inventory tools. 
              Everything you need to run your business efficiently, all in one platform.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 justify-center mb-8">
              <Link href="/demo">
                <Button size="lg" className="w-full sm:w-auto text-lg h-14 px-8 bg-gradient-to-r from-blue-600 to-cyan-500 hover:from-blue-700 hover:to-cyan-600 shadow-xl shadow-blue-500/30 transition-all hover:shadow-2xl hover:shadow-blue-500/40">
                  Try Demo <ArrowRight className="ml-2 h-5 w-5" />
                </Button>
              </Link>
              <Link href="/auth/signup">
                <Button size="lg" variant="outline" className="w-full sm:w-auto text-lg h-14 px-8 border-2 hover:bg-white hover:shadow-lg transition-all">
                  Start Free Trial
                </Button>
              </Link>
            </div>
            
            <p className="text-sm text-slate-500 flex items-center justify-center gap-2 flex-wrap">
              <CheckCircle2 className="w-4 h-4 text-green-500" />
              <span>No credit card required</span>
              <span className="text-slate-300">•</span>
              <span>14-day free trial</span>
              <span className="text-slate-300">•</span>
              <span>Cancel anytime</span>
            </p>
          </div>

          {/* Floating Elements */}
          <div className="hidden lg:block absolute top-1/4 left-10 animate-pulse">
            <div className="w-16 h-16 bg-gradient-to-br from-blue-400 to-cyan-400 rounded-2xl shadow-xl opacity-20" />
          </div>
          <div className="hidden lg:block absolute bottom-1/4 right-10 animate-pulse delay-700">
            <div className="w-20 h-20 bg-gradient-to-br from-purple-400 to-pink-400 rounded-2xl shadow-xl opacity-20" />
          </div>
        </div>
      </section>

      {/* Apps Showcase Section */}
      <section id="features" className="py-20 bg-white">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <div className="inline-flex items-center px-4 py-2 bg-blue-50 rounded-full text-blue-700 text-sm font-semibold mb-4">
              Complete Business Suite
            </div>
            <h2 className="text-4xl md:text-5xl font-bold mb-4">
              Choose Your App
            </h2>
            <p className="text-xl text-slate-600 max-w-2xl mx-auto">
              Each application designed to solve specific business needs. Authenticate once, access all.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 lg:gap-8 mb-12">
            {/* SpendSight Card - Income/Expense Management */}
            <Card className="group relative overflow-hidden border-2 hover:border-blue-500 transition-all duration-300 hover:shadow-2xl hover:-translate-y-2 bg-gradient-to-br from-white to-blue-50/30">
              <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-500/10 to-transparent rounded-bl-full" />
              <div className="p-6 relative">
                <div className="flex items-center justify-between mb-4">
                  <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-2xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform">
                    <DollarSign className="h-7 w-7 text-white" />
                  </div>
                  <div className="flex gap-1">
                    <span className="px-2 py-1 bg-green-100 text-green-700 text-xs font-semibold rounded-full">Web</span>
                    <span className="px-2 py-1 bg-purple-100 text-purple-700 text-xs font-semibold rounded-full">Mobile</span>
                  </div>
                </div>
                <h3 className="text-2xl font-bold mb-3 group-hover:text-blue-600 transition-colors">SpendSight</h3>
                <p className="text-slate-600 mb-4 leading-relaxed">
                  Smart income & expense management with budgeting, analytics, and multi-tenant support
                </p>
                <div className="flex items-center gap-2 mb-4 text-sm text-slate-500">
                  <MessageSquare className="h-4 w-4" />
                  <span>AI Chatbot Included</span>
                </div>
                <div className="flex gap-2">
                  <Link href="/demo/spendsight" className="flex-1">
                    <Button variant="outline" className="w-full border-2 border-blue-500 text-blue-600 hover:bg-blue-50">
                      Try Demo
                    </Button>
                  </Link>
                  <Link href="/auth/signup?app=spendsight" className="flex-1">
                    <Button className="w-full bg-gradient-to-r from-blue-500 to-cyan-500 hover:from-blue-600 hover:to-cyan-600">
                      Get Started
                    </Button>
                  </Link>
                </div>
              </div>
            </Card>

            {/* POS Card */}
            <Card className="group relative overflow-hidden border-2 hover:border-green-500 transition-all duration-300 hover:shadow-2xl hover:-translate-y-2 bg-gradient-to-br from-white to-green-50/30">
              <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-green-500/10 to-transparent rounded-bl-full" />
              <div className="p-6 relative">
                <div className="flex items-center justify-between mb-4">
                  <div className="w-14 h-14 bg-gradient-to-br from-green-500 to-emerald-500 rounded-2xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform">
                    <Zap className="h-7 w-7 text-white" />
                  </div>
                  <div className="flex gap-1">
                    <span className="px-2 py-1 bg-orange-100 text-orange-700 text-xs font-semibold rounded-full">Desktop</span>
                    <span className="px-2 py-1 bg-purple-100 text-purple-700 text-xs font-semibold rounded-full">Mobile</span>
                  </div>
                </div>
                <h3 className="text-2xl font-bold mb-3 group-hover:text-green-600 transition-colors">Point of Sale</h3>
                <p className="text-slate-600 mb-4 leading-relaxed">
                  Lightning-fast POS with receipt printing, cash management, and real-time reporting
                </p>
                <div className="flex items-center gap-2 mb-4 text-sm text-slate-500">
                  <HardDrive className="h-4 w-4" />
                  <span>Hardware Support</span>
                </div>
                <div className="flex gap-2">
                  <Link href="/demo/pos" className="flex-1">
                    <Button variant="outline" className="w-full border-2 border-green-500 text-green-600 hover:bg-green-50">
                      Try Demo
                    </Button>
                  </Link>
                  <Link href="/auth/signup?app=pos" className="flex-1">
                    <Button className="w-full bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600">
                      Get Started
                    </Button>
                  </Link>
                </div>
              </div>
            </Card>

            {/* CRM Card */}
            <Card className="group relative overflow-hidden border-2 hover:border-purple-500 transition-all duration-300 hover:shadow-2xl hover:-translate-y-2 bg-gradient-to-br from-white to-purple-50/30">
              <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-purple-500/10 to-transparent rounded-bl-full" />
              <div className="p-6 relative">
                <div className="flex items-center justify-between mb-4">
                  <div className="w-14 h-14 bg-gradient-to-br from-purple-500 to-pink-500 rounded-2xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform">
                    <Users className="h-7 w-7 text-white" />
                  </div>
                  <div className="flex gap-1">
                    <span className="px-2 py-1 bg-green-100 text-green-700 text-xs font-semibold rounded-full">Web</span>
                    <span className="px-2 py-1 bg-purple-100 text-purple-700 text-xs font-semibold rounded-full">Mobile</span>
                  </div>
                </div>
                <h3 className="text-2xl font-bold mb-3 group-hover:text-purple-600 transition-colors">CRM System</h3>
                <p className="text-slate-600 mb-4 leading-relaxed">
                  Manage customers, suppliers, leads, and track all interactions in one place
                </p>
                <div className="flex items-center gap-2 mb-4 text-sm text-slate-500">
                  <MessageSquare className="h-4 w-4" />
                  <span>AI Chatbot Included</span>
                </div>
                <div className="flex gap-2">
                  <Link href="/demo/crm" className="flex-1">
                    <Button variant="outline" className="w-full border-2 border-purple-500 text-purple-600 hover:bg-purple-50">
                      Try Demo
                    </Button>
                  </Link>
                  <Link href="/auth/signup?app=crm" className="flex-1">
                    <Button className="w-full bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600">
                      Get Started
                    </Button>
                  </Link>
                </div>
              </div>
            </Card>

            {/* Accounting Card */}
            <Card className="group relative overflow-hidden border-2 hover:border-indigo-500 transition-all duration-300 hover:shadow-2xl hover:-translate-y-2 bg-gradient-to-br from-white to-indigo-50/30">
              <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-indigo-500/10 to-transparent rounded-bl-full" />
              <div className="p-6 relative">
                <div className="flex items-center justify-between mb-4">
                  <div className="w-14 h-14 bg-gradient-to-br from-indigo-500 to-blue-500 rounded-2xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform">
                    <Calculator className="h-7 w-7 text-white" />
                  </div>
                  <div className="flex gap-1">
                    <span className="px-2 py-1 bg-green-100 text-green-700 text-xs font-semibold rounded-full">Web</span>
                    <span className="px-2 py-1 bg-orange-100 text-orange-700 text-xs font-semibold rounded-full">Desktop</span>
                  </div>
                </div>
                <h3 className="text-2xl font-bold mb-3 group-hover:text-indigo-600 transition-colors">Accounting</h3>
                <p className="text-slate-600 mb-4 leading-relaxed">
                  Complete accounting with journal entries, ledger, and financial statements
                </p>
                <div className="flex items-center gap-2 mb-4 text-sm text-slate-500">
                  <PieChart className="h-4 w-4" />
                  <span>Advanced Analytics</span>
                </div>
                <div className="flex gap-2">
                  <Link href="/demo/accounts" className="flex-1">
                    <Button variant="outline" className="w-full border-2 border-indigo-500 text-indigo-600 hover:bg-indigo-50">
                      Try Demo
                    </Button>
                  </Link>
                  <Link href="/auth/signup?app=accounts" className="flex-1">
                    <Button className="w-full bg-gradient-to-r from-indigo-500 to-blue-500 hover:from-indigo-600 hover:to-blue-600">
                      Get Started
                    </Button>
                  </Link>
                </div>
              </div>
            </Card>

            {/* Inventory Card */}
            <Card className="group relative overflow-hidden border-2 hover:border-orange-500 transition-all duration-300 hover:shadow-2xl hover:-translate-y-2 bg-gradient-to-br from-white to-orange-50/30">
              <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-orange-500/10 to-transparent rounded-bl-full" />
              <div className="p-6 relative">
                <div className="flex items-center justify-between mb-4">
                  <div className="w-14 h-14 bg-gradient-to-br from-orange-500 to-red-500 rounded-2xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform">
                    <Package className="h-7 w-7 text-white" />
                  </div>
                  <div className="flex gap-1">
                    <span className="px-2 py-1 bg-green-100 text-green-700 text-xs font-semibold rounded-full">Web</span>
                    <span className="px-2 py-1 bg-purple-100 text-purple-700 text-xs font-semibold rounded-full">Mobile</span>
                  </div>
                </div>
                <h3 className="text-2xl font-bold mb-3 group-hover:text-orange-600 transition-colors">Inventory</h3>
                <p className="text-slate-600 mb-4 leading-relaxed">
                  Track stock levels, movements, serial numbers across multiple locations
                </p>
                <div className="flex items-center gap-2 mb-4 text-sm text-slate-500">
                  <HardDrive className="h-4 w-4" />
                  <span>Barcode Scanner Support</span>
                </div>
                <div className="flex gap-2">
                  <Link href="/demo/inventory" className="flex-1">
                    <Button variant="outline" className="w-full border-2 border-orange-500 text-orange-600 hover:bg-orange-50">
                      Try Demo
                    </Button>
                  </Link>
                  <Link href="/auth/signup?app=inventory" className="flex-1">
                    <Button className="w-full bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600">
                      Get Started
                    </Button>
                  </Link>
                </div>
              </div>
            </Card>

            {/* More Apps Coming Soon */}
            <Card className="group relative overflow-hidden border-2 border-dashed border-slate-300 transition-all duration-300 bg-gradient-to-br from-white to-slate-50/30">
              <div className="p-6 relative flex flex-col items-center justify-center h-full text-center">
                <div className="w-14 h-14 bg-gradient-to-br from-slate-300 to-slate-400 rounded-2xl flex items-center justify-center mb-4 opacity-50">
                  <Star className="h-7 w-7 text-white" />
                </div>
                <h3 className="text-2xl font-bold mb-3 text-slate-600">More Apps</h3>
                <p className="text-slate-500 mb-4">
                  Additional apps coming soon. Stay tuned for updates!
                </p>
                <div className="text-sm text-slate-400">
                  Notify me when available
                </div>
              </div>
            </Card>
          </div>
        </div>
      </section>

      {/* Platform Support Section */}
      <section className="py-20 bg-gradient-to-b from-slate-50 to-white">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-4">
              Works On All Your Devices
            </h2>
            <p className="text-xl text-slate-600 max-w-2xl mx-auto">
              Access your business tools on web, mobile, or desktop. With hardware and AI support.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            {[
              {
                icon: Monitor,
                title: 'Web App',
                description: 'Access from any browser. No installation required.',
                color: 'from-blue-500 to-cyan-500'
              },
              {
                icon: Smartphone,
                title: 'Mobile App',
                description: 'iOS and Android apps for on-the-go access.',
                color: 'from-purple-500 to-pink-500'
              },
              {
                icon: Tablet,
                title: 'Desktop App',
                description: 'Native Windows, Mac, and Linux applications.',
                color: 'from-green-500 to-emerald-500'
              },
              {
                icon: MessageSquare,
                title: 'AI Chatbot',
                description: 'Smart assistant to help with queries and automation.',
                color: 'from-orange-500 to-red-500'
              }
            ].map((platform, i) => {
              const Icon = platform.icon
              return (
                <div key={i} className="text-center group">
                  <div className={`w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br ${platform.color} flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform`}>
                    <Icon className="w-8 h-8 text-white" />
                  </div>
                  <h3 className="text-xl font-bold mb-2">{platform.title}</h3>
                  <p className="text-slate-600">{platform.description}</p>
                </div>
              )
            })}
          </div>

          <div className="mt-16 text-center">
            <div className="inline-flex items-center gap-6 p-6 bg-white rounded-2xl shadow-xl border-2 border-slate-100">
              <HardDrive className="w-12 h-12 text-blue-600" />
              <div className="text-left">
                <h3 className="font-bold text-lg mb-1">Hardware Support</h3>
                <p className="text-slate-600">Barcode scanners, receipt printers, cash drawers & more</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Benefits Section */}
      <section className="py-20 bg-white">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-4">
              Why Choose Our Suite?
            </h2>
            <p className="text-xl text-slate-600 max-w-2xl mx-auto">
              Built for modern businesses who demand more from their software
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[
              {
                icon: Lock,
                title: 'Single Sign-On',
                description: 'One account, access all apps. Seamless authentication across the suite.',
              },
              {
                icon: Cloud,
                title: 'Cloud-Based',
                description: 'Access your data anywhere, anytime. Automatic backups and updates.',
              },
              {
                icon: Shield,
                title: 'Enterprise Security',
                description: 'Bank-level encryption and multi-tenant isolation for your data.',
              },
              {
                icon: TrendingUp,
                title: 'Real-Time Sync',
                description: 'All apps sync in real-time. Changes reflect instantly across platforms.',
              },
              {
                icon: Globe,
                title: 'Multi-Location',
                description: 'Manage multiple branches and locations from a single dashboard.',
              },
              {
                icon: CheckCircle2,
                title: 'Free Trial',
                description: '14-day free trial. No credit card required. Cancel anytime.',
              }
            ].map((benefit, i) => {
              const Icon = benefit.icon
              return (
                <div key={i} className="flex gap-4 group">
                  <div className="flex-shrink-0">
                    <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-cyan-500 flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform">
                      <Icon className="w-6 h-6 text-white" />
                    </div>
                  </div>
                  <div>
                    <h3 className="text-lg font-bold mb-2">{benefit.title}</h3>
                    <p className="text-slate-600">{benefit.description}</p>
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-600 via-cyan-500 to-purple-600" />
        <div className="absolute inset-0 bg-grid-white/[0.1] bg-[size:40px_40px]" />
        
        <div className="container mx-auto px-4 relative">
          <div className="max-w-4xl mx-auto text-center text-white">
            <h2 className="text-4xl md:text-5xl font-bold mb-6">
              Ready to Transform Your Business?
            </h2>
            <p className="text-xl mb-10 opacity-90">
              Join 10,000+ businesses already using BillEase Suite to streamline operations
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 justify-center mb-8">
              <Link href="/signup">
                <Button size="lg" className="w-full sm:w-auto text-lg h-14 px-8 bg-white text-blue-600 hover:bg-slate-50 shadow-xl">
                  Start Your Free Trial <ArrowRight className="ml-2 h-5 w-5" />
                </Button>
              </Link>
              <Link href="/contact">
                <Button size="lg" variant="outline" className="w-full sm:w-auto text-lg h-14 px-8 border-2 border-white text-white hover:bg-white/10">
                  Talk to Sales
                </Button>
              </Link>
            </div>
            
            <div className="flex items-center justify-center gap-6 text-sm">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-5 h-5" />
                <span>Free 14-day trial</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-5 h-5" />
                <span>No credit card</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-5 h-5" />
                <span>Cancel anytime</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-slate-900 text-slate-300 py-12">
        <div className="container mx-auto px-4">
          <div className="grid md:grid-cols-4 gap-8 mb-8">
            <div>
              <h3 className="text-white font-bold text-xl mb-4 bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent">
                BillEase
              </h3>
              <p className="text-sm leading-relaxed">
                All-in-one business management platform for modern businesses.
              </p>
            </div>
            
            <div>
              <h4 className="text-white font-semibold mb-4">Products</h4>
              <ul className="space-y-2 text-sm">
                <li><Link href="/products/pos" className="hover:text-white transition-colors">Point of Sale</Link></li>
                <li><Link href="/products/crm" className="hover:text-white transition-colors">CRM System</Link></li>
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
