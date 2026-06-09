"""
GST Billing Backend - Pydantic Models
Request/Response models for FastAPI
"""

from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal
from enum import Enum


# ============================================================================
# ENUMS
# ============================================================================

class PaymentMode(str, Enum):
    CASH = "CASH"
    CREDIT = "CREDIT"
    CARD = "CARD"
    UPI = "UPI"
    NEFT = "NEFT"
    CHEQUE = "CHEQUE"
    ONLINE = "ONLINE"


class PaymentStatus(str, Enum):
    UNPAID = "UNPAID"
    PARTIAL = "PARTIAL"
    PAID = "PAID"
    OVERDUE = "OVERDUE"


class InvoiceStatus(str, Enum):
    DRAFT = "DRAFT"
    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"
    VOID = "VOID"


class GSTRegistrationType(str, Enum):
    REGULAR = "REGULAR"
    COMPOSITION = "COMPOSITION"
    UNREGISTERED = "UNREGISTERED"
    CONSUMER = "CONSUMER"
    OVERSEAS = "OVERSEAS"
    SEZ = "SEZ"


class DiscountType(str, Enum):
    PERCENTAGE = "PERCENTAGE"
    AMOUNT = "AMOUNT"


class ExpenseClassification(str, Enum):
    DIRECT = "DIRECT"
    INDIRECT = "INDIRECT"
    CAPITAL = "CAPITAL"


class RecurrenceFrequency(str, Enum):
    WEEKLY = "WEEKLY"
    MONTHLY = "MONTHLY"
    QUARTERLY = "QUARTERLY"
    YEARLY = "YEARLY"


class PartyType(str, Enum):
    SUPPLIER = "SUPPLIER"
    CUSTOMER = "CUSTOMER"
    EMPLOYEE = "EMPLOYEE"
    BANK = "BANK"
    OTHER = "OTHER"


class PartyChangeType(str, Enum):
    CREATE = "CREATE"
    UPDATE = "UPDATE"
    DEACTIVATE = "DEACTIVATE"
    DELETE = "DELETE"
    REACTIVATE = "REACTIVATE"


# ============================================================================
# COMPANY PROFILE
# ============================================================================

class CompanyProfileBase(BaseModel):
    company_name: str
    legal_name: str
    gstin: Optional[str] = None
    pan: Optional[str] = None
    address_line1: str
    address_line2: Optional[str] = None
    city: str
    state_code: str
    state_name: str
    pincode: str
    phone: Optional[str] = None
    email: Optional[str] = None
    bank_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    bank_ifsc: Optional[str] = None


class CompanyProfileCreate(CompanyProfileBase):
    pass


class CompanyProfile(CompanyProfileBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# ============================================================================
# STATE
# ============================================================================

class State(BaseModel):
    code: str
    name: str
    type: str
    
    class Config:
        from_attributes = True


# ============================================================================
# LEDGER
# ============================================================================

class LedgerBase(BaseModel):
    name: str
    alias: Optional[str] = None
    ledger_group_id: int
    opening_balance: float = 0
    balance_type: str = "DR"
    
    # Party details
    is_party: bool = False
    gstin: Optional[str] = None
    pan: Optional[str] = None
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    billing_address: Optional[str] = None
    billing_city: Optional[str] = None
    billing_state_code: Optional[str] = None
    billing_pincode: Optional[str] = None
    gst_registration_type: GSTRegistrationType = GSTRegistrationType.UNREGISTERED
    credit_limit: float = 0
    credit_days: int = 0


class LedgerCreate(LedgerBase):
    pass


class LedgerUpdate(BaseModel):
    name: Optional[str] = None
    alias: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    billing_address: Optional[str] = None
    credit_limit: Optional[float] = None
    is_active: Optional[bool] = None


class Ledger(LedgerBase):
    id: int
    current_balance: float
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# ============================================================================
# HSN/SAC CODE
# ============================================================================

class HSNCodeBase(BaseModel):
    code: str
    description: str
    type: str = "HSN"  # HSN or SAC
    gst_rate: float = 0
    cgst_rate: float = 0
    sgst_rate: float = 0
    igst_rate: float = 0
    cess_rate: float = 0


class HSNCodeCreate(HSNCodeBase):
    pass


class HSNCode(HSNCodeBase):
    id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


# ============================================================================
# ITEM
# ============================================================================

class ItemBase(BaseModel):
    name: str
    alias: Optional[str] = None
    barcode: Optional[str] = None
    sku: Optional[str] = None
    category_id: Optional[int] = None
    hsn_code: Optional[str] = None
    unit_id: Optional[int] = None
    
    # Pricing
    cost_price: float = 0
    selling_price: float = 0
    mrp: float = 0
    wholesale_price: float = 0
    min_selling_price: float = 0
    price_inclusive_tax: bool = False
    
    # GST
    gst_rate: float = 0
    cess_rate: float = 0
    
    # Inventory
    opening_stock: float = 0
    min_stock_level: float = 0
    reorder_level: float = 0
    
    # Flags
    is_service: bool = False
    batch_tracking: bool = False
    serial_tracking: bool = False
    expiry_tracking: bool = False


class ItemCreate(ItemBase):
    pass


class ItemUpdate(BaseModel):
    name: Optional[str] = None
    selling_price: Optional[float] = None
    mrp: Optional[float] = None
    cost_price: Optional[float] = None
    current_stock: Optional[float] = None
    batch_tracking: Optional[bool] = None
    serial_tracking: Optional[bool] = None
    expiry_tracking: Optional[bool] = None
    is_active: Optional[bool] = None


class Item(ItemBase):
    id: int
    current_stock: float
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ItemSearch(BaseModel):
    """Model for item search results"""
    id: int
    name: str
    barcode: Optional[str]
    sku: Optional[str]
    hsn_code: Optional[str]
    selling_price: float
    mrp: float
    gst_rate: float
    current_stock: float
    unit_code: Optional[str] = "NOS"


# ============================================================================
# INVOICE ITEM (Line Item)
# ============================================================================

class InvoiceItemBase(BaseModel):
    item_id: Optional[int] = None
    item_name: str
    item_description: Optional[str] = None
    hsn_code: Optional[str] = None
    barcode: Optional[str] = None
    
    quantity: float
    unit_code: Optional[str] = "NOS"
    free_quantity: float = 0
    
    rate: float
    mrp: float = 0
    discount_type: DiscountType = DiscountType.AMOUNT
    discount_value: float = 0
    
    gst_rate: float = 0
    cess_rate: float = 0


class InvoiceItemCreate(InvoiceItemBase):
    pass


class InvoiceItem(InvoiceItemBase):
    id: int
    invoice_id: int
    
    # Calculated fields
    discount_amount: float
    taxable_amount: float
    cgst_rate: float
    cgst_amount: float
    sgst_rate: float
    sgst_amount: float
    igst_rate: float
    igst_amount: float
    cess_amount: float
    total_tax_amount: float
    total_amount: float
    
    class Config:
        from_attributes = True


# ============================================================================
# GST INVOICE
# ============================================================================

class GSTInvoiceBase(BaseModel):
    voucher_type_id: int = 1  # Default to Sales Invoice
    invoice_date: date
    due_date: Optional[date] = None
    
    # Party
    party_id: Optional[int] = None
    party_name: str
    party_gstin: Optional[str] = None
    party_state_code: Optional[str] = None
    party_address: Optional[str] = None
    
    # Addresses
    billing_name: Optional[str] = None
    billing_address: Optional[str] = None
    billing_city: Optional[str] = None
    billing_state_code: Optional[str] = None
    billing_pincode: Optional[str] = None
    
    shipping_name: Optional[str] = None
    shipping_address: Optional[str] = None
    shipping_city: Optional[str] = None
    shipping_state_code: Optional[str] = None
    shipping_pincode: Optional[str] = None
    
    # Place of supply
    place_of_supply: Optional[str] = None
    is_reverse_charge: bool = False
    is_export: bool = False
    
    # Discount
    discount_type: DiscountType = DiscountType.AMOUNT
    discount_value: float = 0
    
    # Other charges
    transport_charges: float = 0
    packing_charges: float = 0
    other_charges: float = 0
    
    # Payment
    payment_mode: Optional[PaymentMode] = PaymentMode.CASH
    payment_reference: Optional[str] = None
    paid_amount: float = 0
    
    # E-Way Bill
    eway_bill_number: Optional[str] = None
    vehicle_number: Optional[str] = None
    transporter_name: Optional[str] = None
    
    notes: Optional[str] = None
    terms_conditions: Optional[str] = None


class GSTInvoiceCreate(GSTInvoiceBase):
    items: List[InvoiceItemCreate]


class GSTInvoiceUpdate(BaseModel):
    party_name: Optional[str] = None
    party_address: Optional[str] = None
    notes: Optional[str] = None
    paid_amount: Optional[float] = None
    payment_status: Optional[PaymentStatus] = None
    status: Optional[InvoiceStatus] = None


class GSTInvoice(GSTInvoiceBase):
    id: int
    invoice_number: str
    financial_year_id: Optional[int]
    
    # Calculated amounts
    subtotal: float
    discount_amount: float
    taxable_amount: float
    cgst_amount: float
    sgst_amount: float
    igst_amount: float
    cess_amount: float
    total_tax_amount: float
    round_off_amount: float
    grand_total: float
    amount_in_words: Optional[str]
    
    balance_amount: float
    payment_status: PaymentStatus
    status: InvoiceStatus
    
    items: List[InvoiceItem] = []
    
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
    
    def to_json(self) -> dict:
        """Convert to JSON-serializable dictionary"""
        return {
            "id": self.id,
            "invoice_number": self.invoice_number,
            "invoice_date": self.invoice_date.isoformat(),
            "due_date": self.due_date.isoformat() if self.due_date else None,
            "party_id": self.party_id,
            "party_name": self.party_name,
            "party_gstin": self.party_gstin,
            "party_state_code": self.party_state_code,
            "place_of_supply": self.place_of_supply,
            "billing_address": self.billing_address,
            "shipping_address": self.shipping_address,
            "subtotal": self.subtotal,
            "discount_type": self.discount_type.value,
            "discount_value": self.discount_value,
            "discount_amount": self.discount_amount,
            "taxable_amount": self.taxable_amount,
            "cgst_amount": self.cgst_amount,
            "sgst_amount": self.sgst_amount,
            "igst_amount": self.igst_amount,
            "cess_amount": self.cess_amount,
            "total_tax_amount": self.total_tax_amount,
            "transport_charges": self.transport_charges,
            "packing_charges": self.packing_charges,
            "other_charges": self.other_charges,
            "round_off_amount": self.round_off_amount,
            "grand_total": self.grand_total,
            "amount_in_words": self.amount_in_words,
            "payment_mode": self.payment_mode.value if self.payment_mode else None,
            "paid_amount": self.paid_amount,
            "balance_amount": self.balance_amount,
            "payment_status": self.payment_status.value,
            "status": self.status.value,
            "items": [
                {
                    "id": item.id,
                    "item_id": item.item_id,
                    "item_name": item.item_name,
                    "hsn_code": item.hsn_code,
                    "quantity": item.quantity,
                    "unit_code": item.unit_code,
                    "rate": item.rate,
                    "discount_amount": item.discount_amount,
                    "taxable_amount": item.taxable_amount,
                    "gst_rate": item.gst_rate,
                    "cgst_amount": item.cgst_amount,
                    "sgst_amount": item.sgst_amount,
                    "igst_amount": item.igst_amount,
                    "total_amount": item.total_amount
                }
                for item in self.items
            ],
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat()
        }


# ============================================================================
# TAX SUMMARY
# ============================================================================

class TaxSummary(BaseModel):
    """HSN-wise tax summary"""
    hsn_code: str
    taxable_amount: float
    gst_rate: float
    cgst_amount: float
    sgst_amount: float
    igst_amount: float
    cess_amount: float
    total_tax: float
    quantity: float


# ============================================================================
# INVENTORY
# ============================================================================

class InventoryAdjustment(BaseModel):
    item_id: int
    quantity: float
    adjustment_type: str  # "ADD" or "SUBTRACT"
    reason: str
    reference: Optional[str] = None


class StockSummary(BaseModel):
    id: int
    name: str
    barcode: Optional[str]
    sku: Optional[str]
    hsn_code: Optional[str]
    unit: str
    current_stock: float
    min_stock_level: float
    cost_price: float
    selling_price: float
    mrp: float
    stock_value: float
    needs_reorder: bool


class ItemBatchBase(BaseModel):
    item_id: int
    batch_number: str
    manufacturing_date: Optional[date] = None
    expiry_date: Optional[date] = None
    cost_price: float = 0
    selling_price: float = 0
    mrp: float = 0
    quantity: float = 0


class ItemBatchCreate(ItemBatchBase):
    pass


class ItemBatch(ItemBatchBase):
    id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class ItemSerialBase(BaseModel):
    item_id: int
    serial_number: str
    batch_id: Optional[int] = None
    status: Optional[str] = None
    reference_type: Optional[str] = None
    reference_id: Optional[int] = None


class ItemSerial(ItemSerialBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class StockMovementCreate(BaseModel):
    item_id: int
    movement: str
    quantity: float
    rate: float = 0
    batch_number: Optional[str] = None
    manufacturing_date: Optional[date] = None
    expiry_date: Optional[date] = None
    serial_numbers: Optional[List[str]] = None
    narration: Optional[str] = None
    reference_type: Optional[str] = None
    reference_id: Optional[int] = None
    reference_number: Optional[str] = None


class StockMovementRecord(BaseModel):
    id: int
    transaction_date: date
    reference_type: Optional[str]
    reference_id: Optional[int]
    item_id: int
    item_name: str
    sku: Optional[str]
    unit: str
    batch_number: Optional[str]
    transaction_type: str
    quantity: float
    rate: float
    amount: float
    balance_before: float
    balance_after: float
    narration: Optional[str]
    voucher_number: Optional[str]


# ============================================================================
# REPORTS
# ============================================================================

class DateRange(BaseModel):
    start_date: date
    end_date: date


class SalesReport(BaseModel):
    total_sales: float
    total_tax: float
    total_discount: float
    invoice_count: int
    items_sold: float


class GSTReport(BaseModel):
    """For GSTR-1/GSTR-3B"""
    period: str
    total_taxable: float
    total_cgst: float
    total_sgst: float
    total_igst: float
    total_cess: float
    invoice_count: int
    b2b_invoices: List[dict]
    b2c_invoices: List[dict]


# ============================================================================
# CRM
# ============================================================================

class CRMStaff(BaseModel):
    id: int
    name: str
    email: Optional[str]
    phone: Optional[str]
    is_active: bool


class CRMStaffCreate(BaseModel):
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None


class CRMStaffUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    is_active: Optional[bool] = None


class CRMPipelineStage(BaseModel):
    id: int
    name: str
    sort_order: int
    is_won: bool
    is_lost: bool
    is_active: bool


class CRMLeadCreate(BaseModel):
    name: str
    company_name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    gstin: Optional[str] = None
    source: Optional[str] = None
    status: Optional[str] = None
    pipeline_stage_id: Optional[int] = None
    assigned_staff_id: Optional[int] = None
    credit_limit: float = 0
    expected_value: float = 0
    notes: Optional[str] = None
    next_followup_date: Optional[date] = None


class CRMLeadUpdate(BaseModel):
    name: Optional[str] = None
    company_name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    gstin: Optional[str] = None
    source: Optional[str] = None
    status: Optional[str] = None
    pipeline_stage_id: Optional[int] = None
    assigned_staff_id: Optional[int] = None
    credit_limit: Optional[float] = None
    expected_value: Optional[float] = None
    notes: Optional[str] = None
    next_followup_date: Optional[date] = None


class CRMLead(BaseModel):
    id: int
    name: str
    company_name: Optional[str]
    phone: Optional[str]
    email: Optional[str]
    gstin: Optional[str]
    source: Optional[str]
    status: str
    pipeline_stage_id: Optional[int]
    pipeline_stage: Optional[str] = None
    assigned_staff_id: Optional[int]
    assigned_staff: Optional[str] = None
    credit_limit: float
    expected_value: float
    notes: Optional[str]
    next_followup_date: Optional[date]
    created_at: datetime
    updated_at: datetime


class CRMNoteCreate(BaseModel):
    lead_id: int
    note: str
    created_by: Optional[str] = None


class CRMCallCreate(BaseModel):
    lead_id: int
    call_type: str = 'OUTBOUND'
    outcome: Optional[str] = None
    duration_seconds: int = 0
    notes: Optional[str] = None
    created_by: Optional[str] = None


class CRMFollowUpCreate(BaseModel):
    lead_id: int
    followup_date: date
    reminder_time: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None
    created_by: Optional[str] = None


class CRMFollowUp(BaseModel):
    id: int
    lead_id: int
    lead_name: str
    followup_date: date
    reminder_time: Optional[str]
    status: str
    notes: Optional[str]
    created_at: datetime


class CRMCustomerRisk(BaseModel):
    ledger_id: int
    name: str
    gstin: Optional[str]
    credit_limit: float
    outstanding: float
    total_sales: float
    overdue_days: int
    risk_level: str


# ============================================================================
# EXPENSES & OTHER INCOME
# ============================================================================

class ExpenseCategoryBase(BaseModel):
    name: str
    classification: ExpenseClassification
    ledger_id: Optional[int] = None
    gst_eligible: bool = True


class ExpenseCategoryCreate(ExpenseCategoryBase):
    pass


class ExpenseCategory(ExpenseCategoryBase):
    id: int
    is_active: bool
    created_at: datetime


class ExpenseAttachmentCreate(BaseModel):
    file_path: str
    file_name: Optional[str] = None


class ExpenseAttachment(BaseModel):
    id: int
    expense_id: int
    file_path: str
    file_name: Optional[str]
    created_at: datetime


class ExpenseEntryCreate(BaseModel):
    expense_date: date
    category_id: int
    vendor_ledger_id: Optional[int] = None
    reference_no: Optional[str] = None
    description: Optional[str] = None
    taxable_amount: float = 0
    gst_rate: float = 0
    itc_eligible: bool = True
    payment_mode: Optional[PaymentMode] = None
    paid_amount: float = 0
    due_date: Optional[date] = None
    is_credit: bool = False


class ExpenseEntry(BaseModel):
    id: int
    expense_date: date
    category_id: int
    category_name: Optional[str] = None
    vendor_ledger_id: Optional[int] = None
    vendor_name: Optional[str] = None
    reference_no: Optional[str]
    description: Optional[str]
    taxable_amount: float
    gst_rate: float
    cgst_amount: float
    sgst_amount: float
    igst_amount: float
    total_gst_amount: float
    total_amount: float
    itc_eligible: bool
    payment_mode: Optional[str]
    paid_amount: float
    balance_amount: float
    payment_status: PaymentStatus
    is_credit: bool
    due_date: Optional[date]
    created_at: datetime
    updated_at: datetime


class ExpenseRecurringCreate(BaseModel):
    template_name: str
    category_id: int
    vendor_ledger_id: Optional[int] = None
    description: Optional[str] = None
    taxable_amount: float = 0
    gst_rate: float = 0
    itc_eligible: bool = True
    payment_mode: Optional[PaymentMode] = None
    is_credit: bool = False
    frequency: RecurrenceFrequency
    next_run_date: date


class ExpenseRecurring(BaseModel):
    id: int
    template_name: str
    category_id: int
    category_name: Optional[str] = None
    vendor_ledger_id: Optional[int] = None
    vendor_name: Optional[str] = None
    description: Optional[str] = None
    taxable_amount: float
    gst_rate: float
    itc_eligible: bool
    payment_mode: Optional[str]
    is_credit: bool
    frequency: RecurrenceFrequency
    next_run_date: date
    last_run_date: Optional[date]
    is_active: bool
    created_at: datetime
    updated_at: datetime


class OtherIncomeCreate(BaseModel):
    income_date: date
    ledger_id: Optional[int] = None
    reference_no: Optional[str] = None
    description: Optional[str] = None
    amount: float
    payment_mode: Optional[PaymentMode] = None


class OtherIncome(BaseModel):
    id: int
    income_date: date
    ledger_id: Optional[int]
    ledger_name: Optional[str] = None
    reference_no: Optional[str]
    description: Optional[str]
    amount: float
    payment_mode: Optional[str]
    created_at: datetime


# ============================================================================
# PARTIES / FIRMS (Master Party)
# ============================================================================

class PartyBase(BaseModel):
    party_type: PartyType
    ledger_group_id: Optional[int] = None  # Optional override; when set, used instead of group_map
    name: str
    contact_person: Optional[str] = None
    contact_person_title: Optional[str] = None
    phone: str
    email: Optional[str] = None
    website: Optional[str] = None
    gstin: Optional[str] = None
    pan: Optional[str] = None
    tan: Optional[str] = None
    aadhaar_no: Optional[str] = None
    billing_address: Optional[str] = None
    billing_city: Optional[str] = None
    billing_state_code: Optional[str] = None
    billing_pincode: Optional[str] = None
    shipping_address: Optional[str] = None
    shipping_city: Optional[str] = None
    shipping_state_code: Optional[str] = None
    shipping_pincode: Optional[str] = None
    gst_registration_type: GSTRegistrationType = GSTRegistrationType.UNREGISTERED
    credit_limit: float = 0
    credit_days: int = 0
    opening_balance: float = 0
    balance_type: str = "DR"

    @validator('gstin')
    def validate_gstin(cls, v):
        if v and len(v) != 15:
            raise ValueError('GSTIN must be 15 characters')
        return v

    @validator('pan')
    def validate_pan(cls, v):
        if v and len(v) != 10:
            raise ValueError('PAN must be 10 characters')
        return v

    @validator('billing_state_code', 'shipping_state_code', pre=True)
    def normalize_state_codes(cls, v):
        # Convert empty strings to None to avoid foreign key constraint violations
        if v == '':
            return None
        return v


class PartyCreate(PartyBase):
    pass


class PartyUpdate(BaseModel):
    name: Optional[str] = None
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    billing_address: Optional[str] = None
    billing_city: Optional[str] = None
    billing_state_code: Optional[str] = None
    billing_pincode: Optional[str] = None
    shipping_address: Optional[str] = None
    shipping_city: Optional[str] = None
    shipping_state_code: Optional[str] = None
    shipping_pincode: Optional[str] = None
    credit_limit: Optional[float] = None
    credit_days: Optional[int] = None


class Party(PartyBase):
    id: int
    ledger_id: Optional[int]
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PartyChangeLog(BaseModel):
    id: int
    party_id: int
    change_type: PartyChangeType
    changed_by: Optional[str]
    old_values: Optional[str]
    new_values: Optional[str]
    reason: Optional[str]
    change_date: datetime

    class Config:
        from_attributes = True


# ============================================================================
# PRODUCT IMPORT/EXPORT
# ============================================================================

class ProductImportItem(BaseModel):
    """Single product for import from CSV"""
    name: str
    sku: Optional[str] = None
    barcode: Optional[str] = None
    hsn_code: Optional[str] = None
    unit: Optional[str] = None
    cost_price: Optional[float] = 0
    selling_price: Optional[float] = 0
    mrp: Optional[float] = 0
    gst_rate: Optional[float] = 0
    current_stock: Optional[float] = 0
    min_stock_level: Optional[float] = 0
    max_stock_level: Optional[float] = 0
    description: Optional[str] = None
    is_active: Optional[bool] = True


class ProductImportRequest(BaseModel):
    """Bulk product import request"""
    products: List[ProductImportItem]
    dry_run: bool = True
    financial_year: Optional[str] = None


class ProductImportError(BaseModel):
    """Error details for a specific row"""
    row_number: int
    error_message: str
    error_field: Optional[str] = None


class ProductImportResult(BaseModel):
    """Result of product import operation"""
    success: bool
    imported_count: int
    skipped_count: int
    failed_count: int
    errors: List[ProductImportError] = []
    message: str = ""
    dry_run: bool


# ============================================================================
# API RESPONSES
# ============================================================================

class APIResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None


class PaginatedResponse(BaseModel):
    items: List
    total: int
    page: int
    page_size: int
    total_pages: int
