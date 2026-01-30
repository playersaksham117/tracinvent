-- ============================================
-- BillEase CRM Database - Initial Schema
-- Database: billease_crm
-- Description: Customer Relationship Management with contacts and interactions
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- TENANTS TABLE
-- ============================================
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tenants_user_id ON tenants(user_id);

-- ============================================
-- CUSTOMERS TABLE
-- ============================================
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    customer_code VARCHAR(50) UNIQUE,
    name VARCHAR(255) NOT NULL,
    company VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    mobile VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    tax_number VARCHAR(100),
    credit_limit DECIMAL(10,2) DEFAULT 0,
    credit_balance DECIMAL(10,2) DEFAULT 0,
    payment_terms VARCHAR(50),
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'blocked')),
    customer_type VARCHAR(50) DEFAULT 'regular' CHECK (customer_type IN ('regular', 'vip', 'wholesale')),
    notes TEXT,
    tags JSONB DEFAULT '[]',
    custom_fields JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_tenant_id ON customers(tenant_id);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_status ON customers(status);
CREATE INDEX idx_customers_customer_type ON customers(customer_type);

-- ============================================
-- SUPPLIERS TABLE
-- ============================================
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    supplier_code VARCHAR(50) UNIQUE,
    name VARCHAR(255) NOT NULL,
    company VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    mobile VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    tax_number VARCHAR(100),
    payment_terms VARCHAR(50),
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'blocked')),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    notes TEXT,
    tags JSONB DEFAULT '[]',
    custom_fields JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_suppliers_tenant_id ON suppliers(tenant_id);
CREATE INDEX idx_suppliers_email ON suppliers(email);
CREATE INDEX idx_suppliers_status ON suppliers(status);

-- ============================================
-- LEADS TABLE
-- ============================================
CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    lead_code VARCHAR(50) UNIQUE,
    name VARCHAR(255) NOT NULL,
    company VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    mobile VARCHAR(50),
    source VARCHAR(100),
    status VARCHAR(50) DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'qualified', 'converted', 'lost')),
    stage VARCHAR(50) DEFAULT 'prospect',
    expected_value DECIMAL(10,2),
    probability INTEGER CHECK (probability >= 0 AND probability <= 100),
    expected_close_date DATE,
    assigned_to UUID, -- References main DB users
    converted_to_customer_id UUID REFERENCES customers(id),
    converted_at TIMESTAMP WITH TIME ZONE,
    lost_reason TEXT,
    notes TEXT,
    tags JSONB DEFAULT '[]',
    custom_fields JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_leads_tenant_id ON leads(tenant_id);
CREATE INDEX idx_leads_email ON leads(email);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_assigned_to ON leads(assigned_to);

-- ============================================
-- INTERACTIONS TABLE
-- ============================================
CREATE TABLE interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL CHECK (entity_type IN ('customer', 'supplier', 'lead')),
    entity_id UUID NOT NULL,
    interaction_type VARCHAR(50) NOT NULL CHECK (interaction_type IN ('call', 'email', 'meeting', 'note', 'task')),
    subject VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'cancelled')),
    priority VARCHAR(50) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    user_id UUID NOT NULL, -- References main DB users
    scheduled_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    outcome TEXT,
    attachments JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_interactions_tenant_id ON interactions(tenant_id);
CREATE INDEX idx_interactions_entity ON interactions(entity_type, entity_id);
CREATE INDEX idx_interactions_user_id ON interactions(user_id);
CREATE INDEX idx_interactions_type ON interactions(interaction_type);
CREATE INDEX idx_interactions_status ON interactions(status);
CREATE INDEX idx_interactions_scheduled_at ON interactions(scheduled_at);

-- ============================================
-- CONTACT PERSONS TABLE
-- ============================================
CREATE TABLE contact_persons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL CHECK (entity_type IN ('customer', 'supplier')),
    entity_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    title VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(50),
    mobile VARCHAR(50),
    is_primary BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_contact_persons_tenant_id ON contact_persons(tenant_id);
CREATE INDEX idx_contact_persons_entity ON contact_persons(entity_type, entity_id);

-- ============================================
-- DEALS TABLE (Sales Pipeline)
-- ============================================
CREATE TABLE deals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    deal_code VARCHAR(50) UNIQUE,
    title VARCHAR(255) NOT NULL,
    customer_id UUID REFERENCES customers(id),
    lead_id UUID REFERENCES leads(id),
    value DECIMAL(10,2) NOT NULL,
    stage VARCHAR(50) DEFAULT 'prospecting' CHECK (stage IN ('prospecting', 'qualification', 'proposal', 'negotiation', 'won', 'lost')),
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'won', 'lost')),
    probability INTEGER CHECK (probability >= 0 AND probability <= 100),
    expected_close_date DATE,
    actual_close_date DATE,
    assigned_to UUID, -- References main DB users
    lost_reason TEXT,
    description TEXT,
    notes TEXT,
    tags JSONB DEFAULT '[]',
    custom_fields JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_deals_tenant_id ON deals(tenant_id);
CREATE INDEX idx_deals_customer_id ON deals(customer_id);
CREATE INDEX idx_deals_lead_id ON deals(lead_id);
CREATE INDEX idx_deals_stage ON deals(stage);
CREATE INDEX idx_deals_status ON deals(status);
CREATE INDEX idx_deals_assigned_to ON deals(assigned_to);

-- ============================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE deals ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================

CREATE POLICY "Tenant members can view customers"
    ON customers FOR SELECT
    USING (
        tenant_id IN (
            SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid
        )
    );

CREATE POLICY "Tenant members can insert customers"
    ON customers FOR INSERT
    WITH CHECK (
        tenant_id IN (
            SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid
        )
    );

-- Similar policies for other tables...

-- ============================================
-- TRIGGERS
-- ============================================

CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_interactions_updated_at BEFORE UPDATE ON interactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deals_updated_at BEFORE UPDATE ON deals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VIEWS
-- ============================================

-- Customer summary
CREATE OR REPLACE VIEW customer_summary AS
SELECT
    c.tenant_id,
    c.id,
    c.name,
    c.email,
    c.phone,
    c.customer_type,
    COUNT(DISTINCT i.id) as interaction_count,
    MAX(i.created_at) as last_interaction_date,
    COUNT(DISTINCT d.id) as deal_count,
    COALESCE(SUM(CASE WHEN d.status = 'won' THEN d.value ELSE 0 END), 0) as total_won_value
FROM customers c
LEFT JOIN interactions i ON c.id = i.entity_id AND i.entity_type = 'customer'
LEFT JOIN deals d ON c.id = d.customer_id
GROUP BY c.tenant_id, c.id, c.name, c.email, c.phone, c.customer_type;

-- Sales pipeline
CREATE OR REPLACE VIEW sales_pipeline AS
SELECT
    tenant_id,
    stage,
    COUNT(*) as deal_count,
    SUM(value) as total_value,
    AVG(value) as average_value,
    AVG(probability) as average_probability
FROM deals
WHERE status = 'active'
GROUP BY tenant_id, stage
ORDER BY 
    CASE stage
        WHEN 'prospecting' THEN 1
        WHEN 'qualification' THEN 2
        WHEN 'proposal' THEN 3
        WHEN 'negotiation' THEN 4
    END;

-- ============================================
-- END OF MIGRATION
-- ============================================
