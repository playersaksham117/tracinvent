/// Import Models for POS Data Import Engine
/// Supports: Sales, Purchases, Opening Stock, Ledger Opening Balances
library;

import 'package:flutter/material.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum ImportType {
  sales('sales', 'Sales Data', Icons.point_of_sale),
  purchase('purchase', 'Purchase Data', Icons.shopping_cart),
  openingStock('opening_stock', 'Opening Stock', Icons.inventory_2),
  ledgerOpening('ledger_opening', 'Ledger Opening Balances', Icons.account_balance_wallet);

  final String value;
  final String label;
  final IconData icon;

  const ImportType(this.value, this.label, this.icon);

  static ImportType fromString(String value) {
    return ImportType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ImportType.sales,
    );
  }
}

enum ImportStatus {
  pending('pending', 'Pending', Colors.grey),
  validating('validating', 'Validating', Colors.blue),
  validated('validated', 'Validated', Colors.teal),
  dryRun('dry_run', 'Dry Run', Colors.purple),
  importing('importing', 'Importing', Colors.orange),
  completed('completed', 'Completed', Colors.green),
  failed('failed', 'Failed', Colors.red),
  partial('partial', 'Partial', Colors.amber);

  final String value;
  final String label;
  final Color color;

  const ImportStatus(this.value, this.label, this.color);

  static ImportStatus fromString(String value) {
    return ImportStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ImportStatus.pending,
    );
  }
}

enum SourceFormat {
  csv('csv', 'CSV File', Icons.description, '.csv'),
  xlsx('xlsx', 'Excel File', Icons.table_chart, '.xlsx'),
  json('json', 'JSON File', Icons.code, '.json'),
  tallyXml('tally_xml', 'Tally Export', Icons.import_export, '.xml'),
  genericPos('generic_pos', 'Generic POS', Icons.point_of_sale, '.csv');

  final String value;
  final String label;
  final IconData icon;
  final String extension;

  const SourceFormat(this.value, this.label, this.icon, this.extension);

  static SourceFormat fromString(String value) {
    return SourceFormat.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SourceFormat.csv,
    );
  }
}

enum ValidationSeverity {
  error('error', Colors.red, Icons.error),
  warning('warning', Colors.orange, Icons.warning),
  info('info', Colors.blue, Icons.info);

  final String value;
  final Color color;
  final IconData icon;

  const ValidationSeverity(this.value, this.color, this.icon);

  static ValidationSeverity fromString(String value) {
    return ValidationSeverity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ValidationSeverity.info,
    );
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

class ValidationIssue {
  final int row;
  final String field;
  final String message;
  final ValidationSeverity severity;
  final dynamic value;
  final String? suggestion;

  ValidationIssue({
    required this.row,
    required this.field,
    required this.message,
    required this.severity,
    this.value,
    this.suggestion,
  });

  factory ValidationIssue.fromJson(Map<String, dynamic> json) {
    return ValidationIssue(
      row: json['row'] ?? 0,
      field: json['field'] ?? '',
      message: json['message'] ?? '',
      severity: ValidationSeverity.fromString(json['severity'] ?? 'info'),
      value: json['value'],
      suggestion: json['suggestion'],
    );
  }

  Map<String, dynamic> toJson() => {
    'row': row,
    'field': field,
    'message': message,
    'severity': severity.value,
    'value': value,
    'suggestion': suggestion,
  };
}

class FieldMapping {
  String? sourceField;
  final String targetField;
  String? transform;
  dynamic defaultValue;
  final bool required;
  final String label;
  final String type;
  final List<String>? options;

  FieldMapping({
    this.sourceField,
    required this.targetField,
    this.transform,
    this.defaultValue,
    this.required = false,
    required this.label,
    required this.type,
    this.options,
  });

  factory FieldMapping.fromJson(Map<String, dynamic> json) {
    return FieldMapping(
      sourceField: json['source_field'] ?? json['suggested_source'],
      targetField: json['target_field'] ?? '',
      transform: json['transform'],
      defaultValue: json['default_value'] ?? json['default'],
      required: json['required'] ?? false,
      label: json['label'] ?? json['target_field'] ?? '',
      type: json['type'] ?? 'string',
      options: json['options'] != null ? List<String>.from(json['options']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'source_field': sourceField,
    'target_field': targetField,
    'transform': transform,
    'default_value': defaultValue,
    'required': required,
  };
}

class ImportBatch {
  final String batchId;
  final ImportType importType;
  final SourceFormat sourceFormat;
  final String filename;
  final DateTime createdAt;
  final DateTime? completedAt;
  final ImportStatus status;
  final int totalRecords;
  final int validRecords;
  final int importedRecords;
  final int failedRecords;
  final String? financialYear;
  final String? errorMessage;

  ImportBatch({
    required this.batchId,
    required this.importType,
    required this.sourceFormat,
    required this.filename,
    required this.createdAt,
    this.completedAt,
    required this.status,
    this.totalRecords = 0,
    this.validRecords = 0,
    this.importedRecords = 0,
    this.failedRecords = 0,
    this.financialYear,
    this.errorMessage,
  });

  factory ImportBatch.fromJson(Map<String, dynamic> json) {
    return ImportBatch(
      batchId: json['batch_id'] ?? '',
      importType: ImportType.fromString(json['import_type'] ?? 'sales'),
      sourceFormat: SourceFormat.fromString(json['source_format'] ?? 'csv'),
      filename: json['filename'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      status: ImportStatus.fromString(json['status'] ?? 'pending'),
      totalRecords: json['total_records'] ?? 0,
      validRecords: json['valid_records'] ?? 0,
      importedRecords: json['imported_records'] ?? 0,
      failedRecords: json['failed_records'] ?? 0,
      financialYear: json['financial_year'],
      errorMessage: json['error_message'],
    );
  }

  double get progress {
    if (totalRecords == 0) return 0;
    return importedRecords / totalRecords;
  }

  int get invalidRecords => totalRecords - validRecords;
}

class ParseResult {
  final List<String> headers;
  final List<Map<String, dynamic>> sampleData;
  final int totalRows;
  final String? delimiter;

  ParseResult({
    required this.headers,
    required this.sampleData,
    required this.totalRows,
    this.delimiter,
  });

  factory ParseResult.fromJson(Map<String, dynamic> json) {
    return ParseResult(
      headers: List<String>.from(json['headers'] ?? []),
      sampleData: List<Map<String, dynamic>>.from(
        (json['sample_data'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
      totalRows: json['total_rows'] ?? 0,
      delimiter: json['delimiter'],
    );
  }
}

class ValidationResult {
  final int totalRecords;
  final int validRecords;
  final int invalidRecords;
  final Map<String, int> issuesSummary;
  final List<ValidationIssue> issues;

  ValidationResult({
    required this.totalRecords,
    required this.validRecords,
    required this.invalidRecords,
    required this.issuesSummary,
    required this.issues,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      totalRecords: json['total_records'] ?? 0,
      validRecords: json['valid_records'] ?? 0,
      invalidRecords: json['invalid_records'] ?? 0,
      issuesSummary: Map<String, int>.from(json['issues_summary'] ?? {}),
      issues: (json['issues'] as List? ?? [])
          .map((e) => ValidationIssue.fromJson(e))
          .toList(),
    );
  }

  bool get hasErrors => (issuesSummary['errors'] ?? 0) > 0;
  bool get hasWarnings => (issuesSummary['warnings'] ?? 0) > 0;
}

class DryRunPreview {
  final List<VoucherPreview> vouchersToCreate;
  final Map<String, dynamic> summary;

  DryRunPreview({
    required this.vouchersToCreate,
    required this.summary,
  });

  factory DryRunPreview.fromJson(Map<String, dynamic> json) {
    return DryRunPreview(
      vouchersToCreate: (json['vouchers_to_create'] as List? ?? [])
          .map((e) => VoucherPreview.fromJson(e))
          .toList(),
      summary: Map<String, dynamic>.from(json['summary'] ?? {}),
    );
  }

  int get totalVouchers => summary['total_vouchers'] ?? 0;
  double get totalAmount => (summary['total_amount'] ?? 0).toDouble();
  List<String> get partiesAffected => 
      List<String>.from(summary['parties_affected'] ?? []);
}

class VoucherPreview {
  final String voucherType;
  final String? voucherNumber;
  final String? date;
  final String? partyName;
  final String? gstin;
  final List<Map<String, dynamic>>? items;
  final double total;
  final String? paymentMode;

  VoucherPreview({
    required this.voucherType,
    this.voucherNumber,
    this.date,
    this.partyName,
    this.gstin,
    this.items,
    this.total = 0,
    this.paymentMode,
  });

  factory VoucherPreview.fromJson(Map<String, dynamic> json) {
    return VoucherPreview(
      voucherType: json['voucher_type'] ?? '',
      voucherNumber: json['voucher_number'],
      date: json['date'],
      partyName: json['party_name'],
      gstin: json['gstin'],
      items: json['items'] != null 
          ? List<Map<String, dynamic>>.from(json['items']) 
          : null,
      total: (json['total'] ?? 0).toDouble(),
      paymentMode: json['payment_mode'],
    );
  }
}

class ImportResult {
  final int imported;
  final int failed;
  final List<Map<String, dynamic>> results;

  ImportResult({
    required this.imported,
    required this.failed,
    required this.results,
  });

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    return ImportResult(
      imported: json['imported'] ?? 0,
      failed: json['failed'] ?? 0,
      results: List<Map<String, dynamic>>.from(json['results'] ?? []),
    );
  }

  bool get isSuccess => failed == 0;
  bool get isPartial => imported > 0 && failed > 0;
}

class AuditLogEntry {
  final String action;
  final String details;
  final DateTime timestamp;
  final String? userId;

  AuditLogEntry({
    required this.action,
    required this.details,
    required this.timestamp,
    this.userId,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      userId: json['user_id'],
    );
  }
}

// ============================================================================
// FIELD DEFINITIONS
// ============================================================================

class ImportFieldDefinitions {
  static Map<String, Map<String, dynamic>> getSalesFields() => {
    'invoice_number': {'type': 'string', 'required': true, 'label': 'Invoice Number'},
    'invoice_date': {'type': 'date', 'required': true, 'label': 'Invoice Date'},
    'customer_name': {'type': 'string', 'required': true, 'label': 'Customer Name'},
    'customer_gstin': {'type': 'gstin', 'required': false, 'label': 'Customer GSTIN'},
    'customer_phone': {'type': 'phone', 'required': false, 'label': 'Phone'},
    'item_name': {'type': 'string', 'required': true, 'label': 'Item Name'},
    'hsn_code': {'type': 'hsn', 'required': false, 'label': 'HSN Code'},
    'quantity': {'type': 'number', 'required': true, 'label': 'Quantity'},
    'unit': {'type': 'string', 'required': false, 'label': 'Unit', 'default': 'PCS'},
    'rate': {'type': 'decimal', 'required': true, 'label': 'Rate'},
    'discount_percent': {'type': 'decimal', 'required': false, 'label': 'Discount %'},
    'tax_percent': {'type': 'decimal', 'required': true, 'label': 'Tax %'},
    'total': {'type': 'decimal', 'required': false, 'label': 'Total'},
    'payment_mode': {
      'type': 'enum', 
      'required': false, 
      'label': 'Payment Mode',
      'options': ['cash', 'credit', 'upi', 'card', 'bank'],
      'default': 'cash'
    },
  };

  static Map<String, Map<String, dynamic>> getPurchaseFields() => {
    'invoice_number': {'type': 'string', 'required': true, 'label': 'Supplier Invoice No'},
    'invoice_date': {'type': 'date', 'required': true, 'label': 'Invoice Date'},
    'supplier_name': {'type': 'string', 'required': true, 'label': 'Supplier Name'},
    'supplier_gstin': {'type': 'gstin', 'required': false, 'label': 'Supplier GSTIN'},
    'item_name': {'type': 'string', 'required': true, 'label': 'Item Name'},
    'hsn_code': {'type': 'hsn', 'required': false, 'label': 'HSN Code'},
    'quantity': {'type': 'number', 'required': true, 'label': 'Quantity'},
    'unit': {'type': 'string', 'required': false, 'label': 'Unit', 'default': 'PCS'},
    'rate': {'type': 'decimal', 'required': true, 'label': 'Rate'},
    'tax_percent': {'type': 'decimal', 'required': true, 'label': 'Tax %'},
    'total': {'type': 'decimal', 'required': false, 'label': 'Total'},
    'payment_terms': {'type': 'string', 'required': false, 'label': 'Payment Terms'},
    'due_date': {'type': 'date', 'required': false, 'label': 'Due Date'},
  };

  static Map<String, Map<String, dynamic>> getOpeningStockFields() => {
    'sku': {'type': 'string', 'required': true, 'label': 'SKU / Item Code'},
    'item_name': {'type': 'string', 'required': true, 'label': 'Item Name'},
    'hsn_code': {'type': 'hsn', 'required': false, 'label': 'HSN Code'},
    'quantity': {'type': 'number', 'required': true, 'label': 'Quantity'},
    'unit': {'type': 'string', 'required': false, 'label': 'Unit', 'default': 'PCS'},
    'purchase_rate': {'type': 'decimal', 'required': true, 'label': 'Purchase Rate'},
    'mrp': {'type': 'decimal', 'required': false, 'label': 'MRP'},
    'batch_number': {'type': 'string', 'required': false, 'label': 'Batch Number'},
    'expiry_date': {'type': 'date', 'required': false, 'label': 'Expiry Date'},
    'location': {'type': 'string', 'required': false, 'label': 'Warehouse/Location'},
  };

  static Map<String, Map<String, dynamic>> getLedgerOpeningFields() => {
    'ledger_type': {
      'type': 'enum', 
      'required': true, 
      'label': 'Ledger Type',
      'options': ['debtor', 'creditor']
    },
    'party_name': {'type': 'string', 'required': true, 'label': 'Party Name'},
    'gstin': {'type': 'gstin', 'required': false, 'label': 'GSTIN'},
    'phone': {'type': 'phone', 'required': false, 'label': 'Phone'},
    'opening_balance': {'type': 'decimal', 'required': true, 'label': 'Opening Balance'},
    'balance_type': {
      'type': 'enum', 
      'required': true, 
      'label': 'Dr/Cr',
      'options': ['debit', 'credit']
    },
    'as_on_date': {'type': 'date', 'required': true, 'label': 'As On Date'},
    'credit_limit': {'type': 'decimal', 'required': false, 'label': 'Credit Limit'},
    'credit_days': {'type': 'number', 'required': false, 'label': 'Credit Days', 'default': 30},
  };

  static Map<String, Map<String, dynamic>> getFieldsForType(ImportType type) {
    switch (type) {
      case ImportType.sales:
        return getSalesFields();
      case ImportType.purchase:
        return getPurchaseFields();
      case ImportType.openingStock:
        return getOpeningStockFields();
      case ImportType.ledgerOpening:
        return getLedgerOpeningFields();
    }
  }
}
