"""
Migration: Hierarchical Ledger Groups (Nature > Sub-Group > Group)

Sets parent_id to build hierarchy per user spec:
- Assets: Current Assets, Fixed Assets, Investments (each with children)
- Liabilities: Current Liabilities, Loans (each with children)
- Capital: Capital Account, Partner Capital, Share Capital, Reserves & Surplus, Drawings
- Income: Sales, Service Income, Other Income, etc.
- Expenses: Direct Expenses, Indirect Expenses (each with children)
"""

import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parents[1] / "data" / "gst_billing.db"


def _get_group_id(conn: sqlite3.Connection, name: str):
    row = conn.execute("SELECT id FROM ledger_groups WHERE name = ?", (name,)).fetchone()
    return row[0] if row else None


def _set_parent(conn: sqlite3.Connection, child_name: str, parent_name: str):
    cid = _get_group_id(conn, child_name)
    pid = _get_group_id(conn, parent_name)
    if cid and pid:
        conn.execute("UPDATE ledger_groups SET parent_id = ? WHERE id = ?", (pid, cid))


def run():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.execute("PRAGMA foreign_keys = ON")

        # --- ASSETS: Current Assets (parent) ---
        _set_parent(conn, "Cash-in-Hand", "Current Assets")
        _set_parent(conn, "Bank Accounts", "Current Assets")
        _set_parent(conn, "Sundry Debtors", "Current Assets")
        _set_parent(conn, "Loans & Advances (Asset)", "Current Assets")
        _set_parent(conn, "Input GST (CGST/SGST/IGST)", "Current Assets")
        _set_parent(conn, "TDS Receivable", "Current Assets")
        _set_parent(conn, "Closing Stock", "Current Assets")

        # --- ASSETS: Fixed Assets (parent) ---
        _set_parent(conn, "Furniture & Fixtures", "Fixed Assets")
        _set_parent(conn, "Plant & Machinery", "Fixed Assets")
        _set_parent(conn, "Vehicles", "Fixed Assets")
        _set_parent(conn, "Computers", "Fixed Assets")
        _set_parent(conn, "Office Equipment", "Fixed Assets")

        # --- ASSETS: Investments (parent) ---
        _set_parent(conn, "FDs", "Investments")
        _set_parent(conn, "Shares", "Investments")
        _set_parent(conn, "Mutual Funds", "Investments")

        # --- LIABILITIES: Current Liabilities (parent) ---
        _set_parent(conn, "Sundry Creditors", "Current Liabilities")
        _set_parent(conn, "Outstanding Expenses", "Current Liabilities")
        _set_parent(conn, "GST Payable", "Current Liabilities")
        _set_parent(conn, "TDS Payable", "Current Liabilities")
        _set_parent(conn, "Advances from Customers", "Current Liabilities")
        _set_parent(conn, "Provisions", "Current Liabilities")

        # --- LIABILITIES: Loans (parent) - use Loans (Liability) as parent ---
        _set_parent(conn, "Secured Loans", "Loans (Liability)")
        _set_parent(conn, "Unsecured Loans", "Loans (Liability)")

        # --- EXPENSES: Direct Expenses (parent) ---
        _set_parent(conn, "Purchase", "Direct Expenses")
        _set_parent(conn, "Freight Inward", "Direct Expenses")
        _set_parent(conn, "Manufacturing Cost", "Direct Expenses")

        # --- EXPENSES: Indirect Expenses (parent) ---
        _set_parent(conn, "Salary", "Indirect Expenses")
        _set_parent(conn, "Rent", "Indirect Expenses")
        _set_parent(conn, "Electricity", "Indirect Expenses")
        _set_parent(conn, "Internet", "Indirect Expenses")
        _set_parent(conn, "Office Expenses", "Indirect Expenses")
        _set_parent(conn, "Marketing", "Indirect Expenses")
        _set_parent(conn, "Insurance", "Indirect Expenses")
        _set_parent(conn, "Bank Charges", "Indirect Expenses")
        _set_parent(conn, "Depreciation", "Indirect Expenses")

        conn.commit()
        print("Migration 2026_02_27_ledger_hierarchy completed successfully")
    finally:
        conn.close()


if __name__ == "__main__":
    run()
