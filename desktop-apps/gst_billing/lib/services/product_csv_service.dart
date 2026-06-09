/// Product CSV Import/Export Service
/// Handles CSV parsing and export for product data
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';

class ProductCSVService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// CSV Headers for product export
  static const List<String> productHeaders = [
    'name',
    'sku',
    'barcode',
    'hsn_code',
    'unit',
    'cost_price',
    'selling_price',
    'mrp',
    'gst_rate',
    'current_stock',
    'min_stock_level',
    'max_stock_level',
    'description',
    'is_active',
  ];

  // ============================================================================
  // IMPORT PRODUCTS FROM CSV
  // ============================================================================

  /// Parse CSV content and return product rows
  static ParsedProductCSV parseProductCSV(String csvContent) {
    try {
      final lines = csvContent.split('\n');
      
      if (lines.isEmpty) {
        return ParsedProductCSV(
          headers: [],
          rows: [],
          errors: ['CSV file is empty'],
        );
      }

      // Parse headers
      final headerLine = lines[0].trim();
      final headers = _parseCSVLine(headerLine);

      if (headers.isEmpty) {
        return ParsedProductCSV(
          headers: [],
          rows: [],
          errors: ['No headers found in CSV'],
        );
      }

      // Parse data rows
      final rows = <Map<String, String>>[];
      final errors = <String>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          final values = _parseCSVLine(line);
          
          // Create map from headers and values
          final row = <String, String>{};
          for (int j = 0; j < headers.length; j++) {
            row[headers[j]] = j < values.length ? values[j] : '';
          }
          
          // Validate required fields
          if (row['name']?.isEmpty ?? true) {
            errors.add('Row ${i + 1}: Product name is required');
            continue;
          }
          
          rows.add(row);
        } catch (e) {
          errors.add('Row ${i + 1}: ${e.toString()}');
        }
      }

      return ParsedProductCSV(
        headers: headers,
        rows: rows,
        errors: errors,
      );
    } catch (e) {
      return ParsedProductCSV(
        headers: [],
        rows: [],
        errors: ['Failed to parse CSV: $e'],
      );
    }
  }

  /// Import products from CSV data via API
  static Future<ProductImportResult> importProductsFromCSV(
    List<Map<String, String>> rows, {
    bool dryRun = true,
  }) async {
    try {
      final products = rows
          .map((row) => _mapRowToProduct(row))
          .where((p) => p != null)
          .cast<Map<String, dynamic>>()
          .toList();

      final response = await http.post(
        Uri.parse('$baseUrl/api/products/import'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'products': products,
          'dry_run': dryRun,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProductImportResult(
          success: true,
          totalRows: rows.length,
          importedCount: data['imported_count'] ?? 0,
          skippedCount: data['skipped_count'] ?? 0,
          failedCount: data['failed_count'] ?? 0,
          errors: (data['errors'] as List<dynamic>?)
              ?.cast<String>()
              .toList() ?? [],
          message: data['message'] ?? 'Import successful',
          dryRun: dryRun,
        );
      } else {
        final data = jsonDecode(response.body);
        return ProductImportResult(
          success: false,
          totalRows: rows.length,
          importedCount: 0,
          skippedCount: 0,
          failedCount: rows.length,
          errors: [data['detail'] ?? 'Import failed'],
          message: 'Import failed',
          dryRun: dryRun,
        );
      }
    } catch (e) {
      return ProductImportResult(
        success: false,
        totalRows: rows.length,
        importedCount: 0,
        skippedCount: 0,
        failedCount: rows.length,
        errors: [e.toString()],
        message: 'Import error',
        dryRun: dryRun,
      );
    }
  }

  // ============================================================================
  // EXPORT PRODUCTS TO CSV
  // ============================================================================

  /// Generate CSV content from products
  static String generateProductCSV(List<Item> products) {
    final buffer = StringBuffer();
    
    // Write headers
    buffer.writeln(_escapeAndJoinCSV(productHeaders));

    // Write product rows
    for (final product in products) {
      final row = [
        product.name,
        product.sku ?? '',
        product.barcode ?? '',
        product.hsnCode ?? '',
        product.unitCode ?? '',
        product.costPrice.toStringAsFixed(2),
        product.sellingPrice.toStringAsFixed(2),
        product.mrp.toStringAsFixed(2),
        product.gstRate.toStringAsFixed(2),
        product.currentStock.toStringAsFixed(2),
        product.minStockLevel.toStringAsFixed(2),
        product.maxStockLevel.toStringAsFixed(2),
        product.description ?? '',
        product.isActive ? '1' : '0',
      ];
      buffer.writeln(_escapeAndJoinCSV(row));
    }

    return buffer.toString();
  }

  /// Export products from database via API
  static Future<String> exportProductsFromDatabase() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/export'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return response.body; // Already CSV format from API
      } else {
        throw Exception('Failed to export: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  // ============================================================================
  // HELPER FUNCTIONS
  // ============================================================================

  /// Parse a CSV line handling quoted fields
  static List<String> _parseCSVLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      final nextChar = i + 1 < line.length ? line[i + 1] : null;

      if (char == '"') {
        if (inQuotes && nextChar == '"') {
          // Escaped quote
          buffer.write('"');
          i++; // Skip next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // Field separator
        fields.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    // Add last field
    if (buffer.isNotEmpty || line.endsWith(',')) {
      fields.add(buffer.toString().trim());
    }

    return fields;
  }

  /// Escape and join fields into CSV line
  static String _escapeAndJoinCSV(List<dynamic> fields) {
    return fields
        .map((field) {
          final str = field.toString();
          if (str.contains(',') ||
              str.contains('"') ||
              str.contains('\n') ||
              str.contains('\r')) {
            return '"${str.replaceAll('"', '""')}"';
          }
          return str;
        })
        .join(',');
  }

  /// Map CSV row to product JSON
  static Map<String, dynamic>? _mapRowToProduct(Map<String, String> row) {
    try {
      final name = row['name']?.trim();
      if (name == null || name.isEmpty) return null;

      return {
        'name': name,
        'sku': row['sku']?.trim(),
        'barcode': row['barcode']?.trim(),
        'hsn_code': row['hsn_code']?.trim(),
        'unit': row['unit']?.trim(),
        'cost_price': double.tryParse(row['cost_price'] ?? '0') ?? 0,
        'selling_price': double.tryParse(row['selling_price'] ?? '0') ?? 0,
        'mrp': double.tryParse(row['mrp'] ?? '0') ?? 0,
        'gst_rate': double.tryParse(row['gst_rate'] ?? '0') ?? 0,
        'current_stock': double.tryParse(row['current_stock'] ?? '0') ?? 0,
        'min_stock_level': double.tryParse(row['min_stock_level'] ?? '0') ?? 0,
        'max_stock_level': double.tryParse(row['max_stock_level'] ?? '0') ?? 0,
        'description': row['description']?.trim(),
        'is_active': row['is_active'] == '1' || row['is_active']?.toLowerCase() == 'true',
      };
    } catch (e) {
      return null;
    }
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class ParsedProductCSV {
  final List<String> headers;
  final List<Map<String, String>> rows;
  final List<String> errors;

  ParsedProductCSV({
    required this.headers,
    required this.rows,
    this.errors = const [],
  });

  bool get isValid => errors.isEmpty && rows.isNotEmpty;
  int get rowCount => rows.length;
  int get errorCount => errors.length;
}

class ProductImportResult {
  final bool success;
  final int totalRows;
  final int importedCount;
  final int skippedCount;
  final int failedCount;
  final List<String> errors;
  final String message;
  final bool dryRun;

  ProductImportResult({
    required this.success,
    required this.totalRows,
    required this.importedCount,
    required this.skippedCount,
    required this.failedCount,
    required this.errors,
    required this.message,
    required this.dryRun,
  });

  double get successRate =>
      totalRows > 0 ? (importedCount / totalRows) * 100 : 0;
}
