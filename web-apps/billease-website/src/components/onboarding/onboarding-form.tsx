'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Building2, Users, User, Globe, Calendar, DollarSign, Check } from 'lucide-react'

interface OnboardingFormProps {
  userId: string
}

type AccountType = 'individual' | 'family' | 'business'

interface FormData {
  // Organization info
  orgName: string
  accountType: AccountType
  
  // Financial settings
  currency: string
  country: string
  fiscalYearStart: string
  timezone: string
  
  // Business-specific
  businessName: string
  taxId: string
  
  // Initial setup
  createSampleData: boolean
}

// Account type configurations
const ACCOUNT_TYPE_CONFIG = {
  individual: {
    icon: User,
    label: 'Individual',
    emoji: '👤',
    description: 'For personal finance management',
    features: {
      gst_enabled: false,
      multi_user: false,
      advanced_reports: true,
      api_access: false,
      team_management: false,
      expense_approval: false,
      budget_alerts: true,
      recurring_transactions: true,
    }
  },
  family: {
    icon: Users,
    label: 'Family',
    emoji: '👨‍👩‍👧‍👦',
    description: 'Manage household finances together',
    features: {
      gst_enabled: false,
      multi_user: true,
      advanced_reports: true,
      api_access: false,
      team_management: true,
      expense_approval: true,
      budget_alerts: true,
      recurring_transactions: true,
    }
  },
  business: {
    icon: Building2,
    label: 'Business',
    emoji: '🏢',
    description: 'For SMEs with GST & team features',
    features: {
      gst_enabled: true,
      multi_user: true,
      advanced_reports: true,
      api_access: true,
      team_management: true,
      expense_approval: true,
      budget_alerts: true,
      recurring_transactions: true,
    }
  }
}

const COUNTRIES = [
  { code: 'IN', name: 'India', currency: 'INR', timezone: 'Asia/Kolkata', fiscalYearStart: '4' },
  { code: 'US', name: 'United States', currency: 'USD', timezone: 'America/New_York', fiscalYearStart: '1' },
  { code: 'GB', name: 'United Kingdom', currency: 'GBP', timezone: 'Europe/London', fiscalYearStart: '4' },
  { code: 'AU', name: 'Australia', currency: 'AUD', timezone: 'Australia/Sydney', fiscalYearStart: '7' },
  { code: 'CA', name: 'Canada', currency: 'CAD', timezone: 'America/Toronto', fiscalYearStart: '1' },
  { code: 'SG', name: 'Singapore', currency: 'SGD', timezone: 'Asia/Singapore', fiscalYearStart: '1' },
]

const MONTHS = [
  { value: '1', label: 'January' },
  { value: '2', label: 'February' },
  { value: '3', label: 'March' },
  { value: '4', label: 'April' },
  { value: '5', label: 'May' },
  { value: '6', label: 'June' },
  { value: '7', label: 'July' },
  { value: '8', label: 'August' },
  { value: '9', label: 'September' },
  { value: '10', label: 'October' },
  { value: '11', label: 'November' },
  { value: '12', label: 'December' },
]

export function OnboardingForm({ userId }: OnboardingFormProps) {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [step, setStep] = useState(1)

  const [formData, setFormData] = useState<FormData>({
    // Organization info
    orgName: '',
    accountType: 'individual',
    
    // Financial settings
    currency: 'INR',
    country: 'IN',
    fiscalYearStart: '4', // April
    timezone: 'Asia/Kolkata',
    
    // Business-specific
    businessName: '',
    taxId: '',
    
    // Initial setup
    createSampleData: true,
  })

  const handleCountryChange = (countryCode: string) => {
    const country = COUNTRIES.find(c => c.code === countryCode)
    if (country) {
      setFormData({
        ...formData,
        country: country.code,
        currency: country.currency,
        timezone: country.timezone,
        fiscalYearStart: country.fiscalYearStart,
      })
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      const supabase = createClient()

      // Generate slug
      const slug = formData.orgName
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/(^-|-$)/g, '')
        + '-' + Math.random().toString(36).substring(2, 7)

      // Get features for account type
      const accountTypeConfig = ACCOUNT_TYPE_CONFIG[formData.accountType]
      const features = accountTypeConfig.features

      // Prepare organization data
      const orgData: any = {
        name: formData.orgName,
        slug,
        account_type: formData.accountType,
        currency: formData.currency,
        default_currency: formData.currency,
        fiscal_year_start: parseInt(formData.fiscalYearStart),
        timezone: formData.timezone,
        country: formData.country,
        features,
      }

      // Add business-specific fields
      if (formData.accountType === 'business') {
        orgData.business_name = formData.businessName || formData.orgName
        orgData.tax_id = formData.taxId || null
        orgData.tax_system = formData.country === 'IN' ? 'gst' : 'other'
      }

      // Create organization
      const { data: org, error: orgError } = await supabase
        .from('organizations')
        .insert(orgData)
        .select()
        .single()

      if (orgError) throw orgError

      // Add user as owner
      const { error: memberError } = await supabase
        .from('organization_members')
        .insert({
          organization_id: org.id,
          user_id: userId,
          role: 'owner',
        })

      if (memberError) throw memberError

      // Mark onboarding as completed
      await supabase
        .from('user_profiles')
        .update({ onboarding_completed: true })
        .eq('id', userId)

      // Create sample data if requested
      if (formData.createSampleData) {
        // Create a cash account
        const { data: account } = await supabase
          .from('accounts')
          .insert({
            organization_id: org.id,
            name: 'Cash',
            type: 'cash',
            balance: 10000,
            currency: formData.currency,
          })
          .select()
          .single()

        // Get default categories (they should be auto-created by the trigger)
        const { data: categories } = await supabase
          .from('categories')
          .select('*')
          .eq('organization_id', org.id)
          .limit(5)

        // Create sample transactions if we have categories and account
        if (categories && categories.length > 0 && account) {
          const today = new Date()
          const sampleTransactions = [
            {
              organization_id: org.id,
              created_by: userId,
              type: 'income',
              amount: 50000,
              currency: formData.currency,
              category_id: categories.find(c => c.type === 'income')?.id,
              account_id: account.id,
              transaction_date: new Date(today.getFullYear(), today.getMonth(), 1).toISOString().split('T')[0],
              description: 'Monthly Salary',
              status: 'completed',
            },
            {
              organization_id: org.id,
              created_by: userId,
              type: 'expense',
              amount: 5000,
              currency: formData.currency,
              category_id: categories.find(c => c.type === 'expense')?.id,
              account_id: account.id,
              transaction_date: new Date(today.getFullYear(), today.getMonth(), 5).toISOString().split('T')[0],
              description: 'Grocery Shopping',
              status: 'completed',
            },
          ]

          await supabase.from('transactions').insert(sampleTransactions)
        }
      }

      router.push('/dashboard')
      router.refresh()
    } catch (err: any) {
      setError(err.message || 'Failed to create organization')
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Progress Indicator */}
      <div className="flex items-center justify-center gap-2 mb-8">
        <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
          step >= 1 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'
        }`}>
          1
        </div>
        <div className={`w-16 h-1 ${step >= 2 ? 'bg-blue-600' : 'bg-gray-200'}`} />
        <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
          step >= 2 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'
        }`}>
          2
        </div>
      </div>

      {step === 1 && (
        <div className="space-y-6">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 mb-2">
              Let's Set Up Your Account
            </h2>
            <p className="text-gray-600">
              Tell us about yourself to customize your experience
            </p>
          </div>

          {/* Account Type Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">
              I am using SpendSight for:
            </label>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {(Object.keys(ACCOUNT_TYPE_CONFIG) as AccountType[]).map((type) => {
                const config = ACCOUNT_TYPE_CONFIG[type]
                const Icon = config.icon
                return (
                  <button
                    key={type}
                    type="button"
                    onClick={() => setFormData({ ...formData, accountType: type })}
                    className={`relative p-6 rounded-lg border-2 transition-all text-left ${
                      formData.accountType === type
                        ? 'border-blue-600 bg-blue-50 shadow-lg'
                        : 'border-gray-200 hover:border-gray-300 hover:shadow-md'
                    }`}
                  >
                    {formData.accountType === type && (
                      <div className="absolute top-3 right-3">
                        <div className="w-6 h-6 bg-blue-600 rounded-full flex items-center justify-center">
                          <Check className="w-4 h-4 text-white" />
                        </div>
                      </div>
                    )}
                    <div className="flex items-start gap-3 mb-3">
                      <div className={`p-2 rounded-lg ${
                        formData.accountType === type ? 'bg-blue-100' : 'bg-gray-100'
                      }`}>
                        <Icon className={`w-6 h-6 ${
                          formData.accountType === type ? 'text-blue-600' : 'text-gray-600'
                        }`} />
                      </div>
                      <div className="flex-1">
                        <h3 className={`font-semibold text-lg ${
                          formData.accountType === type ? 'text-blue-900' : 'text-gray-900'
                        }`}>
                          {config.label}
                        </h3>
                      </div>
                    </div>
                    <p className={`text-sm ${
                      formData.accountType === type ? 'text-blue-700' : 'text-gray-600'
                    }`}>
                      {config.description}
                    </p>
                    
                    {/* Feature highlights */}
                    <div className="mt-4 pt-4 border-t border-gray-200">
                      <div className="flex flex-wrap gap-2">
                        {config.features.multi_user && (
                          <span className="text-xs px-2 py-1 bg-green-100 text-green-700 rounded">
                            Multi-user
                          </span>
                        )}
                        {config.features.gst_enabled && (
                          <span className="text-xs px-2 py-1 bg-purple-100 text-purple-700 rounded">
                            GST Ready
                          </span>
                        )}
                        {config.features.api_access && (
                          <span className="text-xs px-2 py-1 bg-blue-100 text-blue-700 rounded">
                            API Access
                          </span>
                        )}
                      </div>
                    </div>
                  </button>
                )
              })}
            </div>
          </div>

          {/* Organization Name */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              {formData.accountType === 'business' ? 'Business Name' : 
               formData.accountType === 'family' ? 'Family Name' : 
               'Organization Name'}
            </label>
            <input
              type="text"
              required
              value={formData.orgName}
              onChange={(e) => setFormData({ ...formData, orgName: e.target.value })}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder={
                formData.accountType === 'business' ? 'Acme Inc.' :
                formData.accountType === 'family' ? 'The Smiths' :
                'My Personal Finances'
              }
            />
          </div>

          {/* Business-specific fields */}
          {formData.accountType === 'business' && (
            <>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Legal Business Name (Optional)
                </label>
                <input
                  type="text"
                  value={formData.businessName}
                  onChange={(e) => setFormData({ ...formData, businessName: e.target.value })}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Acme Private Limited"
                />
                <p className="text-xs text-gray-500 mt-1">
                  If different from business name above
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Tax ID / GST Number (Optional)
                </label>
                <input
                  type="text"
                  value={formData.taxId}
                  onChange={(e) => setFormData({ ...formData, taxId: e.target.value })}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="GST: 27AABCU9603R1ZM"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Can be added later from settings
                </p>
              </div>
            </>
          )}

          {/* Country & Currency Selection */}
          <div className="grid md:grid-cols-2 gap-4">
            <div>
              <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
                <Globe className="w-4 h-4" />
                Country
              </label>
              <select
                value={formData.country}
                onChange={(e) => handleCountryChange(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white"
              >
                {COUNTRIES.map((country) => (
                  <option key={country.code} value={country.code}>
                    {country.name}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
                <DollarSign className="w-4 h-4" />
                Currency
              </label>
              <input
                type="text"
                value={formData.currency}
                readOnly
                className="w-full px-4 py-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-700"
              />
            </div>
          </div>

          {/* Fiscal Year Start */}
          <div>
            <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
              <Calendar className="w-4 h-4" />
              Fiscal Year Starts
            </label>
            <select
              value={formData.fiscalYearStart}
              onChange={(e) => setFormData({ ...formData, fiscalYearStart: e.target.value })}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white"
            >
              {MONTHS.map((month) => (
                <option key={month.value} value={month.value}>
                  {month.label}
                </option>
              ))}
            </select>
            <p className="text-xs text-gray-500 mt-1">
              {formData.country === 'IN' && 'India typically uses April - March'}
              {formData.country === 'US' && 'US typically uses January - December or July - June'}
              {formData.country === 'GB' && 'UK typically uses April - March'}
              {formData.country === 'AU' && 'Australia typically uses July - June'}
            </p>
          </div>

          <div className="flex justify-end pt-4">
            <button
              type="button"
              onClick={() => setStep(2)}
              className="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors"
            >
              Continue to Setup
            </button>
          </div>
        </div>
      )}

      {step === 2 && (
        <div className="space-y-4">
          <h2 className="text-xl font-semibold text-gray-900">
            Initial Setup
          </h2>

          <div className="bg-blue-50 border border-blue-200 rounded-md p-4">
            <label className="flex items-start gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={formData.createSampleData}
                onChange={(e) =>
                  setFormData({
                    ...formData,
                    createSampleData: e.target.checked,
                  })
                }
                className="mt-1"
              />
              <div>
                <p className="font-medium text-blue-900">
                  Create sample data
                </p>
                <p className="text-sm text-blue-700">
                  We&apos;ll add some sample transactions and categories to help you
                  get started. You can delete them later.
                </p>
              </div>
            </label>
          </div>

          <div className="bg-gray-50 rounded-md p-4">
            <h3 className="font-medium text-gray-900 mb-2">
              What happens next?
            </h3>
            <ul className="space-y-2 text-sm text-gray-600">
              <li className="flex items-start gap-2">
                <span className="text-green-600 mt-0.5">✓</span>
                <span>
                  Your organization will be created with default categories
                </span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-green-600 mt-0.5">✓</span>
                <span>
                  You&apos;ll be set as the owner with full access
                </span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-green-600 mt-0.5">✓</span>
                <span>
                  You can invite team members from settings
                </span>
              </li>
            </ul>
          </div>

          <div className="flex gap-4">
            <button
              type="button"
              onClick={() => setStep(1)}
              className="flex-1 py-3 px-4 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 transition-colors font-medium"
            >
              ← Back
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 bg-blue-600 text-white py-3 px-4 rounded-md hover:bg-blue-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Creating...' : 'Create Organization'}
            </button>
          </div>
        </div>
      )}
    </form>
  )
}
