'use client'

import { useState, useEffect, useCallback } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { 
  Search, 
  Filter, 
  Download,
  Key,
  Monitor,
  RefreshCw,
  Ban,
  Check,
  Clock,
  AlertTriangle,
  ChevronLeft,
  ChevronRight,
  Plus,
  Copy,
  Loader2
} from 'lucide-react'
import { fetchLicenses, updateLicense, subscribeToLicenses } from '@/lib/admin/api'
import { DesktopLicense } from '@/types/database.types'

interface License {
  id: string
  licenseKey: string
  customer: string
  email: string
  product: string
  type: 'perpetual' | 'subscription' | 'trial'
  status: 'active' | 'expired' | 'revoked' | 'pending'
  activations: number
  maxActivations: number
  activatedOn: string
  expiresOn: string | null
  lastChecked: string
}

interface LicenseStats {
  total: number
  active: number
  expired: number
  pending: number
}

export default function LicensesPage() {
  const [licenses, setLicenses] = useState<License[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [productFilter, setProductFilter] = useState('all')
  const [currentPage, setCurrentPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [totalCount, setTotalCount] = useState(0)
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState<LicenseStats>({ total: 0, active: 0, expired: 0, pending: 0 })
  const [showCreateModal, setShowCreateModal] = useState(false)

  const itemsPerPage = 10

  const loadLicenses = useCallback(async () => {
    try {
      setLoading(true)
      const data = await fetchLicenses({
        page: currentPage,
        limit: itemsPerPage,
        search: searchQuery,
        status: statusFilter !== 'all' ? statusFilter : undefined,
        product: productFilter !== 'all' ? productFilter : undefined
      })
      
      // Map API response to component format
      const mappedLicenses = (data.licenses || []).map((l: DesktopLicense) => ({
        id: l.id,
        licenseKey: l.license_key,
        customer: l.customer_name || 'Unknown',
        email: l.customer_email || '',
        product: l.product,
        type: l.license_type,
        status: l.status,
        activations: l.activations,
        maxActivations: l.max_activations,
        activatedOn: l.activated_on || '',
        expiresOn: l.expires_on,
        lastChecked: l.last_checked || ''
      }))
      
      setLicenses(mappedLicenses)
      setStats(data.stats || { total: 0, active: 0, expired: 0, pending: 0 })
      setTotalPages(data.pagination?.totalPages || 1)
      setTotalCount(data.pagination?.total || 0)
    } catch (error) {
      console.error('Error loading licenses:', error)
      // Fallback to mock data
      setLicenses([
        { id: '1', licenseKey: 'BE-PRO-XXXX-XXXX-1234', customer: 'John Doe', email: 'john@example.com', product: 'BillEase POS', type: 'perpetual', status: 'active', activations: 2, maxActivations: 3, activatedOn: '2024-01-15', expiresOn: null, lastChecked: '2026-02-02' },
        { id: '2', licenseKey: 'BE-ENT-XXXX-XXXX-5678', customer: 'Jane Smith', email: 'jane@techco.com', product: 'BillEase Suite', type: 'subscription', status: 'active', activations: 8, maxActivations: 10, activatedOn: '2023-11-20', expiresOn: '2027-11-20', lastChecked: '2026-02-02' },
      ])
      setStats({ total: 8, active: 5, expired: 1, pending: 1 })
    } finally {
      setLoading(false)
    }
  }, [currentPage, searchQuery, statusFilter, productFilter])

  useEffect(() => {
    loadLicenses()
  }, [loadLicenses])

  // Real-time subscription
  useEffect(() => {
    const channel = subscribeToLicenses(() => {
      loadLicenses()
    })
    return () => {
      channel.unsubscribe()
    }
  }, [loadLicenses])

  const handleRevoke = async (id: string) => {
    if (!confirm('Are you sure you want to revoke this license?')) return
    try {
      await updateLicense(id, 'revoke')
      loadLicenses()
    } catch (error) {
      console.error('Error revoking license:', error)
    }
  }

  const handleResetActivations = async (id: string) => {
    if (!confirm('Reset all activations for this license?')) return
    try {
      await updateLicense(id, 'reset_activations')
      loadLicenses()
    } catch (error) {
      console.error('Error resetting activations:', error)
    }
  }

  const paginatedLicenses = licenses

  const products = ['BillEase POS', 'BillEase Inventory', 'BillEase Accounts', 'BillEase CRM', 'BillEase Suite']

  const getStatusBadge = (status: string) => {
    const styles = {
      active: { bg: 'bg-green-100 text-green-700', icon: Check },
      expired: { bg: 'bg-red-100 text-red-700', icon: Clock },
      revoked: { bg: 'bg-gray-100 text-gray-700', icon: Ban },
      pending: { bg: 'bg-yellow-100 text-yellow-700', icon: AlertTriangle },
    }
    return styles[status as keyof typeof styles] || styles.pending
  }

  const getTypeBadge = (type: string) => {
    const styles: Record<string, string> = {
      perpetual: 'bg-purple-100 text-purple-700',
      subscription: 'bg-blue-100 text-blue-700',
      trial: 'bg-orange-100 text-orange-700',
    }
    return styles[type] || styles.trial
  }

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text)
    // Could add a toast notification here
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Desktop Licenses</h2>
          <p className="text-gray-500 mt-1">Manage software licenses for desktop applications</p>
        </div>
        <Button className="flex items-center gap-2" onClick={() => setShowCreateModal(true)}>
          <Plus className="h-4 w-4" />
          Generate License
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4 flex items-center gap-4">
            <div className="p-3 bg-blue-50 rounded-lg">
              <Key className="h-6 w-6 text-blue-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{stats.total}</p>
              <p className="text-sm text-gray-500">Total Licenses</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-4">
            <div className="p-3 bg-green-50 rounded-lg">
              <Check className="h-6 w-6 text-green-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{stats.active}</p>
              <p className="text-sm text-gray-500">Active</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-4">
            <div className="p-3 bg-red-50 rounded-lg">
              <Clock className="h-6 w-6 text-red-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{stats.expired}</p>
              <p className="text-sm text-gray-500">Expired</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-4">
            <div className="p-3 bg-yellow-50 rounded-lg">
              <AlertTriangle className="h-6 w-6 text-yellow-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{stats.pending}</p>
              <p className="text-sm text-gray-500">Pending Activation</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="p-4">
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search by license key, customer name, or email..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div className="flex gap-2">
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All Status</option>
                <option value="active">Active</option>
                <option value="expired">Expired</option>
                <option value="revoked">Revoked</option>
                <option value="pending">Pending</option>
              </select>
              <select
                value={productFilter}
                onChange={(e) => setProductFilter(e.target.value)}
                className="px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All Products</option>
                {products.map(product => (
                  <option key={product} value={product}>{product}</option>
                ))}
              </select>
              <Button variant="outline" className="flex items-center gap-2">
                <Download className="h-4 w-4" />
                Export
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Licenses Table */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">License Key</th>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Customer</th>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Product</th>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Type</th>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Activations</th>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Status</th>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Expires</th>
                  <th className="text-right py-4 px-6 text-sm font-medium text-gray-500">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {paginatedLicenses.map((license) => {
                  const statusStyle = getStatusBadge(license.status)
                  const StatusIcon = statusStyle.icon

                  return (
                    <tr key={license.id} className="hover:bg-gray-50 transition-colors">
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-2">
                          <code className="text-sm font-mono bg-gray-100 px-2 py-1 rounded">
                            {license.licenseKey}
                          </code>
                          <button 
                            onClick={() => copyToClipboard(license.licenseKey)}
                            className="p-1 hover:bg-gray-200 rounded transition-colors"
                            title="Copy license key"
                          >
                            <Copy className="h-3.5 w-3.5 text-gray-400" />
                          </button>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <div>
                          <p className="text-sm font-medium text-gray-900">{license.customer}</p>
                          <p className="text-xs text-gray-500">{license.email}</p>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-2">
                          <Monitor className="h-4 w-4 text-gray-400" />
                          <span className="text-sm text-gray-700">{license.product}</span>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-medium capitalize ${getTypeBadge(license.type)}`}>
                          {license.type}
                        </span>
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-2">
                          <div className="w-20 h-2 bg-gray-100 rounded-full overflow-hidden">
                            <div 
                              className={`h-full rounded-full ${
                                license.activations >= license.maxActivations ? 'bg-red-500' : 'bg-green-500'
                              }`}
                              style={{ width: `${(license.activations / license.maxActivations) * 100}%` }}
                            />
                          </div>
                          <span className="text-xs text-gray-500">
                            {license.activations}/{license.maxActivations}
                          </span>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium capitalize ${statusStyle.bg}`}>
                          <StatusIcon className="h-3 w-3" />
                          {license.status}
                        </span>
                      </td>
                      <td className="py-4 px-6 text-sm text-gray-500">
                        {license.expiresOn || 'Never'}
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex items-center justify-end gap-1">
                          <button 
                            onClick={() => handleResetActivations(license.id)}
                            className="p-2 hover:bg-gray-100 rounded-lg transition-colors" 
                            title="Reset activations"
                          >
                            <RefreshCw className="h-4 w-4 text-gray-500" />
                          </button>
                          <button 
                            onClick={() => handleRevoke(license.id)}
                            className="p-2 hover:bg-red-50 rounded-lg transition-colors" 
                            title="Revoke license"
                          >
                            <Ban className="h-4 w-4 text-red-500" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          <div className="flex items-center justify-between px-6 py-4 border-t border-gray-200">
            <p className="text-sm text-gray-500">
              Showing {(currentPage - 1) * itemsPerPage + 1} to {Math.min(currentPage * itemsPerPage, totalCount)} of {totalCount} licenses
            </p>
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                disabled={currentPage === 1}
              >
                <ChevronLeft className="h-4 w-4" />
              </Button>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map(page => (
                <Button
                  key={page}
                  variant={currentPage === page ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => setCurrentPage(page)}
                >
                  {page}
                </Button>
              ))}
              <Button
                variant="outline"
                size="sm"
                onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                disabled={currentPage === totalPages}
              >
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
