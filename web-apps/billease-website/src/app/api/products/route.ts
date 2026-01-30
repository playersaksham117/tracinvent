import { NextRequest, NextResponse } from 'next/server'
import db from '@/lib/db'

// Initialize database on module load
const initDb = () => {
  try {
    // Verify database is accessible
    db.prepare('SELECT COUNT(*) as count FROM products').get()
  } catch (error) {
    console.error('Database initialization error:', error)
  }
}

initDb()

export async function GET() {
  try {
    const products = db.prepare('SELECT * FROM products ORDER BY name').all()
    return NextResponse.json(products)
  } catch (error) {
    console.error('Error fetching products:', error)
    return NextResponse.json({ error: 'Failed to fetch products' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { id, name, sku, description, price, cost, stock, unit, category } = body

    const stmt = db.prepare(`
      INSERT INTO products (id, name, sku, description, price, cost, stock, unit, category)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `)

    stmt.run(id, name, sku, description || '', price, cost || 0, stock || 0, unit || 'piece', category || '')

    return NextResponse.json({ success: true, id })
  } catch (error) {
    console.error('Error creating product:', error)
    return NextResponse.json({ error: 'Failed to create product' }, { status: 500 })
  }
}
