import { createClient } from '@/lib/supabase/server'

export type OrganizationRole = 'owner' | 'admin' | 'member' | 'viewer'

export interface Organization {
  id: string
  name: string
  slug: string
  logo_url: string | null
  currency: string
  role?: OrganizationRole
}

export async function getUserOrganizations(userId: string): Promise<Organization[]> {
  const supabase = await createClient()
  
  const { data, error } = await supabase
    .from('organization_members')
    .select(`
      role,
      is_active,
      organization:organizations (
        id,
        name,
        slug,
        logo_url,
        currency,
        is_active
      )
    `)
    .eq('user_id', userId)
    .eq('is_active', true)
  
  if (error) throw error
  if (!data) return []
  
  return data
    .filter(item => {
      const org = Array.isArray(item.organization) ? item.organization[0] : item.organization
      return org && org.is_active
    })
    .map(item => {
      const org = Array.isArray(item.organization) ? item.organization[0] : item.organization
      return {
        id: org.id,
        name: org.name,
        slug: org.slug,
        logo_url: org.logo_url,
        currency: org.currency,
        role: item.role as OrganizationRole
      }
    })
}

export async function getOrganizationBySlug(slug: string) {
  const supabase = await createClient()
  
  const { data, error } = await supabase
    .from('organizations')
    .select('*')
    .eq('slug', slug)
    .eq('is_active', true)
    .single()
  
  if (error) throw error
  return data
}

export async function createOrganization(name: string, userId: string) {
  const supabase = await createClient()
  
  // Generate slug from name
  const slug = name.toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '')
  
  // Create organization
  const { data: org, error: orgError } = await supabase
    .from('organizations')
    .insert({
      name,
      slug,
      currency: 'INR',
      fiscal_year_start: 4, // April
      timezone: 'Asia/Kolkata',
      country: 'IN'
    })
    .select()
    .single()
  
  if (orgError) throw orgError
  
  // Add user as owner
  const { error: memberError } = await supabase
    .from('organization_members')
    .insert({
      organization_id: org.id,
      user_id: userId,
      role: 'owner'
    })
  
  if (memberError) throw memberError
  
  return org
}

export async function getUserRole(userId: string, organizationId: string): Promise<OrganizationRole | null> {
  const supabase = await createClient()
  
  const { data, error } = await supabase
    .from('organization_members')
    .select('role')
    .eq('user_id', userId)
    .eq('organization_id', organizationId)
    .eq('is_active', true)
    .single()
  
  if (error) return null
  return data.role as OrganizationRole
}

export async function hasPermission(
  userId: string,
  organizationId: string,
  requiredRole: OrganizationRole
): Promise<boolean> {
  const role = await getUserRole(userId, organizationId)
  if (!role) return false
  
  const roleHierarchy: Record<OrganizationRole, number> = {
    viewer: 1,
    member: 2,
    admin: 3,
    owner: 4
  }
  
  return roleHierarchy[role] >= roleHierarchy[requiredRole]
}
