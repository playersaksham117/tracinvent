import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../models/import_models.dart';

/// Service for exporting data to various formats for other accounting apps
/// Supports: CSV, JSON, Tally XML, Generic formats
class DataExportService {
  static final DataExportService instance = DataExportService._init();
  
  DataExportService._init();

  // ============================================================================
  // EXPORT CONFIG MODEL
  // ============================================================================
  
  /// Export configuration for different accounting software
  static final Map<String, ExportConfig> exportConfigs = {
    'tally': ExportConfig(
      name: 'Tally ERP/Prime',
      description: 'Export data compatible with Tally ERP 9 and Tally Prime',
      supportedFormats: [ExportFormat.tally],
      fileExtension: 'xml',
    ),
    'busy': ExportConfig(
      name: 'Busy Accounting',
      description: 'Export data compatible with Busy Accounting Software',
      supportedFormats: [ExportFormat.csv, ExportFormat.excel],
      fileExtension: 'csv',
    ),
    'zoho': ExportConfig(
      name: 'Zoho Books',
      description: 'Export data compatible with Zoho Books',
      supportedFormats: [ExportFormat.csv, ExportFormat.json],
      fileExtension: 'csv',
    ),
    'quickbooks': ExportConfig(
      name: 'QuickBooks',
      description: 'Export data compatible with QuickBooks Desktop/Online',
      supportedFormats: [ExportFormat.csv],
      fileExtension: 'csv',
    ),
    'marg': ExportConfig(
      name: 'Marg ERP',
      description: 'Export data compatible with Marg ERP Software',
      supportedFormats: [ExportFormat.csv, ExportFormat.excel],
      fileExtension: 'csv',
    ),
    'generic': ExportConfig(
      name: 'Generic Export',
      description: 'Standard format compatible with most accounting software',
      supportedFormats: [ExportFormat.csv, ExportFormat.json, ExportFormat.excel],
      fileExtension: 'csv',
    ),
  };

  // ============================================================================
  // MAIN EXPORT METHODS
  // ============================================================================

  /// Export sales data
  Future<ExportResult> exportSales({
    required String targetApp,
    required ExportFormat format,
    DateTime? fromDate,
    DateTime? toDate,
    String? customPath,
  }) async {
    final db = DatabaseHelper.instance;
    
    // Build query conditions
    String? where;
    List<dynamic>? whereArgs;
    
    if (fromDate != null && toDate != null) {
      where = 'created_at >= ? AND created_at <= ?';
      whereArgs = [
        fromDate.toIso8601String(),
        toDate.add(const Duration(days: 1)).toIso8601String(),
      ];
    } else if (fromDate != null) {
      where = 'created_at >= ?';
      whereArgs = [fromDate.toIso8601String()];
    } else if (toDate != null) {
      where = 'created_at <= ?';
      whereArgs = [toDate.add(const Duration(days: 1)).toIso8601String()];
    }

    final sales = await db.query(
      'sales',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    // Get sale items for each sale
    final salesWithItems = <Map<String, dynamic>>[];
    for (final sale in sales) {
      final items = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [sale['id']],
      );
      salesWithItems.add({...sale, 'items': items});
    }

    String filePath;
    String content;

    switch (format) {
      case ExportFormat.csv:
        content = _formatSalesCSV(salesWithItems, targetApp);
        filePath = await _getExportPath('sales_export', 'csv', customPath);
        break;
      case ExportFormat.json:
        content = _formatSalesJSON(salesWithItems);
        filePath = await _getExportPath('sales_export', 'json', customPath);
        break;
      case ExportFormat.tally:
        content = _formatSalesTallyXML(salesWithItems);
        filePath = await _getExportPath('sales_export', 'xml', customPath);
        break;
      case ExportFormat.excel:
        content = _formatSalesCSV(salesWithItems, targetApp);
        filePath = await _getExportPath('sales_export', 'csv', customPath);
        break;
    }

    final file = File(filePath);
    await file.writeAsString(content);

    return ExportResult(
      filePath: filePath,
      recordCount: salesWithItems.length,
      exportType: 'Sales',
      format: format,
      targetApp: targetApp,
    );
  }

  /// Export purchase data
  Future<ExportResult> exportPurchases({
    required String targetApp,
    required ExportFormat format,
    DateTime? fromDate,
    DateTime? toDate,
    String? customPath,
  }) async {
    final db = DatabaseHelper.instance;
    
    String? where;
    List<dynamic>? whereArgs;
    
    if (fromDate != null && toDate != null) {
      where = 'created_at >= ? AND created_at <= ?';
      whereArgs = [
        fromDate.toIso8601String(),
        toDate.add(const Duration(days: 1)).toIso8601String(),
      ];
    } else if (fromDate != null) {
      where = 'created_at >= ?';
      whereArgs = [fromDate.toIso8601String()];
    } else if (toDate != null) {
      where = 'created_at <= ?';
      whereArgs = [toDate.add(const Duration(days: 1)).toIso8601String()];
    }

    final purchases = await db.query(
      'purchases',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    final purchasesWithItems = <Map<String, dynamic>>[];
    for (final purchase in purchases) {
      final items = await db.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchase['id']],
      );
      purchasesWithItems.add({...purchase, 'items': items});
    }

    String filePath;
    String content;

    switch (format) {
      case ExportFormat.csv:
        content = _formatPurchasesCSV(purchasesWithItems, targetApp);
        filePath = await _getExportPath('purchases_export', 'csv', customPath);
        break;
      case ExportFormat.json:
        content = _formatPurchasesJSON(purchasesWithItems);
        filePath = await _getExportPath('purchases_export', 'json', customPath);
        break;
      case ExportFormat.tally:
        content = _formatPurchasesTallyXML(purchasesWithItems);
        filePath = await _getExportPath('purchases_export', 'xml', customPath);
        break;
      case ExportFormat.excel:
        content = _formatPurchasesCSV(purchasesWithItems, targetApp);
        filePath = await _getExportPath('purchases_export', 'csv', customPath);
        break;
    }

    final file = File(filePath);
    await file.writeAsString(content);

    return ExportResult(
      filePath: filePath,
      recordCount: purchasesWithItems.length,
      exportType: 'Purchases',
      format: format,
      targetApp: targetApp,
    );
  }

  /// Export stock/inventory data
  Future<ExportResult> exportStock({
    required String targetApp,
    required ExportFormat format,
    String? customPath,
  }) async {
    final db = DatabaseHelper.instance;
    
    final products = await db.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );

    String filePath;
    String content;

    switch (format) {
      case ExportFormat.csv:
        content = _formatStockCSV(products, targetApp);
        filePath = await _getExportPath('stock_export', 'csv', customPath);
        break;
      case ExportFormat.json:
        content = _formatStockJSON(products);
        filePath = await _getExportPath('stock_export', 'json', customPath);
        break;
      case ExportFormat.tally:
        content = _formatStockTallyXML(products);
        filePath = await _getExportPath('stock_export', 'xml', customPath);
        break;
      case ExportFormat.excel:
        content = _formatStockCSV(products, targetApp);
        filePath = await _getExportPath('stock_export', 'csv', customPath);
        break;
    }

    final file = File(filePath);
    await file.writeAsString(content);

    return ExportResult(
      filePath: filePath,
      recordCount: products.length,
      exportType: 'Stock',
      format: format,
      targetApp: targetApp,
    );
  }

  /// Export customers (debtors)
  Future<ExportResult> exportCustomers({
    required String targetApp,
    required ExportFormat format,
    String? customPath,
  }) async {
    final db = DatabaseHelper.instance;
    
    final customers = await db.query(
      'customers',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );

    String filePath;
    String content;

    switch (format) {
      case ExportFormat.csv:
        content = _formatCustomersCSV(customers, targetApp);
        filePath = await _getExportPath('customers_export', 'csv', customPath);
        break;
      case ExportFormat.json:
        content = _formatCustomersJSON(customers);
        filePath = await _getExportPath('customers_export', 'json', customPath);
        break;
      case ExportFormat.tally:
        content = _formatCustomersTallyXML(customers);
        filePath = await _getExportPath('customers_export', 'xml', customPath);
        break;
      case ExportFormat.excel:
        content = _formatCustomersCSV(customers, targetApp);
        filePath = await _getExportPath('customers_export', 'csv', customPath);
        break;
    }

    final file = File(filePath);
    await file.writeAsString(content);

    return ExportResult(
      filePath: filePath,
      recordCount: customers.length,
      exportType: 'Customers',
      format: format,
      targetApp: targetApp,
    );
  }

  /// Export suppliers (creditors)
  Future<ExportResult> exportSuppliers({
    required String targetApp,
    required ExportFormat format,
    String? customPath,
  }) async {
    final db = DatabaseHelper.instance;
    
    final suppliers = await db.query(
      'suppliers',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );

    String filePath;
    String content;

    switch (format) {
      case ExportFormat.csv:
        content = _formatSuppliersCSV(suppliers, targetApp);
        filePath = await _getExportPath('suppliers_export', 'csv', customPath);
        break;
      case ExportFormat.json:
        content = _formatSuppliersJSON(suppliers);
        filePath = await _getExportPath('suppliers_export', 'json', customPath);
        break;
      case ExportFormat.tally:
        content = _formatSuppliersTallyXML(suppliers);
        filePath = await _getExportPath('suppliers_export', 'xml', customPath);
        break;
      case ExportFormat.excel:
        content = _formatSuppliersCSV(suppliers, targetApp);
        filePath = await _getExportPath('suppliers_export', 'csv', customPath);
        break;
    }

    final file = File(filePath);
    await file.writeAsString(content);

    return ExportResult(
      filePath: filePath,
      recordCount: suppliers.length,
      exportType: 'Suppliers',
      format: format,
      targetApp: targetApp,
    );
  }

  /// Export all data in a single package
  Future<List<ExportResult>> exportAllData({
    required String targetApp,
    required ExportFormat format,
    DateTime? fromDate,
    DateTime? toDate,
    String? customPath,
  }) async {
    final results = <ExportResult>[];

    results.add(await exportSales(
      targetApp: targetApp,
      format: format,
      fromDate: fromDate,
      toDate: toDate,
      customPath: customPath,
    ));

    results.add(await exportPurchases(
      targetApp: targetApp,
      format: format,
      fromDate: fromDate,
      toDate: toDate,
      customPath: customPath,
    ));

    results.add(await exportStock(
      targetApp: targetApp,
      format: format,
      customPath: customPath,
    ));

    results.add(await exportCustomers(
      targetApp: targetApp,
      format: format,
      customPath: customPath,
    ));

    results.add(await exportSuppliers(
      targetApp: targetApp,
      format: format,
      customPath: customPath,
    ));

    return results;
  }

  // ============================================================================
  // CSV FORMATTERS
  // ============================================================================

  String _formatSalesCSV(List<Map<String, dynamic>> sales, String targetApp) {
    final rows = <List<dynamic>>[
      ['Invoice Number', 'Invoice Date', 'Customer Name', 'Customer GSTIN', 
       'Item Name', 'HSN/SAC', 'Quantity', 'Unit Price', 'Tax Rate %', 
       'Tax Amount', 'Total Amount', 'Payment Method', 'Payment Status', 'Notes'],
    ];

    for (final sale in sales) {
      final items = sale['items'] as List<dynamic>? ?? [];
      final saleDate = _formatDateForExport(sale['created_at']);
      
      for (final item in items) {
        rows.add([
          sale['sale_number'] ?? '',
          saleDate,
          sale['customer_name'] ?? '',
          '', // GSTIN would need customer lookup
          item['product_name'] ?? '',
          '', // HSN would need product lookup
          item['quantity'] ?? 0,
          item['unit_price'] ?? 0,
          item['tax_rate'] ?? 0,
          item['tax_amount'] ?? 0,
          item['total_amount'] ?? 0,
          sale['payment_method'] ?? '',
          sale['payment_status'] ?? '',
          sale['notes'] ?? '',
        ]);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  String _formatPurchasesCSV(List<Map<String, dynamic>> purchases, String targetApp) {
    final rows = <List<dynamic>>[
      ['Purchase Number', 'Supplier Invoice', 'Date', 'Supplier Name', 'Supplier GSTIN',
       'Item Name', 'HSN/SAC', 'Quantity', 'Unit Price', 'Tax Rate %',
       'Tax Amount', 'Total Amount', 'Payment Method', 'Payment Status', 'Notes'],
    ];

    for (final purchase in purchases) {
      final items = purchase['items'] as List<dynamic>? ?? [];
      final purchaseDate = _formatDateForExport(purchase['created_at']);
      
      for (final item in items) {
        rows.add([
          purchase['purchase_number'] ?? '',
          purchase['supplier_invoice_number'] ?? '',
          purchaseDate,
          purchase['supplier_name'] ?? '',
          '', // GSTIN would need supplier lookup
          item['product_name'] ?? '',
          '', // HSN would need product lookup
          item['quantity'] ?? 0,
          item['unit_price'] ?? 0,
          item['tax_rate'] ?? 0,
          item['tax_amount'] ?? 0,
          item['total_amount'] ?? 0,
          purchase['payment_method'] ?? '',
          purchase['payment_status'] ?? '',
          purchase['notes'] ?? '',
        ]);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  String _formatStockCSV(List<Map<String, dynamic>> products, String targetApp) {
    final rows = <List<dynamic>>[
      ['SKU', 'Product Name', 'Barcode', 'Category', 'Brand', 'HSN/SAC',
       'Unit', 'Selling Price', 'Cost Price', 'Tax Rate %', 'Stock Quantity',
       'Low Stock Threshold', 'Is Active'],
    ];

    for (final product in products) {
      rows.add([
        product['sku'] ?? '',
        product['name'] ?? '',
        product['barcode'] ?? '',
        product['category'] ?? '',
        product['brand'] ?? '',
        product['hsn_sac'] ?? '',
        product['unit'] ?? 'piece',
        product['price'] ?? 0,
        product['cost'] ?? 0,
        product['tax_rate'] ?? 0,
        product['stock_quantity'] ?? 0,
        product['low_stock_threshold'] ?? 10,
        (product['is_active'] ?? 1) == 1 ? 'Yes' : 'No',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  String _formatCustomersCSV(List<Map<String, dynamic>> customers, String targetApp) {
    final rows = <List<dynamic>>[
      ['Customer Code', 'Name', 'Phone', 'Email', 'Address', 'City',
       'State', 'Postal Code', 'GSTIN', 'Total Purchases', 'Loyalty Points'],
    ];

    for (final customer in customers) {
      rows.add([
        customer['customer_code'] ?? '',
        customer['name'] ?? '',
        customer['phone'] ?? '',
        customer['email'] ?? '',
        customer['address'] ?? '',
        customer['city'] ?? '',
        customer['state'] ?? '',
        customer['postal_code'] ?? '',
        customer['gstin'] ?? '',
        customer['total_purchases'] ?? 0,
        customer['loyalty_points'] ?? 0,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  String _formatSuppliersCSV(List<Map<String, dynamic>> suppliers, String targetApp) {
    final rows = <List<dynamic>>[
      ['Supplier Code', 'Name', 'Phone', 'Email', 'Address', 'City',
       'State', 'Postal Code', 'GSTIN', 'PAN', 'Bank Name', 'Bank Account',
       'IFSC Code', 'Total Purchases', 'Outstanding Balance'],
    ];

    for (final supplier in suppliers) {
      rows.add([
        supplier['supplier_code'] ?? '',
        supplier['name'] ?? '',
        supplier['phone'] ?? '',
        supplier['email'] ?? '',
        supplier['address'] ?? '',
        supplier['city'] ?? '',
        supplier['state'] ?? '',
        supplier['postal_code'] ?? '',
        supplier['gstin'] ?? '',
        supplier['pan_number'] ?? '',
        supplier['bank_name'] ?? '',
        supplier['bank_account'] ?? '',
        supplier['ifsc_code'] ?? '',
        supplier['total_purchases'] ?? 0,
        supplier['outstanding_balance'] ?? 0,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  // ============================================================================
  // JSON FORMATTERS
  // ============================================================================

  String _formatSalesJSON(List<Map<String, dynamic>> sales) {
    final exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'export_type': 'sales',
      'record_count': sales.length,
      'data': sales.map((sale) {
        final items = sale['items'] as List<dynamic>? ?? [];
        return {
          'invoice_number': sale['sale_number'],
          'invoice_date': sale['created_at'],
          'customer_name': sale['customer_name'],
          'subtotal': sale['subtotal'],
          'tax_amount': sale['tax_amount'],
          'discount': sale['discount_amount'],
          'total_amount': sale['total_amount'],
          'payment_method': sale['payment_method'],
          'payment_status': sale['payment_status'],
          'items': items.map((item) => <String, dynamic>{
            'product_name': item['product_name'],
            'sku': item['sku'],
            'quantity': item['quantity'],
            'unit_price': item['unit_price'],
            'tax_rate': item['tax_rate'],
            'tax_amount': item['tax_amount'],
            'total': item['total_amount'],
          }).toList(),
        };
      }).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  String _formatPurchasesJSON(List<Map<String, dynamic>> purchases) {
    final exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'export_type': 'purchases',
      'record_count': purchases.length,
      'data': purchases.map((purchase) {
        final items = purchase['items'] as List<dynamic>? ?? [];
        return {
          'purchase_number': purchase['purchase_number'],
          'supplier_invoice': purchase['supplier_invoice_number'],
          'date': purchase['created_at'],
          'supplier_name': purchase['supplier_name'],
          'subtotal': purchase['subtotal'],
          'tax_amount': purchase['tax_amount'],
          'total_amount': purchase['total_amount'],
          'payment_method': purchase['payment_method'],
          'payment_status': purchase['payment_status'],
          'items': items.map((item) => <String, dynamic>{
            'product_name': item['product_name'],
            'sku': item['sku'],
            'quantity': item['quantity'],
            'unit_price': item['unit_price'],
            'tax_rate': item['tax_rate'],
            'total': item['total_amount'],
          }).toList(),
        };
      }).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  String _formatStockJSON(List<Map<String, dynamic>> products) {
    final exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'export_type': 'stock',
      'record_count': products.length,
      'data': products.map((product) {
        return {
          'sku': product['sku'],
          'name': product['name'],
          'barcode': product['barcode'],
          'category': product['category'],
          'brand': product['brand'],
          'hsn_sac': product['hsn_sac'],
          'unit': product['unit'],
          'selling_price': product['price'],
          'cost_price': product['cost'],
          'tax_rate': product['tax_rate'],
          'stock_quantity': product['stock_quantity'],
        };
      }).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  String _formatCustomersJSON(List<Map<String, dynamic>> customers) {
    final exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'export_type': 'customers',
      'record_count': customers.length,
      'data': customers.map((customer) {
        return {
          'code': customer['customer_code'],
          'name': customer['name'],
          'phone': customer['phone'],
          'email': customer['email'],
          'address': customer['address'],
          'city': customer['city'],
          'state': customer['state'],
          'postal_code': customer['postal_code'],
          'gstin': customer['gstin'],
          'total_purchases': customer['total_purchases'],
        };
      }).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  String _formatSuppliersJSON(List<Map<String, dynamic>> suppliers) {
    final exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'export_type': 'suppliers',
      'record_count': suppliers.length,
      'data': suppliers.map((supplier) {
        return {
          'code': supplier['supplier_code'],
          'name': supplier['name'],
          'phone': supplier['phone'],
          'email': supplier['email'],
          'address': supplier['address'],
          'city': supplier['city'],
          'state': supplier['state'],
          'postal_code': supplier['postal_code'],
          'gstin': supplier['gstin'],
          'pan': supplier['pan_number'],
          'bank_name': supplier['bank_name'],
          'bank_account': supplier['bank_account'],
          'ifsc_code': supplier['ifsc_code'],
          'outstanding_balance': supplier['outstanding_balance'],
        };
      }).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  // ============================================================================
  // TALLY XML FORMATTERS
  // ============================================================================

  String _formatSalesTallyXML(List<Map<String, dynamic>> sales) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<ENVELOPE>');
    buffer.writeln('  <HEADER>');
    buffer.writeln('    <TALLYREQUEST>Import Data</TALLYREQUEST>');
    buffer.writeln('  </HEADER>');
    buffer.writeln('  <BODY>');
    buffer.writeln('    <IMPORTDATA>');
    buffer.writeln('      <REQUESTDESC>');
    buffer.writeln('        <REPORTNAME>Vouchers</REPORTNAME>');
    buffer.writeln('        <STATICVARIABLES>');
    buffer.writeln('          <SVCURRENTCOMPANY>##TARGETCOMPANY##</SVCURRENTCOMPANY>');
    buffer.writeln('        </STATICVARIABLES>');
    buffer.writeln('      </REQUESTDESC>');
    buffer.writeln('      <REQUESTDATA>');

    for (final sale in sales) {
      final items = sale['items'] as List<dynamic>? ?? [];
      final date = _parseDateForTally(sale['created_at']);
      final totalAmount = (sale['total_amount'] as num?)?.toDouble() ?? 0;

      buffer.writeln('        <TALLYMESSAGE xmlns:UDF="TallyUDF">');
      buffer.writeln('          <VOUCHER VCHTYPE="Sales" ACTION="Create">');
      buffer.writeln('            <DATE>$date</DATE>');
      buffer.writeln('            <VOUCHERTYPENAME>Sales</VOUCHERTYPENAME>');
      buffer.writeln('            <VOUCHERNUMBER>${_escapeXml(sale['sale_number'] ?? '')}</VOUCHERNUMBER>');
      
      if (sale['customer_name'] != null) {
        buffer.writeln('            <PARTYNAME>${_escapeXml(sale['customer_name'])}</PARTYNAME>');
      }
      
      buffer.writeln('            <NARRATION>Imported from BillEase POS</NARRATION>');
      
      // Party ledger entry (debit)
      buffer.writeln('            <LEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>${_escapeXml(sale['customer_name'] ?? 'Cash')}</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>-$totalAmount</AMOUNT>');
      buffer.writeln('            </LEDGERENTRIES.LIST>');
      
      // Sales ledger entry (credit)
      buffer.writeln('            <LEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>Sales Account</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>${sale['subtotal'] ?? totalAmount}</AMOUNT>');
      buffer.writeln('            </LEDGERENTRIES.LIST>');
      
      // Tax ledger entry if applicable
      if (((sale['tax_amount'] as num?)?.toDouble() ?? 0) > 0) {
        buffer.writeln('            <LEDGERENTRIES.LIST>');
        buffer.writeln('              <LEDGERNAME>Output GST</LEDGERNAME>');
        buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
        buffer.writeln('              <AMOUNT>${sale['tax_amount']}</AMOUNT>');
        buffer.writeln('            </LEDGERENTRIES.LIST>');
      }
      
      // Inventory entries
      for (final item in items) {
        buffer.writeln('            <INVENTORYENTRIES.LIST>');
        buffer.writeln('              <STOCKITEMNAME>${_escapeXml(item['product_name'] ?? '')}</STOCKITEMNAME>');
        buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
        buffer.writeln('              <ACTUALQTY>${item['quantity']} Nos</ACTUALQTY>');
        buffer.writeln('              <RATE>${item['unit_price']}/Nos</RATE>');
        buffer.writeln('              <AMOUNT>${item['total_amount']}</AMOUNT>');
        buffer.writeln('            </INVENTORYENTRIES.LIST>');
      }
      
      buffer.writeln('          </VOUCHER>');
      buffer.writeln('        </TALLYMESSAGE>');
    }

    buffer.writeln('      </REQUESTDATA>');
    buffer.writeln('    </IMPORTDATA>');
    buffer.writeln('  </BODY>');
    buffer.writeln('</ENVELOPE>');

    return buffer.toString();
  }

  String _formatPurchasesTallyXML(List<Map<String, dynamic>> purchases) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<ENVELOPE>');
    buffer.writeln('  <HEADER>');
    buffer.writeln('    <TALLYREQUEST>Import Data</TALLYREQUEST>');
    buffer.writeln('  </HEADER>');
    buffer.writeln('  <BODY>');
    buffer.writeln('    <IMPORTDATA>');
    buffer.writeln('      <REQUESTDESC>');
    buffer.writeln('        <REPORTNAME>Vouchers</REPORTNAME>');
    buffer.writeln('      </REQUESTDESC>');
    buffer.writeln('      <REQUESTDATA>');

    for (final purchase in purchases) {
      final items = purchase['items'] as List<dynamic>? ?? [];
      final date = _parseDateForTally(purchase['created_at']);
      final totalAmount = (purchase['total_amount'] as num?)?.toDouble() ?? 0;

      buffer.writeln('        <TALLYMESSAGE xmlns:UDF="TallyUDF">');
      buffer.writeln('          <VOUCHER VCHTYPE="Purchase" ACTION="Create">');
      buffer.writeln('            <DATE>$date</DATE>');
      buffer.writeln('            <VOUCHERTYPENAME>Purchase</VOUCHERTYPENAME>');
      buffer.writeln('            <VOUCHERNUMBER>${_escapeXml(purchase['purchase_number'] ?? '')}</VOUCHERNUMBER>');
      
      if (purchase['supplier_name'] != null) {
        buffer.writeln('            <PARTYNAME>${_escapeXml(purchase['supplier_name'])}</PARTYNAME>');
      }
      
      buffer.writeln('            <NARRATION>Imported from BillEase POS - Supplier Inv: ${purchase['supplier_invoice_number'] ?? 'N/A'}</NARRATION>');
      
      // Purchase ledger entry (debit)
      buffer.writeln('            <LEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>Purchase Account</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>-${purchase['subtotal'] ?? totalAmount}</AMOUNT>');
      buffer.writeln('            </LEDGERENTRIES.LIST>');
      
      // Supplier ledger entry (credit)
      buffer.writeln('            <LEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>${_escapeXml(purchase['supplier_name'] ?? 'Cash')}</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>$totalAmount</AMOUNT>');
      buffer.writeln('            </LEDGERENTRIES.LIST>');
      
      // Inventory entries
      for (final item in items) {
        buffer.writeln('            <INVENTORYENTRIES.LIST>');
        buffer.writeln('              <STOCKITEMNAME>${_escapeXml(item['product_name'] ?? '')}</STOCKITEMNAME>');
        buffer.writeln('              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>');
        buffer.writeln('              <ACTUALQTY>${item['quantity']} Nos</ACTUALQTY>');
        buffer.writeln('              <RATE>${item['unit_price']}/Nos</RATE>');
        buffer.writeln('              <AMOUNT>-${item['total_amount']}</AMOUNT>');
        buffer.writeln('            </INVENTORYENTRIES.LIST>');
      }
      
      buffer.writeln('          </VOUCHER>');
      buffer.writeln('        </TALLYMESSAGE>');
    }

    buffer.writeln('      </REQUESTDATA>');
    buffer.writeln('    </IMPORTDATA>');
    buffer.writeln('  </BODY>');
    buffer.writeln('</ENVELOPE>');

    return buffer.toString();
  }

  String _formatStockTallyXML(List<Map<String, dynamic>> products) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<ENVELOPE>');
    buffer.writeln('  <HEADER>');
    buffer.writeln('    <TALLYREQUEST>Import Data</TALLYREQUEST>');
    buffer.writeln('  </HEADER>');
    buffer.writeln('  <BODY>');
    buffer.writeln('    <IMPORTDATA>');
    buffer.writeln('      <REQUESTDESC>');
    buffer.writeln('        <REPORTNAME>All Masters</REPORTNAME>');
    buffer.writeln('      </REQUESTDESC>');
    buffer.writeln('      <REQUESTDATA>');

    for (final product in products) {
      final stockQty = (product['stock_quantity'] as num?)?.toInt() ?? 0;
      final costPrice = (product['cost'] as num?)?.toDouble() ?? 0;
      final openingValue = stockQty * costPrice;

      buffer.writeln('        <TALLYMESSAGE xmlns:UDF="TallyUDF">');
      buffer.writeln('          <STOCKITEM NAME="${_escapeXml(product['name'] ?? '')}" ACTION="Create">');
      buffer.writeln('            <NAME>${_escapeXml(product['name'] ?? '')}</NAME>');
      
      if (product['category'] != null) {
        buffer.writeln('            <PARENT>${_escapeXml(product['category'])}</PARENT>');
      } else {
        buffer.writeln('            <PARENT>Primary</PARENT>');
      }
      
      buffer.writeln('            <BASEUNITS>Nos</BASEUNITS>');
      
      if (product['hsn_sac'] != null) {
        buffer.writeln('            <HSNCODE>${_escapeXml(product['hsn_sac'])}</HSNCODE>');
      }
      
      if (stockQty > 0) {
        buffer.writeln('            <OPENINGBALANCE>$stockQty Nos</OPENINGBALANCE>');
        buffer.writeln('            <OPENINGVALUE>$openingValue</OPENINGVALUE>');
        buffer.writeln('            <OPENINGRATE>$costPrice/Nos</OPENINGRATE>');
      }
      
      if (product['tax_rate'] != null) {
        buffer.writeln('            <GSTRATE>${product['tax_rate']}</GSTRATE>');
      }
      
      buffer.writeln('          </STOCKITEM>');
      buffer.writeln('        </TALLYMESSAGE>');
    }

    buffer.writeln('      </REQUESTDATA>');
    buffer.writeln('    </IMPORTDATA>');
    buffer.writeln('  </BODY>');
    buffer.writeln('</ENVELOPE>');

    return buffer.toString();
  }

  String _formatCustomersTallyXML(List<Map<String, dynamic>> customers) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<ENVELOPE>');
    buffer.writeln('  <HEADER>');
    buffer.writeln('    <TALLYREQUEST>Import Data</TALLYREQUEST>');
    buffer.writeln('  </HEADER>');
    buffer.writeln('  <BODY>');
    buffer.writeln('    <IMPORTDATA>');
    buffer.writeln('      <REQUESTDESC>');
    buffer.writeln('        <REPORTNAME>All Masters</REPORTNAME>');
    buffer.writeln('      </REQUESTDESC>');
    buffer.writeln('      <REQUESTDATA>');

    for (final customer in customers) {
      buffer.writeln('        <TALLYMESSAGE xmlns:UDF="TallyUDF">');
      buffer.writeln('          <LEDGER NAME="${_escapeXml(customer['name'] ?? '')}" ACTION="Create">');
      buffer.writeln('            <NAME>${_escapeXml(customer['name'] ?? '')}</NAME>');
      buffer.writeln('            <PARENT>Sundry Debtors</PARENT>');
      
      if (customer['address'] != null) {
        buffer.writeln('            <ADDRESS>${_escapeXml(customer['address'])}</ADDRESS>');
      }
      
      if (customer['state'] != null) {
        buffer.writeln('            <LEDSTATENAME>${_escapeXml(customer['state'])}</LEDSTATENAME>');
      }
      
      if (customer['gstin'] != null) {
        buffer.writeln('            <PARTYGSTIN>${_escapeXml(customer['gstin'])}</PARTYGSTIN>');
      }
      
      if (customer['phone'] != null) {
        buffer.writeln('            <LEDGERPHONE>${_escapeXml(customer['phone'])}</LEDGERPHONE>');
      }
      
      if (customer['email'] != null) {
        buffer.writeln('            <LEDGERMAIL>${_escapeXml(customer['email'])}</LEDGERMAIL>');
      }
      
      final openingBalance = (customer['total_purchases'] as num?)?.toDouble() ?? 0;
      if (openingBalance > 0) {
        buffer.writeln('            <OPENINGBALANCE>-$openingBalance</OPENINGBALANCE>');
      }
      
      buffer.writeln('          </LEDGER>');
      buffer.writeln('        </TALLYMESSAGE>');
    }

    buffer.writeln('      </REQUESTDATA>');
    buffer.writeln('    </IMPORTDATA>');
    buffer.writeln('  </BODY>');
    buffer.writeln('</ENVELOPE>');

    return buffer.toString();
  }

  String _formatSuppliersTallyXML(List<Map<String, dynamic>> suppliers) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<ENVELOPE>');
    buffer.writeln('  <HEADER>');
    buffer.writeln('    <TALLYREQUEST>Import Data</TALLYREQUEST>');
    buffer.writeln('  </HEADER>');
    buffer.writeln('  <BODY>');
    buffer.writeln('    <IMPORTDATA>');
    buffer.writeln('      <REQUESTDESC>');
    buffer.writeln('        <REPORTNAME>All Masters</REPORTNAME>');
    buffer.writeln('      </REQUESTDESC>');
    buffer.writeln('      <REQUESTDATA>');

    for (final supplier in suppliers) {
      buffer.writeln('        <TALLYMESSAGE xmlns:UDF="TallyUDF">');
      buffer.writeln('          <LEDGER NAME="${_escapeXml(supplier['name'] ?? '')}" ACTION="Create">');
      buffer.writeln('            <NAME>${_escapeXml(supplier['name'] ?? '')}</NAME>');
      buffer.writeln('            <PARENT>Sundry Creditors</PARENT>');
      
      if (supplier['address'] != null) {
        buffer.writeln('            <ADDRESS>${_escapeXml(supplier['address'])}</ADDRESS>');
      }
      
      if (supplier['state'] != null) {
        buffer.writeln('            <LEDSTATENAME>${_escapeXml(supplier['state'])}</LEDSTATENAME>');
      }
      
      if (supplier['gstin'] != null) {
        buffer.writeln('            <PARTYGSTIN>${_escapeXml(supplier['gstin'])}</PARTYGSTIN>');
      }
      
      if (supplier['phone'] != null) {
        buffer.writeln('            <LEDGERPHONE>${_escapeXml(supplier['phone'])}</LEDGERPHONE>');
      }
      
      if (supplier['email'] != null) {
        buffer.writeln('            <LEDGERMAIL>${_escapeXml(supplier['email'])}</LEDGERMAIL>');
      }
      
      if (supplier['pan_number'] != null) {
        buffer.writeln('            <INCOMETAXNUMBER>${_escapeXml(supplier['pan_number'])}</INCOMETAXNUMBER>');
      }
      
      final openingBalance = (supplier['outstanding_balance'] as num?)?.toDouble() ?? 0;
      if (openingBalance > 0) {
        buffer.writeln('            <OPENINGBALANCE>$openingBalance</OPENINGBALANCE>');
      }
      
      buffer.writeln('          </LEDGER>');
      buffer.writeln('        </TALLYMESSAGE>');
    }

    buffer.writeln('      </REQUESTDATA>');
    buffer.writeln('    </IMPORTDATA>');
    buffer.writeln('  </BODY>');
    buffer.writeln('</ENVELOPE>');

    return buffer.toString();
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  Future<String> _getExportPath(String filename, String extension, String? customPath) async {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final fullFilename = '${filename}_$timestamp.$extension';

    if (customPath != null) {
      return '$customPath\\$fullFilename';
    }

    String exportDir;
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      exportDir = '$userProfile\\Documents\\BillEase Exports';
    } else {
      final docs = await getApplicationDocumentsDirectory();
      exportDir = '${docs.path}/BillEase Exports';
    }

    final dir = Directory(exportDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return Platform.isWindows 
        ? '$exportDir\\$fullFilename' 
        : '$exportDir/$fullFilename';
  }

  String _formatDateForExport(dynamic date) {
    if (date == null) return '';
    try {
      DateTime dt;
      if (date is DateTime) {
        dt = date;
      } else if (date is String) {
        dt = DateTime.parse(date);
      } else {
        return date.toString();
      }
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (e) {
      return date.toString();
    }
  }

  String _parseDateForTally(dynamic date) {
    if (date == null) return DateFormat('yyyyMMdd').format(DateTime.now());
    try {
      DateTime dt;
      if (date is DateTime) {
        dt = date;
      } else if (date is String) {
        dt = DateTime.parse(date);
      } else {
        return DateFormat('yyyyMMdd').format(DateTime.now());
      }
      return DateFormat('yyyyMMdd').format(dt);
    } catch (e) {
      return DateFormat('yyyyMMdd').format(DateTime.now());
    }
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

// ============================================================================
// EXPORT RESULT MODEL
// ============================================================================

class ExportResult {
  final String filePath;
  final int recordCount;
  final String exportType;
  final ExportFormat format;
  final String targetApp;
  final DateTime exportedAt;

  ExportResult({
    required this.filePath,
    required this.recordCount,
    required this.exportType,
    required this.format,
    required this.targetApp,
    DateTime? exportedAt,
  }) : exportedAt = exportedAt ?? DateTime.now();
}

// ============================================================================
// EXPORT CONFIG MODEL
// ============================================================================

class ExportConfig {
  final String name;
  final String description;
  final List<ExportFormat> supportedFormats;
  final String fileExtension;

  ExportConfig({
    required this.name,
    required this.description,
    required this.supportedFormats,
    required this.fileExtension,
  });
}
