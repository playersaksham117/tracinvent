-- ============================================
-- BillEase Inventory Database - Initial Schema
-- Database: billease_inventory
-- Description: Inventory management with stock tracking and movements
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
-- LOCATIONS TABLE (Warehouses, Stores, etc.)
-- ============================================
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    location_code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    location_type VARCHAR(50) DEFAULT 'warehouse' CHECK (location_type IN ('warehouse', 'store', 'transit', 'supplier', 'customer')),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    manager VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, location_code)
);

CREATE INDEX idx_locations_tenant_id ON locations(tenant_id);
CREATE INDEX idx_locations_type ON locations(location_type);

-- ============================================
-- PRODUCTS TABLE
-- ============================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    sku VARCHAR(100) NOT NULL,
    barcode VARCHAR(100),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    brand VARCHAR(100),
    unit_of_measure VARCHAR(50) DEFAULT 'pcs',
    weight DECIMAL(10,2),
    weight_unit VARCHAR(20),
    dimensions VARCHAR(100),
    cost_price DECIMAL(10,2) DEFAULT 0,
    selling_price DECIMAL(10,2) DEFAULT 0,
    min_stock_level DECIMAL(10,2) DEFAULT 0,
    max_stock_level DECIMAL(10,2),
    reorder_point DECIMAL(10,2) DEFAULT 0,
    reorder_quantity DECIMAL(10,2) DEFAULT 0,
    lead_time_days INTEGER DEFAULT 0,
    is_tracked BOOLEAN DEFAULT TRUE,
    is_serialized BOOLEAN DEFAULT FALSE,
    is_batch_tracked BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    image_url TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, sku)
);

CREATE INDEX idx_products_tenant_id ON products(tenant_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_category ON products(category);

-- ============================================
-- INVENTORY TABLE (Current Stock Levels)
-- ============================================
CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    quantity_on_hand DECIMAL(10,2) DEFAULT 0,
    quantity_reserved DECIMAL(10,2) DEFAULT 0,
    quantity_available DECIMAL(10,2) DEFAULT 0,
    quantity_on_order DECIMAL(10,2) DEFAULT 0,
    average_cost DECIMAL(10,2) DEFAULT 0,
    total_value DECIMAL(15,2) DEFAULT 0,
    last_counted_at TIMESTAMP WITH TIME ZONE,
    last_movement_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, product_id, location_id)
);

CREATE INDEX idx_inventory_tenant_id ON inventory(tenant_id);
CREATE INDEX idx_inventory_product_id ON inventory(product_id);
CREATE INDEX idx_inventory_location_id ON inventory(location_id);
CREATE INDEX idx_inventory_available ON inventory(quantity_available);

-- ============================================
-- STOCK MOVEMENTS TABLE
-- ============================================
CREATE TABLE stock_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL,
    movement_number VARCHAR(50) UNIQUE NOT NULL,
    movement_date DATE NOT NULL,
    movement_type VARCHAR(50) NOT NULL CHECK (movement_type IN (
        'purchase', 'sale', 'return', 'adjustment', 'transfer',
        'production', 'damage', 'loss', 'found', 'initial'
    )),
    product_id UUID NOT NULL REFERENCES products(id),
    from_location_id UUID REFERENCES locations(id),
    to_location_id UUID REFERENCES locations(id),
    quantity DECIMAL(10,2) NOT NULL,
    unit_cost DECIMAL(10,2) DEFAULT 0,
    total_cost DECIMAL(15,2) DEFAULT 0,
    reference VARCHAR(100),
    notes TEXT,
    created_by UUID NOT NULL, -- References main DB users
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sm_tenant_id ON stock_movements(tenant_id);
CREATE INDEX idx_sm_transaction_id ON stock_movements(transaction_id);
CREATE INDEX idx_sm_movement_number ON stock_movements(movement_number);
CREATE INDEX idx_sm_movement_date ON stock_movements(movement_date DESC);
CREATE INDEX idx_sm_movement_type ON stock_movements(movement_type);
CREATE INDEX idx_sm_product_id ON stock_movements(product_id);
CREATE INDEX idx_sm_from_location ON stock_movements(from_location_id);
CREATE INDEX idx_sm_to_location ON stock_movements(to_location_id);

-- ============================================
-- TRANSACTIONS TABLE (Purchase Orders, Sales, etc.)
-- ============================================
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    transaction_number VARCHAR(50) UNIQUE NOT NULL,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN (
        'purchase_order', 'sales_order', 'stock_transfer', 'stock_adjustment'
    )),
    transaction_date DATE NOT NULL,
    reference VARCHAR(100),
    supplier_id UUID, -- Could reference CRM supplier
    customer_id UUID, -- Could reference CRM customer
    from_location_id UUID REFERENCES locations(id),
    to_location_id UUID REFERENCES locations(id),
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN (
        'draft', 'submitted', 'approved', 'in_progress', 'completed', 'cancelled'
    )),
    total_amount DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    created_by UUID NOT NULL,
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transactions_tenant_id ON transactions(tenant_id);
CREATE INDEX idx_transactions_number ON transactions(transaction_number);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);
CREATE INDEX idx_transactions_date ON transactions(transaction_date DESC);
CREATE INDEX idx_transactions_status ON transactions(status);

-- ============================================
-- TRANSACTION ITEMS TABLE
-- ============================================
CREATE TABLE transaction_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) DEFAULT 0,
    total_price DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ti_tenant_id ON transaction_items(tenant_id);
CREATE INDEX idx_ti_transaction_id ON transaction_items(transaction_id);
CREATE INDEX idx_ti_product_id ON transaction_items(product_id);

-- ============================================
-- SERIAL NUMBERS TABLE
-- ============================================
CREATE TABLE serial_numbers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    serial_number VARCHAR(100) NOT NULL,
    location_id UUID REFERENCES locations(id),
    status VARCHAR(50) DEFAULT 'available' CHECK (status IN ('available', 'sold', 'damaged', 'returned')),
    purchase_date DATE,
    sale_date DATE,
    warranty_until DATE,
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, serial_number)
);

CREATE INDEX idx_sn_tenant_id ON serial_numbers(tenant_id);
CREATE INDEX idx_sn_product_id ON serial_numbers(product_id);
CREATE INDEX idx_sn_serial_number ON serial_numbers(serial_number);
CREATE INDEX idx_sn_location_id ON serial_numbers(location_id);
CREATE INDEX idx_sn_status ON serial_numbers(status);

-- ============================================
-- BATCH TRACKING TABLE
-- ============================================
CREATE TABLE batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    batch_number VARCHAR(100) NOT NULL,
    location_id UUID REFERENCES locations(id),
    quantity DECIMAL(10,2) NOT NULL,
    manufacturing_date DATE,
    expiry_date DATE,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'expired', 'recalled', 'sold')),
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, batch_number)
);

CREATE INDEX idx_batches_tenant_id ON batches(tenant_id);
CREATE INDEX idx_batches_product_id ON batches(product_id);
CREATE INDEX idx_batches_batch_number ON batches(batch_number);
CREATE INDEX idx_batches_location_id ON batches(location_id);
CREATE INDEX idx_batches_expiry_date ON batches(expiry_date);

-- ============================================
-- STOCK COUNTS TABLE (Physical Inventory)
-- ============================================
CREATE TABLE stock_counts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    count_number VARCHAR(50) UNIQUE NOT NULL,
    count_date DATE NOT NULL,
    location_id UUID NOT NULL REFERENCES locations(id),
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    counted_by UUID NOT NULL,
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sc_tenant_id ON stock_counts(tenant_id);
CREATE INDEX idx_sc_count_number ON stock_counts(count_number);
CREATE INDEX idx_sc_location_id ON stock_counts(location_id);
CREATE INDEX idx_sc_status ON stock_counts(status);

-- ============================================
-- STOCK COUNT ITEMS TABLE
-- ============================================
CREATE TABLE stock_count_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    stock_count_id UUID NOT NULL REFERENCES stock_counts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    system_quantity DECIMAL(10,2) DEFAULT 0,
    counted_quantity DECIMAL(10,2),
    variance DECIMAL(10,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sci_tenant_id ON stock_count_items(tenant_id);
CREATE INDEX idx_sci_stock_count_id ON stock_count_items(stock_count_id);
CREATE INDEX idx_sci_product_id ON stock_count_items(product_id);

-- ============================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE serial_numbers ENABLE ROW LEVEL SECURITY;
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_counts ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_count_items ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================

CREATE POLICY "Tenant members can view inventory"
    ON inventory FOR SELECT
    USING (
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

CREATE TRIGGER update_locations_updated_at BEFORE UPDATE ON locations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update inventory on stock movement
CREATE OR REPLACE FUNCTION update_inventory_on_movement()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' THEN
        -- Update from location (decrease)
        IF NEW.from_location_id IS NOT NULL THEN
            UPDATE inventory
            SET 
                quantity_on_hand = quantity_on_hand - NEW.quantity,
                quantity_available = quantity_available - NEW.quantity,
                last_movement_at = CURRENT_TIMESTAMP
            WHERE product_id = NEW.product_id
            AND location_id = NEW.from_location_id;
        END IF;
        
        -- Update to location (increase)
        IF NEW.to_location_id IS NOT NULL THEN
            INSERT INTO inventory (tenant_id, product_id, location_id, quantity_on_hand, quantity_available)
            VALUES (NEW.tenant_id, NEW.product_id, NEW.to_location_id, NEW.quantity, NEW.quantity)
            ON CONFLICT (tenant_id, product_id, location_id)
            DO UPDATE SET
                quantity_on_hand = inventory.quantity_on_hand + NEW.quantity,
                quantity_available = inventory.quantity_available + NEW.quantity,
                last_movement_at = CURRENT_TIMESTAMP;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_inventory_trigger
    AFTER INSERT OR UPDATE ON stock_movements
    FOR EACH ROW
    EXECUTE FUNCTION update_inventory_on_movement();

-- ============================================
-- VIEWS
-- ============================================

-- Current Stock Levels
CREATE OR REPLACE VIEW current_stock_levels AS
SELECT
    i.tenant_id,
    p.sku,
    p.name as product_name,
    l.name as location_name,
    i.quantity_on_hand,
    i.quantity_available,
    i.quantity_reserved,
    p.reorder_point,
    CASE 
        WHEN i.quantity_available <= p.reorder_point THEN 'Low Stock'
        WHEN i.quantity_available = 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END as stock_status
FROM inventory i
JOIN products p ON i.product_id = p.id
JOIN locations l ON i.location_id = l.id;

-- Stock Movement History
CREATE OR REPLACE VIEW stock_movement_history AS
SELECT
    sm.tenant_id,
    sm.movement_date,
    sm.movement_type,
    p.sku,
    p.name as product_name,
    lf.name as from_location,
    lt.name as to_location,
    sm.quantity,
    sm.unit_cost,
    sm.total_cost
FROM stock_movements sm
JOIN products p ON sm.product_id = p.id
LEFT JOIN locations lf ON sm.from_location_id = lf.id
LEFT JOIN locations lt ON sm.to_location_id = lt.id
ORDER BY sm.movement_date DESC;

-- ============================================
-- END OF MIGRATION
-- ============================================
