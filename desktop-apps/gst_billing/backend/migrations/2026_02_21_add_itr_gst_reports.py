"""
Migration: Add ITR and GST report tables
- Fixed assets & depreciation
- Loan schedules
- GST amendments
- Invoice classification (column on invoices)
"""

import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parents[1] / "data" / "gst_billing.db"


def run():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.execute("PRAGMA foreign_keys = ON")

        # Fixed Assets for depreciation
        conn.execute("""
            CREATE TABLE IF NOT EXISTS fixed_assets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                ledger_id INTEGER REFERENCES ledgers(id),
                asset_category TEXT CHECK(asset_category IN ('BUILDING', 'MACHINERY', 'VEHICLE', 'FURNITURE', 'COMPUTER', 'OTHER')) DEFAULT 'OTHER',
                purchase_date DATE NOT NULL,
                purchase_value REAL NOT NULL,
                residual_value REAL DEFAULT 0,
                useful_life_years INTEGER DEFAULT 5,
                depreciation_method TEXT CHECK(depreciation_method IN ('SLM', 'WDV')) DEFAULT 'SLM',
                is_active INTEGER DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Depreciation schedule
        conn.execute("""
            CREATE TABLE IF NOT EXISTS depreciation_schedule (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                asset_id INTEGER NOT NULL REFERENCES fixed_assets(id) ON DELETE CASCADE,
                financial_year_id INTEGER REFERENCES financial_years(id),
                period_from DATE NOT NULL,
                period_to DATE NOT NULL,
                opening_wdv REAL DEFAULT 0,
                depreciation_amount REAL NOT NULL,
                closing_wdv REAL DEFAULT 0,
                ledger_transaction_id INTEGER REFERENCES ledger_transactions(id),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Loan schedules
        conn.execute("""
            CREATE TABLE IF NOT EXISTS loans (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                lender_ledger_id INTEGER REFERENCES ledgers(id),
                principal_amount REAL NOT NULL,
                interest_rate REAL DEFAULT 0,
                tenure_months INTEGER NOT NULL,
                emi_amount REAL DEFAULT 0,
                start_date DATE NOT NULL,
                end_date DATE,
                loan_type TEXT CHECK(loan_type IN ('TERM', 'OVERDRAFT', 'CASH_CREDIT')) DEFAULT 'TERM',
                status TEXT CHECK(status IN ('ACTIVE', 'CLOSED', 'NPA')) DEFAULT 'ACTIVE',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        conn.execute("""
            CREATE TABLE IF NOT EXISTS loan_schedules (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                loan_id INTEGER NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
                installment_number INTEGER NOT NULL,
                due_date DATE NOT NULL,
                principal_amount REAL NOT NULL,
                interest_amount REAL DEFAULT 0,
                emi_amount REAL NOT NULL,
                opening_balance REAL DEFAULT 0,
                closing_balance REAL DEFAULT 0,
                payment_date DATE,
                paid_amount REAL DEFAULT 0,
                status TEXT CHECK(status IN ('PENDING', 'PAID', 'OVERDUE', 'PARTIAL')) DEFAULT 'PENDING',
                ledger_transaction_id INTEGER REFERENCES ledger_transactions(id),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # GST amendments (for revised returns)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS gst_amendments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                invoice_id INTEGER NOT NULL REFERENCES invoices(id),
                amendment_type TEXT CHECK(amendment_type IN ('TAX_VALUE', 'TAX_RATE', 'TAX_AMOUNT', 'OTHER')) NOT NULL,
                original_value REAL,
                revised_value REAL NOT NULL,
                reason TEXT,
                amendment_date DATE NOT NULL,
                gstr_period TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Add invoice_classification to invoices if not exists
        try:
            conn.execute("ALTER TABLE invoices ADD COLUMN invoice_classification TEXT")
        except sqlite3.OperationalError:
            pass  # Column may already exist

        conn.commit()
        print("Migration 2026_02_21_add_itr_gst_reports completed successfully")
    finally:
        conn.close()


if __name__ == "__main__":
    run()
