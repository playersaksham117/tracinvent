export interface User {
  id: string
  email: string
  full_name: string
  company_name?: string
  role: 'user' | 'admin' | 'super_admin'
  avatar_url?: string
  created_at: string
}

export interface SubscriptionPlan {
  id: string
  name: string
  slug: string
  description: string
  price_monthly: number
  price_yearly: number
  features: string[]
  app_access: string[]
  is_popular: boolean
}

export interface Subscription {
  id: string
  user_id: string
  plan_id: string
  status: 'active' | 'cancelled' | 'expired' | 'past_due' | 'trialing'
  billing_period: 'monthly' | 'yearly'
  current_period_start: string
  current_period_end: string
  created_at: string
}

export interface AppAccess {
  id: string
  user_id: string
  app_id: 'pos' | 'crm' | 'accounts' | 'inventory'
  has_access: boolean
  access_level: 'user' | 'admin' | 'owner'
  created_at: string
}

export interface Payment {
  id: string
  user_id: string
  subscription_id?: string
  amount: number
  currency: string
  status: 'pending' | 'succeeded' | 'failed' | 'refunded'
  payment_method: string
  created_at: string
}

export interface AuditLog {
  id: string
  user_id?: string
  action: string
  resource_type?: string
  resource_id?: string
  changes: Record<string, any>
  ip_address?: string
  status: 'success' | 'failure'
  created_at: string
}

// =====================================================
// POS Database Types
// =====================================================

export interface Tenant {
  id: string
  user_id: string
  name: string
  slug: string
  settings: Record<string, any>
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Product {
  id: string
  tenant_id: string
  sku?: string
  barcode?: string
  name: string
  description?: string
  category?: string
  brand?: string
  unit: string
  cost_price: number
  selling_price: number
  tax_rate: number
  stock_quantity: number
  reorder_level: number
  image_url?: string
  is_active: boolean
  is_taxable: boolean
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface Customer {
  id: string
  tenant_id: string
  customer_code: string
  name: string
  email?: string
  phone?: string
  address?: string
  city?: string
  state?: string
  postal_code?: string
  country: string
  tax_id?: string
  credit_limit: number
  current_balance: number
  total_purchases: number
  total_transactions: number
  loyalty_points: number
  customer_group: 'regular' | 'vip' | 'wholesale'
  notes?: string
  is_active: boolean
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface Sale {
  id: string
  tenant_id: string
  sale_number: string
  customer_id?: string
  customer_name?: string
  customer_phone?: string
  customer_email?: string
  subtotal: number
  tax_amount: number
  discount_amount: number
  total_amount: number
  amount_paid: number
  change_amount: number
  payment_method: 'cash' | 'card' | 'upi' | 'wallet' | 'mobile' | 'other'
  payment_status: 'paid' | 'partial' | 'pending' | 'refunded'
  status: 'draft' | 'completed' | 'cancelled' | 'refunded'
  notes?: string
  cashier_id?: string
  shift_id?: string
  metadata: Record<string, any>
  completed_at: string
  created_at: string
  updated_at: string
}

export interface SaleItem {
  id: string
  tenant_id: string
  sale_id: string
  product_id?: string
  product_name: string
  quantity: number
  unit_price: number
  tax_rate: number
  discount: number
  subtotal: number
  total: number
  metadata: Record<string, any>
  created_at: string
}

export interface Shift {
  id: string
  tenant_id: string
  shift_number: string
  cashier_id: string
  opening_balance: number
  closing_balance?: number
  expected_balance?: number
  difference?: number
  total_sales: number
  total_transactions: number
  status: 'open' | 'closed'
  notes?: string
  opened_at: string
  closed_at?: string
  metadata: Record<string, any>
  created_at: string
}

export interface Receipt {
  id: string
  tenant_id: string
  sale_id: string
  receipt_number: string
  receipt_data: Record<string, any>
  print_count: number
  last_printed_at?: string
  created_at: string
}

export interface PaymentTransaction {
  id: string
  tenant_id: string
  sale_id?: string
  amount: number
  payment_method: string
  reference_number?: string
  status: 'pending' | 'completed' | 'failed' | 'refunded'
  metadata: Record<string, any>
  created_at: string
}

export interface Discount {
  id: string
  tenant_id: string
  code: string
  name: string
  description?: string
  discount_type: 'percentage' | 'fixed'
  discount_value: number
  min_purchase_amount: number
  max_discount_amount?: number
  applicable_to: 'all' | 'products' | 'categories'
  applicable_ids: string[]
  valid_from: string
  valid_until?: string
  usage_limit?: number
  usage_count: number
  is_active: boolean
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface PaymentMethod {
  id: string
  tenant_id: string
  name: string
  code: string
  icon?: string
  is_active: boolean
  requires_reference: boolean
  metadata: Record<string, any>
  created_at: string
}

export interface Currency {
  id: string
  tenant_id: string
  code: string
  name: string
  symbol: string
  exchange_rate: number
  is_default: boolean
  is_active: boolean
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface TaxRate {
  id: string
  tenant_id: string
  name: string
  rate: number
  description?: string
  is_default: boolean
  is_active: boolean
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface StockAdjustment {
  id: string
  tenant_id: string
  product_id: string
  adjustment_type: 'add' | 'remove' | 'set' | 'sale' | 'return' | 'damage' | 'audit'
  quantity_before: number
  quantity_change: number
  quantity_after: number
  reason?: string
  reference_id?: string
  adjusted_by?: string
  metadata: Record<string, any>
  created_at: string
}

// =====================================================
// Admin / License Management Types
// =====================================================

export interface AdminCustomer {
  id: string
  user_id: string
  name: string
  email: string
  company: string
  phone?: string
  address?: string
  subscription_id?: string
  subscription_plan?: string
  license_count: number
  status: 'active' | 'inactive' | 'suspended'
  join_date: string
  last_active: string
  total_spent: number
  notes?: string
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface DesktopLicense {
  id: string
  license_key: string
  customer_id: string
  customer_name?: string
  customer_email?: string
  product: string
  product_code: string
  license_type: 'perpetual' | 'subscription' | 'trial'
  status: 'active' | 'expired' | 'revoked' | 'pending'
  activations: number
  max_activations: number
  activated_on?: string
  expires_on?: string
  last_checked?: string
  hardware_ids: string[]
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface LicenseActivation {
  id: string
  license_id: string
  hardware_id: string
  machine_name?: string
  os_info?: string
  ip_address?: string
  activated_at: string
  deactivated_at?: string
  is_active: boolean
  metadata: Record<string, any>
}

export interface AdminSubscription {
  id: string
  customer_id: string
  customer_name?: string
  customer_email?: string
  company?: string
  plan_id: string
  plan_name: string
  price: number
  billing_cycle: 'monthly' | 'yearly'
  status: 'active' | 'canceled' | 'past_due' | 'trialing' | 'paused'
  start_date: string
  next_billing_date?: string
  canceled_at?: string
  cancel_reason?: string
  payment_method?: string
  payment_method_last4?: string
  stripe_subscription_id?: string
  stripe_customer_id?: string
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface PricingPlan {
  id: string
  name: string
  slug: string
  description: string
  monthly_price: number
  yearly_price: number
  features: string[]
  max_users: number
  max_licenses: number
  is_popular: boolean
  is_active: boolean
  stripe_monthly_price_id?: string
  stripe_yearly_price_id?: string
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface DesktopProductPricing {
  id: string
  product: string
  product_code: string
  perpetual_price: number
  subscription_monthly: number
  subscription_yearly: number
  is_active: boolean
  stripe_perpetual_price_id?: string
  stripe_monthly_price_id?: string
  stripe_yearly_price_id?: string
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface DiscountCode {
  id: string
  code: string
  name: string
  description?: string
  discount_type: 'percentage' | 'fixed'
  discount_value: number
  min_purchase_amount: number
  max_discount_amount?: number
  max_uses: number
  used_count: number
  applicable_to: 'all' | 'web' | 'desktop'
  applicable_plans?: string[]
  applicable_products?: string[]
  valid_from: string
  valid_until?: string
  is_active: boolean
  stripe_coupon_id?: string
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface AdminActivity {
  id: string
  admin_id: string
  action_type: 'customer' | 'license' | 'subscription' | 'pricing' | 'discount'
  action: string
  resource_id?: string
  resource_name?: string
  details?: string
  ip_address?: string
  metadata: Record<string, any>
  created_at: string
}

// =====================================================
// Database Schema Type (for Supabase client typing)
// =====================================================

export interface Database {
  public: {
    Tables: {
      users: {
        Row: User
        Insert: Omit<User, 'id' | 'created_at'>
        Update: Partial<Omit<User, 'id' | 'created_at'>>
      }
      admin_customers: {
        Row: AdminCustomer
        Insert: Omit<AdminCustomer, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<AdminCustomer, 'id' | 'created_at'>>
      }
      desktop_licenses: {
        Row: DesktopLicense
        Insert: Omit<DesktopLicense, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<DesktopLicense, 'id' | 'created_at'>>
      }
      license_activations: {
        Row: LicenseActivation
        Insert: Omit<LicenseActivation, 'id'>
        Update: Partial<Omit<LicenseActivation, 'id'>>
      }
      admin_subscriptions: {
        Row: AdminSubscription
        Insert: Omit<AdminSubscription, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<AdminSubscription, 'id' | 'created_at'>>
      }
      pricing_plans: {
        Row: PricingPlan
        Insert: Omit<PricingPlan, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<PricingPlan, 'id' | 'created_at'>>
      }
      desktop_product_pricing: {
        Row: DesktopProductPricing
        Insert: Omit<DesktopProductPricing, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<DesktopProductPricing, 'id' | 'created_at'>>
      }
      discount_codes: {
        Row: DiscountCode
        Insert: Omit<DiscountCode, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<DiscountCode, 'id' | 'created_at'>>
      }
      admin_activities: {
        Row: AdminActivity
        Insert: Omit<AdminActivity, 'id' | 'created_at'>
        Update: Partial<Omit<AdminActivity, 'id' | 'created_at'>>
      }
    }
  }
}
