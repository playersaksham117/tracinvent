-- ============================================================================
-- GST Billing & Accounting System - SQLite Database Schema
-- Version: 1.0.0
-- Compliance: Indian GST Rules, Financial Year (April - March)
-- ============================================================================

-- Enable foreign key support
PRAGMA foreign_keys = ON;

-- ============================================================================
-- COMPANY PROFILE
-- ============================================================================
CREATE TABLE IF NOT EXISTS company_profile (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    company_name TEXT NOT NULL,
    legal_name TEXT NOT NULL,
    gstin TEXT UNIQUE,
    pan TEXT,
    cin TEXT,
    tan TEXT,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT NOT NULL,
    state_code TEXT NOT NULL,
    state_name TEXT NOT NULL,
    pincode TEXT NOT NULL,
    country TEXT DEFAULT 'India',
    phone TEXT,
    email TEXT,
    website TEXT,
    bank_name TEXT,
    bank_account_number TEXT,
    bank_ifsc TEXT,
    bank_branch TEXT,
    logo_path TEXT,
    signature_path TEXT,
    financial_year_start TEXT DEFAULT '04-01',
    invoice_prefix TEXT DEFAULT 'INV',
    invoice_start_number INTEGER DEFAULT 1,
    terms_and_conditions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STATE CODES (Indian GST State Codes)
-- ============================================================================
CREATE TABLE IF NOT EXISTS states (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT CHECK(type IN ('STATE', 'UT')) NOT NULL
);

-- Insert Indian State Codes
INSERT OR IGNORE INTO states (code, name, type) VALUES
('01', 'Jammu & Kashmir', 'UT'),
('02', 'Himachal Pradesh', 'STATE'),
('03', 'Punjab', 'STATE'),
('04', 'Chandigarh', 'UT'),
('05', 'Uttarakhand', 'STATE'),
('06', 'Haryana', 'STATE'),
('07', 'Delhi', 'UT'),
('08', 'Rajasthan', 'STATE'),
('09', 'Uttar Pradesh', 'STATE'),
('10', 'Bihar', 'STATE'),
('11', 'Sikkim', 'STATE'),
('12', 'Arunachal Pradesh', 'STATE'),
('13', 'Nagaland', 'STATE'),
('14', 'Manipur', 'STATE'),
('15', 'Mizoram', 'STATE'),
('16', 'Tripura', 'STATE'),
('17', 'Meghalaya', 'STATE'),
('18', 'Assam', 'STATE'),
('19', 'West Bengal', 'STATE'),
('20', 'Jharkhand', 'STATE'),
('21', 'Odisha', 'STATE'),
('22', 'Chhattisgarh', 'STATE'),
('23', 'Madhya Pradesh', 'STATE'),
('24', 'Gujarat', 'STATE'),
('26', 'Dadra & Nagar Haveli and Daman & Diu', 'UT'),
('27', 'Maharashtra', 'STATE'),
('28', 'Andhra Pradesh', 'STATE'),
('29', 'Karnataka', 'STATE'),
('30', 'Goa', 'STATE'),
('31', 'Lakshadweep', 'UT'),
('32', 'Kerala', 'STATE'),
('33', 'Tamil Nadu', 'STATE'),
('34', 'Puducherry', 'UT'),
('35', 'Andaman & Nicobar Islands', 'UT'),
('36', 'Telangana', 'STATE'),
('37', 'Andhra Pradesh (New)', 'STATE'),
('38', 'Ladakh', 'UT'),
('97', 'Other Territory', 'UT');

-- ============================================================================
-- PARTIES / FIRMS (Master Party Database)
-- ============================================================================
CREATE TABLE IF NOT EXISTS parties (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    party_type TEXT CHECK(party_type IN ('SUPPLIER', 'CUSTOMER', 'EMPLOYEE', 'BANK', 'OTHER')) NOT NULL,
    name TEXT NOT NULL,
    contact_person TEXT,
    contact_person_title TEXT,
    phone TEXT NOT NULL,
    email TEXT,
    website TEXT,
    
    -- GST Details
    gstin TEXT UNIQUE,
    pan TEXT,
    tan TEXT,
    aadhaar_no TEXT,
    
    -- Address
    billing_address TEXT,
    billing_city TEXT,
    billing_state_code TEXT REFERENCES states(code),
    billing_pincode TEXT,
    shipping_address TEXT,
    shipping_city TEXT,
    shipping_state_code TEXT REFERENCES states(code),
    shipping_pincode TEXT,
    
    -- Registration & Classification
    gst_registration_type TEXT CHECK(gst_registration_type IN 
        ('REGULAR', 'COMPOSITION', 'UNREGISTERED', 'CONSUMER', 'OVERSEAS', 'SEZ')) DEFAULT 'UNREGISTERED',
    
    -- Credit Terms
    credit_limit REAL DEFAULT 0,
    credit_days INTEGER DEFAULT 0,
    
    -- Opening Balance & Ledger
    ledger_id INTEGER UNIQUE REFERENCES ledgers(id),
    opening_balance REAL DEFAULT 0,
    balance_type TEXT CHECK(balance_type IN ('DR', 'CR')) DEFAULT 'DR',
    
    -- Status & Tracking
    is_active INTEGER DEFAULT 1,
    deactivation_reason TEXT,
    deactivation_date DATE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_parties_gstin ON parties(gstin) WHERE gstin IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_parties_type ON parties(party_type);
CREATE INDEX IF NOT EXISTS idx_parties_active ON parties(is_active);

-- ============================================================================
-- PARTY HISTORY & CHANGE LOG (Audit Trail)
-- ============================================================================
CREATE TABLE IF NOT EXISTS party_change_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    party_id INTEGER NOT NULL REFERENCES parties(id),
    change_type TEXT CHECK(change_type IN ('CREATE', 'UPDATE', 'DEACTIVATE', 'DELETE', 'REACTIVATE')) NOT NULL,
    changed_by TEXT,
    old_values TEXT,
    new_values TEXT,
    reason TEXT,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_party_changelog_party ON party_change_log(party_id);

-- ============================================================================
-- PARTY DOCUMENTS (Bank Details, Tax Certs, Agreements)
-- ============================================================================
CREATE TABLE IF NOT EXISTS party_documents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    party_id INTEGER NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    document_type TEXT CHECK(document_type IN ('ID_PROOF', 'ADDRESS_PROOF', 'TAX_CERT', 'BANK_MANDATE', 'CONTRACT', 'OTHER')),
    file_path TEXT,
    file_name TEXT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- LEDGER GROUPS (Chart of Accounts)
-- ============================================================================
CREATE TABLE IF NOT EXISTS ledger_groups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    parent_id INTEGER REFERENCES ledger_groups(id),
    nature TEXT CHECK(nature IN ('ASSETS', 'LIABILITIES', 'INCOME', 'EXPENSES')) NOT NULL,
    is_system_group INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Default Ledger Groups
INSERT OR IGNORE INTO ledger_groups (name, nature, is_system_group) VALUES
('Capital Account', 'LIABILITIES', 1),
('Current Assets', 'ASSETS', 1),
('Current Liabilities', 'LIABILITIES', 1),
('Direct Expenses', 'EXPENSES', 1),
('Direct Income', 'INCOME', 1),
('Fixed Assets', 'ASSETS', 1),
('Indirect Expenses', 'EXPENSES', 1),
('Indirect Income', 'INCOME', 1),
('Investments', 'ASSETS', 1),
('Loans & Advances (Asset)', 'ASSETS', 1),
('Loans (Liability)', 'LIABILITIES', 1),
('Sundry Creditors', 'LIABILITIES', 1),
('Sundry Debtors', 'ASSETS', 1),
('Bank Accounts', 'ASSETS', 1),
('Cash-in-Hand', 'ASSETS', 1),
('Duties & Taxes', 'LIABILITIES', 1),
('Purchase Accounts', 'EXPENSES', 1),
('Sales Accounts', 'INCOME', 1);

-- ============================================================================
-- LEDGERS (Party Accounts, Expense/Income Accounts)
-- ============================================================================
CREATE TABLE IF NOT EXISTS ledgers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    alias TEXT,
    ledger_group_id INTEGER NOT NULL REFERENCES ledger_groups(id),
    opening_balance REAL DEFAULT 0,
    balance_type TEXT CHECK(balance_type IN ('DR', 'CR')) DEFAULT 'DR',
    current_balance REAL DEFAULT 0,
    
    -- Party Details (for Sundry Debtors/Creditors)
    is_party INTEGER DEFAULT 0,
    gstin TEXT,
    pan TEXT,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    billing_address TEXT,
    billing_city TEXT,
    billing_state_code TEXT REFERENCES states(code),
    billing_pincode TEXT,
    shipping_address TEXT,
    shipping_city TEXT,
    shipping_state_code TEXT REFERENCES states(code),
    shipping_pincode TEXT,
    credit_limit REAL DEFAULT 0,
    credit_days INTEGER DEFAULT 0,
    
    -- GST Registration Type
    gst_registration_type TEXT CHECK(gst_registration_type IN 
        ('REGULAR', 'COMPOSITION', 'UNREGISTERED', 'CONSUMER', 'OVERSEAS', 'SEZ')) DEFAULT 'UNREGISTERED',
    
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_ledgers_gstin ON ledgers(gstin);
CREATE INDEX IF NOT EXISTS idx_ledgers_group ON ledgers(ledger_group_id);

-- ============================================================================
-- HSN/SAC CODES
-- ============================================================================
CREATE TABLE IF NOT EXISTS hsn_sac_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    type TEXT CHECK(type IN ('HSN', 'SAC')) NOT NULL,
    gst_rate REAL DEFAULT 0,
    cgst_rate REAL DEFAULT 0,
    sgst_rate REAL DEFAULT 0,
    igst_rate REAL DEFAULT 0,
    cess_rate REAL DEFAULT 0,
    cess_type TEXT CHECK(cess_type IN ('PERCENTAGE', 'AMOUNT')) DEFAULT 'PERCENTAGE',
    effective_from DATE,
    effective_to DATE,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_hsn_code ON hsn_sac_codes(code);

-- ============================================================================
-- ITEM CATEGORIES
-- ============================================================================
CREATE TABLE IF NOT EXISTS item_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    parent_id INTEGER REFERENCES item_categories(id),
    description TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- UNITS OF MEASUREMENT
-- ============================================================================
CREATE TABLE IF NOT EXISTS units (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    decimal_places INTEGER DEFAULT 2,
    is_active INTEGER DEFAULT 1
);

-- Insert Default Units
INSERT OR IGNORE INTO units (code, name, decimal_places) VALUES
('NOS', 'Numbers', 0),
('PCS', 'Pieces', 0),
('KGS', 'Kilograms', 3),
('GMS', 'Grams', 3),
('MTR', 'Meters', 2),
('LTR', 'Liters', 3),
('BOX', 'Boxes', 0),
('PKT', 'Packets', 0),
('DOZ', 'Dozens', 0),
('SET', 'Sets', 0),
('SQM', 'Square Meters', 2),
('SQF', 'Square Feet', 2),
('CMS', 'Centimeters', 2),
('QTL', 'Quintals', 3),
('TON', 'Metric Tons', 3),
('BAG', 'Bags', 0),
('BTL', 'Bottles', 0),
('CTN', 'Cartons', 0),
('PAR', 'Pairs', 0),
('ROL', 'Rolls', 0);

-- ============================================================================
-- ITEMS (Inventory Items with GST)
-- ============================================================================
CREATE TABLE IF NOT EXISTS items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    alias TEXT,
    barcode TEXT UNIQUE,
    sku TEXT UNIQUE,
    category_id INTEGER REFERENCES item_categories(id),
    hsn_sac_id INTEGER REFERENCES hsn_sac_codes(id),
    hsn_code TEXT,
    unit_id INTEGER REFERENCES units(id),
    
    -- Pricing
    cost_price REAL DEFAULT 0,
    selling_price REAL DEFAULT 0,
    mrp REAL DEFAULT 0,
    wholesale_price REAL DEFAULT 0,
    min_selling_price REAL DEFAULT 0,
    price_inclusive_tax INTEGER DEFAULT 0,
    
    -- GST Rates (can override HSN defaults)
    gst_rate REAL DEFAULT 0,
    cgst_rate REAL DEFAULT 0,
    sgst_rate REAL DEFAULT 0,
    igst_rate REAL DEFAULT 0,
    cess_rate REAL DEFAULT 0,
    cess_amount REAL DEFAULT 0,
    
    -- Inventory
    opening_stock REAL DEFAULT 0,
    current_stock REAL DEFAULT 0,
    min_stock_level REAL DEFAULT 0,
    max_stock_level REAL DEFAULT 0,
    reorder_level REAL DEFAULT 0,
    
    -- Additional Info
    description TEXT,
    manufacturer TEXT,
    batch_tracking INTEGER DEFAULT 0,
    serial_tracking INTEGER DEFAULT 0,
    expiry_tracking INTEGER DEFAULT 0,
    
    is_service INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_items_barcode ON items(barcode);
CREATE INDEX IF NOT EXISTS idx_items_sku ON items(sku);
CREATE INDEX IF NOT EXISTS idx_items_hsn ON items(hsn_code);

-- ============================================================================
-- ITEM BATCHES (for batch-wise inventory)
-- ============================================================================
CREATE TABLE IF NOT EXISTS item_batches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id INTEGER NOT NULL REFERENCES items(id),
    batch_number TEXT NOT NULL,
    manufacturing_date DATE,
    expiry_date DATE,
    cost_price REAL DEFAULT 0,
    selling_price REAL DEFAULT 0,
    mrp REAL DEFAULT 0,
    quantity REAL DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(item_id, batch_number)
);

-- ============================================================================
-- ITEM SERIALS (for serial-wise inventory)
-- ============================================================================
CREATE TABLE IF NOT EXISTS item_serials (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id INTEGER NOT NULL REFERENCES items(id),
    batch_id INTEGER REFERENCES item_batches(id),
    serial_number TEXT NOT NULL,
    status TEXT CHECK(status IN ('IN_STOCK', 'OUT', 'DAMAGED', 'TRANSFERRED', 'ADJUSTED_OUT')) DEFAULT 'IN_STOCK',
    reference_type TEXT,
    reference_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(item_id, serial_number)
);

CREATE INDEX IF NOT EXISTS idx_item_serials_item ON item_serials(item_id);
CREATE INDEX IF NOT EXISTS idx_item_serials_status ON item_serials(status);

-- ============================================================================
-- FINANCIAL YEARS
-- ============================================================================
CREATE TABLE IF NOT EXISTS financial_years (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active INTEGER DEFAULT 0,
    is_closed INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(start_date, end_date)
);

-- ============================================================================
-- VOUCHER TYPES
-- ============================================================================
CREATE TABLE IF NOT EXISTS voucher_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    code TEXT NOT NULL UNIQUE,
    type TEXT CHECK(type IN ('SALES', 'PURCHASE', 'PAYMENT', 'RECEIPT', 'JOURNAL', 
        'CONTRA', 'DEBIT_NOTE', 'CREDIT_NOTE', 'DELIVERY_NOTE', 'RECEIPT_NOTE')) NOT NULL,
    prefix TEXT,
    starting_number INTEGER DEFAULT 1,
    auto_numbering INTEGER DEFAULT 1,
    affects_inventory INTEGER DEFAULT 0,
    is_system_type INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Default Voucher Types
INSERT OR IGNORE INTO voucher_types (name, code, type, prefix, affects_inventory, is_system_type) VALUES
('Sales Invoice', 'SINV', 'SALES', 'INV/', 1, 1),
('Sales Return', 'SRET', 'CREDIT_NOTE', 'CN/', 1, 1),
('Purchase Invoice', 'PINV', 'PURCHASE', 'BILL/', 1, 1),
('Purchase Return', 'PRET', 'DEBIT_NOTE', 'DN/', 1, 1),
('Payment Voucher', 'PYMT', 'PAYMENT', 'PAY/', 0, 1),
('Receipt Voucher', 'RCPT', 'RECEIPT', 'REC/', 0, 1),
('Journal Voucher', 'JRNL', 'JOURNAL', 'JV/', 0, 1),
('Contra Voucher', 'CONT', 'CONTRA', 'CTR/', 0, 1),
('Delivery Challan', 'DLVY', 'DELIVERY_NOTE', 'DC/', 1, 1),
('Goods Receipt', 'GREC', 'RECEIPT_NOTE', 'GRN/', 1, 1),
('Quotation', 'QUOT', 'SALES', 'QT/', 0, 1),
('Sales Order', 'SORD', 'SALES', 'SO/', 0, 1),
('Purchase Order', 'PORD', 'PURCHASE', 'PO/', 0, 1);

-- ============================================================================
-- INVOICES (Main GST Invoice Table)
-- ============================================================================
CREATE TABLE IF NOT EXISTS invoices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    voucher_type_id INTEGER NOT NULL REFERENCES voucher_types(id),
    invoice_number TEXT NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE,
    financial_year_id INTEGER REFERENCES financial_years(id),
    
    -- Party Details
    party_id INTEGER REFERENCES ledgers(id),
    party_name TEXT NOT NULL,
    party_gstin TEXT,
    party_state_code TEXT REFERENCES states(code),
    party_address TEXT,
    
    -- Billing Address
    billing_name TEXT,
    billing_address TEXT,
    billing_city TEXT,
    billing_state_code TEXT REFERENCES states(code),
    billing_pincode TEXT,
    
    -- Shipping Address
    shipping_name TEXT,
    shipping_address TEXT,
    shipping_city TEXT,
    shipping_state_code TEXT REFERENCES states(code),
    shipping_pincode TEXT,
    
    -- Place of Supply (for GST)
    place_of_supply TEXT REFERENCES states(code),
    is_reverse_charge INTEGER DEFAULT 0,
    is_export INTEGER DEFAULT 0,
    export_type TEXT CHECK(export_type IN ('WITH_PAYMENT', 'WITHOUT_PAYMENT', 'SEZ_WITH', 'SEZ_WITHOUT')),
    
    -- Amounts
    subtotal REAL DEFAULT 0,
    discount_type TEXT CHECK(discount_type IN ('PERCENTAGE', 'AMOUNT')) DEFAULT 'AMOUNT',
    discount_value REAL DEFAULT 0,
    discount_amount REAL DEFAULT 0,
    taxable_amount REAL DEFAULT 0,
    
    -- GST Amounts
    cgst_amount REAL DEFAULT 0,
    sgst_amount REAL DEFAULT 0,
    igst_amount REAL DEFAULT 0,
    cess_amount REAL DEFAULT 0,
    total_tax_amount REAL DEFAULT 0,
    
    -- Other Charges
    transport_charges REAL DEFAULT 0,
    packing_charges REAL DEFAULT 0,
    other_charges REAL DEFAULT 0,
    
    -- Round Off
    round_off_amount REAL DEFAULT 0,
    grand_total REAL DEFAULT 0,
    amount_in_words TEXT,
    
    -- Payment Details
    payment_mode TEXT CHECK(payment_mode IN ('CASH', 'CREDIT', 'CARD', 'UPI', 'NEFT', 'CHEQUE', 'ONLINE')),
    payment_reference TEXT,
    paid_amount REAL DEFAULT 0,
    balance_amount REAL DEFAULT 0,
    payment_status TEXT CHECK(payment_status IN ('UNPAID', 'PARTIAL', 'PAID', 'OVERDUE')) DEFAULT 'UNPAID',
    
    -- E-Way Bill
    eway_bill_number TEXT,
    eway_bill_date DATE,
    vehicle_number TEXT,
    transporter_name TEXT,
    transporter_gstin TEXT,
    transport_mode TEXT CHECK(transport_mode IN ('ROAD', 'RAIL', 'AIR', 'SHIP')),
    distance_km REAL,
    
    -- E-Invoice (GST Portal)
    irn TEXT,
    irn_date TIMESTAMP,
    qr_code TEXT,
    ack_number TEXT,
    ack_date TIMESTAMP,
    
    -- Status
    status TEXT CHECK(status IN ('DRAFT', 'CONFIRMED', 'CANCELLED', 'VOID')) DEFAULT 'DRAFT',
    is_deleted INTEGER DEFAULT 0,
    deleted_reason TEXT,
    
    notes TEXT,
    terms_conditions TEXT,
    internal_notes TEXT,
    
    created_by TEXT,
    updated_by TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(voucher_type_id, invoice_number, financial_year_id)
);

CREATE INDEX IF NOT EXISTS idx_invoices_number ON invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(invoice_date);
CREATE INDEX IF NOT EXISTS idx_invoices_party ON invoices(party_id);
CREATE INDEX IF NOT EXISTS idx_invoices_fy ON invoices(financial_year_id);

-- ============================================================================
-- INVOICE ITEMS (Line Items with GST Details)
-- ============================================================================
CREATE TABLE IF NOT EXISTS invoice_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    item_id INTEGER REFERENCES items(id),
    batch_id INTEGER REFERENCES item_batches(id),
    
    -- Item Details
    item_name TEXT NOT NULL,
    item_description TEXT,
    hsn_code TEXT,
    barcode TEXT,
    
    -- Quantity & Unit
    quantity REAL NOT NULL,
    unit_id INTEGER REFERENCES units(id),
    unit_code TEXT,
    free_quantity REAL DEFAULT 0,
    
    -- Pricing
    rate REAL NOT NULL,
    mrp REAL DEFAULT 0,
    discount_type TEXT CHECK(discount_type IN ('PERCENTAGE', 'AMOUNT')) DEFAULT 'AMOUNT',
    discount_value REAL DEFAULT 0,
    discount_amount REAL DEFAULT 0,
    taxable_amount REAL DEFAULT 0,
    
    -- GST Details
    gst_rate REAL DEFAULT 0,
    cgst_rate REAL DEFAULT 0,
    cgst_amount REAL DEFAULT 0,
    sgst_rate REAL DEFAULT 0,
    sgst_amount REAL DEFAULT 0,
    igst_rate REAL DEFAULT 0,
    igst_amount REAL DEFAULT 0,
    cess_rate REAL DEFAULT 0,
    cess_amount REAL DEFAULT 0,
    
    -- Totals
    total_tax_amount REAL DEFAULT 0,
    total_amount REAL DEFAULT 0,
    
    serial_number INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_items_item ON invoice_items(item_id);

-- ============================================================================
-- INVOICE TAX SUMMARY (HSN-wise Tax Summary)
-- ============================================================================
CREATE TABLE IF NOT EXISTS invoice_tax_summary (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    hsn_code TEXT,
    taxable_amount REAL DEFAULT 0,
    gst_rate REAL DEFAULT 0,
    cgst_amount REAL DEFAULT 0,
    sgst_amount REAL DEFAULT 0,
    igst_amount REAL DEFAULT 0,
    cess_amount REAL DEFAULT 0,
    total_tax_amount REAL DEFAULT 0,
    total_quantity REAL DEFAULT 0
);

-- ============================================================================
-- LEDGER TRANSACTIONS (Double Entry Bookkeeping)
-- ============================================================================
CREATE TABLE IF NOT EXISTS ledger_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    transaction_date DATE NOT NULL,
    voucher_type_id INTEGER REFERENCES voucher_types(id),
    voucher_number TEXT,
    reference_id INTEGER,
    reference_type TEXT,
    ledger_id INTEGER NOT NULL REFERENCES ledgers(id),
    debit_amount REAL DEFAULT 0,
    credit_amount REAL DEFAULT 0,
    balance REAL DEFAULT 0,
    narration TEXT,
    financial_year_id INTEGER REFERENCES financial_years(id),
    is_opening_balance INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ledger_trans_ledger ON ledger_transactions(ledger_id);
CREATE INDEX IF NOT EXISTS idx_ledger_trans_date ON ledger_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_ledger_trans_ref ON ledger_transactions(reference_id, reference_type);

-- ============================================================================
-- INVENTORY TRANSACTIONS (Stock Movements)
-- ============================================================================
CREATE TABLE IF NOT EXISTS inventory_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    transaction_date DATE NOT NULL,
    voucher_type_id INTEGER REFERENCES voucher_types(id),
    voucher_number TEXT,
    reference_id INTEGER,
    reference_type TEXT,
    item_id INTEGER NOT NULL REFERENCES items(id),
    batch_id INTEGER REFERENCES item_batches(id),
    
    transaction_type TEXT CHECK(transaction_type IN ('IN', 'OUT', 'ADJUSTMENT', 'TRANSFER')),
    quantity REAL NOT NULL,
    rate REAL DEFAULT 0,
    amount REAL DEFAULT 0,
    
    -- Running balance
    balance_before REAL DEFAULT 0,
    balance_after REAL DEFAULT 0,
    
    narration TEXT,
    financial_year_id INTEGER REFERENCES financial_years(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Link serials to inventory transactions for audit trail
CREATE TABLE IF NOT EXISTS inventory_transaction_serials (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    inventory_transaction_id INTEGER NOT NULL REFERENCES inventory_transactions(id) ON DELETE CASCADE,
    serial_id INTEGER NOT NULL REFERENCES item_serials(id)
);

CREATE INDEX IF NOT EXISTS idx_inv_trans_item ON inventory_transactions(item_id);
CREATE INDEX IF NOT EXISTS idx_inv_trans_date ON inventory_transactions(transaction_date);

-- ============================================================================
-- PAYMENT/RECEIPT ENTRIES
-- ============================================================================
CREATE TABLE IF NOT EXISTS payment_receipts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    voucher_type_id INTEGER NOT NULL REFERENCES voucher_types(id),
    voucher_number TEXT NOT NULL,
    voucher_date DATE NOT NULL,
    party_id INTEGER REFERENCES ledgers(id),
    party_name TEXT,
    
    payment_mode TEXT CHECK(payment_mode IN ('CASH', 'BANK', 'UPI', 'CARD', 'CHEQUE', 'NEFT', 'RTGS')),
    bank_account_id INTEGER REFERENCES ledgers(id),
    cheque_number TEXT,
    cheque_date DATE,
    transaction_reference TEXT,
    
    amount REAL NOT NULL,
    narration TEXT,
    
    financial_year_id INTEGER REFERENCES financial_years(id),
    is_reconciled INTEGER DEFAULT 0,
    status TEXT CHECK(status IN ('DRAFT', 'CONFIRMED', 'CANCELLED')) DEFAULT 'DRAFT',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PAYMENT ALLOCATIONS (Invoice-wise Settlement)
-- ============================================================================
CREATE TABLE IF NOT EXISTS payment_allocations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_receipt_id INTEGER NOT NULL REFERENCES payment_receipts(id),
    invoice_id INTEGER NOT NULL REFERENCES invoices(id),
    allocated_amount REAL NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- EXPENSES & OTHER INCOME
-- ============================================================================
CREATE TABLE IF NOT EXISTS expense_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    classification TEXT CHECK(classification IN ('DIRECT', 'INDIRECT', 'CAPITAL')) NOT NULL,
    ledger_id INTEGER REFERENCES ledgers(id),
    gst_eligible INTEGER DEFAULT 1,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    expense_date DATE NOT NULL,
    category_id INTEGER NOT NULL REFERENCES expense_categories(id),
    vendor_ledger_id INTEGER REFERENCES ledgers(id),
    reference_no TEXT,
    description TEXT,

    taxable_amount REAL DEFAULT 0,
    gst_rate REAL DEFAULT 0,
    cgst_amount REAL DEFAULT 0,
    sgst_amount REAL DEFAULT 0,
    igst_amount REAL DEFAULT 0,
    total_gst_amount REAL DEFAULT 0,
    total_amount REAL DEFAULT 0,
    itc_eligible INTEGER DEFAULT 1,

    payment_mode TEXT,
    paid_amount REAL DEFAULT 0,
    balance_amount REAL DEFAULT 0,
    payment_status TEXT CHECK(payment_status IN ('UNPAID', 'PARTIAL', 'PAID', 'OVERDUE')) DEFAULT 'UNPAID',
    is_credit INTEGER DEFAULT 0,
    due_date DATE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_vendor ON expenses(vendor_ledger_id);

CREATE TABLE IF NOT EXISTS expense_attachments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    expense_id INTEGER NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    file_name TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS expense_recurring (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    template_name TEXT NOT NULL,
    category_id INTEGER NOT NULL REFERENCES expense_categories(id),
    vendor_ledger_id INTEGER REFERENCES ledgers(id),
    description TEXT,
    taxable_amount REAL DEFAULT 0,
    gst_rate REAL DEFAULT 0,
    itc_eligible INTEGER DEFAULT 1,
    payment_mode TEXT,
    is_credit INTEGER DEFAULT 0,
    frequency TEXT CHECK(frequency IN ('WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY')) NOT NULL,
    next_run_date DATE NOT NULL,
    last_run_date DATE,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS other_income_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    income_date DATE NOT NULL,
    ledger_id INTEGER REFERENCES ledgers(id),
    reference_no TEXT,
    description TEXT,
    amount REAL NOT NULL,
    payment_mode TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- AUDIT LOG (Compliance - No Deletion Allowed)
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL,
    record_id INTEGER NOT NULL,
    action TEXT CHECK(action IN ('INSERT', 'UPDATE', 'DELETE', 'CANCEL', 'VOID')),
    old_values TEXT,
    new_values TEXT,
    changed_by TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address TEXT,
    reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_audit_table ON audit_log(table_name, record_id);

-- ============================================================================
-- CRM TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS crm_staff (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_crm_staff_name ON crm_staff(name);

CREATE TABLE IF NOT EXISTS crm_pipeline_stages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    sort_order INTEGER DEFAULT 0,
    is_won INTEGER DEFAULT 0,
    is_lost INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1
);

INSERT OR IGNORE INTO crm_pipeline_stages (name, sort_order, is_won, is_lost) VALUES
('New', 1, 0, 0),
('Qualified', 2, 0, 0),
('Proposal', 3, 0, 0),
('Negotiation', 4, 0, 0),
('Won', 5, 1, 0),
('Lost', 6, 0, 1);

INSERT OR IGNORE INTO crm_staff (name, email, phone) VALUES
('Aarav Shah', 'aarav@billease.local', '9000000001'),
('Isha Verma', 'isha@billease.local', '9000000002'),
('Neel Kapoor', 'neel@billease.local', '9000000003');

CREATE TABLE IF NOT EXISTS crm_leads (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    company_name TEXT,
    phone TEXT,
    email TEXT,
    gstin TEXT,
    source TEXT,
    status TEXT DEFAULT 'New',
    pipeline_stage_id INTEGER REFERENCES crm_pipeline_stages(id),
    assigned_staff_id INTEGER REFERENCES crm_staff(id),
    credit_limit REAL DEFAULT 0,
    expected_value REAL DEFAULT 0,
    notes TEXT,
    next_followup_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS crm_lead_notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lead_id INTEGER NOT NULL REFERENCES crm_leads(id) ON DELETE CASCADE,
    note TEXT NOT NULL,
    created_by TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS crm_call_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lead_id INTEGER NOT NULL REFERENCES crm_leads(id) ON DELETE CASCADE,
    call_type TEXT CHECK(call_type IN ('INBOUND', 'OUTBOUND')) DEFAULT 'OUTBOUND',
    outcome TEXT,
    duration_seconds INTEGER DEFAULT 0,
    notes TEXT,
    created_by TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS crm_followups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lead_id INTEGER NOT NULL REFERENCES crm_leads(id) ON DELETE CASCADE,
    followup_date DATE NOT NULL,
    reminder_time TEXT,
    status TEXT DEFAULT 'PENDING',
    notes TEXT,
    created_by TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- USER SETTINGS
-- ============================================================================
CREATE TABLE IF NOT EXISTS settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    setting_key TEXT NOT NULL UNIQUE,
    setting_value TEXT,
    setting_type TEXT CHECK(setting_type IN ('STRING', 'INTEGER', 'BOOLEAN', 'JSON')),
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Default Settings
INSERT OR IGNORE INTO settings (setting_key, setting_value, setting_type, description) VALUES
('auto_round_off', 'true', 'BOOLEAN', 'Automatically round off invoice totals'),
('round_off_limit', '0.50', 'STRING', 'Maximum round off amount allowed'),
('enable_negative_stock', 'false', 'BOOLEAN', 'Allow negative stock in inventory'),
('default_gst_rate', '18', 'STRING', 'Default GST rate for new items'),
('backup_frequency', 'daily', 'STRING', 'Automatic backup frequency'),
('invoice_print_copies', '2', 'INTEGER', 'Number of invoice copies to print'),
('show_hsn_in_invoice', 'true', 'BOOLEAN', 'Display HSN code in invoice'),
('price_decimal_places', '2', 'INTEGER', 'Decimal places for prices'),
('quantity_decimal_places', '3', 'INTEGER', 'Decimal places for quantities');

-- ============================================================================
-- TRIGGERS FOR AUDIT TRAIL (Prevents Invoice Deletion)
-- ============================================================================

-- Prevent hard delete of invoices - mark as cancelled instead
CREATE TRIGGER IF NOT EXISTS prevent_invoice_delete
BEFORE DELETE ON invoices
BEGIN
    SELECT RAISE(ABORT, 'Invoice deletion not allowed. Use CANCEL or VOID status instead.');
END;

-- Auto-update timestamps
CREATE TRIGGER IF NOT EXISTS update_invoice_timestamp
AFTER UPDATE ON invoices
BEGIN
    UPDATE invoices SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_item_timestamp
AFTER UPDATE ON items
BEGIN
    UPDATE items SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_ledger_timestamp
AFTER UPDATE ON ledgers
BEGIN
    UPDATE ledgers SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- ============================================================================
-- VIEWS FOR REPORTING
-- ============================================================================

-- Outstanding Invoices View
CREATE VIEW IF NOT EXISTS v_outstanding_invoices AS
SELECT 
    i.id,
    i.invoice_number,
    i.invoice_date,
    i.due_date,
    i.party_name,
    i.grand_total,
    i.paid_amount,
    i.balance_amount,
    i.payment_status,
    CASE 
        WHEN i.due_date < DATE('now') AND i.balance_amount > 0 THEN 
            CAST(JULIANDAY('now') - JULIANDAY(i.due_date) AS INTEGER)
        ELSE 0 
    END as overdue_days
FROM invoices i
WHERE i.status = 'CONFIRMED' 
AND i.balance_amount > 0
AND i.is_deleted = 0;

-- GST Summary View (for GSTR-1)
CREATE VIEW IF NOT EXISTS v_gst_summary AS
SELECT 
    i.invoice_date,
    i.invoice_number,
    i.party_gstin,
    i.party_state_code,
    i.place_of_supply,
    its.hsn_code,
    its.taxable_amount,
    its.gst_rate,
    its.cgst_amount,
    its.sgst_amount,
    its.igst_amount,
    its.cess_amount,
    i.is_reverse_charge,
    i.is_export
FROM invoices i
JOIN invoice_tax_summary its ON i.id = its.invoice_id
WHERE i.status = 'CONFIRMED' AND i.is_deleted = 0;

-- Stock Summary View
CREATE VIEW IF NOT EXISTS v_stock_summary AS
SELECT 
    i.id,
    i.name,
    i.barcode,
    i.sku,
    i.hsn_code,
    u.code as unit,
    i.current_stock,
    i.min_stock_level,
    i.cost_price,
    i.selling_price,
    i.mrp,
    (i.current_stock * i.cost_price) as stock_value,
    CASE WHEN i.current_stock <= i.reorder_level THEN 1 ELSE 0 END as needs_reorder
FROM items i
LEFT JOIN units u ON i.unit_id = u.id
WHERE i.is_active = 1;
