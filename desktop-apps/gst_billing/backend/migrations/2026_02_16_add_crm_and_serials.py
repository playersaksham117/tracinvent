import os
import sqlite3

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'gst_billing.db')

SQL = """
CREATE TABLE IF NOT EXISTS item_serials (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id INTEGER NOT NULL REFERENCES items(id),
    batch_id INTEGER REFERENCES item_batches(id),
    serial_number TEXT NOT NULL,
    status TEXT CHECK(status IN ('IN_STOCK','OUT','DAMAGED','TRANSFERRED','ADJUSTED_OUT')) DEFAULT 'IN_STOCK',
    reference_type TEXT,
    reference_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(item_id, serial_number)
);
CREATE INDEX IF NOT EXISTS idx_item_serials_item ON item_serials(item_id);
CREATE INDEX IF NOT EXISTS idx_item_serials_status ON item_serials(status);
CREATE TABLE IF NOT EXISTS inventory_transaction_serials (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    inventory_transaction_id INTEGER NOT NULL REFERENCES inventory_transactions(id) ON DELETE CASCADE,
    serial_id INTEGER NOT NULL REFERENCES item_serials(id)
);
CREATE TABLE IF NOT EXISTS crm_staff (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS crm_pipeline_stages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    sort_order INTEGER DEFAULT 0,
    is_won INTEGER DEFAULT 0,
    is_lost INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1
);
INSERT OR IGNORE INTO crm_pipeline_stages (name, sort_order, is_won, is_lost) VALUES
('New', 1, 0, 0),
('Qualified', 2, 0, 0),
('Proposal', 3, 0, 0),
('Negotiation', 4, 0, 0),
('Won', 5, 1, 0),
('Lost', 6, 0, 1);
CREATE TABLE IF NOT EXISTS crm_leads (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    company_name TEXT,
    phone TEXT,
    email TEXT,
    gstin TEXT,
    source TEXT,
    status TEXT DEFAULT 'New',
    pipeline_stage_id INTEGER REFERENCES crm_pipeline_stages(id),
    assigned_staff_id INTEGER REFERENCES crm_staff(id),
    credit_limit REAL DEFAULT 0,
    expected_value REAL DEFAULT 0,
    notes TEXT,
    next_followup_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS crm_lead_notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lead_id INTEGER NOT NULL REFERENCES crm_leads(id) ON DELETE CASCADE,
    note TEXT NOT NULL,
    created_by TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS crm_call_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lead_id INTEGER NOT NULL REFERENCES crm_leads(id) ON DELETE CASCADE,
    call_type TEXT CHECK(call_type IN ('INBOUND','OUTBOUND')) DEFAULT 'OUTBOUND',
    outcome TEXT,
    duration_seconds INTEGER DEFAULT 0,
    notes TEXT,
    created_by TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS crm_followups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lead_id INTEGER NOT NULL REFERENCES crm_leads(id) ON DELETE CASCADE,
    followup_date DATE NOT NULL,
    reminder_time TEXT,
    status TEXT DEFAULT 'PENDING',
    notes TEXT,
    created_by TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"""


def main() -> None:
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.executescript(SQL)
        count = conn.execute("SELECT COUNT(*) FROM crm_staff").fetchone()[0]
        if count == 0:
            conn.executemany(
                "INSERT INTO crm_staff (name, email, phone) VALUES (?, ?, ?)",
                [
                    ("Aarav Shah", "aarav@billease.local", "9000000001"),
                    ("Isha Verma", "isha@billease.local", "9000000002"),
                    ("Neel Kapoor", "neel@billease.local", "9000000003"),
                ],
            )
        conn.commit()
        print("Migration applied")
    finally:
        conn.close()


if __name__ == '__main__':
    main()
