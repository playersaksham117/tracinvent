"""
Migration: add parties/firm master tables with validation and audit trail
"""

import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parents[1] / "data" / "gst_billing.db"


def run():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.execute("PRAGMA foreign_keys = ON")
        conn.executescript(
            """
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

            CREATE TABLE IF NOT EXISTS party_documents (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                party_id INTEGER NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
                document_type TEXT CHECK(document_type IN ('ID_PROOF', 'ADDRESS_PROOF', 'TAX_CERT', 'BANK_MANDATE', 'CONTRACT', 'OTHER')),
                file_path TEXT,
                file_name TEXT,
                uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """
        )
        conn.commit()
        print("Party tables migration applied.")
    finally:
        conn.close()


if __name__ == "__main__":
    run()
