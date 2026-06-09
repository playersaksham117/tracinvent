import json
import urllib.request

payload = {
    "item_id": 1,
    "movement": "PURCHASE_IN",
    "quantity": 2,
    "rate": 1000,
    "batch_number": "BATCH-CRM-1",
    "manufacturing_date": "2025-12-01",
    "expiry_date": "2027-12-01",
    "serial_numbers": ["CRM001-A", "CRM001-B"],
    "narration": "Test purchase batch/serial",
}

req = urllib.request.Request(
    "http://127.0.0.1:8000/api/inventory/movements",
    data=json.dumps(payload).encode("utf-8"),
    headers={"Content-Type": "application/json"},
    method="POST",
)

with urllib.request.urlopen(req, timeout=10) as resp:
    print(resp.read().decode("utf-8"))
