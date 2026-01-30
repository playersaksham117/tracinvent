-- ============================================
-- BillEase POS Database - Initial Schema
-- Database: billease_pos
-- Description: Point of Sale system with products, sales, and inventory
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- TENANTS TABLE (Multi-tenancy support)
-- ============================================
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- References main DB users
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tenants_user_id ON tenants(user_id);
CREATE INDEX idx_tenants_slug ON tenants(slug);

-- ============================================
-- PRODUCTS TABLE
-- ============================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    sku VARCHAR(100),
    barcode VARCHAR(100),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    brand VARCHAR(100),
    unit VARCHAR(50) DEFAULT 'pcs',
    cost_price DECIMAL(10,2) DEFAULT 0,
    selling_price DECIMAL(10,2) NOT NULL,
    tax_rate DECIMAL(5,2) DEFAULT 0,
    stock_quantity DECIMAL(10,2) DEFAULT 0,
    reorder_level DECIMAL(10,2) DEFAULT 0,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_taxable BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, sku)
);

CREATE INDEX idx_products_tenant_id ON products(tenant_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_is_active ON products(is_active);

-- ============================================
-- SALES TABLE
-- ============================================
CREATE TABLE sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    sale_number VARCHAR(50) UNIQUE NOT NULL,
    customer_name VARCHAR(255),
    customer_phone VARCHAR(50),
    customer_email VARCHAR(255),
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL DEFAULT 0,
    change_amount DECIMAL(10,2) DEFAULT 0,
    payment_method VARCHAR(50) DEFAULT 'cash' CHECK (payment_method IN ('cash', 'card', 'mobile', 'other')),
    payment_status VARCHAR(50) DEFAULT 'paid' CHECK (payment_status IN ('paid', 'partial', 'pending', 'refunded')),
    status VARCHAR(50) DEFAULT 'completed' CHECK (status IN ('draft', 'completed', 'cancelled', 'refunded')),
    notes TEXT,
    cashier_id UUID, -- References main DB users
    shift_id UUID,
    metadata JSONB DEFAULT '{}',
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sales_tenant_id ON sales(tenant_id);
CREATE INDEX idx_sales_number ON sales(sale_number);
CREATE INDEX idx_sales_customer_phone ON sales(customer_phone);
CREATE INDEX idx_sales_payment_status ON sales(payment_status);
CREATE INDEX idx_sales_status ON sales(status);
CREATE INDEX idx_sales_completed_at ON sales(completed_at DESC);
CREATE INDEX idx_sales_cashier_id ON sales(cashier_id);
CREATE INDEX idx_sales_shift_id ON sales(shift_id);

-- ============================================
-- SALE ITEMS TABLE
-- ============================================
CREATE TABLE sale_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    product_name VARCHAR(255) NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    tax_rate DECIMAL(5,2) DEFAULT 0,
    discount DECIMAL(10,2) DEFAULT 0,
    subtotal DECIMAL(10,2) NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sale_items_tenant_id ON sale_items(tenant_id);
CREATE INDEX idx_sale_items_sale_id ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product_id ON sale_items(product_id);

-- ============================================
-- SHIFTS TABLE (Cashier shifts)
-- ============================================
CREATE TABLE shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    shift_number VARCHAR(50) UNIQUE NOT NULL,
    cashier_id UUID NOT NULL, -- References main DB users
    opening_balance DECIMAL(10,2) NOT NULL DEFAULT 0,
    closing_balance DECIMAL(10,2),
    expected_balance DECIMAL(10,2),
    difference DECIMAL(10,2),
    total_sales DECIMAL(10,2) DEFAULT 0,
    total_transactions INTEGER DEFAULT 0,
    status VARCHAR(50) DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    notes TEXT,
    opened_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_shifts_tenant_id ON shifts(tenant_id);
CREATE INDEX idx_shifts_cashier_id ON shifts(cashier_id);
CREATE INDEX idx_shifts_status ON shifts(status);
CREATE INDEX idx_shifts_opened_at ON shifts(opened_at DESC);

-- ============================================
-- RECEIPTS TABLE
-- ============================================
CREATE TABLE receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    receipt_number VARCHAR(50) UNIQUE NOT NULL,
    receipt_data JSONB NOT NULL,
    print_count INTEGER DEFAULT 0,
    last_printed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_receipts_tenant_id ON receipts(tenant_id);
CREATE INDEX idx_receipts_sale_id ON receipts(sale_id);

-- ============================================
-- PAYMENT TRANSACTIONS TABLE
-- ============================================
CREATE TABLE payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    sale_id UUID REFERENCES sales(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    reference_number VARCHAR(100),
    status VARCHAR(50) DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payment_transactions_tenant_id ON payment_transactions(tenant_id);
CREATE INDEX idx_payment_transactions_sale_id ON payment_transactions(sale_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);

-- ============================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES (Multi-tenant isolation)
-- ============================================

-- Tenants policies
CREATE POLICY "Users can view their own tenants"
    ON tenants FOR SELECT
    USING (auth.uid()::text::uuid = user_id);

CREATE POLICY "Users can insert their own tenants"
    ON tenants FOR INSERT
    WITH CHECK (auth.uid()::text::uuid = user_id);

CREATE POLICY "Users can update their own tenants"
    ON tenants FOR UPDATE
    USING (auth.uid()::text::uuid = user_id);

-- Products policies
CREATE POLICY "Tenant members can view products"
    ON products FOR SELECT
    USING (
        tenant_id IN (
            SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid
        )
    );

CREATE POLICY "Tenant members can insert products"
    ON products FOR INSERT
    WITH CHECK (
        tenant_id IN (
            SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid
        )
    );

CREATE POLICY "Tenant members can update products"
    ON products FOR UPDATE
    USING (
        tenant_id IN (
            SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid
        )
    );

CREATE POLICY "Tenant members can delete products"
    ON products FOR DELETE
    USING (
        tenant_id IN (
            SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid
        )
    );

-- Sales policies (similar pattern)
CREATE POLICY "Tenant members can view sales"
    ON sales FOR SELECT
    USING (
        tenant_id IN (
            SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid
        )
    );

CREATE POLICY "Tenant members can insert sales"
    ON sales FOR INSERT
    WITH CHECK (
        tenant_id IN (
            SELECT id FROM tenants WHERE user_id = auth.uid()::text::uuid
        )
    );

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Update updated_at timestamp
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sales_updated_at BEFORE UPDATE ON sales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to generate sale number
CREATE OR REPLACE FUNCTION generate_sale_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.sale_number IS NULL THEN
        NEW.sale_number := 'SALE-' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDD') || '-' || LPAD(nextval('sale_number_seq')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE sale_number_seq;

CREATE TRIGGER generate_sale_number_trigger
    BEFORE INSERT ON sales
    FOR EACH ROW
    EXECUTE FUNCTION generate_sale_number();

-- Function to update product stock after sale
CREATE OR REPLACE FUNCTION update_product_stock()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE products
        SET stock_quantity = stock_quantity - NEW.quantity
        WHERE id = NEW.product_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_stock_on_sale
    AFTER INSERT ON sale_items
    FOR EACH ROW
    EXECUTE FUNCTION update_product_stock();

-- Function to calculate sale totals
CREATE OR REPLACE FUNCTION calculate_sale_totals()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE sales
    SET 
        subtotal = (SELECT COALESCE(SUM(subtotal), 0) FROM sale_items WHERE sale_id = NEW.sale_id),
        tax_amount = (SELECT COALESCE(SUM((subtotal * tax_rate / 100)), 0) FROM sale_items WHERE sale_id = NEW.sale_id),
        total_amount = (SELECT COALESCE(SUM(total), 0) FROM sale_items WHERE sale_id = NEW.sale_id)
    WHERE id = NEW.sale_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_totals_on_item_change
    AFTER INSERT OR UPDATE ON sale_items
    FOR EACH ROW
    EXECUTE FUNCTION calculate_sale_totals();

-- ============================================
-- VIEWS
-- ============================================

-- Daily sales summary
CREATE OR REPLACE VIEW daily_sales_summary AS
SELECT
    tenant_id,
    DATE(completed_at) as sale_date,
    COUNT(*) as transaction_count,
    SUM(total_amount) as total_sales,
    SUM(tax_amount) as total_tax,
    AVG(total_amount) as average_sale
FROM sales
WHERE status = 'completed'
GROUP BY tenant_id, DATE(completed_at)
ORDER BY sale_date DESC;

-- Top selling products
CREATE OR REPLACE VIEW top_selling_products AS
SELECT
    p.tenant_id,
    p.id as product_id,
    p.name,
    p.category,
    SUM(si.quantity) as total_quantity_sold,
    SUM(si.total) as total_revenue,
    COUNT(DISTINCT si.sale_id) as number_of_sales
FROM products p
JOIN sale_items si ON p.id = si.product_id
JOIN sales s ON si.sale_id = s.id
WHERE s.status = 'completed'
GROUP BY p.tenant_id, p.id, p.name, p.category
ORDER BY total_revenue DESC;

-- Low stock alert
CREATE OR REPLACE VIEW low_stock_products AS
SELECT
    tenant_id,
    id,
    name,
    sku,
    stock_quantity,
    reorder_level,
    (reorder_level - stock_quantity) as shortage
FROM products
WHERE stock_quantity <= reorder_level
AND is_active = TRUE
ORDER BY shortage DESC;

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE tenants IS 'Multi-tenant isolation for POS data';
COMMENT ON TABLE products IS 'Product catalog for POS system';
COMMENT ON TABLE sales IS 'Sales transactions';
COMMENT ON TABLE sale_items IS 'Line items for each sale';
COMMENT ON TABLE shifts IS 'Cashier shifts and cash management';
COMMENT ON TABLE receipts IS 'Receipt data for printing';
COMMENT ON TABLE payment_transactions IS 'Payment transaction details';

-- ============================================
-- END OF MIGRATION
-- ============================================
