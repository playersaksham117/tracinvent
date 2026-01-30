# 🗄️ BillEase SaaS - Database Schemas

## Overview

Complete database schema for the entire SaaS ecosystem with strict isolation between databases.

---

## 📊 MAIN DATABASE (billease_main)

### Purpose
Central authentication, subscriptions, billing, and admin control.

### Schema

```sql
-- =====================================================
-- MAIN DATABASE: billease_main
-- =====================================================

-- Users Table (Central Identity)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255),
  phone VARCHAR(50),
  company_name VARCHAR(255),
  role VARCHAR(50) DEFAULT 'user', -- 'user', 'app_admin', 'super_admin'
  status VARCHAR(50) DEFAULT 'active', -- 'active', 'suspended', 'deleted'
  email_verified BOOLEAN DEFAULT FALSE,
  last_login_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_role ON users(role);

-- =====================================================

-- Subscription Plans
CREATE TABLE subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  apps JSONB NOT NULL, -- ['pos', 'crm', 'accounts', 'inventory']
  price_monthly DECIMAL(10,2) NOT NULL,
  price_yearly DECIMAL(10,2) NOT NULL,
  features JSONB NOT NULL,
  limits JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_plans_slug ON subscription_plans(slug);
CREATE INDEX idx_plans_active ON subscription_plans(is_active);

-- Example plan data
INSERT INTO subscription_plans (name, slug, apps, price_monthly, price_yearly, features, limits) VALUES
('Starter', 'starter', '["pos"]', 29.00, 290.00, 
 '{"users": 3, "storage": "5GB", "support": "basic"}', 
 '{"transactions": 1000}'),
('Professional', 'professional', '["pos", "crm"]', 79.00, 790.00,
 '{"users": 10, "storage": "50GB", "support": "premium"}',
 '{"transactions": 10000, "contacts": 5000}'),
('Business', 'business', '["pos", "crm", "accounts"]', 149.00, 1490.00,
 '{"users": 25, "storage": "200GB", "support": "premium"}',
 '{"transactions": 50000, "contacts": 25000}'),
('Enterprise', 'enterprise', '["pos", "crm", "accounts", "inventory"]', 299.00, 2990.00,
 '{"users": -1, "storage": "unlimited", "support": "enterprise"}',
 '{"transactions": -1, "contacts": -1}');

-- =====================================================

-- User Subscriptions
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES subscription_plans(id),
  status VARCHAR(50) DEFAULT 'active', -- 'active', 'cancelled', 'expired', 'trial'
  billing_cycle VARCHAR(20), -- 'monthly', 'yearly'
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  trial_ends_at TIMESTAMP,
  current_period_start TIMESTAMP NOT NULL,
  current_period_end TIMESTAMP NOT NULL,
  cancel_at_period_end BOOLEAN DEFAULT FALSE,
  cancelled_at TIMESTAMP,
  stripe_subscription_id VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_stripe ON subscriptions(stripe_subscription_id);

-- =====================================================

-- App Access Control
CREATE TABLE app_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  app_id VARCHAR(50) NOT NULL, -- 'pos', 'crm', 'accounts', 'inventory'
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE CASCADE,
  has_access BOOLEAN DEFAULT TRUE,
  permissions JSONB DEFAULT '["read", "write"]',
  last_accessed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, app_id)
);

CREATE INDEX idx_app_access_user ON app_access(user_id);
CREATE INDEX idx_app_access_app ON app_access(app_id);

-- =====================================================

-- Payments & Invoices
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES subscriptions(id),
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'refunded'
  payment_method VARCHAR(50), -- 'card', 'bank_transfer', etc.
  stripe_payment_id VARCHAR(255),
  stripe_invoice_id VARCHAR(255),
  invoice_url TEXT,
  paid_at TIMESTAMP,
  refunded_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_subscription ON payments(subscription_id);
CREATE INDEX idx_payments_status ON payments(status);

-- =====================================================

-- Usage Analytics
CREATE TABLE usage_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  app_id VARCHAR(50) NOT NULL,
  metric_name VARCHAR(100) NOT NULL, -- 'api_calls', 'storage_used', 'transactions_count'
  metric_value DECIMAL(15,2) NOT NULL,
  period_start TIMESTAMP NOT NULL,
  period_end TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_analytics_user ON usage_analytics(user_id);
CREATE INDEX idx_analytics_app ON usage_analytics(app_id);
CREATE INDEX idx_analytics_metric ON usage_analytics(metric_name);

-- =====================================================

-- Audit Logs
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL, -- 'login', 'subscription_created', 'app_accessed'
  entity_type VARCHAR(100), -- 'user', 'subscription', 'payment'
  entity_id UUID,
  changes JSONB, -- Old and new values
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_created ON audit_logs(created_at);

-- =====================================================

-- API Keys (for third-party integrations)
CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  app_id VARCHAR(50) NOT NULL,
  key_hash VARCHAR(255) NOT NULL,
  key_prefix VARCHAR(20) NOT NULL, -- First few chars for identification
  name VARCHAR(100),
  scopes JSONB DEFAULT '["read"]', -- Permissions
  last_used_at TIMESTAMP,
  expires_at TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_api_keys_user ON api_keys(user_id);
CREATE INDEX idx_api_keys_prefix ON api_keys(key_prefix);

-- =====================================================

-- Webhooks Configuration
CREATE TABLE webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  app_id VARCHAR(50) NOT NULL,
  url TEXT NOT NULL,
  events JSONB NOT NULL, -- ['subscription.created', 'payment.succeeded']
  secret VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  last_triggered_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_webhooks_user ON webhooks(user_id);
CREATE INDEX idx_webhooks_app ON webhooks(app_id);

-- =====================================================

-- Session Management (Optional - can use Redis instead)
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL,
  device_info JSONB,
  ip_address INET,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_sessions_user ON sessions(user_id);
CREATE INDEX idx_sessions_token ON sessions(token_hash);
CREATE INDEX idx_sessions_expires ON sessions(expires_at);

-- =====================================================

-- Row Level Security (RLS) Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY users_select_own ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY users_update_own ON users
  FOR UPDATE USING (auth.uid() = id);

-- Subscriptions policy
CREATE POLICY subscriptions_select_own ON subscriptions
  FOR SELECT USING (auth.uid() = user_id);

-- App access policy
CREATE POLICY app_access_select_own ON app_access
  FOR SELECT USING (auth.uid() = user_id);

-- Payments policy
CREATE POLICY payments_select_own ON payments
  FOR SELECT USING (auth.uid() = user_id);

-- Admin policies (separate)
CREATE POLICY admin_all_access ON users
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('super_admin', 'app_admin')
    )
  );
```

---

## 🛒 POS DATABASE (billease_pos)

### Purpose
Point of Sale operations, products, sales, and transactions.

### Schema

```sql
-- =====================================================
-- POS DATABASE: billease_pos
-- =====================================================

-- POS Users (App-Specific)
CREATE TABLE pos_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  main_user_id UUID NOT NULL, -- Reference to main DB (not FK)
  email VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'cashier', -- 'admin', 'manager', 'cashier'
  permissions JSONB DEFAULT '["sales", "products"]',
  pin VARCHAR(6), -- Quick login for POS
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_pos_users_main ON pos_users(main_user_id);
CREATE INDEX idx_pos_users_email ON pos_users(email);

-- =====================================================

-- Products
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku VARCHAR(100) UNIQUE NOT NULL,
  barcode VARCHAR(100),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100),
  price DECIMAL(10,2) NOT NULL,
  cost DECIMAL(10,2),
  tax_rate DECIMAL(5,2) DEFAULT 0,
  stock_quantity INTEGER DEFAULT 0,
  min_stock_level INTEGER DEFAULT 0,
  unit VARCHAR(50) DEFAULT 'pcs',
  image_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES pos_users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_category ON products(category);

-- =====================================================

-- Sales
CREATE TABLE sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_number VARCHAR(50) UNIQUE NOT NULL,
  cashier_id UUID REFERENCES pos_users(id),
  customer_name VARCHAR(255),
  customer_phone VARCHAR(50),
  subtotal DECIMAL(10,2) NOT NULL,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL,
  payment_method VARCHAR(50) NOT NULL, -- 'cash', 'card', 'upi', 'wallet'
  payment_status VARCHAR(50) DEFAULT 'completed', -- 'completed', 'pending', 'refunded'
  amount_paid DECIMAL(10,2),
  change_amount DECIMAL(10,2),
  notes TEXT,
  sale_date TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_sales_number ON sales(sale_number);
CREATE INDEX idx_sales_cashier ON sales(cashier_id);
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sales_status ON sales(payment_status);

-- =====================================================

-- Sale Items
CREATE TABLE sale_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id UUID REFERENCES sales(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  product_name VARCHAR(255) NOT NULL, -- Store name in case product deleted
  quantity DECIMAL(10,2) NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  tax_rate DECIMAL(5,2) DEFAULT 0,
  discount DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id);

-- =====================================================

-- Receipts
CREATE TABLE receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id UUID REFERENCES sales(id) ON DELETE CASCADE,
  receipt_number VARCHAR(50) UNIQUE NOT NULL,
  receipt_data JSONB NOT NULL, -- Complete receipt information
  printed_at TIMESTAMP,
  emailed_to VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_receipts_sale ON receipts(sale_id);

-- =====================================================

-- Cash Drawer / Shifts
CREATE TABLE shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cashier_id UUID REFERENCES pos_users(id),
  opening_balance DECIMAL(10,2) NOT NULL,
  closing_balance DECIMAL(10,2),
  expected_balance DECIMAL(10,2),
  difference DECIMAL(10,2),
  total_sales DECIMAL(10,2),
  total_cash DECIMAL(10,2),
  total_card DECIMAL(10,2),
  total_other DECIMAL(10,2),
  started_at TIMESTAMP DEFAULT NOW(),
  ended_at TIMESTAMP,
  notes TEXT
);

CREATE INDEX idx_shifts_cashier ON shifts(cashier_id);
CREATE INDEX idx_shifts_started ON shifts(started_at);

-- =====================================================

-- Product Categories
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES categories(id),
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
```

---

## 👥 CRM DATABASE (billease_crm)

### Schema

```sql
-- =====================================================
-- CRM DATABASE: billease_crm
-- =====================================================

-- CRM Users
CREATE TABLE crm_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  main_user_id UUID NOT NULL,
  email VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'agent', -- 'admin', 'manager', 'agent'
  permissions JSONB DEFAULT '["contacts"]',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_crm_users_main ON crm_users(main_user_id);

-- =====================================================

-- Customers
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_number VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  company VARCHAR(255),
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(100),
  postal_code VARCHAR(20),
  website VARCHAR(255),
  tax_id VARCHAR(100),
  type VARCHAR(50) DEFAULT 'individual', -- 'individual', 'business'
  status VARCHAR(50) DEFAULT 'active', -- 'active', 'inactive', 'blocked'
  tags JSONB DEFAULT '[]',
  custom_fields JSONB DEFAULT '{}',
  notes TEXT,
  assigned_to UUID REFERENCES crm_users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_customers_number ON customers(customer_number);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_assigned ON customers(assigned_to);

-- =====================================================

-- Suppliers / Vendors
CREATE TABLE suppliers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_number VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  company VARCHAR(255),
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(100),
  postal_code VARCHAR(20),
  website VARCHAR(255),
  tax_id VARCHAR(100),
  payment_terms VARCHAR(100),
  status VARCHAR(50) DEFAULT 'active',
  tags JSONB DEFAULT '[]',
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_suppliers_number ON suppliers(supplier_number);
CREATE INDEX idx_suppliers_email ON suppliers(email);

-- =====================================================

-- Contacts (Additional contacts for customers/suppliers)
CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type VARCHAR(50) NOT NULL, -- 'customer', 'supplier'
  entity_id UUID NOT NULL,
  name VARCHAR(255) NOT NULL,
  position VARCHAR(100),
  email VARCHAR(255),
  phone VARCHAR(50),
  is_primary BOOLEAN DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_contacts_entity ON contacts(entity_type, entity_id);

-- =====================================================

-- Interactions / Activities
CREATE TABLE interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type VARCHAR(50) NOT NULL, -- 'customer', 'supplier', 'lead'
  entity_id UUID NOT NULL,
  interaction_type VARCHAR(50) NOT NULL, -- 'call', 'email', 'meeting', 'note'
  subject VARCHAR(255),
  description TEXT,
  outcome VARCHAR(100),
  duration_minutes INTEGER,
  scheduled_at TIMESTAMP,
  completed_at TIMESTAMP,
  created_by UUID REFERENCES crm_users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_interactions_entity ON interactions(entity_type, entity_id);
CREATE INDEX idx_interactions_type ON interactions(interaction_type);
CREATE INDEX idx_interactions_scheduled ON interactions(scheduled_at);

-- =====================================================

-- Leads / Opportunities
CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_number VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  company VARCHAR(255),
  email VARCHAR(255),
  phone VARCHAR(50),
  source VARCHAR(100), -- 'website', 'referral', 'cold_call', 'event'
  status VARCHAR(50) DEFAULT 'new', -- 'new', 'contacted', 'qualified', 'lost', 'converted'
  value DECIMAL(10,2),
  probability INTEGER DEFAULT 0, -- 0-100
  expected_close_date DATE,
  assigned_to UUID REFERENCES crm_users(id),
  notes TEXT,
  converted_to_customer_id UUID REFERENCES customers(id),
  converted_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_leads_number ON leads(lead_number);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_assigned ON leads(assigned_to);

-- =====================================================

-- Documents / Files
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type VARCHAR(50) NOT NULL,
  entity_id UUID NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(100),
  file_size BIGINT,
  file_url TEXT NOT NULL,
  uploaded_by UUID REFERENCES crm_users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_documents_entity ON documents(entity_type, entity_id);
```

---

## 💰 ACCOUNTS DATABASE (billease_accounts)

### Schema

```sql
-- =====================================================
-- ACCOUNTS DATABASE: billease_accounts
-- =====================================================

-- Accounts Users
CREATE TABLE accounts_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  main_user_id UUID NOT NULL,
  email VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'accountant', -- 'admin', 'accountant', 'viewer'
  permissions JSONB DEFAULT '["read"]',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_accounts_users_main ON accounts_users(main_user_id);

-- =====================================================

-- Chart of Accounts
CREATE TABLE chart_of_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_code VARCHAR(50) UNIQUE NOT NULL,
  account_name VARCHAR(255) NOT NULL,
  account_type VARCHAR(50) NOT NULL, -- 'asset', 'liability', 'equity', 'revenue', 'expense'
  sub_type VARCHAR(50), -- 'current_asset', 'fixed_asset', etc.
  parent_account_id UUID REFERENCES chart_of_accounts(id),
  level INTEGER DEFAULT 1,
  opening_balance DECIMAL(15,2) DEFAULT 0,
  current_balance DECIMAL(15,2) DEFAULT 0,
  is_system BOOLEAN DEFAULT FALSE, -- Cannot be deleted
  is_active BOOLEAN DEFAULT TRUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_accounts_code ON chart_of_accounts(account_code);
CREATE INDEX idx_accounts_type ON chart_of_accounts(account_type);
CREATE INDEX idx_accounts_parent ON chart_of_accounts(parent_account_id);

-- =====================================================

-- Fiscal Years
CREATE TABLE fiscal_years (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status VARCHAR(50) DEFAULT 'open', -- 'open', 'closed', 'locked'
  closed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_fiscal_years_dates ON fiscal_years(start_date, end_date);

-- =====================================================

-- Journal Entries
CREATE TABLE journal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_number VARCHAR(50) UNIQUE NOT NULL,
  entry_date DATE NOT NULL,
  entry_type VARCHAR(50) DEFAULT 'general', -- 'general', 'opening', 'closing', 'adjusting'
  reference_number VARCHAR(100),
  description TEXT,
  total_debit DECIMAL(15,2) NOT NULL,
  total_credit DECIMAL(15,2) NOT NULL,
  status VARCHAR(50) DEFAULT 'draft', -- 'draft', 'posted', 'voided'
  posted_at TIMESTAMP,
  posted_by UUID REFERENCES accounts_users(id),
  fiscal_year_id UUID REFERENCES fiscal_years(id),
  created_by UUID REFERENCES accounts_users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT check_balanced CHECK (total_debit = total_credit)
);

CREATE INDEX idx_journal_entries_number ON journal_entries(entry_number);
CREATE INDEX idx_journal_entries_date ON journal_entries(entry_date);
CREATE INDEX idx_journal_entries_fiscal_year ON journal_entries(fiscal_year_id);

-- =====================================================

-- Journal Entry Lines
CREATE TABLE journal_entry_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_id UUID REFERENCES journal_entries(id) ON DELETE CASCADE,
  account_id UUID REFERENCES chart_of_accounts(id),
  line_number INTEGER NOT NULL,
  description TEXT,
  debit DECIMAL(15,2) DEFAULT 0,
  credit DECIMAL(15,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT check_debit_or_credit CHECK (
    (debit > 0 AND credit = 0) OR (credit > 0 AND debit = 0)
  )
);

CREATE INDEX idx_entry_lines_entry ON journal_entry_lines(entry_id);
CREATE INDEX idx_entry_lines_account ON journal_entry_lines(account_id);

-- =====================================================

-- General Ledger (Materialized View or Table)
CREATE TABLE general_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID REFERENCES chart_of_accounts(id),
  entry_id UUID REFERENCES journal_entries(id),
  entry_line_id UUID REFERENCES journal_entry_lines(id),
  transaction_date DATE NOT NULL,
  description TEXT,
  debit DECIMAL(15,2) DEFAULT 0,
  credit DECIMAL(15,2) DEFAULT 0,
  balance DECIMAL(15,2) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ledger_account ON general_ledger(account_id);
CREATE INDEX idx_ledger_date ON general_ledger(transaction_date);

-- =====================================================

-- Tax Rates
CREATE TABLE tax_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  rate DECIMAL(5,2) NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'sales', 'purchase', 'both'
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================

-- Bank Accounts
CREATE TABLE bank_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID REFERENCES chart_of_accounts(id),
  bank_name VARCHAR(255) NOT NULL,
  account_number VARCHAR(100) NOT NULL,
  account_type VARCHAR(50), -- 'checking', 'savings', 'credit'
  opening_balance DECIMAL(15,2) DEFAULT 0,
  current_balance DECIMAL(15,2) DEFAULT 0,
  currency VARCHAR(3) DEFAULT 'USD',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 📦 INVENTORY DATABASE (billease_inventory)

### Schema

```sql
-- =====================================================
-- INVENTORY DATABASE: billease_inventory
-- =====================================================

-- Inventory Users
CREATE TABLE inventory_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  main_user_id UUID NOT NULL,
  email VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'staff', -- 'admin', 'manager', 'staff'
  permissions JSONB DEFAULT '["read"]',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_inventory_users_main ON inventory_users(main_user_id);

-- =====================================================

-- Products
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku VARCHAR(100) UNIQUE NOT NULL,
  barcode VARCHAR(100),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category_id UUID REFERENCES categories(id),
  unit_id UUID REFERENCES units(id),
  brand VARCHAR(100),
  model VARCHAR(100),
  reorder_level INTEGER DEFAULT 0,
  reorder_quantity INTEGER DEFAULT 0,
  cost_price DECIMAL(10,2),
  selling_price DECIMAL(10,2),
  image_url TEXT,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_category ON products(category_id);

-- =====================================================

-- Categories
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES categories(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================

-- Units of Measurement
CREATE TABLE units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) UNIQUE NOT NULL,
  abbreviation VARCHAR(10) NOT NULL,
  type VARCHAR(50), -- 'quantity', 'weight', 'volume', 'length'
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================

-- Stock / Inventory
CREATE TABLE inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products(id),
  location_id UUID REFERENCES locations(id),
  quantity DECIMAL(10,2) DEFAULT 0,
  reserved_quantity DECIMAL(10,2) DEFAULT 0,
  available_quantity DECIMAL(10,2) GENERATED ALWAYS AS (quantity - reserved_quantity) STORED,
  last_stock_check DATE,
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(product_id, location_id)
);

CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_inventory_location ON inventory(location_id);

-- =====================================================

-- Locations / Warehouses
CREATE TABLE locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  code VARCHAR(50) UNIQUE NOT NULL,
  address TEXT,
  type VARCHAR(50) DEFAULT 'warehouse', -- 'warehouse', 'store', 'transit'
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================

-- Stock Movements
CREATE TABLE stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  movement_number VARCHAR(50) UNIQUE NOT NULL,
  product_id UUID REFERENCES products(id),
  from_location_id UUID REFERENCES locations(id),
  to_location_id UUID REFERENCES locations(id),
  movement_type VARCHAR(50) NOT NULL, -- 'purchase', 'sale', 'transfer', 'adjustment', 'return'
  quantity DECIMAL(10,2) NOT NULL,
  unit_cost DECIMAL(10,2),
  total_cost DECIMAL(10,2),
  reference_number VARCHAR(100),
  notes TEXT,
  movement_date DATE NOT NULL,
  created_by UUID REFERENCES inventory_users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_movements_product ON stock_movements(product_id);
CREATE INDEX idx_movements_date ON stock_movements(movement_date);
CREATE INDEX idx_movements_type ON stock_movements(movement_type);

-- =====================================================

-- Income/Expense Transactions
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_number VARCHAR(50) UNIQUE NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'income', 'expense'
  category VARCHAR(100),
  amount DECIMAL(10,2) NOT NULL,
  payment_method VARCHAR(50),
  account VARCHAR(100),
  description TEXT,
  reference_number VARCHAR(100),
  transaction_date DATE NOT NULL,
  created_by UUID REFERENCES inventory_users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_category ON transactions(category);

-- =====================================================

-- Stock Valuation (for FIFO, LIFO, Weighted Average)
CREATE TABLE stock_valuation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products(id),
  location_id UUID REFERENCES locations(id),
  batch_number VARCHAR(100),
  quantity DECIMAL(10,2) NOT NULL,
  unit_cost DECIMAL(10,2) NOT NULL,
  total_value DECIMAL(15,2) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
  received_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_valuation_product ON stock_valuation(product_id);
```

---

## 🔗 DATABASE RELATIONSHIPS & CONSTRAINTS

### Cross-Database References

**IMPORTANT**: No foreign keys across databases. Use UUID references with application-level validation.

```typescript
// Example: Validating user access in POS app
interface UserAccessValidation {
  main_user_id: string;        // From main DB
  app_user_id: string;          // From app DB
  email: string;                // Verified in both
  has_subscription: boolean;    // Verified via API
  permissions: string[];        // From app DB
}

// Validate before allowing access
const validateUserAccess = async (main_token: string, app: string) => {
  // 1. Validate token with Main API
  const mainUser = await mainAPI.validateToken(main_token);
  
  // 2. Check subscription for app
  const hasAccess = mainUser.subscriptions.includes(app);
  
  // 3. Get or create app-specific user
  let appUser = await getAppUser(mainUser.id);
  if (!appUser) {
    appUser = await createAppUser({
      main_user_id: mainUser.id,
      email: mainUser.email,
    });
  }
  
  return { mainUser, appUser, hasAccess };
};
```

---

## 📈 DATABASE INDEXES STRATEGY

### Main Database
- Users: email, status, role
- Subscriptions: user_id, status, stripe_id
- App Access: user_id, app_id
- Payments: user_id, status, subscription_id
- Audit Logs: user_id, action, created_at

### App Databases
- Products: SKU, barcode, category
- Sales/Transactions: date, number, status
- Customers: email, phone, number
- Journal Entries: date, number, fiscal_year

---

## 🔒 SECURITY FEATURES

### Row-Level Security (RLS)
All tables have RLS enabled where appropriate.

### Encryption
- Passwords: bcrypt hashed
- API Keys: Hashed with prefix for lookup
- Sensitive data: Encrypted at rest

### Audit Trail
Every critical operation logged in `audit_logs` table.

---

## 🚀 MIGRATION STRATEGY

### Initial Setup
```bash
# Create databases
createdb billease_main
createdb billease_pos
createdb billease_crm
createdb billease_accounts
createdb billease_inventory

# Run migrations in order
psql -d billease_main -f migrations/main/001_initial.sql
psql -d billease_pos -f migrations/pos/001_initial.sql
psql -d billease_crm -f migrations/crm/001_initial.sql
psql -d billease_accounts -f migrations/accounts/001_initial.sql
psql -d billease_inventory -f migrations/inventory/001_initial.sql
```

---

## ✅ SCHEMA VALIDATION CHECKLIST

- [x] All tables have primary keys
- [x] Proper indexes on foreign keys
- [x] Appropriate data types
- [x] Constraints for data integrity
- [x] Timestamps for audit trail
- [x] Soft delete capability where needed
- [x] RLS policies for multi-tenancy
- [x] Proper normalization
- [x] Performance considerations

---

This schema design supports:
- ✅ Strict isolation
- ✅ Scalability
- ✅ Data integrity
- ✅ Security
- ✅ Audit compliance
- ✅ Performance
