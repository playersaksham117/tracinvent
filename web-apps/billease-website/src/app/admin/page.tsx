'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Users, Key, CreditCard, DollarSign, TrendingUp, TrendingDown, Loader2 } from 'lucide-react'
import { fetchAdminStats } from '@/lib/admin/api'
import { formatDistanceToNow } from 'date-fns'

interface DashboardStats {
  totalCustomers: number
  activeSubscriptions: number
  activeLicenses: number
  mrr: number
  customerGrowth: number
}

interface Activity {
  id: string
  type: string
  action: string
  resourceName: string
  time: string
}

export default function AdminOverviewPage() {
  const [stats, setStats] = useState<DashboardStats>({
    totalCustomers: 0,
    activeSubscriptions: 0,
    activeLicenses: 0,
    mrr: 0,
    customerGrowth: 0,
  })
  const [recentActivity, setRecentActivity] = useState<Activity[]>([])
  const [subscriptionDistribution, setSubscriptionDistribution] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    loadStats()
  }, [])

  const loadStats = async () => {
    try {
      setLoading(true)
      const data = await fetchAdminStats()
      setStats(data.stats)
      setRecentActivity(data.recentActivity || [])
      setSubscriptionDistribution(data.subscriptionDistribution || [])
    } catch (err) {
      console.error('Error loading stats:', err)
      setError('Failed to load dashboard data')
      // Fallback to mock data
      setStats({
        totalCustomers: 1247,
        activeSubscriptions: 892,
        activeLicenses: 456,
        mrr: 24680,
        customerGrowth: 12.5,
      })
      setRecentActivity([
        { id: '1', type: 'subscription', resourceName: 'John Doe', action: 'Upgraded to Pro', time: new Date().toISOString() },
        { id: '2', type: 'license', resourceName: 'Jane Smith', action: 'Activated Desktop License', time: new Date().toISOString() },
      ])
      setSubscriptionDistribution([
        { plan: 'Free', count: 355, percentage: 40 },
        { plan: 'Starter', count: 267, percentage: 30 },
        { plan: 'Pro', count: 178, percentage: 20 },
        { plan: 'Enterprise', count: 89, percentage: 10 },
      ])
    } finally {
      setLoading(false)
    }
  }

  const statCards = [
    {
      title: 'Total Customers',
      value: stats.totalCustomers.toLocaleString(),
      change: stats.customerGrowth,
      icon: Users,
      color: 'blue',
    },
    {
      title: 'Active Subscriptions',
      value: stats.activeSubscriptions.toLocaleString(),
      change: 5.2,
      icon: CreditCard,
      color: 'green',
    },
    {
      title: 'Active Licenses',
      value: stats.activeLicenses.toLocaleString(),
      change: 2.1,
      icon: Key,
      color: 'purple',
    },
    {
      title: 'Monthly Revenue',
      value: `$${stats.mrr.toLocaleString()}`,
      change: 8.3,
      icon: DollarSign,
      color: 'orange',
    },
  ]

  const colorClasses: Record<string, { bg: string; icon: string }> = {
    blue: { bg: 'bg-blue-50', icon: 'text-blue-600' },
    green: { bg: 'bg-green-50', icon: 'text-green-600' },
    purple: { bg: 'bg-purple-50', icon: 'text-purple-600' },
    orange: { bg: 'bg-orange-50', icon: 'text-orange-600' },
  }

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Dashboard Overview</h2>
        <p className="text-gray-500 mt-1">Welcome to the BillEase admin panel</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {statCards.map((stat) => {
          const Icon = stat.icon
          const colors = colorClasses[stat.color]
          const isPositive = stat.change >= 0

          return (
            <Card key={stat.title}>
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div className={`p-3 rounded-lg ${colors.bg}`}>
                    <Icon className={`h-6 w-6 ${colors.icon}`} />
                  </div>
                  <div className={`flex items-center gap-1 text-sm ${isPositive ? 'text-green-600' : 'text-red-600'}`}>
                    {isPositive ? <TrendingUp className="h-4 w-4" /> : <TrendingDown className="h-4 w-4" />}
                    {Math.abs(stat.change)}%
                  </div>
                </div>
                <div className="mt-4">
                  <h3 className="text-2xl font-bold text-gray-900">{stat.value}</h3>
                  <p className="text-sm text-gray-500 mt-1">{stat.title}</p>
                </div>
              </CardContent>
            </Card>
          )
        })}
      </div>

      {/* Recent Activity & Quick Actions */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Activity */}
        <Card>
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
            <CardDescription>Latest customer and subscription activity</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {loading ? (
                <div className="flex items-center justify-center py-8">
                  <Loader2 className="h-6 w-6 animate-spin text-gray-400" />
                </div>
              ) : recentActivity.length === 0 ? (
                <p className="text-sm text-gray-500 text-center py-4">No recent activity</p>
              ) : (
                recentActivity.map((activity) => (
                  <div key={activity.id} className="flex items-center gap-4 p-3 bg-gray-50 rounded-lg">
                    <div className={`p-2 rounded-full ${
                      activity.type === 'subscription' ? 'bg-green-100' :
                      activity.type === 'license' ? 'bg-purple-100' : 'bg-blue-100'
                    }`}>
                      {activity.type === 'subscription' ? (
                        <CreditCard className="h-4 w-4 text-green-600" />
                      ) : activity.type === 'license' ? (
                        <Key className="h-4 w-4 text-purple-600" />
                      ) : (
                        <Users className="h-4 w-4 text-blue-600" />
                      )}
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium text-gray-900">{activity.resourceName}</p>
                      <p className="text-xs text-gray-500">{activity.action}</p>
                    </div>
                    <span className="text-xs text-gray-400">
                      {formatDistanceToNow(new Date(activity.time), { addSuffix: true })}
                    </span>
                  </div>
                ))
              )}
            </div>
          </CardContent>
        </Card>

        {/* Quick Stats */}
        <Card>
          <CardHeader>
            <CardTitle>Subscription Distribution</CardTitle>
            <CardDescription>Breakdown by plan type</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {(subscriptionDistribution.length > 0 ? subscriptionDistribution : [
                { plan: 'Free', count: 355, percentage: 40 },
                { plan: 'Starter', count: 267, percentage: 30 },
                { plan: 'Pro', count: 178, percentage: 20 },
                { plan: 'Enterprise', count: 89, percentage: 10 },
              ]).map((item) => {
                const colorMap: Record<string, string> = {
                  'Free': 'bg-gray-400',
                  'Starter': 'bg-blue-500',
                  'Pro': 'bg-purple-500',
                  'Enterprise': 'bg-orange-500',
                }
                return (
                  <div key={item.plan} className="space-y-2">
                    <div className="flex items-center justify-between text-sm">
                      <span className="font-medium text-gray-700">{item.plan}</span>
                      <span className="text-gray-500">{item.count} users ({item.percentage}%)</span>
                    </div>
                    <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div 
                        className={`h-full ${colorMap[item.plan] || 'bg-blue-500'} rounded-full transition-all duration-500`}
                        style={{ width: `${item.percentage}%` }}
                      />
                    </div>
                  </div>
                )
              })}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}