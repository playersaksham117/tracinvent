'use client'

interface Stat {
  label: string
  value: string
  change: string
  trend: 'up' | 'down' | 'neutral'
}

interface DashboardStatsProps {
  stats: Stat[]
}

export function DashboardStats({ stats }: DashboardStatsProps) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      {stats.map((stat) => (
        <div
          key={stat.label}
          className="bg-white rounded-lg border border-gray-200 p-6"
        >
          <p className="text-sm font-medium text-gray-600">{stat.label}</p>
          <p className="text-2xl font-bold text-gray-900 mt-2">{stat.value}</p>
          <div className="flex items-center gap-1 mt-2">
            {stat.trend === 'up' && (
              <span className="text-green-600">↑</span>
            )}
            {stat.trend === 'down' && (
              <span className="text-red-600">↓</span>
            )}
            <span
              className={`text-sm ${
                stat.trend === 'up'
                  ? 'text-green-600'
                  : stat.trend === 'down'
                  ? 'text-red-600'
                  : 'text-gray-600'
              }`}
            >
              {stat.change}
            </span>
          </div>
        </div>
      ))}
    </div>
  )
}
