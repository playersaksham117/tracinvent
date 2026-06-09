import sqlite3

DB_PATH = r"e:/Vyoumix/BillEase Suite/desktop-apps/gst_billing/backend/data/gst_billing.db"


def main() -> None:
    conn = sqlite3.connect(DB_PATH)
    try:
        row = conn.execute("SELECT id, name, sku FROM items WHERE sku = ?", ("CRM-001",)).fetchone()
        print(row)
    finally:
        conn.close()


if __name__ == '__main__':
    main()
