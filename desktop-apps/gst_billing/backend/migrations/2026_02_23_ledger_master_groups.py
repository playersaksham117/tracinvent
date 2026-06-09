"""
Migration: Professional Ledger Master Groups + Controls

Creates/ensures predefined master ledger groups:

Assets: Cash, Bank, Sundry Debtors, Loans & Advances, Stock
Liabilities: Sundry Creditors, Duties & Taxes, Secured Loans, Unsecured Loans
Capital: Capital Account, Drawings
Income: Sales, Other Income
Expenses: Direct Expenses, Indirect Expenses

Also adds DB-level controls:
- Prevent ledger deletion if transactions exist
- Prevent ledger regrouping (ledger_group_id change) if transactions exist
"""

import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parents[1] / "data" / "gst_billing.db"


def _get_group_id(conn: sqlite3.Connection, name: str):
    row = conn.execute("SELECT id FROM ledger_groups WHERE name = ?", (name,)).fetchone()
    return row[0] if row else None


def _ensure_group(conn: sqlite3.Connection, name: str, nature: str, parent_name: str | None = None):
    conn.execute(
        "INSERT OR IGNORE INTO ledger_groups (name, nature, is_system_group) VALUES (?, ?, 1)",
        (name, nature),
    )
    if parent_name:
        gid = _get_group_id(conn, name)
        pid = _get_group_id(conn, parent_name)
        if gid and pid:
            conn.execute("UPDATE ledger_groups SET parent_id = ? WHERE id = ?", (pid, gid))


def run():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.execute("PRAGMA foreign_keys = ON")

        # --- Assets ---
        _ensure_group(conn, "Cash", "ASSETS", parent_name="Cash-in-Hand")
        _ensure_group(conn, "Bank", "ASSETS", parent_name="Bank Accounts")
        _ensure_group(conn, "Sundry Debtors", "ASSETS")
        _ensure_group(conn, "Loans & Advances (Asset)", "ASSETS")
        _ensure_group(conn, "Stock", "ASSETS", parent_name="Current Assets")

        # --- Liabilities ---
        _ensure_group(conn, "Sundry Creditors", "LIABILITIES")
        _ensure_group(conn, "Duties & Taxes", "LIABILITIES")
        _ensure_group(conn, "Secured Loans", "LIABILITIES", parent_name="Loans (Liability)")
        _ensure_group(conn, "Unsecured Loans", "LIABILITIES", parent_name="Loans (Liability)")

        # --- Capital (modelled under LIABILITIES in this schema) ---
        _ensure_group(conn, "Capital Account", "LIABILITIES")
        _ensure_group(conn, "Drawings", "LIABILITIES", parent_name="Capital Account")

        # --- Income ---
        _ensure_group(conn, "Sales", "INCOME", parent_name="Sales Accounts")
        _ensure_group(conn, "Other Income", "INCOME", parent_name="Indirect Income")

        # --- Expenses ---
        _ensure_group(conn, "Direct Expenses", "EXPENSES")
        _ensure_group(conn, "Indirect Expenses", "EXPENSES")

        # --- Controls: prevent deletion/regrouping after transactions ---
        conn.executescript(
            """
            CREATE TRIGGER IF NOT EXISTS prevent_ledger_delete_with_transactions
            BEFORE DELETE ON ledgers
            BEGIN
                SELECT
                    CASE
                        WHEN EXISTS (SELECT 1 FROM ledger_transactions WHERE ledger_id = OLD.id)
                             OR EXISTS (SELECT 1 FROM invoices WHERE party_id = OLD.id)
                             OR EXISTS (SELECT 1 FROM payment_receipts WHERE party_id = OLD.id)
                        THEN RAISE(ABORT, 'Ledger deletion not allowed after transactions.')
                    END;
            END;

            CREATE TRIGGER IF NOT EXISTS prevent_ledger_regroup_with_transactions
            BEFORE UPDATE OF ledger_group_id ON ledgers
            BEGIN
                SELECT
                    CASE
                        WHEN NEW.ledger_group_id != OLD.ledger_group_id
                             AND (
                               EXISTS (SELECT 1 FROM ledger_transactions WHERE ledger_id = OLD.id)
                               OR EXISTS (SELECT 1 FROM invoices WHERE party_id = OLD.id)
                             )
                        THEN RAISE(ABORT, 'Ledger regrouping not allowed after transactions.')
                    END;
            END;
            """
        )

        conn.commit()
        print("Migration 2026_02_23_ledger_master_groups completed successfully")
    finally:
        conn.close()


if __name__ == "__main__":
    run()

