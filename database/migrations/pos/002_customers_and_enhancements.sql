-- ============================================
-- BillEase POS Database - Customer Management & Enhancements
-- Migration: 002
-- Description: Add customer management and enhanced features
-- ============================================

-- ============================================
-- CUSTOMERS TABLE
-- ============================================
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    customer_code VARCHAR(50) UNIQUE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'US',
    tax_id VARCHAR(50),
    credit_limit DECIMAL(10,2) DEFAULT 0,
    current_balance DECIMAL(10,2) DEFAULT 0,
    total_purchases DECIMAL(10,2) DEFAULT 0,
    total_transactions INTEGER DEFAULT 0,
    loyalty_points INTEGER DEFAULT 0,
    customer_group VARCHAR(50) DEFAULT 'regular', -- regular, vip, wholesale
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, customer_code)
);

CREATE INDEX idx_customers_tenant_id ON customers(tenant_id);
CREATE INDEX idx_customers_code ON customers(customer_code);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_group ON customers(customer_group);
CREATE INDEX idx_customers_is_active ON customers(is_active);

-- ============================================
-- CUSTOMER PURCHASE HISTORY (Enhanced from sales)
-- ============================================
-- Add customer_id to sales table
ALTER TABLE sales ADD COLUMN customer_id UUID REFERENCES customers(id) ON DELETE SET NULL;
CREATE INDEX idx_sales_customer_id ON sales(customer_id);

-- ============================================
-- DISCOUNTS TABLE
-- ============================================
CREATE TABLE discounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value DECIMAL(10,2) NOT NULL,
    min_purchase_amount DECIMAL(10,2) DEFAULT 0,
    max_discount_amount DECIMAL(10,2),
    applicable_to VARCHAR(20) DEFAULT 'all' CHECK (applicable_to IN ('all', 'products', 'categories')),
    applicable_ids JSONB DEFAULT '[]',
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP WITH TIME ZONE,
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, code)
);

CREATE INDEX idx_discounts_tenant_id ON discounts(tenant_id);
CREATE INDEX idx_discounts_code ON discounts(code);
CREATE INDEX idx_discounts_is_active ON discounts(is_active);

-- ============================================
-- PAYMENT METHODS TABLE
-- ============================================
CREATE TABLE payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL, -- cash, card, upi, wallet, bank_transfer
    icon VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    requires_reference BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, code)
);

CREATE INDEX idx_payment_methods_tenant_id ON payment_methods(tenant_id);
CREATE INDEX idx_payment_methods_code ON payment_methods(code);

-- Insert default payment methods (will be inserted per tenant)
-- Example: INSERT INTO payment_methods (tenant_id, name, code, icon) VALUES 
-- (tenant_id, 'Cash', 'cash', '💵'),
-- (tenant_id, 'Credit/Debit Card', 'card', '💳'),
-- (tenant_id, 'UPI', 'upi', '📱'),
-- (tenant_id, 'Digital Wallet', 'wallet', '👛');

-- ============================================
-- CURRENCIES TABLE
-- ============================================
CREATE TABLE currencies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    code VARCHAR(3) NOT NULL, -- USD, EUR, INR, etc.
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    exchange_rate DECIMAL(10,4) DEFAULT 1.0000,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, code)
);

CREATE INDEX idx_currencies_tenant_id ON currencies(tenant_id);
CREATE INDEX idx_currencies_code ON currencies(code);

-- ============================================
-- TAX RATES TABLE
-- ============================================
CREATE TABLE tax_rates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    rate DECIMAL(5,2) NOT NULL,
    description TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tax_rates_tenant_id ON tax_rates(tenant_id);

-- ============================================
-- STOCK ADJUSTMENTS TABLE
-- ============================================
CREATE TABLE stock_adjustments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    adjustment_type VARCHAR(50) NOT NULL CHECK (adjustment_type IN ('add', 'remove', 'set', 'sale', 'return', 'damage', 'audit')),
    quantity_before DECIMAL(10,2) NOT NULL,
    quantity_change DECIMAL(10,2) NOT NULL,
    quantity_after DECIMAL(10,2) NOT NULL,
    reason TEXT,
    reference_id UUID, -- Can reference sale_id or other transaction
    adjusted_by UUID, -- References main DB users
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_stock_adjustments_tenant_id ON stock_adjustments(tenant_id);
CREATE INDEX idx_stock_adjustments_product_id ON stock_adjustments(product_id);
CREATE INDEX idx_stock_adjustments_type ON stock_adjustments(adjustment_type);
CREATE INDEX idx_stock_adjustments_created_at ON stock_adjustments(created_at DESC);

-- ============================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE currencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_adjustments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Customers policies
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

CREATE POLICY "Tenant members can update customers"
    ON customers FOR UPDATE
    USING (
        tenant_id IN (
            SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid
        )
    );

CREATE POLICY "Tenant members can delete customers"
    ON customers FOR DELETE
    USING (
        tenant_id IN (
            SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid
        )
    );

-- Similar policies for other tables
CREATE POLICY "Tenant members can view discounts" ON discounts FOR SELECT
    USING (tenant_id IN (SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid));

CREATE POLICY "Tenant members can manage discounts" ON discounts FOR ALL
    USING (tenant_id IN (SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid));

CREATE POLICY "Tenant members can view payment_methods" ON payment_methods FOR SELECT
    USING (tenant_id IN (SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid));

CREATE POLICY "Tenant members can view currencies" ON currencies FOR SELECT
    USING (tenant_id IN (SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid));

CREATE POLICY "Tenant members can view tax_rates" ON tax_rates FOR SELECT
    USING (tenant_id IN (SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid));

CREATE POLICY "Tenant members can view stock_adjustments" ON stock_adjustments FOR SELECT
    USING (tenant_id IN (SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid));

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_discounts_updated_at BEFORE UPDATE ON discounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_currencies_updated_at BEFORE UPDATE ON currencies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tax_rates_updated_at BEFORE UPDATE ON tax_rates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to generate customer code
CREATE OR REPLACE FUNCTION generate_customer_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.customer_code IS NULL THEN
        NEW.customer_code := 'CUST-' || LPAD(nextval('customer_code_seq')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE customer_code_seq;

CREATE TRIGGER generate_customer_code_trigger
    BEFORE INSERT ON customers
    FOR EACH ROW
    EXECUTE FUNCTION generate_customer_code();

-- Function to update customer stats after sale
CREATE OR REPLACE FUNCTION update_customer_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.customer_id IS NOT NULL AND NEW.status = 'completed' THEN
        UPDATE customers
        SET 
            total_purchases = total_purchases + NEW.total_amount,
            total_transactions = total_transactions + 1,
            current_balance = current_balance + NEW.total_amount - NEW.amount_paid,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customer_stats_on_sale
    AFTER INSERT ON sales
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_stats();

-- Function to log stock adjustments
CREATE OR REPLACE FUNCTION log_stock_adjustment()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.stock_quantity != NEW.stock_quantity THEN
        INSERT INTO stock_adjustments (
            tenant_id,
            product_id,
            adjustment_type,
            quantity_before,
            quantity_change,
            quantity_after,
            reason
        ) VALUES (
            NEW.tenant_id,
            NEW.id,
            CASE 
                WHEN NEW.stock_quantity > OLD.stock_quantity THEN 'add'
                ELSE 'remove'
            END,
            OLD.stock_quantity,
            NEW.stock_quantity - OLD.stock_quantity,
            NEW.stock_quantity,
            'Manual adjustment'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_product_stock_change
    AFTER UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION log_stock_adjustment();

-- ============================================
-- VIEWS
-- ============================================

-- Customer purchase history
CREATE OR REPLACE VIEW customer_purchase_history AS
SELECT
    c.id as customer_id,
    c.name as customer_name,
    c.phone,
    c.email,
    s.id as sale_id,
    s.sale_number,
    s.total_amount,
    s.payment_status,
    s.payment_method,
    s.completed_at,
    s.status
FROM customers c
LEFT JOIN sales s ON c.id = s.customer_id
WHERE s.status = 'completed'
ORDER BY s.completed_at DESC;

-- Top customers
CREATE OR REPLACE VIEW top_customers AS
SELECT
    c.id,
    c.customer_code,
    c.name,
    c.phone,
    c.email,
    c.total_purchases,
    c.total_transactions,
    c.loyalty_points,
    c.customer_group,
    AVG(s.total_amount) as average_purchase,
    MAX(s.completed_at) as last_purchase_date
FROM customers c
LEFT JOIN sales s ON c.id = s.customer_id AND s.status = 'completed'
GROUP BY c.id
ORDER BY c.total_purchases DESC;

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE customers IS 'Customer information and contact details';
COMMENT ON TABLE discounts IS 'Discount codes and promotional offers';
COMMENT ON TABLE payment_methods IS 'Available payment methods for the POS';
COMMENT ON TABLE currencies IS 'Multi-currency support';
COMMENT ON TABLE tax_rates IS 'Tax rate configurations';
COMMENT ON TABLE stock_adjustments IS 'Inventory adjustment history';

-- ============================================
-- END OF MIGRATION
-- ============================================
