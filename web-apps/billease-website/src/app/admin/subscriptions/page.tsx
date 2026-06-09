'use client'

import { useState, useEffect, useCallback } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { 
  Search, 
  Filter, 
  Download,
  CreditCard,
  Calendar,
  RefreshCw,
  XCircle,
  CheckCircle,
  Clock,
  AlertCircle,
  ChevronLeft,
  ChevronRight,
  TrendingUp,
  DollarSign,
  Loader2
} from 'lucide-react'
import { fetchSubscriptions, updateSubscription, subscribeToSubscriptions } from '@/lib/admin/api'
import type { AdminSubscription } from '@/types/database.types'
import { format } from 'date-fns'

interface Subscription {
  id: string
  customer: string
  email: string
  company: string
  plan: string
  price: number
  billingCycle: 'monthly' | 'yearly'
  status: 'active' | 'canceled' | 'past_due' | 'trialing' | 'paused'
  startDate: string
  nextBillingDate: string
  canceledAt: string | null
  paymentMethod: string
}

interface Stats {
  mrr: number
  activeCount: number
  trialingCount: number
  pastDueCount: number
  churnedCount: number
}

export default function SubscriptionsPage() {
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [planFilter, setPlanFilter] = useState('all')
  const [currentPage, setCurrentPage] = useState(1)
  const [totalCount, setTotalCount] = useState(0)
  const [loading, setLoading] = useState(true)
  const [actionLoading, setActionLoading] = useState<string | null>(null)
  const [stats, setStats] = useState<Stats>({
    mrr: 0,
    activeCount: 0,
    trialingCount: 0,
    pastDueCount: 0,
    churnedCount: 0
  })

  const itemsPerPage = 10

  const mapSubscription = (sub: AdminSubscription): Subscription => ({
    id: sub.id,
    customer: sub.customer_name || 'Unknown',
    email: sub.customer_email || '',
    company: sub.company || '',
    plan: sub.plan_name,
    price: sub.price,
    billingCycle: sub.billing_cycle,
    status: sub.status,
    startDate: sub.start_date,
    nextBillingDate: sub.next_billing_date || '',
    canceledAt: sub.canceled_at || null,
    paymentMethod: sub.payment_method 
      ? `${sub.payment_method} •••• ${sub.payment_method_last4 || '****'}`
      : 'Not set'
  })

  const loadSubscriptions = useCallback(async () => {
    setLoading(true)
    try {
      const params: Record<string, string> = {
        page: currentPage.toString(),
        limit: itemsPerPage.toString(),
      }
      
      if (searchQuery) params.search = searchQuery
      if (statusFilter !== 'all') params.status = statusFilter
      if (planFilter !== 'all') params.plan = planFilter

      const response = await fetchSubscriptions(params)
      const mappedSubscriptions = response.subscriptions.map(mapSubscription)
      setSubscriptions(mappedSubscriptions)
      setTotalCount(response.totalCount)
      
      // Get stats from API response
      if (response.stats) {
        setStats({
          mrr: response.stats.mrr || 0,
          activeCount: response.stats.active || 0,
          trialingCount: response.stats.trialing || 0,
          pastDueCount: response.stats.past_due || 0,
          churnedCount: response.stats.canceled || 0
        })
      }
    } catch (error) {
      console.error('Failed to fetch subscriptions:', error)
      // Fallback to mock data on error
      const mockSubscriptions: Subscription[] = [
        { id: 'sub_1', customer: 'John Doe', email: 'john@example.com', company: 'Acme Corp', plan: 'Pro', price: 29, billingCycle: 'monthly', status: 'active', startDate: '2024-01-15', nextBillingDate: '2026-03-15', canceledAt: null, paymentMethod: 'Visa •••• 4242' },
        { id: 'sub_2', customer: 'Jane Smith', email: 'jane@techco.com', company: 'TechCo', plan: 'Enterprise', price: 199, billingCycle: 'yearly', status: 'active', startDate: '2023-11-20', nextBillingDate: '2026-11-20', canceledAt: null, paymentMethod: 'Mastercard •••• 5555' },
      ]
      setSubscriptions(mockSubscriptions)
      setTotalCount(mockSubscriptions.length)
    } finally {
      setLoading(false)
    }
  }, [currentPage, searchQuery, statusFilter, planFilter])

  useEffect(() => {
    loadSubscriptions()
    
    // Set up real-time subscription
    const channel = subscribeToSubscriptions(() => {
      loadSubscriptions()
    })
    
    return () => {
      channel.unsubscribe()
    }
  }, [loadSubscriptions])

  const handleCancelSubscription = async (id: string) => {
    if (!confirm('Are you sure you want to cancel this subscription?')) return
    
    setActionLoading(id)
    try {
      await updateSubscription(id, 'cancel', { 
        canceled_at: new Date().toISOString()
      })
      await loadSubscriptions()
    } catch (error) {
      console.error('Failed to cancel subscription:', error)
      alert('Failed to cancel subscription')
    } finally {
      setActionLoading(null)
    }
  }

  const handleReactivateSubscription = async (id: string) => {
    setActionLoading(id)
    try {
      await updateSubscription(id, 'reactivate')
      await loadSubscriptions()
    } catch (error) {
      console.error('Failed to reactivate subscription:', error)
      alert('Failed to reactivate subscription')
    } finally {
      setActionLoading(null)
    }
  }

  const handleRetryPayment = async (id: string) => {
    setActionLoading(id)
    try {
      // In production, this would trigger a Stripe retry
      alert('Payment retry initiated. This would integrate with Stripe in production.')
      // await updateSubscription(id, { status: 'active' })
      // await loadSubscriptions()
    } catch (error) {
      console.error('Failed to retry payment:', error)
    } finally {
      setActionLoading(null)
    }
  }

  const totalPages = Math.ceil(totalCount / itemsPerPage)

  const formatDate = (dateStr: string) => {
    if (!dateStr) return 'N/A'
    try {
      return format(new Date(dateStr), 'MMM d, yyyy')
    } catch {
      return dateStr
    }
  }

  const getStatusBadge = (status: string) => {
    const styles = {
      active: { bg: 'bg-green-100 text-green-700', icon: CheckCircle },
      canceled: { bg: 'bg-gray-100 text-gray-700', icon: XCircle },
      past_due: { bg: 'bg-red-100 text-red-700', icon: AlertCircle },
      trialing: { bg: 'bg-blue-100 text-blue-700', icon: Clock },
      paused: { bg: 'bg-yellow-100 text-yellow-700', icon: Clock },
    }
    return styles[status as keyof typeof styles] || styles.trialing
  }

  const getPlanBadge = (plan: string) => {
    const styles: Record<string, string> = {
      Free: 'bg-gray-100 text-gray-700',
      Starter: 'bg-blue-100 text-blue-700',
      Pro: 'bg-purple-100 text-purple-700',
      Enterprise: 'bg-orange-100 text-orange-700',
    }
    return styles[plan] || styles.Free
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Subscriptions</h2>
          <p className="text-gray-500 mt-1">Manage customer subscriptions and billing</p>
        </div>
        <Button variant="outline" className="flex items-center gap-2">
          <Download className="h-4 w-4" />
          Export Report
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">Monthly Recurring Revenue</p>
                <p className="text-2xl font-bold text-gray-900">${stats.mrr.toFixed(0)}</p>
              </div>
              <div className="p-3 bg-green-50 rounded-lg">
                <DollarSign className="h-6 w-6 text-green-600" />
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">Active</p>
                <p className="text-2xl font-bold text-gray-900">{stats.activeCount}</p>
              </div>
              <div className="p-3 bg-blue-50 rounded-lg">
                <CheckCircle className="h-6 w-6 text-blue-600" />
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">Trialing</p>
                <p className="text-2xl font-bold text-gray-900">{stats.trialingCount}</p>
              </div>
              <div className="p-3 bg-purple-50 rounded-lg">
                <Clock className="h-6 w-6 text-purple-600" />
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">Past Due</p>
                <p className="text-2xl font-bold text-gray-900">{stats.pastDueCount}</p>
              </div>
              <div className="p-3 bg-red-50 rounded-lg">
                <AlertCircle className="h-6 w-6 text-red-600" />
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">Churned</p>
                <p className="text-2xl font-bold text-gray-900">{stats.churnedCount}</p>
              </div>
              <div className="p-3 bg-gray-100 rounded-lg">
                <XCircle className="h-6 w-6 text-gray-600" />
              </div>
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
                placeholder="Search by customer name, email, or company..."
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
                <option value="trialing">Trialing</option>
                <option value="past_due">Past Due</option>
                <option value="canceled">Canceled</option>
              </select>
              <select
                value={planFilter}
                onChange={(e) => setPlanFilter(e.target.value)}
                className="px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All Plans</option>
                <option value="Starter">Starter</option>
                <option value="Pro">Pro</option>
                <option value="Enterprise">Enterprise</option>
              </select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Subscriptions Table */}
      <Card>
        <CardContent className="p-0">
          {loading ? (
            <div className="flex items-center justify-center py-16">
              <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
            </div>
          ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Customer</th>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Plan</th>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Price</th>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Status</th>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Next Billing</th>
                  <th className="text-left py-4 px-6 text-sm font-medium text-gray-500">Payment Method</th>
                  <th className="text-right py-4 px-6 text-sm font-medium text-gray-500">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {subscriptions.map((sub) => {
                  const statusStyle = getStatusBadge(sub.status)
                  const StatusIcon = statusStyle.icon

                  return (
                    <tr key={sub.id} className="hover:bg-gray-50 transition-colors">
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-3">
                          <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
                            <span className="text-sm font-medium text-blue-600">
                              {sub.customer.split(' ').map(n => n[0]).join('')}
                            </span>
                          </div>
                          <div>
                            <p className="text-sm font-medium text-gray-900">{sub.customer}</p>
                            <p className="text-xs text-gray-500">{sub.company}</p>
                          </div>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-medium ${getPlanBadge(sub.plan)}`}>
                          {sub.plan}
                        </span>
                      </td>
                      <td className="py-4 px-6">
                        <div>
                          <p className="text-sm font-medium text-gray-900">${sub.price}</p>
                          <p className="text-xs text-gray-500">/{sub.billingCycle === 'monthly' ? 'mo' : 'yr'}</p>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium ${statusStyle.bg}`}>
                          <StatusIcon className="h-3 w-3" />
                          {sub.status === 'past_due' ? 'Past Due' : sub.status.charAt(0).toUpperCase() + sub.status.slice(1)}
                        </span>
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4 text-gray-400" />
                          <span className="text-sm text-gray-700">
                            {sub.nextBillingDate || 'N/A'}
                          </span>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-2">
                          <CreditCard className="h-4 w-4 text-gray-400" />
                          <span className="text-sm text-gray-700">{sub.paymentMethod}</span>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex items-center justify-end gap-1">
                          {sub.status === 'past_due' && (
                            <Button 
                              size="sm" 
                              variant="outline" 
                              className="text-xs"
                              onClick={() => handleRetryPayment(sub.id)}
                              disabled={actionLoading === sub.id}
                            >
                              {actionLoading === sub.id ? (
                                <Loader2 className="h-3 w-3 animate-spin" />
                              ) : (
                                'Retry Payment'
                              )}
                            </Button>
                          )}
                          {sub.status === 'active' && (
                            <Button 
                              size="sm" 
                              variant="outline" 
                              className="text-xs text-red-600 hover:text-red-700"
                              onClick={() => handleCancelSubscription(sub.id)}
                              disabled={actionLoading === sub.id}
                            >
                              {actionLoading === sub.id ? (
                                <Loader2 className="h-3 w-3 animate-spin" />
                              ) : (
                                'Cancel'
                              )}
                            </Button>
                          )}
                          {sub.status === 'canceled' && (
                            <Button 
                              size="sm" 
                              variant="outline" 
                              className="text-xs"
                              onClick={() => handleReactivateSubscription(sub.id)}
                              disabled={actionLoading === sub.id}
                            >
                              {actionLoading === sub.id ? (
                                <Loader2 className="h-3 w-3 animate-spin" />
                              ) : (
                                'Reactivate'
                              )}
                            </Button>
                          )}
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
          )}

          {/* Pagination */}
          <div className="flex items-center justify-between px-6 py-4 border-t border-gray-200">
            <p className="text-sm text-gray-500">
              Showing {(currentPage - 1) * itemsPerPage + 1} to {Math.min(currentPage * itemsPerPage, totalCount)} of {totalCount} subscriptions
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
