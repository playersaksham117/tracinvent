-- ============================================
-- BillEase SaaS - Multi-Tenant Schema
-- Description: Core multi-tenant architecture for Income, Expense, Budgeting & Analytics
-- ============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- ORGANIZATIONS (Multi-tenant core)
-- ============================================
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    logo_url TEXT,
    
    -- Account Type Configuration
    account_type VARCHAR(20) NOT NULL DEFAULT 'individual' CHECK (account_type IN ('individual', 'family', 'business')),
    
    -- Financial Configuration
    currency VARCHAR(3) DEFAULT 'INR',
    default_currency VARCHAR(3) DEFAULT 'INR', -- Explicit default for multi-currency support
    fiscal_year_start INTEGER DEFAULT 4, -- Month number (1-12), April for India
    timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
    country VARCHAR(2) DEFAULT 'IN', -- ISO 3166-1 alpha-2 country code
    
    -- Business-specific fields
    business_name VARCHAR(255), -- Legal business name
    tax_id VARCHAR(100), -- GST/VAT/Tax ID
    tax_system VARCHAR(50), -- 'gst', 'vat', 'sales_tax', etc.
    company_registration VARCHAR(100), -- Company registration number
    
    -- Feature flags based on account type
    features JSONB DEFAULT '{
        "gst_enabled": false,
        "multi_user": false,
        "advanced_reports": false,
        "api_access": false,
        "team_management": false,
        "expense_approval": false,
        "budget_alerts": true,
        "recurring_transactions": true
    }'::jsonb,
    
    -- Settings
    settings JSONB DEFAULT '{}',
    
    -- Subscription
    subscription_plan VARCHAR(50) DEFAULT 'free',
    subscription_status VARCHAR(50) DEFAULT 'active',
    trial_ends_at TIMESTAMP WITH TIME ZONE,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_org_slug ON organizations(slug);
CREATE INDEX idx_org_active ON organizations(is_active);

-- ============================================
-- USER PROFILES (Extends Supabase auth.users)
-- ============================================
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255),
    avatar_url TEXT,
    phone VARCHAR(20),
    preferences JSONB DEFAULT '{}',
    onboarding_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- ORGANIZATION MEMBERS (User-Organization mapping)
-- ============================================
CREATE TABLE organization_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    permissions JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    invited_by UUID REFERENCES auth.users(id),
    invited_at TIMESTAMP WITH TIME ZONE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, user_id)
);

CREATE INDEX idx_org_members_org ON organization_members(organization_id);
CREATE INDEX idx_org_members_user ON organization_members(user_id);
CREATE INDEX idx_org_members_role ON organization_members(role);

-- ============================================
-- CATEGORIES (Income & Expense categories)
-- ============================================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    color VARCHAR(7) DEFAULT '#6B7280',
    icon VARCHAR(50),
    parent_id UUID REFERENCES categories(id),
    is_system BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, name, type)
);

CREATE INDEX idx_categories_org ON categories(organization_id);
CREATE INDEX idx_categories_type ON categories(type);
CREATE INDEX idx_categories_parent ON categories(parent_id);

-- ============================================
-- ACCOUNTS (Bank accounts, wallets, etc.)
-- ============================================
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('bank', 'cash', 'credit_card', 'wallet', 'investment', 'other')),
    account_number VARCHAR(100),
    bank_name VARCHAR(255),
    balance DECIMAL(15,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'INR',
    is_active BOOLEAN DEFAULT TRUE,
    color VARCHAR(7) DEFAULT '#10B981',
    icon VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_accounts_org ON accounts(organization_id);
CREATE INDEX idx_accounts_type ON accounts(type);

-- ============================================
-- TRANSACTIONS (Income & Expense transactions)
-- ============================================
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) DEFAULT 'INR',
    category_id UUID REFERENCES categories(id),
    account_id UUID REFERENCES accounts(id),
    transaction_date DATE NOT NULL,
    description TEXT,
    notes TEXT,
    tags TEXT[] DEFAULT '{}',
    payment_method VARCHAR(50),
    reference_number VARCHAR(100),
    status VARCHAR(50) DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'cancelled')),
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_rule JSONB,
    parent_transaction_id UUID REFERENCES transactions(id),
    attachments JSONB DEFAULT '[]',
    created_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transactions_org ON transactions(organization_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_date ON transactions(transaction_date DESC);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_transactions_account ON transactions(account_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created_by ON transactions(created_by);

-- ============================================
-- BUDGETS
-- ============================================
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    period_type VARCHAR(20) NOT NULL CHECK (period_type IN ('monthly', 'quarterly', 'yearly', 'custom')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL CHECK (total_amount > 0),
    spent_amount DECIMAL(15,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'INR',
    alert_threshold INTEGER DEFAULT 80, -- Alert at 80%
    alert_enabled BOOLEAN DEFAULT TRUE,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('draft', 'active', 'completed', 'archived')),
    created_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_dates CHECK (end_date > start_date)
);

CREATE INDEX idx_budgets_org ON budgets(organization_id);
CREATE INDEX idx_budgets_period ON budgets(start_date, end_date);
CREATE INDEX idx_budgets_status ON budgets(status);

-- ============================================
-- BUDGET CATEGORIES (Category-wise budget allocation)
-- ============================================
CREATE TABLE budget_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id),
    allocated_amount DECIMAL(15,2) NOT NULL CHECK (allocated_amount >= 0),
    spent_amount DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(budget_id, category_id)
);

CREATE INDEX idx_budget_categories_budget ON budget_categories(budget_id);
CREATE INDEX idx_budget_categories_category ON budget_categories(category_id);

-- ============================================
-- RECURRING TEMPLATES
-- ============================================
CREATE TABLE recurring_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    category_id UUID REFERENCES categories(id),
    account_id UUID REFERENCES accounts(id),
    description TEXT,
    frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly')),
    frequency_interval INTEGER DEFAULT 1,
    start_date DATE NOT NULL,
    end_date DATE,
    next_occurrence DATE,
    last_generated_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_recurring_org ON recurring_templates(organization_id);
CREATE INDEX idx_recurring_next ON recurring_templates(next_occurrence);
CREATE INDEX idx_recurring_active ON recurring_templates(is_active);

-- ============================================
-- ANALYTICS CACHE (For performance)
-- ============================================
CREATE TABLE analytics_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    metric_type VARCHAR(100) NOT NULL,
    period_type VARCHAR(20) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    data JSONB NOT NULL,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(organization_id, metric_type, period_type, period_start)
);

CREATE INDEX idx_analytics_org ON analytics_cache(organization_id);
CREATE INDEX idx_analytics_metric ON analytics_cache(metric_type);
CREATE INDEX idx_analytics_expires ON analytics_cache(expires_at);

-- ============================================
-- ACTIVITY LOGS (Audit trail)
-- ============================================
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    metadata JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activity_org ON activity_logs(organization_id);
CREATE INDEX idx_activity_user ON activity_logs(user_id);
CREATE INDEX idx_activity_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_created ON activity_logs(created_at DESC);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- Organizations: Users can see orgs they're members of
CREATE POLICY "Users can view their organizations"
    ON organizations FOR SELECT
    USING (
        id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND is_active = TRUE
        )
    );

CREATE POLICY "Users can update organizations they own"
    ON organizations FOR UPDATE
    USING (
        id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin') AND is_active = TRUE
        )
    );

-- User Profiles: Users can manage their own profile
CREATE POLICY "Users can view own profile"
    ON user_profiles FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
    ON user_profiles FOR UPDATE
    USING (id = auth.uid());

CREATE POLICY "Users can insert own profile"
    ON user_profiles FOR INSERT
    WITH CHECK (id = auth.uid());

-- Organization Members: View members of orgs you belong to
CREATE POLICY "View organization members"
    ON organization_members FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND is_active = TRUE
        )
    );

CREATE POLICY "Admins can manage members"
    ON organization_members FOR ALL
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin') AND is_active = TRUE
        )
    );

-- Categories: Org members can view, admins can manage
CREATE POLICY "View categories"
    ON categories FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND is_active = TRUE
        )
    );

CREATE POLICY "Manage categories"
    ON categories FOR ALL
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'member') AND is_active = TRUE
        )
    );

-- Accounts: Similar to categories
CREATE POLICY "View accounts"
    ON accounts FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND is_active = TRUE
        )
    );

CREATE POLICY "Manage accounts"
    ON accounts FOR ALL
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'member') AND is_active = TRUE
        )
    );

-- Transactions: Org members can view and manage
CREATE POLICY "View transactions"
    ON transactions FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND is_active = TRUE
        )
    );

CREATE POLICY "Manage transactions"
    ON transactions FOR ALL
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'member') AND is_active = TRUE
        )
    );

-- Budgets: Similar access pattern
CREATE POLICY "View budgets"
    ON budgets FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND is_active = TRUE
        )
    );

CREATE POLICY "Manage budgets"
    ON budgets FOR ALL
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'member') AND is_active = TRUE
        )
    );

-- Budget Categories
CREATE POLICY "View budget categories"
    ON budget_categories FOR SELECT
    USING (
        budget_id IN (
            SELECT id FROM budgets WHERE organization_id IN (
                SELECT organization_id FROM organization_members
                WHERE user_id = auth.uid() AND is_active = TRUE
            )
        )
    );

CREATE POLICY "Manage budget categories"
    ON budget_categories FOR ALL
    USING (
        budget_id IN (
            SELECT id FROM budgets WHERE organization_id IN (
                SELECT organization_id FROM organization_members
                WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'member') AND is_active = TRUE
            )
        )
    );

-- Recurring Templates
CREATE POLICY "View recurring templates"
    ON recurring_templates FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND is_active = TRUE
        )
    );

CREATE POLICY "Manage recurring templates"
    ON recurring_templates FOR ALL
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'member') AND is_active = TRUE
        )
    );

-- Analytics Cache: Read-only for org members
CREATE POLICY "View analytics"
    ON analytics_cache FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND is_active = TRUE
        )
    );

-- Activity Logs: Read-only for org members
CREATE POLICY "View activity logs"
    ON activity_logs FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM organization_members
            WHERE user_id = auth.uid() AND is_active = TRUE
        )
    );

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_org_members_updated_at BEFORE UPDATE ON organization_members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budget_categories_updated_at BEFORE UPDATE ON budget_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recurring_templates_updated_at BEFORE UPDATE ON recurring_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update account balance on transaction
CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.type = 'income' THEN
            UPDATE accounts SET balance = balance + NEW.amount WHERE id = NEW.account_id;
        ELSIF NEW.type = 'expense' THEN
            UPDATE accounts SET balance = balance - NEW.amount WHERE id = NEW.account_id;
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Reverse old transaction
        IF OLD.type = 'income' THEN
            UPDATE accounts SET balance = balance - OLD.amount WHERE id = OLD.account_id;
        ELSIF OLD.type = 'expense' THEN
            UPDATE accounts SET balance = balance + OLD.amount WHERE id = OLD.account_id;
        END IF;
        -- Apply new transaction
        IF NEW.type = 'income' THEN
            UPDATE accounts SET balance = balance + NEW.amount WHERE id = NEW.account_id;
        ELSIF NEW.type = 'expense' THEN
            UPDATE accounts SET balance = balance - NEW.amount WHERE id = NEW.account_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.type = 'income' THEN
            UPDATE accounts SET balance = balance - OLD.amount WHERE id = OLD.account_id;
        ELSIF OLD.type = 'expense' THEN
            UPDATE accounts SET balance = balance + OLD.amount WHERE id = OLD.account_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_account_balance_trigger
    AFTER INSERT OR UPDATE OR DELETE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_account_balance();

-- Update budget spent amount
CREATE OR REPLACE FUNCTION update_budget_spent()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        UPDATE budgets b
        SET spent_amount = (
            SELECT COALESCE(SUM(t.amount), 0)
            FROM transactions t
            WHERE t.organization_id = b.organization_id
            AND t.type = 'expense'
            AND t.transaction_date BETWEEN b.start_date AND b.end_date
            AND t.status = 'completed'
        )
        WHERE id IN (
            SELECT budget_id FROM budget_categories WHERE category_id = NEW.category_id
        );
        
        UPDATE budget_categories bc
        SET spent_amount = (
            SELECT COALESCE(SUM(t.amount), 0)
            FROM transactions t
            WHERE t.category_id = bc.category_id
            AND t.type = 'expense'
            AND t.status = 'completed'
            AND t.transaction_date BETWEEN 
                (SELECT start_date FROM budgets WHERE id = bc.budget_id) AND
                (SELECT end_date FROM budgets WHERE id = bc.budget_id)
        )
        WHERE category_id = NEW.category_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_budget_spent_trigger
    AFTER INSERT OR UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_budget_spent();

-- ============================================
-- INITIAL DATA SEEDING
-- ============================================

-- Default expense categories
INSERT INTO categories (organization_id, name, type, color, icon, is_system) 
SELECT 
    o.id,
    unnest(ARRAY['Food & Dining', 'Transportation', 'Shopping', 'Entertainment', 'Bills & Utilities', 'Healthcare', 'Education', 'Personal Care', 'Travel', 'Other']),
    'expense',
    unnest(ARRAY['#EF4444', '#F59E0B', '#10B981', '#3B82F6', '#6366F1', '#8B5CF6', '#EC4899', '#14B8A6', '#F97316', '#6B7280']),
    unnest(ARRAY['utensils', 'car', 'shopping-bag', 'film', 'home', 'heart', 'book', 'user', 'plane', 'more-horizontal']),
    true
FROM organizations o
ON CONFLICT DO NOTHING;

-- Default income categories
INSERT INTO categories (organization_id, name, type, color, icon, is_system)
SELECT 
    o.id,
    unnest(ARRAY['Salary', 'Business Income', 'Investments', 'Freelancing', 'Rental Income', 'Other Income']),
    'income',
    unnest(ARRAY['#10B981', '#059669', '#14B8A6', '#0891B2', '#0284C7', '#6B7280']),
    unnest(ARRAY['briefcase', 'trending-up', 'bar-chart', 'code', 'home', 'dollar-sign']),
    true
FROM organizations o
ON CONFLICT DO NOTHING;
