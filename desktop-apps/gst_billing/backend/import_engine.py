"""
External POS Data Import Engine
================================
Supports: Sales, Purchases, Opening Stock, Ledger Opening Balances

Flow: Upload → Field Mapping → Validation → Dry Run → Transactional Import → Audit Log

Features:
- Duplicate prevention
- Financial period lock respect
- Proper voucher creation via accounting engine
- Ledger & inventory updates
- Import batch tracking
"""

import csv
import json
import uuid
import hashlib
from datetime import datetime, date
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field, asdict
from enum import Enum
import sqlite3
import traceback

# ============================================================================
# ENUMS & DATA CLASSES
# ============================================================================

class ImportType(str, Enum):
    SALES = "sales"
    PURCHASE = "purchase"
    OPENING_STOCK = "opening_stock"
    LEDGER_OPENING = "ledger_opening"

class ImportStatus(str, Enum):
    PENDING = "pending"
    VALIDATING = "validating"
    VALIDATED = "validated"
    DRY_RUN = "dry_run"
    IMPORTING = "importing"
    COMPLETED = "completed"
    FAILED = "failed"
    PARTIAL = "partial"

class SourceFormat(str, Enum):
    CSV = "csv"
    XLSX = "xlsx"
    JSON = "json"
    TALLY_XML = "tally_xml"
    GENERIC_POS = "generic_pos"

class ValidationSeverity(str, Enum):
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"

@dataclass
class ValidationIssue:
    row: int
    field: str
    message: str
    severity: ValidationSeverity
    value: Any = None
    suggestion: Optional[str] = None

@dataclass
class FieldMapping:
    source_field: str
    target_field: str
    transform: Optional[str] = None  # e.g., "date:DD/MM/YYYY", "number:en-IN"
    default_value: Optional[Any] = None
    required: bool = False

@dataclass
class ImportRecord:
    row_number: int
    data: Dict[str, Any]
    hash_key: str
    is_valid: bool = True
    issues: List[ValidationIssue] = field(default_factory=list)
    imported: bool = False
    voucher_id: Optional[str] = None

@dataclass
class ImportBatch:
    batch_id: str
    import_type: ImportType
    source_format: SourceFormat
    filename: str
    created_at: datetime
    status: ImportStatus
    total_records: int = 0
    valid_records: int = 0
    imported_records: int = 0
    failed_records: int = 0
    field_mappings: List[FieldMapping] = field(default_factory=list)
    records: List[ImportRecord] = field(default_factory=list)
    audit_log: List[Dict] = field(default_factory=list)
    financial_year: str = ""
    user_id: str = ""

# ============================================================================
# FIELD DEFINITIONS FOR EACH IMPORT TYPE
# ============================================================================

SALES_FIELDS = {
    "invoice_number": {"type": "string", "required": True, "label": "Invoice Number"},
    "invoice_date": {"type": "date", "required": True, "label": "Invoice Date"},
    "customer_name": {"type": "string", "required": True, "label": "Customer Name"},
    "customer_gstin": {"type": "gstin", "required": False, "label": "Customer GSTIN"},
    "customer_phone": {"type": "phone", "required": False, "label": "Phone"},
    "customer_address": {"type": "string", "required": False, "label": "Address"},
    "item_name": {"type": "string", "required": True, "label": "Item Name"},
    "hsn_code": {"type": "hsn", "required": False, "label": "HSN Code"},
    "quantity": {"type": "number", "required": True, "label": "Quantity"},
    "unit": {"type": "string", "required": False, "label": "Unit", "default": "PCS"},
    "rate": {"type": "decimal", "required": True, "label": "Rate"},
    "discount_percent": {"type": "decimal", "required": False, "label": "Discount %", "default": 0},
    "tax_percent": {"type": "decimal", "required": True, "label": "Tax %"},
    "total": {"type": "decimal", "required": False, "label": "Total"},
    "payment_mode": {"type": "enum", "required": False, "label": "Payment Mode", 
                     "options": ["cash", "credit", "upi", "card", "bank"], "default": "cash"},
    "payment_reference": {"type": "string", "required": False, "label": "Payment Reference"},
}

PURCHASE_FIELDS = {
    "invoice_number": {"type": "string", "required": True, "label": "Supplier Invoice No"},
    "invoice_date": {"type": "date", "required": True, "label": "Invoice Date"},
    "supplier_name": {"type": "string", "required": True, "label": "Supplier Name"},
    "supplier_gstin": {"type": "gstin", "required": False, "label": "Supplier GSTIN"},
    "item_name": {"type": "string", "required": True, "label": "Item Name"},
    "hsn_code": {"type": "hsn", "required": False, "label": "HSN Code"},
    "quantity": {"type": "number", "required": True, "label": "Quantity"},
    "unit": {"type": "string", "required": False, "label": "Unit", "default": "PCS"},
    "rate": {"type": "decimal", "required": True, "label": "Rate"},
    "tax_percent": {"type": "decimal", "required": True, "label": "Tax %"},
    "total": {"type": "decimal", "required": False, "label": "Total"},
    "payment_terms": {"type": "string", "required": False, "label": "Payment Terms"},
    "due_date": {"type": "date", "required": False, "label": "Due Date"},
}

OPENING_STOCK_FIELDS = {
    "sku": {"type": "string", "required": True, "label": "SKU / Item Code"},
    "item_name": {"type": "string", "required": True, "label": "Item Name"},
    "hsn_code": {"type": "hsn", "required": False, "label": "HSN Code"},
    "quantity": {"type": "number", "required": True, "label": "Quantity"},
    "unit": {"type": "string", "required": False, "label": "Unit", "default": "PCS"},
    "purchase_rate": {"type": "decimal", "required": True, "label": "Purchase Rate"},
    "mrp": {"type": "decimal", "required": False, "label": "MRP"},
    "batch_number": {"type": "string", "required": False, "label": "Batch Number"},
    "expiry_date": {"type": "date", "required": False, "label": "Expiry Date"},
    "location": {"type": "string", "required": False, "label": "Warehouse/Location"},
}

LEDGER_OPENING_FIELDS = {
    "ledger_type": {"type": "enum", "required": True, "label": "Ledger Type",
                    "options": ["debtor", "creditor"]},
    "party_name": {"type": "string", "required": True, "label": "Party Name"},
    "gstin": {"type": "gstin", "required": False, "label": "GSTIN"},
    "phone": {"type": "phone", "required": False, "label": "Phone"},
    "opening_balance": {"type": "decimal", "required": True, "label": "Opening Balance"},
    "balance_type": {"type": "enum", "required": True, "label": "Dr/Cr",
                     "options": ["debit", "credit"]},
    "as_on_date": {"type": "date", "required": True, "label": "As On Date"},
    "credit_limit": {"type": "decimal", "required": False, "label": "Credit Limit"},
    "credit_days": {"type": "number", "required": False, "label": "Credit Days", "default": 30},
}

FIELD_DEFINITIONS = {
    ImportType.SALES: SALES_FIELDS,
    ImportType.PURCHASE: PURCHASE_FIELDS,
    ImportType.OPENING_STOCK: OPENING_STOCK_FIELDS,
    ImportType.LEDGER_OPENING: LEDGER_OPENING_FIELDS,
}

# ============================================================================
# IMPORT ENGINE
# ============================================================================

class ImportEngine:
    """Main import engine that handles all import operations"""
    
    def __init__(self, db_path: str, accounting_engine=None):
        self.db_path = db_path
        self.accounting_engine = accounting_engine
        self._init_import_tables()
    
    def _get_connection(self):
        return sqlite3.connect(self.db_path, detect_types=sqlite3.PARSE_DECLTYPES)
    
    def _init_import_tables(self):
        """Create import tracking tables if not exists"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.executescript("""
            CREATE TABLE IF NOT EXISTS import_batches (
                batch_id TEXT PRIMARY KEY,
                import_type TEXT NOT NULL,
                source_format TEXT NOT NULL,
                filename TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                completed_at TIMESTAMP,
                status TEXT DEFAULT 'pending',
                total_records INTEGER DEFAULT 0,
                valid_records INTEGER DEFAULT 0,
                imported_records INTEGER DEFAULT 0,
                failed_records INTEGER DEFAULT 0,
                field_mappings TEXT,
                financial_year TEXT,
                user_id TEXT,
                error_message TEXT
            );
            
            CREATE TABLE IF NOT EXISTS import_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                batch_id TEXT NOT NULL,
                row_number INTEGER NOT NULL,
                data_hash TEXT NOT NULL,
                raw_data TEXT NOT NULL,
                mapped_data TEXT,
                is_valid INTEGER DEFAULT 1,
                validation_issues TEXT,
                imported INTEGER DEFAULT 0,
                voucher_id TEXT,
                voucher_type TEXT,
                imported_at TIMESTAMP,
                error_message TEXT,
                FOREIGN KEY (batch_id) REFERENCES import_batches(batch_id),
                UNIQUE(batch_id, data_hash)
            );
            
            CREATE TABLE IF NOT EXISTS import_audit_log (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                batch_id TEXT NOT NULL,
                action TEXT NOT NULL,
                details TEXT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                user_id TEXT,
                FOREIGN KEY (batch_id) REFERENCES import_batches(batch_id)
            );
            
            CREATE TABLE IF NOT EXISTS import_duplicates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                batch_id TEXT NOT NULL,
                data_hash TEXT NOT NULL,
                original_batch_id TEXT,
                original_voucher_id TEXT,
                detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (batch_id) REFERENCES import_batches(batch_id)
            );
            
            CREATE INDEX IF NOT EXISTS idx_import_records_batch ON import_records(batch_id);
            CREATE INDEX IF NOT EXISTS idx_import_records_hash ON import_records(data_hash);
            CREATE INDEX IF NOT EXISTS idx_import_audit_batch ON import_audit_log(batch_id);
        """)
        
        conn.commit()
        conn.close()
    
    # -------------------------------------------------------------------------
    # BATCH MANAGEMENT
    # -------------------------------------------------------------------------
    
    def create_batch(self, import_type: ImportType, source_format: SourceFormat,
                     filename: str, financial_year: str, user_id: str = "") -> str:
        """Create a new import batch and return batch_id"""
        batch_id = f"IMP-{datetime.now().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:6].upper()}"
        
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO import_batches 
            (batch_id, import_type, source_format, filename, financial_year, user_id, status)
            VALUES (?, ?, ?, ?, ?, ?, 'pending')
        """, (batch_id, import_type.value, source_format.value, filename, financial_year, user_id))
        
        conn.commit()
        conn.close()
        
        self._log_audit(batch_id, "BATCH_CREATED", 
                        f"Created {import_type.value} import batch from {filename}")
        
        return batch_id
    
    def get_batch(self, batch_id: str) -> Optional[Dict]:
        """Get batch details"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM import_batches WHERE batch_id = ?", (batch_id,))
        row = cursor.fetchone()
        conn.close()
        
        if row:
            columns = ['batch_id', 'import_type', 'source_format', 'filename', 'created_at',
                       'completed_at', 'status', 'total_records', 'valid_records', 
                       'imported_records', 'failed_records', 'field_mappings', 
                       'financial_year', 'user_id', 'error_message']
            return dict(zip(columns, row))
        return None
    
    def update_batch_status(self, batch_id: str, status: ImportStatus, error_msg: str = None):
        """Update batch status"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        if status in [ImportStatus.COMPLETED, ImportStatus.FAILED, ImportStatus.PARTIAL]:
            cursor.execute("""
                UPDATE import_batches 
                SET status = ?, completed_at = CURRENT_TIMESTAMP, error_message = ?
                WHERE batch_id = ?
            """, (status.value, error_msg, batch_id))
        else:
            cursor.execute("""
                UPDATE import_batches SET status = ?, error_message = ? WHERE batch_id = ?
            """, (status.value, error_msg, batch_id))
        
        conn.commit()
        conn.close()
        
        self._log_audit(batch_id, "STATUS_CHANGED", f"Status changed to {status.value}")
    
    # -------------------------------------------------------------------------
    # FILE PARSING
    # -------------------------------------------------------------------------
    
    def parse_file(self, batch_id: str, file_content: str, source_format: SourceFormat) -> Dict:
        """Parse uploaded file and return headers and sample data"""
        try:
            if source_format == SourceFormat.CSV:
                return self._parse_csv(file_content)
            elif source_format == SourceFormat.JSON:
                return self._parse_json(file_content)
            elif source_format == SourceFormat.TALLY_XML:
                return self._parse_tally_xml(file_content)
            else:
                return self._parse_csv(file_content)  # Default to CSV
        except Exception as e:
            self._log_audit(batch_id, "PARSE_ERROR", str(e))
            raise ValueError(f"Failed to parse file: {str(e)}")
    
    def _parse_csv(self, content: str) -> Dict:
        """Parse CSV content"""
        lines = content.strip().split('\n')
        if not lines:
            raise ValueError("Empty file")
        
        # Try to detect delimiter
        first_line = lines[0]
        delimiter = ','
        if '\t' in first_line:
            delimiter = '\t'
        elif ';' in first_line:
            delimiter = ';'
        
        reader = csv.DictReader(lines, delimiter=delimiter)
        headers = reader.fieldnames or []
        
        rows = []
        for i, row in enumerate(reader):
            if i >= 100:  # Limit preview to 100 rows
                break
            rows.append(row)
        
        return {
            "headers": headers,
            "sample_data": rows[:10],
            "total_rows": len(lines) - 1,
            "delimiter": delimiter
        }
    
    def _parse_json(self, content: str) -> Dict:
        """Parse JSON content"""
        data = json.loads(content)
        
        if isinstance(data, list) and len(data) > 0:
            headers = list(data[0].keys()) if isinstance(data[0], dict) else []
            return {
                "headers": headers,
                "sample_data": data[:10],
                "total_rows": len(data),
                "delimiter": None
            }
        elif isinstance(data, dict) and "records" in data:
            records = data["records"]
            headers = list(records[0].keys()) if records else []
            return {
                "headers": headers,
                "sample_data": records[:10],
                "total_rows": len(records),
                "delimiter": None
            }
        else:
            raise ValueError("Invalid JSON structure. Expected array or {records: []}")
    
    def _parse_tally_xml(self, content: str) -> Dict:
        """Parse Tally XML export"""
        # Simplified Tally XML parsing - would need full XML parsing in production
        import re
        
        # Extract vouchers from Tally format
        voucher_pattern = r'<VOUCHER[^>]*>(.*?)</VOUCHER>'
        vouchers = re.findall(voucher_pattern, content, re.DOTALL)
        
        rows = []
        headers = set()
        
        for voucher in vouchers[:100]:
            row = {}
            # Extract common fields
            for field in ['VOUCHERNUMBER', 'DATE', 'PARTYNAME', 'AMOUNT', 'NARRATION']:
                match = re.search(f'<{field}>(.*?)</{field}>', voucher)
                if match:
                    row[field.lower()] = match.group(1)
                    headers.add(field.lower())
            rows.append(row)
        
        return {
            "headers": list(headers),
            "sample_data": rows[:10],
            "total_rows": len(vouchers),
            "delimiter": None
        }
    
    # -------------------------------------------------------------------------
    # FIELD MAPPING
    # -------------------------------------------------------------------------
    
    def get_field_suggestions(self, import_type: ImportType, source_headers: List[str]) -> Dict:
        """Suggest field mappings based on header names"""
        target_fields = FIELD_DEFINITIONS[import_type]
        suggestions = {}
        
        # Common header name variations
        header_aliases = {
            "invoice_number": ["inv no", "invoice no", "bill no", "voucher no", "inv_no", "billno"],
            "invoice_date": ["date", "inv date", "bill date", "voucher date", "trans date"],
            "customer_name": ["customer", "party", "buyer", "client", "cust name", "party name"],
            "supplier_name": ["supplier", "vendor", "party", "seller", "supp name"],
            "customer_gstin": ["gstin", "gst no", "gst", "tin", "customer gst"],
            "supplier_gstin": ["gstin", "gst no", "gst", "tin", "supplier gst"],
            "item_name": ["item", "product", "description", "particulars", "item name", "product name"],
            "hsn_code": ["hsn", "hsn code", "sac", "sac code", "hsn/sac"],
            "quantity": ["qty", "quantity", "units", "nos", "pcs"],
            "rate": ["rate", "price", "unit price", "mrp", "unit rate"],
            "tax_percent": ["tax %", "gst %", "tax rate", "gst rate", "tax"],
            "total": ["total", "amount", "net amount", "gross", "value"],
            "payment_mode": ["payment", "mode", "pay mode", "payment type"],
            "sku": ["sku", "item code", "product code", "barcode", "code"],
            "purchase_rate": ["cost", "purchase price", "buy rate", "cost price"],
            "opening_balance": ["balance", "opening", "op bal", "amount"],
            "party_name": ["name", "party", "customer", "supplier", "account"]
        }
        
        for target_field, field_def in target_fields.items():
            best_match = None
            best_score = 0
            
            for source_header in source_headers:
                normalized_source = source_header.lower().strip()
                
                # Exact match
                if normalized_source == target_field:
                    best_match = source_header
                    best_score = 100
                    break
                
                # Check aliases
                if target_field in header_aliases:
                    for alias in header_aliases[target_field]:
                        if alias in normalized_source or normalized_source in alias:
                            if best_score < 80:
                                best_match = source_header
                                best_score = 80
                
                # Partial match
                if target_field.replace('_', ' ') in normalized_source:
                    if best_score < 60:
                        best_match = source_header
                        best_score = 60
            
            suggestions[target_field] = {
                "suggested_source": best_match,
                "confidence": best_score,
                "required": field_def.get("required", False),
                "label": field_def.get("label", target_field),
                "type": field_def.get("type", "string"),
                "default": field_def.get("default"),
                "options": field_def.get("options")
            }
        
        return suggestions
    
    def save_field_mappings(self, batch_id: str, mappings: List[Dict]) -> None:
        """Save field mappings for the batch"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE import_batches SET field_mappings = ? WHERE batch_id = ?
        """, (json.dumps(mappings), batch_id))
        
        conn.commit()
        conn.close()
        
        self._log_audit(batch_id, "MAPPINGS_SAVED", f"Saved {len(mappings)} field mappings")
    
    # -------------------------------------------------------------------------
    # VALIDATION
    # -------------------------------------------------------------------------
    
    def validate_batch(self, batch_id: str, data_rows: List[Dict], 
                       mappings: List[Dict]) -> Dict:
        """Validate all records in batch"""
        self.update_batch_status(batch_id, ImportStatus.VALIDATING)
        
        batch = self.get_batch(batch_id)
        import_type = ImportType(batch['import_type'])
        field_defs = FIELD_DEFINITIONS[import_type]
        
        # Create mapping lookup
        mapping_lookup = {m['target_field']: m for m in mappings}
        
        conn = self._get_connection()
        cursor = conn.cursor()
        
        valid_count = 0
        issues_summary = {"errors": 0, "warnings": 0}
        all_issues = []
        
        for row_num, raw_row in enumerate(data_rows, start=1):
            # Apply mappings to get target data
            mapped_data = self._apply_mappings(raw_row, mappings)
            
            # Generate hash for duplicate detection
            data_hash = self._generate_hash(import_type, mapped_data)
            
            # Validate the record
            issues = self._validate_record(row_num, mapped_data, field_defs, import_type)
            
            # Check for duplicates
            dup_check = self._check_duplicate(batch_id, data_hash, cursor)
            if dup_check:
                issues.append(ValidationIssue(
                    row=row_num,
                    field="*",
                    message=f"Duplicate: already imported in batch {dup_check['batch_id']}",
                    severity=ValidationSeverity.ERROR,
                    suggestion="Skip this record or modify unique fields"
                ))
            
            is_valid = not any(i.severity == ValidationSeverity.ERROR for i in issues)
            if is_valid:
                valid_count += 1
            
            for issue in issues:
                if issue.severity == ValidationSeverity.ERROR:
                    issues_summary["errors"] += 1
                else:
                    issues_summary["warnings"] += 1
                all_issues.append(asdict(issue))
            
            # Store record
            cursor.execute("""
                INSERT OR REPLACE INTO import_records 
                (batch_id, row_number, data_hash, raw_data, mapped_data, is_valid, validation_issues)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                batch_id, row_num, data_hash,
                json.dumps(raw_row), json.dumps(mapped_data),
                1 if is_valid else 0,
                json.dumps([asdict(i) for i in issues])
            ))
        
        # Update batch stats
        cursor.execute("""
            UPDATE import_batches 
            SET total_records = ?, valid_records = ?, status = 'validated'
            WHERE batch_id = ?
        """, (len(data_rows), valid_count, batch_id))
        
        conn.commit()
        conn.close()
        
        self._log_audit(batch_id, "VALIDATION_COMPLETE", 
                        f"Validated {len(data_rows)} records, {valid_count} valid")
        
        self.update_batch_status(batch_id, ImportStatus.VALIDATED)
        
        return {
            "total_records": len(data_rows),
            "valid_records": valid_count,
            "invalid_records": len(data_rows) - valid_count,
            "issues_summary": issues_summary,
            "issues": all_issues[:100]  # Limit returned issues
        }
    
    def _apply_mappings(self, raw_row: Dict, mappings: List[Dict]) -> Dict:
        """Apply field mappings to transform raw data"""
        result = {}
        
        for mapping in mappings:
            source_field = mapping.get('source_field')
            target_field = mapping['target_field']
            transform = mapping.get('transform')
            default = mapping.get('default_value')
            
            value = raw_row.get(source_field) if source_field else None
            
            if value is None or value == '':
                value = default
            elif transform:
                value = self._apply_transform(value, transform)
            
            result[target_field] = value
        
        return result
    
    def _apply_transform(self, value: Any, transform: str) -> Any:
        """Apply transformation to value"""
        if not value or not transform:
            return value
        
        try:
            if transform.startswith('date:'):
                fmt = transform.split(':')[1]
                # Convert date format
                if fmt == 'DD/MM/YYYY':
                    parts = str(value).split('/')
                    return f"{parts[2]}-{parts[1]}-{parts[0]}"
                elif fmt == 'MM/DD/YYYY':
                    parts = str(value).split('/')
                    return f"{parts[2]}-{parts[0]}-{parts[1]}"
            elif transform.startswith('number:'):
                # Handle Indian number format
                return float(str(value).replace(',', ''))
            elif transform == 'uppercase':
                return str(value).upper()
            elif transform == 'lowercase':
                return str(value).lower()
            elif transform == 'trim':
                return str(value).strip()
        except:
            pass
        
        return value
    
    def _generate_hash(self, import_type: ImportType, data: Dict) -> str:
        """Generate unique hash for duplicate detection"""
        key_fields = {
            ImportType.SALES: ['invoice_number', 'invoice_date', 'customer_name'],
            ImportType.PURCHASE: ['invoice_number', 'invoice_date', 'supplier_name'],
            ImportType.OPENING_STOCK: ['sku', 'batch_number'],
            ImportType.LEDGER_OPENING: ['party_name', 'ledger_type', 'as_on_date']
        }
        
        fields = key_fields.get(import_type, [])
        hash_string = '|'.join(str(data.get(f, '')) for f in fields)
        return hashlib.md5(hash_string.encode()).hexdigest()
    
    def _validate_record(self, row_num: int, data: Dict, field_defs: Dict, 
                         import_type: ImportType) -> List[ValidationIssue]:
        """Validate a single record"""
        issues = []
        
        for field_name, field_def in field_defs.items():
            value = data.get(field_name)
            field_type = field_def.get('type', 'string')
            required = field_def.get('required', False)
            label = field_def.get('label', field_name)
            
            # Check required
            if required and (value is None or value == ''):
                issues.append(ValidationIssue(
                    row=row_num, field=field_name,
                    message=f"{label} is required",
                    severity=ValidationSeverity.ERROR
                ))
                continue
            
            if value is None or value == '':
                continue
            
            # Type-specific validation
            if field_type == 'date':
                if not self._validate_date(value):
                    issues.append(ValidationIssue(
                        row=row_num, field=field_name, value=value,
                        message=f"Invalid date format for {label}",
                        severity=ValidationSeverity.ERROR,
                        suggestion="Use YYYY-MM-DD format"
                    ))
            
            elif field_type in ['number', 'decimal']:
                try:
                    float(value)
                except:
                    issues.append(ValidationIssue(
                        row=row_num, field=field_name, value=value,
                        message=f"Invalid number for {label}",
                        severity=ValidationSeverity.ERROR
                    ))
            
            elif field_type == 'gstin':
                if value and not self._validate_gstin(str(value)):
                    issues.append(ValidationIssue(
                        row=row_num, field=field_name, value=value,
                        message=f"Invalid GSTIN format",
                        severity=ValidationSeverity.WARNING,
                        suggestion="GSTIN should be 15 characters"
                    ))
            
            elif field_type == 'hsn':
                if value and not self._validate_hsn(str(value)):
                    issues.append(ValidationIssue(
                        row=row_num, field=field_name, value=value,
                        message=f"Invalid HSN code",
                        severity=ValidationSeverity.WARNING,
                        suggestion="HSN code should be 4-8 digits"
                    ))
            
            elif field_type == 'enum':
                options = field_def.get('options', [])
                if str(value).lower() not in [o.lower() for o in options]:
                    issues.append(ValidationIssue(
                        row=row_num, field=field_name, value=value,
                        message=f"Invalid value for {label}",
                        severity=ValidationSeverity.ERROR,
                        suggestion=f"Valid options: {', '.join(options)}"
                    ))
        
        # Cross-field validations
        if import_type == ImportType.SALES:
            qty = data.get('quantity')
            rate = data.get('rate')
            total = data.get('total')
            if qty and rate and total:
                try:
                    expected = float(qty) * float(rate)
                    actual = float(total)
                    if abs(expected - actual) > 1:  # Allow ₹1 tolerance
                        issues.append(ValidationIssue(
                            row=row_num, field='total', value=total,
                            message=f"Total mismatch: expected {expected:.2f}",
                            severity=ValidationSeverity.WARNING
                        ))
                except:
                    pass
        
        return issues
    
    def _validate_date(self, value: Any) -> bool:
        """Validate date format"""
        if not value:
            return True
        try:
            if isinstance(value, (date, datetime)):
                return True
            # Try common formats
            for fmt in ['%Y-%m-%d', '%d/%m/%Y', '%d-%m-%Y', '%m/%d/%Y']:
                try:
                    datetime.strptime(str(value), fmt)
                    return True
                except:
                    continue
            return False
        except:
            return False
    
    def _validate_gstin(self, value: str) -> bool:
        """Validate GSTIN format"""
        import re
        if not value:
            return True
        pattern = r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$'
        return bool(re.match(pattern, value.upper()))
    
    def _validate_hsn(self, value: str) -> bool:
        """Validate HSN code"""
        if not value:
            return True
        return value.isdigit() and 4 <= len(value) <= 8
    
    def _check_duplicate(self, batch_id: str, data_hash: str, cursor) -> Optional[Dict]:
        """Check if record already exists"""
        cursor.execute("""
            SELECT batch_id, voucher_id FROM import_records 
            WHERE data_hash = ? AND batch_id != ? AND imported = 1
        """, (data_hash, batch_id))
        
        row = cursor.fetchone()
        if row:
            return {"batch_id": row[0], "voucher_id": row[1]}
        return None
    
    # -------------------------------------------------------------------------
    # DRY RUN
    # -------------------------------------------------------------------------
    
    def dry_run(self, batch_id: str) -> Dict:
        """Perform dry run - simulate import without committing"""
        self.update_batch_status(batch_id, ImportStatus.DRY_RUN)
        
        batch = self.get_batch(batch_id)
        import_type = ImportType(batch['import_type'])
        
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT row_number, mapped_data, is_valid FROM import_records 
            WHERE batch_id = ? AND is_valid = 1 ORDER BY row_number
        """, (batch_id,))
        
        records = cursor.fetchall()
        conn.close()
        
        preview = {
            "vouchers_to_create": [],
            "inventory_changes": [],
            "ledger_changes": [],
            "summary": {
                "total_vouchers": 0,
                "total_amount": 0,
                "items_affected": 0,
                "parties_affected": set()
            }
        }
        
        # Group records by voucher (for multi-line invoices)
        voucher_groups = self._group_by_voucher(import_type, records)
        
        for voucher_key, voucher_records in voucher_groups.items():
            voucher_preview = self._preview_voucher(import_type, voucher_records)
            preview["vouchers_to_create"].append(voucher_preview)
            preview["summary"]["total_vouchers"] += 1
            preview["summary"]["total_amount"] += voucher_preview.get("total", 0)
            preview["summary"]["parties_affected"].add(voucher_preview.get("party_name", ""))
        
        preview["summary"]["parties_affected"] = list(preview["summary"]["parties_affected"])
        
        self._log_audit(batch_id, "DRY_RUN_COMPLETE", 
                        f"Preview: {preview['summary']['total_vouchers']} vouchers")
        
        return preview
    
    def _group_by_voucher(self, import_type: ImportType, records: List) -> Dict:
        """Group records by voucher key (for multi-line invoices)"""
        groups = {}
        
        for row_num, mapped_data_json, is_valid in records:
            data = json.loads(mapped_data_json)
            
            if import_type == ImportType.SALES:
                key = (data.get('invoice_number'), data.get('invoice_date'), data.get('customer_name'))
            elif import_type == ImportType.PURCHASE:
                key = (data.get('invoice_number'), data.get('invoice_date'), data.get('supplier_name'))
            else:
                key = (row_num,)  # Each record is its own voucher
            
            if key not in groups:
                groups[key] = []
            groups[key].append((row_num, data))
        
        return groups
    
    def _preview_voucher(self, import_type: ImportType, records: List) -> Dict:
        """Generate preview for a single voucher"""
        if import_type == ImportType.SALES:
            first_record = records[0][1]
            items = []
            total = 0
            
            for row_num, data in records:
                qty = float(data.get('quantity', 0) or 0)
                rate = float(data.get('rate', 0) or 0)
                tax = float(data.get('tax_percent', 0) or 0)
                item_total = qty * rate * (1 + tax/100)
                total += item_total
                
                items.append({
                    "item_name": data.get('item_name'),
                    "hsn": data.get('hsn_code'),
                    "qty": qty,
                    "rate": rate,
                    "tax": tax,
                    "amount": item_total
                })
            
            return {
                "voucher_type": "Sales Invoice",
                "voucher_number": first_record.get('invoice_number'),
                "date": first_record.get('invoice_date'),
                "party_name": first_record.get('customer_name'),
                "gstin": first_record.get('customer_gstin'),
                "items": items,
                "total": round(total, 2),
                "payment_mode": first_record.get('payment_mode', 'cash')
            }
        
        elif import_type == ImportType.PURCHASE:
            first_record = records[0][1]
            items = []
            total = 0
            
            for row_num, data in records:
                qty = float(data.get('quantity', 0) or 0)
                rate = float(data.get('rate', 0) or 0)
                tax = float(data.get('tax_percent', 0) or 0)
                item_total = qty * rate * (1 + tax/100)
                total += item_total
                
                items.append({
                    "item_name": data.get('item_name'),
                    "hsn": data.get('hsn_code'),
                    "qty": qty,
                    "rate": rate,
                    "tax": tax,
                    "amount": item_total
                })
            
            return {
                "voucher_type": "Purchase Invoice",
                "voucher_number": first_record.get('invoice_number'),
                "date": first_record.get('invoice_date'),
                "party_name": first_record.get('supplier_name'),
                "gstin": first_record.get('supplier_gstin'),
                "items": items,
                "total": round(total, 2),
                "payment_terms": first_record.get('payment_terms')
            }
        
        elif import_type == ImportType.OPENING_STOCK:
            data = records[0][1]
            qty = float(data.get('quantity', 0) or 0)
            rate = float(data.get('purchase_rate', 0) or 0)
            
            return {
                "voucher_type": "Stock Journal",
                "item_name": data.get('item_name'),
                "sku": data.get('sku'),
                "qty": qty,
                "rate": rate,
                "total": round(qty * rate, 2),
                "batch": data.get('batch_number'),
                "location": data.get('location')
            }
        
        elif import_type == ImportType.LEDGER_OPENING:
            data = records[0][1]
            return {
                "voucher_type": "Opening Balance",
                "party_name": data.get('party_name'),
                "ledger_type": data.get('ledger_type'),
                "balance": float(data.get('opening_balance', 0) or 0),
                "balance_type": data.get('balance_type'),
                "as_on_date": data.get('as_on_date')
            }
        
        return {}
    
    # -------------------------------------------------------------------------
    # TRANSACTIONAL IMPORT
    # -------------------------------------------------------------------------
    
    def execute_import(self, batch_id: str, skip_invalid: bool = True) -> Dict:
        """Execute the actual import with transaction safety"""
        self.update_batch_status(batch_id, ImportStatus.IMPORTING)
        
        batch = self.get_batch(batch_id)
        import_type = ImportType(batch['import_type'])
        financial_year = batch['financial_year']
        
        # Check financial period lock
        if self._is_period_locked(financial_year):
            self.update_batch_status(batch_id, ImportStatus.FAILED, 
                                     "Financial period is locked")
            raise ValueError(f"Financial period {financial_year} is locked")
        
        conn = self._get_connection()
        cursor = conn.cursor()
        
        # Get valid records
        cursor.execute("""
            SELECT id, row_number, mapped_data FROM import_records 
            WHERE batch_id = ? AND is_valid = 1 AND imported = 0 
            ORDER BY row_number
        """, (batch_id,))
        
        records = cursor.fetchall()
        
        # Group by voucher
        voucher_groups = {}
        for record_id, row_num, mapped_data_json in records:
            data = json.loads(mapped_data_json)
            
            if import_type == ImportType.SALES:
                key = (data.get('invoice_number'), data.get('invoice_date'), data.get('customer_name'))
            elif import_type == ImportType.PURCHASE:
                key = (data.get('invoice_number'), data.get('invoice_date'), data.get('supplier_name'))
            else:
                key = (record_id,)
            
            if key not in voucher_groups:
                voucher_groups[key] = []
            voucher_groups[key].append((record_id, row_num, data))
        
        imported = 0
        failed = 0
        results = []
        
        for voucher_key, voucher_records in voucher_groups.items():
            try:
                # Start transaction for each voucher
                cursor.execute("SAVEPOINT voucher_import")
                
                # Create voucher through accounting engine
                voucher_result = self._create_voucher(
                    cursor, import_type, voucher_records, batch_id
                )
                
                # Mark records as imported
                for record_id, _, _ in voucher_records:
                    cursor.execute("""
                        UPDATE import_records 
                        SET imported = 1, voucher_id = ?, voucher_type = ?, imported_at = CURRENT_TIMESTAMP
                        WHERE id = ?
                    """, (voucher_result['voucher_id'], voucher_result['voucher_type'], record_id))
                
                cursor.execute("RELEASE voucher_import")
                imported += 1
                results.append({
                    "status": "success",
                    "voucher_id": voucher_result['voucher_id'],
                    "voucher_type": voucher_result['voucher_type']
                })
                
            except Exception as e:
                cursor.execute("ROLLBACK TO voucher_import")
                failed += 1
                
                # Mark records as failed
                for record_id, _, _ in voucher_records:
                    cursor.execute("""
                        UPDATE import_records SET error_message = ? WHERE id = ?
                    """, (str(e), record_id))
                
                results.append({
                    "status": "failed",
                    "error": str(e),
                    "rows": [r[1] for r in voucher_records]
                })
                
                self._log_audit(batch_id, "IMPORT_ERROR", 
                                f"Failed to import voucher: {str(e)}")
        
        # Update batch stats
        cursor.execute("""
            UPDATE import_batches 
            SET imported_records = ?, failed_records = ?
            WHERE batch_id = ?
        """, (imported, failed, batch_id))
        
        conn.commit()
        conn.close()
        
        # Set final status
        if failed == 0:
            self.update_batch_status(batch_id, ImportStatus.COMPLETED)
        elif imported == 0:
            self.update_batch_status(batch_id, ImportStatus.FAILED, "All records failed")
        else:
            self.update_batch_status(batch_id, ImportStatus.PARTIAL, 
                                     f"{failed} records failed")
        
        self._log_audit(batch_id, "IMPORT_COMPLETE", 
                        f"Imported {imported}, Failed {failed}")
        
        return {
            "imported": imported,
            "failed": failed,
            "results": results
        }
    
    def _create_voucher(self, cursor, import_type: ImportType, 
                        records: List, batch_id: str) -> Dict:
        """Create voucher using accounting engine patterns"""
        
        if import_type == ImportType.SALES:
            return self._create_sales_voucher(cursor, records, batch_id)
        elif import_type == ImportType.PURCHASE:
            return self._create_purchase_voucher(cursor, records, batch_id)
        elif import_type == ImportType.OPENING_STOCK:
            return self._create_stock_journal(cursor, records[0], batch_id)
        elif import_type == ImportType.LEDGER_OPENING:
            return self._create_opening_balance(cursor, records[0], batch_id)
        
        raise ValueError(f"Unknown import type: {import_type}")
    
    def _create_sales_voucher(self, cursor, records: List, batch_id: str) -> Dict:
        """Create sales invoice and update ledgers/inventory"""
        first_data = records[0][2]
        
        voucher_id = f"SIMP-{datetime.now().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:4].upper()}"
        
        # Ensure customer exists
        customer_id = self._ensure_party(cursor, {
            'name': first_data.get('customer_name'),
            'gstin': first_data.get('customer_gstin'),
            'phone': first_data.get('customer_phone'),
            'type': 'customer'
        })
        
        # Calculate totals
        items = []
        subtotal = 0
        total_tax = 0
        
        for _, _, data in records:
            qty = float(data.get('quantity', 0) or 0)
            rate = float(data.get('rate', 0) or 0)
            tax_pct = float(data.get('tax_percent', 0) or 0)
            discount = float(data.get('discount_percent', 0) or 0)
            
            line_amount = qty * rate * (1 - discount/100)
            line_tax = line_amount * tax_pct / 100
            
            item_id = self._ensure_item(cursor, {
                'name': data.get('item_name'),
                'hsn': data.get('hsn_code'),
                'unit': data.get('unit', 'PCS')
            })
            
            items.append({
                'item_id': item_id,
                'item_name': data.get('item_name'),
                'hsn': data.get('hsn_code'),
                'qty': qty,
                'rate': rate,
                'discount': discount,
                'tax_percent': tax_pct,
                'tax_amount': line_tax,
                'amount': line_amount + line_tax
            })
            
            subtotal += line_amount
            total_tax += line_tax
            
            # Update inventory (reduce stock)
            self._update_inventory(cursor, item_id, -qty, rate, 'sale')
        
        grand_total = subtotal + total_tax
        
        # Insert sales invoice
        cursor.execute("""
            INSERT INTO sales_invoices 
            (invoice_id, invoice_number, invoice_date, customer_id, customer_name, customer_gstin,
             subtotal, tax_amount, total_amount, payment_mode, import_batch_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        """, (
            voucher_id, first_data.get('invoice_number'), first_data.get('invoice_date'),
            customer_id, first_data.get('customer_name'), first_data.get('customer_gstin'),
            subtotal, total_tax, grand_total, first_data.get('payment_mode', 'cash'), batch_id
        ))
        
        # Insert line items
        for item in items:
            cursor.execute("""
                INSERT INTO sales_invoice_items 
                (invoice_id, item_id, item_name, hsn_code, quantity, rate, discount_percent,
                 tax_percent, tax_amount, amount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                voucher_id, item['item_id'], item['item_name'], item['hsn'],
                item['qty'], item['rate'], item['discount'], item['tax_percent'],
                item['tax_amount'], item['amount']
            ))
        
        # Update customer ledger (debit)
        self._update_ledger(cursor, customer_id, 'customer', grand_total, 'debit', 
                           f"Sales Invoice {first_data.get('invoice_number')}", voucher_id)
        
        return {"voucher_id": voucher_id, "voucher_type": "sales_invoice"}
    
    def _create_purchase_voucher(self, cursor, records: List, batch_id: str) -> Dict:
        """Create purchase invoice and update ledgers/inventory"""
        first_data = records[0][2]
        
        voucher_id = f"PIMP-{datetime.now().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:4].upper()}"
        
        # Ensure supplier exists
        supplier_id = self._ensure_party(cursor, {
            'name': first_data.get('supplier_name'),
            'gstin': first_data.get('supplier_gstin'),
            'type': 'supplier'
        })
        
        items = []
        subtotal = 0
        total_tax = 0
        
        for _, _, data in records:
            qty = float(data.get('quantity', 0) or 0)
            rate = float(data.get('rate', 0) or 0)
            tax_pct = float(data.get('tax_percent', 0) or 0)
            
            line_amount = qty * rate
            line_tax = line_amount * tax_pct / 100
            
            item_id = self._ensure_item(cursor, {
                'name': data.get('item_name'),
                'hsn': data.get('hsn_code'),
                'unit': data.get('unit', 'PCS')
            })
            
            items.append({
                'item_id': item_id,
                'item_name': data.get('item_name'),
                'hsn': data.get('hsn_code'),
                'qty': qty,
                'rate': rate,
                'tax_percent': tax_pct,
                'tax_amount': line_tax,
                'amount': line_amount + line_tax
            })
            
            subtotal += line_amount
            total_tax += line_tax
            
            # Update inventory (increase stock)
            self._update_inventory(cursor, item_id, qty, rate, 'purchase')
        
        grand_total = subtotal + total_tax
        
        # Insert purchase invoice
        cursor.execute("""
            INSERT INTO purchase_invoices 
            (invoice_id, supplier_invoice_no, invoice_date, supplier_id, supplier_name, supplier_gstin,
             subtotal, tax_amount, total_amount, payment_terms, due_date, import_batch_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        """, (
            voucher_id, first_data.get('invoice_number'), first_data.get('invoice_date'),
            supplier_id, first_data.get('supplier_name'), first_data.get('supplier_gstin'),
            subtotal, total_tax, grand_total, first_data.get('payment_terms'),
            first_data.get('due_date'), batch_id
        ))
        
        # Insert line items
        for item in items:
            cursor.execute("""
                INSERT INTO purchase_invoice_items 
                (invoice_id, item_id, item_name, hsn_code, quantity, rate,
                 tax_percent, tax_amount, amount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                voucher_id, item['item_id'], item['item_name'], item['hsn'],
                item['qty'], item['rate'], item['tax_percent'],
                item['tax_amount'], item['amount']
            ))
        
        # Update supplier ledger (credit)
        self._update_ledger(cursor, supplier_id, 'supplier', grand_total, 'credit',
                           f"Purchase Invoice {first_data.get('invoice_number')}", voucher_id)
        
        return {"voucher_id": voucher_id, "voucher_type": "purchase_invoice"}
    
    def _create_stock_journal(self, cursor, record: Tuple, batch_id: str) -> Dict:
        """Create opening stock entry"""
        _, _, data = record
        
        voucher_id = f"SJIMP-{datetime.now().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:4].upper()}"
        
        item_id = self._ensure_item(cursor, {
            'name': data.get('item_name'),
            'sku': data.get('sku'),
            'hsn': data.get('hsn_code'),
            'unit': data.get('unit', 'PCS'),
            'mrp': data.get('mrp')
        })
        
        qty = float(data.get('quantity', 0) or 0)
        rate = float(data.get('purchase_rate', 0) or 0)
        
        # Update inventory directly for opening stock
        self._update_inventory(cursor, item_id, qty, rate, 'opening',
                              batch=data.get('batch_number'),
                              expiry=data.get('expiry_date'),
                              location=data.get('location'))
        
        # Create stock journal entry
        cursor.execute("""
            INSERT INTO stock_journals 
            (journal_id, journal_type, item_id, item_name, quantity, rate, total_value,
             batch_number, location, narration, import_batch_id, created_at)
            VALUES (?, 'opening', ?, ?, ?, ?, ?, ?, ?, 'Opening Stock Import', ?, CURRENT_TIMESTAMP)
        """, (
            voucher_id, item_id, data.get('item_name'), qty, rate, qty * rate,
            data.get('batch_number'), data.get('location'), batch_id
        ))
        
        return {"voucher_id": voucher_id, "voucher_type": "stock_journal"}
    
    def _create_opening_balance(self, cursor, record: Tuple, batch_id: str) -> Dict:
        """Create ledger opening balance entry"""
        _, _, data = record
        
        voucher_id = f"OBIMP-{datetime.now().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:4].upper()}"
        
        party_type = 'customer' if data.get('ledger_type') == 'debtor' else 'supplier'
        
        party_id = self._ensure_party(cursor, {
            'name': data.get('party_name'),
            'gstin': data.get('gstin'),
            'phone': data.get('phone'),
            'type': party_type,
            'credit_limit': data.get('credit_limit'),
            'credit_days': data.get('credit_days')
        })
        
        balance = float(data.get('opening_balance', 0) or 0)
        balance_type = data.get('balance_type', 'debit')
        
        # Create opening balance entry
        cursor.execute("""
            INSERT INTO ledger_opening_balances 
            (entry_id, party_id, party_name, party_type, opening_balance, balance_type,
             as_on_date, import_batch_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        """, (
            voucher_id, party_id, data.get('party_name'), party_type,
            balance, balance_type, data.get('as_on_date'), batch_id
        ))
        
        # Update party ledger
        self._update_ledger(cursor, party_id, party_type, balance, balance_type,
                           f"Opening Balance as on {data.get('as_on_date')}", voucher_id)
        
        return {"voucher_id": voucher_id, "voucher_type": "opening_balance"}
    
    # -------------------------------------------------------------------------
    # HELPER METHODS FOR ACCOUNTING ENGINE
    # -------------------------------------------------------------------------
    
    def _ensure_party(self, cursor, party_data: Dict) -> str:
        """Ensure party exists, create if not. Returns party_id"""
        cursor.execute("""
            SELECT id FROM parties WHERE LOWER(name) = LOWER(?) AND type = ?
        """, (party_data['name'], party_data['type']))
        
        row = cursor.fetchone()
        if row:
            return row[0]
        
        party_id = f"P-{uuid.uuid4().hex[:8].upper()}"
        cursor.execute("""
            INSERT INTO parties (id, name, gstin, phone, type, credit_limit, credit_days, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        """, (
            party_id, party_data['name'], party_data.get('gstin'),
            party_data.get('phone'), party_data['type'],
            party_data.get('credit_limit'), party_data.get('credit_days')
        ))
        
        return party_id
    
    def _ensure_item(self, cursor, item_data: Dict) -> str:
        """Ensure item exists, create if not. Returns item_id"""
        cursor.execute("""
            SELECT id FROM items WHERE LOWER(name) = LOWER(?)
        """, (item_data['name'],))
        
        row = cursor.fetchone()
        if row:
            return row[0]
        
        item_id = f"ITM-{uuid.uuid4().hex[:8].upper()}"
        cursor.execute("""
            INSERT INTO items (id, name, sku, hsn_code, unit, mrp, created_at)
            VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        """, (
            item_id, item_data['name'], item_data.get('sku'),
            item_data.get('hsn'), item_data.get('unit', 'PCS'),
            item_data.get('mrp')
        ))
        
        return item_id
    
    def _update_inventory(self, cursor, item_id: str, qty_change: float, 
                          rate: float, trans_type: str, **kwargs):
        """Update inventory stock levels"""
        # Get current stock
        cursor.execute("SELECT stock_qty, avg_cost FROM inventory WHERE item_id = ?", (item_id,))
        row = cursor.fetchone()
        
        if row:
            current_qty, current_cost = row
            new_qty = current_qty + qty_change
            
            # Calculate weighted average cost for purchases
            if qty_change > 0 and trans_type in ['purchase', 'opening']:
                total_value = (current_qty * current_cost) + (qty_change * rate)
                new_cost = total_value / new_qty if new_qty > 0 else rate
            else:
                new_cost = current_cost
            
            cursor.execute("""
                UPDATE inventory SET stock_qty = ?, avg_cost = ?, updated_at = CURRENT_TIMESTAMP
                WHERE item_id = ?
            """, (new_qty, new_cost, item_id))
        else:
            cursor.execute("""
                INSERT INTO inventory (item_id, stock_qty, avg_cost, created_at)
                VALUES (?, ?, ?, CURRENT_TIMESTAMP)
            """, (item_id, qty_change, rate))
        
        # Log stock movement
        cursor.execute("""
            INSERT INTO stock_movements 
            (item_id, movement_type, quantity, rate, batch_number, location, created_at)
            VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        """, (
            item_id, trans_type, qty_change, rate,
            kwargs.get('batch'), kwargs.get('location')
        ))
    
    def _update_ledger(self, cursor, party_id: str, party_type: str,
                       amount: float, dr_cr: str, narration: str, voucher_id: str):
        """Update party ledger with transaction"""
        cursor.execute("""
            INSERT INTO ledger_entries 
            (party_id, party_type, amount, dr_cr, narration, voucher_id, voucher_type, created_at)
            VALUES (?, ?, ?, ?, ?, ?, 'import', CURRENT_TIMESTAMP)
        """, (party_id, party_type, amount, dr_cr, narration, voucher_id))
        
        # Update party balance
        balance_change = amount if dr_cr == 'debit' else -amount
        cursor.execute("""
            UPDATE parties SET balance = COALESCE(balance, 0) + ? WHERE id = ?
        """, (balance_change, party_id))
    
    def _is_period_locked(self, financial_year: str) -> bool:
        """Check if financial period is locked"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT is_locked FROM financial_periods WHERE year = ?
        """, (financial_year,))
        
        row = cursor.fetchone()
        conn.close()
        
        return bool(row and row[0])
    
    # -------------------------------------------------------------------------
    # AUDIT LOGGING
    # -------------------------------------------------------------------------
    
    def _log_audit(self, batch_id: str, action: str, details: str, user_id: str = ""):
        """Log audit entry"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO import_audit_log (batch_id, action, details, user_id)
            VALUES (?, ?, ?, ?)
        """, (batch_id, action, details, user_id))
        
        conn.commit()
        conn.close()
    
    def get_audit_log(self, batch_id: str) -> List[Dict]:
        """Get audit log for a batch"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT action, details, timestamp, user_id 
            FROM import_audit_log WHERE batch_id = ? ORDER BY timestamp DESC
        """, (batch_id,))
        
        rows = cursor.fetchall()
        conn.close()
        
        return [
            {"action": r[0], "details": r[1], "timestamp": r[2], "user_id": r[3]}
            for r in rows
        ]
    
    # -------------------------------------------------------------------------
    # BATCH LISTING & HISTORY
    # -------------------------------------------------------------------------
    
    def list_batches(self, import_type: ImportType = None, 
                     status: ImportStatus = None, limit: int = 50) -> List[Dict]:
        """List import batches with optional filters"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        query = "SELECT * FROM import_batches WHERE 1=1"
        params = []
        
        if import_type:
            query += " AND import_type = ?"
            params.append(import_type.value)
        
        if status:
            query += " AND status = ?"
            params.append(status.value)
        
        query += " ORDER BY created_at DESC LIMIT ?"
        params.append(limit)
        
        cursor.execute(query, params)
        rows = cursor.fetchall()
        conn.close()
        
        columns = ['batch_id', 'import_type', 'source_format', 'filename', 'created_at',
                   'completed_at', 'status', 'total_records', 'valid_records',
                   'imported_records', 'failed_records', 'field_mappings',
                   'financial_year', 'user_id', 'error_message']
        
        return [dict(zip(columns, row)) for row in rows]


# ============================================================================
# API INTEGRATION
# ============================================================================

def create_import_api_routes(app, db_path: str):
    """Create FastAPI routes for import engine"""
    from fastapi import HTTPException, UploadFile, File
    from pydantic import BaseModel
    
    engine = ImportEngine(db_path)
    
    class CreateBatchRequest(BaseModel):
        import_type: str
        source_format: str
        filename: str
        financial_year: str
    
    class FieldMappingRequest(BaseModel):
        batch_id: str
        mappings: List[Dict]
    
    class ValidateRequest(BaseModel):
        batch_id: str
        data_rows: List[Dict]
    
    @app.post("/api/import/batch/create")
    async def create_batch(request: CreateBatchRequest):
        try:
            batch_id = engine.create_batch(
                ImportType(request.import_type),
                SourceFormat(request.source_format),
                request.filename,
                request.financial_year
            )
            return {"batch_id": batch_id}
        except Exception as e:
            raise HTTPException(500, str(e))
    
    @app.get("/api/import/batch/{batch_id}")
    async def get_batch(batch_id: str):
        batch = engine.get_batch(batch_id)
        if not batch:
            raise HTTPException(404, "Batch not found")
        return batch
    
    @app.post("/api/import/parse")
    async def parse_file(batch_id: str, content: str, source_format: str):
        try:
            result = engine.parse_file(batch_id, content, SourceFormat(source_format))
            return result
        except Exception as e:
            raise HTTPException(400, str(e))
    
    @app.get("/api/import/field-suggestions/{import_type}")
    async def get_field_suggestions(import_type: str, headers: str):
        try:
            header_list = headers.split(',')
            suggestions = engine.get_field_suggestions(ImportType(import_type), header_list)
            return suggestions
        except Exception as e:
            raise HTTPException(400, str(e))
    
    @app.post("/api/import/mappings")
    async def save_mappings(request: FieldMappingRequest):
        try:
            engine.save_field_mappings(request.batch_id, request.mappings)
            return {"success": True}
        except Exception as e:
            raise HTTPException(500, str(e))
    
    @app.post("/api/import/validate")
    async def validate_batch(request: ValidateRequest):
        try:
            result = engine.validate_batch(request.batch_id, request.data_rows, 
                                           json.loads(engine.get_batch(request.batch_id)['field_mappings']))
            return result
        except Exception as e:
            raise HTTPException(500, str(e))
    
    @app.post("/api/import/dry-run/{batch_id}")
    async def dry_run(batch_id: str):
        try:
            return engine.dry_run(batch_id)
        except Exception as e:
            raise HTTPException(500, str(e))
    
    @app.post("/api/import/execute/{batch_id}")
    async def execute_import(batch_id: str, skip_invalid: bool = True):
        try:
            return engine.execute_import(batch_id, skip_invalid)
        except Exception as e:
            raise HTTPException(500, str(e))
    
    @app.get("/api/import/audit/{batch_id}")
    async def get_audit_log(batch_id: str):
        return engine.get_audit_log(batch_id)
    
    @app.get("/api/import/batches")
    async def list_batches(import_type: str = None, status: str = None, limit: int = 50):
        return engine.list_batches(
            ImportType(import_type) if import_type else None,
            ImportStatus(status) if status else None,
            limit
        )
    
    @app.get("/api/import/fields/{import_type}")
    async def get_field_definitions(import_type: str):
        return FIELD_DEFINITIONS.get(ImportType(import_type), {})


if __name__ == "__main__":
    # Test the import engine
    engine = ImportEngine("./data/gst_billing.db")
    
    # Test CSV parsing
    sample_csv = """Invoice No,Date,Customer,GSTIN,Item,HSN,Qty,Rate,Tax %,Total
INV001,2024-01-15,ABC Traders,07AABBC1234A1ZK,Laptop,8471,2,50000,18,118000
INV001,2024-01-15,ABC Traders,07AABBC1234A1ZK,Mouse,8471,5,500,18,2950
INV002,2024-01-16,XYZ Corp,07XYZD5678B2ZL,Monitor,8528,1,25000,28,32000"""
    
    result = engine.parse_file("test", sample_csv, SourceFormat.CSV)
    print("Parsed headers:", result['headers'])
    print("Sample data:", result['sample_data'][:2])
    
    suggestions = engine.get_field_suggestions(ImportType.SALES, result['headers'])
    print("\nField suggestions:", json.dumps(suggestions, indent=2))
