import { NextRequest, NextResponse } from 'next/server'
import db from '@/lib/db'

export async function GET() {
  try {
    const customers = db.prepare('SELECT * FROM customers ORDER BY name').all()
    return NextResponse.json(customers)
  } catch (error) {
    console.error('Error fetching customers:', error)
    return NextResponse.json({ error: 'Failed to fetch customers' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { id, name, email, phone, company, address, city, country, status } = body

    const stmt = db.prepare(`
      INSERT INTO customers (id, name, email, phone, company, address, city, country, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `)

    stmt.run(
      id, 
      name, 
      email || null, 
      phone || null, 
      company || null, 
      address || null, 
      city || null, 
      country || null, 
      status || 'active'
    )

    return NextResponse.json({ success: true, id })
  } catch (error) {
    console.error('Error creating customer:', error)
    return NextResponse.json({ error: 'Failed to create customer' }, { status: 500 })
  }
}
