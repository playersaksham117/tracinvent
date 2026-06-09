"""
GST Billing Backend - FastAPI Main Application
RESTful API for GST Billing & Accounting System
"""

from fastapi import FastAPI, HTTPException, Query, Depends
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
from datetime import date, datetime, timedelta
from decimal import Decimal
import json

from models import (
    CompanyProfile, CompanyProfileCreate,
    Ledger, LedgerCreate, LedgerUpdate,
    Item, ItemCreate, ItemUpdate, ItemSearch,
    HSNCode, HSNCodeCreate,
    GSTInvoice, GSTInvoiceCreate, GSTInvoiceUpdate,
    InvoiceItem, InvoiceItemCreate,
    TaxSummary, StockSummary, InventoryAdjustment,
    ItemBatch, ItemBatchCreate, ItemSerial,
    StockMovementCreate, StockMovementRecord,
    State, APIResponse, PaginatedResponse,
    CRMStaff, CRMStaffCreate, CRMStaffUpdate, CRMPipelineStage,
    CRMLead, CRMLeadCreate, CRMLeadUpdate,
    CRMNoteCreate, CRMCallCreate,
    CRMFollowUp, CRMFollowUpCreate,
    CRMCustomerRisk,
    ExpenseCategory, ExpenseCategoryCreate,
    ExpenseEntry, ExpenseEntryCreate,
    ExpenseAttachment, ExpenseAttachmentCreate,
    ExpenseRecurring, ExpenseRecurringCreate,
    OtherIncome, OtherIncomeCreate,
    Party, PartyCreate, PartyUpdate, PartyChangeLog,
    PaymentMode, PaymentStatus, InvoiceStatus, DiscountType,
    ProductImportRequest, ProductImportResult, ProductImportError, ProductImportItem
)
from database.db_helper import (
    DatabaseHelper, init_database, get_db_connection,
    FinancialYearHelper, InvoiceNumberGenerator, AuditLogger
)
from gst_calculator import (
    GSTCalculator, Transaction, TransactionItem,
    DiscountType as CalcDiscountType, number_to_words_indian
)


# Initialize FastAPI app
app = FastAPI(
    title="GST Billing API",
    description="Indian GST Billing & Accounting System API",
    version="1.0.0"
)

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize GST Calculator
gst_calculator = GSTCalculator()


def _get_boolean_setting(key: str, default: bool = False) -> bool:
    setting = DatabaseHelper.execute_one(
        "SELECT setting_value FROM settings WHERE setting_key = ?",
        (key,)
    )
    if not setting or setting.get('setting_value') is None:
        return default
    return str(setting['setting_value']).strip().lower() in ("true", "1", "yes")


def _get_ledger_group_id(group_name: str) -> Optional[int]:
    group = DatabaseHelper.execute_one(
        "SELECT id FROM ledger_groups WHERE name = ?",
        (group_name,)
    )
    return group['id'] if group else None


def _get_or_create_ledger(name: str, group_name: str, is_party: bool = False) -> int:
    existing = DatabaseHelper.execute_one(
        "SELECT id FROM ledgers WHERE name = ?",
        (name,)
    )
    if existing:
        return existing['id']

    group_id = _get_ledger_group_id(group_name)
    if not group_id:
        raise HTTPException(status_code=400, detail=f"Ledger group not found: {group_name}")

    return DatabaseHelper.execute_insert(
        """INSERT INTO ledgers
           (name, ledger_group_id, opening_balance, balance_type, current_balance, is_party)
           VALUES (?, ?, 0, 'DR', 0, ?)""",
        (name, group_id, 1 if is_party else 0)
    )


def _resolve_expense_ledger(category_row: dict) -> int:
    if category_row.get('ledger_id'):
        return category_row['ledger_id']

    classification = (category_row.get('classification') or 'INDIRECT').upper()
    group_map = {
        'DIRECT': 'Direct Expenses',
        'INDIRECT': 'Indirect Expenses',
        'CAPITAL': 'Fixed Assets',
    }
    group_name = group_map.get(classification, 'Indirect Expenses')
    ledger_id = _get_or_create_ledger(category_row['name'], group_name)
    DatabaseHelper.execute_update(
        "UPDATE expense_categories SET ledger_id = ? WHERE id = ?",
        (ledger_id, category_row['id'])
    )
    return ledger_id


def _get_itc_ledger_id() -> int:
    return _get_or_create_ledger("Input GST (ITC)", "Duties & Taxes")


def _get_cash_ledger_id() -> int:
    return _get_or_create_ledger("Cash", "Cash-in-Hand")


def _get_bank_ledger_id() -> int:
    return _get_or_create_ledger("Bank", "Bank Accounts")


def _calculate_gst_split(taxable_amount: float, gst_rate: float) -> dict:
    gst_amount = (taxable_amount * gst_rate) / 100 if gst_rate else 0
    cgst = gst_amount / 2
    sgst = gst_amount / 2
    return {
        "cgst_amount": cgst,
        "sgst_amount": sgst,
        "igst_amount": 0,
        "total_gst_amount": gst_amount,
    }


# ============================================================================
# STARTUP EVENT
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """Initialize database on startup"""
    init_database()
    FinancialYearHelper.ensure_current_fy()
    # Run migrations
    try:
        from pathlib import Path
        for m in ["2026_02_21_add_itr_gst_reports", "2026_02_21_statutory_compliance", "2026_02_23_ledger_master_groups"]:
            migration_path = Path(__file__).parent / "migrations" / f"{m}.py"
            if migration_path.exists():
                with open(migration_path) as f:
                    code = compile(f.read(), migration_path, "exec")
                    ns = {}
                    exec(code, ns)
                    if "run" in ns:
                        ns["run"]()
    except Exception:
        pass


# ============================================================================
# HEALTH CHECK
# ============================================================================

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


# ============================================================================
# COMPANY PROFILE ENDPOINTS
# ============================================================================

@app.get("/api/company", response_model=CompanyProfile)
async def get_company_profile():
    """Get company profile"""
    company = DatabaseHelper.execute_one("SELECT * FROM company_profile LIMIT 1")
    if not company:
        # Return empty default company profile for new installations
        return {
            "id": 1,
            "company_name": "My Company",
            "legal_name": "My Company Pvt Ltd",
            "gstin": "",
            "pan": "",
            "cin": "",
            "tan": "",
            "address_line1": "",
            "address_line2": "",
            "city": "",
            "state_code": "07",
            "state_name": "Delhi",
            "pincode": "",
            "country": "India",
            "phone": "",
            "email": "",
            "website": "",
            "bank_name": "",
            "bank_account_number": "",
            "bank_ifsc": "",
            "bank_branch": "",
            "logo_path": None,
            "signature_path": None,
            "financial_year_start": "04-01",
            "invoice_prefix": "INV",
            "invoice_start_number": 1,
            "terms_and_conditions": "",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
        }
    return company


@app.post("/api/company", response_model=APIResponse)
async def create_or_update_company(company: CompanyProfileCreate):
    """Create or update company profile"""
    existing = DatabaseHelper.execute_one("SELECT id FROM company_profile LIMIT 1")
    
    if existing:
        # Update
        DatabaseHelper.execute_update(
            """UPDATE company_profile SET 
               company_name=?, legal_name=?, gstin=?, pan=?,
               address_line1=?, address_line2=?, city=?, state_code=?,
               state_name=?, pincode=?, phone=?, email=?,
               bank_name=?, bank_account_number=?, bank_ifsc=?,
               updated_at=CURRENT_TIMESTAMP
               WHERE id=?""",
            (company.company_name, company.legal_name, company.gstin, company.pan,
             company.address_line1, company.address_line2, company.city, company.state_code,
             company.state_name, company.pincode, company.phone, company.email,
             company.bank_name, company.bank_account_number, company.bank_ifsc,
             existing['id'])
        )
        return APIResponse(success=True, message="Company profile updated")
    else:
        # Create
        DatabaseHelper.execute_insert(
            """INSERT INTO company_profile 
               (company_name, legal_name, gstin, pan, address_line1, address_line2,
                city, state_code, state_name, pincode, phone, email,
                bank_name, bank_account_number, bank_ifsc)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (company.company_name, company.legal_name, company.gstin, company.pan,
             company.address_line1, company.address_line2, company.city, company.state_code,
             company.state_name, company.pincode, company.phone, company.email,
             company.bank_name, company.bank_account_number, company.bank_ifsc)
        )
        return APIResponse(success=True, message="Company profile created")


# ============================================================================
# STATE ENDPOINTS
# ============================================================================

@app.get("/api/states", response_model=List[State])
async def get_states():
    """Get all Indian states with GST codes"""
    return DatabaseHelper.execute_query("SELECT * FROM states ORDER BY name")


# ============================================================================
# LEDGER GROUP & LEDGER ENDPOINTS
# ============================================================================

@app.get("/api/ledger-groups")
async def get_ledger_groups():
    """
    Get all ledger groups (chart of accounts).

    Nature is stored at group level (ASSETS, LIABILITIES, INCOME, EXPENSES)
    and is used by the frontend to drive read-only 'nature' for ledgers and
    enforce DR/CR rules.
    """
    return DatabaseHelper.execute_query(
        """
        SELECT id, name, parent_id, nature, is_system_group, created_at
        FROM ledger_groups
        ORDER BY 
          CASE nature
            WHEN 'ASSETS' THEN 1
            WHEN 'LIABILITIES' THEN 2
            WHEN 'INCOME' THEN 3
            WHEN 'EXPENSES' THEN 4
            ELSE 5
          END,
          name
        """
    )


# Capital groups (stored as LIABILITIES; filter "Capital" maps to these)
_CAPITAL_GROUP_NAMES = frozenset({
    "Capital Account", "Partner Capital", "Share Capital",
    "Reserves & Surplus", "Drawings",
})


@app.get("/api/ledgers", response_model=List[Ledger])
async def get_ledgers(
    group_id: Optional[int] = None,
    nature: Optional[str] = None,
    is_party: Optional[bool] = None,
    search: Optional[str] = None,
    is_active: bool = True
):
    """Get ledgers with optional filters. nature: ASSETS, LIABILITIES, INCOME, EXPENSES, or CAPITAL (maps to capital groups)."""
    if nature and nature.upper() == "CAPITAL":
        # Capital: filter by group name (stored as LIABILITIES)
        query = """SELECT l.* FROM ledgers l
                   JOIN ledger_groups lg ON l.ledger_group_id = lg.id
                   WHERE l.is_active = ? AND lg.name IN ({})""".format(
            ",".join("?" * len(_CAPITAL_GROUP_NAMES))
        )
        params = [1 if is_active else 0] + list(_CAPITAL_GROUP_NAMES)
    else:
        query = "SELECT l.* FROM ledgers l JOIN ledger_groups lg ON l.ledger_group_id = lg.id WHERE l.is_active = ?"
        params = [1 if is_active else 0]
        if nature and nature.upper() in ("ASSETS", "LIABILITIES", "INCOME", "EXPENSES"):
            query += " AND lg.nature = ?"
            params.append(nature.upper())

    if group_id:
        query += " AND l.ledger_group_id = ?"
        params.append(group_id)

    if is_party is not None:
        query += " AND l.is_party = ?"
        params.append(1 if is_party else 0)

    if search:
        query += " AND (l.name LIKE ? OR l.gstin LIKE ? OR l.phone LIKE ?)"
        search_param = f"%{search}%"
        params.extend([search_param, search_param, search_param])

    query += " ORDER BY lg.nature, lg.name, l.name"
    return DatabaseHelper.execute_query(query, tuple(params))


@app.get("/api/ledgers/{ledger_id}", response_model=Ledger)
async def get_ledger(ledger_id: int):
    """Get single ledger by ID"""
    ledger = DatabaseHelper.execute_one(
        "SELECT * FROM ledgers WHERE id = ?", (ledger_id,)
    )
    if not ledger:
        raise HTTPException(status_code=404, detail="Ledger not found")
    return ledger


@app.post("/api/ledgers", response_model=APIResponse)
async def create_ledger(ledger: LedgerCreate):
    """Create new ledger"""
    # Controls: prevent negative opening and wrong sign by group nature
    if ledger.opening_balance is not None and ledger.opening_balance < 0:
        raise HTTPException(status_code=400, detail="Opening balance must be 0 or more (use balance type DR/CR).")
    if ledger.balance_type not in ("DR", "CR"):
        raise HTTPException(status_code=400, detail="Balance type must be DR or CR.")

    group = DatabaseHelper.execute_one(
        "SELECT name, nature FROM ledger_groups WHERE id = ?",
        (ledger.ledger_group_id,),
    )
    if not group:
        raise HTTPException(status_code=400, detail="Invalid ledger group.")

    normal = "DR" if group["nature"] in ("ASSETS", "EXPENSES") else "CR"
    if ledger.opening_balance and ledger.opening_balance > 0 and ledger.balance_type != normal:
        raise HTTPException(
            status_code=400,
            detail=f"Wrong opening sign for {group['nature']} ledger. Use {normal} for opening balance.",
        )

    ledger_id = DatabaseHelper.execute_insert(
        """INSERT INTO ledgers 
           (name, alias, ledger_group_id, opening_balance, balance_type,
            is_party, gstin, pan, contact_person, phone, email,
            billing_address, billing_city, billing_state_code, billing_pincode,
            gst_registration_type, credit_limit, credit_days, current_balance)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (ledger.name, ledger.alias, ledger.ledger_group_id, 
         ledger.opening_balance, ledger.balance_type,
         1 if ledger.is_party else 0, ledger.gstin, ledger.pan,
         ledger.contact_person, ledger.phone, ledger.email,
         ledger.billing_address, ledger.billing_city, ledger.billing_state_code,
         ledger.billing_pincode, ledger.gst_registration_type.value,
         ledger.credit_limit, ledger.credit_days, ledger.opening_balance)
    )
    
    AuditLogger.log("ledgers", ledger_id, "INSERT", new_values=ledger.model_dump_json())
    return APIResponse(success=True, message="Ledger created", data={"id": ledger_id})


@app.put("/api/ledgers/{ledger_id}", response_model=APIResponse)
async def update_ledger(ledger_id: int, ledger: LedgerUpdate):
    """Update existing ledger"""
    existing = DatabaseHelper.execute_one(
        "SELECT * FROM ledgers WHERE id = ?", (ledger_id,)
    )
    if not existing:
        raise HTTPException(status_code=404, detail="Ledger not found")

    patch = ledger.model_dump(exclude_unset=True)
    if "opening_balance" in patch and patch["opening_balance"] is not None and patch["opening_balance"] < 0:
        raise HTTPException(status_code=400, detail="Opening balance must be 0 or more (use balance type DR/CR).")
    if "balance_type" in patch and patch["balance_type"] is not None and patch["balance_type"] not in ("DR", "CR"):
        raise HTTPException(status_code=400, detail="Balance type must be DR or CR.")

    # Prevent casual regrouping: disallow group change if any transactions exist
    if "ledger_group_id" in patch and patch["ledger_group_id"] is not None and patch["ledger_group_id"] != existing.get("ledger_group_id"):
        tx = DatabaseHelper.execute_one(
            "SELECT COUNT(*) as c FROM ledger_transactions WHERE ledger_id = ?",
            (ledger_id,),
        )
        inv = DatabaseHelper.execute_one(
            "SELECT COUNT(*) as c FROM invoices WHERE party_id = ?",
            (ledger_id,),
        )
        if (tx and tx.get("c", 0) > 0) or (inv and inv.get("c", 0) > 0):
            raise HTTPException(status_code=400, detail="Cannot change ledger group after transactions. Create a new ledger instead.")

    # Validate opening sign if opening_balance/balance_type being changed
    effective_group_id = patch.get("ledger_group_id", existing.get("ledger_group_id"))
    effective_opening = patch.get("opening_balance", existing.get("opening_balance", 0))
    effective_bt = patch.get("balance_type", existing.get("balance_type", "DR"))
    if effective_opening and float(effective_opening) > 0:
        group = DatabaseHelper.execute_one(
            "SELECT nature FROM ledger_groups WHERE id = ?",
            (effective_group_id,),
        )
        if group:
            normal = "DR" if group["nature"] in ("ASSETS", "EXPENSES") else "CR"
            if effective_bt != normal:
                raise HTTPException(status_code=400, detail=f"Wrong opening sign for {group['nature']} ledger. Use {normal}.")
    
    update_fields = []
    update_values = []
    
    for field, value in ledger.model_dump(exclude_unset=True).items():
        if value is not None:
            update_fields.append(f"{field} = ?")
            update_values.append(value)
    
    if update_fields:
        update_values.append(ledger_id)
        DatabaseHelper.execute_update(
            f"UPDATE ledgers SET {', '.join(update_fields)} WHERE id = ?",
            tuple(update_values)
        )
    
    AuditLogger.log("ledgers", ledger_id, "UPDATE", 
                    old_values=json.dumps(existing),
                    new_values=ledger.model_dump_json())
    return APIResponse(success=True, message="Ledger updated")


# ============================================================================
# HSN CODE ENDPOINTS
# ============================================================================

@app.get("/api/hsn-codes", response_model=List[HSNCode])
async def get_hsn_codes(
    search: Optional[str] = None,
    type: Optional[str] = None
):
    """Get HSN/SAC codes"""
    query = "SELECT * FROM hsn_sac_codes WHERE is_active = 1"
    params = []
    
    if search:
        query += " AND (code LIKE ? OR description LIKE ?)"
        search_param = f"%{search}%"
        params.extend([search_param, search_param])
    
    if type:
        query += " AND type = ?"
        params.append(type)
    
    query += " ORDER BY code LIMIT 100"
    return DatabaseHelper.execute_query(query, tuple(params))


@app.post("/api/hsn-codes", response_model=APIResponse)
async def create_hsn_code(hsn: HSNCodeCreate):
    """Create new HSN/SAC code"""
    hsn_id = DatabaseHelper.execute_insert(
        """INSERT INTO hsn_sac_codes 
           (code, description, type, gst_rate, cgst_rate, sgst_rate, igst_rate, cess_rate)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
        (hsn.code, hsn.description, hsn.type, hsn.gst_rate,
         hsn.gst_rate / 2, hsn.gst_rate / 2, hsn.gst_rate, hsn.cess_rate)
    )
    return APIResponse(success=True, message="HSN code created", data={"id": hsn_id})


# ============================================================================
# ITEM ENDPOINTS
# ============================================================================

@app.get("/api/items", response_model=List[Item])
async def get_items(
    search: Optional[str] = None,
    category_id: Optional[int] = None,
    low_stock: bool = False,
    is_active: bool = True,
    page: int = 1,
    page_size: int = 50
):
    """Get items with filters"""
    query = "SELECT * FROM items WHERE is_active = ?"
    params = [1 if is_active else 0]
    
    if search:
        query += " AND (name LIKE ? OR barcode LIKE ? OR sku LIKE ? OR hsn_code LIKE ?)"
        search_param = f"%{search}%"
        params.extend([search_param, search_param, search_param, search_param])
    
    if category_id:
        query += " AND category_id = ?"
        params.append(category_id)
    
    if low_stock:
        query += " AND current_stock <= reorder_level"
    
    query += f" ORDER BY name LIMIT {page_size} OFFSET {(page - 1) * page_size}"
    return DatabaseHelper.execute_query(query, tuple(params))


@app.get("/api/items/search", response_model=List[ItemSearch])
async def search_items(
    q: str = Query(..., min_length=1),
    limit: int = 20
):
    """Quick search items by barcode, name, or SKU"""
    query = """
        SELECT i.id, i.name, i.barcode, i.sku, i.hsn_code,
               i.selling_price, i.mrp, i.gst_rate, i.current_stock,
               COALESCE(u.code, 'NOS') as unit_code
        FROM items i
        LEFT JOIN units u ON i.unit_id = u.id
        WHERE i.is_active = 1 
        AND (i.barcode = ? OR i.name LIKE ? OR i.sku LIKE ?)
        ORDER BY 
            CASE WHEN i.barcode = ? THEN 0 ELSE 1 END,
            i.name
        LIMIT ?
    """
    search_param = f"%{q}%"
    return DatabaseHelper.execute_query(query, (q, search_param, search_param, q, limit))


@app.get("/api/items/barcode/{barcode}", response_model=ItemSearch)
async def get_item_by_barcode(barcode: str):
    """Get item by exact barcode match"""
    item = DatabaseHelper.execute_one(
        """SELECT i.id, i.name, i.barcode, i.sku, i.hsn_code,
                  i.selling_price, i.mrp, i.gst_rate, i.current_stock,
                  COALESCE(u.code, 'NOS') as unit_code
           FROM items i
           LEFT JOIN units u ON i.unit_id = u.id
           WHERE i.barcode = ? AND i.is_active = 1""",
        (barcode,)
    )
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item


@app.get("/api/items/{item_id}", response_model=Item)
async def get_item(item_id: int):
    """Get single item by ID"""
    item = DatabaseHelper.execute_one(
        "SELECT * FROM items WHERE id = ?", (item_id,)
    )
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item


@app.post("/api/items", response_model=APIResponse)
async def create_item(item: ItemCreate):
    """Create new item"""
    # Check for duplicate barcode
    if item.barcode:
        existing = DatabaseHelper.execute_one(
            "SELECT id FROM items WHERE barcode = ?", (item.barcode,)
        )
        if existing:
            raise HTTPException(status_code=400, detail="Barcode already exists")
    
    item_id = DatabaseHelper.execute_insert(
        """INSERT INTO items 
                     (name, alias, barcode, sku, category_id, hsn_code, unit_id,
                        cost_price, selling_price, mrp, wholesale_price, min_selling_price,
                        price_inclusive_tax, gst_rate, cgst_rate, sgst_rate, igst_rate, cess_rate,
                        opening_stock, current_stock, min_stock_level, reorder_level,
                        is_service, batch_tracking, serial_tracking, expiry_tracking)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (item.name, item.alias, item.barcode, item.sku, item.category_id,
         item.hsn_code, item.unit_id, item.cost_price, item.selling_price,
         item.mrp, item.wholesale_price, item.min_selling_price,
         1 if item.price_inclusive_tax else 0,
         item.gst_rate, item.gst_rate / 2, item.gst_rate / 2, item.gst_rate,
         item.cess_rate, item.opening_stock, item.opening_stock,
         item.min_stock_level, item.reorder_level,
                 1 if item.is_service else 0, 1 if item.batch_tracking else 0,
                 1 if item.serial_tracking else 0, 1 if item.expiry_tracking else 0)
    )
    
    AuditLogger.log("items", item_id, "INSERT", new_values=item.model_dump_json())
    return APIResponse(success=True, message="Item created", data={"id": item_id})


@app.put("/api/items/{item_id}", response_model=APIResponse)
async def update_item(item_id: int, item: ItemUpdate):
    """Update existing item"""
    existing = DatabaseHelper.execute_one(
        "SELECT * FROM items WHERE id = ?", (item_id,)
    )
    if not existing:
        raise HTTPException(status_code=404, detail="Item not found")
    
    update_fields = []
    update_values = []
    
    for field, value in item.model_dump(exclude_unset=True).items():
        if value is not None:
            update_fields.append(f"{field} = ?")
            update_values.append(value)
    
    if update_fields:
        update_values.append(item_id)
        DatabaseHelper.execute_update(
            f"UPDATE items SET {', '.join(update_fields)} WHERE id = ?",
            tuple(update_values)
        )
    
    AuditLogger.log("items", item_id, "UPDATE",
                    old_values=json.dumps(existing),
                    new_values=item.model_dump_json())
    return APIResponse(success=True, message="Item updated")


# ============================================================================
# PRODUCT IMPORT/EXPORT ENDPOINTS
# ============================================================================

@app.post("/api/products/import", response_model=ProductImportResult)
async def import_products_csv(request: ProductImportRequest):
    """
    Bulk import products from CSV data.
    Validates all products before import, supports dry-run mode.
    """
    errors: List[ProductImportError] = []
    imported_items = []
    skipped_count = 0
    
    # Get or create financial year if not provided
    fy_id = FinancialYearHelper.ensure_current_fy()
    
    # Get default unit (piece)
    default_unit = DatabaseHelper.execute_one(
        "SELECT id FROM units WHERE name = 'Piece' LIMIT 1"
    )
    default_unit_id = default_unit['id'] if default_unit else 1
    
    # Validate and prepare products
    for idx, product in enumerate(request.products, 1):
        try:
            # Required field check
            if not product.name or not product.name.strip():
                errors.append(ProductImportError(
                    row_number=idx,
                    error_message="Product name is required",
                    error_field="name"
                ))
                continue
            
            # Check for duplicate SKU if provided
            if product.sku:
                existing = DatabaseHelper.execute_one(
                    "SELECT id FROM items WHERE sku = ? AND is_deleted = 0",
                    (product.sku,)
                )
                if existing:
                    errors.append(ProductImportError(
                        row_number=idx,
                        error_message=f"SKU '{product.sku}' already exists",
                        error_field="sku"
                    ))
                    skipped_count += 1
                    continue
            
            # Check for duplicate barcode if provided
            if product.barcode:
                existing = DatabaseHelper.execute_one(
                    "SELECT id FROM items WHERE barcode = ? AND is_deleted = 0",
                    (product.barcode,)
                )
                if existing:
                    errors.append(ProductImportError(
                        row_number=idx,
                        error_message=f"Barcode '{product.barcode}' already exists",
                        error_field="barcode"
                    ))
                    skipped_count += 1
                    continue
            
            # Validate prices
            cost_price = float(product.cost_price or 0)
            selling_price = float(product.selling_price or 0)
            mrp = float(product.mrp or 0)
            gst_rate = float(product.gst_rate or 0)
            
            if cost_price < 0 or selling_price < 0 or mrp < 0:
                errors.append(ProductImportError(
                    row_number=idx,
                    error_message="Prices cannot be negative",
                    error_field="prices"
                ))
                continue
            
            # Validate GST rate
            if gst_rate < 0 or gst_rate > 100:
                errors.append(ProductImportError(
                    row_number=idx,
                    error_message="GST rate must be between 0 and 100",
                    error_field="gst_rate"
                ))
                continue
            
            # Prepare item data for insertion
            item_data = {
                'name': product.name.strip(),
                'sku': product.sku or None,
                'barcode': product.barcode or None,
                'hsn_code': product.hsn_code or None,
                'unit_id': default_unit_id,
                'cost_price': cost_price,
                'selling_price': selling_price,
                'mrp': mrp,
                'gst_rate': gst_rate,
                'opening_stock': float(product.current_stock or 0),
                'min_stock_level': float(product.min_stock_level or 0),
                'is_active': product.is_active if product.is_active is not None else True,
                'is_service': False,
                'batch_tracking': False,
                'serial_tracking': False,
                'expiry_tracking': False
            }
            imported_items.append((idx, item_data))
        
        except ValueError as e:
            errors.append(ProductImportError(
                row_number=idx,
                error_message=f"Invalid data format: {str(e)}",
                error_field="data"
            ))
            continue
        except Exception as e:
            errors.append(ProductImportError(
                row_number=idx,
                error_message=f"Error processing row: {str(e)}",
                error_field="unknown"
            ))
            continue
    
    # If dry run, return results without saving
    if request.dry_run:
        return ProductImportResult(
            success=len(errors) == 0,
            imported_count=len(imported_items),
            skipped_count=skipped_count,
            failed_count=len(errors),
            errors=errors,
            message=f"Dry run: {len(imported_items)} products ready to import" if errors else f"All {len(imported_items)} products validated successfully",
            dry_run=True
        )
    
    # Insert validated products into database
    imported_count = 0
    try:
        for row_num, item_data in imported_items:
            query = """
                INSERT INTO items (
                    name, sku, barcode, hsn_code, unit_id,
                    cost_price, selling_price, mrp, gst_rate,
                    opening_stock, min_stock_level, current_stock,
                    is_active, is_service, batch_tracking, serial_tracking, expiry_tracking
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            params = (
                item_data['name'], item_data['sku'], item_data['barcode'], item_data['hsn_code'],
                item_data['unit_id'], item_data['cost_price'], item_data['selling_price'],
                item_data['mrp'], item_data['gst_rate'], item_data['opening_stock'],
                item_data['min_stock_level'], item_data['opening_stock'],  # current_stock = opening_stock
                item_data['is_active'], item_data['is_service'],
                item_data['batch_tracking'], item_data['serial_tracking'], item_data['expiry_tracking']
            )
            DatabaseHelper.execute_insert(query, params)
            imported_count += 1
            
            # Log the import
            AuditLogger.log("items", None, "CREATE", 
                          new_values=json.dumps(item_data))
        
        return ProductImportResult(
            success=True,
            imported_count=imported_count,
            skipped_count=skipped_count,
            failed_count=len(errors),
            errors=errors,
            message=f"Successfully imported {imported_count} product(s)",
            dry_run=False
        )
    
    except Exception as e:
        return ProductImportResult(
            success=False,
            imported_count=imported_count,
            skipped_count=skipped_count,
            failed_count=len(errors) + len(imported_items),
            errors=errors,
            message=f"Import failed: {str(e)}",
            dry_run=False
        )


@app.get("/api/products/export")
async def export_products_csv(active_only: bool = True) -> str:
    """
    Export all products as CSV.
    Returns CSV-formatted string with all products.
    """
    import csv
    from io import StringIO
    
    # Query products
    query = "SELECT * FROM items WHERE is_deleted = 0"
    if active_only:
        query += " AND is_active = 1"
    query += " ORDER BY name ASC"
    
    products = DatabaseHelper.execute_query(query)
    
    if not products:
        return "name,sku,barcode,hsn_code,unit,cost_price,selling_price,mrp,gst_rate,current_stock,min_stock_level,max_stock_level,description,is_active\n"
    
    # Get unit names
    units_map = {}
    units = DatabaseHelper.execute_query("SELECT id, name FROM units")
    for unit in units:
        units_map[unit['id']] = unit['name']
    
    # Create CSV
    output = StringIO()
    writer = csv.writer(output)
    
    # Header
    headers = [
        'name', 'sku', 'barcode', 'hsn_code', 'unit',
        'cost_price', 'selling_price', 'mrp', 'gst_rate',
        'current_stock', 'min_stock_level', 'max_stock_level', 'description', 'is_active'
    ]
    writer.writerow(headers)
    
    # Data rows
    for product in products:
        unit_name = units_map.get(product.get('unit_id'), 'Piece')
        row = [
            product.get('name', ''),
            product.get('sku', ''),
            product.get('barcode', ''),
            product.get('hsn_code', ''),
            unit_name,
            product.get('cost_price', 0),
            product.get('selling_price', 0),
            product.get('mrp', 0),
            product.get('gst_rate', 0),
            product.get('current_stock', 0),
            product.get('min_stock_level', 0),
            product.get('reorder_level', 0),  # max_stock_level maps to reorder_level
            product.get('alias', ''),  # description maps to alias
            1 if product.get('is_active', True) else 0
        ]
        writer.writerow(row)
    
    return output.getvalue()


# ============================================================================
# INVOICE ENDPOINTS
# ============================================================================

@app.get("/api/invoices", response_model=List[GSTInvoice])
async def get_invoices(
    voucher_type_id: Optional[int] = None,
    party_id: Optional[int] = None,
    status: Optional[str] = None,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    page: int = 1,
    page_size: int = 50
):
    """Get invoices with filters"""
    query = "SELECT * FROM invoices WHERE is_deleted = 0"
    params = []
    
    if voucher_type_id:
        query += " AND voucher_type_id = ?"
        params.append(voucher_type_id)
    
    if party_id:
        query += " AND party_id = ?"
        params.append(party_id)
    
    if status:
        query += " AND status = ?"
        params.append(status)
    
    if from_date:
        query += " AND invoice_date >= ?"
        params.append(from_date.isoformat())
    
    if to_date:
        query += " AND invoice_date <= ?"
        params.append(to_date.isoformat())
    
    query += f" ORDER BY invoice_date DESC, id DESC LIMIT {page_size} OFFSET {(page - 1) * page_size}"
    
    invoices = DatabaseHelper.execute_query(query, tuple(params))
    
    # Load items for each invoice
    for invoice in invoices:
        invoice['items'] = DatabaseHelper.execute_query(
            "SELECT * FROM invoice_items WHERE invoice_id = ? ORDER BY serial_number",
            (invoice['id'],)
        )
    
    return invoices


@app.get("/api/invoices/{invoice_id}", response_model=GSTInvoice)
async def get_invoice(invoice_id: int):
    """Get single invoice with items"""
    invoice = DatabaseHelper.execute_one(
        "SELECT * FROM invoices WHERE id = ? AND is_deleted = 0",
        (invoice_id,)
    )
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    
    invoice['items'] = DatabaseHelper.execute_query(
        "SELECT * FROM invoice_items WHERE invoice_id = ? ORDER BY serial_number",
        (invoice_id,)
    )
    
    return invoice


@app.post("/api/invoices", response_model=APIResponse)
async def create_invoice(invoice_data: GSTInvoiceCreate):
    """
    Create new GST invoice with atomic inventory and ledger updates
    """
    if not invoice_data.items:
        raise HTTPException(status_code=400, detail="Invoice must have at least one item")
    
    # Get company profile for GST calculation
    company = DatabaseHelper.execute_one("SELECT * FROM company_profile LIMIT 1")
    if not company:
        raise HTTPException(status_code=400, detail="Company profile not set")

    voucher_type = DatabaseHelper.execute_one(
        "SELECT id, type, affects_inventory FROM voucher_types WHERE id = ?",
        (invoice_data.voucher_type_id,)
    )
    if not voucher_type:
        raise HTTPException(status_code=400, detail="Invalid voucher type")
    is_purchase = voucher_type['type'] == 'PURCHASE'
    
    # Get or create financial year
    fy_id = FinancialYearHelper.ensure_current_fy()
    
    # Generate invoice number
    invoice_number = InvoiceNumberGenerator.get_next_number(
        invoice_data.voucher_type_id, fy_id
    )
    
    # Determine place of supply
    place_of_supply = invoice_data.place_of_supply or invoice_data.party_state_code or company['state_code']
    
    # Prepare transaction items for GST calculation
    calc_items = []
    for item in invoice_data.items:
        calc_items.append(TransactionItem(
            item_id=item.item_id or 0,
            item_name=item.item_name,
            hsn_code=item.hsn_code or "",
            quantity=Decimal(str(item.quantity)),
            rate=Decimal(str(item.rate)),
            mrp=Decimal(str(item.mrp)),
            discount_type=CalcDiscountType[item.discount_type.value],
            discount_value=Decimal(str(item.discount_value)),
            gst_rate=Decimal(str(item.gst_rate)),
            cess_rate=Decimal(str(item.cess_rate)),
            free_quantity=Decimal(str(item.free_quantity)),
            unit_code=item.unit_code or "NOS"
        ))
    
    # Create transaction and calculate GST
    transaction = Transaction(
        company_state_code=company['state_code'],
        party_state_code=invoice_data.party_state_code or company['state_code'],
        place_of_supply=place_of_supply,
        items=calc_items,
        is_reverse_charge=invoice_data.is_reverse_charge,
        is_export=invoice_data.is_export,
        invoice_discount_type=CalcDiscountType[invoice_data.discount_type.value],
        invoice_discount_value=Decimal(str(invoice_data.discount_value)),
        transport_charges=Decimal(str(invoice_data.transport_charges)),
        packing_charges=Decimal(str(invoice_data.packing_charges)),
        other_charges=Decimal(str(invoice_data.other_charges))
    )
    
    result = gst_calculator.calculate_transaction(transaction)
    
    # Calculate balances
    balance_amount = float(result.grand_total) - invoice_data.paid_amount
    payment_status = "PAID" if balance_amount <= 0 else ("PARTIAL" if invoice_data.paid_amount > 0 else "UNPAID")
    
    # Amount in words
    amount_words = number_to_words_indian(float(result.grand_total))
    
    # Start atomic transaction
    with get_db_connection() as conn:
        try:
            # Insert invoice header
            cursor = conn.execute(
                """INSERT INTO invoices 
                   (voucher_type_id, invoice_number, invoice_date, due_date, financial_year_id,
                    party_id, party_name, party_gstin, party_state_code, party_address,
                    billing_name, billing_address, billing_city, billing_state_code, billing_pincode,
                    shipping_name, shipping_address, shipping_city, shipping_state_code, shipping_pincode,
                    place_of_supply, is_reverse_charge, is_export,
                    subtotal, discount_type, discount_value, discount_amount, taxable_amount,
                    cgst_amount, sgst_amount, igst_amount, cess_amount, total_tax_amount,
                    transport_charges, packing_charges, other_charges,
                    round_off_amount, grand_total, amount_in_words,
                    payment_mode, payment_reference, paid_amount, balance_amount, payment_status,
                    eway_bill_number, vehicle_number, transporter_name,
                    notes, terms_conditions, status)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (invoice_data.voucher_type_id, invoice_number, 
                 invoice_data.invoice_date.isoformat(),
                 invoice_data.due_date.isoformat() if invoice_data.due_date else None,
                 fy_id,
                 invoice_data.party_id, invoice_data.party_name,
                 invoice_data.party_gstin, invoice_data.party_state_code,
                 invoice_data.party_address,
                 invoice_data.billing_name, invoice_data.billing_address,
                 invoice_data.billing_city, invoice_data.billing_state_code,
                 invoice_data.billing_pincode,
                 invoice_data.shipping_name, invoice_data.shipping_address,
                 invoice_data.shipping_city, invoice_data.shipping_state_code,
                 invoice_data.shipping_pincode,
                 place_of_supply, 1 if invoice_data.is_reverse_charge else 0,
                 1 if invoice_data.is_export else 0,
                 float(result.subtotal), invoice_data.discount_type.value,
                 invoice_data.discount_value, float(result.total_discount),
                 float(result.total_taxable),
                 float(result.total_cgst), float(result.total_sgst),
                 float(result.total_igst), float(result.total_cess),
                 float(result.total_tax),
                 invoice_data.transport_charges, invoice_data.packing_charges,
                 invoice_data.other_charges,
                 float(result.round_off), float(result.grand_total), amount_words,
                 invoice_data.payment_mode.value if invoice_data.payment_mode else None,
                 invoice_data.payment_reference,
                 invoice_data.paid_amount, balance_amount, payment_status,
                 invoice_data.eway_bill_number, invoice_data.vehicle_number,
                 invoice_data.transporter_name,
                 invoice_data.notes, invoice_data.terms_conditions, "CONFIRMED")
            )
            
            invoice_id = cursor.lastrowid
            
            # Insert invoice items and update inventory
            for idx, (item_data, calc_item) in enumerate(zip(invoice_data.items, result.items)):
                # Insert invoice item
                conn.execute(
                    """INSERT INTO invoice_items 
                       (invoice_id, item_id, item_name, item_description, hsn_code, barcode,
                        quantity, unit_code, free_quantity, rate, mrp,
                        discount_type, discount_value, discount_amount, taxable_amount,
                        gst_rate, cgst_rate, cgst_amount, sgst_rate, sgst_amount,
                        igst_rate, igst_amount, cess_rate, cess_amount,
                        total_tax_amount, total_amount, serial_number)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (invoice_id, item_data.item_id, item_data.item_name,
                     item_data.item_description, item_data.hsn_code, item_data.barcode,
                     item_data.quantity, item_data.unit_code, item_data.free_quantity,
                     item_data.rate, item_data.mrp,
                     item_data.discount_type.value, item_data.discount_value,
                     float(calc_item.discount_amount), float(calc_item.taxable_amount),
                     item_data.gst_rate,
                     float(calc_item.cgst_rate), float(calc_item.cgst_amount),
                     float(calc_item.sgst_rate), float(calc_item.sgst_amount),
                     float(calc_item.igst_rate), float(calc_item.igst_amount),
                     item_data.cess_rate, float(calc_item.total_cess_amount),
                     float(calc_item.total_tax_amount), float(calc_item.total_amount),
                     idx + 1)
                )
                
                # Update inventory (OUT for sales, IN for purchase)
                if item_data.item_id and voucher_type['affects_inventory']:
                    total_qty = item_data.quantity + item_data.free_quantity
                    
                    # Get current stock
                    item = conn.execute(
                        "SELECT current_stock FROM items WHERE id = ?",
                        (item_data.item_id,)
                    ).fetchone()
                    
                    if item:
                        balance_before = item['current_stock']
                        balance_after = (
                            balance_before + total_qty
                            if is_purchase
                            else balance_before - total_qty
                        )
                        
                        # Update stock
                        conn.execute(
                            "UPDATE items SET current_stock = ? WHERE id = ?",
                            (balance_after, item_data.item_id)
                        )
                        
                        # Log inventory transaction
                        conn.execute(
                            """INSERT INTO inventory_transactions 
                               (transaction_date, voucher_type_id, voucher_number,
                                reference_id, reference_type, item_id,
                                transaction_type, quantity, rate, amount,
                                balance_before, balance_after, financial_year_id)
                               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                            (invoice_data.invoice_date.isoformat(),
                             invoice_data.voucher_type_id, invoice_number,
                             invoice_id, 'INVOICE', item_data.item_id,
                                      'IN' if is_purchase else 'OUT', total_qty, item_data.rate,
                             total_qty * item_data.rate,
                             balance_before, balance_after, fy_id)
                        )
            
            # Insert HSN-wise tax summary
            hsn_summary = gst_calculator.get_hsn_wise_summary(result)
            for summary in hsn_summary:
                conn.execute(
                    """INSERT INTO invoice_tax_summary 
                       (invoice_id, hsn_code, taxable_amount, gst_rate,
                        cgst_amount, sgst_amount, igst_amount, cess_amount,
                        total_tax_amount, total_quantity)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (invoice_id, summary['hsn_code'],
                     float(summary['taxable_amount']), float(summary['gst_rate']),
                     float(summary['cgst_amount']), float(summary['sgst_amount']),
                     float(summary['igst_amount']), float(summary['cess_amount']),
                     float(summary['total_tax']), float(summary['quantity']))
                )
            
            # Update party ledger balance (if party selected)
            if invoice_data.party_id:
                conn.execute(
                    """UPDATE ledgers SET current_balance = current_balance + ? 
                       WHERE id = ?""",
                    (float(result.grand_total), invoice_data.party_id)
                )
                
                # Create ledger transaction
                conn.execute(
                    """INSERT INTO ledger_transactions 
                       (transaction_date, voucher_type_id, voucher_number,
                        reference_id, reference_type, ledger_id,
                        debit_amount, credit_amount, narration, financial_year_id)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (invoice_data.invoice_date.isoformat(),
                     invoice_data.voucher_type_id, invoice_number,
                     invoice_id, 'INVOICE', invoice_data.party_id,
                     0 if is_purchase else float(result.grand_total),
                     float(result.grand_total) if is_purchase else 0,
                     f"{'Purchase' if is_purchase else 'Sales'} Invoice {invoice_number}", fy_id)
                )
            
            conn.commit()
            
            AuditLogger.log("invoices", invoice_id, "INSERT",
                           new_values=json.dumps({"invoice_number": invoice_number}))
            
            return APIResponse(
                success=True, 
                message="Invoice created successfully",
                data={
                    "id": invoice_id,
                    "invoice_number": invoice_number,
                    "grand_total": float(result.grand_total)
                }
            )
            
        except Exception as e:
            conn.rollback()
            raise HTTPException(status_code=500, detail=f"Failed to create invoice: {str(e)}")


@app.put("/api/invoices/{invoice_id}/cancel", response_model=APIResponse)
async def cancel_invoice(invoice_id: int, reason: str = ""):
    """
    Cancel an invoice (cannot delete - audit trail)
    Reverses inventory and ledger transactions
    STATUTORY: Cannot cancel if GSTR-1 filed - use amendment entry instead
    """
    invoice = DatabaseHelper.execute_one(
        "SELECT * FROM invoices WHERE id = ? AND is_deleted = 0",
        (invoice_id,)
    )
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")

    # Compliance: Do not allow editing of filed data
    try:
        from compliance_engine import check_edit_allowed, ComplianceError
        check_edit_allowed('invoice', invoice_id, invoice.get('financial_year_id'))
    except ImportError:
        pass
    except ComplianceError as e:
        raise HTTPException(status_code=403, detail=str(e))
    
    if invoice['status'] == 'CANCELLED':
        raise HTTPException(status_code=400, detail="Invoice already cancelled")
    
    with get_db_connection() as conn:
        try:
            # Mark invoice as cancelled
            conn.execute(
                """UPDATE invoices SET status = 'CANCELLED', 
                   deleted_reason = ?, updated_at = CURRENT_TIMESTAMP
                   WHERE id = ?""",
                (reason, invoice_id)
            )
            
            # Reverse inventory transactions
            items = conn.execute(
                "SELECT * FROM invoice_items WHERE invoice_id = ?",
                (invoice_id,)
            ).fetchall()
            
            for item in items:
                if item['item_id']:
                    total_qty = item['quantity'] + item['free_quantity']
                    
                    # Restore stock
                    conn.execute(
                        "UPDATE items SET current_stock = current_stock + ? WHERE id = ?",
                        (total_qty, item['item_id'])
                    )
            
            # Reverse ledger balance
            if invoice['party_id']:
                conn.execute(
                    """UPDATE ledgers SET current_balance = current_balance - ? 
                       WHERE id = ?""",
                    (invoice['grand_total'], invoice['party_id'])
                )
            
            conn.commit()
            
            AuditLogger.log("invoices", invoice_id, "CANCEL", reason=reason)
            
            return APIResponse(success=True, message="Invoice cancelled")
            
        except Exception as e:
            conn.rollback()
            raise HTTPException(status_code=500, detail=f"Failed to cancel invoice: {str(e)}")


# ============================================================================
# INVENTORY ENDPOINTS
# ============================================================================

@app.get("/api/inventory/stock-summary", response_model=List[StockSummary])
async def get_stock_summary(low_stock_only: bool = False):
    """Get stock summary with optional low stock filter"""
    query = """
        SELECT i.id, i.name, i.barcode, i.sku, i.hsn_code, 
               'NOS' as unit,
               i.current_stock, i.min_stock_level,
               i.cost_price, i.selling_price, COALESCE(i.mrp, 0) as mrp,
               (i.current_stock * COALESCE(i.cost_price, 0)) as stock_value,
               CASE WHEN i.current_stock <= i.reorder_level THEN 1 ELSE 0 END as needs_reorder
        FROM items i
        WHERE i.is_active = 1
    """
    
    if low_stock_only:
        query += " AND i.current_stock <= i.reorder_level"
    
    query += " ORDER BY i.name"
    return DatabaseHelper.execute_query(query)


@app.post("/api/inventory/adjust", response_model=APIResponse)
async def adjust_inventory(adjustment: InventoryAdjustment):
    """Adjust inventory stock"""
    item = DatabaseHelper.execute_one(
        "SELECT * FROM items WHERE id = ?",
        (adjustment.item_id,)
    )
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    balance_before = item['current_stock']
    
    if adjustment.adjustment_type == "ADD":
        new_stock = balance_before + adjustment.quantity
    else:
        new_stock = balance_before - adjustment.quantity
    
    allow_negative = _get_boolean_setting("enable_negative_stock", False)
    if new_stock < 0 and not allow_negative:
        raise HTTPException(status_code=400, detail="Stock cannot be negative")
    
    fy_id = FinancialYearHelper.ensure_current_fy()
    
    with get_db_connection() as conn:
        try:
            # Update stock
            conn.execute(
                "UPDATE items SET current_stock = ? WHERE id = ?",
                (new_stock, adjustment.item_id)
            )
            
            # Log transaction
            conn.execute(
                """INSERT INTO inventory_transactions 
                   (transaction_date, reference_type, item_id,
                    transaction_type, quantity, balance_before, balance_after,
                    narration, financial_year_id)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (date.today().isoformat(), 'ADJUSTMENT', adjustment.item_id,
                 'IN' if adjustment.adjustment_type == 'ADD' else 'OUT',
                 adjustment.quantity, balance_before, new_stock,
                 adjustment.reason, fy_id)
            )
            
            conn.commit()
            
            return APIResponse(
                success=True, 
                message="Stock adjusted",
                data={"new_stock": new_stock}
            )
            
        except Exception as e:
            conn.rollback()
            raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/inventory/batches", response_model=List[ItemBatch])
async def get_item_batches(item_id: int):
    """Get batches for a specific item"""
    return DatabaseHelper.execute_query(
        "SELECT * FROM item_batches WHERE item_id = ? ORDER BY created_at DESC",
        (item_id,)
    )


@app.get("/api/inventory/serials", response_model=List[ItemSerial])
async def get_item_serials(item_id: int, status: Optional[str] = None):
    """Get serials for a specific item"""
    query = "SELECT * FROM item_serials WHERE item_id = ?"
    params = [item_id]
    if status:
        query += " AND status = ?"
        params.append(status)
    query += " ORDER BY created_at DESC"
    return DatabaseHelper.execute_query(query, tuple(params))


@app.get("/api/inventory/movements", response_model=List[StockMovementRecord])
async def get_inventory_movements(
    item_id: Optional[int] = None,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    limit: int = 50
):
    """Get inventory movement history"""
    query = """
        SELECT it.id, it.transaction_date, it.reference_type, it.reference_id,
               it.item_id, i.name as item_name, i.sku,
               COALESCE(u.code, 'NOS') as unit,
               b.batch_number, it.transaction_type, it.quantity, it.rate, it.amount,
               it.balance_before, it.balance_after, it.narration, it.voucher_number
        FROM inventory_transactions it
        JOIN items i ON it.item_id = i.id
        LEFT JOIN units u ON i.unit_id = u.id
        LEFT JOIN item_batches b ON it.batch_id = b.id
        WHERE 1 = 1
    """
    params: List = []
    if item_id is not None:
        query += " AND it.item_id = ?"
        params.append(item_id)
    if from_date is not None:
        query += " AND it.transaction_date >= ?"
        params.append(from_date.isoformat())
    if to_date is not None:
        query += " AND it.transaction_date <= ?"
        params.append(to_date.isoformat())
    query += " ORDER BY it.transaction_date DESC, it.id DESC LIMIT ?"
    params.append(limit)
    return DatabaseHelper.execute_query(query, tuple(params))


@app.post("/api/inventory/movements", response_model=APIResponse)
async def create_inventory_movement(movement: StockMovementCreate):
    """Create inventory movement with optional batch/serial tracking"""
    item = DatabaseHelper.execute_one(
        "SELECT * FROM items WHERE id = ?",
        (movement.item_id,)
    )
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    movement_key = movement.movement.strip().upper()
    movement_map = {
        "PURCHASE_IN": ("IN", 1, "PURCHASE"),
        "SALE_OUT": ("OUT", -1, "SALE"),
        "TRANSFER_OUT": ("TRANSFER", -1, "TRANSFER_OUT"),
        "TRANSFER_IN": ("TRANSFER", 1, "TRANSFER_IN"),
        "DAMAGE": ("OUT", -1, "DAMAGE"),
        "ADJUSTMENT_IN": ("ADJUSTMENT", 1, "ADJUSTMENT"),
        "ADJUSTMENT_OUT": ("ADJUSTMENT", -1, "ADJUSTMENT"),
    }
    if movement_key not in movement_map:
        raise HTTPException(status_code=400, detail="Invalid movement type")

    transaction_type, direction, default_reference = movement_map[movement_key]
    if movement.quantity <= 0:
        raise HTTPException(status_code=400, detail="Quantity must be greater than 0")

    allow_negative = _get_boolean_setting("enable_negative_stock", False)
    fy_id = FinancialYearHelper.ensure_current_fy()
    serials = [s.strip() for s in (movement.serial_numbers or []) if s and s.strip()]

    if item.get('serial_tracking') == 1:
        if not serials:
            raise HTTPException(status_code=400, detail="Serial numbers required for this item")
        if movement.quantity != int(movement.quantity) or int(movement.quantity) != len(serials):
            raise HTTPException(status_code=400, detail="Quantity must match serial count and be whole number")

    if item.get('batch_tracking') == 1 or item.get('expiry_tracking') == 1:
        if not movement.batch_number:
            raise HTTPException(status_code=400, detail="Batch number required for this item")

    with get_db_connection() as conn:
        try:
            balance_before = item['current_stock']
            new_stock = balance_before + (movement.quantity * direction)
            if new_stock < 0 and not allow_negative:
                raise HTTPException(status_code=400, detail="Stock cannot be negative")

            batch_id = None
            if movement.batch_number:
                batch = conn.execute(
                    "SELECT * FROM item_batches WHERE item_id = ? AND batch_number = ?",
                    (movement.item_id, movement.batch_number)
                ).fetchone()

                if not batch and direction < 0:
                    raise HTTPException(status_code=400, detail="Batch not found for outbound movement")

                if not batch:
                    cursor = conn.execute(
                        """INSERT INTO item_batches
                           (item_id, batch_number, manufacturing_date, expiry_date,
                            cost_price, selling_price, mrp, quantity)
                           VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                        (
                            movement.item_id,
                            movement.batch_number,
                            movement.manufacturing_date.isoformat() if movement.manufacturing_date else None,
                            movement.expiry_date.isoformat() if movement.expiry_date else None,
                            item['cost_price'],
                            item['selling_price'],
                            item['mrp'],
                            movement.quantity,
                        )
                    )
                    batch_id = cursor.lastrowid
                else:
                    batch_id = batch['id']
                    new_batch_qty = batch['quantity'] + (movement.quantity * direction)
                    if new_batch_qty < 0 and not allow_negative:
                        raise HTTPException(status_code=400, detail="Insufficient batch stock")
                    conn.execute(
                        "UPDATE item_batches SET quantity = ? WHERE id = ?",
                        (new_batch_qty, batch_id)
                    )

            if serials:
                if direction > 0:
                    for serial in serials:
                        conn.execute(
                            """INSERT INTO item_serials
                               (item_id, batch_id, serial_number, status, reference_type, reference_id)
                               VALUES (?, ?, ?, 'IN_STOCK', ?, ?)""",
                            (
                                movement.item_id,
                                batch_id,
                                serial,
                                movement.reference_type or default_reference,
                                movement.reference_id,
                            )
                        )
                else:
                    placeholders = ",".join(["?"] * len(serials))
                    rows = conn.execute(
                        f"SELECT * FROM item_serials WHERE item_id = ? AND serial_number IN ({placeholders})",
                        (movement.item_id, *serials)
                    ).fetchall()

                    if len(rows) != len(serials):
                        raise HTTPException(status_code=400, detail="Some serials were not found")

                    for row in rows:
                        if row['status'] != 'IN_STOCK':
                            raise HTTPException(status_code=400, detail="Serial not available in stock")

                    status_map = {
                        "SALE_OUT": "OUT",
                        "DAMAGE": "DAMAGED",
                        "TRANSFER_OUT": "TRANSFERRED",
                        "ADJUSTMENT_OUT": "ADJUSTED_OUT",
                    }
                    new_status = status_map.get(movement_key, "OUT")

                    for serial in serials:
                        conn.execute(
                            """UPDATE item_serials
                               SET status = ?, reference_type = ?, reference_id = ?, updated_at = CURRENT_TIMESTAMP
                               WHERE item_id = ? AND serial_number = ?""",
                            (
                                new_status,
                                movement.reference_type or default_reference,
                                movement.reference_id,
                                movement.item_id,
                                serial,
                            )
                        )

            conn.execute(
                "UPDATE items SET current_stock = ? WHERE id = ?",
                (new_stock, movement.item_id)
            )

            amount = movement.quantity * movement.rate
            cursor = conn.execute(
                """INSERT INTO inventory_transactions
                   (transaction_date, reference_type, reference_id, item_id, batch_id,
                    transaction_type, quantity, rate, amount,
                    balance_before, balance_after, narration, financial_year_id, voucher_number)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    date.today().isoformat(),
                    movement.reference_type or default_reference,
                    movement.reference_id,
                    movement.item_id,
                    batch_id,
                    transaction_type,
                    movement.quantity,
                    movement.rate,
                    amount,
                    balance_before,
                    new_stock,
                    movement.narration,
                    fy_id,
                    movement.reference_number,
                )
            )
            transaction_id = cursor.lastrowid

            if serials:
                placeholders = ",".join(["?"] * len(serials))
                serial_rows = conn.execute(
                    f"SELECT id FROM item_serials WHERE item_id = ? AND serial_number IN ({placeholders})",
                    (movement.item_id, *serials)
                ).fetchall()
                conn.executemany(
                    "INSERT INTO inventory_transaction_serials (inventory_transaction_id, serial_id) VALUES (?, ?)",
                    [(transaction_id, row['id']) for row in serial_rows]
                )

            conn.commit()
            return APIResponse(
                success=True,
                message="Stock movement posted",
                data={"transaction_id": transaction_id, "new_stock": new_stock}
            )

        except HTTPException:
            conn.rollback()
            raise
        except Exception as e:
            conn.rollback()
            raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# REPORTS ENDPOINTS
# ============================================================================

@app.get("/api/reports/inventory/valuation")
async def get_inventory_valuation(method: str = "fifo"):
    """Get inventory valuation summary"""
    result = DatabaseHelper.execute_one(
        """SELECT
            COUNT(*) as total_items,
            COALESCE(SUM(current_stock), 0) as total_quantity,
            COALESCE(SUM(current_stock * cost_price), 0) as total_purchase_value,
            COALESCE(SUM(current_stock * selling_price), 0) as total_selling_value
           FROM items
           WHERE is_active = 1"""
    )
    total_purchase = result['total_purchase_value'] if result else 0
    total_selling = result['total_selling_value'] if result else 0
    return {
        "valuation_method": method,
        "total_items": result['total_items'] if result else 0,
        "total_quantity": result['total_quantity'] if result else 0,
        "total_purchase_value": total_purchase,
        "total_selling_value": total_selling,
        "potential_profit": total_selling - total_purchase,
    }


@app.get("/api/reports/inventory/aging")
async def get_inventory_aging(
    as_of: Optional[date] = None,
    buckets: Optional[str] = None
):
    """Get inventory aging buckets"""
    as_of_date = as_of or date.today()
    bucket_edges = [30, 60, 90]
    if buckets:
        try:
            bucket_edges = [int(x.strip()) for x in buckets.split(',') if x.strip()]
            bucket_edges = sorted([b for b in bucket_edges if b > 0])
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid buckets parameter")

    items = DatabaseHelper.execute_query(
        """SELECT i.id, i.name, i.sku, i.current_stock, i.cost_price,
                  COALESCE(MAX(t.transaction_date), DATE(i.created_at)) as last_movement
           FROM items i
           LEFT JOIN inventory_transactions t ON t.item_id = i.id
           WHERE i.is_active = 1 AND i.current_stock > 0
           GROUP BY i.id"""
    )

    bucket_labels = []
    previous = 0
    for edge in bucket_edges:
        bucket_labels.append((previous + 1, edge))
        previous = edge
    bucket_labels.append((previous + 1, None))

    buckets_result = []
    for start, end in bucket_labels:
        label = f"{start}-{end} days" if end else f"{start}+ days"
        buckets_result.append({"label": label, "sku_count": 0, "value": 0})

    for item in items:
        last_movement = date.fromisoformat(item['last_movement']) if item['last_movement'] else as_of_date
        age_days = (as_of_date - last_movement).days
        value = item['current_stock'] * item['cost_price']
        for idx, (start, end) in enumerate(bucket_labels):
            if end is None and age_days >= start:
                buckets_result[idx]['sku_count'] += 1
                buckets_result[idx]['value'] += value
                break
            if end is not None and start <= age_days <= end:
                buckets_result[idx]['sku_count'] += 1
                buckets_result[idx]['value'] += value
                break

    return buckets_result


@app.get("/api/reports/inventory/dead-stock")
async def get_dead_stock(days: int = 90):
    """Get items with no movement beyond the given threshold"""
    as_of_date = date.today()
    items = DatabaseHelper.execute_query(
        """SELECT i.id, i.name, i.sku, i.current_stock, i.cost_price,
                  COALESCE(MAX(t.transaction_date), DATE(i.created_at)) as last_movement
           FROM items i
           LEFT JOIN inventory_transactions t ON t.item_id = i.id
           WHERE i.is_active = 1 AND i.current_stock > 0
           GROUP BY i.id"""
    )
    result = []
    for item in items:
        last_movement = date.fromisoformat(item['last_movement']) if item['last_movement'] else as_of_date
        age_days = (as_of_date - last_movement).days
        if age_days >= days:
            result.append({
                "name": item['name'],
                "sku": item['sku'],
                "days": age_days,
                "value": item['current_stock'] * item['cost_price'],
            })
    return result


@app.get("/api/reports/inventory/fast-moving")
async def get_fast_moving(days: int = 30, limit: int = 10):
    """Get fast moving items by outbound quantity"""
    end_date = date.today()
    start_date = end_date - timedelta(days=days)
    result = DatabaseHelper.execute_query(
        """SELECT i.name, i.sku, SUM(t.quantity) as quantity, SUM(t.amount) as value
           FROM inventory_transactions t
           JOIN items i ON t.item_id = i.id
           WHERE t.transaction_type = 'OUT'
           AND t.transaction_date BETWEEN ? AND ?
           GROUP BY t.item_id
           ORDER BY quantity DESC
           LIMIT ?""",
        (start_date.isoformat(), end_date.isoformat(), limit)
    )
    return result


# ============================================================================
# EXPENSES & OTHER INCOME ENDPOINTS
# ============================================================================


@app.get("/api/expenses/categories", response_model=List[ExpenseCategory])
async def get_expense_categories():
    return DatabaseHelper.execute_query(
        "SELECT * FROM expense_categories WHERE is_active = 1 ORDER BY name"
    )


@app.post("/api/expenses/categories", response_model=APIResponse)
async def create_expense_category(category: ExpenseCategoryCreate):
    category_id = DatabaseHelper.execute_insert(
        """INSERT INTO expense_categories (name, classification, ledger_id, gst_eligible)
           VALUES (?, ?, ?, ?)""",
        (
            category.name,
            category.classification.value,
            category.ledger_id,
            1 if category.gst_eligible else 0,
        )
    )
    return APIResponse(success=True, message="Expense category created", data={"id": category_id})


@app.get("/api/expenses", response_model=List[ExpenseEntry])
async def get_expenses(
    category_id: Optional[int] = None,
    vendor_ledger_id: Optional[int] = None,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
):
    query = """
        SELECT e.*, c.name as category_name, v.name as vendor_name
        FROM expenses e
        JOIN expense_categories c ON e.category_id = c.id
        LEFT JOIN ledgers v ON e.vendor_ledger_id = v.id
        WHERE 1 = 1
    """
    params: List = []
    if category_id:
        query += " AND e.category_id = ?"
        params.append(category_id)
    if vendor_ledger_id:
        query += " AND e.vendor_ledger_id = ?"
        params.append(vendor_ledger_id)
    if from_date:
        query += " AND e.expense_date >= ?"
        params.append(from_date.isoformat())
    if to_date:
        query += " AND e.expense_date <= ?"
        params.append(to_date.isoformat())
    query += " ORDER BY e.expense_date DESC, e.id DESC"
    return DatabaseHelper.execute_query(query, tuple(params))


@app.post("/api/expenses", response_model=APIResponse)
async def create_expense(expense: ExpenseEntryCreate):
    category = DatabaseHelper.execute_one(
        "SELECT * FROM expense_categories WHERE id = ?",
        (expense.category_id,)
    )
    if not category:
        raise HTTPException(status_code=404, detail="Expense category not found")

    gst_split = _calculate_gst_split(expense.taxable_amount, expense.gst_rate)
    total_amount = expense.taxable_amount + gst_split['total_gst_amount']

    paid_amount = expense.paid_amount
    if expense.is_credit or expense.payment_mode == PaymentMode.CREDIT:
        paid_amount = 0
    if paid_amount > total_amount:
        raise HTTPException(status_code=400, detail="Paid amount cannot exceed total")

    balance_amount = total_amount - paid_amount
    payment_status = "PAID" if balance_amount <= 0 else ("PARTIAL" if paid_amount > 0 else "UNPAID")

    fy_id = FinancialYearHelper.ensure_current_fy()

    with get_db_connection() as conn:
        try:
            cursor = conn.execute(
                """INSERT INTO expenses
                   (expense_date, category_id, vendor_ledger_id, reference_no, description,
                    taxable_amount, gst_rate, cgst_amount, sgst_amount, igst_amount, total_gst_amount,
                    total_amount, itc_eligible, payment_mode, paid_amount, balance_amount,
                    payment_status, is_credit, due_date)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    expense.expense_date.isoformat(),
                    expense.category_id,
                    expense.vendor_ledger_id,
                    expense.reference_no,
                    expense.description,
                    expense.taxable_amount,
                    expense.gst_rate,
                    gst_split['cgst_amount'],
                    gst_split['sgst_amount'],
                    gst_split['igst_amount'],
                    gst_split['total_gst_amount'],
                    total_amount,
                    1 if expense.itc_eligible else 0,
                    expense.payment_mode.value if expense.payment_mode else None,
                    paid_amount,
                    balance_amount,
                    payment_status,
                    1 if expense.is_credit else 0,
                    expense.due_date.isoformat() if expense.due_date else None,
                )
            )
            expense_id = cursor.lastrowid

            expense_ledger_id = _resolve_expense_ledger(category)
            itc_ledger_id = _get_itc_ledger_id() if expense.itc_eligible and gst_split['total_gst_amount'] > 0 else None

            debit_amount = total_amount if not expense.itc_eligible else expense.taxable_amount
            conn.execute(
                """INSERT INTO ledger_transactions
                   (transaction_date, voucher_type_id, voucher_number, reference_id, reference_type,
                    ledger_id, debit_amount, credit_amount, narration, financial_year_id)
                   VALUES (?, NULL, NULL, ?, 'EXPENSE', ?, ?, 0, ?, ?)""",
                (
                    expense.expense_date.isoformat(),
                    expense_id,
                    expense_ledger_id,
                    debit_amount,
                    f"Expense: {category['name']}",
                    fy_id,
                )
            )

            if itc_ledger_id:
                conn.execute(
                    """INSERT INTO ledger_transactions
                       (transaction_date, voucher_type_id, voucher_number, reference_id, reference_type,
                        ledger_id, debit_amount, credit_amount, narration, financial_year_id)
                       VALUES (?, NULL, NULL, ?, 'EXPENSE', ?, ?, 0, ?, ?)""",
                    (
                        expense.expense_date.isoformat(),
                        expense_id,
                        itc_ledger_id,
                        gst_split['total_gst_amount'],
                        "Input GST (ITC)",
                        fy_id,
                    )
                )

            if paid_amount > 0:
                payment_ledger_id = _get_cash_ledger_id() if expense.payment_mode in (PaymentMode.CASH, None) else _get_bank_ledger_id()
                conn.execute(
                    """INSERT INTO ledger_transactions
                       (transaction_date, voucher_type_id, voucher_number, reference_id, reference_type,
                        ledger_id, debit_amount, credit_amount, narration, financial_year_id)
                       VALUES (?, NULL, NULL, ?, 'EXPENSE', ?, 0, ?, ?, ?)""",
                    (
                        expense.expense_date.isoformat(),
                        expense_id,
                        payment_ledger_id,
                        paid_amount,
                        "Expense payment",
                        fy_id,
                    )
                )

            if balance_amount > 0 and expense.vendor_ledger_id:
                conn.execute(
                    """INSERT INTO ledger_transactions
                       (transaction_date, voucher_type_id, voucher_number, reference_id, reference_type,
                        ledger_id, debit_amount, credit_amount, narration, financial_year_id)
                       VALUES (?, NULL, NULL, ?, 'EXPENSE', ?, 0, ?, ?, ?)""",
                    (
                        expense.expense_date.isoformat(),
                        expense_id,
                        expense.vendor_ledger_id,
                        balance_amount,
                        "Expense payable",
                        fy_id,
                    )
                )
                conn.execute(
                    "UPDATE ledgers SET current_balance = current_balance + ? WHERE id = ?",
                    (balance_amount, expense.vendor_ledger_id)
                )

            conn.commit()
            return APIResponse(success=True, message="Expense recorded", data={"id": expense_id})
        except Exception as exc:
            conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc))


@app.post("/api/expenses/{expense_id}/attachments", response_model=APIResponse)
async def add_expense_attachment(expense_id: int, attachment: ExpenseAttachmentCreate):
    exists = DatabaseHelper.execute_one(
        "SELECT id FROM expenses WHERE id = ?",
        (expense_id,)
    )
    if not exists:
        raise HTTPException(status_code=404, detail="Expense not found")
    attachment_id = DatabaseHelper.execute_insert(
        """INSERT INTO expense_attachments (expense_id, file_path, file_name)
           VALUES (?, ?, ?)""",
        (expense_id, attachment.file_path, attachment.file_name)
    )
    return APIResponse(success=True, message="Attachment saved", data={"id": attachment_id})


@app.get("/api/expenses/recurring", response_model=List[ExpenseRecurring])
async def get_recurring_expenses():
    return DatabaseHelper.execute_query(
        """
        SELECT r.*, c.name as category_name, v.name as vendor_name
        FROM expense_recurring r
        JOIN expense_categories c ON r.category_id = c.id
        LEFT JOIN ledgers v ON r.vendor_ledger_id = v.id
        WHERE r.is_active = 1
        ORDER BY r.next_run_date
        """
    )


@app.post("/api/expenses/recurring", response_model=APIResponse)
async def create_recurring_expense(recurring: ExpenseRecurringCreate):
    recurring_id = DatabaseHelper.execute_insert(
        """INSERT INTO expense_recurring
           (template_name, category_id, vendor_ledger_id, description,
            taxable_amount, gst_rate, itc_eligible, payment_mode, is_credit,
            frequency, next_run_date)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            recurring.template_name,
            recurring.category_id,
            recurring.vendor_ledger_id,
            recurring.description,
            recurring.taxable_amount,
            recurring.gst_rate,
            1 if recurring.itc_eligible else 0,
            recurring.payment_mode.value if recurring.payment_mode else None,
            1 if recurring.is_credit else 0,
            recurring.frequency.value,
            recurring.next_run_date.isoformat(),
        )
    )
    return APIResponse(success=True, message="Recurring expense created", data={"id": recurring_id})


@app.post("/api/expenses/recurring/{recurring_id}/run", response_model=APIResponse)
async def run_recurring_expense(recurring_id: int):
    recurring = DatabaseHelper.execute_one(
        "SELECT * FROM expense_recurring WHERE id = ?",
        (recurring_id,)
    )
    if not recurring:
        raise HTTPException(status_code=404, detail="Recurring template not found")

    payload = ExpenseEntryCreate(
        expense_date=date.fromisoformat(recurring['next_run_date']),
        category_id=recurring['category_id'],
        vendor_ledger_id=recurring['vendor_ledger_id'],
        description=recurring.get('description'),
        taxable_amount=recurring.get('taxable_amount', 0),
        gst_rate=recurring.get('gst_rate', 0),
        itc_eligible=bool(recurring.get('itc_eligible', 1)),
        payment_mode=PaymentMode(recurring['payment_mode']) if recurring.get('payment_mode') else None,
        paid_amount=0,
        is_credit=bool(recurring.get('is_credit', 0)),
    )
    response = await create_expense(payload)

    frequency = recurring['frequency']
    next_date = date.fromisoformat(recurring['next_run_date'])
    if frequency == 'WEEKLY':
        next_date = next_date + timedelta(days=7)
    elif frequency == 'MONTHLY':
        next_date = next_date + timedelta(days=30)
    elif frequency == 'QUARTERLY':
        next_date = next_date + timedelta(days=90)
    else:
        next_date = next_date + timedelta(days=365)

    DatabaseHelper.execute_update(
        """UPDATE expense_recurring
           SET last_run_date = ?, next_run_date = ?, updated_at = CURRENT_TIMESTAMP
           WHERE id = ?""",
        (date.today().isoformat(), next_date.isoformat(), recurring_id)
    )

    return response


@app.get("/api/other-income", response_model=List[OtherIncome])
async def get_other_income():
    return DatabaseHelper.execute_query(
        """SELECT o.*, l.name as ledger_name
           FROM other_income_entries o
           LEFT JOIN ledgers l ON o.ledger_id = l.id
           ORDER BY o.income_date DESC, o.id DESC"""
    )


@app.post("/api/other-income", response_model=APIResponse)
async def create_other_income(income: OtherIncomeCreate):
    ledger_id = income.ledger_id
    if not ledger_id:
        ledger_id = _get_or_create_ledger("Other Income", "Indirect Income")

    income_id = DatabaseHelper.execute_insert(
        """INSERT INTO other_income_entries
           (income_date, ledger_id, reference_no, description, amount, payment_mode)
           VALUES (?, ?, ?, ?, ?, ?)""",
        (
            income.income_date.isoformat(),
            ledger_id,
            income.reference_no,
            income.description,
            income.amount,
            income.payment_mode.value if income.payment_mode else None,
        )
    )

    fy_id = FinancialYearHelper.ensure_current_fy()
    payment_ledger_id = _get_cash_ledger_id() if income.payment_mode in (PaymentMode.CASH, None) else _get_bank_ledger_id()
    DatabaseHelper.execute_insert(
        """INSERT INTO ledger_transactions
           (transaction_date, voucher_type_id, voucher_number, reference_id, reference_type,
            ledger_id, debit_amount, credit_amount, narration, financial_year_id)
           VALUES (?, NULL, NULL, ?, 'OTHER_INCOME', ?, 0, ?, ?, ?)""",
        (
            income.income_date.isoformat(),
            income_id,
            ledger_id,
            income.amount,
            "Other income",
            fy_id,
        )
    )
    DatabaseHelper.execute_insert(
        """INSERT INTO ledger_transactions
           (transaction_date, voucher_type_id, voucher_number, reference_id, reference_type,
            ledger_id, debit_amount, credit_amount, narration, financial_year_id)
           VALUES (?, NULL, NULL, ?, 'OTHER_INCOME', ?, ?, 0, ?, ?)""",
        (
            income.income_date.isoformat(),
            income_id,
            payment_ledger_id,
            income.amount,
            "Other income receipt",
            fy_id,
        )
    )

    return APIResponse(success=True, message="Other income recorded", data={"id": income_id})


# ============================================================================
# CRM ENDPOINTS
# ============================================================================

@app.get("/api/crm/pipeline", response_model=List[CRMPipelineStage])
async def get_crm_pipeline():
    return DatabaseHelper.execute_query(
        "SELECT * FROM crm_pipeline_stages WHERE is_active = 1 ORDER BY sort_order"
    )


@app.get("/api/crm/staff", response_model=List[CRMStaff])
async def get_crm_staff():
    return DatabaseHelper.execute_query(
        "SELECT * FROM crm_staff WHERE is_active = 1 ORDER BY name"
    )


@app.post("/api/crm/staff", response_model=APIResponse)
async def create_crm_staff(staff: CRMStaffCreate):
    staff_id = DatabaseHelper.execute_insert(
        "INSERT INTO crm_staff (name, email, phone) VALUES (?, ?, ?)",
        (staff.name, staff.email, staff.phone)
    )
    return APIResponse(success=True, message="Staff created", data={"id": staff_id})


@app.put("/api/crm/staff/{staff_id}", response_model=APIResponse)
async def update_crm_staff(staff_id: int, staff: CRMStaffUpdate):
    existing = DatabaseHelper.execute_one(
        "SELECT * FROM crm_staff WHERE id = ?",
        (staff_id,)
    )
    if not existing:
        raise HTTPException(status_code=404, detail="Staff not found")

    update_fields = []
    update_values = []

    for field, value in staff.model_dump(exclude_unset=True).items():
        if value is not None:
            update_fields.append(f"{field} = ?")
            update_values.append(value)

    if update_fields:
        update_values.append(staff_id)
        DatabaseHelper.execute_update(
            f"UPDATE crm_staff SET {', '.join(update_fields)} WHERE id = ?",
            tuple(update_values)
        )

    return APIResponse(success=True, message="Staff updated")


@app.get("/api/crm/leads", response_model=List[CRMLead])
async def get_crm_leads(
    status: Optional[str] = None,
    stage_id: Optional[int] = None,
    assigned_staff_id: Optional[int] = None,
    search: Optional[str] = None,
):
    query = """
        SELECT l.*, s.name as assigned_staff, p.name as pipeline_stage
        FROM crm_leads l
        LEFT JOIN crm_staff s ON l.assigned_staff_id = s.id
        LEFT JOIN crm_pipeline_stages p ON l.pipeline_stage_id = p.id
        WHERE 1 = 1
    """
    params: List = []

    if status:
        query += " AND l.status = ?"
        params.append(status)
    if stage_id:
        query += " AND l.pipeline_stage_id = ?"
        params.append(stage_id)
    if assigned_staff_id:
        query += " AND l.assigned_staff_id = ?"
        params.append(assigned_staff_id)
    if search:
        query += " AND (l.name LIKE ? OR l.company_name LIKE ? OR l.phone LIKE ? OR l.email LIKE ?)"
        like = f"%{search}%"
        params.extend([like, like, like, like])

    query += " ORDER BY l.updated_at DESC"
    return DatabaseHelper.execute_query(query, tuple(params))


@app.get("/api/crm/leads/{lead_id}/timeline")
async def get_crm_lead_timeline(lead_id: int):
    notes = DatabaseHelper.execute_query(
        """SELECT id, note as detail, created_by, created_at
           FROM crm_lead_notes WHERE lead_id = ?""",
        (lead_id,)
    )
    calls = DatabaseHelper.execute_query(
        """SELECT id, notes as detail, outcome, call_type, duration_seconds, created_at
           FROM crm_call_logs WHERE lead_id = ?""",
        (lead_id,)
    )
    followups = DatabaseHelper.execute_query(
        """SELECT id, notes as detail, followup_date, status, created_at
           FROM crm_followups WHERE lead_id = ?""",
        (lead_id,)
    )

    items = []
    for row in notes:
        items.append({
            "type": "note",
            "title": "Note",
            "detail": row.get("detail"),
            "meta": row.get("created_by"),
            "created_at": row.get("created_at"),
        })
    for row in calls:
        items.append({
            "type": "call",
            "title": row.get("call_type", "Call"),
            "detail": row.get("detail"),
            "meta": row.get("outcome"),
            "duration": row.get("duration_seconds"),
            "created_at": row.get("created_at"),
        })
    for row in followups:
        items.append({
            "type": "followup",
            "title": "Follow-up",
            "detail": row.get("detail"),
            "meta": row.get("status"),
            "followup_date": row.get("followup_date"),
            "created_at": row.get("created_at"),
        })

    items.sort(key=lambda x: x.get("created_at") or "", reverse=True)
    return items


@app.post("/api/crm/leads", response_model=APIResponse)
async def create_crm_lead(lead: CRMLeadCreate):
    lead_id = DatabaseHelper.execute_insert(
        """INSERT INTO crm_leads
           (name, company_name, phone, email, gstin, source, status,
            pipeline_stage_id, assigned_staff_id, credit_limit, expected_value,
            notes, next_followup_date)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            lead.name,
            lead.company_name,
            lead.phone,
            lead.email,
            lead.gstin,
            lead.source,
            lead.status or 'New',
            lead.pipeline_stage_id,
            lead.assigned_staff_id,
            lead.credit_limit,
            lead.expected_value,
            lead.notes,
            lead.next_followup_date.isoformat() if lead.next_followup_date else None,
        )
    )
    return APIResponse(success=True, message="Lead created", data={"id": lead_id})


@app.put("/api/crm/leads/{lead_id}", response_model=APIResponse)
async def update_crm_lead(lead_id: int, lead: CRMLeadUpdate):
    existing = DatabaseHelper.execute_one(
        "SELECT * FROM crm_leads WHERE id = ?",
        (lead_id,)
    )
    if not existing:
        raise HTTPException(status_code=404, detail="Lead not found")

    update_fields = []
    update_values = []

    for field, value in lead.model_dump(exclude_unset=True).items():
        if value is not None:
            update_fields.append(f"{field} = ?")
            update_values.append(
                value.isoformat() if isinstance(value, date) else value
            )

    if update_fields:
        update_fields.append("updated_at = CURRENT_TIMESTAMP")
        update_values.append(lead_id)
        DatabaseHelper.execute_update(
            f"UPDATE crm_leads SET {', '.join(update_fields)} WHERE id = ?",
            tuple(update_values)
        )

    return APIResponse(success=True, message="Lead updated")


@app.post("/api/crm/leads/notes", response_model=APIResponse)
async def create_crm_note(note: CRMNoteCreate):
    note_id = DatabaseHelper.execute_insert(
        "INSERT INTO crm_lead_notes (lead_id, note, created_by) VALUES (?, ?, ?)",
        (note.lead_id, note.note, note.created_by)
    )
    return APIResponse(success=True, message="Note added", data={"id": note_id})


@app.post("/api/crm/leads/calls", response_model=APIResponse)
async def create_crm_call(call: CRMCallCreate):
    call_id = DatabaseHelper.execute_insert(
        """INSERT INTO crm_call_logs
           (lead_id, call_type, outcome, duration_seconds, notes, created_by)
           VALUES (?, ?, ?, ?, ?, ?)""",
        (call.lead_id, call.call_type, call.outcome, call.duration_seconds, call.notes, call.created_by)
    )
    return APIResponse(success=True, message="Call log added", data={"id": call_id})


@app.post("/api/crm/leads/followups", response_model=APIResponse)
async def create_crm_followup(followup: CRMFollowUpCreate):
    follow_id = DatabaseHelper.execute_insert(
        """INSERT INTO crm_followups
           (lead_id, followup_date, reminder_time, status, notes, created_by)
           VALUES (?, ?, ?, ?, ?, ?)""",
        (
            followup.lead_id,
            followup.followup_date.isoformat(),
            followup.reminder_time,
            followup.status or 'PENDING',
            followup.notes,
            followup.created_by,
        )
    )
    DatabaseHelper.execute_update(
        "UPDATE crm_leads SET next_followup_date = ? WHERE id = ?",
        (followup.followup_date.isoformat(), followup.lead_id)
    )
    return APIResponse(success=True, message="Follow-up scheduled", data={"id": follow_id})


@app.get("/api/crm/followups", response_model=List[CRMFollowUp])
async def get_crm_followups(status: Optional[str] = None):
    query = """
        SELECT f.id, f.lead_id, l.name as lead_name,
               f.followup_date, f.reminder_time, f.status, f.notes, f.created_at
        FROM crm_followups f
        JOIN crm_leads l ON f.lead_id = l.id
        WHERE 1 = 1
    """
    params: List = []
    if status:
        query += " AND f.status = ?"
        params.append(status)
    query += " ORDER BY f.followup_date ASC"
    return DatabaseHelper.execute_query(query, tuple(params))


@app.get("/api/crm/customers", response_model=List[CRMCustomerRisk])
async def get_crm_customers(search: Optional[str] = None):
    query = """
        SELECT l.id as ledger_id, l.name, l.gstin, l.credit_limit,
               COALESCE(SUM(i.grand_total), 0) as total_sales,
               COALESCE(SUM(i.balance_amount), 0) as outstanding,
               COALESCE(MAX(v.overdue_days), 0) as overdue_days
        FROM ledgers l
        LEFT JOIN invoices i ON i.party_id = l.id AND i.status = 'CONFIRMED' AND i.is_deleted = 0
        LEFT JOIN v_outstanding_invoices v ON v.party_name = l.name
        WHERE l.is_party = 1
    """
    params: List = []
    if search:
        query += " AND (l.name LIKE ? OR l.gstin LIKE ? OR l.phone LIKE ?)"
        like = f"%{search}%"
        params.extend([like, like, like])
    query += " GROUP BY l.id ORDER BY l.name"
    customers = DatabaseHelper.execute_query(query, tuple(params))

    result = []
    for c in customers:
        outstanding = c['outstanding'] or 0
        credit_limit = c['credit_limit'] or 0
        overdue_days = c['overdue_days'] or 0
        risk_level = "LOW"
        if credit_limit > 0 and outstanding > credit_limit:
            risk_level = "HIGH"
        elif outstanding > 0 and overdue_days > 30:
            risk_level = "MEDIUM"
        result.append({
            "ledger_id": c['ledger_id'],
            "name": c['name'],
            "gstin": c['gstin'],
            "credit_limit": credit_limit,
            "outstanding": outstanding,
            "total_sales": c['total_sales'] or 0,
            "overdue_days": overdue_days,
            "risk_level": risk_level,
        })
    return result


@app.get("/api/crm/reports")
async def get_crm_reports():
    total_leads = DatabaseHelper.execute_one(
        "SELECT COUNT(*) as count FROM crm_leads"
    )
    won_leads = DatabaseHelper.execute_one(
        """SELECT COUNT(*) as count
           FROM crm_leads l
           JOIN crm_pipeline_stages p ON l.pipeline_stage_id = p.id
           WHERE p.is_won = 1"""
    )
    total_sales = DatabaseHelper.execute_one(
        "SELECT COALESCE(SUM(grand_total), 0) as total_sales FROM invoices WHERE status = 'CONFIRMED' AND is_deleted = 0"
    )
    outstanding = DatabaseHelper.execute_one(
        "SELECT COALESCE(SUM(balance_amount), 0) as outstanding FROM invoices WHERE status = 'CONFIRMED' AND is_deleted = 0"
    )

    total_count = total_leads['count'] if total_leads else 0
    won_count = won_leads['count'] if won_leads else 0
    conversion_rate = (won_count / total_count * 100) if total_count else 0
    recovery_efficiency = 0
    total_sales_amount = total_sales['total_sales'] if total_sales else 0
    outstanding_amount = outstanding['outstanding'] if outstanding else 0
    if total_sales_amount:
        recovery_efficiency = ((total_sales_amount - outstanding_amount) / total_sales_amount) * 100

    return {
        "lead_count": total_count,
        "won_leads": won_count,
        "conversion_rate": conversion_rate,
        "lifetime_value": total_sales_amount,
        "recovery_efficiency": recovery_efficiency,
    }

@app.get("/api/reports/sales-summary")
async def get_sales_summary(
    from_date: date,
    to_date: date
):
    """Get sales summary for date range"""
    result = DatabaseHelper.execute_one(
        """SELECT 
            COUNT(*) as invoice_count,
            COALESCE(SUM(grand_total), 0) as total_sales,
            COALESCE(SUM(total_tax_amount), 0) as total_tax,
            COALESCE(SUM(discount_amount), 0) as total_discount
           FROM invoices 
           WHERE voucher_type_id = 1 
           AND status = 'CONFIRMED'
           AND is_deleted = 0
           AND invoice_date BETWEEN ? AND ?""",
        (from_date.isoformat(), to_date.isoformat())
    )
    return result


@app.get("/api/reports/gst-summary")
async def get_gst_summary(
    from_date: date,
    to_date: date
):
    """Get GST summary for date range (GSTR-3B style)"""
    result = DatabaseHelper.execute_one(
        """SELECT 
            COALESCE(SUM(taxable_amount), 0) as total_taxable,
            COALESCE(SUM(cgst_amount), 0) as total_cgst,
            COALESCE(SUM(sgst_amount), 0) as total_sgst,
            COALESCE(SUM(igst_amount), 0) as total_igst,
            COALESCE(SUM(cess_amount), 0) as total_cess,
            COUNT(*) as invoice_count
           FROM invoices 
           WHERE status = 'CONFIRMED'
           AND is_deleted = 0
           AND invoice_date BETWEEN ? AND ?""",
        (from_date.isoformat(), to_date.isoformat())
    )
    return result


@app.get("/api/reports/hsn-summary")
async def get_hsn_summary(
    from_date: date,
    to_date: date
):
    """Get HSN-wise tax summary for date range"""
    return DatabaseHelper.execute_query(
        """SELECT 
            its.hsn_code,
            SUM(its.total_quantity) as quantity,
            SUM(its.taxable_amount) as taxable_amount,
            its.gst_rate,
            SUM(its.cgst_amount) as cgst_amount,
            SUM(its.sgst_amount) as sgst_amount,
            SUM(its.igst_amount) as igst_amount,
            SUM(its.cess_amount) as cess_amount,
            SUM(its.total_tax_amount) as total_tax
           FROM invoice_tax_summary its
           JOIN invoices i ON its.invoice_id = i.id
           WHERE i.status = 'CONFIRMED'
           AND i.is_deleted = 0
           AND i.invoice_date BETWEEN ? AND ?
           GROUP BY its.hsn_code, its.gst_rate
           ORDER BY its.hsn_code""",
        (from_date.isoformat(), to_date.isoformat())
    )


@app.get("/api/reports/outstanding")
async def get_outstanding_invoices():
    """Get outstanding (unpaid/partial) invoices"""
    return DatabaseHelper.execute_query(
        """SELECT * FROM v_outstanding_invoices ORDER BY overdue_days DESC, invoice_date"""
    )


# ============================================================================
# ITR REPORTS (Income Tax Return)
# ============================================================================

@app.get("/api/reports/itr/pl")
async def get_profit_loss(
    from_date: date,
    to_date: date,
    financial_year_id: Optional[int] = None
):
    """Profit & Loss statement - Income vs Expenses by ledger groups"""
    fy_filter = ""
    params: list = [from_date.isoformat(), to_date.isoformat()]
    if financial_year_id:
        fy_filter = " AND lt.financial_year_id = ?"
        params.append(financial_year_id)

    # Income (ledger groups with nature INCOME)
    income = DatabaseHelper.execute_query(
        f"""SELECT lg.name as group_name, l.name as ledger_name,
            COALESCE(SUM(lt.credit_amount - lt.debit_amount), 0) as amount
           FROM ledger_groups lg
           JOIN ledgers l ON l.ledger_group_id = lg.id
           LEFT JOIN ledger_transactions lt ON lt.ledger_id = l.id
               AND lt.transaction_date BETWEEN ? AND ? {fy_filter}
               AND lt.is_opening_balance = 0
           WHERE lg.nature = 'INCOME'
           GROUP BY lg.id, l.id
           HAVING amount != 0
           ORDER BY lg.name, l.name""",
        tuple(params)
    )

    # Expenses (ledger groups with nature EXPENSES)
    expense_params = [from_date.isoformat(), to_date.isoformat()]
    if financial_year_id:
        expense_params.append(financial_year_id)
    expenses = DatabaseHelper.execute_query(
        f"""SELECT lg.name as group_name, l.name as ledger_name,
            COALESCE(SUM(lt.debit_amount - lt.credit_amount), 0) as amount
           FROM ledger_groups lg
           JOIN ledgers l ON l.ledger_group_id = lg.id
           LEFT JOIN ledger_transactions lt ON lt.ledger_id = l.id
               AND lt.transaction_date BETWEEN ? AND ? {fy_filter}
               AND lt.is_opening_balance = 0
           WHERE lg.nature = 'EXPENSES'
           GROUP BY lg.id, l.id
           HAVING amount != 0
           ORDER BY lg.name, l.name""",
        tuple(expense_params)
    )

    total_income = sum(float(r.get('amount', 0) or 0) for r in income)
    total_expenses = sum(float(r.get('amount', 0) or 0) for r in expenses)
    net_profit = total_income - total_expenses

    return {
        "from_date": from_date.isoformat(),
        "to_date": to_date.isoformat(),
        "income": income,
        "expenses": expenses,
        "total_income": total_income,
        "total_expenses": total_expenses,
        "net_profit": net_profit,
    }


@app.get("/api/reports/itr/balance-sheet")
async def get_balance_sheet(
    as_on_date: date,
    financial_year_id: Optional[int] = None
):
    """Balance Sheet - Assets and Liabilities as on date"""
    fy_filter = ""
    params: list = [as_on_date.isoformat()]
    if financial_year_id:
        fy_filter = " AND lt.financial_year_id = ?"
        params.append(financial_year_id)

    # Assets
    assets = DatabaseHelper.execute_query(
        f"""SELECT lg.name as group_name, l.name as ledger_name,
            COALESCE(l.opening_balance, 0) + COALESCE(SUM(
                CASE WHEN l.balance_type = 'DR' THEN lt.debit_amount - lt.credit_amount
                     ELSE lt.credit_amount - lt.debit_amount END
            ), 0) as balance
           FROM ledger_groups lg
           JOIN ledgers l ON l.ledger_group_id = lg.id
           LEFT JOIN ledger_transactions lt ON lt.ledger_id = l.id
               AND lt.transaction_date <= ? {fy_filter}
               AND lt.is_opening_balance = 0
           WHERE lg.nature = 'ASSETS'
           GROUP BY lg.id, l.id
           HAVING balance != 0
           ORDER BY lg.name, l.name""",
        tuple(params)
    )

    # Liabilities
    liabilities = DatabaseHelper.execute_query(
        f"""SELECT lg.name as group_name, l.name as ledger_name,
            COALESCE(l.opening_balance, 0) + COALESCE(SUM(
                CASE WHEN l.balance_type = 'CR' THEN lt.credit_amount - lt.debit_amount
                     ELSE lt.debit_amount - lt.credit_amount END
            ), 0) as balance
           FROM ledger_groups lg
           JOIN ledgers l ON l.ledger_group_id = lg.id
           LEFT JOIN ledger_transactions lt ON lt.ledger_id = l.id
               AND lt.transaction_date <= ? {fy_filter}
               AND lt.is_opening_balance = 0
           WHERE lg.nature IN ('LIABILITIES', 'CAPITAL')
           GROUP BY lg.id, l.id
           HAVING balance != 0
           ORDER BY lg.name, l.name""",
        tuple(params)
    )

    total_assets = sum(float(r.get('balance', 0) or 0) for r in assets)
    total_liabilities = sum(float(r.get('balance', 0) or 0) for r in liabilities)

    return {
        "as_on_date": as_on_date.isoformat(),
        "assets": assets,
        "liabilities": liabilities,
        "total_assets": total_assets,
        "total_liabilities": total_liabilities,
    }


@app.get("/api/reports/itr/depreciation")
async def get_depreciation_report(
    from_date: date,
    to_date: date,
    financial_year_id: Optional[int] = None
):
    """Depreciation schedule - Fixed assets depreciation"""
    try:
        fy_filter = ""
        params: list = [from_date.isoformat(), to_date.isoformat()]
        if financial_year_id:
            fy_filter = " AND ds.financial_year_id = ?"
            params.append(financial_year_id)

        schedule = DatabaseHelper.execute_query(
            f"""SELECT fa.name as asset_name, fa.asset_category, fa.purchase_date,
                fa.purchase_value, fa.depreciation_method,
                ds.period_from, ds.period_to, ds.depreciation_amount,
                ds.opening_wdv, ds.closing_wdv
               FROM fixed_assets fa
               JOIN depreciation_schedule ds ON ds.asset_id = fa.id
               WHERE ds.period_from >= ? AND ds.period_to <= ? {fy_filter}
               ORDER BY fa.name, ds.period_from""",
            tuple(params)
        )
    except Exception:
        schedule = []

    # Also return asset list for reference
    assets = DatabaseHelper.execute_query(
        "SELECT * FROM fixed_assets WHERE is_active = 1 ORDER BY name"
    ) if _table_exists("fixed_assets") else []

    return {
        "from_date": from_date.isoformat(),
        "to_date": to_date.isoformat(),
        "depreciation_schedule": schedule,
        "assets": assets,
    }


@app.get("/api/reports/itr/capital-account")
async def get_capital_account_report(
    from_date: date,
    to_date: date,
    financial_year_id: Optional[int] = None
):
    """Capital account - Ledgers in Capital Account group"""
    capital_group = DatabaseHelper.execute_one(
        "SELECT id FROM ledger_groups WHERE name = 'Capital Account'"
    )
    if not capital_group:
        return {"ledgers": [], "total": 0}

    fy_filter = ""
    params: list = [from_date.isoformat(), to_date.isoformat()]
    if financial_year_id:
        fy_filter = " AND lt.financial_year_id = ?"
        params.append(financial_year_id)
    params.append(capital_group['id'])

    ledgers = DatabaseHelper.execute_query(
        f"""SELECT l.id, l.name, l.opening_balance, l.balance_type,
            COALESCE(SUM(lt.debit_amount), 0) as total_debit,
            COALESCE(SUM(lt.credit_amount), 0) as total_credit,
            l.current_balance
           FROM ledgers l
           LEFT JOIN ledger_transactions lt ON lt.ledger_id = l.id
               AND lt.transaction_date BETWEEN ? AND ? {fy_filter}
               AND lt.is_opening_balance = 0
           WHERE l.ledger_group_id = ?
           GROUP BY l.id
           ORDER BY l.name""",
        tuple(params)
    )

    total = sum(
        float(r.get('current_balance', 0) or 0) * (1 if r.get('balance_type') == 'CR' else -1)
        for r in ledgers
    )

    return {
        "from_date": from_date.isoformat(),
        "to_date": to_date.isoformat(),
        "ledgers": ledgers,
        "total": total,
    }


@app.get("/api/reports/itr/loan-schedules")
async def get_loan_schedules(loan_id: Optional[int] = None):
    """Loan schedules - EMI breakdown, principal, interest"""
    if not _table_exists("loan_schedules"):
        return {"loans": [], "schedules": []}

    if loan_id:
        schedules = DatabaseHelper.execute_query(
            """SELECT ls.*, l.name as loan_name, l.principal_amount
               FROM loan_schedules ls
               JOIN loans l ON l.id = ls.loan_id
               WHERE ls.loan_id = ?
               ORDER BY ls.installment_number""",
            (loan_id,)
        )
        return {"schedules": schedules}
    else:
        loans = DatabaseHelper.execute_query(
            "SELECT * FROM loans WHERE status = 'ACTIVE' ORDER BY name"
        )
        all_schedules = []
        for loan in loans:
            sched = DatabaseHelper.execute_query(
                "SELECT * FROM loan_schedules WHERE loan_id = ? ORDER BY installment_number",
                (loan['id'],)
            )
            all_schedules.append({"loan": loan, "schedules": sched})
        return {"loans": loans, "schedules_by_loan": all_schedules}


def _table_exists(table_name: str) -> bool:
    """Check if table exists in database"""
    r = DatabaseHelper.execute_one(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        (table_name,)
    )
    return r is not None


# ============================================================================
# GST REPORTS
# ============================================================================

@app.get("/api/reports/gst/invoice-classification")
async def get_invoice_classification(
    from_date: date,
    to_date: date
):
    """Invoice classification - B2B, B2C Small, B2C Large, Export"""
    company = DatabaseHelper.execute_one("SELECT state_code FROM company_profile LIMIT 1")
    company_state = (company or {}).get('state_code', '27')

    rows = DatabaseHelper.execute_query(
        """SELECT 
            CASE 
                WHEN i.is_export = 1 THEN 'EXPORT'
                WHEN i.party_gstin IS NOT NULL AND TRIM(i.party_gstin) != '' THEN 'B2B'
                WHEN (i.place_of_supply IS NULL OR i.place_of_supply != ?) AND i.grand_total > 250000 THEN 'B2CL'
                ELSE 'B2CS'
            END as classification,
            COUNT(*) as invoice_count,
            COALESCE(SUM(i.taxable_amount), 0) as taxable_amount,
            COALESCE(SUM(i.cgst_amount), 0) as cgst,
            COALESCE(SUM(i.sgst_amount), 0) as sgst,
            COALESCE(SUM(i.igst_amount), 0) as igst,
            COALESCE(SUM(i.total_tax_amount), 0) as total_tax
           FROM invoices i
           WHERE i.status = 'CONFIRMED' AND i.is_deleted = 0
           AND i.invoice_date BETWEEN ? AND ?
           GROUP BY classification
           ORDER BY classification""",
        (company_state, from_date.isoformat(), to_date.isoformat())
    )
    return {"classifications": rows, "from_date": from_date.isoformat(), "to_date": to_date.isoformat()}


@app.get("/api/reports/gst/hsn-summary")
async def get_gst_hsn_summary(
    from_date: date,
    to_date: date
):
    """HSN-wise summary for GSTR-1"""
    return DatabaseHelper.execute_query(
        """SELECT 
            COALESCE(its.hsn_code, '0000') as hsn_code,
            SUM(its.total_quantity) as quantity,
            SUM(its.taxable_amount) as taxable_amount,
            its.gst_rate,
            SUM(its.cgst_amount) as cgst_amount,
            SUM(its.sgst_amount) as sgst_amount,
            SUM(its.igst_amount) as igst_amount,
            SUM(its.cess_amount) as cess_amount,
            SUM(its.total_tax_amount) as total_tax
           FROM invoice_tax_summary its
           JOIN invoices i ON its.invoice_id = i.id
           WHERE i.status = 'CONFIRMED' AND i.is_deleted = 0
           AND i.invoice_date BETWEEN ? AND ?
           GROUP BY its.hsn_code, its.gst_rate
           ORDER BY its.hsn_code""",
        (from_date.isoformat(), to_date.isoformat())
    )


@app.get("/api/reports/gst/itc")
async def get_itc_report(
    from_date: date,
    to_date: date
):
    """Input Tax Credit (ITC) - From purchase invoices and expenses"""
    # ITC from expenses
    expense_itc = DatabaseHelper.execute_query(
        """SELECT category_id, SUM(total_gst_amount) as itc_amount
           FROM expenses
           WHERE expense_date BETWEEN ? AND ? AND itc_eligible = 1
           GROUP BY category_id""",
        (from_date.isoformat(), to_date.isoformat())
    ) if _table_exists("expenses") else []

    # Placeholder for purchase ITC (when purchase module posts to ledger)
    purchase_itc = []

    total_itc = sum(float(r.get('itc_amount', 0) or 0) for r in expense_itc)

    return {
        "from_date": from_date.isoformat(),
        "to_date": to_date.isoformat(),
        "expense_itc": expense_itc,
        "purchase_itc": purchase_itc,
        "total_itc": total_itc,
    }


@app.get("/api/reports/gst/tax-payable")
async def get_tax_payable_report(
    from_date: date,
    to_date: date
):
    """GST Tax Payable - Output tax minus ITC"""
    # Output tax (from sales)
    output = DatabaseHelper.execute_one(
        """SELECT 
            COALESCE(SUM(cgst_amount), 0) as cgst,
            COALESCE(SUM(sgst_amount), 0) as sgst,
            COALESCE(SUM(igst_amount), 0) as igst,
            COALESCE(SUM(cess_amount), 0) as cess,
            COALESCE(SUM(total_tax_amount), 0) as total
           FROM invoices
           WHERE status = 'CONFIRMED' AND is_deleted = 0
           AND invoice_date BETWEEN ? AND ?""",
        (from_date.isoformat(), to_date.isoformat())
    )

    # ITC (simplified - from expenses)
    itc_result = DatabaseHelper.execute_one(
        """SELECT COALESCE(SUM(total_gst_amount), 0) as total_itc
           FROM expenses
           WHERE expense_date BETWEEN ? AND ? AND itc_eligible = 1""",
        (from_date.isoformat(), to_date.isoformat())
    ) if _table_exists("expenses") else {"total_itc": 0}

    output_tax = output or {"cgst": 0, "sgst": 0, "igst": 0, "cess": 0, "total": 0}
    itc = float((itc_result or {}).get("total_itc", 0))

    return {
        "from_date": from_date.isoformat(),
        "to_date": to_date.isoformat(),
        "output_tax": output_tax,
        "itc_available": itc,
        "tax_payable": float(output_tax.get("total", 0)) - itc,
    }


@app.get("/api/reports/gst/amendments")
async def get_gst_amendments(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    invoice_id: Optional[int] = None
):
    """GST Amendments - Revised return entries"""
    if not _table_exists("gst_amendments"):
        return {"amendments": []}

    query = "SELECT ga.*, i.invoice_number FROM gst_amendments ga JOIN invoices i ON i.id = ga.invoice_id WHERE 1=1"
    params: list = []
    if from_date:
        query += " AND ga.amendment_date >= ?"
        params.append(from_date.isoformat())
    if to_date:
        query += " AND ga.amendment_date <= ?"
        params.append(to_date.isoformat())
    if invoice_id:
        query += " AND ga.invoice_id = ?"
        params.append(invoice_id)
    query += " ORDER BY ga.amendment_date DESC"

    amendments = DatabaseHelper.execute_query(query, tuple(params))
    return {"amendments": amendments}


# ============================================================================
# STATUTORY COMPLIANCE ENDPOINTS
# ============================================================================

@app.get("/api/compliance/trial-balance")
async def api_trial_balance(from_date: date, to_date: date, financial_year_id: Optional[int] = None):
    """Trial Balance - All ledgers with Dr/Cr totals for CA verification"""
    from compliance_engine import get_trial_balance
    return get_trial_balance(from_date, to_date, financial_year_id)


@app.get("/api/compliance/books/day-book")
async def api_day_book(from_date: date, to_date: date):
    """Day book - All transactions by date"""
    from compliance_engine import get_day_book
    return get_day_book(from_date, to_date)


@app.get("/api/compliance/books/cash-book")
async def api_cash_book(from_date: date, to_date: date):
    """Cash book"""
    from compliance_engine import get_cash_book
    return get_cash_book(from_date, to_date)


@app.get("/api/compliance/books/bank-book")
async def api_bank_book(from_date: date, to_date: date):
    """Bank book"""
    from compliance_engine import get_bank_book
    return get_bank_book(from_date, to_date)


@app.get("/api/compliance/books/sales-register")
async def api_sales_register(from_date: date, to_date: date):
    """Sales register"""
    from compliance_engine import get_sales_register
    return get_sales_register(from_date, to_date)


@app.get("/api/compliance/books/purchase-register")
async def api_purchase_register(from_date: date, to_date: date):
    """Purchase register"""
    from compliance_engine import get_purchase_register
    return get_purchase_register(from_date, to_date)


@app.get("/api/compliance/books/journal-register")
async def api_journal_register(from_date: date, to_date: date):
    """Journal register"""
    from compliance_engine import get_journal_register
    return get_journal_register(from_date, to_date)


@app.get("/api/compliance/gstr1")
async def api_gstr1_data(from_date: date, to_date: date):
    """GSTR-1 data: B2B, B2C large/small, Export, HSN summary"""
    from compliance_engine import get_gstr1_data
    return get_gstr1_data(from_date, to_date)


@app.get("/api/compliance/gstr3b")
async def api_gstr3b_summary(from_date: date, to_date: date):
    """GSTR-3B summary: Outward tax, RCM, ITC, Net payable"""
    from compliance_engine import get_gstr3b_summary
    return get_gstr3b_summary(from_date, to_date)


@app.get("/api/compliance/itc-tracking")
async def api_itc_tracking(from_date: date, to_date: date):
    """ITC tracking with eligible/ineligible, supplier match"""
    from compliance_engine import get_itc_tracking
    return get_itc_tracking(from_date, to_date)


@app.get("/api/compliance/mismatch-alerts")
async def api_mismatch_alerts(status: str = "OPEN"):
    """Compliance mismatch alerts (ITC 2B, outward, tax, bank recon)"""
    from compliance_engine import get_mismatch_alerts
    return get_mismatch_alerts(status)


@app.get("/api/compliance/tax-payment-tracking")
async def api_tax_payment_tracking(period_year: int, period_month: int):
    """Tax payment: Liability, Paid, Remaining"""
    from compliance_engine import get_tax_payment_tracking
    return get_tax_payment_tracking(period_year, period_month)


@app.get("/api/compliance/capital-movement")
async def api_capital_movement(from_date: date, to_date: date, financial_year_id: Optional[int] = None):
    """Capital movement: Opening, Add profit, Less drawings, Closing"""
    from compliance_engine import get_capital_movement
    return get_capital_movement(from_date, to_date, financial_year_id)


@app.get("/api/compliance/turnover-summary")
async def api_turnover_summary(from_date: date, to_date: date):
    """Turnover summary for ITR"""
    from compliance_engine import get_turnover_summary
    return get_turnover_summary(from_date, to_date)


@app.get("/api/compliance/related-party-transactions")
async def api_related_party_transactions(from_date: date, to_date: date):
    """Related party transactions for ITR"""
    from compliance_engine import get_related_party_transactions
    return get_related_party_transactions(from_date, to_date)


@app.post("/api/compliance/lock-year")
async def api_lock_financial_year(fy_id: int = Query(...), locked_by: str = Query("system")):
    """Lock financial year - no edits allowed after audit"""
    from compliance_engine import lock_financial_year
    lock_financial_year(fy_id, locked_by)
    return {"success": True, "message": "Financial year locked"}


@app.post("/api/compliance/mark-invoice-filed")
async def api_mark_invoice_filed(invoice_id: int = Query(...), arn: Optional[str] = Query(None)):
    """Mark invoice as filed in GSTR-1 - immutable"""
    from compliance_engine import mark_invoice_filed
    mark_invoice_filed(invoice_id, arn)
    return {"success": True, "message": "Invoice marked as filed"}


@app.post("/api/compliance/amendment-entry")
async def api_create_amendment_entry(
    original_entity_type: str,
    original_entity_id: int,
    amendment_type: str,
    reason: str,
    amendment_date: date
):
    """Create amendment entry - do NOT edit original"""
    from compliance_engine import create_amendment_entry
    aid = create_amendment_entry(original_entity_type, original_entity_id, amendment_type, reason, amendment_date)
    return {"success": True, "amendment_id": aid}


@app.get("/api/compliance/export-ca")
async def api_export_for_ca(
    from_date: date,
    to_date: date,
    reports: str = "trial_balance,pl,balance_sheet,day_book,cash_book,bank_book,sales_register,purchase_register,journal_register"
):
    """Export for Chartered Accountant - all books and statements"""
    from compliance_engine import export_for_ca
    report_types = [r.strip() for r in reports.split(",")]
    return export_for_ca(from_date, to_date, report_types)


# ============================================================================
# UNITS ENDPOINTS
# ============================================================================

@app.get("/api/units")
async def get_units():
    """Get all units of measurement"""
    return DatabaseHelper.execute_query(
        "SELECT * FROM units WHERE is_active = 1 ORDER BY name"
    )


# ============================================================================
# PARTIES / FIRMS ENDPOINTS
# ============================================================================

@app.get("/api/parties", response_model=List[Party])
async def get_parties(
    party_type: Optional[str] = None,
    is_active: bool = True,
    search: Optional[str] = None,
):
    """Get all parties with optional filters"""
    query = """SELECT p.*, l.ledger_group_id
               FROM parties p
               LEFT JOIN ledgers l ON p.ledger_id = l.id
               WHERE p.is_active = ?"""
    params: List = [1 if is_active else 0]

    if party_type:
        query += " AND p.party_type = ?"
        params.append(party_type)

    if search:
        query += " AND (p.name LIKE ? OR p.gstin LIKE ? OR p.phone LIKE ? OR p.email LIKE ?)"
        like = f"%{search}%"
        params.extend([like, like, like, like])

    query += " ORDER BY p.name"
    return DatabaseHelper.execute_query(query, tuple(params))


@app.get("/api/parties/{party_id}", response_model=Party)
async def get_party(party_id: int):
    """Get single party details"""
    party = DatabaseHelper.execute_one(
        """SELECT p.*, l.ledger_group_id
           FROM parties p
           LEFT JOIN ledgers l ON p.ledger_id = l.id
           WHERE p.id = ?""",
        (party_id,)
    )
    if not party:
        raise HTTPException(status_code=404, detail="Party not found")
    return party


@app.get("/api/parties/{party_id}/history", response_model=List[PartyChangeLog])
async def get_party_history(party_id: int):
    """Get change log history for a party"""
    return DatabaseHelper.execute_query(
        "SELECT * FROM party_change_log WHERE party_id = ? ORDER BY change_date DESC",
        (party_id,)
    )


@app.post("/api/parties", response_model=APIResponse)
async def create_party(party: PartyCreate):
    """
    Create new party with automatic ledger creation and validation
    """
    if party.opening_balance is not None and party.opening_balance < 0:
        raise HTTPException(status_code=400, detail="Opening balance must be 0 or more (use DR/CR by party type).")

    # Check duplicate GSTIN
    if party.gstin:
        existing_gstin = DatabaseHelper.execute_one(
            "SELECT id FROM parties WHERE gstin = ?",
            (party.gstin,)
        )
        if existing_gstin:
            raise HTTPException(status_code=400, detail="GSTIN already registered")

    # Check duplicate PAN
    if party.pan:
        existing_pan = DatabaseHelper.execute_one(
            "SELECT id FROM parties WHERE pan = ? AND id != ?",
            (party.pan, -1)
        )
        if existing_pan:
            raise HTTPException(status_code=400, detail="PAN already registered")

    # Determine ledger group: use ledger_group_id if provided, else group_map by party type
    group_map = {
        "SUPPLIER": "Sundry Creditors",
        "CUSTOMER": "Sundry Debtors",
        "EMPLOYEE": "Loans & Advances (Asset)",
        "BANK": "Bank Accounts",
        "OTHER": "Current Assets",
    }
    if party.ledger_group_id:
        group = DatabaseHelper.execute_one(
            "SELECT id, nature FROM ledger_groups WHERE id = ?",
            (party.ledger_group_id,),
        )
        if not group:
            raise HTTPException(status_code=400, detail="Invalid ledger group.")
        group_id = group["id"]
        # Balance type from group nature: ASSETS/EXPENSES -> DR, LIABILITIES/INCOME -> CR
        balance_type = "DR" if group["nature"] in ("ASSETS", "EXPENSES") else "CR"
    else:
        group_name = group_map.get(party.party_type.value, "Current Assets")
        group = DatabaseHelper.execute_one(
            "SELECT id FROM ledger_groups WHERE name = ?",
            (group_name,)
        )
        if not group:
            raise HTTPException(status_code=500, detail=f"Ledger group not found: {group_name}")
        group_id = group["id"]
        balance_type = "CR" if party.party_type.value == "SUPPLIER" else "DR"

    with get_db_connection() as conn:
        try:
            # Create ledger first
            cursor = conn.execute(
                """INSERT INTO ledgers
                   (name, ledger_group_id, opening_balance, balance_type, current_balance,
                    is_party, gstin, pan, contact_person, phone, email,
                    billing_address, billing_city, billing_state_code, billing_pincode,
                    shipping_address, shipping_city, shipping_state_code, shipping_pincode,
                    credit_limit, credit_days, gst_registration_type)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    party.name,
                    group_id,
                    party.opening_balance,
                    balance_type,
                    party.opening_balance,
                    1,
                    party.gstin,
                    party.pan,
                    party.contact_person,
                    party.phone,
                    party.email,
                    party.billing_address,
                    party.billing_city,
                    party.billing_state_code,
                    party.billing_pincode,
                    party.shipping_address,
                    party.shipping_city,
                    party.shipping_state_code,
                    party.shipping_pincode,
                    party.credit_limit,
                    party.credit_days,
                    party.gst_registration_type.value,
                )
            )
            ledger_id = cursor.lastrowid

            # Create party record
            cursor = conn.execute(
                """INSERT INTO parties
                   (party_type, name, contact_person, contact_person_title, phone, email, website,
                    gstin, pan, tan, aadhaar_no,
                    billing_address, billing_city, billing_state_code, billing_pincode,
                    shipping_address, shipping_city, shipping_state_code, shipping_pincode,
                    gst_registration_type, credit_limit, credit_days,
                    ledger_id, opening_balance, balance_type)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    party.party_type.value,
                    party.name,
                    party.contact_person,
                    party.contact_person_title,
                    party.phone,
                    party.email,
                    party.website,
                    party.gstin,
                    party.pan,
                    party.tan,
                    party.aadhaar_no,
                    party.billing_address,
                    party.billing_city,
                    party.billing_state_code,
                    party.billing_pincode,
                    party.shipping_address,
                    party.shipping_city,
                    party.shipping_state_code,
                    party.shipping_pincode,
                    party.gst_registration_type.value,
                    party.credit_limit,
                    party.credit_days,
                    ledger_id,
                    party.opening_balance,
                    balance_type,
                )
            )
            party_id = cursor.lastrowid

            # Log change
            conn.execute(
                """INSERT INTO party_change_log
                   (party_id, change_type, new_values, reason)
                   VALUES (?, 'CREATE', ?, 'Party creation')""",
                (party_id, party.model_dump_json())
            )

            # Post opening balance to ledger if non-zero
            if party.opening_balance > 0:
                fy_id = FinancialYearHelper.ensure_current_fy()
                conn.execute(
                    """INSERT INTO ledger_transactions
                       (transaction_date, reference_id, reference_type, ledger_id,
                        debit_amount, credit_amount, narration, financial_year_id, is_opening_balance)
                       VALUES (?, ?, 'PARTY', ?, ?, ?, ?, ?, 1)""",
                    (
                        date.today().isoformat(),
                        party_id,
                        ledger_id,
                        party.opening_balance if balance_type == "DR" else 0,
                        party.opening_balance if balance_type == "CR" else 0,
                        f"Opening balance for {party.name}",
                        fy_id,
                    )
                )

            conn.commit()
            return APIResponse(
                success=True,
                message="Party created successfully with ledger",
                data={"id": party_id, "ledger_id": ledger_id}
            )
        except Exception as exc:
            conn.rollback()
            raise HTTPException(status_code=500, detail=f"Failed to create party: {str(exc)}")


@app.put("/api/parties/{party_id}", response_model=APIResponse)
async def update_party(party_id: int, party: PartyUpdate):
    """Update party details"""
    existing = DatabaseHelper.execute_one(
        "SELECT * FROM parties WHERE id = ?",
        (party_id,)
    )
    if not existing:
        raise HTTPException(status_code=404, detail="Party not found")

    update_fields = []
    update_values = []

    for field, value in party.model_dump(exclude_unset=True).items():
        # Normalize empty state codes to None
        if field in ('billing_state_code', 'shipping_state_code') and value == '':
            value = None
        
        if value is not None:
            update_fields.append(f"{field} = ?")
            update_values.append(value)

    if update_fields:
        update_values.append(party_id)
        DatabaseHelper.execute_update(
            f"UPDATE parties SET {', '.join(update_fields)}, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            tuple(update_values)
        )

        # Log change
        DatabaseHelper.execute_insert(
            """INSERT INTO party_change_log
               (party_id, change_type, old_values, new_values)
               VALUES (?, 'UPDATE', ?, ?)""",
            (party_id, existing.__str__(), party.model_dump_json())
        )

        # Update linked ledger
        if existing['ledger_id']:
            ledger_updates = {}
            if 'name' in party.model_dump(exclude_unset=True):
                ledger_updates['name'] = party.name
            if 'phone' in party.model_dump(exclude_unset=True):
                ledger_updates['phone'] = party.phone
            if 'email' in party.model_dump(exclude_unset=True):
                ledger_updates['email'] = party.email
            if 'credit_limit' in party.model_dump(exclude_unset=True):
                ledger_updates['credit_limit'] = party.credit_limit
            if 'credit_days' in party.model_dump(exclude_unset=True):
                ledger_updates['credit_days'] = party.credit_days

            if ledger_updates:
                ledger_fields = ", ".join([f"{k} = ?" for k in ledger_updates.keys()])
                ledger_values = list(ledger_updates.values())
                ledger_values.append(existing['ledger_id'])
                DatabaseHelper.execute_update(
                    f"UPDATE ledgers SET {ledger_fields}, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                    tuple(ledger_values)
                )

    return APIResponse(success=True, message="Party updated")


@app.post("/api/parties/{party_id}/deactivate", response_model=APIResponse)
async def deactivate_party(party_id: int, reason: str = ""):
    """
    Deactivate party (cannot delete if transactions exist)
    """
    party = DatabaseHelper.execute_one(
        "SELECT * FROM parties WHERE id = ?",
        (party_id,)
    )
    if not party:
        raise HTTPException(status_code=404, detail="Party not found")

    if not party['is_active']:
        raise HTTPException(status_code=400, detail="Party already deactivated")

    # Check if party has transactions
    if party['ledger_id']:
        transactions = DatabaseHelper.execute_one(
            "SELECT COUNT(*) as count FROM ledger_transactions WHERE ledger_id = ?",
            (party['ledger_id'],)
        )
        if transactions and transactions['count'] > 0:
            raise HTTPException(
                status_code=400,
                detail="Cannot delete party with existing transactions. Can only deactivate."
            )

    DatabaseHelper.execute_update(
        """UPDATE parties SET is_active = 0, deactivation_reason = ?, deactivation_date = ?, updated_at = CURRENT_TIMESTAMP
           WHERE id = ?""",
        (reason, date.today().isoformat(), party_id)
    )

    DatabaseHelper.execute_insert(
        """INSERT INTO party_change_log
           (party_id, change_type, reason)
           VALUES (?, 'DEACTIVATE', ?)""",
        (party_id, reason)
    )

    return APIResponse(success=True, message="Party deactivated")


@app.post("/api/parties/{party_id}/reactivate", response_model=APIResponse)
async def reactivate_party(party_id: int):
    """Reactivate a deactivated party"""
    party = DatabaseHelper.execute_one(
        "SELECT * FROM parties WHERE id = ?",
        (party_id,)
    )
    if not party:
        raise HTTPException(status_code=404, detail="Party not found")

    if party['is_active']:
        raise HTTPException(status_code=400, detail="Party is already active")

    DatabaseHelper.execute_update(
        """UPDATE parties SET is_active = 1, deactivation_reason = NULL, deactivation_date = NULL, updated_at = CURRENT_TIMESTAMP
           WHERE id = ?""",
        (party_id,)
    )

    DatabaseHelper.execute_insert(
        """INSERT INTO party_change_log
           (party_id, change_type, reason)
           VALUES (?, 'REACTIVATE', 'Party reactivated')""",
        (party_id,)
    )

    return APIResponse(success=True, message="Party reactivated")


# ============================================================================
# VOUCHER TYPES ENDPOINTS
# ============================================================================

@app.get("/api/voucher-types")
async def get_voucher_types():
    """Get all voucher types"""
    return DatabaseHelper.execute_query(
        "SELECT * FROM voucher_types WHERE is_active = 1 ORDER BY name"
    )


# ============================================================================
# STATEMENTS ENDPOINTS (Party Ledger Statements)
# ============================================================================

@app.get("/api/statements/{party_id}")
async def get_party_statement(
    party_id: int,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None
):
    """Get detailed party statement with all transactions"""
    from datetime import datetime as dt
    
    # Get party details
    party = DatabaseHelper.execute_one(
        """SELECT p.id, p.name, p.gstin, p.phone, p.email, p.billing_address,
                  l.opening_balance, l.balance_type, l.current_balance, 
                  l.credit_limit, l.credit_days
           FROM parties p
           LEFT JOIN ledgers l ON l.id = p.ledger_id
           WHERE p.id = ?""",
        (party_id,)
    )
    
    if not party:
        raise HTTPException(status_code=404, detail="Party not found")
    
    # Get ledger ID from party
    ledger = DatabaseHelper.execute_one(
        "SELECT id FROM ledgers WHERE is_party = 1 AND (SELECT ledger_id FROM parties WHERE id = ?) = id",
        (party_id,)
    )
    
    party_ledger_id = party.get('id')  # From parties table
    # Get ledger ID from parties table via manual lookup
    party_with_ledger = DatabaseHelper.execute_one(
        "SELECT ledger_id FROM parties WHERE id = ?",
        (party_id,)
    )
    ledger_id = party_with_ledger.get('ledger_id') if party_with_ledger else None
    
    if not ledger_id:
        # Create or get party ledger if not exists
        ledger_id = _get_or_create_ledger(party['name'], 'Sundry Debtors', is_party=True)
    
    # Parse dates
    start_date = datetime.strptime(from_date, "%Y-%m-%d").date() if from_date else date.today() - timedelta(days=365)
    end_date = datetime.strptime(to_date, "%Y-%m-%d").date() if to_date else date.today()
    
    # Get all transactions for this party
    transactions_data = []
    
    # 1. Get invoices (Sales/Purchase)
    invoices = DatabaseHelper.execute_query(
        """SELECT 
            lt.id,
            lt.transaction_date as date,
            i.invoice_number as reference_number,
            'Invoice' as type,
            lt.debit_amount,
            lt.credit_amount,
            lt.balance,
            lt.narration
        FROM ledger_transactions lt
        LEFT JOIN invoices i ON i.id = lt.reference_id AND lt.reference_type = 'INVOICE'
        WHERE lt.ledger_id = ? AND lt.transaction_date BETWEEN ? AND ?
        ORDER BY lt.transaction_date ASC""",
        (ledger_id, start_date, end_date)
    )
    transactions_data.extend(invoices or [])
    
    # 2. Get credit notes
    credit_notes = DatabaseHelper.execute_query(
        """SELECT 
            lt.id,
            lt.transaction_date as date,
            i.invoice_number as reference_number,
            'CreditNote' as type,
            lt.debit_amount,
            lt.credit_amount,
            lt.balance,
            lt.narration
        FROM ledger_transactions lt
        LEFT JOIN invoices i ON i.id = lt.reference_id AND lt.reference_type = 'CREDIT_NOTE'
        WHERE lt.ledger_id = ? AND lt.transaction_date BETWEEN ? AND ?
        ORDER BY lt.transaction_date ASC""",
        (ledger_id, start_date, end_date)
    )
    transactions_data.extend(credit_notes or [])
    
    # 3. Get debit notes
    debit_notes = DatabaseHelper.execute_query(
        """SELECT 
            lt.id,
            lt.transaction_date as date,
            i.invoice_number as reference_number,
            'DebitNote' as type,
            lt.debit_amount,
            lt.credit_amount,
            lt.balance,
            lt.narration
        FROM ledger_transactions lt
        LEFT JOIN invoices i ON i.id = lt.reference_id AND lt.reference_type = 'DEBIT_NOTE'
        WHERE lt.ledger_id = ? AND lt.transaction_date BETWEEN ? AND ?
        ORDER BY lt.transaction_date ASC""",
        (ledger_id, start_date, end_date)
    )
    transactions_data.extend(debit_notes or [])
    
    # 4. Get payment entries
    payments = DatabaseHelper.execute_query(
        """SELECT 
            lt.id,
            lt.transaction_date as date,
            pr.voucher_number as reference_number,
            'Payment' as type,
            lt.debit_amount,
            lt.credit_amount,
            lt.balance,
            lt.narration
        FROM ledger_transactions lt
        LEFT JOIN payment_receipts pr ON pr.id = lt.reference_id AND lt.reference_type = 'PAYMENT'
        WHERE lt.ledger_id = ? AND lt.transaction_date BETWEEN ? AND ?
        ORDER BY lt.transaction_date ASC""",
        (ledger_id, start_date, end_date)
    )
    transactions_data.extend(payments or [])
    
    # Sort all transactions by date
    transactions_data.sort(key=lambda x: x['date'] if x['date'] else date.today())
    
    # Calculate running balance
    running_balance = party.get('opening_balance', 0)
    opening_balance = running_balance
    opening_balance_type = party.get('balance_type', 'DR')
    
    transactions = []
    total_debit = 0
    total_credit = 0
    
    for txn in transactions_data:
        debit = txn.get('debit_amount', 0) or 0
        credit = txn.get('credit_amount', 0) or 0
        
        total_debit += debit
        total_credit += credit
        
        if debit > 0:
            running_balance += debit
        if credit > 0:
            running_balance -= credit
        
        txn_type_map = {
            'Invoice': 'invoice',
            'CreditNote': 'creditNote',
            'DebitNote': 'debitNote',
            'Payment': 'payment'
        }
        
        transactions.append({
            'id': txn.get('id', 0),
            'date': txn['date'].isoformat() if txn['date'] else date.today().isoformat(),
            'reference_number': txn.get('reference_number', ''),
            'description': party['name'],
            'type': txn_type_map.get(txn['type'], 'invoice'),
            'debit_amount': debit,
            'credit_amount': credit,
            'running_balance': running_balance,
            'narration': txn.get('narration')
        })
    
    # Calculate final balance
    closing_balance = running_balance
    closing_balance_type = 'DR' if closing_balance >= 0 else 'CR'
    
    return {
        'party_id': party_id,
        'party_name': party['name'],
        'gstin': party.get('gstin'),
        'phone': party.get('phone'),
        'email': party.get('email'),
        'address': party.get('billing_address'),
        'from_date': start_date.isoformat(),
        'to_date': end_date.isoformat(),
        'transactions': transactions,
        'summary': {
            'opening_balance': opening_balance,
            'opening_balance_type': opening_balance_type,
            'total_debit': total_debit,
            'total_credit': total_credit,
            'closing_balance': abs(closing_balance),
            'closing_balance_type': closing_balance_type,
            'credit_limit': party.get('credit_limit', 0),
            'available_credit': max(0, (party.get('credit_limit', 0) - abs(closing_balance))),
            'credit_days': party.get('credit_days', 30),
            'last_transaction_date': transactions[-1]['date'] if transactions else None,
            'total_transactions': len(transactions)
        }
    }


@app.get("/api/statements/overview")
async def get_statements_overview():
    """Get overview of all party statements with balances"""
    statements = DatabaseHelper.execute_query(
        """SELECT 
            p.id,
            p.name,
            p.gstin,
            l.current_balance,
            l.balance_type,
            l.credit_limit,
            l.credit_days,
            (SELECT COUNT(*) FROM ledger_transactions WHERE ledger_id = l.id) as transaction_count,
            (SELECT MAX(transaction_date) FROM ledger_transactions WHERE ledger_id = l.id) as last_transaction_date
        FROM parties p
        LEFT JOIN ledgers l ON l.id = p.ledger_id
        WHERE p.is_active = 1
        ORDER BY p.name""",
    )
    
    result = []
    for stmt in statements:
        result.append({
            'party_id': stmt['id'],
            'party_name': stmt['name'],
            'gstin': stmt.get('gstin'),
            'balance': stmt.get('current_balance', 0),
            'balance_type': stmt.get('balance_type', 'DR'),
            'credit_limit': stmt.get('credit_limit', 0),
            'available_credit': max(0, stmt.get('credit_limit', 0) - abs(stmt.get('current_balance', 0))),
            'credit_days': stmt.get('credit_days', 30),
            'transaction_count': stmt.get('transaction_count', 0),
            'last_transaction_date': stmt.get('last_transaction_date')
        })
    
    return result


# ============================================================================
# DATA IMPORT ENGINE ENDPOINTS
# ============================================================================

from import_engine import ImportEngine, ImportType, ImportStatus, SourceFormat

try:
    # Use the same SQLite DB path as the rest of the backend
    from database.db_helper import DATABASE_PATH
    import_engine = ImportEngine(DATABASE_PATH)
except Exception:
    # Fallback: keep import endpoints disabled if init fails
    import_engine = None


@app.post("/api/import/batch")
async def create_import_batch(
    import_type: str,
    source_format: str,
    source_reference: Optional[str] = None
):
    """Create a new import batch"""
    if import_engine is None:
        raise HTTPException(status_code=503, detail="Import engine not initialized")
    try:
        batch_id = import_engine.create_batch(
            ImportType(import_type),
            SourceFormat(source_format),
            source_reference
        )
        return {"success": True, "batch_id": batch_id}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/api/import/batch/{batch_id}/parse")
async def parse_import_file(batch_id: str, file_content: str, file_name: str):
    """Parse uploaded file content"""
    if import_engine is None:
        raise HTTPException(status_code=503, detail="Import engine not initialized")
    try:
        result = import_engine.parse_file(batch_id, file_content, file_name)
        return {
            "success": True,
            "headers": result.headers,
            "sample_rows": result.sample_rows,
            "total_rows": result.total_rows,
            "errors": result.errors
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/api/import/batch/{batch_id}/field-suggestions")
async def get_field_suggestions(batch_id: str):
    """Get auto-detected field mapping suggestions"""
    if import_engine is None:
        raise HTTPException(status_code=503, detail="Import engine not initialized")
    try:
        suggestions = import_engine.get_field_suggestions(batch_id)
        return {"success": True, "suggestions": suggestions}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/api/import/batch/{batch_id}/mapping")
async def save_field_mapping(batch_id: str, mappings: dict):
    """Save field mappings for the batch"""
    try:
        import_engine.save_field_mapping(batch_id, mappings)
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/api/import/batch/{batch_id}/validate")
async def validate_import_batch(batch_id: str):
    """Validate the import batch data"""
    try:
        result = import_engine.validate_batch(batch_id)
        return {
            "success": True,
            "is_valid": result.is_valid,
            "errors": [{"row": e.row, "field": e.field, "message": e.message, "severity": e.severity.value} for e in result.errors],
            "warnings": [{"row": w.row, "field": w.field, "message": w.message, "severity": w.severity.value} for w in result.warnings],
            "valid_row_count": result.valid_row_count,
            "invalid_row_count": result.invalid_row_count
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/api/import/batch/{batch_id}/dry-run")
async def dry_run_import(batch_id: str):
    """Execute dry run to preview import results"""
    try:
        preview = import_engine.dry_run(batch_id)
        return {
            "success": True,
            "vouchers_to_create": [
                {
                    "type": v.type,
                    "party": v.party,
                    "amount": float(v.amount),
                    "date": v.date,
                    "items": v.items
                } for v in preview.vouchers_to_create
            ],
            "inventory_changes": preview.inventory_changes,
            "ledger_changes": preview.ledger_changes,
            "duplicate_warnings": preview.duplicate_warnings,
            "period_lock_warnings": preview.period_lock_warnings,
            "estimated_time_seconds": preview.estimated_time_seconds
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/api/import/batch/{batch_id}/execute")
async def execute_import(batch_id: str):
    """Execute the actual import"""
    try:
        result = import_engine.execute_import(batch_id)
        return {
            "success": result.success,
            "batch_id": result.batch_id,
            "records_processed": result.records_processed,
            "records_imported": result.records_imported,
            "records_skipped": result.records_skipped,
            "records_failed": result.records_failed,
            "vouchers_created": result.vouchers_created,
            "errors": result.errors,
            "execution_time_seconds": result.execution_time_seconds
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/api/import/batch/{batch_id}/audit-log")
async def get_import_audit_log(batch_id: str):
    """Get audit log for an import batch"""
    try:
        logs = import_engine.get_audit_log(batch_id)
        return {
            "success": True,
            "logs": [
                {
                    "timestamp": log.timestamp,
                    "action": log.action,
                    "details": log.details,
                    "user": log.user,
                    "affected_records": log.affected_records
                } for log in logs
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/api/import/batches")
async def list_import_batches(
    status: Optional[str] = None,
    import_type: Optional[str] = None,
    limit: int = 50
):
    """List all import batches"""
    try:
        query = """
            SELECT batch_id, import_type, source_format, source_reference,
                   status, created_at, completed_at, total_records,
                   imported_records, failed_records, error_message
            FROM import_batches
            WHERE 1=1
        """
        params = []
        
        if status:
            query += " AND status = ?"
            params.append(status)
        if import_type:
            query += " AND import_type = ?"
            params.append(import_type)
        
        query += " ORDER BY created_at DESC LIMIT ?"
        params.append(limit)
        
        batches = DatabaseHelper.execute_query(query, tuple(params))
        return {"success": True, "batches": batches}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/api/import/batch/{batch_id}")
async def delete_import_batch(batch_id: str):
    """Delete an import batch (only if not completed)"""
    try:
        batch = DatabaseHelper.execute_one(
            "SELECT status FROM import_batches WHERE batch_id = ?",
            (batch_id,)
        )
        if not batch:
            raise HTTPException(status_code=404, detail="Batch not found")
        
        if batch['status'] == 'completed':
            raise HTTPException(status_code=400, detail="Cannot delete completed batch")
        
        DatabaseHelper.execute_query(
            "DELETE FROM import_batches WHERE batch_id = ?",
            (batch_id,)
        )
        DatabaseHelper.execute_query(
            "DELETE FROM import_audit_log WHERE batch_id = ?",
            (batch_id,)
        )
        
        return {"success": True, "message": "Batch deleted"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
