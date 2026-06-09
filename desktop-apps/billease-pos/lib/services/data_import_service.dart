import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/import_models.dart';

/// Service for importing data from various formats
/// Supports: CSV, XLSX (via CSV conversion), JSON, Tally XML, Generic POS
class DataImportService {
  static final DataImportService instance = DataImportService._init();
  final _uuid = const Uuid();
  
  DataImportService._init();

  // ============================================================================
  // MAIN IMPORT METHODS
  // ============================================================================

  /// Import sales data from file
  Future<ImportResult> importSales(String filePath, {ImportSourceFormat? format}) async {
    format ??= _detectFormat(filePath);
    
    List<Map<String, dynamic>> rawData;
    switch (format) {
      case ImportSourceFormat.csv:
      case ImportSourceFormat.xlsx:
        rawData = await _parseCSV(filePath);
        break;
      case ImportSourceFormat.json:
        rawData = await _parseJSON(filePath);
        break;
      case ImportSourceFormat.tally:
        return await _importTallySales(filePath);
      case ImportSourceFormat.genericPos:
        rawData = await _parseCSV(filePath);
        break;
    }

    final errors = <ImportError>[];
    var successCount = 0;
    final db = DatabaseHelper.instance;
    
    // Group items by invoice number
    final Map<String, List<SalesImportRow>> invoiceGroups = {};
    
    for (var i = 0; i < rawData.length; i++) {
      try {
        final row = SalesImportRow.fromMap(rawData[i]);
        invoiceGroups.putIfAbsent(row.invoiceNumber, () => []).add(row);
      } catch (e) {
        errors.add(ImportError(
          rowNumber: i + 2, // +2 for header and 0-indexing
          field: 'parsing',
          message: e.toString(),
        ));
      }
    }

    // Process each invoice group
    for (final entry in invoiceGroups.entries) {
      try {
        final items = entry.value;
        final firstItem = items.first;
        
        // Calculate totals
        double subtotal = 0;
        double taxAmount = 0;
        for (final item in items) {
          final itemSubtotal = item.quantity * item.rate;
          subtotal += itemSubtotal;
          taxAmount += itemSubtotal * (item.taxPercent / 100);
        }
        final totalAmount = subtotal + taxAmount;

        // Get or create customer if name provided
        int? customerId;
        if (firstItem.customerName != null && firstItem.customerName!.isNotEmpty) {
          customerId = await _getOrCreateCustomer(
            name: firstItem.customerName!,
            gstin: firstItem.gstin,
          );
        }

        // Insert sale
        final saleId = await db.insert('sales', {
          'tenant_id': 'default',
          'sale_number': firstItem.invoiceNumber,
          'customer_id': customerId,
          'customer_name': firstItem.customerName,
          'subtotal': subtotal,
          'tax_amount': taxAmount,
          'discount_amount': 0,
          'total_amount': totalAmount,
          'paid_amount': totalAmount,
          'due_amount': 0,
          'change_amount': 0,
          'payment_method': firstItem.paymentMode ?? 'Cash',
          'notes': 'Imported from external source',
          'status': 'completed',
          'payment_status': 'paid',
          'created_at': firstItem.invoiceDate.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Insert sale items
        for (final item in items) {
          // Get or create product
          final productId = await _getOrCreateProduct(
            name: item.itemName,
            hsn: item.hsn,
            price: item.rate,
            taxRate: item.taxPercent,
          );

          final itemSubtotal = item.quantity * item.rate;
          final itemTax = itemSubtotal * (item.taxPercent / 100);

          await db.insert('sale_items', {
            'sale_id': saleId,
            'product_id': productId,
            'product_name': item.itemName,
            'sku': 'IMP-${_uuid.v4().substring(0, 8).toUpperCase()}',
            'quantity': item.quantity.toInt(),
            'unit_price': item.rate,
            'discount_amount': 0,
            'tax_rate': item.taxPercent,
            'tax_amount': itemTax,
            'total_amount': itemSubtotal + itemTax,
            'created_at': firstItem.invoiceDate.toIso8601String(),
          });
        }

        successCount++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: 0,
          field: 'invoice ${entry.key}',
          message: e.toString(),
        ));
      }
    }

    return ImportResult(
      totalRows: invoiceGroups.length,
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
      importType: 'Sales',
    );
  }

  /// Import purchase data from file
  Future<ImportResult> importPurchases(String filePath, {ImportSourceFormat? format}) async {
    format ??= _detectFormat(filePath);
    
    List<Map<String, dynamic>> rawData;
    switch (format) {
      case ImportSourceFormat.csv:
      case ImportSourceFormat.xlsx:
        rawData = await _parseCSV(filePath);
        break;
      case ImportSourceFormat.json:
        rawData = await _parseJSON(filePath);
        break;
      case ImportSourceFormat.tally:
        return await _importTallyPurchases(filePath);
      case ImportSourceFormat.genericPos:
        rawData = await _parseCSV(filePath);
        break;
    }

    final errors = <ImportError>[];
    var successCount = 0;
    final db = DatabaseHelper.instance;
    
    // Group items by invoice number
    final Map<String, List<PurchaseImportRow>> invoiceGroups = {};
    
    for (var i = 0; i < rawData.length; i++) {
      try {
        final row = PurchaseImportRow.fromMap(rawData[i]);
        invoiceGroups.putIfAbsent(row.invoiceNumber, () => []).add(row);
      } catch (e) {
        errors.add(ImportError(
          rowNumber: i + 2,
          field: 'parsing',
          message: e.toString(),
        ));
      }
    }

    // Process each invoice group
    for (final entry in invoiceGroups.entries) {
      try {
        final items = entry.value;
        final firstItem = items.first;
        
        // Calculate totals
        double subtotal = 0;
        double taxAmount = 0;
        for (final item in items) {
          final itemSubtotal = item.quantity * item.rate;
          subtotal += itemSubtotal;
          taxAmount += itemSubtotal * (item.taxPercent / 100);
        }
        final totalAmount = subtotal + taxAmount;

        // Get or create supplier if name provided
        int? supplierId;
        if (firstItem.supplierName != null && firstItem.supplierName!.isNotEmpty) {
          supplierId = await _getOrCreateSupplier(
            name: firstItem.supplierName!,
            gstin: firstItem.gstin,
          );
        }

        // Generate purchase number
        final purchaseNumber = 'PUR-${DateTime.now().millisecondsSinceEpoch}';

        // Insert purchase
        final purchaseId = await db.insert('purchases', {
          'tenant_id': 'default',
          'purchase_number': purchaseNumber,
          'supplier_id': supplierId,
          'supplier_name': firstItem.supplierName,
          'supplier_invoice_number': firstItem.invoiceNumber,
          'subtotal': subtotal,
          'tax_amount': taxAmount,
          'discount_amount': 0,
          'total_amount': totalAmount,
          'paid_amount': totalAmount,
          'due_amount': 0,
          'payment_method': 'Cash',
          'notes': 'Imported from external source. Payment terms: ${firstItem.paymentTerms ?? "N/A"}',
          'status': 'completed',
          'payment_status': 'paid',
          'created_at': firstItem.date.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Insert purchase items and update stock
        for (final item in items) {
          // Get or create product
          final productId = await _getOrCreateProduct(
            name: item.itemName,
            hsn: item.hsn,
            price: item.rate,
            taxRate: item.taxPercent,
            cost: item.rate,
          );

          final itemSubtotal = item.quantity * item.rate;
          final itemTax = itemSubtotal * (item.taxPercent / 100);

          await db.insert('purchase_items', {
            'purchase_id': purchaseId,
            'product_id': productId,
            'product_name': item.itemName,
            'sku': 'IMP-${_uuid.v4().substring(0, 8).toUpperCase()}',
            'quantity': item.quantity.toInt(),
            'unit_price': item.rate,
            'discount_amount': 0,
            'tax_rate': item.taxPercent,
            'tax_amount': itemTax,
            'total_amount': itemSubtotal + itemTax,
            'created_at': firstItem.date.toIso8601String(),
          });

          // Update product stock quantity
          await db.update(
            'products',
            {'stock_quantity': await _getCurrentStock(productId) + item.quantity.toInt()},
            where: 'id = ?',
            whereArgs: [productId],
          );
        }

        successCount++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: 0,
          field: 'invoice ${entry.key}',
          message: e.toString(),
        ));
      }
    }

    return ImportResult(
      totalRows: invoiceGroups.length,
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
      importType: 'Purchases',
    );
  }

  /// Import stock opening balances from file
  Future<ImportResult> importStockOpening(String filePath, {ImportSourceFormat? format}) async {
    format ??= _detectFormat(filePath);
    
    List<Map<String, dynamic>> rawData;
    switch (format) {
      case ImportSourceFormat.csv:
      case ImportSourceFormat.xlsx:
        rawData = await _parseCSV(filePath);
        break;
      case ImportSourceFormat.json:
        rawData = await _parseJSON(filePath);
        break;
      case ImportSourceFormat.tally:
        rawData = await _parseTallyStockItems(filePath);
        break;
      case ImportSourceFormat.genericPos:
        rawData = await _parseCSV(filePath);
        break;
    }

    final errors = <ImportError>[];
    var successCount = 0;
    final db = DatabaseHelper.instance;

    for (var i = 0; i < rawData.length; i++) {
      try {
        final row = StockOpeningImportRow.fromMap(rawData[i]);
        
        // Check if product with SKU exists
        final existingProducts = await db.query(
          'products',
          where: 'sku = ?',
          whereArgs: [row.sku],
        );

        if (existingProducts.isNotEmpty) {
          // Update existing product
          await db.update(
            'products',
            {
              'stock_quantity': row.quantity.toInt(),
              'cost': row.purchaseRate,
              if (row.hsn != null) 'hsn_sac': row.hsn,
              if (row.barcode != null) 'barcode': row.barcode,
              if (row.taxRate != null) 'tax_rate': row.taxRate,
              if (row.category != null) 'category': row.category,
            },
            where: 'sku = ?',
            whereArgs: [row.sku],
          );
        } else {
          // Create new product
          await db.insert('products', {
            'tenant_id': 'default',
            'name': row.productName ?? row.sku,
            'sku': row.sku,
            'barcode': row.barcode,
            'category': row.category,
            'hsn_sac': row.hsn,
            'unit': 'piece',
            'price': row.purchaseRate,
            'cost': row.purchaseRate,
            'tax_rate': row.taxRate ?? 0,
            'stock_quantity': row.quantity.toInt(),
            'low_stock_threshold': 10,
            'is_active': 1,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        // Record stock adjustment for audit trail
        final productId = existingProducts.isNotEmpty 
            ? existingProducts.first['id'] as int
            : (await db.query('products', where: 'sku = ?', whereArgs: [row.sku])).first['id'] as int;

        await db.insert('stock_adjustments', {
          'tenant_id': 'default',
          'product_id': productId,
          'product_name': row.productName ?? row.sku,
          'adjustment_type': 'opening_balance',
          'quantity_change': row.quantity.toInt(),
          'reason': 'Opening stock balance import${row.batch != null ? " (Batch: ${row.batch})" : ""}',
          'performed_by': 'System Import',
          'created_at': DateTime.now().toIso8601String(),
        });

        successCount++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: i + 2,
          field: 'stock item',
          message: e.toString(),
        ));
      }
    }

    return ImportResult(
      totalRows: rawData.length,
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
      importType: 'Stock Opening',
    );
  }

  /// Import ledger opening balances (debtors/creditors)
  Future<ImportResult> importLedgerOpeningBalances(
    String filePath, 
    String ledgerType, // 'debtor' or 'creditor'
    {ImportSourceFormat? format}
  ) async {
    format ??= _detectFormat(filePath);
    
    List<Map<String, dynamic>> rawData;
    switch (format) {
      case ImportSourceFormat.csv:
      case ImportSourceFormat.xlsx:
        rawData = await _parseCSV(filePath);
        break;
      case ImportSourceFormat.json:
        rawData = await _parseJSON(filePath);
        break;
      case ImportSourceFormat.tally:
        rawData = await _parseTallyLedgers(filePath, ledgerType);
        break;
      case ImportSourceFormat.genericPos:
        rawData = await _parseCSV(filePath);
        break;
    }

    final errors = <ImportError>[];
    var successCount = 0;
    final db = DatabaseHelper.instance;

    for (var i = 0; i < rawData.length; i++) {
      try {
        final row = LedgerOpeningImportRow.fromMap(rawData[i], ledgerType);
        
        if (ledgerType == 'debtor') {
          // Import as customer
          final existingCustomers = await db.query(
            'customers',
            where: 'name = ? OR (gstin IS NOT NULL AND gstin = ?)',
            whereArgs: [row.name, row.gstin],
          );

          if (existingCustomers.isNotEmpty) {
            // Update existing customer with opening balance
            await db.update(
              'customers',
              {
                'total_purchases': row.openingBalance,
                if (row.phone != null) 'phone': row.phone,
                if (row.email != null) 'email': row.email,
                if (row.address != null) 'address': row.address,
                if (row.city != null) 'city': row.city,
                if (row.state != null) 'state': row.state,
                if (row.postalCode != null) 'postal_code': row.postalCode,
                if (row.gstin != null) 'gstin': row.gstin,
              },
              where: 'id = ?',
              whereArgs: [existingCustomers.first['id']],
            );
          } else {
            // Create new customer
            final customerCode = 'CUST-${_uuid.v4().substring(0, 8).toUpperCase()}';
            await db.insert('customers', {
              'tenant_id': 'default',
              'customer_code': customerCode,
              'name': row.name,
              'phone': row.phone,
              'email': row.email,
              'address': row.address,
              'city': row.city,
              'state': row.state,
              'postal_code': row.postalCode,
              'gstin': row.gstin,
              'total_purchases': row.openingBalance,
              'is_active': 1,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        } else {
          // Import as supplier
          final existingSuppliers = await db.query(
            'suppliers',
            where: 'name = ? OR (gstin IS NOT NULL AND gstin = ?)',
            whereArgs: [row.name, row.gstin],
          );

          if (existingSuppliers.isNotEmpty) {
            // Update existing supplier with opening balance
            await db.update(
              'suppliers',
              {
                'outstanding_balance': row.openingBalance,
                if (row.phone != null) 'phone': row.phone,
                if (row.email != null) 'email': row.email,
                if (row.address != null) 'address': row.address,
                if (row.city != null) 'city': row.city,
                if (row.state != null) 'state': row.state,
                if (row.postalCode != null) 'postal_code': row.postalCode,
                if (row.gstin != null) 'gstin': row.gstin,
                if (row.panNumber != null) 'pan_number': row.panNumber,
                if (row.bankName != null) 'bank_name': row.bankName,
                if (row.bankAccount != null) 'bank_account': row.bankAccount,
                if (row.ifscCode != null) 'ifsc_code': row.ifscCode,
              },
              where: 'id = ?',
              whereArgs: [existingSuppliers.first['id']],
            );
          } else {
            // Create new supplier
            final supplierCode = 'SUP-${_uuid.v4().substring(0, 8).toUpperCase()}';
            await db.insert('suppliers', {
              'tenant_id': 'default',
              'supplier_code': supplierCode,
              'name': row.name,
              'phone': row.phone,
              'email': row.email,
              'address': row.address,
              'city': row.city,
              'state': row.state,
              'postal_code': row.postalCode,
              'gstin': row.gstin,
              'pan_number': row.panNumber,
              'bank_name': row.bankName,
              'bank_account': row.bankAccount,
              'ifsc_code': row.ifscCode,
              'outstanding_balance': row.openingBalance,
              'is_active': 1,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        }

        successCount++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: i + 2,
          field: ledgerType,
          message: e.toString(),
        ));
      }
    }

    return ImportResult(
      totalRows: rawData.length,
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
      importType: ledgerType == 'debtor' ? 'Debtors' : 'Creditors',
    );
  }

  // ============================================================================
  // FILE PARSING METHODS
  // ============================================================================

  ImportSourceFormat _detectFormat(String filePath) {
    final ext = filePath.toLowerCase().split('.').last;
    switch (ext) {
      case 'csv':
        return ImportSourceFormat.csv;
      case 'xlsx':
      case 'xls':
        return ImportSourceFormat.xlsx;
      case 'json':
        return ImportSourceFormat.json;
      case 'xml':
        return ImportSourceFormat.tally;
      default:
        return ImportSourceFormat.csv;
    }
  }

  Future<List<Map<String, dynamic>>> _parseCSV(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(content);
    
    if (rows.isEmpty) return [];
    
    // First row is header
    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final data = <Map<String, dynamic>>[];
    
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
        continue; // Skip empty rows
      }
      
      final map = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        map[headers[j]] = row[j];
      }
      data.add(map);
    }
    
    return data;
  }

  Future<List<Map<String, dynamic>>> _parseJSON(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    
    if (decoded is List) {
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (decoded is Map && decoded.containsKey('data')) {
      final data = decoded['data'];
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    
    throw const FormatException('Invalid JSON format. Expected array or object with "data" array.');
  }

  Future<ImportResult> _importTallySales(String filePath) async {
    // Parse Tally XML export for sales vouchers
    final vouchers = await _parseTallyVouchers(filePath, 'Sales');
    final errors = <ImportError>[];
    var successCount = 0;
    final db = DatabaseHelper.instance;

    for (final voucher in vouchers) {
      try {
        // Get or create customer
        int? customerId;
        if (voucher.partyName != null) {
          customerId = await _getOrCreateCustomer(name: voucher.partyName!);
        }

        // Calculate totals from ledger entries
        double totalAmount = 0;
        for (final entry in voucher.ledgerEntries) {
          if (!entry.isDebit) {
            totalAmount += entry.amount;
          }
        }

        // Insert sale
        final saleId = await db.insert('sales', {
          'tenant_id': 'default',
          'sale_number': voucher.voucherNumber,
          'customer_id': customerId,
          'customer_name': voucher.partyName,
          'subtotal': totalAmount,
          'tax_amount': 0,
          'total_amount': totalAmount,
          'paid_amount': totalAmount,
          'payment_method': 'Cash',
          'notes': voucher.narration ?? 'Imported from Tally',
          'status': 'completed',
          'payment_status': 'paid',
          'created_at': voucher.date.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Insert sale items from inventory entries
        for (final item in voucher.inventoryEntries) {
          final productId = await _getOrCreateProduct(
            name: item.stockItemName,
            price: item.rate,
          );

          await db.insert('sale_items', {
            'sale_id': saleId,
            'product_id': productId,
            'product_name': item.stockItemName,
            'sku': 'TALLY-${_uuid.v4().substring(0, 8).toUpperCase()}',
            'quantity': item.quantity.toInt(),
            'unit_price': item.rate,
            'total_amount': item.amount,
            'created_at': voucher.date.toIso8601String(),
          });
        }

        successCount++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: 0,
          field: 'voucher ${voucher.voucherNumber}',
          message: e.toString(),
        ));
      }
    }

    return ImportResult(
      totalRows: vouchers.length,
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
      importType: 'Tally Sales',
    );
  }

  Future<ImportResult> _importTallyPurchases(String filePath) async {
    final vouchers = await _parseTallyVouchers(filePath, 'Purchase');
    final errors = <ImportError>[];
    var successCount = 0;
    final db = DatabaseHelper.instance;

    for (final voucher in vouchers) {
      try {
        // Get or create supplier
        int? supplierId;
        if (voucher.partyName != null) {
          supplierId = await _getOrCreateSupplier(name: voucher.partyName!);
        }

        double totalAmount = 0;
        for (final entry in voucher.ledgerEntries) {
          if (entry.isDebit) {
            totalAmount += entry.amount;
          }
        }

        final purchaseNumber = 'TALLY-${voucher.voucherNumber}';

        final purchaseId = await db.insert('purchases', {
          'tenant_id': 'default',
          'purchase_number': purchaseNumber,
          'supplier_id': supplierId,
          'supplier_name': voucher.partyName,
          'supplier_invoice_number': voucher.voucherNumber,
          'subtotal': totalAmount,
          'total_amount': totalAmount,
          'paid_amount': totalAmount,
          'payment_method': 'Cash',
          'notes': voucher.narration ?? 'Imported from Tally',
          'status': 'completed',
          'payment_status': 'paid',
          'created_at': voucher.date.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        for (final item in voucher.inventoryEntries) {
          final productId = await _getOrCreateProduct(
            name: item.stockItemName,
            price: item.rate,
            cost: item.rate,
          );

          await db.insert('purchase_items', {
            'purchase_id': purchaseId,
            'product_id': productId,
            'product_name': item.stockItemName,
            'sku': 'TALLY-${_uuid.v4().substring(0, 8).toUpperCase()}',
            'quantity': item.quantity.toInt(),
            'unit_price': item.rate,
            'total_amount': item.amount,
            'created_at': voucher.date.toIso8601String(),
          });

          // Update stock
          await db.update(
            'products',
            {'stock_quantity': await _getCurrentStock(productId) + item.quantity.toInt()},
            where: 'id = ?',
            whereArgs: [productId],
          );
        }

        successCount++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: 0,
          field: 'voucher ${voucher.voucherNumber}',
          message: e.toString(),
        ));
      }
    }

    return ImportResult(
      totalRows: vouchers.length,
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
      importType: 'Tally Purchases',
    );
  }

  Future<List<TallyVoucherImport>> _parseTallyVouchers(String filePath, String voucherType) async {
    // Basic Tally XML parsing - supports common export formats
    final file = File(filePath);
    final content = await file.readAsString();
    
    final vouchers = <TallyVoucherImport>[];
    
    // Simple regex-based parsing for Tally XML
    final voucherRegex = RegExp(
      r'<VOUCHER[^>]*VCHTYPE="' + voucherType + r'"[^>]*>(.*?)</VOUCHER>',
      dotAll: true,
      caseSensitive: false,
    );
    
    for (final match in voucherRegex.allMatches(content)) {
      final voucherXml = match.group(1) ?? '';
      
      final voucherNumber = _extractXmlValue(voucherXml, 'VOUCHERNUMBER') ?? 
                           _extractXmlValue(voucherXml, 'NUMBER') ?? 
                           'V-${DateTime.now().millisecondsSinceEpoch}';
      
      final dateStr = _extractXmlValue(voucherXml, 'DATE');
      final date = dateStr != null ? _parseTallyDate(dateStr) : DateTime.now();
      
      final partyName = _extractXmlValue(voucherXml, 'PARTYNAME') ?? 
                        _extractXmlValue(voucherXml, 'PARTYLEDGERNAME');
      
      final narration = _extractXmlValue(voucherXml, 'NARRATION');
      
      // Parse ledger entries
      final ledgerEntries = <TallyLedgerEntry>[];
      final ledgerRegex = RegExp(r'<LEDGERENTRIES.LIST>(.*?)</LEDGERENTRIES.LIST>', dotAll: true);
      for (final ledgerMatch in ledgerRegex.allMatches(voucherXml)) {
        final ledgerXml = ledgerMatch.group(1) ?? '';
        final ledgerName = _extractXmlValue(ledgerXml, 'LEDGERNAME') ?? '';
        final amountStr = _extractXmlValue(ledgerXml, 'AMOUNT') ?? '0';
        final amount = double.tryParse(amountStr.replaceAll(',', '')) ?? 0;
        
        ledgerEntries.add(TallyLedgerEntry(
          ledgerName: ledgerName,
          amount: amount.abs(),
          isDebit: amount > 0,
        ));
      }
      
      // Parse inventory entries
      final inventoryEntries = <TallyInventoryEntry>[];
      final inventoryRegex = RegExp(r'<INVENTORYENTRIES.LIST>(.*?)</INVENTORYENTRIES.LIST>', dotAll: true);
      for (final invMatch in inventoryRegex.allMatches(voucherXml)) {
        final invXml = invMatch.group(1) ?? '';
        final stockItemName = _extractXmlValue(invXml, 'STOCKITEMNAME') ?? '';
        final qty = double.tryParse(_extractXmlValue(invXml, 'ACTUALQTY')?.replaceAll(RegExp(r'[^\d.-]'), '') ?? '0') ?? 0;
        final rate = double.tryParse(_extractXmlValue(invXml, 'RATE')?.replaceAll(RegExp(r'[^\d.-]'), '') ?? '0') ?? 0;
        final amount = double.tryParse(_extractXmlValue(invXml, 'AMOUNT')?.replaceAll(RegExp(r'[^\d.-]'), '') ?? '0') ?? 0;
        final batchName = _extractXmlValue(invXml, 'BATCHNAME');
        final godownName = _extractXmlValue(invXml, 'GODOWNNAME');
        
        if (stockItemName.isNotEmpty) {
          inventoryEntries.add(TallyInventoryEntry(
            stockItemName: stockItemName,
            quantity: qty.abs(),
            rate: rate.abs(),
            amount: amount.abs(),
            batchName: batchName,
            godownName: godownName,
          ));
        }
      }
      
      vouchers.add(TallyVoucherImport(
        voucherType: voucherType,
        voucherNumber: voucherNumber,
        date: date,
        partyName: partyName,
        ledgerEntries: ledgerEntries,
        inventoryEntries: inventoryEntries,
        narration: narration,
      ));
    }
    
    return vouchers;
  }

  Future<List<Map<String, dynamic>>> _parseTallyStockItems(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    
    final items = <Map<String, dynamic>>[];
    
    // Parse stock items from Tally master export
    final stockRegex = RegExp(
      r'<STOCKITEM[^>]*NAME="([^"]*)"[^>]*>(.*?)</STOCKITEM>',
      dotAll: true,
      caseSensitive: false,
    );
    
    for (final match in stockRegex.allMatches(content)) {
      final name = match.group(1) ?? '';
      final itemXml = match.group(2) ?? '';
      
      final openingBalance = _extractXmlValue(itemXml, 'OPENINGBALANCE') ?? 
                             _extractXmlValue(itemXml, 'CLOSINGBALANCE') ?? '0';
      final openingValue = _extractXmlValue(itemXml, 'OPENINGVALUE') ?? '0';
      
      // Extract quantity from opening balance (format: "100 Nos" or "50 Pcs")
      final qtyMatch = RegExp(r'([\d.]+)').firstMatch(openingBalance);
      final qty = qtyMatch != null ? double.tryParse(qtyMatch.group(1)!) ?? 0 : 0;
      
      final value = double.tryParse(openingValue.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0;
      final rate = qty > 0 ? value / qty : 0;
      
      items.add({
        'sku': name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-').toUpperCase(),
        'product_name': name,
        'quantity': qty,
        'purchase_rate': rate,
        'hsn': _extractXmlValue(itemXml, 'HSNCODE'),
        'category': _extractXmlValue(itemXml, 'PARENT'),
      });
    }
    
    return items;
  }

  Future<List<Map<String, dynamic>>> _parseTallyLedgers(String filePath, String ledgerType) async {
    final file = File(filePath);
    final content = await file.readAsString();
    
    final ledgers = <Map<String, dynamic>>[];
    
    // Tally groups for debtors and creditors
    final targetGroups = ledgerType == 'debtor' 
        ? ['Sundry Debtors', 'Trade Receivables']
        : ['Sundry Creditors', 'Trade Payables'];
    
    final ledgerRegex = RegExp(
      r'<LEDGER[^>]*NAME="([^"]*)"[^>]*>(.*?)</LEDGER>',
      dotAll: true,
      caseSensitive: false,
    );
    
    for (final match in ledgerRegex.allMatches(content)) {
      final name = match.group(1) ?? '';
      final ledgerXml = match.group(2) ?? '';
      
      final parent = _extractXmlValue(ledgerXml, 'PARENT') ?? '';
      
      // Check if ledger belongs to target groups
      if (targetGroups.any((g) => parent.toLowerCase().contains(g.toLowerCase()))) {
        final openingBalance = _extractXmlValue(ledgerXml, 'OPENINGBALANCE') ?? '0';
        final balance = double.tryParse(openingBalance.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0;
        
        ledgers.add({
          'name': name,
          'opening_balance': balance.abs(),
          'gstin': _extractXmlValue(ledgerXml, 'PARTYGSTIN'),
          'phone': _extractXmlValue(ledgerXml, 'LEDGERPHONE'),
          'email': _extractXmlValue(ledgerXml, 'LEDGERMAIL') ?? _extractXmlValue(ledgerXml, 'EMAIL'),
          'address': _extractXmlValue(ledgerXml, 'ADDRESS'),
          'city': _extractXmlValue(ledgerXml, 'LEDSTATENAME'),
          'state': _extractXmlValue(ledgerXml, 'LEDSTATENAME'),
          'postal_code': _extractXmlValue(ledgerXml, 'PINCODE'),
          'pan_number': _extractXmlValue(ledgerXml, 'INCOMETAXNUMBER'),
        });
      }
    }
    
    return ledgers;
  }

  String? _extractXmlValue(String xml, String tagName) {
    final regex = RegExp('<$tagName>([^<]*)</$tagName>', caseSensitive: false);
    final match = regex.firstMatch(xml);
    final value = match?.group(1)?.trim();
    return value?.isEmpty == true ? null : value;
  }

  DateTime _parseTallyDate(String dateStr) {
    // Tally dates are typically in YYYYMMDD format
    if (dateStr.length == 8 && int.tryParse(dateStr) != null) {
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      return DateTime(year, month, day);
    }
    return DateTime.now();
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<int> _getOrCreateCustomer({required String name, String? gstin}) async {
    final db = DatabaseHelper.instance;
    
    // Try to find existing customer
    final existing = await db.query(
      'customers',
      where: 'name = ? OR (gstin IS NOT NULL AND gstin = ?)',
      whereArgs: [name, gstin],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    
    // Create new customer
    final customerCode = 'CUST-${_uuid.v4().substring(0, 8).toUpperCase()}';
    return await db.insert('customers', {
      'tenant_id': 'default',
      'customer_code': customerCode,
      'name': name,
      'gstin': gstin,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> _getOrCreateSupplier({required String name, String? gstin}) async {
    final db = DatabaseHelper.instance;
    
    final existing = await db.query(
      'suppliers',
      where: 'name = ? OR (gstin IS NOT NULL AND gstin = ?)',
      whereArgs: [name, gstin],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    
    final supplierCode = 'SUP-${_uuid.v4().substring(0, 8).toUpperCase()}';
    return await db.insert('suppliers', {
      'tenant_id': 'default',
      'supplier_code': supplierCode,
      'name': name,
      'gstin': gstin,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> _getOrCreateProduct({
    required String name,
    String? hsn,
    double? price,
    double? taxRate,
    double? cost,
  }) async {
    final db = DatabaseHelper.instance;
    
    // Try to find by name
    final existing = await db.query(
      'products',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    
    // Create new product
    final sku = 'IMP-${_uuid.v4().substring(0, 8).toUpperCase()}';
    return await db.insert('products', {
      'tenant_id': 'default',
      'name': name,
      'sku': sku,
      'hsn_sac': hsn,
      'unit': 'piece',
      'price': price ?? 0,
      'cost': cost ?? price ?? 0,
      'tax_rate': taxRate ?? 0,
      'stock_quantity': 0,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> _getCurrentStock(int productId) async {
    final db = DatabaseHelper.instance;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    
    if (result.isEmpty) return 0;
    return result.first['stock_quantity'] as int? ?? 0;
  }

  // ============================================================================
  // SAMPLE FILE GENERATORS
  // ============================================================================

  /// Generate sample CSV template for sales import
  String generateSalesTemplate() {
    return '''Invoice Number,Invoice Date,Customer Name,GSTIN,Item Name,HSN,Qty,Rate,Tax %,Total,Payment Mode,Notes
INV-001,2024-01-15,ABC Traders,29AABCT1234F1ZD,Product A,8471,2,1000,18,2360,Cash,Sample sale
INV-001,2024-01-15,ABC Traders,29AABCT1234F1ZD,Product B,8471,1,500,12,560,Cash,Sample sale
INV-002,2024-01-16,XYZ Corp,29XYZC5678G1ZD,Product C,8473,3,750,18,2655,UPI,Another sale''';
  }

  /// Generate sample CSV template for purchase import
  String generatePurchaseTemplate() {
    return '''Supplier,Invoice Number,GSTIN,Date,Item,HSN,Qty,Rate,Tax %,Total,Payment Terms,Notes
ABC Suppliers,PUR-001,29ABCS1234F1ZD,2024-01-10,Raw Material A,3926,100,50,18,5900,30 Days,Bulk order
ABC Suppliers,PUR-001,29ABCS1234F1ZD,2024-01-10,Raw Material B,3926,50,100,18,5900,30 Days,Bulk order
XYZ Vendors,PUR-002,29XYZV5678G1ZD,2024-01-12,Component X,8542,200,25,12,5600,15 Days,Regular order''';
  }

  /// Generate sample CSV template for stock opening import
  String generateStockOpeningTemplate() {
    return '''SKU,Product Name,Quantity,Purchase Rate,Batch,Barcode,HSN,Tax Rate,Category
SKU-001,Widget A,100,150,BATCH-2024-01,8901234567890,8471,18,Electronics
SKU-002,Gadget B,50,300,,8901234567891,8473,12,Electronics
SKU-003,Component C,200,25,BATCH-2024-02,8901234567892,3926,18,Components''';
  }

  /// Generate sample CSV template for ledger opening balance import
  String generateLedgerTemplate(String type) {
    if (type == 'debtor') {
      return '''Name,Opening Balance,GSTIN,Phone,Email,Address,City,State,Postal Code
ABC Traders,25000,29AABCT1234F1ZD,9876543210,abc@example.com,123 Main Street,Mumbai,Maharashtra,400001
XYZ Corp,15000,29XYZC5678G1ZD,9876543211,xyz@example.com,456 Park Road,Delhi,Delhi,110001''';
    } else {
      return '''Name,Opening Balance,GSTIN,Phone,Email,Address,City,State,Postal Code,PAN,Bank Name,Bank Account,IFSC Code
ABC Suppliers,50000,29ABCS1234F1ZD,9876543220,supplier@example.com,789 Industrial Area,Chennai,Tamil Nadu,600001,ABCPS1234F,HDFC Bank,1234567890123,HDFC0001234
XYZ Vendors,30000,29XYZV5678G1ZD,9876543221,vendor@example.com,321 Trade Zone,Bangalore,Karnataka,560001,XYZPV5678G,ICICI Bank,9876543210987,ICIC0005678''';
    }
  }
}
