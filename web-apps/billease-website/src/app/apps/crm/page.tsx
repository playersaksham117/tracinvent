'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { 
  ArrowLeft,
  Plus,
  Search,
  Mail,
  Phone,
  Building,
  MapPin
} from 'lucide-react'

interface Customer {
  id: string
  name: string
  email: string | null
  phone: string | null
  company: string | null
  city: string | null
  country: string | null
  status: string
}

export default function CRMAppPage() {
  const [customers, setCustomers] = useState<Customer[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchCustomers()
  }, [])

  const fetchCustomers = async () => {
    try {
      const res = await fetch('/api/customers')
      if (res.ok) {
        const data = await res.json()
        setCustomers(data)
      }
    } catch (error) {
      console.error('Failed to fetch customers:', error)
    } finally {
      setLoading(false)
    }
  }

  const filteredCustomers = customers.filter(c => 
    c.name.toLowerCase().includes(search.toLowerCase()) ||
    c.email?.toLowerCase().includes(search.toLowerCase()) ||
    c.company?.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Header */}
      <div className="bg-white border-b sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Link href="/dashboard">
                <Button variant="ghost" size="sm">
                  <ArrowLeft className="w-4 h-4 mr-2" />
                  Back to Dashboard
                </Button>
              </Link>
              <h1 className="text-2xl font-bold bg-gradient-to-r from-purple-600 to-pink-500 bg-clip-text text-transparent">
                EASECRM • Customer Management
              </h1>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-6">
        <Card className="p-6">
          <div className="flex items-center justify-between mb-6">
            <div className="flex-1 max-w-md relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
              <input
                type="text"
                placeholder="Search customers..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
              />
            </div>
            <Button className="bg-gradient-to-r from-purple-600 to-pink-500">
              <Plus className="w-4 h-4 mr-2" />
              Add Customer
            </Button>
          </div>

          {loading ? (
            <div className="text-center py-12">
              <p className="text-slate-500">Loading customers...</p>
            </div>
          ) : filteredCustomers.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-slate-500">No customers found</p>
            </div>
          ) : (
            <div className="grid gap-4">
              {filteredCustomers.map((customer) => (
                <div
                  key={customer.id}
                  className="p-4 bg-gradient-to-r from-purple-50 to-pink-50 rounded-lg border border-purple-100 hover:shadow-md transition-shadow"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <h3 className="text-lg font-bold mb-2">{customer.name}</h3>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-slate-600">
                        {customer.email && (
                          <div className="flex items-center gap-2">
                            <Mail className="w-4 h-4" />
                            <span>{customer.email}</span>
                          </div>
                        )}
                        {customer.phone && (
                          <div className="flex items-center gap-2">
                            <Phone className="w-4 h-4" />
                            <span>{customer.phone}</span>
                          </div>
                        )}
                        {customer.company && (
                          <div className="flex items-center gap-2">
                            <Building className="w-4 h-4" />
                            <span>{customer.company}</span>
                          </div>
                        )}
                        {(customer.city || customer.country) && (
                          <div className="flex items-center gap-2">
                            <MapPin className="w-4 h-4" />
                            <span>{[customer.city, customer.country].filter(Boolean).join(', ')}</span>
                          </div>
                        )}
                      </div>
                    </div>
                    <div className="flex flex-col gap-2">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        customer.status === 'active' 
                          ? 'bg-green-100 text-green-700'
                          : 'bg-slate-100 text-slate-700'
                      }`}>
                        {customer.status}
                      </span>
                      <Button variant="outline" size="sm">View Details</Button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>
    </div>
  )
}
