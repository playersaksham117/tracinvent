"""
Migration: add expenses and other income tables
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
            """
        )
        conn.commit()
        print("Expense tables migration applied.")
    finally:
        conn.close()


if __name__ == "__main__":
    run()
