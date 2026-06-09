import { createClient } from '@/lib/supabase/client'
import { 
  AdminCustomer, 
  DesktopLicense, 
  AdminSubscription, 
  PricingPlan, 
  DesktopProductPricing, 
  DiscountCode 
} from '@/types/database.types'

const supabase = createClient()

// =====================================================
// Customer API Functions
// =====================================================

export interface FetchCustomersParams {
  page?: number
  limit?: number
  search?: string
  status?: string
}

export async function fetchCustomers(params: FetchCustomersParams = {}) {
  const queryParams = new URLSearchParams({
    page: String(params.page || 1),
    limit: String(params.limit || 10),
    ...(params.search && { search: params.search }),
    ...(params.status && { status: params.status })
  })

  const response = await fetch(`/api/admin/customers?${queryParams}`)
  if (!response.ok) throw new Error('Failed to fetch customers')
  return response.json()
}

export async function createCustomer(data: Partial<AdminCustomer>) {
  const response = await fetch('/api/admin/customers', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  if (!response.ok) throw new Error('Failed to create customer')
  return response.json()
}

export async function updateCustomer(id: string, data: Partial<AdminCustomer>) {
  const response = await fetch('/api/admin/customers', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, ...data })
  })
  if (!response.ok) throw new Error('Failed to update customer')
  return response.json()
}

export async function deleteCustomer(id: string) {
  const response = await fetch(`/api/admin/customers?id=${id}`, {
    method: 'DELETE'
  })
  if (!response.ok) throw new Error('Failed to delete customer')
  return response.json()
}

// =====================================================
// License API Functions
// =====================================================

export interface FetchLicensesParams {
  page?: number
  limit?: number
  search?: string
  status?: string
  product?: string
  type?: string
}

export async function fetchLicenses(params: FetchLicensesParams = {}) {
  const queryParams = new URLSearchParams({
    page: String(params.page || 1),
    limit: String(params.limit || 10),
    ...(params.search && { search: params.search }),
    ...(params.status && { status: params.status }),
    ...(params.product && { product: params.product }),
    ...(params.type && { type: params.type })
  })

  const response = await fetch(`/api/admin/licenses?${queryParams}`)
  if (!response.ok) throw new Error('Failed to fetch licenses')
  return response.json()
}

export async function generateLicense(data: Partial<DesktopLicense>) {
  const response = await fetch('/api/admin/licenses', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  if (!response.ok) throw new Error('Failed to generate license')
  return response.json()
}

export async function updateLicense(id: string, action: string, data?: any) {
  const response = await fetch('/api/admin/licenses', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, action, ...data })
  })
  if (!response.ok) throw new Error('Failed to update license')
  return response.json()
}

export async function deleteLicense(id: string) {
  const response = await fetch(`/api/admin/licenses?id=${id}`, {
    method: 'DELETE'
  })
  if (!response.ok) throw new Error('Failed to delete license')
  return response.json()
}

export async function validateLicense(licenseKey: string, hardwareId: string, machineInfo?: any) {
  const response = await fetch('/api/admin/licenses/validate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      license_key: licenseKey,
      hardware_id: hardwareId,
      ...machineInfo
    })
  })
  return response.json()
}

// =====================================================
// Subscription API Functions
// =====================================================

export interface FetchSubscriptionsParams {
  page?: number
  limit?: number
  search?: string
  status?: string
  plan?: string
}

export async function fetchSubscriptions(params: FetchSubscriptionsParams = {}) {
  const queryParams = new URLSearchParams({
    page: String(params.page || 1),
    limit: String(params.limit || 10),
    ...(params.search && { search: params.search }),
    ...(params.status && { status: params.status }),
    ...(params.plan && { plan: params.plan })
  })

  const response = await fetch(`/api/admin/subscriptions?${queryParams}`)
  if (!response.ok) throw new Error('Failed to fetch subscriptions')
  return response.json()
}

export async function createSubscription(data: Partial<AdminSubscription>) {
  const response = await fetch('/api/admin/subscriptions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  if (!response.ok) throw new Error('Failed to create subscription')
  return response.json()
}

export async function updateSubscription(id: string, action: string, data?: any) {
  const response = await fetch('/api/admin/subscriptions', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, action, ...data })
  })
  if (!response.ok) throw new Error('Failed to update subscription')
  return response.json()
}

export async function deleteSubscription(id: string) {
  const response = await fetch(`/api/admin/subscriptions?id=${id}`, {
    method: 'DELETE'
  })
  if (!response.ok) throw new Error('Failed to delete subscription')
  return response.json()
}

// =====================================================
// Pricing API Functions
// =====================================================

export async function fetchPricing(type: 'all' | 'plans' | 'desktop' | 'discounts' = 'all') {
  const response = await fetch(`/api/admin/pricing?type=${type}`)
  if (!response.ok) throw new Error('Failed to fetch pricing')
  return response.json()
}

export async function createPricingItem(type: 'plan' | 'desktop' | 'discount', data: any) {
  const response = await fetch('/api/admin/pricing', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ type, ...data })
  })
  if (!response.ok) throw new Error(`Failed to create ${type}`)
  return response.json()
}

export async function updatePricingItem(type: 'plan' | 'desktop' | 'discount', id: string, data: any) {
  const response = await fetch('/api/admin/pricing', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ type, id, ...data })
  })
  if (!response.ok) throw new Error(`Failed to update ${type}`)
  return response.json()
}

export async function deletePricingItem(type: 'plan' | 'desktop' | 'discount', id: string) {
  const response = await fetch(`/api/admin/pricing?type=${type}&id=${id}`, {
    method: 'DELETE'
  })
  if (!response.ok) throw new Error(`Failed to delete ${type}`)
  return response.json()
}

export async function validateDiscountCode(code: string, purchaseAmount?: number, productType?: string) {
  const response = await fetch('/api/admin/pricing/validate-discount', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code, purchase_amount: purchaseAmount, product_type: productType })
  })
  return response.json()
}

// =====================================================
// Admin Stats API Functions
// =====================================================

export async function fetchAdminStats() {
  const response = await fetch('/api/admin/stats')
  if (!response.ok) throw new Error('Failed to fetch admin stats')
  return response.json()
}

// =====================================================
// Real-time Subscriptions (Supabase)
// =====================================================

export function subscribeToCustomers(callback: (payload: any) => void) {
  return supabase
    .channel('admin_customers_changes')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'admin_customers' }, callback)
    .subscribe()
}

export function subscribeToLicenses(callback: (payload: any) => void) {
  return supabase
    .channel('desktop_licenses_changes')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'desktop_licenses' }, callback)
    .subscribe()
}

export function subscribeToSubscriptions(callback: (payload: any) => void) {
  return supabase
    .channel('admin_subscriptions_changes')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'admin_subscriptions' }, callback)
    .subscribe()
}

// =====================================================
// Storage Functions
// =====================================================

export async function uploadCustomerAvatar(customerId: string, file: File) {
  const fileExt = file.name.split('.').pop()
  const fileName = `${customerId}-${Date.now()}.${fileExt}`
  const filePath = `customer-avatars/${fileName}`

  const { data, error } = await supabase.storage
    .from('admin-assets')
    .upload(filePath, file, { upsert: true })

  if (error) throw error

  const { data: { publicUrl } } = supabase.storage
    .from('admin-assets')
    .getPublicUrl(filePath)

  return publicUrl
}

export async function uploadProductImage(productCode: string, file: File) {
  const fileExt = file.name.split('.').pop()
  const fileName = `${productCode}-${Date.now()}.${fileExt}`
  const filePath = `product-images/${fileName}`

  const { data, error } = await supabase.storage
    .from('admin-assets')
    .upload(filePath, file, { upsert: true })

  if (error) throw error

  const { data: { publicUrl } } = supabase.storage
    .from('admin-assets')
    .getPublicUrl(filePath)

  return publicUrl
}

export async function deleteStorageFile(filePath: string) {
  const { error } = await supabase.storage
    .from('admin-assets')
    .remove([filePath])

  if (error) throw error
  return true
}
