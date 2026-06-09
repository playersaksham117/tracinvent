"""
Migration: Full Ledger Groups (5 Natures + Sub-Groups)

Assets, Liabilities, Capital, Income, Expenses with sub-groups per user spec.
Nature stored at group level; ledger inherits from group.
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

        # --- ASSETS ---
        _ensure_group(conn, "Cash-in-Hand", "ASSETS")
        _ensure_group(conn, "Bank Accounts", "ASSETS")
        _ensure_group(conn, "Sundry Debtors", "ASSETS")
        _ensure_group(conn, "Loans & Advances (Asset)", "ASSETS")
        _ensure_group(conn, "Input GST (CGST/SGST/IGST)", "ASSETS")
        _ensure_group(conn, "TDS Receivable", "ASSETS")
        _ensure_group(conn, "Closing Stock", "ASSETS")
        _ensure_group(conn, "Current Assets", "ASSETS")
        _ensure_group(conn, "Furniture & Fixtures", "ASSETS")
        _ensure_group(conn, "Plant & Machinery", "ASSETS")
        _ensure_group(conn, "Vehicles", "ASSETS")
        _ensure_group(conn, "Computers", "ASSETS")
        _ensure_group(conn, "Office Equipment", "ASSETS")
        _ensure_group(conn, "Fixed Assets", "ASSETS")
        _ensure_group(conn, "Investments", "ASSETS")
        _ensure_group(conn, "FDs", "ASSETS")
        _ensure_group(conn, "Shares", "ASSETS")
        _ensure_group(conn, "Mutual Funds", "ASSETS")

        # --- LIABILITIES ---
        _ensure_group(conn, "Sundry Creditors", "LIABILITIES")
        _ensure_group(conn, "Outstanding Expenses", "LIABILITIES")
        _ensure_group(conn, "GST Payable", "LIABILITIES")
        _ensure_group(conn, "TDS Payable", "LIABILITIES")
        _ensure_group(conn, "Advances from Customers", "LIABILITIES")
        _ensure_group(conn, "Provisions", "LIABILITIES")
        _ensure_group(conn, "Current Liabilities", "LIABILITIES")
        _ensure_group(conn, "Secured Loans", "LIABILITIES")
        _ensure_group(conn, "Unsecured Loans", "LIABILITIES")
        _ensure_group(conn, "Loans (Liability)", "LIABILITIES")
        _ensure_group(conn, "Duties & Taxes", "LIABILITIES")

        # --- CAPITAL (stored as LIABILITIES in schema) ---
        _ensure_group(conn, "Capital Account", "LIABILITIES")
        _ensure_group(conn, "Partner Capital", "LIABILITIES")
        _ensure_group(conn, "Share Capital", "LIABILITIES")
        _ensure_group(conn, "Reserves & Surplus", "LIABILITIES")
        _ensure_group(conn, "Drawings", "LIABILITIES")

        # --- INCOME ---
        _ensure_group(conn, "Sales", "INCOME")
        _ensure_group(conn, "Sales Accounts", "INCOME")
        _ensure_group(conn, "Service Income", "INCOME")
        _ensure_group(conn, "Other Income", "INCOME")
        _ensure_group(conn, "Interest Income", "INCOME")
        _ensure_group(conn, "Commission Income", "INCOME")
        _ensure_group(conn, "Discount Received", "INCOME")
        _ensure_group(conn, "Direct Income", "INCOME")
        _ensure_group(conn, "Indirect Income", "INCOME")

        # --- EXPENSES ---
        _ensure_group(conn, "Purchase", "EXPENSES")
        _ensure_group(conn, "Purchase Accounts", "EXPENSES")
        _ensure_group(conn, "Freight Inward", "EXPENSES")
        _ensure_group(conn, "Manufacturing Cost", "EXPENSES")
        _ensure_group(conn, "Direct Expenses", "EXPENSES")
        _ensure_group(conn, "Salary", "EXPENSES")
        _ensure_group(conn, "Rent", "EXPENSES")
        _ensure_group(conn, "Electricity", "EXPENSES")
        _ensure_group(conn, "Internet", "EXPENSES")
        _ensure_group(conn, "Office Expenses", "EXPENSES")
        _ensure_group(conn, "Marketing", "EXPENSES")
        _ensure_group(conn, "Insurance", "EXPENSES")
        _ensure_group(conn, "Bank Charges", "EXPENSES")
        _ensure_group(conn, "Depreciation", "EXPENSES")
        _ensure_group(conn, "Indirect Expenses", "EXPENSES")

        conn.commit()
        print("Migration 2026_02_26_ledger_groups_full completed successfully")
    finally:
        conn.close()


if __name__ == "__main__":
    run()
