-- =====================================================
-- BillEase Admin Database Schema for Supabase
-- Run this in your Supabase SQL Editor
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- Admin Customers Table
-- =====================================================
CREATE TABLE IF NOT EXISTS admin_customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  company VARCHAR(255) NOT NULL DEFAULT '',
  phone VARCHAR(50),
  address TEXT,
  subscription_id UUID,
  subscription_plan VARCHAR(100),
  license_count INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
  join_date TIMESTAMPTZ DEFAULT NOW(),
  last_active TIMESTAMPTZ DEFAULT NOW(),
  total_spent DECIMAL(12, 2) DEFAULT 0,
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_admin_customers_email ON admin_customers(email);
CREATE INDEX idx_admin_customers_status ON admin_customers(status);
CREATE INDEX idx_admin_customers_user_id ON admin_customers(user_id);

-- =====================================================
-- Desktop Licenses Table
-- =====================================================
CREATE TABLE IF NOT EXISTS desktop_licenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  license_key VARCHAR(50) UNIQUE NOT NULL,
  customer_id UUID REFERENCES admin_customers(id) ON DELETE SET NULL,
  customer_name VARCHAR(255),
  customer_email VARCHAR(255),
  product VARCHAR(255) NOT NULL,
  product_code VARCHAR(20) NOT NULL,
  license_type VARCHAR(20) DEFAULT 'perpetual' CHECK (license_type IN ('perpetual', 'subscription', 'trial')),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('active', 'expired', 'revoked', 'pending')),
  activations INTEGER DEFAULT 0,
  max_activations INTEGER DEFAULT 1,
  activated_on TIMESTAMPTZ,
  expires_on TIMESTAMPTZ,
  last_checked TIMESTAMPTZ,
  hardware_ids TEXT[] DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_desktop_licenses_key ON desktop_licenses(license_key);
CREATE INDEX idx_desktop_licenses_customer ON desktop_licenses(customer_id);
CREATE INDEX idx_desktop_licenses_status ON desktop_licenses(status);
CREATE INDEX idx_desktop_licenses_product ON desktop_licenses(product);

-- =====================================================
-- License Activations Table
-- =====================================================
CREATE TABLE IF NOT EXISTS license_activations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  license_id UUID REFERENCES desktop_licenses(id) ON DELETE CASCADE,
  hardware_id VARCHAR(255) NOT NULL,
  machine_name VARCHAR(255),
  os_info VARCHAR(255),
  ip_address VARCHAR(50),
  activated_at TIMESTAMPTZ DEFAULT NOW(),
  deactivated_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_license_activations_license ON license_activations(license_id);
CREATE INDEX idx_license_activations_hardware ON license_activations(hardware_id);

-- =====================================================
-- Admin Subscriptions Table
-- =====================================================
CREATE TABLE IF NOT EXISTS admin_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES admin_customers(id) ON DELETE SET NULL,
  customer_name VARCHAR(255),
  customer_email VARCHAR(255),
  company VARCHAR(255),
  plan_id UUID,
  plan_name VARCHAR(100) NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  billing_cycle VARCHAR(20) DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'yearly')),
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'canceled', 'past_due', 'trialing', 'paused')),
  start_date TIMESTAMPTZ DEFAULT NOW(),
  next_billing_date TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,
  cancel_reason TEXT,
  payment_method VARCHAR(50),
  payment_method_last4 VARCHAR(4),
  stripe_subscription_id VARCHAR(255),
  stripe_customer_id VARCHAR(255),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_admin_subscriptions_customer ON admin_subscriptions(customer_id);
CREATE INDEX idx_admin_subscriptions_status ON admin_subscriptions(status);
CREATE INDEX idx_admin_subscriptions_plan ON admin_subscriptions(plan_name);

-- =====================================================
-- Pricing Plans Table
-- =====================================================
CREATE TABLE IF NOT EXISTS pricing_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  monthly_price DECIMAL(10, 2) NOT NULL,
  yearly_price DECIMAL(10, 2) NOT NULL,
  features TEXT[] DEFAULT '{}',
  max_users INTEGER DEFAULT 1,
  max_licenses INTEGER DEFAULT 1,
  is_popular BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  stripe_monthly_price_id VARCHAR(255),
  stripe_yearly_price_id VARCHAR(255),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pricing_plans_slug ON pricing_plans(slug);

-- =====================================================
-- Desktop Product Pricing Table
-- =====================================================
CREATE TABLE IF NOT EXISTS desktop_product_pricing (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product VARCHAR(255) NOT NULL,
  product_code VARCHAR(20) UNIQUE NOT NULL,
  perpetual_price DECIMAL(10, 2) NOT NULL,
  subscription_monthly DECIMAL(10, 2) NOT NULL,
  subscription_yearly DECIMAL(10, 2) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  stripe_perpetual_price_id VARCHAR(255),
  stripe_monthly_price_id VARCHAR(255),
  stripe_yearly_price_id VARCHAR(255),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- Discount Codes Table
-- =====================================================
CREATE TABLE IF NOT EXISTS discount_codes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  discount_type VARCHAR(20) DEFAULT 'percentage' CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value DECIMAL(10, 2) NOT NULL,
  min_purchase_amount DECIMAL(10, 2) DEFAULT 0,
  max_discount_amount DECIMAL(10, 2),
  max_uses INTEGER DEFAULT -1,
  used_count INTEGER DEFAULT 0,
  applicable_to VARCHAR(20) DEFAULT 'all' CHECK (applicable_to IN ('all', 'web', 'desktop')),
  applicable_plans TEXT[],
  applicable_products TEXT[],
  valid_from TIMESTAMPTZ DEFAULT NOW(),
  valid_until TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  stripe_coupon_id VARCHAR(255),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_discount_codes_code ON discount_codes(code);
CREATE INDEX idx_discount_codes_active ON discount_codes(is_active);

-- =====================================================
-- Admin Activities Table
-- =====================================================
CREATE TABLE IF NOT EXISTS admin_activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action_type VARCHAR(50) NOT NULL,
  action VARCHAR(255) NOT NULL,
  resource_id UUID,
  resource_name VARCHAR(255),
  details TEXT,
  ip_address VARCHAR(50),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_admin_activities_admin ON admin_activities(admin_id);
CREATE INDEX idx_admin_activities_type ON admin_activities(action_type);
CREATE INDEX idx_admin_activities_created ON admin_activities(created_at DESC);

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to increment customer license count
CREATE OR REPLACE FUNCTION increment_customer_license_count(customer_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE admin_customers 
  SET license_count = license_count + 1,
      updated_at = NOW()
  WHERE id = customer_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement customer license count
CREATE OR REPLACE FUNCTION decrement_customer_license_count(customer_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE admin_customers 
  SET license_count = GREATEST(0, license_count - 1),
      updated_at = NOW()
  WHERE id = customer_id;
END;
$$ LANGUAGE plpgsql;

-- Function to increment discount usage
CREATE OR REPLACE FUNCTION increment_discount_usage(discount_code VARCHAR)
RETURNS void AS $$
BEGIN
  UPDATE discount_codes 
  SET used_count = used_count + 1,
      updated_at = NOW()
  WHERE code = discount_code;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE admin_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE desktop_licenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE license_activations ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pricing_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE desktop_product_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE discount_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_activities ENABLE ROW LEVEL SECURITY;

-- Admin policy: Allow full access for admin users
CREATE POLICY admin_customers_admin_policy ON admin_customers
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' IN ('admin', 'super_admin')
    )
  );

CREATE POLICY desktop_licenses_admin_policy ON desktop_licenses
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' IN ('admin', 'super_admin')
    )
  );

CREATE POLICY license_activations_admin_policy ON license_activations
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' IN ('admin', 'super_admin')
    )
  );

CREATE POLICY admin_subscriptions_admin_policy ON admin_subscriptions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' IN ('admin', 'super_admin')
    )
  );

CREATE POLICY pricing_plans_admin_policy ON pricing_plans
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' IN ('admin', 'super_admin')
    )
  );

-- Public read access for pricing plans
CREATE POLICY pricing_plans_public_read ON pricing_plans
  FOR SELECT USING (is_active = true);

CREATE POLICY desktop_product_pricing_admin_policy ON desktop_product_pricing
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' IN ('admin', 'super_admin')
    )
  );

-- Public read access for desktop pricing
CREATE POLICY desktop_product_pricing_public_read ON desktop_product_pricing
  FOR SELECT USING (is_active = true);

CREATE POLICY discount_codes_admin_policy ON discount_codes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' IN ('admin', 'super_admin')
    )
  );

CREATE POLICY admin_activities_admin_policy ON admin_activities
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' IN ('admin', 'super_admin')
    )
  );

-- =====================================================
-- Insert Default Data
-- =====================================================

-- Insert default pricing plans
INSERT INTO pricing_plans (name, slug, description, monthly_price, yearly_price, features, max_users, max_licenses, is_popular) VALUES
  ('Starter', 'starter', 'Perfect for small businesses getting started', 9, 90, ARRAY['Up to 100 transactions/month', 'Basic reports', 'Email support', '1 user'], 1, 1, false),
  ('Pro', 'pro', 'For growing businesses that need more power', 29, 290, ARRAY['Unlimited transactions', 'Advanced reports', 'Priority support', 'Up to 5 users', 'API access', 'Desktop app'], 5, 3, true),
  ('Enterprise', 'enterprise', 'For large organizations with custom needs', 199, 1990, ARRAY['Everything in Pro', 'Unlimited users', 'Custom integrations', 'Dedicated support', 'SLA guarantee', 'On-premise option'], -1, 25, false)
ON CONFLICT (slug) DO NOTHING;

-- Insert default desktop product pricing
INSERT INTO desktop_product_pricing (product, product_code, perpetual_price, subscription_monthly, subscription_yearly) VALUES
  ('BillEase POS', 'BE-POS', 299, 19, 190),
  ('BillEase Inventory', 'BE-INV', 249, 15, 150),
  ('BillEase Accounts', 'BE-ACC', 349, 25, 250),
  ('BillEase CRM', 'BE-CRM', 199, 12, 120),
  ('BillEase Suite (All Apps)', 'BE-SUITE', 799, 59, 590)
ON CONFLICT (product_code) DO NOTHING;

-- =====================================================
-- Storage Buckets
-- =====================================================

-- Create storage bucket for admin assets (run this separately in Supabase Storage settings)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('admin-assets', 'admin-assets', true);

-- Storage policy for admin assets
-- CREATE POLICY admin_assets_policy ON storage.objects
--   FOR ALL USING (
--     bucket_id = 'admin-assets' AND
--     EXISTS (
--       SELECT 1 FROM auth.users 
--       WHERE auth.users.id = auth.uid() 
--       AND auth.users.raw_user_meta_data->>'role' IN ('admin', 'super_admin')
--     )
--   );
