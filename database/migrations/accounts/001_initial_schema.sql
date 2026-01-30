-- ============================================
-- BillEase Accounts Database - Initial Schema
-- Database: billease_accounts
-- Description: Accounting system with chart of accounts, journal entries, and ledger
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
    fiscal_year_start INTEGER DEFAULT 1, -- Month (1-12)
    currency VARCHAR(3) DEFAULT 'USD',
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tenants_user_id ON tenants(user_id);

-- ============================================
-- CHART OF ACCOUNTS
-- ============================================
CREATE TABLE chart_of_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    account_code VARCHAR(50) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) NOT NULL CHECK (account_type IN ('asset', 'liability', 'equity', 'revenue', 'expense')),
    account_subtype VARCHAR(100),
    parent_account_id UUID REFERENCES chart_of_accounts(id),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_system BOOLEAN DEFAULT FALSE,
    normal_balance VARCHAR(10) NOT NULL CHECK (normal_balance IN ('debit', 'credit')),
    level INTEGER DEFAULT 1,
    opening_balance DECIMAL(15,2) DEFAULT 0,
    current_balance DECIMAL(15,2) DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, account_code)
);

CREATE INDEX idx_coa_tenant_id ON chart_of_accounts(tenant_id);
CREATE INDEX idx_coa_account_code ON chart_of_accounts(account_code);
CREATE INDEX idx_coa_account_type ON chart_of_accounts(account_type);
CREATE INDEX idx_coa_parent ON chart_of_accounts(parent_account_id);
CREATE INDEX idx_coa_active ON chart_of_accounts(is_active);

-- ============================================
-- JOURNAL ENTRIES
-- ============================================
CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    entry_number VARCHAR(50) UNIQUE NOT NULL,
    entry_date DATE NOT NULL,
    entry_type VARCHAR(50) DEFAULT 'general' CHECK (entry_type IN ('general', 'opening', 'closing', 'adjusting', 'reversing')),
    reference VARCHAR(100),
    description TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'posted', 'voided')),
    fiscal_year INTEGER NOT NULL,
    fiscal_period INTEGER NOT NULL,
    created_by UUID NOT NULL, -- References main DB users
    posted_by UUID, -- References main DB users
    posted_at TIMESTAMP WITH TIME ZONE,
    voided_by UUID,
    voided_at TIMESTAMP WITH TIME ZONE,
    void_reason TEXT,
    total_debit DECIMAL(15,2) DEFAULT 0,
    total_credit DECIMAL(15,2) DEFAULT 0,
    attachments JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT balanced_entry CHECK (total_debit = total_credit OR status = 'draft')
);

CREATE INDEX idx_je_tenant_id ON journal_entries(tenant_id);
CREATE INDEX idx_je_entry_number ON journal_entries(entry_number);
CREATE INDEX idx_je_entry_date ON journal_entries(entry_date DESC);
CREATE INDEX idx_je_status ON journal_entries(status);
CREATE INDEX idx_je_fiscal_period ON journal_entries(fiscal_year, fiscal_period);
CREATE INDEX idx_je_created_by ON journal_entries(created_by);

-- ============================================
-- JOURNAL ENTRY LINES
-- ============================================
CREATE TABLE journal_entry_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    journal_entry_id UUID NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    debit_amount DECIMAL(15,2) DEFAULT 0,
    credit_amount DECIMAL(15,2) DEFAULT 0,
    description TEXT,
    reference VARCHAR(100),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT debit_or_credit CHECK (
        (debit_amount > 0 AND credit_amount = 0) OR
        (credit_amount > 0 AND debit_amount = 0)
    )
);

CREATE INDEX idx_jel_tenant_id ON journal_entry_lines(tenant_id);
CREATE INDEX idx_jel_journal_entry_id ON journal_entry_lines(journal_entry_id);
CREATE INDEX idx_jel_account_id ON journal_entry_lines(account_id);

-- ============================================
-- GENERAL LEDGER
-- ============================================
CREATE TABLE general_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    journal_entry_id UUID NOT NULL REFERENCES journal_entries(id),
    journal_entry_line_id UUID NOT NULL REFERENCES journal_entry_lines(id),
    transaction_date DATE NOT NULL,
    fiscal_year INTEGER NOT NULL,
    fiscal_period INTEGER NOT NULL,
    entry_number VARCHAR(50) NOT NULL,
    description TEXT,
    debit_amount DECIMAL(15,2) DEFAULT 0,
    credit_amount DECIMAL(15,2) DEFAULT 0,
    running_balance DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_gl_tenant_id ON general_ledger(tenant_id);
CREATE INDEX idx_gl_account_id ON general_ledger(account_id);
CREATE INDEX idx_gl_transaction_date ON general_ledger(transaction_date DESC);
CREATE INDEX idx_gl_fiscal_period ON general_ledger(fiscal_year, fiscal_period);
CREATE INDEX idx_gl_journal_entry ON general_ledger(journal_entry_id);

-- ============================================
-- FISCAL PERIODS
-- ============================================
CREATE TABLE fiscal_periods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    fiscal_year INTEGER NOT NULL,
    period_number INTEGER NOT NULL,
    period_name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'open' CHECK (status IN ('open', 'closed', 'locked')),
    closed_by UUID,
    closed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, fiscal_year, period_number)
);

CREATE INDEX idx_fp_tenant_id ON fiscal_periods(tenant_id);
CREATE INDEX idx_fp_fiscal_year ON fiscal_periods(fiscal_year);
CREATE INDEX idx_fp_status ON fiscal_periods(status);

-- ============================================
-- BANK ACCOUNTS
-- ============================================
CREATE TABLE bank_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    bank_name VARCHAR(255) NOT NULL,
    account_number VARCHAR(100) NOT NULL,
    account_holder VARCHAR(255),
    branch VARCHAR(255),
    swift_code VARCHAR(50),
    iban VARCHAR(100),
    currency VARCHAR(3) DEFAULT 'USD',
    opening_balance DECIMAL(15,2) DEFAULT 0,
    current_balance DECIMAL(15,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bank_accounts_tenant_id ON bank_accounts(tenant_id);
CREATE INDEX idx_bank_accounts_account_id ON bank_accounts(account_id);

-- ============================================
-- BANK TRANSACTIONS
-- ============================================
CREATE TABLE bank_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    bank_account_id UUID NOT NULL REFERENCES bank_accounts(id),
    journal_entry_id UUID REFERENCES journal_entries(id),
    transaction_date DATE NOT NULL,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('deposit', 'withdrawal', 'transfer', 'fee', 'interest')),
    amount DECIMAL(15,2) NOT NULL,
    reference VARCHAR(100),
    description TEXT,
    payee_payer VARCHAR(255),
    is_reconciled BOOLEAN DEFAULT FALSE,
    reconciled_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bt_tenant_id ON bank_transactions(tenant_id);
CREATE INDEX idx_bt_bank_account_id ON bank_transactions(bank_account_id);
CREATE INDEX idx_bt_transaction_date ON bank_transactions(transaction_date DESC);
CREATE INDEX idx_bt_reconciled ON bank_transactions(is_reconciled);

-- ============================================
-- BUDGETS
-- ============================================
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    fiscal_year INTEGER NOT NULL,
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'closed')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    description TEXT,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_budgets_tenant_id ON budgets(tenant_id);
CREATE INDEX idx_budgets_fiscal_year ON budgets(fiscal_year);
CREATE INDEX idx_budgets_status ON budgets(status);

-- ============================================
-- BUDGET LINES
-- ============================================
CREATE TABLE budget_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    period_1 DECIMAL(15,2) DEFAULT 0,
    period_2 DECIMAL(15,2) DEFAULT 0,
    period_3 DECIMAL(15,2) DEFAULT 0,
    period_4 DECIMAL(15,2) DEFAULT 0,
    period_5 DECIMAL(15,2) DEFAULT 0,
    period_6 DECIMAL(15,2) DEFAULT 0,
    period_7 DECIMAL(15,2) DEFAULT 0,
    period_8 DECIMAL(15,2) DEFAULT 0,
    period_9 DECIMAL(15,2) DEFAULT 0,
    period_10 DECIMAL(15,2) DEFAULT 0,
    period_11 DECIMAL(15,2) DEFAULT 0,
    period_12 DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bl_tenant_id ON budget_lines(tenant_id);
CREATE INDEX idx_bl_budget_id ON budget_lines(budget_id);
CREATE INDEX idx_bl_account_id ON budget_lines(account_id);

-- ============================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE chart_of_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entry_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE general_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE fiscal_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_lines ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================

CREATE POLICY "Tenant members can view chart of accounts"
    ON chart_of_accounts FOR SELECT
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

CREATE TRIGGER update_coa_updated_at BEFORE UPDATE ON chart_of_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_je_updated_at BEFORE UPDATE ON journal_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to post journal entry to general ledger
CREATE OR REPLACE FUNCTION post_to_general_ledger()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'posted' AND OLD.status = 'draft' THEN
        INSERT INTO general_ledger (
            tenant_id, account_id, journal_entry_id, journal_entry_line_id,
            transaction_date, fiscal_year, fiscal_period, entry_number,
            description, debit_amount, credit_amount
        )
        SELECT
            jel.tenant_id, jel.account_id, je.id, jel.id,
            je.entry_date, je.fiscal_year, je.fiscal_period, je.entry_number,
            jel.description, jel.debit_amount, jel.credit_amount
        FROM journal_entry_lines jel
        WHERE jel.journal_entry_id = NEW.id;
        
        -- Update account balances
        UPDATE chart_of_accounts coa
        SET current_balance = current_balance +
            CASE 
                WHEN coa.normal_balance = 'debit' THEN
                    COALESCE((SELECT SUM(debit_amount - credit_amount) FROM journal_entry_lines WHERE account_id = coa.id AND journal_entry_id = NEW.id), 0)
                ELSE
                    COALESCE((SELECT SUM(credit_amount - debit_amount) FROM journal_entry_lines WHERE account_id = coa.id AND journal_entry_id = NEW.id), 0)
            END
        WHERE coa.id IN (SELECT account_id FROM journal_entry_lines WHERE journal_entry_id = NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER post_journal_entry_trigger
    AFTER UPDATE ON journal_entries
    FOR EACH ROW
    EXECUTE FUNCTION post_to_general_ledger();

-- Function to calculate JE totals
CREATE OR REPLACE FUNCTION calculate_je_totals()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE journal_entries
    SET
        total_debit = (SELECT COALESCE(SUM(debit_amount), 0) FROM journal_entry_lines WHERE journal_entry_id = NEW.journal_entry_id),
        total_credit = (SELECT COALESCE(SUM(credit_amount), 0) FROM journal_entry_lines WHERE journal_entry_id = NEW.journal_entry_id)
    WHERE id = NEW.journal_entry_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_totals_on_line_change
    AFTER INSERT OR UPDATE ON journal_entry_lines
    FOR EACH ROW
    EXECUTE FUNCTION calculate_je_totals();

-- ============================================
-- VIEWS
-- ============================================

-- Trial Balance
CREATE OR REPLACE VIEW trial_balance AS
SELECT
    coa.tenant_id,
    coa.account_code,
    coa.account_name,
    coa.account_type,
    SUM(gl.debit_amount) as total_debit,
    SUM(gl.credit_amount) as total_credit,
    coa.current_balance
FROM chart_of_accounts coa
LEFT JOIN general_ledger gl ON coa.id = gl.account_id
WHERE coa.is_active = TRUE
GROUP BY coa.tenant_id, coa.id, coa.account_code, coa.account_name, coa.account_type, coa.current_balance
ORDER BY coa.account_code;

-- Profit & Loss Statement
CREATE OR REPLACE VIEW profit_loss AS
SELECT
    tenant_id,
    account_type,
    account_code,
    account_name,
    current_balance as amount
FROM chart_of_accounts
WHERE account_type IN ('revenue', 'expense')
AND is_active = TRUE
ORDER BY account_type, account_code;

-- Balance Sheet
CREATE OR REPLACE VIEW balance_sheet AS
SELECT
    tenant_id,
    account_type,
    account_code,
    account_name,
    current_balance as amount
FROM chart_of_accounts
WHERE account_type IN ('asset', 'liability', 'equity')
AND is_active = TRUE
ORDER BY 
    CASE account_type
        WHEN 'asset' THEN 1
        WHEN 'liability' THEN 2
        WHEN 'equity' THEN 3
    END,
    account_code;

-- ============================================
-- END OF MIGRATION
-- ============================================
