'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: 'LayoutDashboard' },
  { name: 'Transactions', href: '/dashboard/transactions', icon: 'ArrowLeftRight' },
  { name: 'Income', href: '/dashboard/income', icon: 'TrendingUp' },
  { name: 'Expenses', href: '/dashboard/expenses', icon: 'TrendingDown' },
  { name: 'Budgets', href: '/dashboard/budgets', icon: 'Target' },
  { name: 'Accounts', href: '/dashboard/accounts', icon: 'Wallet' },
  { name: 'Categories', href: '/dashboard/categories', icon: 'FolderKanban' },
  { name: 'Analytics', href: '/dashboard/analytics', icon: 'BarChart3' },
  { name: 'Reports', href: '/dashboard/reports', icon: 'FileText' },
  { name: 'Settings', href: '/dashboard/settings', icon: 'Settings' },
]

export function DashboardNav() {
  const pathname = usePathname()

  return (
    <nav className="p-4 space-y-1">
      {navigation.map((item) => {
        const isActive = pathname === item.href
        return (
          <Link
            key={item.name}
            href={item.href}
            className={cn(
              'flex items-center gap-3 px-3 py-2 text-sm font-medium rounded-md transition-colors',
              isActive
                ? 'bg-blue-50 text-blue-600'
                : 'text-gray-700 hover:bg-gray-50 hover:text-gray-900'
            )}
          >
            <span className="text-lg">{getIcon(item.icon)}</span>
            {item.name}
          </Link>
        )
      })}
    </nav>
  )
}

function getIcon(name: string) {
  const icons: Record<string, string> = {
    LayoutDashboard: '📊',
    ArrowLeftRight: '💱',
    TrendingUp: '📈',
    TrendingDown: '📉',
    Target: '🎯',
    Wallet: '💰',
    FolderKanban: '📂',
    BarChart3: '📊',
    FileText: '📄',
    Settings: '⚙️',
  }
  return icons[name] || '•'
}
