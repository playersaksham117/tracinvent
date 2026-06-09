/// Import models for data migration from different sources
/// Supports: Excel (CSV/XLSX), JSON, Tally export, Generic POS export

// ============================================================================
// SALES IMPORT MODEL
// ============================================================================

class SalesImportRow {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String? customerName;
  final String? gstin;
  final String itemName;
  final String? hsn;
  final double quantity;
  final double rate;
  final double taxPercent;
  final double total;
  final String? paymentMode;
  final String? notes;

  SalesImportRow({
    required this.invoiceNumber,
    required this.invoiceDate,
    this.customerName,
    this.gstin,
    required this.itemName,
    this.hsn,
    required this.quantity,
    required this.rate,
    required this.taxPercent,
    required this.total,
    this.paymentMode,
    this.notes,
  });

  factory SalesImportRow.fromMap(Map<String, dynamic> map) {
    return SalesImportRow(
      invoiceNumber: _getString(map, ['invoice_number', 'invoicenumber', 'invoice_no', 'invoiceno', 'inv_no', 'bill_no', 'billno', 'voucher_no', 'voucherno']),
      invoiceDate: _getDate(map, ['invoice_date', 'invoicedate', 'date', 'bill_date', 'billdate', 'voucher_date', 'voucherdate']),
      customerName: _getStringOptional(map, ['customer_name', 'customername', 'customer', 'party_name', 'partyname', 'buyer_name']),
      gstin: _getStringOptional(map, ['gstin', 'gst_no', 'gstno', 'gst_number', 'gstnumber', 'party_gstin']),
      itemName: _getString(map, ['item_name', 'itemname', 'item', 'product_name', 'productname', 'product', 'stock_item', 'stockitem', 'particular']),
      hsn: _getStringOptional(map, ['hsn', 'hsn_code', 'hsncode', 'hsn_sac', 'hsnsac']),
      quantity: _getDouble(map, ['qty', 'quantity', 'qnty', 'units', 'nos']),
      rate: _getDouble(map, ['rate', 'price', 'unit_price', 'unitprice', 'mrp']),
      taxPercent: _getDouble(map, ['tax_percent', 'taxpercent', 'tax_%', 'tax', 'gst_rate', 'gstrate', 'tax_rate', 'taxrate']),
      total: _getDouble(map, ['total', 'amount', 'total_amount', 'totalamount', 'net_amount', 'netamount', 'value']),
      paymentMode: _getStringOptional(map, ['payment_mode', 'paymentmode', 'payment', 'mode', 'pay_mode', 'payment_method']),
      notes: _getStringOptional(map, ['notes', 'remarks', 'description', 'narration']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String(),
      'customer_name': customerName,
      'gstin': gstin,
      'item_name': itemName,
      'hsn': hsn,
      'quantity': quantity,
      'rate': rate,
      'tax_percent': taxPercent,
      'total': total,
      'payment_mode': paymentMode,
      'notes': notes,
    };
  }
}

// ============================================================================
// PURCHASE IMPORT MODEL
// ============================================================================

class PurchaseImportRow {
  final String? supplierName;
  final String invoiceNumber;
  final String? gstin;
  final DateTime date;
  final String itemName;
  final String? hsn;
  final double quantity;
  final double rate;
  final double taxPercent;
  final double total;
  final String? paymentTerms;
  final String? notes;

  PurchaseImportRow({
    this.supplierName,
    required this.invoiceNumber,
    this.gstin,
    required this.date,
    required this.itemName,
    this.hsn,
    required this.quantity,
    required this.rate,
    required this.taxPercent,
    required this.total,
    this.paymentTerms,
    this.notes,
  });

  factory PurchaseImportRow.fromMap(Map<String, dynamic> map) {
    return PurchaseImportRow(
      supplierName: _getStringOptional(map, ['supplier', 'supplier_name', 'suppliername', 'vendor', 'vendor_name', 'party_name', 'partyname']),
      invoiceNumber: _getString(map, ['invoice_number', 'invoicenumber', 'invoice_no', 'invoiceno', 'inv_no', 'bill_no', 'billno', 'voucher_no', 'voucherno', 'supplier_invoice']),
      gstin: _getStringOptional(map, ['gstin', 'gst_no', 'gstno', 'gst_number', 'gstnumber', 'supplier_gstin']),
      date: _getDate(map, ['date', 'invoice_date', 'invoicedate', 'purchase_date', 'purchasedate', 'bill_date', 'billdate']),
      itemName: _getString(map, ['item', 'item_name', 'itemname', 'product_name', 'productname', 'product', 'stock_item', 'stockitem', 'particular']),
      hsn: _getStringOptional(map, ['hsn', 'hsn_code', 'hsncode', 'hsn_sac', 'hsnsac']),
      quantity: _getDouble(map, ['qty', 'quantity', 'qnty', 'units', 'nos']),
      rate: _getDouble(map, ['rate', 'price', 'unit_price', 'unitprice', 'purchase_rate', 'cost']),
      taxPercent: _getDouble(map, ['tax', 'tax_percent', 'taxpercent', 'tax_%', 'gst_rate', 'gstrate', 'tax_rate', 'taxrate']),
      total: _getDouble(map, ['total', 'amount', 'total_amount', 'totalamount', 'net_amount', 'netamount', 'value']),
      paymentTerms: _getStringOptional(map, ['payment_terms', 'paymentterms', 'terms', 'credit_days', 'due_days']),
      notes: _getStringOptional(map, ['notes', 'remarks', 'description', 'narration']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supplier_name': supplierName,
      'invoice_number': invoiceNumber,
      'gstin': gstin,
      'date': date.toIso8601String(),
      'item_name': itemName,
      'hsn': hsn,
      'quantity': quantity,
      'rate': rate,
      'tax_percent': taxPercent,
      'total': total,
      'payment_terms': paymentTerms,
      'notes': notes,
    };
  }
}

// ============================================================================
// STOCK OPENING IMPORT MODEL
// ============================================================================

class StockOpeningImportRow {
  final String sku;
  final String? productName;
  final double quantity;
  final double purchaseRate;
  final String? batch;
  final DateTime? expiryDate;
  final String? barcode;
  final String? hsn;
  final double? taxRate;
  final String? category;

  StockOpeningImportRow({
    required this.sku,
    this.productName,
    required this.quantity,
    required this.purchaseRate,
    this.batch,
    this.expiryDate,
    this.barcode,
    this.hsn,
    this.taxRate,
    this.category,
  });

  factory StockOpeningImportRow.fromMap(Map<String, dynamic> map) {
    return StockOpeningImportRow(
      sku: _getString(map, ['sku', 'item_code', 'itemcode', 'product_code', 'productcode', 'code', 'part_number', 'partnumber', 'stock_code']),
      productName: _getStringOptional(map, ['product_name', 'productname', 'name', 'item_name', 'itemname', 'item', 'description']),
      quantity: _getDouble(map, ['quantity', 'qty', 'qnty', 'opening_qty', 'openingqty', 'stock', 'stock_qty', 'opening_stock']),
      purchaseRate: _getDouble(map, ['purchase_rate', 'purchaserate', 'cost', 'cost_price', 'costprice', 'rate', 'unit_cost', 'buying_price']),
      batch: _getStringOptional(map, ['batch', 'batch_no', 'batchno', 'batch_number', 'batchnumber', 'lot', 'lot_no']),
      expiryDate: _getDateOptional(map, ['expiry', 'expiry_date', 'expirydate', 'exp_date', 'expdate', 'best_before']),
      barcode: _getStringOptional(map, ['barcode', 'bar_code', 'ean', 'upc']),
      hsn: _getStringOptional(map, ['hsn', 'hsn_code', 'hsncode', 'hsn_sac', 'hsnsac']),
      taxRate: _getDoubleOptional(map, ['tax_rate', 'taxrate', 'tax', 'gst_rate', 'gst']),
      category: _getStringOptional(map, ['category', 'group', 'product_group', 'item_group']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'product_name': productName,
      'quantity': quantity,
      'purchase_rate': purchaseRate,
      'batch': batch,
      'expiry_date': expiryDate?.toIso8601String(),
      'barcode': barcode,
      'hsn': hsn,
      'tax_rate': taxRate,
      'category': category,
    };
  }
}

// ============================================================================
// LEDGER OPENING BALANCE IMPORT MODEL
// ============================================================================

class LedgerOpeningImportRow {
  final String name;
  final String ledgerType; // 'debtor' or 'creditor'
  final double openingBalance;
  final String? gstin;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? panNumber;
  final String? bankName;
  final String? bankAccount;
  final String? ifscCode;

  LedgerOpeningImportRow({
    required this.name,
    required this.ledgerType,
    required this.openingBalance,
    this.gstin,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.panNumber,
    this.bankName,
    this.bankAccount,
    this.ifscCode,
  });

  factory LedgerOpeningImportRow.fromMap(Map<String, dynamic> map, String type) {
    return LedgerOpeningImportRow(
      name: _getString(map, ['name', 'party_name', 'partyname', 'ledger_name', 'ledgername', 'customer_name', 'supplier_name']),
      ledgerType: type,
      openingBalance: _getDouble(map, ['opening_balance', 'openingbalance', 'balance', 'opening', 'due_amount', 'outstanding', 'amount']),
      gstin: _getStringOptional(map, ['gstin', 'gst_no', 'gstno', 'gst_number', 'gstnumber']),
      phone: _getStringOptional(map, ['phone', 'mobile', 'contact', 'phone_no', 'phoneno', 'mobile_no', 'mobileno']),
      email: _getStringOptional(map, ['email', 'email_id', 'emailid', 'mail']),
      address: _getStringOptional(map, ['address', 'billing_address', 'billingaddress', 'addr']),
      city: _getStringOptional(map, ['city', 'town']),
      state: _getStringOptional(map, ['state', 'region', 'province']),
      postalCode: _getStringOptional(map, ['postal_code', 'postalcode', 'pin', 'pincode', 'pin_code', 'zip', 'zipcode']),
      panNumber: _getStringOptional(map, ['pan', 'pan_no', 'panno', 'pan_number', 'pannumber']),
      bankName: _getStringOptional(map, ['bank_name', 'bankname', 'bank']),
      bankAccount: _getStringOptional(map, ['bank_account', 'bankaccount', 'account_no', 'accountno', 'account_number']),
      ifscCode: _getStringOptional(map, ['ifsc', 'ifsc_code', 'ifsccode']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ledger_type': ledgerType,
      'opening_balance': openingBalance,
      'gstin': gstin,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'pan_number': panNumber,
      'bank_name': bankName,
      'bank_account': bankAccount,
      'ifsc_code': ifscCode,
    };
  }
}

// ============================================================================
// IMPORT RESULT MODEL
// ============================================================================

class ImportResult {
  final int totalRows;
  final int successCount;
  final int errorCount;
  final List<ImportError> errors;
  final String importType;
  final DateTime importedAt;

  ImportResult({
    required this.totalRows,
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.importType,
    DateTime? importedAt,
  }) : importedAt = importedAt ?? DateTime.now();

  bool get hasErrors => errorCount > 0;
  double get successRate => totalRows > 0 ? (successCount / totalRows) * 100 : 0;
}

class ImportError {
  final int rowNumber;
  final String field;
  final String message;
  final String? originalValue;

  ImportError({
    required this.rowNumber,
    required this.field,
    required this.message,
    this.originalValue,
  });

  @override
  String toString() => 'Row $rowNumber: $field - $message';
}

// ============================================================================
// EXPORT FORMAT ENUM
// ============================================================================

enum ExportFormat {
  csv,
  json,
  tally,
  excel,
}

enum ImportSourceFormat {
  csv,
  xlsx,
  json,
  tally,
  genericPos,
}

// ============================================================================
// HELPER FUNCTIONS FOR FIELD MAPPING
// ============================================================================

String _getString(Map<String, dynamic> map, List<String> possibleKeys) {
  for (final key in possibleKeys) {
    final lowerMap = map.map((k, v) => MapEntry(k.toLowerCase().replaceAll(' ', '_'), v));
    if (lowerMap.containsKey(key) && lowerMap[key] != null) {
      return lowerMap[key].toString().trim();
    }
  }
  throw FormatException('Required field not found. Tried: ${possibleKeys.join(", ")}');
}

String? _getStringOptional(Map<String, dynamic> map, List<String> possibleKeys) {
  try {
    final value = _getString(map, possibleKeys);
    return value.isEmpty ? null : value;
  } catch (_) {
    return null;
  }
}

double _getDouble(Map<String, dynamic> map, List<String> possibleKeys) {
  for (final key in possibleKeys) {
    final lowerMap = map.map((k, v) => MapEntry(k.toLowerCase().replaceAll(' ', '_'), v));
    if (lowerMap.containsKey(key) && lowerMap[key] != null) {
      final value = lowerMap[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        // Remove currency symbols, commas, and spaces
        final cleaned = value.replaceAll(RegExp(r'[₹$,\s]'), '').trim();
        if (cleaned.isEmpty) return 0;
        return double.tryParse(cleaned) ?? 0;
      }
    }
  }
  return 0;
}

double? _getDoubleOptional(Map<String, dynamic> map, List<String> possibleKeys) {
  final value = _getDouble(map, possibleKeys);
  return value == 0 ? null : value;
}

DateTime _getDate(Map<String, dynamic> map, List<String> possibleKeys) {
  for (final key in possibleKeys) {
    final lowerMap = map.map((k, v) => MapEntry(k.toLowerCase().replaceAll(' ', '_'), v));
    if (lowerMap.containsKey(key) && lowerMap[key] != null) {
      return _parseDate(lowerMap[key]);
    }
  }
  return DateTime.now();
}

DateTime? _getDateOptional(Map<String, dynamic> map, List<String> possibleKeys) {
  try {
    for (final key in possibleKeys) {
      final lowerMap = map.map((k, v) => MapEntry(k.toLowerCase().replaceAll(' ', '_'), v));
      if (lowerMap.containsKey(key) && lowerMap[key] != null) {
        final value = lowerMap[key];
        if (value is String && value.trim().isEmpty) return null;
        return _parseDate(value);
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is num) {
    // Excel serial date number
    final baseDate = DateTime(1899, 12, 30);
    return baseDate.add(Duration(days: value.toInt()));
  }
  if (value is String) {
    final str = value.trim();
    
    // Try ISO format first
    try {
      return DateTime.parse(str);
    } catch (_) {}
    
    // Common date formats
    final formats = [
      // DD-MM-YYYY
      RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$'),
      // YYYY-MM-DD
      RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$'),
      // DD-MMM-YYYY (e.g., 01-Jan-2024)
      RegExp(r'^(\d{1,2})[-/]([A-Za-z]{3})[-/](\d{4})$'),
      // MM/DD/YYYY
      RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$'),
    ];
    
    // DD-MM-YYYY or DD/MM/YYYY
    var match = formats[0].firstMatch(str);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      return DateTime(year, month, day);
    }
    
    // YYYY-MM-DD
    match = formats[1].firstMatch(str);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      return DateTime(year, month, day);
    }
    
    // DD-MMM-YYYY
    match = formats[2].firstMatch(str);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final monthStr = match.group(2)!.toLowerCase();
      final year = int.parse(match.group(3)!);
      final months = {'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 
                      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12};
      final month = months[monthStr] ?? 1;
      return DateTime(year, month, day);
    }
    
    throw FormatException('Unable to parse date: $str');
  }
  throw FormatException('Invalid date value: $value');
}

// ============================================================================
// TALLY SPECIFIC MODELS
// ============================================================================

class TallyVoucherImport {
  final String voucherType; // Sales, Purchase, Receipt, Payment
  final String voucherNumber;
  final DateTime date;
  final String? partyName;
  final List<TallyLedgerEntry> ledgerEntries;
  final List<TallyInventoryEntry> inventoryEntries;
  final String? narration;

  TallyVoucherImport({
    required this.voucherType,
    required this.voucherNumber,
    required this.date,
    this.partyName,
    required this.ledgerEntries,
    required this.inventoryEntries,
    this.narration,
  });
}

class TallyLedgerEntry {
  final String ledgerName;
  final double amount;
  final bool isDebit;

  TallyLedgerEntry({
    required this.ledgerName,
    required this.amount,
    required this.isDebit,
  });
}

class TallyInventoryEntry {
  final String stockItemName;
  final double quantity;
  final String? unit;
  final double rate;
  final double amount;
  final String? batchName;
  final String? godownName;

  TallyInventoryEntry({
    required this.stockItemName,
    required this.quantity,
    this.unit,
    required this.rate,
    required this.amount,
    this.batchName,
    this.godownName,
  });
}
