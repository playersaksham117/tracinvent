"""
Migration: Statutory Compliance Engine
- Year locking (no edit after audit)
- GST filed status (immutable records)
- Amendment flow (adjustment entries only)
- Evidence storage
- ITC tracking & mismatch alerts
- Tax payment tracking
"""

import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parents[1] / "data" / "gst_billing.db"


def run():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.execute("PRAGMA foreign_keys = ON")

        # Add is_locked to financial_years (year lock - no change after audit)
        for col in ["is_locked", "locked_at", "locked_by", "audit_completed_at"]:
            try:
                if col == "is_locked":
                    conn.execute("ALTER TABLE financial_years ADD COLUMN is_locked INTEGER DEFAULT 0")
                elif col == "locked_at":
                    conn.execute("ALTER TABLE financial_years ADD COLUMN locked_at TIMESTAMP")
                elif col == "locked_by":
                    conn.execute("ALTER TABLE financial_years ADD COLUMN locked_by TEXT")
                elif col == "audit_completed_at":
                    conn.execute("ALTER TABLE financial_years ADD COLUMN audit_completed_at TIMESTAMP")
            except sqlite3.OperationalError:
                pass

        # Add filed_status to invoices (GSTR-1 filed = immutable)
        try:
            conn.execute("ALTER TABLE invoices ADD COLUMN gstr1_filed INTEGER DEFAULT 0")
            conn.execute("ALTER TABLE invoices ADD COLUMN gstr1_filed_at TIMESTAMP")
            conn.execute("ALTER TABLE invoices ADD COLUMN gstr1_arn TEXT")
        except sqlite3.OperationalError:
            pass

        # GST Return Filing (GSTR-1, GSTR-3B) - immutable record of what was filed
        conn.execute("""
            CREATE TABLE IF NOT EXISTS gst_return_filed (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                return_type TEXT CHECK(return_type IN ('GSTR1', 'GSTR3B')) NOT NULL,
                period_month INTEGER NOT NULL,
                period_year INTEGER NOT NULL,
                filed_date DATE NOT NULL,
                arn TEXT,
                status TEXT CHECK(status IN ('FILED', 'AMENDED')) DEFAULT 'FILED',
                json_snapshot TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Tax Payment Tracking (liability, paid, remaining)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS gst_tax_payments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                period_month INTEGER NOT NULL,
                period_year INTEGER NOT NULL,
                cgst_liability REAL DEFAULT 0,
                sgst_liability REAL DEFAULT 0,
                igst_liability REAL DEFAULT 0,
                cess_liability REAL DEFAULT 0,
                total_liability REAL DEFAULT 0,
                cgst_paid REAL DEFAULT 0,
                sgst_paid REAL DEFAULT 0,
                igst_paid REAL DEFAULT 0,
                cess_paid REAL DEFAULT 0,
                total_paid REAL DEFAULT 0,
                challan_number TEXT,
                challan_date DATE,
                bank_reference TEXT,
                status TEXT CHECK(status IN ('PENDING', 'PARTIAL', 'PAID')) DEFAULT 'PENDING',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # ITC Tracking (input GST - eligible/ineligible, supplier match)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS itc_register (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                source_type TEXT CHECK(source_type IN ('PURCHASE', 'EXPENSE', 'IMPORT')) NOT NULL,
                source_id INTEGER,
                supplier_gstin TEXT,
                invoice_number TEXT,
                invoice_date DATE,
                taxable_value REAL DEFAULT 0,
                cgst_amount REAL DEFAULT 0,
                sgst_amount REAL DEFAULT 0,
                igst_amount REAL DEFAULT 0,
                cess_amount REAL DEFAULT 0,
                total_itc REAL DEFAULT 0,
                itc_eligible INTEGER DEFAULT 1,
                itc_claimed INTEGER DEFAULT 0,
                supplier_2b_match INTEGER DEFAULT 0,
                mismatch_reason TEXT,
                period_month INTEGER,
                period_year INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # ITC / GST Mismatch Alerts (books vs portal vs supplier)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS compliance_mismatch_alerts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                alert_type TEXT CHECK(alert_type IN ('ITC_2B', 'OUTWARD_SUPPLY', 'TAX_LIABILITY', 'BANK_RECON')) NOT NULL,
                reference_type TEXT,
                reference_id INTEGER,
                description TEXT,
                books_value REAL,
                portal_value REAL,
                difference REAL,
                severity TEXT CHECK(severity IN ('INFO', 'WARNING', 'CRITICAL')) DEFAULT 'WARNING',
                status TEXT CHECK(status IN ('OPEN', 'RESOLVED', 'EXPLAINED')) DEFAULT 'OPEN',
                resolved_at TIMESTAMP,
                resolution_notes TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Compliance Evidence Storage (invoices, attachments, challans)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS compliance_evidence (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                entity_type TEXT CHECK(entity_type IN ('INVOICE', 'EXPENSE', 'PAYMENT', 'CHALLAN', 'RETURN')) NOT NULL,
                entity_id INTEGER NOT NULL,
                file_path TEXT NOT NULL,
                file_name TEXT,
                file_type TEXT,
                description TEXT,
                uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Amendment Entries (do not edit original - create adjustment)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS amendment_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                original_entity_type TEXT NOT NULL,
                original_entity_id INTEGER NOT NULL,
                amendment_type TEXT CHECK(amendment_type IN ('CORRECTION', 'REVERSAL', 'SUPPLEMENTARY')) NOT NULL,
                amendment_date DATE NOT NULL,
                reason TEXT NOT NULL,
                voucher_number TEXT,
                ledger_transaction_id INTEGER REFERENCES ledger_transactions(id),
                created_by TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Voucher Traceability (invoice -> ledger -> return -> payment)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS voucher_traceability (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                voucher_type TEXT NOT NULL,
                voucher_id INTEGER NOT NULL,
                voucher_number TEXT,
                ledger_transaction_ids TEXT,
                gst_return_id INTEGER REFERENCES gst_return_filed(id),
                payment_id INTEGER,
                trace_hash TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Fixed assets - add rate for depreciation
        try:
            conn.execute("ALTER TABLE fixed_assets ADD COLUMN depreciation_rate REAL DEFAULT 0")
        except sqlite3.OperationalError:
            pass

        # Capital movement tracking
        conn.execute("""
            CREATE TABLE IF NOT EXISTS capital_movement (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                movement_date DATE NOT NULL,
                movement_type TEXT CHECK(movement_type IN ('OPENING', 'ADDITION', 'DRAWINGS', 'PROFIT', 'LOSS', 'CLOSING')) NOT NULL,
                ledger_id INTEGER REFERENCES ledgers(id),
                amount REAL NOT NULL,
                narration TEXT,
                voucher_id INTEGER,
                voucher_type TEXT,
                financial_year_id INTEGER REFERENCES financial_years(id),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Related party transactions (ITR)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS related_party_transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                transaction_date DATE NOT NULL,
                party_ledger_id INTEGER REFERENCES ledgers(id),
                transaction_type TEXT,
                amount REAL NOT NULL,
                description TEXT,
                reference_id INTEGER,
                reference_type TEXT,
                financial_year_id INTEGER REFERENCES financial_years(id),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        conn.commit()
        print("Migration 2026_02_21_statutory_compliance completed successfully")
    finally:
        conn.close()


if __name__ == "__main__":
    run()
