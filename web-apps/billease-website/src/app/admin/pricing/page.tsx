'use client'

import { useState, useEffect, useCallback } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { 
  DollarSign, 
  Save, 
  Plus, 
  Trash2,
  Check,
  Edit,
  X,
  Monitor,
  Globe,
  Percent,
  Loader2
} from 'lucide-react'
import { fetchPricing, updatePricingItem, createPricingItem, deletePricingItem } from '@/lib/admin/api'
import type { PricingPlan, DesktopProductPricing, DiscountCode } from '@/types/database.types'

interface LocalPricingPlan {
  id: string
  name: string
  description: string
  monthlyPrice: number
  yearlyPrice: number
  features: string[]
  isPopular: boolean
  maxUsers: number
  maxLicenses: number
  isActive: boolean
}

interface LocalDesktopPrice {
  id: string
  product: string
  productCode: string
  perpetualPrice: number
  subscriptionMonthly: number
  subscriptionYearly: number
  isActive: boolean
}

interface LocalDiscount {
  id: string
  code: string
  name: string
  type: 'percentage' | 'fixed'
  value: number
  maxUses: number
  usedCount: number
  expiresAt: string | null
  isActive: boolean
  applicableTo: 'all' | 'web' | 'desktop'
}

export default function PricingSettingsPage() {
  const [activeTab, setActiveTab] = useState<'web' | 'desktop' | 'discounts'>('web')
  const [loading, setLoading] = useState(true)
  const [isSaving, setIsSaving] = useState(false)
  const [editingPlan, setEditingPlan] = useState<string | null>(null)

  // Web subscription plans
  const [plans, setPlans] = useState<LocalPricingPlan[]>([])
  // Desktop license pricing
  const [desktopPrices, setDesktopPrices] = useState<LocalDesktopPrice[]>([])
  // Discount codes
  const [discounts, setDiscounts] = useState<LocalDiscount[]>([])

  // Track unsaved changes
  const [hasChanges, setHasChanges] = useState(false)

  const mapPricingPlan = (plan: PricingPlan): LocalPricingPlan => ({
    id: plan.id,
    name: plan.name,
    description: plan.description || '',
    monthlyPrice: plan.monthly_price,
    yearlyPrice: plan.yearly_price,
    features: plan.features || [],
    isPopular: plan.is_popular,
    maxUsers: plan.max_users,
    maxLicenses: plan.max_licenses,
    isActive: plan.is_active
  })

  const mapDesktopPrice = (price: DesktopProductPricing): LocalDesktopPrice => ({
    id: price.id,
    product: price.product,
    productCode: price.product_code,
    perpetualPrice: price.perpetual_price,
    subscriptionMonthly: price.subscription_monthly,
    subscriptionYearly: price.subscription_yearly,
    isActive: price.is_active
  })

  const mapDiscount = (discount: DiscountCode): LocalDiscount => ({
    id: discount.id,
    code: discount.code,
    name: discount.name,
    type: discount.discount_type,
    value: discount.discount_value,
    maxUses: discount.max_uses,
    usedCount: discount.used_count,
    expiresAt: discount.valid_until || null,
    isActive: discount.is_active,
    applicableTo: discount.applicable_to
  })

  const loadPricing = useCallback(async () => {
    setLoading(true)
    try {
      const response = await fetchPricing()
      setPlans(response.plans.map(mapPricingPlan))
      setDesktopPrices(response.desktopPricing.map(mapDesktopPrice))
      setDiscounts(response.discounts.map(mapDiscount))
    } catch (error) {
      console.error('Failed to fetch pricing:', error)
      // Fallback to default mock data
      setPlans([
        { id: 'starter', name: 'Starter', description: 'Perfect for small businesses getting started', monthlyPrice: 9, yearlyPrice: 90, features: ['Up to 100 transactions/month', 'Basic reports', 'Email support', '1 user'], isPopular: false, maxUsers: 1, maxLicenses: 1, isActive: true },
        { id: 'pro', name: 'Pro', description: 'For growing businesses that need more power', monthlyPrice: 29, yearlyPrice: 290, features: ['Unlimited transactions', 'Advanced reports', 'Priority support', 'Up to 5 users', 'API access', 'Desktop app'], isPopular: true, maxUsers: 5, maxLicenses: 3, isActive: true },
        { id: 'enterprise', name: 'Enterprise', description: 'For large organizations with custom needs', monthlyPrice: 199, yearlyPrice: 1990, features: ['Everything in Pro', 'Unlimited users', 'Custom integrations', 'Dedicated support', 'SLA guarantee', 'On-premise option'], isPopular: false, maxUsers: -1, maxLicenses: 25, isActive: true },
      ])
      setDesktopPrices([
        { id: '1', product: 'BillEase POS', productCode: 'BE-POS', perpetualPrice: 299, subscriptionMonthly: 19, subscriptionYearly: 190, isActive: true },
        { id: '2', product: 'BillEase Inventory', productCode: 'BE-INV', perpetualPrice: 249, subscriptionMonthly: 15, subscriptionYearly: 150, isActive: true },
        { id: '3', product: 'BillEase Accounts', productCode: 'BE-ACC', perpetualPrice: 349, subscriptionMonthly: 25, subscriptionYearly: 250, isActive: true },
        { id: '4', product: 'BillEase CRM', productCode: 'BE-CRM', perpetualPrice: 199, subscriptionMonthly: 12, subscriptionYearly: 120, isActive: true },
        { id: '5', product: 'BillEase Suite (All Apps)', productCode: 'BE-SUITE', perpetualPrice: 799, subscriptionMonthly: 59, subscriptionYearly: 590, isActive: true },
      ])
      setDiscounts([
        { id: '1', code: 'WELCOME20', name: 'Welcome Discount', type: 'percentage', value: 20, maxUses: 100, usedCount: 45, expiresAt: '2026-12-31', isActive: true, applicableTo: 'all' },
        { id: '2', code: 'ANNUAL50', name: 'Annual Plan Discount', type: 'percentage', value: 50, maxUses: 50, usedCount: 12, expiresAt: '2026-06-30', isActive: true, applicableTo: 'web' },
      ])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadPricing()
  }, [loadPricing])

  const handleSave = async () => {
    setIsSaving(true)
    try {
      // Save all plans
      for (const plan of plans) {
        await updatePricingItem('plan', plan.id, {
          name: plan.name,
          description: plan.description,
          monthly_price: plan.monthlyPrice,
          yearly_price: plan.yearlyPrice,
          features: plan.features,
          is_popular: plan.isPopular,
          max_users: plan.maxUsers,
          max_licenses: plan.maxLicenses,
          is_active: plan.isActive
        })
      }

      // Save all desktop prices
      for (const price of desktopPrices) {
        await updatePricingItem('desktop', price.id, {
          product: price.product,
          product_code: price.productCode,
          perpetual_price: price.perpetualPrice,
          subscription_monthly: price.subscriptionMonthly,
          subscription_yearly: price.subscriptionYearly,
          is_active: price.isActive
        })
      }

      // Save all discounts
      for (const discount of discounts) {
        await updatePricingItem('discount', discount.id, {
          code: discount.code,
          name: discount.name,
          discount_type: discount.type,
          discount_value: discount.value,
          max_uses: discount.maxUses,
          valid_until: discount.expiresAt,
          is_active: discount.isActive,
          applicable_to: discount.applicableTo
        })
      }

      setHasChanges(false)
      alert('All changes saved successfully!')
    } catch (error) {
      console.error('Failed to save pricing:', error)
      alert('Failed to save some changes. Please try again.')
    } finally {
      setIsSaving(false)
    }
  }

  const updatePlanPrice = (planId: string, field: 'monthlyPrice' | 'yearlyPrice', value: number) => {
    setPlans(plans.map(plan => 
      plan.id === planId ? { ...plan, [field]: value } : plan
    ))
    setHasChanges(true)
  }

  const updateDesktopPrice = (id: string, field: keyof LocalDesktopPrice, value: number) => {
    setDesktopPrices(desktopPrices.map(price => 
      price.id === id ? { ...price, [field]: value } : price
    ))
    setHasChanges(true)
  }

  const toggleDiscount = async (id: string) => {
    const discount = discounts.find(d => d.id === id)
    if (!discount) return

    try {
      await updatePricingItem('discount', id, { is_active: !discount.isActive })
      setDiscounts(discounts.map(d => 
        d.id === id ? { ...d, isActive: !d.isActive } : d
      ))
    } catch (error) {
      console.error('Failed to toggle discount:', error)
      alert('Failed to update discount status')
    }
  }

  const handleDeleteDiscount = async (id: string) => {
    if (!confirm('Are you sure you want to delete this discount code?')) return

    try {
      await deletePricingItem('discount', id)
      setDiscounts(discounts.filter(d => d.id !== id))
    } catch (error) {
      console.error('Failed to delete discount:', error)
      alert('Failed to delete discount')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Pricing Settings</h2>
          <p className="text-gray-500 mt-1">Configure subscription plans, desktop licenses, and discount codes</p>
        </div>
        <Button onClick={handleSave} disabled={isSaving || !hasChanges} className="flex items-center gap-2">
          {isSaving ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <Save className="h-4 w-4" />
          )}
          {isSaving ? 'Saving...' : hasChanges ? 'Save Changes' : 'Saved'}
        </Button>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <nav className="flex gap-8">
          <button
            onClick={() => setActiveTab('web')}
            className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
              activeTab === 'web'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            <div className="flex items-center gap-2">
              <Globe className="h-4 w-4" />
              Web Subscriptions
            </div>
          </button>
          <button
            onClick={() => setActiveTab('desktop')}
            className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
              activeTab === 'desktop'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            <div className="flex items-center gap-2">
              <Monitor className="h-4 w-4" />
              Desktop Licenses
            </div>
          </button>
          <button
            onClick={() => setActiveTab('discounts')}
            className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
              activeTab === 'discounts'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            <div className="flex items-center gap-2">
              <Percent className="h-4 w-4" />
              Discount Codes
            </div>
          </button>
        </nav>
      </div>

      {/* Web Subscriptions Tab */}
      {activeTab === 'web' && (
        <div className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {plans.map((plan) => (
              <Card key={plan.id} className={plan.isPopular ? 'ring-2 ring-blue-500' : ''}>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-lg">{plan.name}</CardTitle>
                    {plan.isPopular && (
                      <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs font-medium rounded-full">
                        Popular
                      </span>
                    )}
                  </div>
                  <CardDescription>{plan.description}</CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  {/* Pricing */}
                  <div className="space-y-4">
                    <div>
                      <label className="text-sm font-medium text-gray-700">Monthly Price</label>
                      <div className="mt-1 relative">
                        <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                        <input
                          type="number"
                          value={plan.monthlyPrice}
                          onChange={(e) => updatePlanPrice(plan.id, 'monthlyPrice', Number(e.target.value))}
                          className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                    </div>
                    <div>
                      <label className="text-sm font-medium text-gray-700">Yearly Price</label>
                      <div className="mt-1 relative">
                        <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                        <input
                          type="number"
                          value={plan.yearlyPrice}
                          onChange={(e) => updatePlanPrice(plan.id, 'yearlyPrice', Number(e.target.value))}
                          className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                      <p className="text-xs text-gray-500 mt-1">
                        {Math.round((1 - plan.yearlyPrice / (plan.monthlyPrice * 12)) * 100)}% discount from monthly
                      </p>
                    </div>
                  </div>

                  {/* Limits */}
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="text-sm font-medium text-gray-700">Max Users</label>
                      <input
                        type="number"
                        value={plan.maxUsers}
                        onChange={(e) => {
                          setPlans(plans.map(p => 
                            p.id === plan.id ? { ...p, maxUsers: Number(e.target.value) } : p
                          ))
                          setHasChanges(true)
                        }}
                        className="w-full mt-1 px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                        placeholder="-1 for unlimited"
                      />
                    </div>
                    <div>
                      <label className="text-sm font-medium text-gray-700">Max Licenses</label>
                      <input
                        type="number"
                        value={plan.maxLicenses}
                        onChange={(e) => {
                          setPlans(plans.map(p => 
                            p.id === plan.id ? { ...p, maxLicenses: Number(e.target.value) } : p
                          ))
                          setHasChanges(true)
                        }}
                        className="w-full mt-1 px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  {/* Features */}
                  <div>
                    <label className="text-sm font-medium text-gray-700">Features</label>
                    <div className="mt-2 space-y-2">
                      {plan.features.map((feature, index) => (
                        <div key={index} className="flex items-center gap-2 text-sm">
                          <Check className="h-4 w-4 text-green-500 flex-shrink-0" />
                          <span className="text-gray-700">{feature}</span>
                          <button 
                            onClick={() => {
                              setPlans(plans.map(p => 
                                p.id === plan.id 
                                  ? { ...p, features: p.features.filter((_, i) => i !== index) } 
                                  : p
                              ))
                              setHasChanges(true)
                            }}
                            className="ml-auto p-1 hover:bg-red-50 rounded transition-colors"
                          >
                            <X className="h-3 w-3 text-red-500" />
                          </button>
                        </div>
                      ))}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}

      {/* Desktop Licenses Tab */}
      {activeTab === 'desktop' && (
        <Card>
          <CardHeader>
            <CardTitle>Desktop License Pricing</CardTitle>
            <CardDescription>Set prices for perpetual and subscription-based desktop licenses</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Product</th>
                    <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Perpetual License</th>
                    <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Monthly Subscription</th>
                    <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Yearly Subscription</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {desktopPrices.map((price) => (
                    <tr key={price.id} className="hover:bg-gray-50">
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-3">
                          <div className="p-2 bg-blue-50 rounded-lg">
                            <Monitor className="h-5 w-5 text-blue-600" />
                          </div>
                          <span className="font-medium text-gray-900">{price.product}</span>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <div className="relative w-32">
                          <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                          <input
                            type="number"
                            value={price.perpetualPrice}
                            onChange={(e) => updateDesktopPrice(price.id, 'perpetualPrice', Number(e.target.value))}
                            className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                          />
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <div className="relative w-32">
                          <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                          <input
                            type="number"
                            value={price.subscriptionMonthly}
                            onChange={(e) => updateDesktopPrice(price.id, 'subscriptionMonthly', Number(e.target.value))}
                            className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                          />
                        </div>
                        <span className="text-xs text-gray-500">/month</span>
                      </td>
                      <td className="py-4 px-6">
                        <div className="relative w-32">
                          <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                          <input
                            type="number"
                            value={price.subscriptionYearly}
                            onChange={(e) => updateDesktopPrice(price.id, 'subscriptionYearly', Number(e.target.value))}
                            className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                          />
                        </div>
                        <span className="text-xs text-gray-500">/year ({Math.round((1 - price.subscriptionYearly / (price.subscriptionMonthly * 12)) * 100)}% off)</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Discount Codes Tab */}
      {activeTab === 'discounts' && (
        <div className="space-y-6">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <div>
                <CardTitle>Discount Codes</CardTitle>
                <CardDescription>Create and manage promotional discount codes</CardDescription>
              </div>
              <Button className="flex items-center gap-2">
                <Plus className="h-4 w-4" />
                Add Discount
              </Button>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50 border-b border-gray-200">
                    <tr>
                      <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Code</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Type</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Value</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Usage</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Expires</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Status</th>
                      <th className="text-right py-4 px-6 text-sm font-medium text-gray-500">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {discounts.map((discount) => (
                      <tr key={discount.id} className="hover:bg-gray-50">
                        <td className="py-4 px-6">
                          <code className="px-2 py-1 bg-gray-100 rounded text-sm font-mono">
                            {discount.code}
                          </code>
                        </td>
                        <td className="py-4 px-6">
                          <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-medium ${
                            discount.type === 'percentage' ? 'bg-purple-100 text-purple-700' : 'bg-green-100 text-green-700'
                          }`}>
                            {discount.type === 'percentage' ? 'Percentage' : 'Fixed Amount'}
                          </span>
                        </td>
                        <td className="py-4 px-6 font-medium">
                          {discount.type === 'percentage' ? `${discount.value}%` : `$${discount.value}`}
                        </td>
                        <td className="py-4 px-6">
                          <div className="flex items-center gap-2">
                            <div className="w-20 h-2 bg-gray-100 rounded-full overflow-hidden">
                              <div 
                                className={`h-full rounded-full ${
                                  discount.maxUses === -1 ? 'bg-blue-500' :
                                  discount.usedCount >= discount.maxUses ? 'bg-red-500' : 'bg-green-500'
                                }`}
                                style={{ 
                                  width: discount.maxUses === -1 ? '50%' : `${(discount.usedCount / discount.maxUses) * 100}%` 
                                }}
                              />
                            </div>
                            <span className="text-xs text-gray-500">
                              {discount.usedCount}/{discount.maxUses === -1 ? '∞' : discount.maxUses}
                            </span>
                          </div>
                        </td>
                        <td className="py-4 px-6 text-sm text-gray-500">
                          {discount.expiresAt || 'Never'}
                        </td>
                        <td className="py-4 px-6">
                          <button
                            onClick={() => toggleDiscount(discount.id)}
                            className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                              discount.isActive ? 'bg-green-500' : 'bg-gray-200'
                            }`}
                          >
                            <span
                              className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                                discount.isActive ? 'translate-x-6' : 'translate-x-1'
                              }`}
                            />
                          </button>
                        </td>
                        <td className="py-4 px-6">
                          <div className="flex items-center justify-end gap-2">
                            <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
                              <Edit className="h-4 w-4 text-gray-500" />
                            </button>
                            <button 
                              onClick={() => handleDeleteDiscount(discount.id)}
                              className="p-2 hover:bg-red-50 rounded-lg transition-colors"
                            >
                              <Trash2 className="h-4 w-4 text-red-500" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}
