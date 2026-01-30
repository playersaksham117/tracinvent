-- ============================================
-- BillEase Main Database - Initial Schema
-- Database: billease_main
-- Description: Central database for users, subscriptions, and app access
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    company_name VARCHAR(255),
    company_size VARCHAR(50),
    industry VARCHAR(100),
    role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('user', 'admin', 'super_admin')),
    email_verified BOOLEAN DEFAULT FALSE,
    avatar_url TEXT,
    timezone VARCHAR(100) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deleted')),
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_ip INET,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- ============================================
-- SUBSCRIPTION PLANS TABLE
-- ============================================
CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    price_monthly DECIMAL(10,2) NOT NULL,
    price_yearly DECIMAL(10,2) NOT NULL,
    billing_period VARCHAR(20) DEFAULT 'monthly' CHECK (billing_period IN ('monthly', 'yearly')),
    features JSONB DEFAULT '[]',
    limits JSONB DEFAULT '{}',
    app_access JSONB DEFAULT '[]', -- ['pos', 'crm', 'accounts', 'inventory']
    is_popular BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    stripe_price_id_monthly VARCHAR(255),
    stripe_price_id_yearly VARCHAR(255),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Subscription plans indexes
CREATE INDEX idx_subscription_plans_slug ON subscription_plans(slug);
CREATE INDEX idx_subscription_plans_active ON subscription_plans(is_active);

-- Insert default plans
INSERT INTO subscription_plans (name, slug, description, price_monthly, price_yearly, app_access, features, is_popular) VALUES
('Starter', 'starter', 'Perfect for small businesses', 29.00, 290.00, '["pos"]', '["POS System", "Up to 100 products", "Basic reports", "Email support"]', FALSE),
('Business', 'business', 'For growing businesses', 79.00, 790.00, '["pos", "crm"]', '["POS + CRM", "Unlimited products", "Advanced reports", "Priority support", "Multi-location"]', TRUE),
('Professional', 'professional', 'Complete business solution', 149.00, 1490.00, '["pos", "crm", "accounts"]', '["POS + CRM + Accounts", "All features", "API access", "24/7 support", "Custom integrations"]', FALSE),
('Enterprise', 'enterprise', 'Full suite with inventory', 249.00, 2490.00, '["pos", "crm", "accounts", "inventory"]', '["All Apps", "Unlimited everything", "Dedicated support", "Custom development", "SLA guarantee"]', FALSE);

-- ============================================
-- SUBSCRIPTIONS TABLE
-- ============================================
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'past_due', 'trialing')),
    billing_period VARCHAR(20) DEFAULT 'monthly' CHECK (billing_period IN ('monthly', 'yearly')),
    current_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    current_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    trial_start TIMESTAMP WITH TIME ZONE,
    trial_end TIMESTAMP WITH TIME ZONE,
    cancel_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    stripe_subscription_id VARCHAR(255),
    stripe_customer_id VARCHAR(255),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Subscriptions indexes
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_plan_id ON subscriptions(plan_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_period_end ON subscriptions(current_period_end);
CREATE INDEX idx_subscriptions_stripe ON subscriptions(stripe_subscription_id);

-- ============================================
-- PAYMENTS TABLE
-- ============================================
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded')),
    payment_method VARCHAR(50),
    stripe_payment_id VARCHAR(255),
    stripe_invoice_id VARCHAR(255),
    description TEXT,
    receipt_url TEXT,
    failure_reason TEXT,
    metadata JSONB DEFAULT '{}',
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Payments indexes
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_subscription_id ON payments(subscription_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_stripe_payment ON payments(stripe_payment_id);
CREATE INDEX idx_payments_created_at ON payments(created_at DESC);

-- ============================================
-- APP ACCESS TABLE
-- ============================================
CREATE TABLE app_access (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    app_id VARCHAR(50) NOT NULL CHECK (app_id IN ('pos', 'crm', 'accounts', 'inventory')),
    has_access BOOLEAN DEFAULT FALSE,
    access_level VARCHAR(50) DEFAULT 'user' CHECK (access_level IN ('user', 'admin', 'owner')),
    granted_by UUID REFERENCES users(id),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    last_accessed_at TIMESTAMP WITH TIME ZONE,
    access_count INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, app_id)
);

-- App access indexes
CREATE INDEX idx_app_access_user_id ON app_access(user_id);
CREATE INDEX idx_app_access_app_id ON app_access(app_id);
CREATE INDEX idx_app_access_has_access ON app_access(has_access);
CREATE INDEX idx_app_access_expires_at ON app_access(expires_at);

-- ============================================
-- AUDIT LOGS TABLE
-- ============================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id UUID,
    changes JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    status VARCHAR(50) DEFAULT 'success' CHECK (status IN ('success', 'failure')),
    error_message TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Audit logs indexes
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- ============================================
-- API KEYS TABLE
-- ============================================
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) NOT NULL UNIQUE,
    key_prefix VARCHAR(20) NOT NULL,
    permissions JSONB DEFAULT '[]',
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- API keys indexes
CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_key_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_is_active ON api_keys(is_active);

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    link TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- ============================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Users policies
CREATE POLICY "Users can view their own data"
    ON users FOR SELECT
    USING (auth.uid()::uuid = id);

CREATE POLICY "Users can update their own data"
    ON users FOR UPDATE
    USING (auth.uid()::uuid = id);

CREATE POLICY "Admins can view all users"
    ON users FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()::uuid
            AND role IN ('admin', 'super_admin')
        )
    );

-- Subscriptions policies
CREATE POLICY "Users can view their own subscriptions"
    ON subscriptions FOR SELECT
    USING (auth.uid()::uuid = user_id);

CREATE POLICY "Admins can view all subscriptions"
    ON subscriptions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()::uuid
            AND role IN ('admin', 'super_admin')
        )
    );

-- Payments policies
CREATE POLICY "Users can view their own payments"
    ON payments FOR SELECT
    USING (auth.uid()::uuid = user_id);

-- App access policies
CREATE POLICY "Users can view their own app access"
    ON app_access FOR SELECT
    USING (auth.uid()::uuid = user_id);

-- Notifications policies
CREATE POLICY "Users can view their own notifications"
    ON notifications FOR SELECT
    USING (auth.uid()::uuid = user_id);

CREATE POLICY "Users can update their own notifications"
    ON notifications FOR UPDATE
    USING (auth.uid()::uuid = user_id);

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscription_plans_updated_at BEFORE UPDATE ON subscription_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_app_access_updated_at BEFORE UPDATE ON app_access
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON api_keys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to grant app access based on subscription
CREATE OR REPLACE FUNCTION grant_app_access_from_subscription()
RETURNS TRIGGER AS $$
DECLARE
    plan_apps JSONB;
    app_name TEXT;
BEGIN
    -- Get app access from subscription plan
    SELECT app_access INTO plan_apps
    FROM subscription_plans
    WHERE id = NEW.plan_id;
    
    -- Only process if subscription is active
    IF NEW.status = 'active' THEN
        -- Loop through each app in the plan
        FOR app_name IN SELECT jsonb_array_elements_text(plan_apps)
        LOOP
            -- Insert or update app access
            INSERT INTO app_access (user_id, app_id, has_access, granted_at)
            VALUES (NEW.user_id, app_name, TRUE, CURRENT_TIMESTAMP)
            ON CONFLICT (user_id, app_id)
            DO UPDATE SET 
                has_access = TRUE,
                granted_at = CURRENT_TIMESTAMP,
                expires_at = NEW.current_period_end;
        END LOOP;
    ELSE
        -- If subscription is not active, revoke access
        UPDATE app_access
        SET has_access = FALSE,
            expires_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-grant app access on subscription creation/update
CREATE TRIGGER grant_app_access_on_subscription
    AFTER INSERT OR UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION grant_app_access_from_subscription();

-- ============================================
-- VIEWS
-- ============================================

-- Active subscriptions view
CREATE OR REPLACE VIEW active_subscriptions AS
SELECT 
    s.*,
    u.email,
    u.full_name,
    sp.name as plan_name,
    sp.app_access
FROM subscriptions s
JOIN users u ON s.user_id = u.id
JOIN subscription_plans sp ON s.plan_id = sp.id
WHERE s.status = 'active'
AND s.current_period_end > CURRENT_TIMESTAMP;

-- User access summary view
CREATE OR REPLACE VIEW user_access_summary AS
SELECT 
    u.id as user_id,
    u.email,
    u.full_name,
    u.role,
    s.status as subscription_status,
    sp.name as plan_name,
    sp.app_access as available_apps,
    json_agg(
        json_build_object(
            'app_id', aa.app_id,
            'has_access', aa.has_access,
            'last_accessed', aa.last_accessed_at
        )
    ) as app_access_details
FROM users u
LEFT JOIN subscriptions s ON u.id = s.user_id AND s.status = 'active'
LEFT JOIN subscription_plans sp ON s.plan_id = sp.id
LEFT JOIN app_access aa ON u.id = aa.user_id
GROUP BY u.id, u.email, u.full_name, u.role, s.status, sp.name, sp.app_access;

-- Revenue analytics view
CREATE OR REPLACE VIEW revenue_analytics AS
SELECT
    DATE_TRUNC('month', paid_at) as month,
    COUNT(*) as payment_count,
    SUM(amount) as total_revenue,
    AVG(amount) as average_payment,
    COUNT(DISTINCT user_id) as unique_customers
FROM payments
WHERE status = 'succeeded'
AND paid_at IS NOT NULL
GROUP BY DATE_TRUNC('month', paid_at)
ORDER BY month DESC;

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE users IS 'Central user accounts for the entire platform';
COMMENT ON TABLE subscription_plans IS 'Available subscription plans with pricing and features';
COMMENT ON TABLE subscriptions IS 'User subscriptions to plans';
COMMENT ON TABLE payments IS 'Payment history and transactions';
COMMENT ON TABLE app_access IS 'Per-app access control for users';
COMMENT ON TABLE audit_logs IS 'Audit trail of all system actions';
COMMENT ON TABLE api_keys IS 'API keys for programmatic access';
COMMENT ON TABLE notifications IS 'User notifications and alerts';

-- ============================================
-- END OF MIGRATION
-- ============================================
