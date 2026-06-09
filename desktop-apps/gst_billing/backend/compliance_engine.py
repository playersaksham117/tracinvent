"""
Statutory Compliance Engine
- Year locking (no edit after audit)
- Filed data protection (immutable)
- Amendment flow only
- Trial balance, P&L, Balance sheet
- Books of accounts
- GSTR-1, GSTR-3B
- ITC tracking, mismatch alerts
- CA export
"""

from datetime import date, datetime
from typing import Optional, List, Dict, Any
from decimal import Decimal

from database.db_helper import DatabaseHelper


class ComplianceError(Exception):
    """Raised when compliance rules are violated"""
    pass


def is_year_locked(financial_year_id: int) -> bool:
    """Check if financial year is locked (no edits allowed)"""
    row = DatabaseHelper.execute_one(
        "SELECT is_locked FROM financial_years WHERE id = ?",
        (financial_year_id,)
    )
    return row and (row.get('is_locked') or 0) == 1


def is_invoice_filed(invoice_id: int) -> bool:
    """Check if invoice is filed in GSTR-1 (immutable)"""
    row = DatabaseHelper.execute_one(
        "SELECT gstr1_filed FROM invoices WHERE id = ?",
        (invoice_id,)
    )
    return row and (row.get('gstr1_filed') or 0) == 1


def check_edit_allowed(entity_type: str, entity_id: int, financial_year_id: Optional[int] = None) -> None:
    """
    Raise ComplianceError if edit is not allowed.
    Entity: invoice, ledger_transaction, expense, etc.
    """
    if financial_year_id and is_year_locked(financial_year_id):
        raise ComplianceError("Financial year is locked. No edits allowed. Use amendment entries only.")

    if entity_type == 'invoice' and is_invoice_filed(entity_id):
        raise ComplianceError("Invoice is filed in GSTR-1. Cannot edit. Create amendment entry instead.")


# ============================================================================
# ITR REPORTS
# ============================================================================

def get_trial_balance(from_date: date, to_date: date, financial_year_id: Optional[int] = None) -> Dict:
    """Trial Balance - All ledgers with Dr/Cr totals. CA uses this to verify correctness."""
    fy_filter = " AND lt.financial_year_id = ?" if financial_year_id else ""
    params = [from_date.isoformat(), to_date.isoformat()]
    if financial_year_id:
        params.append(financial_year_id)

    rows = DatabaseHelper.execute_query(
        f"""SELECT l.id, l.name, lg.name as group_name, lg.nature,
            COALESCE(SUM(lt.debit_amount), 0) as total_debit,
            COALESCE(SUM(lt.credit_amount), 0) as total_credit,
            l.opening_balance, l.balance_type
           FROM ledgers l
           JOIN ledger_groups lg ON l.ledger_group_id = lg.id
           LEFT JOIN ledger_transactions lt ON lt.ledger_id = l.id
               AND lt.transaction_date BETWEEN ? AND ?
               AND lt.is_opening_balance = 0 {fy_filter}
           GROUP BY l.id
           ORDER BY lg.name, l.name""",
        tuple(params)
    )

    total_dr = sum(float(r.get('total_debit', 0) or 0) for r in rows)
    total_cr = sum(float(r.get('total_credit', 0) or 0) for r in rows)

    return {
        "from_date": from_date.isoformat(),
        "to_date": to_date.isoformat(),
        "ledgers": rows,
        "total_debit": total_dr,
        "total_credit": total_cr,
        "balanced": abs(total_dr - total_cr) < 0.01,
    }


def get_profit_loss(from_date: date, to_date: date, financial_year_id: Optional[int] = None) -> Dict:
    """P&L: Sales/revenue, Other income, Direct expenses, Gross profit, Indirect expenses, Net profit"""
    fy_filter = " AND lt.financial_year_id = ?" if financial_year_id else ""
    params = [from_date.isoformat(), to_date.isoformat()]
    if financial_year_id:
        params.append(financial_year_id)

    # Direct Income (Sales)
    direct_income = DatabaseHelper.execute_query(
        f"""SELECT l.name, COALESCE(SUM(lt.credit_amount - lt.debit_amount), 0) as amount
           FROM ledgers l
           JOIN ledger_groups lg ON l.ledger_group_id = lg.id
           LEFT JOIN ledger_transactions lt ON lt.ledger_id = l.id
               AND lt.transaction_date BETWEEN ? AND ? AND lt.is_opening_balance = 0 {fy_filter}
           WHERE lg.name LIKE '%Sales%' OR lg.name LIKE '%Direct Income%'
           GROUP BY l.id HAVING amount != 0""",
        tuple(params)
    )

    # Other/Indirect Income
    other_income = DatabaseHelper.execute_query(
        f"""SELECT l.name, COALESCE(SUM(lt.credit_amount - lt.debit_amount), 0) as amount
           FROM ledgers l
           JOIN ledger_groups lg ON l.ledger_group_id = lg.id
           LEFT JOIN ledger_transactions lt ON lt.ledger_id = l.id
               AND lt.transaction_date BETWEEN ? AND ? AND lt.is_opening_balance = 0 {fy_filter}
           WHERE lg.name LIKE '%Indirect Income%' OR lg.name = 'Indirect Income'
           GROUP BY l.id HAVING amount != 0""",
        tuple(params)
    )

    # Direct Expenses
    direct_expenses = DatabaseHelper.execute_query(
        f"""SELECT l.name, COALESCE(SUM(lt.debit_amount - lt.credit_amount), 0) as amount
           FROM ledgers l
           JOIN ledger_groups lg ON l.ledger_group_id = lg.id
           LEFT JOIN ledger_transactions lt ON lt.ledger_id = l.id
               AND lt.transaction_date BETWEEN ? AND ? AND lt.is_opening_balance = 0 {fy_filter}
           WHERE lg.name IN ('Direct Expenses', 'Purchase Accounts')
           GROUP BY l.id HAVING amount != 0""",
        tuple(params)
    )

    # Indirect Expenses
    indirect_expenses = DatabaseHelper.execute_query(
        f"""SELECT l.name, COALESCE(SUM(lt.debit_amount - lt.credit_amount), 0) as amount
           FROM ledgers l
           JOIN ledger_groups lg ON l.ledger_group_id = lg.id
           LEFT JOIN ledger_transactions lt ON lt.ledger_id = l.id
               AND lt.transaction_date BETWEEN ? AND ? AND lt.is_opening_balance = 0 {fy_filter}
           WHERE lg.name = 'Indirect Expenses'
           GROUP BY l.id HAVING amount != 0""",
        tuple(params)
    )

    total_revenue = sum(float(r.get('amount', 0) or 0) for r in direct_income)
    total_other_income = sum(float(r.get('amount', 0) or 0) for r in other_income)
    total_direct_exp = sum(float(r.get('amount', 0) or 0) for r in direct_expenses)
    total_indirect_exp = sum(float(r.get('amount', 0) or 0) for r in indirect_expenses)

    gross_profit = total_revenue - total_direct_exp
    net_profit = gross_profit + total_other_income - total_indirect_exp

    return {
        "from_date": from_date.isoformat(),
        "to_date": to_date.isoformat(),
        "sales_revenue": direct_income,
        "other_income": other_income,
        "direct_expenses": direct_expenses,
        "indirect_expenses": indirect_expenses,
        "total_revenue": total_revenue,
        "total_other_income": total_other_income,
        "total_direct_expenses": total_direct_exp,
        "total_indirect_expenses": total_indirect_exp,
        "gross_profit": gross_profit,
        "net_profit": net_profit,
    }


def get_balance_sheet(as_on_date: date, financial_year_id: Optional[int] = None) -> Dict:
    """Balance Sheet: Assets (FA, Inventory, Receivables, Cash, Bank, Loans given),
       Liabilities (Payables, Loans, Outstanding expenses, Capital)"""
    assets = DatabaseHelper.execute_query(
        """SELECT lg.name as group_name, l.name, l.current_balance, l.balance_type
           FROM ledgers l
           JOIN ledger_groups lg ON l.ledger_group_id = lg.id
           WHERE lg.nature = 'ASSETS' AND l.current_balance != 0
           ORDER BY lg.name, l.name"""
    )

    liabilities = DatabaseHelper.execute_query(
        """SELECT lg.name as group_name, l.name, l.current_balance, l.balance_type
           FROM ledgers l
           JOIN ledger_groups lg ON l.ledger_group_id = lg.id
           WHERE lg.nature = 'LIABILITIES' AND l.current_balance != 0
           ORDER BY lg.name, l.name"""
    )

    capital = DatabaseHelper.execute_query(
        """SELECT l.name, l.current_balance, l.balance_type
           FROM ledgers l
           JOIN ledger_groups lg ON l.ledger_group_id = lg.id
           WHERE lg.name = 'Capital Account'
           ORDER BY l.name"""
    )

    return {
        "as_on_date": as_on_date.isoformat(),
        "assets": assets,
        "liabilities": liabilities,
        "capital": capital,
    }


def get_capital_movement(from_date: date, to_date: date, financial_year_id: Optional[int] = None) -> Dict:
    """Capital movement: Opening, Add profit, Less drawings, Closing"""
    if not _table_exists("capital_movement"):
        return {"movements": [], "from_date": from_date.isoformat(), "to_date": to_date.isoformat()}

    params = [from_date.isoformat(), to_date.isoformat()]
    if financial_year_id:
        params.append(financial_year_id)
    q = "SELECT * FROM capital_movement WHERE movement_date BETWEEN ? AND ?"
    if financial_year_id:
        q += " AND financial_year_id = ?"
    q += " ORDER BY movement_date"
    rows = DatabaseHelper.execute_query(q, tuple(params))
    return {"movements": rows, "from_date": from_date.isoformat(), "to_date": to_date.isoformat()}


def get_turnover_summary(from_date: date, to_date: date) -> Dict:
    """Turnover summary for ITR"""
    r = DatabaseHelper.execute_one(
        """SELECT COALESCE(SUM(grand_total), 0) as total_turnover, COUNT(*) as invoice_count
           FROM invoices WHERE status = 'CONFIRMED' AND is_deleted = 0
           AND invoice_date BETWEEN ? AND ?""",
        (from_date.isoformat(), to_date.isoformat())
    )
    return r or {"total_turnover": 0, "invoice_count": 0}


def get_related_party_transactions(from_date: date, to_date: date) -> List:
    """Related party transactions for ITR"""
    if not _table_exists("related_party_transactions"):
        return []
    return DatabaseHelper.execute_query(
        """SELECT * FROM related_party_transactions
           WHERE transaction_date BETWEEN ? AND ?
           ORDER BY transaction_date""",
        (from_date.isoformat(), to_date.isoformat())
    )


# ============================================================================
# BOOKS OF ACCOUNTS
# ============================================================================

def get_day_book(from_date: date, to_date: date) -> List:
    """Day book - All transactions by date"""
    return DatabaseHelper.execute_query(
        """SELECT lt.transaction_date, lt.voucher_number, vt.name as voucher_type,
            l.name as ledger, lt.debit_amount, lt.credit_amount, lt.narration
           FROM ledger_transactions lt
           LEFT JOIN voucher_types vt ON vt.id = lt.voucher_type_id
           JOIN ledgers l ON l.id = lt.ledger_id
           WHERE lt.transaction_date BETWEEN ? AND ? AND lt.is_opening_balance = 0
           ORDER BY lt.transaction_date, lt.id""",
        (from_date.isoformat(), to_date.isoformat())
    )


def get_cash_book(from_date: date, to_date: date) -> List:
    """Cash book - Cash ledger transactions"""
    cash_group = DatabaseHelper.execute_one("SELECT id FROM ledger_groups WHERE name = 'Cash-in-Hand'")
    if not cash_group:
        return []
    return DatabaseHelper.execute_query(
        """SELECT lt.transaction_date, lt.voucher_number, l.name, lt.debit_amount, lt.credit_amount, lt.narration
           FROM ledger_transactions lt
           JOIN ledgers l ON l.id = lt.ledger_id
           WHERE l.ledger_group_id = ? AND lt.transaction_date BETWEEN ? AND ? AND lt.is_opening_balance = 0
           ORDER BY lt.transaction_date""",
        (cash_group['id'], from_date.isoformat(), to_date.isoformat())
    )


def get_bank_book(from_date: date, to_date: date) -> List:
    """Bank book - Bank ledger transactions"""
    bank_group = DatabaseHelper.execute_one("SELECT id FROM ledger_groups WHERE name = 'Bank Accounts'")
    if not bank_group:
        return []
    return DatabaseHelper.execute_query(
        """SELECT lt.transaction_date, lt.voucher_number, l.name, lt.debit_amount, lt.credit_amount, lt.narration
           FROM ledger_transactions lt
           JOIN ledgers l ON l.id = lt.ledger_id
           WHERE l.ledger_group_id = ? AND lt.transaction_date BETWEEN ? AND ? AND lt.is_opening_balance = 0
           ORDER BY lt.transaction_date""",
        (bank_group['id'], from_date.isoformat(), to_date.isoformat())
    )


def get_sales_register(from_date: date, to_date: date) -> List:
    """Sales register"""
    return DatabaseHelper.execute_query(
        """SELECT i.invoice_number, i.invoice_date, i.party_name, i.party_gstin,
            i.taxable_amount, i.cgst_amount, i.sgst_amount, i.igst_amount, i.grand_total
           FROM invoices i
           WHERE i.voucher_type_id IN (SELECT id FROM voucher_types WHERE type = 'SALES')
           AND i.status = 'CONFIRMED' AND i.is_deleted = 0
           AND i.invoice_date BETWEEN ? AND ?
           ORDER BY i.invoice_date""",
        (from_date.isoformat(), to_date.isoformat())
    )


def get_purchase_register(from_date: date, to_date: date) -> List:
    """Purchase register"""
    return DatabaseHelper.execute_query(
        """SELECT i.invoice_number, i.invoice_date, i.party_name, i.party_gstin,
            i.taxable_amount, i.cgst_amount, i.sgst_amount, i.igst_amount, i.grand_total
           FROM invoices i
           WHERE i.voucher_type_id IN (SELECT id FROM voucher_types WHERE type = 'PURCHASE')
           AND i.status = 'CONFIRMED' AND i.is_deleted = 0
           AND i.invoice_date BETWEEN ? AND ?
           ORDER BY i.invoice_date""",
        (from_date.isoformat(), to_date.isoformat())
    )


def get_journal_register(from_date: date, to_date: date) -> List:
    """Journal register"""
    return DatabaseHelper.execute_query(
        """SELECT lt.voucher_number, lt.transaction_date, l.name as ledger,
            lt.debit_amount, lt.credit_amount, lt.narration
           FROM ledger_transactions lt
           JOIN ledgers l ON l.id = lt.ledger_id
           JOIN voucher_types vt ON vt.id = lt.voucher_type_id AND vt.type = 'JOURNAL'
           WHERE lt.transaction_date BETWEEN ? AND ? AND lt.is_opening_balance = 0
           ORDER BY lt.transaction_date, lt.voucher_number""",
        (from_date.isoformat(), to_date.isoformat())
    )


# ============================================================================
# GST REPORTS
# ============================================================================

def get_gstr1_data(from_date: date, to_date: date) -> Dict:
    """GSTR-1: B2B, B2C large, B2C small, Export, Credit/Debit notes, HSN summary"""
    company = DatabaseHelper.execute_one("SELECT state_code FROM company_profile LIMIT 1")
    company_state = (company or {}).get('state_code', '27')

    # B2B (with GSTIN)
    b2b = DatabaseHelper.execute_query(
        """SELECT i.*, its.hsn_code, its.taxable_amount, its.gst_rate, its.cgst_amount, its.sgst_amount, its.igst_amount
           FROM invoices i
           LEFT JOIN invoice_tax_summary its ON its.invoice_id = i.id
           WHERE i.party_gstin IS NOT NULL AND TRIM(i.party_gstin) != ''
           AND i.status = 'CONFIRMED' AND i.is_deleted = 0
           AND i.invoice_date BETWEEN ? AND ?
           AND i.voucher_type_id IN (SELECT id FROM voucher_types WHERE type IN ('SALES', 'CREDIT_NOTE'))
           ORDER BY i.invoice_date""",
        (from_date.isoformat(), to_date.isoformat())
    )

    # B2C Large (>2.5L inter-state)
    b2cl = DatabaseHelper.execute_query(
        """SELECT * FROM invoices
           WHERE (party_gstin IS NULL OR TRIM(party_gstin) = '')
           AND (place_of_supply IS NULL OR place_of_supply != ?)
           AND grand_total > 250000
           AND status = 'CONFIRMED' AND is_deleted = 0
           AND invoice_date BETWEEN ? AND ?""",
        (company_state, from_date.isoformat(), to_date.isoformat())
    )

    # B2C Small
    b2cs = DatabaseHelper.execute_query(
        """SELECT * FROM invoices
           WHERE (party_gstin IS NULL OR TRIM(party_gstin) = '')
           AND (place_of_supply = ? OR (place_of_supply IS NULL AND grand_total <= 250000))
           AND status = 'CONFIRMED' AND is_deleted = 0
           AND invoice_date BETWEEN ? AND ?
           AND voucher_type_id IN (SELECT id FROM voucher_types WHERE type IN ('SALES', 'CREDIT_NOTE'))""",
        (company_state, from_date.isoformat(), to_date.isoformat())
    )

    # Export
    export_inv = DatabaseHelper.execute_query(
        """SELECT * FROM invoices WHERE is_export = 1
           AND status = 'CONFIRMED' AND is_deleted = 0
           AND invoice_date BETWEEN ? AND ?""",
        (from_date.isoformat(), to_date.isoformat())
    )

    # HSN Summary
    hsn = DatabaseHelper.execute_query(
        """SELECT its.hsn_code, SUM(its.total_quantity) as qty, SUM(its.taxable_amount) as taxable,
            its.gst_rate, SUM(its.cgst_amount) as cgst, SUM(its.sgst_amount) as sgst,
            SUM(its.igst_amount) as igst, SUM(its.cess_amount) as cess
           FROM invoice_tax_summary its
           JOIN invoices i ON i.id = its.invoice_id
           WHERE i.status = 'CONFIRMED' AND i.is_deleted = 0
           AND i.invoice_date BETWEEN ? AND ?
           GROUP BY its.hsn_code, its.gst_rate""",
        (from_date.isoformat(), to_date.isoformat())
    )

    return {
        "b2b": b2b,
        "b2c_large": b2cl,
        "b2c_small": b2cs,
        "export": export_inv,
        "hsn_summary": hsn,
        "from_date": from_date.isoformat(),
        "to_date": to_date.isoformat(),
    }


def get_gstr3b_summary(from_date: date, to_date: date) -> Dict:
    """GSTR-3B: Outward tax, RCM, ITC, Net payable"""
    # Outward supply tax
    outward = DatabaseHelper.execute_one(
        """SELECT COALESCE(SUM(cgst_amount), 0) as cgst, COALESCE(SUM(sgst_amount), 0) as sgst,
            COALESCE(SUM(igst_amount), 0) as igst, COALESCE(SUM(cess_amount), 0) as cess,
            COALESCE(SUM(total_tax_amount), 0) as total
           FROM invoices
           WHERE status = 'CONFIRMED' AND is_deleted = 0
           AND invoice_date BETWEEN ? AND ?
           AND voucher_type_id IN (SELECT id FROM voucher_types WHERE type IN ('SALES', 'CREDIT_NOTE'))""",
        (from_date.isoformat(), to_date.isoformat())
    )

    # ITC
    itc = DatabaseHelper.execute_one(
        """SELECT COALESCE(SUM(total_gst_amount), 0) as total_itc
           FROM expenses WHERE expense_date BETWEEN ? AND ? AND itc_eligible = 1""",
        (from_date.isoformat(), to_date.isoformat())
    ) if _table_exists("expenses") else {"total_itc": 0}

    outward = outward or {"cgst": 0, "sgst": 0, "igst": 0, "cess": 0, "total": 0}
    itc_val = float((itc or {}).get("total_itc", 0))
    net_payable = float(outward.get("total", 0)) - itc_val

    return {
        "outward_tax": outward,
        "rcm_tax": 0,  # Reverse charge - to be populated from purchase RCM
        "itc_available": itc_val,
        "net_payable": max(0, net_payable),
        "from_date": from_date.isoformat(),
        "to_date": to_date.isoformat(),
    }


def get_itc_tracking(from_date: date, to_date: date) -> List:
    """ITC register with eligible/ineligible, supplier match"""
    if not _table_exists("itc_register"):
        return []
    return DatabaseHelper.execute_query(
        """SELECT * FROM itc_register
           WHERE (period_year * 100 + period_month) BETWEEN ? AND ?
           ORDER BY invoice_date""",
        (from_date.year * 100 + from_date.month, to_date.year * 100 + to_date.month)
    )


def get_mismatch_alerts(status: str = 'OPEN') -> List:
    """Compliance mismatch alerts (ITC 2B, outward, tax, bank recon)"""
    if not _table_exists("compliance_mismatch_alerts"):
        return []
    return DatabaseHelper.execute_query(
        "SELECT * FROM compliance_mismatch_alerts WHERE status = ? ORDER BY created_at DESC",
        (status,)
    )


def get_tax_payment_tracking(period_year: int, period_month: int) -> Dict:
    """Tax payment: Liability, Paid, Remaining"""
    if not _table_exists("gst_tax_payments"):
        return {}
    row = DatabaseHelper.execute_one(
        "SELECT * FROM gst_tax_payments WHERE period_year = ? AND period_month = ?",
        (period_year, period_month)
    )
    return row or {}


# ============================================================================
# CONTROLS
# ============================================================================

def lock_financial_year(fy_id: int, locked_by: str) -> bool:
    """Lock financial year - no edits allowed after this"""
    DatabaseHelper.execute_update(
        """UPDATE financial_years SET is_locked = 1, locked_at = CURRENT_TIMESTAMP, locked_by = ?
           WHERE id = ?""",
        (locked_by, fy_id)
    )
    return True


def mark_invoice_filed(invoice_id: int, arn: str = None) -> bool:
    """Mark invoice as filed in GSTR-1 - immutable"""
    DatabaseHelper.execute_update(
        """UPDATE invoices SET gstr1_filed = 1, gstr1_filed_at = CURRENT_TIMESTAMP, gstr1_arn = ?
           WHERE id = ?""",
        (arn, invoice_id)
    )
    return True


def create_amendment_entry(original_entity_type: str, original_entity_id: int,
                           amendment_type: str, reason: str, amendment_date: date) -> int:
    """Create amendment entry - do NOT edit original"""
    return DatabaseHelper.execute_insert(
        """INSERT INTO amendment_entries (original_entity_type, original_entity_id, amendment_type, amendment_date, reason)
           VALUES (?, ?, ?, ?, ?)""",
        (original_entity_type, original_entity_id, amendment_type, amendment_date.isoformat(), reason)
    )


def export_for_ca(from_date: date, to_date: date, report_types: List[str]) -> Dict:
    """Export for Chartered Accountant - Trial balance, P&L, BS, registers"""
    result = {}
    if "trial_balance" in report_types:
        result["trial_balance"] = get_trial_balance(from_date, to_date)
    if "pl" in report_types or "profit_loss" in report_types:
        result["profit_loss"] = get_profit_loss(from_date, to_date)
    if "balance_sheet" in report_types:
        result["balance_sheet"] = get_balance_sheet(to_date)
    if "day_book" in report_types:
        result["day_book"] = get_day_book(from_date, to_date)
    if "cash_book" in report_types:
        result["cash_book"] = get_cash_book(from_date, to_date)
    if "bank_book" in report_types:
        result["bank_book"] = get_bank_book(from_date, to_date)
    if "sales_register" in report_types:
        result["sales_register"] = get_sales_register(from_date, to_date)
    if "purchase_register" in report_types:
        result["purchase_register"] = get_purchase_register(from_date, to_date)
    if "journal_register" in report_types:
        result["journal_register"] = get_journal_register(from_date, to_date)
    return result


def _table_exists(name: str) -> bool:
    r = DatabaseHelper.execute_one("SELECT name FROM sqlite_master WHERE type='table' AND name=?", (name,))
    return r is not None
