"""
GST Billing Backend - Database Helper
Handles SQLite database connections and operations
"""

import sqlite3
import os
from contextlib import contextmanager
from typing import Optional, List, Dict, Any
from datetime import datetime, date

DATABASE_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'gst_billing.db')
SCHEMA_PATH = os.path.join(os.path.dirname(__file__), 'schema.sql')


def ensure_data_directory():
    """Ensure the data directory exists"""
    data_dir = os.path.dirname(DATABASE_PATH)
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)


def dict_factory(cursor, row):
    """Convert SQLite rows to dictionaries"""
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d


@contextmanager
def get_db_connection():
    """Context manager for database connections"""
    ensure_data_directory()
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = dict_factory
    conn.execute("PRAGMA foreign_keys = ON")
    try:
        yield conn
    finally:
        conn.close()


def init_database():
    """Initialize the database with the schema"""
    ensure_data_directory()
    
    if os.path.exists(SCHEMA_PATH):
        with open(SCHEMA_PATH, 'r') as f:
            schema_sql = f.read()
        
        with get_db_connection() as conn:
            conn.executescript(schema_sql)
            conn.commit()
        print(f"Database initialized at: {DATABASE_PATH}")
    else:
        print(f"Schema file not found: {SCHEMA_PATH}")


class DatabaseHelper:
    """Helper class for common database operations"""
    
    @staticmethod
    def execute_query(query: str, params: tuple = ()) -> List[Dict[str, Any]]:
        """Execute a SELECT query and return results"""
        with get_db_connection() as conn:
            cursor = conn.execute(query, params)
            return cursor.fetchall()
    
    @staticmethod
    def execute_one(query: str, params: tuple = ()) -> Optional[Dict[str, Any]]:
        """Execute a SELECT query and return single result"""
        with get_db_connection() as conn:
            cursor = conn.execute(query, params)
            return cursor.fetchone()
    
    @staticmethod
    def execute_insert(query: str, params: tuple = ()) -> int:
        """Execute an INSERT query and return the last row id"""
        with get_db_connection() as conn:
            cursor = conn.execute(query, params)
            conn.commit()
            return cursor.lastrowid
    
    @staticmethod
    def execute_update(query: str, params: tuple = ()) -> int:
        """Execute an UPDATE query and return affected rows"""
        with get_db_connection() as conn:
            cursor = conn.execute(query, params)
            conn.commit()
            return cursor.rowcount
    
    @staticmethod
    def execute_many(query: str, params_list: List[tuple]) -> int:
        """Execute multiple queries with different parameters"""
        with get_db_connection() as conn:
            cursor = conn.executemany(query, params_list)
            conn.commit()
            return cursor.rowcount
    
    @staticmethod
    def execute_transaction(queries: List[tuple]) -> bool:
        """Execute multiple queries as a single transaction"""
        with get_db_connection() as conn:
            try:
                for query, params in queries:
                    conn.execute(query, params)
                conn.commit()
                return True
            except Exception as e:
                conn.rollback()
                raise e


class FinancialYearHelper:
    """Helper for financial year operations"""
    
    @staticmethod
    def get_current_fy() -> Dict[str, Any]:
        """Get the current financial year based on today's date"""
        today = date.today()
        # Indian FY: April 1 to March 31
        if today.month >= 4:
            fy_start = date(today.year, 4, 1)
            fy_end = date(today.year + 1, 3, 31)
        else:
            fy_start = date(today.year - 1, 4, 1)
            fy_end = date(today.year, 3, 31)
        
        fy_name = f"FY {fy_start.year}-{str(fy_end.year)[2:]}"
        
        return {
            'name': fy_name,
            'start_date': fy_start.isoformat(),
            'end_date': fy_end.isoformat()
        }
    
    @staticmethod
    def ensure_current_fy() -> int:
        """Ensure current financial year exists and return its ID"""
        fy = FinancialYearHelper.get_current_fy()
        
        existing = DatabaseHelper.execute_one(
            "SELECT id FROM financial_years WHERE start_date = ? AND end_date = ?",
            (fy['start_date'], fy['end_date'])
        )
        
        if existing:
            return existing['id']
        
        # Create new financial year
        return DatabaseHelper.execute_insert(
            "INSERT INTO financial_years (name, start_date, end_date, is_active) VALUES (?, ?, ?, 1)",
            (fy['name'], fy['start_date'], fy['end_date'])
        )
    
    @staticmethod
    def get_active_fy() -> Optional[Dict[str, Any]]:
        """Get the active financial year"""
        return DatabaseHelper.execute_one(
            "SELECT * FROM financial_years WHERE is_active = 1"
        )


class InvoiceNumberGenerator:
    """Generate sequential invoice numbers"""
    
    @staticmethod
    def get_next_number(voucher_type_id: int, financial_year_id: int) -> str:
        """Get the next invoice number for a voucher type"""
        voucher_type = DatabaseHelper.execute_one(
            "SELECT * FROM voucher_types WHERE id = ?",
            (voucher_type_id,)
        )
        
        if not voucher_type:
            raise ValueError(f"Voucher type {voucher_type_id} not found")
        
        # Get the last invoice number for this type and FY
        last_invoice = DatabaseHelper.execute_one(
            """SELECT invoice_number FROM invoices 
               WHERE voucher_type_id = ? AND financial_year_id = ?
               ORDER BY id DESC LIMIT 1""",
            (voucher_type_id, financial_year_id)
        )
        
        prefix = voucher_type.get('prefix', '')
        
        if last_invoice and last_invoice['invoice_number']:
            # Extract number from last invoice
            last_num_str = last_invoice['invoice_number'].replace(prefix, '')
            try:
                last_num = int(last_num_str)
                next_num = last_num + 1
            except ValueError:
                next_num = voucher_type.get('starting_number', 1)
        else:
            next_num = voucher_type.get('starting_number', 1)
        
        # Format: INV/2025-26/00001
        fy = DatabaseHelper.execute_one(
            "SELECT * FROM financial_years WHERE id = ?",
            (financial_year_id,)
        )
        fy_suffix = ""
        if fy:
            start_year = fy['start_date'][:4]
            end_year = fy['end_date'][:4][2:]
            fy_suffix = f"{start_year}-{end_year}/"
        
        return f"{prefix}{fy_suffix}{next_num:05d}"


class AuditLogger:
    """Audit trail logging"""
    
    @staticmethod
    def log(table_name: str, record_id: int, action: str, 
            old_values: str = None, new_values: str = None,
            changed_by: str = None, reason: str = None):
        """Log an audit entry"""
        DatabaseHelper.execute_insert(
            """INSERT INTO audit_log 
               (table_name, record_id, action, old_values, new_values, changed_by, reason)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (table_name, record_id, action, old_values, new_values, changed_by, reason)
        )


if __name__ == "__main__":
    # Initialize database when run directly
    init_database()
    print("Database setup complete!")
