'use client'

import { useState, useEffect, useRef } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import type { Product, Customer, PaymentMethod, Discount } from '@/types/database.types'
import { 
  ArrowLeft, 
  Plus, 
  Search,
  ShoppingCart,
  DollarSign,
  Trash2,
  User,
  Scan,
  Tag,
  X,
  Check
} from 'lucide-react'

interface CartItem extends Product {
  quantity: number
  discount: number
  line_total: number
}

export default function POSAppPage() {
  const [products, setProducts] = useState<Product[]>([])
  const [customers, setCustomers] = useState<Customer[]>([])
  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>([])
  const [cart, setCart] = useState<CartItem[]>([])
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null)
  const [search, setSearch] = useState('')
  const [barcodeInput, setBarcodeInput] = useState('')
  const [loading, setLoading] = useState(true)
  
  // Checkout modal states
  const [showCheckout, setShowCheckout] = useState(false)
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState<string>('cash')
  const [amountPaid, setAmountPaid] = useState('')
  const [referenceNumber, setReferenceNumber] = useState('')
  const [discountCode, setDiscountCode] = useState('')
  const [appliedDiscount, setAppliedDiscount] = useState<any>(null)
  const [notes, setNotes] = useState('')
  
  // Customer modal
  const [showCustomerModal, setShowCustomerModal] = useState(false)
  const [showCustomerForm, setShowCustomerForm] = useState(false)
  const [newCustomer, setNewCustomer] = useState({
    name: '',
    phone: '',
    email: '',
    address: ''
  })

  const barcodeInputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    fetchInitialData()
  }, [])

  const fetchInitialData = async () => {
    try {
      await Promise.all([
        fetchProducts(),
        fetchCustomers(),
        fetchPaymentMethods()
      ])
    } catch (error) {
      console.error('Failed to fetch initial data:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchProducts = async () => {
    try {
      const res = await fetch('/api/products')
      if (res.ok) {
        const data = await res.json()
        setProducts(data)
      }
    } catch (error) {
      console.error('Failed to fetch products:', error)
    }
  }

  const fetchCustomers = async () => {
    try {
      const res = await fetch('/api/pos/customers?active=true')
      if (res.ok) {
        const data = await res.json()
        setCustomers(data)
      }
    } catch (error) {
      console.error('Failed to fetch customers:', error)
    }
  }

  const fetchPaymentMethods = async () => {
    try {
      const res = await fetch('/api/pos/payment-methods')
      if (res.ok) {
        const data = await res.json()
        setPaymentMethods(data)
      }
    } catch (error) {
      console.error('Failed to fetch payment methods:', error)
    }
  }

  const handleBarcodeSearch = async () => {
    if (!barcodeInput.trim()) return
    
    const product = products.find(p => p.barcode === barcodeInput.trim())
    if (product) {
      addToCart(product)
      setBarcodeInput('')
    } else {
      alert('Product not found with barcode: ' + barcodeInput)
    }
  }

  const addToCart = (product: Product) => {
    if (product.stock_quantity <= 0) {
      alert('Product is out of stock')
      return
    }

    const existing = cart.find(item => item.id === product.id)
    if (existing) {
      if (existing.quantity >= product.stock_quantity) {
        alert('Cannot add more than available stock')
        return
      }
      updateCart(cart.map(item => 
        item.id === product.id 
          ? { ...item, quantity: item.quantity + 1, line_total: calculateLineTotal(item, item.quantity + 1) }
          : item
      ))
    } else {
      const newItem: CartItem = {
        ...product,
        quantity: 1,
        discount: 0,
        line_total: product.selling_price * (1 + product.tax_rate / 100)
      }
      updateCart([...cart, newItem])
    }
  }

  const calculateLineTotal = (item: CartItem, quantity: number) => {
    const subtotal = item.selling_price * quantity
    const tax = subtotal * (item.tax_rate / 100)
    return subtotal + tax - item.discount
  }

  const removeFromCart = (productId: string) => {
    updateCart(cart.filter(item => item.id !== productId))
  }

  const updateQuantity = (productId: string, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(productId)
    } else {
      const product = products.find(p => p.id === productId)
      if (product && quantity > product.stock_quantity) {
        alert('Cannot add more than available stock')
        return
      }
      updateCart(cart.map(item => 
        item.id === productId 
          ? { ...item, quantity, line_total: calculateLineTotal(item, quantity) } 
          : item
      ))
    }
  }

  const updateItemDiscount = (productId: string, discount: number) => {
    updateCart(cart.map(item => {
      if (item.id === productId) {
        const newItem = { ...item, discount }
        return { ...newItem, line_total: calculateLineTotal(newItem, item.quantity) }
      }
      return item
    }))
  }

  const updateCart = (newCart: CartItem[]) => {
    setCart(newCart)
    if (appliedDiscount) {
      validateDiscount(appliedDiscount.code)
    }
  }

  const getSubtotal = () => {
    return cart.reduce((sum, item) => sum + (item.selling_price * item.quantity), 0)
  }

  const getTaxAmount = () => {
    return cart.reduce((sum, item) => 
      sum + ((item.selling_price * item.quantity) * (item.tax_rate / 100)), 0)
  }

  const getItemDiscounts = () => {
    return cart.reduce((sum, item) => sum + item.discount, 0)
  }

  const getTotal = () => {
    const subtotal = getSubtotal()
    const tax = getTaxAmount()
    const itemDiscounts = getItemDiscounts()
    const globalDiscount = appliedDiscount?.calculated_discount || 0
    return subtotal + tax - itemDiscounts - globalDiscount
  }

  const getChangeAmount = () => {
    const paid = parseFloat(amountPaid) || 0
    return Math.max(0, paid - getTotal())
  }

  const validateDiscount = async (code: string) => {
    if (!code.trim()) {
      setAppliedDiscount(null)
      return
    }

    try {
      const res = await fetch('/api/pos/discounts/validate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          code: code.trim(), 
          purchase_amount: getSubtotal() 
        })
      })
      
      const data = await res.json()
      
      if (data.valid) {
        setAppliedDiscount(data.discount)
      } else {
        alert(data.error || 'Invalid discount code')
        setAppliedDiscount(null)
      }
    } catch (error) {
      console.error('Failed to validate discount:', error)
      alert('Failed to validate discount code')
    }
  }

  const saveCustomer = async () => {
    if (!newCustomer.name || !newCustomer.phone) {
      alert('Name and phone are required')
      return
    }

    try {
      const res = await fetch('/api/pos/customers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newCustomer)
      })

      if (res.ok) {
        const customer = await res.json()
        setSelectedCustomer(customer)
        setCustomers([...customers, customer])
        setShowCustomerForm(false)
        setShowCustomerModal(false)
        setNewCustomer({ name: '', phone: '', email: '', address: '' })
      }
    } catch (error) {
      console.error('Failed to save customer:', error)
      alert('Failed to save customer')
    }
  }

  const processCheckout = async () => {
    if (cart.length === 0) {
      alert('Cart is empty')
      return
    }

    const total = getTotal()
    const paid = parseFloat(amountPaid) || 0

    if (paid < total) {
      alert('Amount paid is less than total')
      return
    }

    try {
      const saleData = {
        customer_id: selectedCustomer?.id,
        customer_name: selectedCustomer?.name,
        customer_phone: selectedCustomer?.phone,
        customer_email: selectedCustomer?.email,
        items: cart.map(item => ({
          product_id: item.id,
          product_name: item.name,
          quantity: item.quantity,
          unit_price: item.selling_price,
          tax_rate: item.tax_rate,
          discount: item.discount
        })),
        discount_amount: (appliedDiscount?.calculated_discount || 0) + getItemDiscounts(),
        amount_paid: paid,
        payment_method: selectedPaymentMethod,
        reference_number: referenceNumber || undefined,
        notes: notes || undefined,
        status: 'completed',
        payment_status: 'paid'
      }

      const res = await fetch('/api/pos/sales', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(saleData)
      })

      if (res.ok) {
        const sale = await res.json()
        alert(`Sale completed! Invoice #${sale.sale_number}`)
        
        // Print receipt
        printReceipt(sale)
        
        // Reset everything
        setCart([])
        setSelectedCustomer(null)
        setAppliedDiscount(null)
        setDiscountCode('')
        setAmountPaid('')
        setReferenceNumber('')
        setNotes('')
        setShowCheckout(false)
        fetchProducts() // Refresh stock
      } else {
        const error = await res.json()
        alert('Failed to process sale: ' + (error.error || 'Unknown error'))
      }
    } catch (error) {
      console.error('Failed to process checkout:', error)
      alert('Failed to process sale')
    }
  }

  const printReceipt = (sale: any) => {
    const receiptWindow = window.open('', '_blank', 'width=300,height=600')
    if (!receiptWindow) return

    const receiptHTML = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Receipt - ${sale.sale_number}</title>
        <style>
          body { font-family: monospace; font-size: 12px; margin: 20px; }
          .center { text-align: center; }
          .right { text-align: right; }
          .bold { font-weight: bold; }
          hr { border: none; border-top: 1px dashed #000; margin: 10px 0; }
          table { width: 100%; }
          .line-item { margin: 5px 0; }
        </style>
      </head>
      <body>
        <div class="center bold">
          <h2>INVOICE</h2>
          <p>${sale.sale_number}</p>
          <p>${new Date(sale.completed_at).toLocaleString()}</p>
        </div>
        <hr>
        ${selectedCustomer ? `
          <div>
            <p><strong>Customer:</strong> ${selectedCustomer.name}</p>
            <p><strong>Phone:</strong> ${selectedCustomer.phone}</p>
          </div>
          <hr>
        ` : ''}
        <div>
          ${cart.map(item => `
            <div class="line-item">
              <div>${item.name}</div>
              <div>${item.quantity} x $${item.selling_price.toFixed(2)} = $${(item.selling_price * item.quantity).toFixed(2)}</div>
              ${item.tax_rate > 0 ? `<div style="padding-left: 10px;">Tax (${item.tax_rate}%): $${((item.selling_price * item.quantity * item.tax_rate) / 100).toFixed(2)}</div>` : ''}
              ${item.discount > 0 ? `<div style="padding-left: 10px;">Discount: -$${item.discount.toFixed(2)}</div>` : ''}
            </div>
          `).join('')}
        </div>
        <hr>
        <table>
          <tr><td>Subtotal:</td><td class="right">$${getSubtotal().toFixed(2)}</td></tr>
          <tr><td>Tax:</td><td class="right">$${getTaxAmount().toFixed(2)}</td></tr>
          ${appliedDiscount ? `<tr><td>Discount (${appliedDiscount.code}):</td><td class="right">-$${appliedDiscount.calculated_discount.toFixed(2)}</td></tr>` : ''}
          <tr class="bold"><td>TOTAL:</td><td class="right">$${getTotal().toFixed(2)}</td></tr>
          <tr><td>Paid:</td><td class="right">$${parseFloat(amountPaid).toFixed(2)}</td></tr>
          <tr><td>Change:</td><td class="right">$${getChangeAmount().toFixed(2)}</td></tr>
        </table>
        <hr>
        <div class="center">
          <p>Payment Method: ${paymentMethods.find(pm => pm.code === selectedPaymentMethod)?.name || selectedPaymentMethod}</p>
          ${referenceNumber ? `<p>Reference: ${referenceNumber}</p>` : ''}
          <p>Thank you for your business!</p>
        </div>
        <script>
          window.onload = () => {
            window.print();
            setTimeout(() => window.close(), 500);
          };
        </script>
      </body>
      </html>
    `

    receiptWindow.document.write(receiptHTML)
    receiptWindow.document.close()
  }

  const openCheckout = () => {
    if (cart.length === 0) {
      alert('Cart is empty')
      return
    }
    setAmountPaid(getTotal().toFixed(2))
    setShowCheckout(true)
  }

  const filteredProducts = products.filter(p => 
    p.name.toLowerCase().includes(search.toLowerCase()) ||
    (p.sku && p.sku.toLowerCase().includes(search.toLowerCase())) ||
    (p.category && p.category.toLowerCase().includes(search.toLowerCase()))
  )

  const filteredCustomers = customers.filter(c =>
    c.name.toLowerCase().includes(search.toLowerCase()) ||
    (c.phone && c.phone.includes(search))
  )

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center">
        <p className="text-xl text-slate-600">Loading POS System...</p>
      </div>
    )
  }

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
                  Back
                </Button>
              </Link>
              <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-500 bg-clip-text text-transparent">
                💳 Point of Sale
              </h1>
            </div>
            <div className="flex items-center gap-2">
              {selectedCustomer && (
                <div className="px-3 py-1 bg-blue-50 rounded-lg flex items-center gap-2">
                  <User className="w-4 h-4 text-blue-600" />
                  <span className="text-sm font-medium">{selectedCustomer.name}</span>
                  <button 
                    onClick={() => setSelectedCustomer(null)}
                    className="text-blue-600 hover:text-blue-800"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Products Section */}
          <div className="lg:col-span-2 space-y-4">
            {/* Barcode Scanner */}
            <Card className="p-4">
              <div className="flex gap-2">
                <div className="flex-1 relative">
                  <Scan className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
                  <input
                    ref={barcodeInputRef}
                    type="text"
                    placeholder="Scan or enter barcode..."
                    value={barcodeInput}
                    onChange={(e) => setBarcodeInput(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && handleBarcodeSearch()}
                    className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <Button onClick={handleBarcodeSearch}>
                  <Search className="w-4 h-4" />
                </Button>
              </div>
            </Card>

            {/* Product Search & Grid */}
            <Card className="p-6">
              <div className="flex items-center gap-4 mb-6">
                <div className="flex-1 relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
                  <input
                    type="text"
                    placeholder="Search products by name, SKU, or category..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              {filteredProducts.length === 0 ? (
                <div className="text-center py-12">
                  <p className="text-slate-500">No products found</p>
                </div>
              ) : (
                <div className="grid grid-cols-2 md:grid-cols-3 gap-4 max-h-[600px] overflow-y-auto">
                  {filteredProducts.map((product) => (
                    <button
                      key={product.id}
                      onClick={() => addToCart(product)}
                      disabled={product.stock_quantity <= 0}
                      className={`p-4 rounded-lg border-2 transition-all text-left ${
                        product.stock_quantity <= 0
                          ? 'bg-slate-100 border-slate-200 opacity-50 cursor-not-allowed'
                          : 'bg-slate-50 hover:bg-blue-50 hover:border-blue-300 border-transparent'
                      }`}
                    >
                      <h3 className="font-semibold text-sm mb-1 truncate">{product.name}</h3>
                      {product.sku && <p className="text-xs text-slate-500 mb-1">{product.sku}</p>}
                      {product.category && (
                        <span className="inline-block px-2 py-0.5 bg-slate-200 text-xs rounded mb-2">
                          {product.category}
                        </span>
                      )}
                      <div className="flex items-center justify-between mt-2">
                        <span className="text-lg font-bold text-blue-600">
                          ${product.selling_price.toFixed(2)}
                        </span>
                        <span className={`text-xs ${product.stock_quantity <= product.reorder_level ? 'text-red-500' : 'text-slate-500'}`}>
                          Stock: {product.stock_quantity}
                        </span>
                      </div>
                      {product.tax_rate > 0 && (
                        <p className="text-xs text-slate-500 mt-1">+{product.tax_rate}% tax</p>
                      )}
                    </button>
                  ))}
                </div>
              )}
            </Card>
          </div>

          {/* Cart & Checkout Section */}
          <div className="lg:col-span-1">
            <Card className="p-6 sticky top-24">
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-2">
                  <ShoppingCart className="w-5 h-5 text-blue-600" />
                  <h2 className="text-xl font-bold">Cart ({cart.length})</h2>
                </div>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => setShowCustomerModal(true)}
                >
                  <User className="w-4 h-4 mr-1" />
                  Customer
                </Button>
              </div>

              {cart.length === 0 ? (
                <div className="text-center py-12">
                  <ShoppingCart className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                  <p className="text-slate-500">Cart is empty</p>
                  <p className="text-xs text-slate-400 mt-2">Scan or select products to start</p>
                </div>
              ) : (
                <>
                  <div className="space-y-3 mb-4 max-h-64 overflow-y-auto">
                    {cart.map((item) => (
                      <div key={item.id} className="p-3 bg-slate-50 rounded-lg">
                        <div className="flex items-start justify-between mb-2">
                          <div className="flex-1">
                            <h3 className="font-semibold text-sm">{item.name}</h3>
                            <p className="text-xs text-slate-500">
                              ${item.selling_price.toFixed(2)} each
                              {item.tax_rate > 0 && ` (+${item.tax_rate}% tax)`}
                            </p>
                          </div>
                          <button
                            onClick={() => removeFromCart(item.id)}
                            className="text-red-500 hover:text-red-700"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => updateQuantity(item.id, item.quantity - 1)}
                            className="w-7 h-7 bg-white border rounded hover:bg-slate-100 flex items-center justify-center"
                          >
                            -
                          </button>
                          <span className="flex-1 text-center font-semibold text-sm">{item.quantity}</span>
                          <button
                            onClick={() => updateQuantity(item.id, item.quantity + 1)}
                            className="w-7 h-7 bg-white border rounded hover:bg-slate-100 flex items-center justify-center"
                          >
                            +
                          </button>
                          <span className="font-bold text-blue-600 text-sm ml-2">
                            ${item.line_total.toFixed(2)}
                          </span>
                        </div>
                        <div className="mt-2 flex gap-2">
                          <input
                            type="number"
                            placeholder="Item discount"
                            value={item.discount || ''}
                            onChange={(e) => updateItemDiscount(item.id, parseFloat(e.target.value) || 0)}
                            className="flex-1 px-2 py-1 text-xs border rounded"
                            step="0.01"
                            min="0"
                          />
                        </div>
                      </div>
                    ))}
                  </div>

                  {/* Discount Code */}
                  <div className="mb-4">
                    <div className="flex gap-2">
                      <input
                        type="text"
                        placeholder="Discount code"
                        value={discountCode}
                        onChange={(e) => setDiscountCode(e.target.value)}
                        className="flex-1 px-3 py-2 text-sm border rounded"
                      />
                      <Button
                        size="sm"
                        onClick={() => validateDiscount(discountCode)}
                      >
                        <Tag className="w-4 h-4" />
                      </Button>
                    </div>
                    {appliedDiscount && (
                      <div className="mt-2 px-3 py-2 bg-green-50 border border-green-200 rounded flex items-center justify-between">
                        <span className="text-xs text-green-700">
                          {appliedDiscount.name} applied
                        </span>
                        <button
                          onClick={() => {
                            setAppliedDiscount(null)
                            setDiscountCode('')
                          }}
                          className="text-green-700 hover:text-green-900"
                        >
                          <X className="w-3 h-3" />
                        </button>
                      </div>
                    )}
                  </div>

                  {/* Totals */}
                  <div className="border-t pt-4 space-y-2">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-slate-600">Subtotal:</span>
                      <span>${getSubtotal().toFixed(2)}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-slate-600">Tax:</span>
                      <span>${getTaxAmount().toFixed(2)}</span>
                    </div>
                    {(getItemDiscounts() > 0 || appliedDiscount) && (
                      <div className="flex items-center justify-between text-sm text-green-600">
                        <span>Discount:</span>
                        <span>-${((appliedDiscount?.calculated_discount || 0) + getItemDiscounts()).toFixed(2)}</span>
                      </div>
                    )}
                    <div className="flex items-center justify-between text-lg font-bold pt-2 border-t">
                      <span>Total:</span>
                      <span className="text-2xl text-blue-600">${getTotal().toFixed(2)}</span>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="mt-4 space-y-2">
                    <Button
                      onClick={openCheckout}
                      className="w-full bg-gradient-to-r from-blue-600 to-cyan-500 hover:from-blue-700 hover:to-cyan-600"
                      size="lg"
                    >
                      <DollarSign className="w-5 h-5 mr-2" />
                      Checkout
                    </Button>
                    <Button
                      onClick={() => setCart([])}
                      variant="outline"
                      className="w-full"
                    >
                      Clear Cart
                    </Button>
                  </div>
                </>
              )}
            </Card>
          </div>
        </div>
      </div>

      {/* Checkout Modal */}
      {showCheckout && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-bold">Checkout</h2>
                <button
                  onClick={() => setShowCheckout(false)}
                  className="text-slate-500 hover:text-slate-700"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              {/* Order Summary */}
              <div className="mb-6 p-4 bg-slate-50 rounded-lg">
                <h3 className="font-semibold mb-2">Order Summary</h3>
                <div className="space-y-1 text-sm">
                  {cart.map(item => (
                    <div key={item.id} className="flex justify-between">
                      <span>{item.name} x {item.quantity}</span>
                      <span>${item.line_total.toFixed(2)}</span>
                    </div>
                  ))}
                </div>
                <div className="border-t mt-2 pt-2 font-bold flex justify-between">
                  <span>Total:</span>
                  <span className="text-xl text-blue-600">${getTotal().toFixed(2)}</span>
                </div>
              </div>

              {/* Payment Method */}
              <div className="mb-4">
                <label className="block text-sm font-medium mb-2">Payment Method</label>
                <div className="grid grid-cols-2 gap-2">
                  {paymentMethods.map(method => (
                    <button
                      key={method.id}
                      onClick={() => setSelectedPaymentMethod(method.code)}
                      className={`p-3 border-2 rounded-lg text-sm font-medium transition-all ${
                        selectedPaymentMethod === method.code
                          ? 'border-blue-500 bg-blue-50 text-blue-700'
                          : 'border-slate-200 hover:border-slate-300'
                      }`}
                    >
                      <span className="mr-2">{method.icon}</span>
                      {method.name}
                    </button>
                  ))}
                </div>
              </div>

              {/* Amount Paid */}
              <div className="mb-4">
                <label className="block text-sm font-medium mb-2">Amount Paid</label>
                <input
                  type="number"
                  value={amountPaid}
                  onChange={(e) => setAmountPaid(e.target.value)}
                  className="w-full px-4 py-2 border rounded-lg"
                  step="0.01"
                  min="0"
                />
                {amountPaid && parseFloat(amountPaid) >= getTotal() && (
                  <p className="text-sm text-green-600 mt-1">
                    Change: ${getChangeAmount().toFixed(2)}
                  </p>
                )}
              </div>

              {/* Reference Number */}
              {paymentMethods.find(pm => pm.code === selectedPaymentMethod)?.requires_reference && (
                <div className="mb-4">
                  <label className="block text-sm font-medium mb-2">
                    Reference Number
                  </label>
                  <input
                    type="text"
                    value={referenceNumber}
                    onChange={(e) => setReferenceNumber(e.target.value)}
                    placeholder="Transaction ID / Reference"
                    className="w-full px-4 py-2 border rounded-lg"
                  />
                </div>
              )}

              {/* Notes */}
              <div className="mb-6">
                <label className="block text-sm font-medium mb-2">Notes (Optional)</label>
                <textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Add notes..."
                  className="w-full px-4 py-2 border rounded-lg"
                  rows={3}
                />
              </div>

              {/* Actions */}
              <div className="flex gap-3">
                <Button
                  onClick={processCheckout}
                  className="flex-1 bg-gradient-to-r from-green-600 to-emerald-500 hover:from-green-700 hover:to-emerald-600"
                  size="lg"
                >
                  <Check className="w-5 h-5 mr-2" />
                  Complete Sale
                </Button>
                <Button
                  onClick={() => setShowCheckout(false)}
                  variant="outline"
                  size="lg"
                >
                  Cancel
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Customer Modal */}
      {showCustomerModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-bold">
                  {showCustomerForm ? 'Add Customer' : 'Select Customer'}
                </h2>
                <button
                  onClick={() => {
                    setShowCustomerModal(false)
                    setShowCustomerForm(false)
                  }}
                  className="text-slate-500 hover:text-slate-700"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              {!showCustomerForm ? (
                <>
                  <div className="mb-4">
                    <input
                      type="text"
                      placeholder="Search customers..."
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                      className="w-full px-4 py-2 border rounded-lg"
                    />
                  </div>
                  
                  <div className="space-y-2 mb-4 max-h-96 overflow-y-auto">
                    {filteredCustomers.map(customer => (
                      <button
                        key={customer.id}
                        onClick={() => {
                          setSelectedCustomer(customer)
                          setShowCustomerModal(false)
                          setSearch('')
                        }}
                        className="w-full p-4 border-2 rounded-lg text-left hover:border-blue-500 hover:bg-blue-50 transition-all"
                      >
                        <div className="font-semibold">{customer.name}</div>
                        <div className="text-sm text-slate-600">{customer.phone}</div>
                        {customer.email && <div className="text-xs text-slate-500">{customer.email}</div>}
                      </button>
                    ))}
                  </div>

                  <Button
                    onClick={() => setShowCustomerForm(true)}
                    className="w-full"
                    variant="outline"
                  >
                    <Plus className="w-4 h-4 mr-2" />
                    Add New Customer
                  </Button>
                </>
              ) : (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium mb-2">Name *</label>
                    <input
                      type="text"
                      value={newCustomer.name}
                      onChange={(e) => setNewCustomer({...newCustomer, name: e.target.value})}
                      className="w-full px-4 py-2 border rounded-lg"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-2">Phone *</label>
                    <input
                      type="tel"
                      value={newCustomer.phone}
                      onChange={(e) => setNewCustomer({...newCustomer, phone: e.target.value})}
                      className="w-full px-4 py-2 border rounded-lg"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-2">Email</label>
                    <input
                      type="email"
                      value={newCustomer.email}
                      onChange={(e) => setNewCustomer({...newCustomer, email: e.target.value})}
                      className="w-full px-4 py-2 border rounded-lg"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-2">Address</label>
                    <textarea
                      value={newCustomer.address}
                      onChange={(e) => setNewCustomer({...newCustomer, address: e.target.value})}
                      className="w-full px-4 py-2 border rounded-lg"
                      rows={3}
                    />
                  </div>
                  <div className="flex gap-3">
                    <Button onClick={saveCustomer} className="flex-1">
                      Save Customer
                    </Button>
                    <Button
                      onClick={() => setShowCustomerForm(false)}
                      variant="outline"
                    >
                      Back
                    </Button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
