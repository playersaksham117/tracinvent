'use client'

import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { ArrowLeft, Package, AlertTriangle, TrendingUp, Boxes } from 'lucide-react'

export default function InventoryAppPage() {
  return (
    <div className="min-h-screen bg-slate-50">
      <div className="bg-white border-b sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center gap-4">
            <Link href="/dashboard">
              <Button variant="ghost" size="sm">
                <ArrowLeft className="w-4 h-4 mr-2" />
                Back to Dashboard
              </Button>
            </Link>
            <h1 className="text-2xl font-bold bg-gradient-to-r from-orange-600 to-red-500 bg-clip-text text-transparent">
              TRACINVENT • Inventory Tracking
            </h1>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-600">Total Items</span>
              <Package className="w-5 h-5 text-blue-600" />
            </div>
            <p className="text-3xl font-bold text-blue-600">1,234</p>
            <p className="text-sm text-slate-500">Across all locations</p>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-600">Low Stock</span>
              <AlertTriangle className="w-5 h-5 text-orange-600" />
            </div>
            <p className="text-3xl font-bold text-orange-600">23</p>
            <p className="text-sm text-orange-600">Needs reorder</p>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-600">Categories</span>
              <Boxes className="w-5 h-5 text-purple-600" />
            </div>
            <p className="text-3xl font-bold text-purple-600">8</p>
            <p className="text-sm text-slate-500">Product categories</p>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-600">Stock Value</span>
              <TrendingUp className="w-5 h-5 text-green-600" />
            </div>
            <p className="text-3xl font-bold text-green-600">$45,820</p>
            <p className="text-sm text-green-600">+8.3% this month</p>
          </Card>
        </div>

        <Card className="p-8 text-center">
          <Package className="w-16 h-16 text-orange-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold mb-2">TRACINVENT Module</h2>
          <p className="text-slate-600 mb-6">
            Complete inventory tracking features including:
            <br />
            Real-time stock tracking, Multi-location support, Barcode scanning, Purchase orders, and more.
          </p>
          <div className="inline-flex gap-3">
            <Button className="bg-gradient-to-r from-orange-600 to-red-500">
              View Stock
            </Button>
            <Button variant="outline">Add Product</Button>
          </div>
        </Card>
      </div>
    </div>
  )
}
