/// Import Service - API integration for POS Data Import Engine
library;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/import_models.dart';

class ImportService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // -------------------------------------------------------------------------
  // BATCH MANAGEMENT
  // -------------------------------------------------------------------------

  /// Create a new import batch
  static Future<String> createBatch({
    required ImportType importType,
    required SourceFormat sourceFormat,
    required String filename,
    required String financialYear,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/import/batch/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'import_type': importType.value,
        'source_format': sourceFormat.value,
        'filename': filename,
        'financial_year': financialYear,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['batch_id'];
    }
    throw Exception('Failed to create batch: ${response.body}');
  }

  /// Get batch details
  static Future<ImportBatch> getBatch(String batchId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/import/batch/$batchId'),
    );

    if (response.statusCode == 200) {
      return ImportBatch.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get batch: ${response.body}');
  }

  /// List all import batches
  static Future<List<ImportBatch>> listBatches({
    ImportType? importType,
    ImportStatus? status,
    int limit = 50,
  }) async {
    final params = <String, String>{};
    if (importType != null) params['import_type'] = importType.value;
    if (status != null) params['status'] = status.value;
    params['limit'] = limit.toString();

    final uri = Uri.parse('$baseUrl/api/import/batches')
        .replace(queryParameters: params);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ImportBatch.fromJson(e)).toList();
    }
    throw Exception('Failed to list batches: ${response.body}');
  }

  // -------------------------------------------------------------------------
  // FILE PARSING
  // -------------------------------------------------------------------------

  /// Parse uploaded file content
  static Future<ParseResult> parseFile({
    required String batchId,
    required String content,
    required SourceFormat sourceFormat,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/import/parse'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'batch_id': batchId,
        'content': content,
        'source_format': sourceFormat.value,
      }),
    );

    if (response.statusCode == 200) {
      return ParseResult.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to parse file: ${response.body}');
  }

  /// Parse file locally (for CSV without backend)
  static ParseResult parseCSVLocally(String content) {
    final lines = content.trim().split('\n');
    if (lines.isEmpty) {
      throw Exception('Empty file');
    }

    // Detect delimiter
    String delimiter = ',';
    if (lines[0].contains('\t')) {
      delimiter = '\t';
    } else if (lines[0].contains(';')) {
      delimiter = ';';
    }

    // Parse headers
    final headers = _parseCSVLine(lines[0], delimiter);

    // Parse data rows
    final sampleData = <Map<String, dynamic>>[];
    for (int i = 1; i < lines.length && i <= 10; i++) {
      final values = _parseCSVLine(lines[i], delimiter);
      final row = <String, dynamic>{};
      for (int j = 0; j < headers.length && j < values.length; j++) {
        row[headers[j]] = values[j];
      }
      sampleData.add(row);
    }

    return ParseResult(
      headers: headers,
      sampleData: sampleData,
      totalRows: lines.length - 1,
      delimiter: delimiter,
    );
  }

  static List<String> _parseCSVLine(String line, String delimiter) {
    final result = <String>[];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == delimiter && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());

    return result;
  }

  // -------------------------------------------------------------------------
  // FIELD MAPPING
  // -------------------------------------------------------------------------

  /// Get field mapping suggestions
  static Future<Map<String, FieldMapping>> getFieldSuggestions({
    required ImportType importType,
    required List<String> headers,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/import/field-suggestions/${importType.value}')
          .replace(queryParameters: {'headers': headers.join(',')}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data.map((key, value) => MapEntry(
        key,
        FieldMapping.fromJson({...value, 'target_field': key}),
      ));
    }
    throw Exception('Failed to get suggestions: ${response.body}');
  }

  /// Get field suggestions locally (without backend)
  static Map<String, FieldMapping> getFieldSuggestionsLocally({
    required ImportType importType,
    required List<String> headers,
  }) {
    final fieldDefs = ImportFieldDefinitions.getFieldsForType(importType);
    final suggestions = <String, FieldMapping>{};

    // Header aliases for matching
    const headerAliases = {
      'invoice_number': ['inv no', 'invoice no', 'bill no', 'voucher no', 'inv_no', 'billno'],
      'invoice_date': ['date', 'inv date', 'bill date', 'voucher date', 'trans date'],
      'customer_name': ['customer', 'party', 'buyer', 'client', 'cust name', 'party name'],
      'supplier_name': ['supplier', 'vendor', 'party', 'seller', 'supp name'],
      'customer_gstin': ['gstin', 'gst no', 'gst', 'tin', 'customer gst'],
      'supplier_gstin': ['gstin', 'gst no', 'gst', 'tin', 'supplier gst'],
      'item_name': ['item', 'product', 'description', 'particulars', 'item name', 'product name'],
      'hsn_code': ['hsn', 'hsn code', 'sac', 'sac code', 'hsn/sac'],
      'quantity': ['qty', 'quantity', 'units', 'nos', 'pcs'],
      'rate': ['rate', 'price', 'unit price', 'mrp', 'unit rate'],
      'tax_percent': ['tax %', 'gst %', 'tax rate', 'gst rate', 'tax'],
      'total': ['total', 'amount', 'net amount', 'gross', 'value'],
      'payment_mode': ['payment', 'mode', 'pay mode', 'payment type'],
      'sku': ['sku', 'item code', 'product code', 'barcode', 'code'],
      'purchase_rate': ['cost', 'purchase price', 'buy rate', 'cost price'],
      'opening_balance': ['balance', 'opening', 'op bal', 'amount'],
      'party_name': ['name', 'party', 'customer', 'supplier', 'account'],
    };

    for (final entry in fieldDefs.entries) {
      final targetField = entry.key;
      final fieldDef = entry.value;

      String? bestMatch;
      int bestScore = 0;

      for (final sourceHeader in headers) {
        final normalizedSource = sourceHeader.toLowerCase().trim();

        // Exact match
        if (normalizedSource == targetField) {
          bestMatch = sourceHeader;
          bestScore = 100;
          break;
        }

        // Check aliases
        if (headerAliases.containsKey(targetField)) {
          for (final alias in headerAliases[targetField]!) {
            if (normalizedSource.contains(alias) || alias.contains(normalizedSource)) {
              if (bestScore < 80) {
                bestMatch = sourceHeader;
                bestScore = 80;
              }
            }
          }
        }

        // Partial match
        if (targetField.replaceAll('_', ' ').contains(normalizedSource) ||
            normalizedSource.contains(targetField.replaceAll('_', ''))) {
          if (bestScore < 60) {
            bestMatch = sourceHeader;
            bestScore = 60;
          }
        }
      }

      suggestions[targetField] = FieldMapping(
        sourceField: bestMatch,
        targetField: targetField,
        required: fieldDef['required'] ?? false,
        label: fieldDef['label'] ?? targetField,
        type: fieldDef['type'] ?? 'string',
        defaultValue: fieldDef['default'],
        options: fieldDef['options'] != null 
            ? List<String>.from(fieldDef['options']) 
            : null,
      );
    }

    return suggestions;
  }

  /// Save field mappings
  static Future<void> saveFieldMappings({
    required String batchId,
    required List<FieldMapping> mappings,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/import/mappings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'batch_id': batchId,
        'mappings': mappings.map((m) => m.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save mappings: ${response.body}');
    }
  }

  // -------------------------------------------------------------------------
  // VALIDATION
  // -------------------------------------------------------------------------

  /// Validate batch data
  static Future<ValidationResult> validateBatch({
    required String batchId,
    required List<Map<String, dynamic>> dataRows,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/import/validate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'batch_id': batchId,
        'data_rows': dataRows,
      }),
    );

    if (response.statusCode == 200) {
      return ValidationResult.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to validate: ${response.body}');
  }

  /// Validate data locally
  static ValidationResult validateDataLocally({
    required List<Map<String, dynamic>> dataRows,
    required List<FieldMapping> mappings,
    required ImportType importType,
  }) {
    final issues = <ValidationIssue>[];
    int validCount = 0;

    for (int rowNum = 0; rowNum < dataRows.length; rowNum++) {
      final row = dataRows[rowNum];
      final rowIssues = <ValidationIssue>[];

      for (final mapping in mappings) {
        final value = mapping.sourceField != null 
            ? row[mapping.sourceField] 
            : mapping.defaultValue;

        // Check required
        if (mapping.required && (value == null || value.toString().isEmpty)) {
          rowIssues.add(ValidationIssue(
            row: rowNum + 1,
            field: mapping.targetField,
            message: '${mapping.label} is required',
            severity: ValidationSeverity.error,
          ));
          continue;
        }

        if (value == null || value.toString().isEmpty) continue;

        // Type validation
        final strValue = value.toString();
        
        if (mapping.type == 'date') {
          if (!_isValidDate(strValue)) {
            rowIssues.add(ValidationIssue(
              row: rowNum + 1,
              field: mapping.targetField,
              message: 'Invalid date format for ${mapping.label}',
              severity: ValidationSeverity.error,
              value: value,
              suggestion: 'Use YYYY-MM-DD format',
            ));
          }
        } else if (mapping.type == 'number' || mapping.type == 'decimal') {
          if (double.tryParse(strValue.replaceAll(',', '')) == null) {
            rowIssues.add(ValidationIssue(
              row: rowNum + 1,
              field: mapping.targetField,
              message: 'Invalid number for ${mapping.label}',
              severity: ValidationSeverity.error,
              value: value,
            ));
          }
        } else if (mapping.type == 'gstin') {
          if (!_isValidGSTIN(strValue)) {
            rowIssues.add(ValidationIssue(
              row: rowNum + 1,
              field: mapping.targetField,
              message: 'Invalid GSTIN format',
              severity: ValidationSeverity.warning,
              value: value,
              suggestion: 'GSTIN should be 15 characters',
            ));
          }
        } else if (mapping.type == 'enum' && mapping.options != null) {
          if (!mapping.options!.any((o) => 
              o.toLowerCase() == strValue.toLowerCase())) {
            rowIssues.add(ValidationIssue(
              row: rowNum + 1,
              field: mapping.targetField,
              message: 'Invalid value for ${mapping.label}',
              severity: ValidationSeverity.error,
              value: value,
              suggestion: 'Valid options: ${mapping.options!.join(", ")}',
            ));
          }
        }
      }

      issues.addAll(rowIssues);
      if (!rowIssues.any((i) => i.severity == ValidationSeverity.error)) {
        validCount++;
      }
    }

    final errorCount = issues.where((i) => 
        i.severity == ValidationSeverity.error).length;
    final warningCount = issues.where((i) => 
        i.severity == ValidationSeverity.warning).length;

    return ValidationResult(
      totalRecords: dataRows.length,
      validRecords: validCount,
      invalidRecords: dataRows.length - validCount,
      issuesSummary: {'errors': errorCount, 'warnings': warningCount},
      issues: issues,
    );
  }

  static bool _isValidDate(String value) {
    // Try common date formats
    final formats = [
      RegExp(r'^\d{4}-\d{2}-\d{2}$'),  // YYYY-MM-DD
      RegExp(r'^\d{2}/\d{2}/\d{4}$'),  // DD/MM/YYYY
      RegExp(r'^\d{2}-\d{2}-\d{4}$'),  // DD-MM-YYYY
    ];
    return formats.any((f) => f.hasMatch(value));
  }

  static bool _isValidGSTIN(String value) {
    if (value.isEmpty) return true;
    final pattern = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    return pattern.hasMatch(value.toUpperCase());
  }

  // -------------------------------------------------------------------------
  // DRY RUN
  // -------------------------------------------------------------------------

  /// Perform dry run preview
  static Future<DryRunPreview> dryRun(String batchId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/import/dry-run/$batchId'),
    );

    if (response.statusCode == 200) {
      return DryRunPreview.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to dry run: ${response.body}');
  }

  /// Generate dry run preview locally
  static DryRunPreview generateDryRunLocally({
    required List<Map<String, dynamic>> dataRows,
    required List<FieldMapping> mappings,
    required ImportType importType,
  }) {
    final vouchers = <VoucherPreview>[];
    double totalAmount = 0;
    final parties = <String>{};

    // Group by invoice for sales/purchase
    if (importType == ImportType.sales || importType == ImportType.purchase) {
      final grouped = <String, List<Map<String, dynamic>>>{};
      
      for (final row in dataRows) {
        final invoiceNo = _getMappedValue(row, mappings, 'invoice_number') ?? '';
        final partyName = importType == ImportType.sales
            ? _getMappedValue(row, mappings, 'customer_name')
            : _getMappedValue(row, mappings, 'supplier_name');
        final key = '$invoiceNo|$partyName';
        
        grouped.putIfAbsent(key, () => []).add(row);
      }

      for (final entry in grouped.entries) {
        final records = entry.value;
        final first = records.first;
        double voucherTotal = 0;
        final items = <Map<String, dynamic>>[];

        for (final record in records) {
          final qty = double.tryParse(
              _getMappedValue(record, mappings, 'quantity')?.replaceAll(',', '') ?? '0') ?? 0;
          final rate = double.tryParse(
              _getMappedValue(record, mappings, 'rate')?.replaceAll(',', '') ?? '0') ?? 0;
          final tax = double.tryParse(
              _getMappedValue(record, mappings, 'tax_percent')?.replaceAll(',', '') ?? '0') ?? 0;
          final itemTotal = qty * rate * (1 + tax / 100);
          voucherTotal += itemTotal;

          items.add({
            'item_name': _getMappedValue(record, mappings, 'item_name'),
            'qty': qty,
            'rate': rate,
            'tax': tax,
            'amount': itemTotal,
          });
        }

        final partyName = importType == ImportType.sales
            ? _getMappedValue(first, mappings, 'customer_name')
            : _getMappedValue(first, mappings, 'supplier_name');

        vouchers.add(VoucherPreview(
          voucherType: importType == ImportType.sales ? 'Sales Invoice' : 'Purchase Invoice',
          voucherNumber: _getMappedValue(first, mappings, 'invoice_number'),
          date: _getMappedValue(first, mappings, 'invoice_date'),
          partyName: partyName,
          gstin: importType == ImportType.sales
              ? _getMappedValue(first, mappings, 'customer_gstin')
              : _getMappedValue(first, mappings, 'supplier_gstin'),
          items: items,
          total: voucherTotal,
          paymentMode: _getMappedValue(first, mappings, 'payment_mode'),
        ));

        totalAmount += voucherTotal;
        if (partyName != null) parties.add(partyName);
      }
    } else {
      // For stock/ledger, each row is a voucher
      for (final row in dataRows) {
        if (importType == ImportType.openingStock) {
          final qty = double.tryParse(
              _getMappedValue(row, mappings, 'quantity')?.replaceAll(',', '') ?? '0') ?? 0;
          final rate = double.tryParse(
              _getMappedValue(row, mappings, 'purchase_rate')?.replaceAll(',', '') ?? '0') ?? 0;
          final value = qty * rate;
          totalAmount += value;

          vouchers.add(VoucherPreview(
            voucherType: 'Stock Journal',
            voucherNumber: _getMappedValue(row, mappings, 'sku'),
            partyName: _getMappedValue(row, mappings, 'item_name'),
            total: value,
          ));
        } else {
          final balance = double.tryParse(
              _getMappedValue(row, mappings, 'opening_balance')?.replaceAll(',', '') ?? '0') ?? 0;
          totalAmount += balance;
          final partyName = _getMappedValue(row, mappings, 'party_name');

          vouchers.add(VoucherPreview(
            voucherType: 'Opening Balance',
            partyName: partyName,
            total: balance,
            date: _getMappedValue(row, mappings, 'as_on_date'),
          ));

          if (partyName != null) parties.add(partyName);
        }
      }
    }

    return DryRunPreview(
      vouchersToCreate: vouchers,
      summary: {
        'total_vouchers': vouchers.length,
        'total_amount': totalAmount,
        'parties_affected': parties.toList(),
      },
    );
  }

  static String? _getMappedValue(
    Map<String, dynamic> row,
    List<FieldMapping> mappings,
    String targetField,
  ) {
    final mapping = mappings.firstWhere(
      (m) => m.targetField == targetField,
      orElse: () => FieldMapping(targetField: targetField, label: '', type: 'string'),
    );
    
    if (mapping.sourceField != null) {
      return row[mapping.sourceField]?.toString();
    }
    return mapping.defaultValue?.toString();
  }

  // -------------------------------------------------------------------------
  // EXECUTE IMPORT
  // -------------------------------------------------------------------------

  /// Execute the actual import
  static Future<ImportResult> executeImport({
    required String batchId,
    bool skipInvalid = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/import/execute/$batchId')
          .replace(queryParameters: {'skip_invalid': skipInvalid.toString()}),
    );

    if (response.statusCode == 200) {
      return ImportResult.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to execute import: ${response.body}');
  }

  // -------------------------------------------------------------------------
  // AUDIT LOG
  // -------------------------------------------------------------------------

  /// Get audit log for a batch
  static Future<List<AuditLogEntry>> getAuditLog(String batchId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/import/audit/$batchId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AuditLogEntry.fromJson(e)).toList();
    }
    throw Exception('Failed to get audit log: ${response.body}');
  }
}
