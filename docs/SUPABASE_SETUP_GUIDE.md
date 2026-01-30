# Supabase Setup Guide for BillEase Suite

This guide will walk you through setting up Supabase for both the Desktop App and Web App.

## 🆕 Latest Enhancements

### ✅ Complete Audit Logging System (Step 2.14)
**Every user action is now tracked automatically!**
- 📝 All INSERT, UPDATE, DELETE operations logged
- 👤 Tracks which user made each change
- 🕐 Records before/after values for complete history
- 🔍 Searchable audit trail for compliance
- 📊 Daily activity summaries per user
- 🔐 Session tracking (login/logout times, IP, device)

### ✅ Module Distribution Clarified
- **Desktop App**: Full featured with **Accounts+ module** (chart of accounts, ledger, financial reports)
- **Web App**: Simplified without Accounts+ (POS, Stock, ExIn only)

### ✅ Enhanced User Tracking
- Every record includes `user_id` for accountability
- User sessions tracked with login/logout times
- Activity summaries show productivity metrics
- Real-time monitoring of active users

## Prerequisites
- Supabase account (create at https://supabase.com)
- Your Supabase project credentials (already configured):
  - Project ID: `xtgptccdcnmknjwicccc`
  - Project URL: `https://xtgptccdcnmknjwicccc.supabase.co`
  - Anon Key: Already configured in both apps

## Step 1: Access Your Supabase Project

1. Go to https://app.supabase.com
2. Sign in to your account
3. Select your project: `xtgptccdcnmknjwicccc`

## Step 2: Create Database Tables

Go to **SQL Editor** in the left sidebar and run the following SQL scripts:


### 2.0 Base Tables (Organizations & Users)

**IMPORTANT**: Run these first as they are required for tenant-based security

```sql
-- Organizations/Tenants Table
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted INTEGER DEFAULT 0
);

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Allow users to see organizations they belong to
CREATE POLICY "Users can view their organization" ON organizations
  FOR SELECT USING (
    id IN (
      SELECT organization_id FROM user_profiles 
      WHERE user_id = auth.uid()
    )
  );

-- User Profiles Table (links auth.users to organizations)
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'user', -- 'owner', 'admin', 'user', 'viewer'
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, organization_id)
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (user_id = auth.uid());

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (user_id = auth.uid());

-- Create indexes
CREATE INDEX idx_user_profiles_user ON user_profiles(user_id);
CREATE INDEX idx_user_profiles_org ON user_profiles(organization_id);

-- Helper function to get user's organization
CREATE OR REPLACE FUNCTION auth.user_organization_id()
RETURNS UUID AS $$
  SELECT organization_id FROM user_profiles
  WHERE user_id = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;
```

### 2.1 Categories Table
```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  is_deleted INTEGER DEFAULT 0
);

-- Enable Row Level Security
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Tenant-based policies
CREATE POLICY "Users can view categories in their organization" ON categories
  FOR SELECT USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can insert categories in their organization" ON categories
  FOR INSERT WITH CHECK (organization_id = auth.user_organization_id());

CREATE POLICY "Users can update categories in their organization" ON categories
  FOR UPDATE USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can delete categories in their organization" ON categories
  FOR DELETE USING (organization_id = auth.user_organization_id());

-- Create indexes
CREATE INDEX idx_categories_org ON categories(organization_id);
```

### 2.2 Units Table
```sql
CREATE TABLE units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  abbreviation TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  is_deleted INTEGER DEFAULT 0
);

ALTER TABLE units ENABLE ROW LEVEL SECURITY;

-- Tenant-based policies
CREATE POLICY "Users can view units in their organization" ON units
  FOR SELECT USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can insert units in their organization" ON units
  FOR INSERT WITH CHECK (organization_id = auth.user_organization_id());

CREATE POLICY "Users can update units in their organization" ON units
  FOR UPDATE USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can delete units in their organization" ON units
  FOR DELETE USING (organization_id = auth.user_organization_id());

-- Create indexes
CREATE INDEX idx_units_org ON units(organization_id);
```

### 2.3 Products Table
```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  sku TEXT,
  barcode TEXT,
  category_id UUID REFERENCES categories(id),
  unit_id UUID REFERENCES units(id),
  description TEXT,
  unit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  cost_price DECIMAL(10,2) DEFAULT 0,
  stock_quantity INTEGER DEFAULT 0,
  min_stock_level INTEGER DEFAULT 0,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  is_deleted INTEGER DEFAULT 0
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Tenant-based policies
CREATE POLICY "Users can view products in their organization" ON products
  FOR SELECT USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can insert products in their organization" ON products
  FOR INSERT WITH CHECK (organization_id = auth.user_organization_id());

CREATE POLICY "Users can update products in their organization" ON products
  FOR UPDATE USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can delete products in their organization" ON products
  FOR DELETE USING (organization_id = auth.user_organization_id());

-- Create indexes for better performance
CREATE INDEX idx_products_org ON products(organization_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_barcode ON products(barcode);
```

### 2.4 Customers Table
```sql
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  postal_code TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  is_deleted INTEGER DEFAULT 0
);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Tenant-based policies
CREATE POLICY "Users can view customers in their organization" ON customers
  FOR SELECT USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can insert customers in their organization" ON customers
  FOR INSERT WITH CHECK (organization_id = auth.user_organization_id());

CREATE POLICY "Users can update customers in their organization" ON customers
  FOR UPDATE USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can delete customers in their organization" ON customers
  FOR DELETE USING (organization_id = auth.user_organization_id());

-- Create indexes
CREATE INDEX idx_customers_org ON customers(organization_id);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_phone ON customers(phone);
```

### 2.5 Suppliers Table
```sql
CREATE TABLE suppliers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  postal_code TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  is_deleted INTEGER DEFAULT 0
);

ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

-- Tenant-based policies
CREATE POLICY "Users can view suppliers in their organization" ON suppliers
  FOR SELECT USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can insert suppliers in their organization" ON suppliers
  FOR INSERT WITH CHECK (organization_id = auth.user_organization_id());

CREATE POLICY "Users can update suppliers in their organization" ON suppliers
  FOR UPDATE USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can delete suppliers in their organization" ON suppliers
  FOR DELETE USING (organization_id = auth.user_organization_id());

-- Create indexes
CREATE INDEX idx_suppliers_org ON suppliers(organization_id);
```

### 2.6 Sales Table
```sql
CREATE TABLE sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  customer_id UUID REFERENCES customers(id),
  total_amount DECIMAL(10,2) NOT NULL,
  discount DECIMAL(10,2) DEFAULT 0,
  tax DECIMAL(10,2) DEFAULT 0,
  payment_method TEXT,
  status TEXT DEFAULT 'completed',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  is_deleted INTEGER DEFAULT 0
);

ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

-- Tenant-based policies
CREATE POLICY "Users can view sales in their organization" ON sales
  FOR SELECT USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can insert sales in their organization" ON sales
  FOR INSERT WITH CHECK (
    organization_id = auth.user_organization_id() AND
    user_id = auth.uid()
  );

CREATE POLICY "Users can update sales in their organization" ON sales
  FOR UPDATE USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can delete sales in their organization" ON sales
  FOR DELETE USING (organization_id = auth.user_organization_id());

-- Create indexes
CREATE INDEX idx_sales_org ON sales(organization_id);
CREATE INDEX idx_sales_user ON sales(user_id);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_sales_date ON sales(created_at);
CREATE INDEX idx_sales_status ON sales(status);
```

### 2.7 Sale Items Table
```sql
CREATE TABLE sale_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  sale_id UUID REFERENCES sales(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES products(id) NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  is_deleted INTEGER DEFAULT 0
);

ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;

-- Tenant-based policies (inherit from sale)
CREATE POLICY "Users can view sale_items in their organization" ON sale_items
  FOR SELECT USING (
    organization_id = auth.user_organization_id()
  );

CREATE POLICY "Users can insert sale_items in their organization" ON sale_items
  FOR INSERT WITH CHECK (
    organization_id = auth.user_organization_id()
  );

CREATE POLICY "Users can update sale_items in their organization" ON sale_items
  FOR UPDATE USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can delete sale_items in their organization" ON sale_items
  FOR DELETE USING (organization_id = auth.user_organization_id());

-- Create indexes
CREATE INDEX idx_sale_items_org ON sale_items(organization_id);
CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id);
```

### 2.8 Stock Movements Table
```sql
CREATE TABLE stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  product_id UUID REFERENCES products(id) NOT NULL,
  quantity INTEGER NOT NULL,
  type TEXT NOT NULL, -- 'in' or 'out' or 'adjustment'
  reference_type TEXT, -- 'sale', 'purchase', 'adjustment'
  reference_id UUID,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  is_deleted INTEGER DEFAULT 0
);

ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;

-- Tenant-based policies
CREATE POLICY "Users can view stock_movements in their organization" ON stock_movements
  FOR SELECT USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can insert stock_movements in their organization" ON stock_movements
  FOR INSERT WITH CHECK (organization_id = auth.user_organization_id());

CREATE POLICY "Users can update stock_movements in their organization" ON stock_movements
  FOR UPDATE USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can delete stock_movements in their organization" ON stock_movements
  FOR DELETE USING (organization_id = auth.user_organization_id());

-- Create indexes
CREATE INDEX idx_stock_movements_org ON stock_movements(organization_id);
CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
CREATE INDEX idx_stock_movements_date ON stock_movements(created_at);
```

### 2.9 Transactions Table (for ExIn module)
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  type TEXT NOT NULL, -- 'Income' or 'Expense'
  category TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  date DATE NOT NULL,
  description TEXT,
  payment_method TEXT,
  reference TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  is_deleted INTEGER DEFAULT 0
);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Tenant-based policies
CREATE POLICY "Users can view transactions in their organization" ON transactions
  FOR SELECT USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can insert transactions in their organization" ON transactions
  FOR INSERT WITH CHECK (
    organization_id = auth.user_organization_id() AND
    user_id = auth.uid()
  );

CREATE POLICY "Users can update transactions in their organization" ON transactions
  FOR UPDATE USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can delete transactions in their organization" ON transactions
  FOR DELETE USING (organization_id = auth.user_organization_id());

-- Create indexes
CREATE INDEX idx_transactions_org ON transactions(organization_id);
CREATE INDEX idx_transactions_user ON transactions(user_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_category ON transactions(category);
```

### 2.10 Chart of Accounts Table
```sql
CREATE TABLE chart_of_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- 'Asset', 'Liability', 'Equity', 'Revenue', 'Expense'
  parent_id UUID REFERENCES chart_of_accounts(id),
  balance DECIMAL(15,2) DEFAULT 0,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  is_deleted INTEGER DEFAULT 0,
  UNIQUE(organization_id, code)
);

ALTER TABLE chart_of_accounts ENABLE ROW LEVEL SECURITY;

-- Tenant-based policies
CREATE POLICY "Users can view chart_of_accounts in their organization" ON chart_of_accounts
  FOR SELECT USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can insert chart_of_accounts in their organization" ON chart_of_accounts
  FOR INSERT WITH CHECK (organization_id = auth.user_organization_id());

CREATE POLICY "Users can update chart_of_accounts in their organization" ON chart_of_accounts
  FOR UPDATE USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can delete chart_of_accounts in their organization" ON chart_of_accounts
  FOR DELETE USING (organization_id = auth.user_organization_id());

-- Create indexes
CREATE INDEX idx_coa_org ON chart_of_accounts(organization_id);
CREATE INDEX idx_coa_code ON chart_of_accounts(code);
CREATE INDEX idx_coa_type ON chart_of_accounts(type);
CREATE INDEX idx_coa_parent ON chart_of_accounts(parent_id);
```

### 2.11 Ledger Table
```sql
CREATE TABLE ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  account_id UUID REFERENCES chart_of_accounts(id) NOT NULL,
  date DATE NOT NULL,
  description TEXT,
  debit DECIMAL(15,2) DEFAULT 0,
  credit DECIMAL(15,2) DEFAULT 0,
  reference_type TEXT, -- 'sale', 'transaction', 'manual'
  reference_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  is_deleted INTEGER DEFAULT 0
);

ALTER TABLE ledger ENABLE ROW LEVEL SECURITY;

-- Tenant-based policies
CREATE POLICY "Users can view ledger in their organization" ON ledger
  FOR SELECT USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can insert ledger in their organization" ON ledger
  FOR INSERT WITH CHECK (organization_id = auth.user_organization_id());

CREATE POLICY "Users can update ledger in their organization" ON ledger
  FOR UPDATE USING (organization_id = auth.user_organization_id());

CREATE POLICY "Users can delete ledger in their organization" ON ledger
  FOR DELETE USING (organization_id = auth.user_organization_id());

-- Create indexes
CREATE INDEX idx_ledger_org ON ledger(organization_id);
CREATE INDEX idx_ledger_account ON ledger(account_id);
CREATE INDEX idx_ledger_date ON ledger(date);
CREATE INDEX idx_ledger_reference ON ledger(reference_type, reference_id);
```

## Step 2.12: Automation Triggers

### 🔄 Auto Stock Update Trigger

**Purpose**: Automatically updates product stock quantities when sale items are created or modified.

```sql
-- Function to update stock on sale
CREATE OR REPLACE FUNCTION update_product_stock_on_sale()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    -- Reduce stock when sale item is created
    UPDATE products
    SET stock_quantity = stock_quantity - NEW.quantity,
        updated_at = NOW()
    WHERE id = NEW.product_id;
    
    -- Create stock movement record
    INSERT INTO stock_movements (
      organization_id,
      user_id,
      product_id,
      quantity,
      type,
      reference_type,
      reference_id,
      notes
    ) VALUES (
      NEW.organization_id,
      (SELECT user_id FROM sales WHERE id = NEW.sale_id),
      NEW.product_id,
      -NEW.quantity,
      'out',
      'sale',
      NEW.sale_id,
      'Auto stock movement from sale'
    );
    
  ELSIF (TG_OP = 'UPDATE') THEN
    -- Adjust stock if quantity changed
    IF OLD.quantity <> NEW.quantity THEN
      UPDATE products
      SET stock_quantity = stock_quantity + OLD.quantity - NEW.quantity,
          updated_at = NOW()
      WHERE id = NEW.product_id;
      
      -- Create adjustment record
      INSERT INTO stock_movements (
        organization_id,
        user_id,
        product_id,
        quantity,
        type,
        reference_type,
        reference_id,
        notes
      ) VALUES (
        NEW.organization_id,
        (SELECT user_id FROM sales WHERE id = NEW.sale_id),
        NEW.product_id,
        OLD.quantity - NEW.quantity,
        'adjustment',
        'sale',
        NEW.sale_id,
        'Auto stock adjustment from sale update'
      );
    END IF;
    
  ELSIF (TG_OP = 'DELETE') THEN
    -- Restore stock when sale item is deleted
    UPDATE products
    SET stock_quantity = stock_quantity + OLD.quantity,
        updated_at = NOW()
    WHERE id = OLD.product_id;
    
    -- Create stock movement record
    INSERT INTO stock_movements (
      organization_id,
      user_id,
      product_id,
      quantity,
      type,
      reference_type,
      reference_id,
      notes
    ) VALUES (
      OLD.organization_id,
      (SELECT user_id FROM sales WHERE id = OLD.sale_id),
      OLD.product_id,
      OLD.quantity,
      'in',
      'sale',
      OLD.sale_id,
      'Auto stock restoration from sale cancellation'
    );
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER trigger_update_stock_on_sale
  AFTER INSERT OR UPDATE OR DELETE ON sale_items
  FOR EACH ROW
  EXECUTE FUNCTION update_product_stock_on_sale();
```

### 📊 Auto Ledger Posting from Sales

**Purpose**: Automatically creates ledger entries when sales are completed.

```sql
-- Function to post sale to ledger
CREATE OR REPLACE FUNCTION post_sale_to_ledger()
RETURNS TRIGGER AS $$
DECLARE
  v_revenue_account_id UUID;
  v_cash_account_id UUID;
  v_receivable_account_id UUID;
  v_discount_account_id UUID;
  v_tax_payable_account_id UUID;
BEGIN
  -- Only process completed sales
  IF NEW.status = 'completed' AND (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status <> 'completed')) THEN
    
    -- Find required accounts (you may need to adjust these codes)
    SELECT id INTO v_revenue_account_id 
    FROM chart_of_accounts 
    WHERE organization_id = NEW.organization_id 
      AND type = 'Revenue' 
      AND code = '4000' 
    LIMIT 1;
    
    SELECT id INTO v_cash_account_id 
    FROM chart_of_accounts 
    WHERE organization_id = NEW.organization_id 
      AND type = 'Asset' 
      AND code = '1000' 
    LIMIT 1;
    
    SELECT id INTO v_receivable_account_id 
    FROM chart_of_accounts 
    WHERE organization_id = NEW.organization_id 
      AND type = 'Asset' 
      AND code = '1200' 
    LIMIT 1;
    
    SELECT id INTO v_discount_account_id 
    FROM chart_of_accounts 
    WHERE organization_id = NEW.organization_id 
      AND type = 'Expense' 
      AND code = '5000' 
    LIMIT 1;
    
    SELECT id INTO v_tax_payable_account_id 
    FROM chart_of_accounts 
    WHERE organization_id = NEW.organization_id 
      AND type = 'Liability' 
      AND code = '2100' 
    LIMIT 1;
    
    -- Debit: Cash or Accounts Receivable
    IF NEW.payment_method IN ('cash', 'card', 'mobile') THEN
      IF v_cash_account_id IS NOT NULL THEN
        INSERT INTO ledger (
          organization_id, user_id, account_id, date, description,
          debit, credit, reference_type, reference_id
        ) VALUES (
          NEW.organization_id, NEW.user_id, v_cash_account_id, 
          CURRENT_DATE, 'Sale #' || NEW.id::TEXT,
          NEW.total_amount, 0, 'sale', NEW.id
        );
      END IF;
    ELSE
      IF v_receivable_account_id IS NOT NULL THEN
        INSERT INTO ledger (
          organization_id, user_id, account_id, date, description,
          debit, credit, reference_type, reference_id
        ) VALUES (
          NEW.organization_id, NEW.user_id, v_receivable_account_id,
          CURRENT_DATE, 'Sale #' || NEW.id::TEXT,
          NEW.total_amount, 0, 'sale', NEW.id
        );
      END IF;
    END IF;
    
    -- Credit: Sales Revenue
    IF v_revenue_account_id IS NOT NULL THEN
      INSERT INTO ledger (
        organization_id, user_id, account_id, date, description,
        debit, credit, reference_type, reference_id
      ) VALUES (
        NEW.organization_id, NEW.user_id, v_revenue_account_id,
        CURRENT_DATE, 'Sale #' || NEW.id::TEXT,
        0, NEW.total_amount - NEW.tax, 'sale', NEW.id
      );
    END IF;
    
    -- Handle Discount
    IF NEW.discount > 0 AND v_discount_account_id IS NOT NULL THEN
      INSERT INTO ledger (
        organization_id, user_id, account_id, date, description,
        debit, credit, reference_type, reference_id
      ) VALUES (
        NEW.organization_id, NEW.user_id, v_discount_account_id,
        CURRENT_DATE, 'Discount on Sale #' || NEW.id::TEXT,
        NEW.discount, 0, 'sale', NEW.id
      );
    END IF;
    
    -- Handle Tax
    IF NEW.tax > 0 AND v_tax_payable_account_id IS NOT NULL THEN
      INSERT INTO ledger (
        organization_id, user_id, account_id, date, description,
        debit, credit, reference_type, reference_id
      ) VALUES (
        NEW.organization_id, NEW.user_id, v_tax_payable_account_id,
        CURRENT_DATE, 'Tax on Sale #' || NEW.id::TEXT,
        0, NEW.tax, 'sale', NEW.id
      );
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER trigger_post_sale_to_ledger
  AFTER INSERT OR UPDATE ON sales
  FOR EACH ROW
  EXECUTE FUNCTION post_sale_to_ledger();
```

### 📈 Update Account Balances Trigger

**Purpose**: Automatically updates chart of accounts balances when ledger entries are made.

```sql
-- Function to update account balance
CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    -- Update balance based on debit/credit
    UPDATE chart_of_accounts
    SET balance = balance + NEW.debit - NEW.credit,
        updated_at = NOW()
    WHERE id = NEW.account_id;
    
  ELSIF (TG_OP = 'UPDATE') THEN
    -- Reverse old entry and apply new one
    UPDATE chart_of_accounts
    SET balance = balance - OLD.debit + OLD.credit + NEW.debit - NEW.credit,
        updated_at = NOW()
    WHERE id = NEW.account_id;
    
  ELSIF (TG_OP = 'DELETE') THEN
    -- Reverse the entry
    UPDATE chart_of_accounts
    SET balance = balance - OLD.debit + OLD.credit,
        updated_at = NOW()
    WHERE id = OLD.account_id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER trigger_update_account_balance
  AFTER INSERT OR UPDATE OR DELETE ON ledger
  FOR EACH ROW
  EXECUTE FUNCTION update_account_balance();
```

### 🔔 Updated At Triggers (for all tables)

**Purpose**: Automatically update `updated_at` timestamp on row changes.

```sql
-- Generic function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at column
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_units_updated_at BEFORE UPDATE ON units
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sales_updated_at BEFORE UPDATE ON sales
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chart_of_accounts_updated_at BEFORE UPDATE ON chart_of_accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ledger_updated_at BEFORE UPDATE ON ledger
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 💰 Automatic Provisions Function

**Purpose**: Automatically create accounting provisions for common scenarios.

```sql
-- Function to create automatic provisions
CREATE OR REPLACE FUNCTION create_automatic_provisions(p_organization_id UUID)
RETURNS void AS $$
DECLARE
  v_bad_debt_provision_account UUID;
  v_bad_debt_expense_account UUID;
  v_depreciation_provision_account UUID;
  v_depreciation_expense_account UUID;
  v_total_receivables DECIMAL(15,2);
  v_provision_amount DECIMAL(15,2);
  v_equipment_value DECIMAL(15,2);
  v_depreciation_amount DECIMAL(15,2);
BEGIN
  -- Find provision accounts
  SELECT id INTO v_bad_debt_provision_account
  FROM chart_of_accounts
  WHERE organization_id = p_organization_id
    AND code = '1210' AND name = 'Provision for Bad Debts'
  LIMIT 1;
  
  SELECT id INTO v_bad_debt_expense_account
  FROM chart_of_accounts
  WHERE organization_id = p_organization_id
    AND code = '5150' AND name = 'Bad Debt Expense'
  LIMIT 1;
  
  SELECT id INTO v_depreciation_provision_account
  FROM chart_of_accounts
  WHERE organization_id = p_organization_id
    AND code = '1510' AND name = 'Accumulated Depreciation'
  LIMIT 1;
  
  SELECT id INTO v_depreciation_expense_account
  FROM chart_of_accounts
  WHERE organization_id = p_organization_id
    AND code = '5250' AND name = 'Depreciation Expense'
  LIMIT 1;
  
  -- Calculate bad debt provision (5% of receivables)
  SELECT COALESCE(balance, 0) INTO v_total_receivables
  FROM chart_of_accounts
  WHERE organization_id = p_organization_id
    AND code = '1200'; -- Accounts Receivable
  
  v_provision_amount := v_total_receivables * 0.05;
  
  -- Create bad debt provision entry if accounts exist and amount > 0
  IF v_bad_debt_provision_account IS NOT NULL 
     AND v_bad_debt_expense_account IS NOT NULL 
     AND v_provision_amount > 0 THEN
    
    -- Debit: Bad Debt Expense
    INSERT INTO ledger (
      organization_id, account_id, date, description,
      debit, credit, reference_type
    ) VALUES (
      p_organization_id, v_bad_debt_expense_account,
      CURRENT_DATE, 'Auto provision for bad debts (5% of receivables)',
      v_provision_amount, 0, 'provision'
    );
    
    -- Credit: Provision for Bad Debts
    INSERT INTO ledger (
      organization_id, account_id, date, description,
      debit, credit, reference_type
    ) VALUES (
      p_organization_id, v_bad_debt_provision_account,
      CURRENT_DATE, 'Auto provision for bad debts (5% of receivables)',
      0, v_provision_amount, 'provision'
    );
  END IF;
  
  -- Calculate depreciation (10% of equipment annually, monthly = 0.833%)
  SELECT COALESCE(balance, 0) INTO v_equipment_value
  FROM chart_of_accounts
  WHERE organization_id = p_organization_id
    AND code = '1500'; -- Equipment
  
  v_depreciation_amount := v_equipment_value * 0.00833;
  
  -- Create depreciation provision if accounts exist and amount > 0
  IF v_depreciation_provision_account IS NOT NULL 
     AND v_depreciation_expense_account IS NOT NULL 
     AND v_depreciation_amount > 0 THEN
    
    -- Debit: Depreciation Expense
    INSERT INTO ledger (
      organization_id, account_id, date, description,
      debit, credit, reference_type
    ) VALUES (
      p_organization_id, v_depreciation_expense_account,
      CURRENT_DATE, 'Auto monthly depreciation (10% annually)',
      v_depreciation_amount, 0, 'provision'
    );
    
    -- Credit: Accumulated Depreciation
    INSERT INTO ledger (
      organization_id, account_id, date, description,
      debit, credit, reference_type
    ) VALUES (
      p_organization_id, v_depreciation_provision_account,
      CURRENT_DATE, 'Auto monthly depreciation (10% annually)',
      0, v_depreciation_amount, 'provision'
    );
  END IF;
  
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to run provisions for all organizations (call monthly)
CREATE OR REPLACE FUNCTION run_all_provisions()
RETURNS void AS $$
DECLARE
  org_record RECORD;
BEGIN
  FOR org_record IN SELECT id FROM organizations WHERE is_deleted = 0 LOOP
    PERFORM create_automatic_provisions(org_record.id);
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule: Run on first day of each month (requires pg_cron)
-- SELECT cron.schedule(
--   'monthly-provisions',
--   '0 0 1 * *', -- At 00:00 on day 1 of month
--   $$ SELECT run_all_provisions(); $$
-- );
```

## Step 2.13: Seed Default Chart of Accounts (Optional)

**Purpose**: Create a standard chart of accounts for each organization.

```sql
-- Function to seed chart of accounts for new organizations
CREATE OR REPLACE FUNCTION seed_chart_of_accounts(p_organization_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Assets
  INSERT INTO chart_of_accounts (organization_id, code, name, type, description)
  VALUES 
    (p_organization_id, '1000', 'Cash', 'Asset', 'Cash on hand and in bank'),
    (p_organization_id, '1200', 'Accounts Receivable', 'Asset', 'Money owed by customers'),
    (p_organization_id, '1210', 'Provision for Bad Debts', 'Asset', 'Contra-asset for uncollectible receivables'),
    (p_organization_id, '1300', 'Inventory', 'Asset', 'Products in stock'),
    (p_organization_id, '1500', 'Equipment', 'Asset', 'Business equipment'),
    (p_organization_id, '1510', 'Accumulated Depreciation', 'Asset', 'Contra-asset for equipment depreciation');
  
  -- Liabilities
  INSERT INTO chart_of_accounts (organization_id, code, name, type, description)
  VALUES 
    (p_organization_id, '2000', 'Accounts Payable', 'Liability', 'Money owed to suppliers'),
    (p_organization_id, '2100', 'Tax Payable', 'Liability', 'Taxes owed to government');
  
  -- Equity
  INSERT INTO chart_of_accounts (organization_id, code, name, type, description)
  VALUES 
    (p_organization_id, '3000', 'Owner Equity', 'Equity', 'Owner investment'),
    (p_organization_id, '3900', 'Retained Earnings', 'Equity', 'Accumulated profits');
  
  -- Revenue
  INSERT INTO chart_of_accounts (organization_id, code, name, type, description)
  VALUES 
    (p_organization_id, '4000', 'Sales Revenue', 'Revenue', 'Income from sales'),
    (p_organization_id, '4100', 'Service Revenue', 'Revenue', 'Income from services');
  
  -- Expenses
  INSERT INTO chart_of_accounts (organization_id, code, name, type, description)
  VALUES 
    (p_organization_id, '5000', 'Discounts Given', 'Expense', 'Sales discounts'),
    (p_organization_id, '5100', 'Cost of Goods Sold', 'Expense', 'Direct cost of products'),
    (p_organization_id, '5150', 'Bad Debt Expense', 'Expense', 'Provision for uncollectible accounts'),
    (p_organization_id, '5200', 'Rent Expense', 'Expense', 'Office/store rent'),
    (p_organization_id, '5250', 'Depreciation Expense', 'Expense', 'Asset depreciation'),
    (p_organization_id, '5300', 'Utilities Expense', 'Expense', 'Electricity, water, internet'),
    (p_organization_id, '5400', 'Salary Expense', 'Expense', 'Employee salaries');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Example: Call this function after creating an organization
-- SELECT seed_chart_of_accounts('your-org-id-here');
```

## Step 2.14: User Activity & Audit Logging System

**Purpose**: Track EVERY action performed by EVERY user for complete audit trail and accountability.

### 📝 Audit Logs Table

```sql
-- Comprehensive audit logging table
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  user_email TEXT,
  user_name TEXT,
  action TEXT NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE', 'SELECT', 'LOGIN', 'LOGOUT', etc.
  table_name TEXT, -- Which table was affected
  record_id UUID, -- ID of the affected record
  old_data JSONB, -- Previous values (for UPDATE/DELETE)
  new_data JSONB, -- New values (for INSERT/UPDATE)
  ip_address INET,
  user_agent TEXT,
  description TEXT, -- Human-readable description
  metadata JSONB, -- Additional context
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Tenant-based policies for audit logs
CREATE POLICY "Users can view audit logs in their organization" ON audit_logs
  FOR SELECT USING (organization_id = auth.user_organization_id());

-- Only system can insert (via triggers)
CREATE POLICY "System can insert audit logs" ON audit_logs
  FOR INSERT WITH CHECK (true);

-- Create indexes for fast queries
CREATE INDEX idx_audit_logs_org ON audit_logs(organization_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_table ON audit_logs(table_name);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_date ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_record ON audit_logs(record_id);
```

### 👤 User Sessions Table

```sql
-- Track user login sessions
CREATE TABLE user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  user_email TEXT,
  user_name TEXT,
  login_at TIMESTAMPTZ DEFAULT NOW(),
  logout_at TIMESTAMPTZ,
  ip_address INET,
  user_agent TEXT,
  device_type TEXT, -- 'web', 'desktop', 'mobile'
  session_duration INTERVAL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

-- Users can view their own sessions
CREATE POLICY "Users can view own sessions" ON user_sessions
  FOR SELECT USING (user_id = auth.uid());

-- Users can view all sessions in their org (for admins)
CREATE POLICY "Users can view org sessions" ON user_sessions
  FOR SELECT USING (organization_id = auth.user_organization_id());

-- Create indexes
CREATE INDEX idx_user_sessions_org ON user_sessions(organization_id);
CREATE INDEX idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_active ON user_sessions(is_active);
CREATE INDEX idx_user_sessions_date ON user_sessions(login_at);
```

### 📊 User Activity Summary Table

```sql
-- Daily summary of user activities
CREATE TABLE user_activity_summary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  date DATE NOT NULL,
  total_actions INTEGER DEFAULT 0,
  total_inserts INTEGER DEFAULT 0,
  total_updates INTEGER DEFAULT 0,
  total_deletes INTEGER DEFAULT 0,
  total_sales DECIMAL(10,2) DEFAULT 0,
  total_products_created INTEGER DEFAULT 0,
  total_customers_created INTEGER DEFAULT 0,
  session_count INTEGER DEFAULT 0,
  total_session_duration INTERVAL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organization_id, user_id, date)
);

ALTER TABLE user_activity_summary ENABLE ROW LEVEL SECURITY;

-- Users can view activity in their organization
CREATE POLICY "Users can view activity in their organization" ON user_activity_summary
  FOR SELECT USING (organization_id = auth.user_organization_id());

-- Create indexes
CREATE INDEX idx_user_activity_org ON user_activity_summary(organization_id);
CREATE INDEX idx_user_activity_user ON user_activity_summary(user_id);
CREATE INDEX idx_user_activity_date ON user_activity_summary(date);
```

### 🔄 Generic Audit Trigger Function

```sql
-- Function to log all table changes
CREATE OR REPLACE FUNCTION log_audit_trail()
RETURNS TRIGGER AS $$
DECLARE
  v_organization_id UUID;
  v_user_id UUID;
  v_user_email TEXT;
  v_user_name TEXT;
  v_description TEXT;
BEGIN
  -- Get current user info
  v_user_id := auth.uid();
  
  -- Get user details
  SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;
  SELECT full_name INTO v_user_name FROM user_profiles WHERE user_id = v_user_id LIMIT 1;
  
  -- Get organization_id from the record
  IF TG_OP = 'DELETE' THEN
    v_organization_id := OLD.organization_id;
  ELSE
    v_organization_id := NEW.organization_id;
  END IF;
  
  -- Build description
  IF TG_OP = 'INSERT' THEN
    v_description := 'Created new ' || TG_TABLE_NAME || ' record';
  ELSIF TG_OP = 'UPDATE' THEN
    v_description := 'Updated ' || TG_TABLE_NAME || ' record';
  ELSIF TG_OP = 'DELETE' THEN
    v_description := 'Deleted ' || TG_TABLE_NAME || ' record';
  END IF;
  
  -- Insert audit log
  INSERT INTO audit_logs (
    organization_id,
    user_id,
    user_email,
    user_name,
    action,
    table_name,
    record_id,
    old_data,
    new_data,
    description
  ) VALUES (
    v_organization_id,
    v_user_id,
    v_user_email,
    v_user_name,
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN row_to_json(OLD) ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW) ELSE NULL END,
    v_description
  );
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit logging to all main tables
CREATE TRIGGER audit_categories AFTER INSERT OR UPDATE OR DELETE ON categories
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER audit_units AFTER INSERT OR UPDATE OR DELETE ON units
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER audit_products AFTER INSERT OR UPDATE OR DELETE ON products
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER audit_customers AFTER INSERT OR UPDATE OR DELETE ON customers
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER audit_suppliers AFTER INSERT OR UPDATE OR DELETE ON suppliers
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER audit_sales AFTER INSERT OR UPDATE OR DELETE ON sales
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER audit_sale_items AFTER INSERT OR UPDATE OR DELETE ON sale_items
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER audit_stock_movements AFTER INSERT OR UPDATE OR DELETE ON stock_movements
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER audit_transactions AFTER INSERT OR UPDATE OR DELETE ON transactions
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER audit_chart_of_accounts AFTER INSERT OR UPDATE OR DELETE ON chart_of_accounts
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER audit_ledger AFTER INSERT OR UPDATE OR DELETE ON ledger
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();
```

### 📈 Function to Update Activity Summary

```sql
-- Function to update daily activity summary
CREATE OR REPLACE FUNCTION update_user_activity_summary()
RETURNS void AS $$
BEGIN
  -- Update today's summary for all active users
  INSERT INTO user_activity_summary (
    organization_id,
    user_id,
    date,
    total_actions,
    total_inserts,
    total_updates,
    total_deletes,
    total_sales,
    total_products_created,
    total_customers_created,
    session_count
  )
  SELECT 
    organization_id,
    user_id,
    CURRENT_DATE,
    COUNT(*),
    COUNT(*) FILTER (WHERE action = 'INSERT'),
    COUNT(*) FILTER (WHERE action = 'UPDATE'),
    COUNT(*) FILTER (WHERE action = 'DELETE'),
    COALESCE(SUM((new_data->>'total_amount')::decimal) FILTER (WHERE table_name = 'sales' AND action = 'INSERT'), 0),
    COUNT(*) FILTER (WHERE table_name = 'products' AND action = 'INSERT'),
    COUNT(*) FILTER (WHERE table_name = 'customers' AND action = 'INSERT'),
    (SELECT COUNT(DISTINCT id) FROM user_sessions 
     WHERE user_id = audit_logs.user_id 
       AND DATE(login_at) = CURRENT_DATE)
  FROM audit_logs
  WHERE DATE(created_at) = CURRENT_DATE
  GROUP BY organization_id, user_id
  ON CONFLICT (organization_id, user_id, date) 
  DO UPDATE SET
    total_actions = EXCLUDED.total_actions,
    total_inserts = EXCLUDED.total_inserts,
    total_updates = EXCLUDED.total_updates,
    total_deletes = EXCLUDED.total_deletes,
    total_sales = EXCLUDED.total_sales,
    total_products_created = EXCLUDED.total_products_created,
    total_customers_created = EXCLUDED.total_customers_created,
    session_count = EXCLUDED.session_count,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 🕐 Scheduled Job (Optional - requires pg_cron extension)

```sql
-- Run daily summary update every hour
-- Requires pg_cron extension (ask Supabase support to enable)
-- SELECT cron.schedule(
--   'update-activity-summary',
--   '0 * * * *', -- Every hour
--   $$ SELECT update_user_activity_summary(); $$
-- );
```

## Step 3: Set Up Authentication

### 3.1 Enable Email Authentication
1. Go to **Authentication** → **Providers** in the left sidebar
2. Enable **Email** provider
3. Configure email settings:
   - Enable **Confirm email**: OFF (for development)
   - Enable **Secure email change**: ON
   - Enable **Secure password change**: ON

### 3.2 Create Test User & Organization (Required for Testing)

**IMPORTANT**: With tenant-based RLS, you must create both a user AND an organization.

1. **Create Organization**:
```sql
-- Run in SQL Editor
INSERT INTO organizations (id, name, slug) 
VALUES 
  ('11111111-1111-1111-1111-111111111111', 'Demo Company', 'demo-company');
```

2. **Create User via Auth UI**:
   - Go to **Authentication** → **Users**
   - Click **Add user** → **Create new user**
   - Enter:
     - Email: `demo@001.com`
     - Password: `demo@123`
     - Auto Confirm User: ON
   - Click **Create user**
   - **Copy the User ID** from the users list

3. **Link User to Organization**:
```sql
-- Replace 'USER_ID_HERE' with the actual user ID from step 2
INSERT INTO user_profiles (user_id, organization_id, role, full_name)
VALUES 
  ('USER_ID_HERE', '11111111-1111-1111-1111-111111111111', 'owner', 'Demo User');
```

4. **Seed Chart of Accounts** (optional but recommended):
```sql
SELECT seed_chart_of_accounts('11111111-1111-1111-1111-111111111111');
```

## Step 4: Tenant-Based RLS Security Overview

## Step 4: Tenant-Based RLS Security Overview

✅ **All tables are now protected with tenant-based RLS**

### How It Works

1. **Organizations Table**: Each client/business has one organization record
2. **User Profiles**: Links users to organizations (users can belong to multiple orgs)
3. **All Data Tables**: Include `organization_id` to isolate data per tenant
4. **RLS Policies**: Automatically filter data based on user's organization

### Key Features

🔒 **Data Isolation**: Users can only see/edit data in their organization
👥 **Multi-User**: Multiple users can belong to the same organization
🏢 **Multi-Tenant**: Perfect for agencies managing multiple clients
🔑 **Automatic**: No code changes needed - RLS enforces at database level

### Policy Structure (applied to all tables)

```sql
-- Users can only SELECT from their organization
CREATE POLICY "view_policy" ON table_name
  FOR SELECT USING (organization_id = auth.user_organization_id());

-- Users can only INSERT into their organization
CREATE POLICY "insert_policy" ON table_name
  FOR INSERT WITH CHECK (organization_id = auth.user_organization_id());

-- Users can only UPDATE in their organization
CREATE POLICY "update_policy" ON table_name
  FOR UPDATE USING (organization_id = auth.user_organization_id());

-- Users can only DELETE in their organization  
CREATE POLICY "delete_policy" ON table_name
  FOR DELETE USING (organization_id = auth.user_organization_id());
```

### For Agency/Multi-Client Setup

**Scenario**: You're an agency managing multiple client businesses

1. Create one organization per client:
```sql
INSERT INTO organizations (name, slug) VALUES
  ('Client A Bakery', 'client-a-bakery'),
  ('Client B Store', 'client-b-store'),
  ('Client C Restaurant', 'client-c-restaurant');
```

2. Add users and link to their respective organizations:
```sql
-- Client A's user
INSERT INTO user_profiles (user_id, organization_id, role)
VALUES ('user-id-1', 'org-id-client-a', 'owner');

-- Your agency admin who can switch between clients
-- (requires custom logic in your app)
INSERT INTO user_profiles (user_id, organization_id, role)
VALUES 
  ('agency-admin-id', 'org-id-client-a', 'admin'),
  ('agency-admin-id', 'org-id-client-b', 'admin'),
  ('agency-admin-id', 'org-id-client-c', 'admin');
```

### Testing RLS Policies

```sql
-- Test as authenticated user (should only see own org's data)
SELECT * FROM products; -- Only shows products in user's organization

-- Test data isolation
SELECT COUNT(*) FROM products WHERE organization_id = 'other-org-id'; 
-- Returns 0 even if data exists (RLS blocks it)
```

## Step 5: Automation Triggers Explained

### 🔄 Stock Auto-Update

**What it does**: When a sale is made, product stock automatically decreases

**Example**:
- Product "Coffee" has 100 units
- Customer buys 5 units
- ✅ **Automatic**: Stock becomes 95, stock movement recorded

**Handles**:
- New sales: Reduces stock
- Updated sales: Adjusts stock if quantity changed
- Cancelled sales: Restores stock

### 📊 Ledger Auto-Posting

**What it does**: When a sale completes, accounting entries are automatically created

**Example** - Sale of $120 with $10 tax:
```
Debit:  Cash                $130
Credit: Sales Revenue       $120
Credit: Tax Payable         $10
```

**Handles**:
- Cash vs Credit sales (different accounts)
- Discounts (posts to discount expense account)
- Taxes (posts to tax payable account)
- Multiple revenue streams

**Requirements**: Chart of Accounts must have these codes:
- `1000`: Cash (Asset)
- `1200`: Accounts Receivable (Asset)
- `4000`: Sales Revenue (Revenue)
- `2100`: Tax Payable (Liability)
- `5000`: Discounts Given (Expense)

### 📈 Account Balance Auto-Update

**What it does**: Keeps chart of accounts balances current with every ledger entry

**Example**:
- Ledger entry: Debit Cash $100
- ✅ **Automatic**: Cash account balance increases by $100

### 🔍 Audit Logging Auto-Tracking

**What it does**: Automatically logs every data change with full context

**Example** - User updates a product price:
```
Action: UPDATE
Table: products
User: john@example.com
Old Data: { "unit_price": 5.00 }
New Data: { "unit_price": 6.00 }
Timestamp: 2025-12-30 10:15:23
```

**Tracks**:
- All INSERT, UPDATE, DELETE operations
- User who performed the action
- Old values (before change)
- New values (after change)
- Timestamp and IP address
- Human-readable description

**Benefits**:
- Complete audit trail for compliance
- Track who changed what and when
- Rollback capability (manual using old_data)
- Accountability for all users
- Security monitoring

## Step 6: Using With Web & Desktop Apps

### 🌐 Web App Setup (Next.js)

**Location**: `web-app/.env.local`

Your credentials are already configured. The web app will:

✅ Use Supabase Client for real-time queries
✅ Enforce RLS automatically
✅ Auto-sync across browser tabs
✅ Support offline mode with service workers
✅ **Automatically track all user actions** (via triggers)
✅ **NO Accounts+ module** (removed for simplicity)

**Required Code Changes**:

1. **Pass organization_id and user_id on inserts**:
```typescript
// Before
await supabase.from('products').insert({ name: 'Coffee', price: 5 })

// After (with tenant support + audit tracking)
await supabase.from('products').insert({ 
  name: 'Coffee', 
  price: 5,
  organization_id: user.user_metadata.organization_id,
  user_id: user.id  // ← Tracks who created it
})
// ✅ Audit log automatically created by trigger
```

2. **Helper function** (add to `lib/supabase/client.ts`):
```typescript
export async function getUserOrganizationId() {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null
  
  const { data } = await supabase
    .from('user_profiles')
    .select('organization_id')
    .eq('user_id', user.id)
    .single()
  
  return data?.organization_id
}

// Track user session on login
export async function createUserSession(deviceType: 'web' | 'desktop' | 'mobile') {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return

  const orgId = await getUserOrganizationId()
  
  await supabase.from('user_sessions').insert({
    organization_id: orgId,
    user_id: user.id,
    user_email: user.email,
    device_type: deviceType,
    ip_address: null, // Can be populated from server-side
    user_agent: navigator.userAgent
  })
}

// View user's recent activity
export async function getUserAuditLogs(limit = 50) {
  const { data } = await supabase
    .from('audit_logs')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit)
  
  return data
}
```

3. **Remove Accounts+ routes and components**:
```typescript
// ❌ REMOVE these routes (moved to Desktop):
// - /workspace/accounting/**
// - /workspace/chart-of-accounts/**
// - /workspace/ledger/**
// - /workspace/journal-entries/**
// - /workspace/financial-reports/**

// ✅ KEEP these routes (Web = Operations):
// - /workspace/dashboard (operational metrics)
// - /workspace/pos (point of sale)
// - /workspace/products (inventory)
// - /workspace/stock (stock management)
// - /workspace/sales (sales & orders)
// - /workspace/customers (customer management)
// - /workspace/suppliers (supplier management)
// - /workspace/exin (income/expense tracking)
// - /workspace/reports (sales reports only, not financial)

// Navigation update:
const webAppNavigation = [
  { section: 'Operations', items: [
    { href: '/workspace/dashboard', label: 'Dashboard', icon: 'LayoutDashboard' },
    { href: '/workspace/pos', label: 'POS', icon: 'ShoppingCart' },
  ]},
  { section: 'Inventory', items: [
    { href: '/workspace/products', label: 'Products', icon: 'Package' },
    { href: '/workspace/stock', label: 'Stock', icon: 'Warehouse' },
  ]},
  { section: 'Business', items: [
    { href: '/workspace/sales', label: 'Sales', icon: 'TrendingUp' },
    { href: '/workspace/customers', label: 'Customers', icon: 'Users' },
    { href: '/workspace/suppliers', label: 'Suppliers', icon: 'Truck' },
    { href: '/workspace/exin', label: 'ExIn', icon: 'DollarSign' },
  ]},
  { section: 'Reports', items: [
    { href: '/workspace/reports', label: 'Sales Reports', icon: 'BarChart' },
  ]},
  // ❌ NO Accounts+ section
];
```

### 🖥️ Desktop App Setup (Flutter)

**Location**: `desktop-app/flutter_app/lib/`

The desktop app uses local SQLite + Supabase sync. Updates needed:

✅ **Full Accounts+ module included** (chart of accounts, ledger, etc.)
✅ **Audit logging supported** (syncs to Supabase)
✅ Offline-first with automatic sync

**1. Update Local Database Schema** (`lib/services/database_service.dart`):

```dart
// Add to table creation
await db.execute('''
  ALTER TABLE products ADD COLUMN organization_id TEXT NOT NULL;
  ALTER TABLE products ADD COLUMN user_id TEXT;
''');

// Add audit logs table (for offline tracking)
await db.execute('''
  CREATE TABLE IF NOT EXISTS audit_logs_local (
    id TEXT PRIMARY KEY,
    organization_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    action TEXT NOT NULL,
    table_name TEXT,
    record_id TEXT,
    old_data TEXT,
    new_data TEXT,
    description TEXT,
    created_at TEXT NOT NULL,
    synced INTEGER DEFAULT 0
  );
''');

// Add user sessions table
await db.execute('''
  CREATE TABLE IF NOT EXISTS user_sessions_local (
    id TEXT PRIMARY KEY,
    organization_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    login_at TEXT NOT NULL,
    logout_at TEXT,
    device_type TEXT DEFAULT 'desktop',
    synced INTEGER DEFAULT 0
  );
''');

// Do this for all tables: categories, units, products, customers, etc.
```

**2. Update Sync Logic** (`lib/services/sync_service.dart`):

```dart
Future<void> syncProducts() async {
  // Get user's organization
  final orgId = await getUserOrganizationId();
  
  // Sync from Supabase (RLS automatically filters)
  final response = await supabase
    .from('products')
    .select()
    .eq('organization_id', orgId);
  
  // Update local database
  for (var product in response) {
    await db.insert('products', product, 
      conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

Future<void> pushLocalChanges() async {
  final orgId = await getUserOrganizationId();
  final userId = supabase.auth.currentUser?.id;
  
  // Get local changes
  final localProducts = await db.query('products', 
    where: 'synced_at IS NULL OR synced_at < updated_at');
  
  // Push to Supabase with organization_id
  for (var product in localProducts) {
    product['organization_id'] = orgId;
    product['user_id'] = userId;
    
    await supabase.from('products').upsert(product);
    // ✅ Audit log automatically created by Supabase trigger
    
    // Mark as synced
    await db.update('products', 
      {'synced_at': DateTime.now().toIso8601String()},
      where: 'id = ?', whereArgs: [product['id']]);
  }
  
  // Sync local audit logs to Supabase
  await syncAuditLogs();
}

// Sync audit logs
Future<void> syncAuditLogs() async {
  final localLogs = await db.query('audit_logs_local', 
    where: 'synced = 0');
  
  for (var log in localLogs) {
    await supabase.from('audit_logs').insert({
      ...log,
      'old_data': log['old_data'] != null ? jsonDecode(log['old_data']) : null,
      'new_data': log['new_data'] != null ? jsonDecode(log['new_data']) : null,
    });
    
    // Mark as synced
    await db.update('audit_logs_local', 
      {'synced': 1},
      where: 'id = ?', whereArgs: [log['id']]);
  }
}

// Log local actions (for offline mode)
Future<void> logLocalAction(String action, String tableName, String recordId, 
    Map<String, dynamic>? oldData, Map<String, dynamic>? newData) async {
  final orgId = await getUserOrganizationId();
  final userId = supabase.auth.currentUser?.id;
  
  await db.insert('audit_logs_local', {
    'id': Uuid().v4(),
    'organization_id': orgId,
    'user_id': userId,
    'action': action,
    'table_name': tableName,
    'record_id': recordId,
    'old_data': oldData != null ? jsonEncode(oldData) : null,
    'new_data': newData != null ? jsonEncode(newData) : null,
    'description': '$action ${tableName}',
    'created_at': DateTime.now().toIso8601String(),
    'synced': 0
  });
}
```

**3. Track User Sessions**:

```dart
// On app login
Future<void> onUserLogin() async {
  final orgId = await getUserOrganizationId();
  final userId = supabase.auth.currentUser?.id;
  
  final sessionId = Uuid().v4();
  
  // Local session
  await db.insert('user_sessions_local', {
    'id': sessionId,
    'organization_id': orgId,
    'user_id': userId,
    'login_at': DateTime.now().toIso8601String(),
    'device_type': 'desktop',
    'synced': 0
  });
  
  // Try to sync to Supabase if online
  try {
    await supabase.from('user_sessions').insert({
      'id': sessionId,
      'organization_id': orgId,
      'user_id': userId,
      'user_email': supabase.auth.currentUser?.email,
      'device_type': 'desktop'
    });
    
    await db.update('user_sessions_local',
      {'synced': 1},
      where: 'id = ?', whereArgs: [sessionId]);
  } catch (e) {
    // Will sync later when online
  }
}

// On app logout
Future<void> onUserLogout(String sessionId) async {
  final logoutTime = DateTime.now().toIso8601String();
  
  // Update local
  await db.update('user_sessions_local',
    {'logout_at': logoutTime, 'synced': 0},
    where: 'id = ?', whereArgs: [sessionId]);
  
  // Try to sync to Supabase if online
  try {
    await supabase.from('user_sessions')
      .update({'logout_at': logoutTime, 'is_active': false})
      .eq('id', sessionId);
  } catch (e) {
    // Will sync later
  }
}
```

**4. Handle User Registration**:

```dart
// After user signs up
Future<void> onUserRegistration(String userId) async {
  // Create organization
  final org = await supabase.from('organizations').insert({
    'name': 'My Business',
    'slug': 'my-business-${DateTime.now().millisecondsSinceEpoch}'
  }).select().single();
  
  // Link user to organization
  await supabase.from('user_profiles').insert({
    'user_id': userId,
    'organization_id': org['id'],
    'role': 'owner'
  });
  
  // Seed chart of accounts (for Accounts+ module)
  await supabase.rpc('seed_chart_of_accounts', 
    params: {'p_organization_id': org['id']});
}
```

**5. Desktop App = Accounts+ ONLY**:
```dart
// ✅ KEEP ONLY these routes (Desktop = Accounting):
// - /accounting/dashboard (financial dashboard)
// - /accounting/chart-of-accounts (manage accounts)
// - /accounting/ledger (general ledger)
// - /accounting/journal-entries (manual entries)
// - /accounting/provisions (automatic provisions)
// - /accounting/reconciliation (bank reconciliation)
// - /accounting/reports/balance-sheet
// - /accounting/reports/income-statement
// - /accounting/reports/trial-balance
// - /accounting/reports/cash-flow
// - /accounting/reports/general-ledger-report
// - /accounting/settings (accounting preferences)

// ❌ REMOVE these routes (moved to Web):
// - /pos/** (Point of Sale)
// - /products/** (Product management)
// - /stock/** (Stock management)
// - /sales/** (Sales management)
// - /customers/** (Customer management)
// - /suppliers/** (Supplier management)
// - /exin/** (Income/Expense)

// Navigation for Desktop:
final desktopNavigation = [
  NavigationSection(
    title: 'Dashboard',
    items: [
      NavigationItem(route: '/accounting/dashboard', label: 'Overview', icon: Icons.dashboard),
    ],
  ),
  NavigationSection(
    title: 'Accounts',
    items: [
      NavigationItem(route: '/accounting/chart-of-accounts', label: 'Chart of Accounts', icon: Icons.account_tree),
      NavigationItem(route: '/accounting/ledger', label: 'General Ledger', icon: Icons.book),
      NavigationItem(route: '/accounting/journal-entries', label: 'Journal Entries', icon: Icons.edit_note),
      NavigationItem(route: '/accounting/provisions', label: 'Provisions', icon: Icons.savings),
    ],
  ),
  NavigationSection(
    title: 'Reports',
    items: [
      NavigationItem(route: '/accounting/reports/balance-sheet', label: 'Balance Sheet', icon: Icons.balance),
      NavigationItem(route: '/accounting/reports/income-statement', label: 'Income Statement', icon: Icons.trending_up),
      NavigationItem(route: '/accounting/reports/trial-balance', label: 'Trial Balance', icon: Icons.calculate),
      NavigationItem(route: '/accounting/reports/cash-flow', label: 'Cash Flow', icon: Icons.water_drop),
    ],
  ),
];

// Add automatic provisions feature
Future<void> runMonthlyProvisions() async {
  try {
    await supabase.rpc('run_all_provisions');
    showSuccessMessage('Monthly provisions created successfully');
  } catch (e) {
    showErrorMessage('Failed to create provisions: $e');
  }
}

// Schedule provisions on first of month
void scheduleProvisions() {
  Timer.periodic(Duration(days: 1), (timer) {
    final now = DateTime.now();
    if (now.day == 1 && now.hour == 0) {
      runMonthlyProvisions();
    }
  });
}
```

### 🔄 Sync Behavior

**Web App**: Real-time, always connected
- Changes appear instantly across all browser tabs
- Uses Supabase Realtime subscriptions
- No manual sync needed

**Desktop App**: Offline-first with periodic sync
- Works fully offline with local SQLite
- Syncs when internet available
- Conflict resolution: Last write wins
- Background sync every 5 minutes (configurable)

### Common Operations with Tenancy

**Create a Product**:
```typescript
// Web
const orgId = await getUserOrganizationId()
await supabase.from('products').insert({
  organization_id: orgId,
  user_id: user.id,
  name: 'Coffee',
  unit_price: 5.00,
  stock_quantity: 100
})
```

**Make a Sale** (auto-updates stock & ledger):
```typescript
// Web
const sale = await supabase.from('sales').insert({
  organization_id: orgId,
  user_id: user.id,
  customer_id: customerId,
  total_amount: 50.00,
  tax: 5.00,
  status: 'completed'
}).select().single()

// Add items (triggers stock reduction)
await supabase.from('sale_items').insert([
  {
    organization_id: orgId,
    sale_id: sale.id,
    product_id: productId,
    quantity: 10,
    unit_price: 5.00,
    total: 50.00
  }
])
// ✅ Stock automatically reduced by 10
// ✅ Ledger entries automatically created
```

**View Reports** (automatically filtered to user's org):
```typescript
// Web - Sales report
const { data: sales } = await supabase
  .from('sales')
  .select('*, sale_items(*, products(name))')
  .gte('created_at', startDate)
  .lte('created_at', endDate)
// ✅ Only shows sales from user's organization (RLS enforced)
```

## Step 7: Verify Everything Works

1. Go to **Storage** in the left sidebar
2. Click **New bucket**
3. Create a bucket named: `billease-files`
4. Settings:
   - Public bucket: ON (for product images)
   - File size limit: 5MB
   - Allowed MIME types: `image/*`

### Storage Policy
```sql
-- Allow public read access
CREATE POLICY "Public Access" ON storage.objects FOR SELECT
  USING (bucket_id = 'billease-files');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'billease-files' AND auth.role() = 'authenticated');
```

## Step 7: Verify Everything Works

### Test 1: RLS & Tenancy

```sql
-- In SQL Editor, test as authenticated user
SELECT * FROM products;
-- Should only show products from your organization

-- Try to access another org's data (should return 0)
SELECT COUNT(*) FROM products WHERE organization_id = 'fake-org-id';
```

### Test 2: Stock Automation

```sql
-- Check initial stock
SELECT name, stock_quantity FROM products WHERE name = 'Test Product';

-- Create a sale with sale items
INSERT INTO sales (organization_id, user_id, total_amount, status)
VALUES ('your-org-id', 'your-user-id', 50.00, 'completed')
RETURNING id;

INSERT INTO sale_items (organization_id, sale_id, product_id, quantity, unit_price, total)
VALUES ('your-org-id', 'sale-id-from-above', 'product-id', 5, 10.00, 50.00);

-- Check stock again (should be reduced by 5)
SELECT name, stock_quantity FROM products WHERE name = 'Test Product';

-- Check stock movements
SELECT * FROM stock_movements WHERE product_id = 'product-id' ORDER BY created_at DESC;
```

### Test 3: Ledger Auto-Posting

```sql
-- Check ledger entries created from the sale
SELECT 
  l.description,
  c.code,
  c.name,
  l.debit,
  l.credit
FROM ledger l
JOIN chart_of_accounts c ON c.id = l.account_id
WHERE l.reference_type = 'sale' AND l.reference_id = 'sale-id-from-above';

-- Should show multiple entries (Cash/AR debit, Revenue credit, etc.)
```

### Test 4: Web App

1. Open web app: `http://localhost:3001`
2. Sign in with `demo@001.com` / `demo@123`
3. Navigate to Products
4. Create a new product
5. Go to Sales and create a sale
6. Check that stock decreased
7. Go to Accounting → Ledger and verify entries exist

### Test 5: Desktop App

1. Launch Flutter desktop app
2. Sign in with same credentials
3. Verify products sync from web
4. Create a product in desktop app
5. Create a sale in desktop app
6. Verify in web app that data synced

## Step 8: Storage Setup (Optional - for product images)

1. Go to **Storage** in the left sidebar
2. Click **New bucket**
3. Create a bucket named: `billease-files`
4. Settings:
   - Public bucket: ON (for product images)
   - File size limit: 5MB
   - Allowed MIME types: `image/*`

### Storage Policy
```sql
-- Allow public read access
CREATE POLICY "Public Access" ON storage.objects FOR SELECT
  USING (bucket_id = 'billease-files');

-- Allow authenticated users to upload (tenant-aware)
CREATE POLICY "Authenticated users can upload" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'billease-files' AND 
    auth.role() = 'authenticated'
  );

-- Users can only delete their own org's files
CREATE POLICY "Users can delete own org files" ON storage.objects FOR DELETE
  USING (
    bucket_id = 'billease-files' AND 
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.user_organization_id()::text
  );
```

**Recommended folder structure**:
```
billease-files/
  {organization_id}/
    products/
      {product_id}.jpg
    invoices/
      {invoice_id}.pdf
```

## Step 9: Monitoring and Logs

1. Go to **Logs** → **API** to see all database queries
2. Go to **Logs** → **Auth** to see authentication logs
3. Go to **Database** → **Replication** to monitor sync status (for desktop app)
4. Set up **Alerts** in Settings for:
   - High query count (performance issues)
   - Failed auth attempts (security)
   - Storage limit warnings

## 🔧 Troubleshooting Guide

### Issue: "Row violates row-level security policy"

**Cause**: User not linked to organization OR organization_id missing

**Solution**:
```sql
-- Check user's organization
SELECT * FROM user_profiles WHERE user_id = 'your-user-id';

-- If missing, create profile
INSERT INTO user_profiles (user_id, organization_id, role)
VALUES ('your-user-id', 'your-org-id', 'owner');

-- Check if organization exists
SELECT * FROM organizations WHERE id = 'your-org-id';
```

### Issue: Stock not updating automatically

**Cause**: Trigger not created or disabled

**Solution**:
```sql
-- Check if trigger exists
SELECT * FROM pg_trigger WHERE tgname = 'trigger_update_stock_on_sale';

-- If missing, recreate it (see Step 2.12)
-- Test manually
INSERT INTO sale_items (organization_id, sale_id, product_id, quantity, unit_price, total)
VALUES ('org-id', 'sale-id', 'product-id', 1, 10, 10);

-- Check trigger fired
SELECT * FROM stock_movements ORDER BY created_at DESC LIMIT 5;
```

### Issue: Ledger entries not created

**Cause**: Chart of accounts not seeded OR account codes don't match

**Solution**:
```sql
-- Check if accounts exist
SELECT code, name, type FROM chart_of_accounts 
WHERE organization_id = 'your-org-id' 
  AND code IN ('1000', '4000', '2100', '5000');

-- If missing, seed them
SELECT seed_chart_of_accounts('your-org-id');

-- Check trigger logs (in Logs → Functions)
```

### Issue: Desktop app not syncing

**Cause**: Internet connection, RLS blocking, or sync logic issues

**Solution**:
1. Check internet connection
2. Verify Supabase URL/keys in app config
3. Check Supabase Logs → API for errors
4. Ensure user is authenticated: `supabase.auth.currentUser`
5. Check if organization_id is set on local records before push
6. Test with direct Supabase query:
```dart
final test = await supabase.from('products').select().limit(1);
print(test); // Should return data if RLS allows
```

### Issue: User can see other organization's data

**Cause**: RLS policy not applied OR auth.user_organization_id() returning wrong org

**Solution**:
```sql
-- Test the helper function
SELECT auth.user_organization_id();
-- Should return your organization ID

-- Check if policies exist
SELECT * FROM pg_policies WHERE tablename = 'products';

-- Re-apply policies if needed (see Step 2 for each table)
```

### Issue: Web app shows "organization_id cannot be null"

**Cause**: Client-side code not passing organization_id

**Solution**: Ensure all inserts include organization_id:
```typescript
const orgId = await getUserOrganizationId()
if (!orgId) throw new Error('No organization found for user')

await supabase.from('products').insert({
  organization_id: orgId,  // ← Required!
  user_id: user.id,
  name: 'Product',
  // ... other fields
})
```

### Issue: Audit logs not being created

**Cause**: Triggers not created or auth.uid() returning null

**Solution**:
```sql
-- Check if audit trigger exists
SELECT tgname FROM pg_trigger WHERE tgname LIKE 'audit_%';

-- Test current user
SELECT auth.uid(), current_user;

-- Manually test audit logging
INSERT INTO products (organization_id, user_id, name, unit_price)
VALUES ('your-org-id', auth.uid(), 'Test Product', 10.00);

-- Check if audit log was created
SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 5;

-- If no logs, recreate triggers (see Step 2.14)
```

### Issue: User activity summary not updating

**Cause**: Function not scheduled or manual execution needed

**Solution**:
```sql
-- Manually run the update
SELECT update_user_activity_summary();

-- Check if data was created
SELECT * FROM user_activity_summary WHERE date = CURRENT_DATE;

-- Schedule it (requires pg_cron extension - contact Supabase support)
```

### Issue: RLS Policies Blocking Access (Legacy)
**Solution**: Check that your policies allow access for authenticated users:
```sql
-- View current policies
SELECT * FROM pg_policies WHERE tablename = 'products';

-- Drop and recreate if needed
DROP POLICY "policy_name" ON table_name;
CREATE POLICY "new_policy" ON table_name FOR ALL USING (organization_id = auth.user_organization_id());
```

### Issue: Can't Create Users
**Solution**:
1. Go to **Authentication** → **Providers**
2. Ensure Email provider is enabled
3. Check **Authentication** → **URL Configuration** for correct redirect URLs

## 📚 Quick Reference

### Standard Account Codes

| Code | Name | Type | Purpose |
|------|------|------|---------|
| 1000 | Cash | Asset | Cash payments |
| 1200 | Accounts Receivable | Asset | Credit sales |
| 1300 | Inventory | Asset | Product stock |
| 2000 | Accounts Payable | Liability | Supplier bills |
| 2100 | Tax Payable | Liability | Sales tax owed |
| 3000 | Owner Equity | Equity | Owner investment |
| 4000 | Sales Revenue | Revenue | Product sales |
| 5000 | Discounts Given | Expense | Sales discounts |
| 5100 | Cost of Goods Sold | Expense | Product costs |

### Required Fields by Table

**Products**: `organization_id`, `name`, `unit_price`
**Sales**: `organization_id`, `user_id`, `total_amount`, `status`
**Sale Items**: `organization_id`, `sale_id`, `product_id`, `quantity`, `unit_price`, `total`
**Ledger**: `organization_id`, `account_id`, `date`
**All**: `organization_id` (except organizations & user_profiles)

### Common Queries

**Get user's organization**:
```sql
SELECT organization_id FROM user_profiles WHERE user_id = auth.uid();
```

**Total sales today**:
```sql
SELECT SUM(total_amount) FROM sales 
WHERE DATE(created_at) = CURRENT_DATE;
```

**Low stock products**:
```sql
SELECT name, stock_quantity, min_stock_level 
FROM products 
WHERE stock_quantity <= min_stock_level;
```

**Account balance**:
```sql
SELECT code, name, balance FROM chart_of_accounts 
WHERE type = 'Asset';
```

**Recent stock movements**:
```sql
SELECT 
  p.name, 
  sm.quantity, 
  sm.type, 
  sm.created_at
FROM stock_movements sm
JOIN products p ON p.id = sm.product_id
ORDER BY sm.created_at DESC
LIMIT 20;
```

**View user's recent actions (Audit Log)**:
```sql
SELECT 
  user_name,
  action,
  table_name,
  description,
  created_at
FROM audit_logs
WHERE user_id = 'specific-user-id'
ORDER BY created_at DESC
LIMIT 50;
```

**View all actions on a specific record**:
```sql
SELECT 
  user_name,
  action,
  old_data,
  new_data,
  created_at
FROM audit_logs
WHERE record_id = 'specific-record-id'
ORDER BY created_at DESC;
```

**User activity summary for today**:
```sql
SELECT 
  up.full_name,
  uas.total_actions,
  uas.total_inserts,
  uas.total_updates,
  uas.total_deletes,
  uas.total_sales,
  uas.session_count
FROM user_activity_summary uas
JOIN user_profiles up ON up.user_id = uas.user_id
WHERE uas.date = CURRENT_DATE
ORDER BY uas.total_actions DESC;
```

**Active user sessions**:
```sql
SELECT 
  user_email,
  user_name,
  login_at,
  device_type,
  ip_address
FROM user_sessions
WHERE is_active = true
ORDER BY login_at DESC;
```

**Most active users this month**:
```sql
SELECT 
  up.full_name,
  COUNT(*) as action_count,
  COUNT(DISTINCT DATE(al.created_at)) as active_days
FROM audit_logs al
JOIN user_profiles up ON up.user_id = al.user_id
WHERE al.created_at >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY up.full_name
ORDER BY action_count DESC
LIMIT 10;
```

**Data changes in last 24 hours**:
```sql
SELECT 
  table_name,
  action,
  COUNT(*) as change_count
FROM audit_logs
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY table_name, action
ORDER BY change_count DESC;
```

## 🚀 Production Deployment Checklist

- [ ] All tables created with RLS enabled
- [ ] All triggers created and tested
- [ ] Chart of accounts seeded for test organization
- [ ] Test user created and linked to organization  
- [ ] RLS policies verified (no data leakage between orgs)
- [ ] Stock automation tested (sale reduces stock)
- [ ] Ledger auto-posting tested (sale creates ledger entries)
- [ ] **Audit logging tested** (all actions tracked in audit_logs)
- [ ] **User sessions tracked** (login/logout recorded)
- [ ] **Activity summaries working** (daily stats generated)
- [ ] Web app updated to pass `organization_id` and `user_id`
- [ ] Desktop app schema updated with tenant fields
- [ ] Desktop app sync logic updated for tenancy
- [ ] **Web app: Accounts+ module removed** (all accounting features)
- [ ] **Desktop app: Accounts+ module active** (full accounting)
- [ ] Storage bucket created with policies
- [ ] Email provider configured in Auth
- [ ] Backup schedule configured
- [ ] Monitoring alerts set up
- [ ] `.env` files configured (never commit to git!)
- [ ] Production URLs updated in environment files
- [ ] Audit log retention policy defined (optional)
- [ ] User activity reports accessible to admins

## 🔐 Security Best Practices

✅ **DO**:
- Use RLS on all tables (including audit_logs)
- Validate organization_id on client side before insert
- Test with multiple organizations to ensure isolation
- Use prepared statements (Supabase does this automatically)
- Enable MFA for admin accounts
- Regular database backups
- Monitor logs for suspicious activity
- **Review audit logs regularly for anomalies**
- **Track user sessions and unusual access patterns**
- **Set up alerts for high-privilege actions** (deletions, account changes)
- **Implement audit log retention policy** (e.g., keep for 1-2 years)
- **Restrict audit log access to admins only**

❌ **DON'T**:
- Disable RLS (even temporarily)
- Use service role key in client apps
- Hard-code organization IDs in code
- Trust client-provided organization_id without verification
- Commit API keys to version control
- Grant SUPERUSER privileges unnecessarily
- **Delete audit logs** (archive old logs instead)
- **Allow users to modify audit_logs** (read-only for non-admins)
- **Ignore failed authentication attempts in logs**

## 📖 Additional Resources

- **Supabase RLS Guide**: https://supabase.com/docs/guides/auth/row-level-security
- **Multi-tenancy Patterns**: https://supabase.com/docs/guides/database/multi-tenancy
- **Triggers Documentation**: https://www.postgresql.org/docs/current/sql-createtrigger.html
- **Flutter Offline Sync**: See `desktop-app/OFFLINE_SYNC_IMPLEMENTATION.md`
- **Web App Architecture**: See `web-app/ARCHITECTURE_README.md`

## Next Steps

1. **Seed Sample Data**: Run SQL scripts to add sample categories, units, products
2. **Set Up Backup**: Configure automatic backups in **Settings** → **Backup**
3. **Production**: Update environment variables with production URLs
4. **Monitoring**: Set up alerts in **Settings** → **Alerts**

## Important Security Notes

⚠️ **Never commit these keys to public repositories:**
- Service Role Key (already in .env files)
- Database password
- API secrets

✅ **Safe to expose:**
- Supabase URL
- Anon/Public Key (with proper RLS policies)

## Support

- Supabase Documentation: https://supabase.com/docs
- Supabase Discord: https://discord.supabase.com
- BillEase Suite Issues: Check the project README

---

**Configuration Status**: ✅ ENHANCED with Multi-Tenancy, Automation & Complete Audit Logging

## 🎯 What's Included

### 🔐 Tenant-Based RLS (Row Level Security)
- ✅ Multi-organization support (perfect for agencies with multiple clients)
- ✅ Complete data isolation between tenants
- ✅ User profiles linked to organizations
- ✅ Helper function: `auth.user_organization_id()`
- ✅ All policies enforce organization-level access

### 👤 Proper User Linking
- ✅ All data tables include `user_id` field
- ✅ Sales and transactions require `user_id` (tracked by creator)
- ✅ User profiles with role-based access (owner, admin, user, viewer)
- ✅ Multi-user support per organization

### ⚡ Stock Auto-Update Triggers
- ✅ Automatically reduces stock when sale items created
- ✅ Automatically adjusts stock when sale items updated
- ✅ Automatically restores stock when sale items deleted
- ✅ Creates stock movement records for audit trail
- ✅ Works for both web and desktop apps

### 📊 Ledger Auto-Posting from Sales
- ✅ Automatically creates ledger entries when sales completed
- ✅ Posts to correct accounts (Cash/AR, Revenue, Tax, Discounts)
- ✅ Updates chart of accounts balances automatically
- ✅ Maintains double-entry bookkeeping integrity
- ✅ Full audit trail with reference linking

### 🔍 COMPLETE Audit Logging & User Activity Tracking (NEW!)
- ✅ **Every action tracked**: INSERT, UPDATE, DELETE on all tables
- ✅ **User identification**: Tracks who did what and when
- ✅ **Full data history**: Stores old and new values for all changes
- ✅ **Session tracking**: Login/logout times, IP addresses, device types
- ✅ **Activity summaries**: Daily statistics per user
- ✅ **Automatic triggers**: No code changes needed - works automatically
- ✅ **Organization-isolated**: Each tenant sees only their audit logs
- ✅ **Searchable**: Indexed for fast queries and reports

### 🔔 Additional Automation
- ✅ Auto-update `updated_at` timestamps on all tables
- ✅ Account balance auto-calculation from ledger
- ✅ Function to seed default chart of accounts
- ✅ **Automatic Provisions** (NEW!)
  - Bad debt provision (5% of receivables)
  - Depreciation provision (10% annually on equipment)
  - Runs automatically monthly
  - Creates proper journal entries
  - Updates account balances
- ✅ **Automatic Provisions** (NEW!)
  - Bad debt provision (5% of receivables)
  - Depreciation provision (10% annually on equipment)
  - Runs automatically monthly
  - Creates proper journal entries
  - Updates account balances

### 📱 Module Distribution

**🖥️ DESKTOP APP (Flutter)** - ACCOUNTING ONLY:
- ✅ **Accounts+ (Full Accounting Module)** ← ONLY MODULE IN DESKTOP
  - Chart of Accounts
  - General Ledger
  - Journal Entries
  - Double-entry bookkeeping
  - Financial reports (Balance Sheet, P&L, Trial Balance, Cash Flow)
  - Account reconciliation
  - Provisions & adjustments (automatic)
  - Period closing
- ❌ **NO POS** (moved to web)
- ❌ **NO Stock Management** (moved to web)
- ❌ **NO ExIn** (moved to web)

**🌐 WEB APP (Next.js)** - OPERATIONS ONLY:
- ✅ **POS (Point of Sale)** - Fast checkout, receipts
- ✅ **Stock Management** - Products, inventory, categories
- ✅ **ExIn (Income/Expense Tracking)** - Quick transactions
- ✅ **Sales Management** - Orders, customers, reports
- ✅ **Dashboard** - Real-time metrics and analytics
- ❌ **NO Accounts+** (moved to desktop)

**WHY?**: Clear separation - Desktop for accountants/bookkeepers (financial control), Web for operations team (sales, inventory, daily tasks). Best user experience for each role.

## 📋 Setup Status

- [x] Desktop App: Configured (needs code updates for tenancy + audit logging)
- [x] Web App (.env.local): Configured (needs code updates for tenancy + audit logging)
- [x] Web App (.env.production): Configured
- [x] Database Tables: **READY - Run all SQL scripts in Step 2**
- [x] Authentication: **READY - Follow Step 3**
- [x] Tenant System: **READY - Organizations + User Profiles**
- [x] Automation: **READY - All triggers included**
- [x] Audit Logging: **READY - Complete tracking system**
- [x] User Activity Tracking: **READY - Session & summary tables**

## 🚦 Getting Started

1. **Run Step 2.0**: Create organizations & user_profiles tables FIRST
2. **Run Steps 2.1-2.11**: Create all data tables with tenant support
3. **Run Step 2.12**: Create all automation triggers
4. **Run Step 2.13**: Optional - Seed chart of accounts function
5. **Run Step 2.14**: Create audit logging system (tracks ALL user actions)
6. **Follow Step 3**: Set up authentication & create test user/org
7. **Follow Step 6**: Update web app code for tenancy
8. **Follow Step 6**: Update desktop app code for tenancy
9. **Follow Step 7**: Test everything works
10. **Check audit logs**: Query `audit_logs` table to see tracked actions

## 🎓 Key Concepts

**Tenant/Organization**: A business entity (e.g., "ABC Store", "XYZ Restaurant")
**User Profile**: Links a user account to one or more organizations
**RLS**: Automatically filters all queries to show only user's org data
**Triggers**: Database functions that run automatically on data changes

## ⚠️ Breaking Changes from Previous Version

If you already have tables created WITHOUT tenant support:

```sql
-- You'll need to migrate existing data
-- 1. Create new organization
-- 2. Add organization_id columns
-- 3. Update existing rows with organization_id
-- 4. Add NOT NULL constraint
-- 5. Update RLS policies

-- Example migration:
ALTER TABLE products ADD COLUMN organization_id UUID REFERENCES organizations(id);
UPDATE products SET organization_id = 'your-org-id';
ALTER TABLE products ALTER COLUMN organization_id SET NOT NULL;
```

Or start fresh by dropping and recreating all tables (CAUTION: deletes all data).
