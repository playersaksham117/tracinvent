import Database from 'better-sqlite3'
import path from 'path'
import fs from 'fs'

const dbDir = path.join(process.cwd(), 'data')
const dbPath = path.join(dbDir, 'billease.db')

// Ensure data directory exists
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true })
}

const db = new Database(dbPath)

// Initialize database tables
db.exec(`
  -- Users table
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    full_name TEXT,
    company TEXT,
    role TEXT DEFAULT 'user',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  -- Sessions table
  CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token TEXT UNIQUE NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
  );

  -- Products table
  CREATE TABLE IF NOT EXISTS products (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    sku TEXT UNIQUE,
    description TEXT,
    category TEXT,
    price REAL NOT NULL DEFAULT 0,
    cost REAL DEFAULT 0,
    stock INTEGER DEFAULT 0,
    unit TEXT DEFAULT 'piece',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  -- Customers table
  CREATE TABLE IF NOT EXISTS customers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    company TEXT,
    address TEXT,
    city TEXT,
    country TEXT,
    status TEXT DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  -- Sales table
  CREATE TABLE IF NOT EXISTS sales (
    id TEXT PRIMARY KEY,
    invoice_number TEXT UNIQUE NOT NULL,
    customer_id TEXT,
    total_amount REAL NOT NULL,
    tax_amount REAL DEFAULT 0,
    discount_amount REAL DEFAULT 0,
    payment_method TEXT,
    payment_status TEXT DEFAULT 'pending',
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
  );

  -- Sale items table
  CREATE TABLE IF NOT EXISTS sale_items (
    id TEXT PRIMARY KEY,
    sale_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price REAL NOT NULL,
    total REAL NOT NULL,
    FOREIGN KEY (sale_id) REFERENCES sales(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
  );

  -- Insert demo user if not exists
  INSERT OR IGNORE INTO users (id, email, password, full_name, company, role)
  VALUES ('demo-user-id', 'demo1@billease.com', 'demo123', 'Demo User', 'Demo Company', 'admin');

  -- Insert demo products
  INSERT OR IGNORE INTO products (id, name, sku, description, price, stock, category)
  VALUES 
    ('prod-1', 'Laptop Dell XPS 15', 'DELL-XPS-15', 'High performance laptop', 1299.99, 15, 'Electronics'),
    ('prod-2', 'iPhone 14 Pro', 'IPHONE-14-PRO', 'Latest iPhone model', 999.99, 25, 'Electronics'),
    ('prod-3', 'Office Chair', 'CHAIR-001', 'Ergonomic office chair', 299.99, 50, 'Furniture'),
    ('prod-4', 'Wireless Mouse', 'MOUSE-001', 'Bluetooth wireless mouse', 29.99, 100, 'Accessories');

  -- Insert demo customers
  INSERT OR IGNORE INTO customers (id, name, email, phone, company, city, country)
  VALUES 
    ('cust-1', 'John Smith', 'john@example.com', '+1234567890', 'ABC Corp', 'New York', 'USA'),
    ('cust-2', 'Jane Doe', 'jane@example.com', '+1234567891', 'XYZ Ltd', 'London', 'UK'),
    ('cust-3', 'Bob Johnson', 'bob@example.com', '+1234567892', 'Tech Solutions', 'Toronto', 'Canada');
`)

console.log('✅ SQLite database initialized at:', dbPath)

export default db
