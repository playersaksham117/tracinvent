-- ============================================
-- Sample Data for BillEase POS Testing
-- ============================================

-- Note: Replace 'YOUR_TENANT_ID' with your actual tenant ID
-- Get your tenant_id by running: SELECT id FROM tenants WHERE user_id = auth.uid();

-- ============================================
-- SAMPLE PAYMENT METHODS
-- ============================================
INSERT INTO payment_methods (tenant_id, name, code, icon, is_active, requires_reference) VALUES
('YOUR_TENANT_ID', 'Cash', 'cash', '💵', true, false),
('YOUR_TENANT_ID', 'Credit/Debit Card', 'card', '💳', true, true),
('YOUR_TENANT_ID', 'UPI', 'upi', '📱', true, true),
('YOUR_TENANT_ID', 'Digital Wallet', 'wallet', '👛', true, true),
('YOUR_TENANT_ID', 'Bank Transfer', 'bank_transfer', '🏦', true, true);

-- ============================================
-- SAMPLE TAX RATES
-- ============================================
INSERT INTO tax_rates (tenant_id, name, rate, description, is_default, is_active) VALUES
('YOUR_TENANT_ID', 'GST 18%', 18.00, 'Standard GST Rate', true, true),
('YOUR_TENANT_ID', 'GST 12%', 12.00, 'Reduced GST Rate', false, true),
('YOUR_TENANT_ID', 'GST 5%', 5.00, 'Essential Goods GST', false, true),
('YOUR_TENANT_ID', 'No Tax', 0.00, 'Tax Exempt Items', false, true);

-- ============================================
-- SAMPLE PRODUCTS
-- ============================================
INSERT INTO products (tenant_id, sku, barcode, name, description, category, brand, selling_price, cost_price, tax_rate, stock_quantity, reorder_level, is_active) VALUES
-- Electronics
('YOUR_TENANT_ID', 'ELEC-001', '1234567890001', 'Wireless Mouse', 'Ergonomic wireless mouse with USB receiver', 'Electronics', 'TechPro', 29.99, 15.00, 18.0, 50, 10, true),
('YOUR_TENANT_ID', 'ELEC-002', '1234567890002', 'USB Keyboard', 'Full-size USB keyboard', 'Electronics', 'TechPro', 39.99, 20.00, 18.0, 30, 10, true),
('YOUR_TENANT_ID', 'ELEC-003', '1234567890003', 'HDMI Cable 2m', 'High-speed HDMI cable', 'Electronics', 'ConnectPlus', 12.99, 5.00, 18.0, 100, 20, true),
('YOUR_TENANT_ID', 'ELEC-004', '1234567890004', 'Webcam HD 1080p', 'Full HD webcam with microphone', 'Electronics', 'TechPro', 79.99, 40.00, 18.0, 25, 5, true),
('YOUR_TENANT_ID', 'ELEC-005', '1234567890005', 'USB-C Hub', '4-port USB-C hub adapter', 'Electronics', 'ConnectPlus', 34.99, 18.00, 18.0, 40, 10, true),

-- Office Supplies
('YOUR_TENANT_ID', 'OFF-001', '1234567890101', 'A4 Paper Ream', '500 sheets premium white paper', 'Office', 'PaperMax', 8.99, 4.50, 12.0, 200, 50, true),
('YOUR_TENANT_ID', 'OFF-002', '1234567890102', 'Blue Pen Pack (10)', 'Ball point pens pack of 10', 'Office', 'WritePro', 5.99, 2.50, 12.0, 150, 30, true),
('YOUR_TENANT_ID', 'OFF-003', '1234567890103', 'Sticky Notes 3x3', 'Assorted color sticky notes', 'Office', 'NoteMaster', 3.99, 1.50, 12.0, 100, 25, true),
('YOUR_TENANT_ID', 'OFF-004', '1234567890104', 'Stapler', 'Heavy-duty metal stapler', 'Office', 'OfficePro', 12.99, 6.00, 12.0, 50, 10, true),
('YOUR_TENANT_ID', 'OFF-005', '1234567890105', 'File Folder Pack', 'Letter size file folders, 25 pack', 'Office', 'OfficePro', 15.99, 8.00, 12.0, 60, 15, true),

-- Beverages
('YOUR_TENANT_ID', 'BEV-001', '1234567890201', 'Bottled Water 500ml', 'Pure drinking water', 'Beverages', 'AquaPure', 1.49, 0.50, 5.0, 500, 100, true),
('YOUR_TENANT_ID', 'BEV-002', '1234567890202', 'Coffee Beans 250g', 'Premium arabica coffee beans', 'Beverages', 'CafeMaster', 18.99, 10.00, 5.0, 80, 20, true),
('YOUR_TENANT_ID', 'BEV-003', '1234567890203', 'Green Tea Box', 'Organic green tea, 25 bags', 'Beverages', 'TeaTime', 9.99, 5.00, 5.0, 70, 15, true),
('YOUR_TENANT_ID', 'BEV-004', '1234567890204', 'Orange Juice 1L', 'Fresh squeezed orange juice', 'Beverages', 'FreshJuice', 5.99, 3.00, 5.0, 60, 20, true),
('YOUR_TENANT_ID', 'BEV-005', '1234567890205', 'Energy Drink', 'Sugar-free energy drink', 'Beverages', 'PowerUp', 2.99, 1.50, 5.0, 200, 50, true),

-- Snacks
('YOUR_TENANT_ID', 'SNK-001', '1234567890301', 'Potato Chips', 'Classic salted potato chips', 'Snacks', 'Crunchies', 3.49, 1.50, 12.0, 120, 30, true),
('YOUR_TENANT_ID', 'SNK-002', '1234567890302', 'Chocolate Bar', 'Milk chocolate bar 100g', 'Snacks', 'ChocoDelight', 2.99, 1.20, 12.0, 150, 40, true),
('YOUR_TENANT_ID', 'SNK-003', '1234567890303', 'Mixed Nuts 200g', 'Roasted and salted mixed nuts', 'Snacks', 'NuttyBites', 8.99, 4.50, 12.0, 80, 20, true),
('YOUR_TENANT_ID', 'SNK-004', '1234567890304', 'Protein Bar', 'High protein energy bar', 'Snacks', 'FitFuel', 3.99, 2.00, 12.0, 100, 25, true),
('YOUR_TENANT_ID', 'SNK-005', '1234567890305', 'Cookies Pack', 'Chocolate chip cookies 6-pack', 'Snacks', 'BakeMaster', 4.99, 2.50, 12.0, 90, 20, true);

-- ============================================
-- SAMPLE CUSTOMERS
-- ============================================
INSERT INTO customers (tenant_id, name, phone, email, address, city, state, postal_code, customer_group) VALUES
('YOUR_TENANT_ID', 'John Smith', '+1-555-0101', 'john.smith@email.com', '123 Main St', 'New York', 'NY', '10001', 'regular'),
('YOUR_TENANT_ID', 'Sarah Johnson', '+1-555-0102', 'sarah.j@email.com', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'vip'),
('YOUR_TENANT_ID', 'Mike Williams', '+1-555-0103', 'mike.w@email.com', '789 Pine Rd', 'Chicago', 'IL', '60601', 'regular'),
('YOUR_TENANT_ID', 'Emily Brown', '+1-555-0104', 'emily.brown@email.com', '321 Elm St', 'Houston', 'TX', '77001', 'vip'),
('YOUR_TENANT_ID', 'David Lee', '+1-555-0105', 'david.lee@email.com', '654 Maple Dr', 'Phoenix', 'AZ', '85001', 'wholesale'),
('YOUR_TENANT_ID', 'Lisa Davis', '+1-555-0106', 'lisa.davis@email.com', '987 Cedar Ln', 'Philadelphia', 'PA', '19101', 'regular'),
('YOUR_TENANT_ID', 'Robert Taylor', '+1-555-0107', 'rob.taylor@email.com', '147 Birch Way', 'San Antonio', 'TX', '78201', 'regular'),
('YOUR_TENANT_ID', 'Jennifer Wilson', '+1-555-0108', 'jen.wilson@email.com', '258 Walnut St', 'San Diego', 'CA', '92101', 'vip'),
('YOUR_TENANT_ID', 'James Anderson', '+1-555-0109', 'james.a@email.com', '369 Spruce Ave', 'Dallas', 'TX', '75201', 'wholesale'),
('YOUR_TENANT_ID', 'Maria Garcia', '+1-555-0110', 'maria.g@email.com', '741 Ash Blvd', 'San Jose', 'CA', '95101', 'regular');

-- ============================================
-- SAMPLE DISCOUNTS
-- ============================================
INSERT INTO discounts (tenant_id, code, name, description, discount_type, discount_value, min_purchase_amount, valid_from, valid_until, usage_limit, is_active) VALUES
('YOUR_TENANT_ID', 'SAVE10', '10% Off', 'Get 10% off your purchase', 'percentage', 10.00, 50.00, NOW(), NOW() + INTERVAL '365 days', 1000, true),
('YOUR_TENANT_ID', 'SAVE20', '20% Off VIP', 'Special 20% discount for VIP customers', 'percentage', 20.00, 100.00, NOW(), NOW() + INTERVAL '365 days', 500, true),
('YOUR_TENANT_ID', 'FIRST5', '$5 Off First Purchase', 'First-time customer discount', 'fixed', 5.00, 25.00, NOW(), NOW() + INTERVAL '365 days', NULL, true),
('YOUR_TENANT_ID', 'BULK15', '15% Bulk Discount', 'Save 15% on orders over $200', 'percentage', 15.00, 200.00, NOW(), NOW() + INTERVAL '365 days', NULL, true),
('YOUR_TENANT_ID', 'WELCOME', 'Welcome Discount', 'New customer welcome offer', 'fixed', 10.00, 0.00, NOW(), NOW() + INTERVAL '365 days', 2000, true);

-- ============================================
-- SAMPLE CURRENCY
-- ============================================
INSERT INTO currencies (tenant_id, code, name, symbol, exchange_rate, is_default, is_active) VALUES
('YOUR_TENANT_ID', 'USD', 'US Dollar', '$', 1.0000, true, true),
('YOUR_TENANT_ID', 'EUR', 'Euro', '€', 0.92, false, true),
('YOUR_TENANT_ID', 'GBP', 'British Pound', '£', 0.79, false, true),
('YOUR_TENANT_ID', 'INR', 'Indian Rupee', '₹', 83.00, false, true),
('YOUR_TENANT_ID', 'CAD', 'Canadian Dollar', 'C$', 1.35, false, true);

-- ============================================
-- USAGE INSTRUCTIONS
-- ============================================

-- 1. First, get your tenant_id:
--    SELECT id FROM tenants WHERE user_id = auth.uid();

-- 2. Replace 'YOUR_TENANT_ID' in this file with your actual tenant_id

-- 3. Run this SQL in your Supabase SQL Editor

-- 4. Verify data:
--    SELECT * FROM products;
--    SELECT * FROM customers;
--    SELECT * FROM payment_methods;
--    SELECT * FROM discounts;

-- 5. Start using the POS system!

-- ============================================
-- SAMPLE QUERIES
-- ============================================

-- Get all products with low stock:
-- SELECT * FROM products WHERE stock_quantity <= reorder_level;

-- Get top customers by purchase amount:
-- SELECT * FROM customers ORDER BY total_purchases DESC LIMIT 10;

-- Get all active discounts:
-- SELECT * FROM discounts WHERE is_active = true AND (valid_until IS NULL OR valid_until > NOW());

-- Get sales for today:
-- SELECT * FROM sales WHERE DATE(completed_at) = CURRENT_DATE;
