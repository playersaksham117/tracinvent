# Stock Search & Traceability Implementation
## Complete Code Implementation Guide

---

## 1. STOCK SEARCH SERVICE
**File**: `lib/services/stock_search_service.dart`

This is the backbone for fast, global stock searches across all warehouses and locations.

```dart
import 'database_service.dart';
import '../models/inventory_item.dart';

class LocationStockDetail {
  final String stockId;
  final String warehouseId;
  final String warehouseName;
  final String? zoneId;
  final String? zoneName;
  final String? rackId;
  final String? rackName;
  final String? shelfId;
  final String? shelfName;
  final String? binId;
  final String? binName;
  final double quantity;
  final String? batchNumber;
  final DateTime? expiryDate;
  final DateTime? lastUpdated;

  String get locationPath {
    final parts = <String>[warehouseName];
    if (zoneName != null) parts.add(zoneName!);
    if (rackName != null) parts.add(rackName!);
    if (shelfName != null) parts.add(shelfName!);
    if (binName != null) parts.add(binName!);
    return parts.join(' / ');
  }

  String get hierarchyLevel {
    if (binName != null) return 'Bin';
    if (shelfName != null) return 'Shelf';
    if (rackName != null) return 'Rack';
    if (zoneName != null) return 'Zone';
    return 'Warehouse';
  }

  LocationStockDetail({
    required this.stockId,
    required this.warehouseId,
    required this.warehouseName,
    this.zoneId,
    this.zoneName,
    this.rackId,
    this.rackName,
    this.shelfId,
    this.shelfName,
    this.binId,
    this.binName,
    required this.quantity,
    this.batchNumber,
    this.expiryDate,
    this.lastUpdated,
  });

  factory LocationStockDetail.fromMap(Map<String, dynamic> map) {
    return LocationStockDetail(
      stockId: map['id'] as String,
      warehouseId: map['warehouseId'] as String,
      warehouseName: map['warehouseName'] as String,
      zoneId: map['zoneId'] as String?,
      zoneName: map['zoneName'] as String?,
      rackId: map['rackId'] as String?,
      rackName: map['rackName'] as String?,
      shelfId: map['shelfId'] as String?,
      shelfName: map['shelfName'] as String?,
      binId: map['binId'] as String?,
      binName: map['binName'] as String?,
      quantity: (map['quantity'] as num).toDouble(),
      batchNumber: map['batchNumber'] as String?,
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate'] as String) : null,
      lastUpdated: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }
}

class StockSearchResult {
  final String itemId;
  final String itemName;
  final String sku;
  final String? barcode;
  final String category;
  final String unit;
  final double costPrice;
  final double sellingPrice;
  final double totalQuantity;
  final List<LocationStockDetail> locations;
  final bool isLowStock;
  final bool isCritical;
  final double reorderLevel;

  StockSearchResult({
    required this.itemId,
    required this.itemName,
    required this.sku,
    this.barcode,
    required this.category,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.totalQuantity,
    required this.locations,
    required this.isLowStock,
    required this.isCritical,
    required this.reorderLevel,
  });

  double get totalValue => totalQuantity * costPrice;
  double get totalSaleValue => totalQuantity * sellingPrice;
  double get estimatedProfit => totalSaleValue - totalValue;

  int get warehouseCount => locations.map((l) => l.warehouseId).toSet().length;
  int get locationCount => locations.length;
}

/// Core stock search service with fast, indexed searches
class StockSearchService {
  
  /// GLOBAL SEARCH: Find items by SKU, Name, or Barcode
  /// Returns items with all their locations and quantities
  static Future<List<StockSearchResult>> globalSearch(String query) async {
    final db = await DatabaseService.database;
    final searchTerm = '%$query%';

    try {
      // Search by SKU, Item Name, or Barcode
      final itemResults = await db.rawQuery('''
        SELECT DISTINCT
          ii.id,
          ii.sku,
          ii.name,
          ii.barcode,
          ii.category,
          ii.unit,
          ii.costPrice,
          ii.sellingPrice,
          ii.reorderLevel,
          COALESCE(SUM(st.quantity), 0) as totalQuantity
        FROM inventory_items ii
        LEFT JOIN stocks st ON ii.id = st.itemId
        WHERE ii.sku LIKE ? OR ii.name LIKE ? OR ii.barcode LIKE ?
        GROUP BY ii.id
        ORDER BY ii.name ASC
      ''', [searchTerm, searchTerm, searchTerm]);

      List<StockSearchResult> results = [];

      for (var item in itemResults) {
        final itemId = item['id'] as String;
        final totalQty = (item['totalQuantity'] as num).toDouble();

        // Get all locations for this item
        final locations = await _getItemLocations(itemId);

        results.add(StockSearchResult(
          itemId: itemId,
          itemName: item['name'] as String,
          sku: item['sku'] as String,
          barcode: item['barcode'] as String?,
          category: item['category'] as String,
          unit: item['unit'] as String,
          costPrice: (item['costPrice'] as num).toDouble(),
          sellingPrice: (item['sellingPrice'] as num).toDouble(),
          totalQuantity: totalQty,
          locations: locations,
          isLowStock: totalQty <= (item['reorderLevel'] as num).toDouble(),
          isCritical: totalQty <= ((item['reorderLevel'] as num).toDouble() * 0.5),
          reorderLevel: (item['reorderLevel'] as num).toDouble(),
        ));
      }

      return results;
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  /// SEARCH BY SKU ONLY (Fast exact match)
  static Future<StockSearchResult?> searchBySku(String sku) async {
    final db = await DatabaseService.database;

    try {
      final results = await db.rawQuery('''
        SELECT
          ii.id,
          ii.sku,
          ii.name,
          ii.barcode,
          ii.category,
          ii.unit,
          ii.costPrice,
          ii.sellingPrice,
          ii.reorderLevel,
          COALESCE(SUM(st.quantity), 0) as totalQuantity
        FROM inventory_items ii
        LEFT JOIN stocks st ON ii.id = st.itemId
        WHERE ii.sku = ?
        GROUP BY ii.id
      ''', [sku]);

      if (results.isEmpty) return null;

      final item = results.first;
      final itemId = item['id'] as String;
      final locations = await _getItemLocations(itemId);

      return StockSearchResult(
        itemId: itemId,
        itemName: item['name'] as String,
        sku: item['sku'] as String,
        barcode: item['barcode'] as String?,
        category: item['category'] as String,
        unit: item['unit'] as String,
        costPrice: (item['costPrice'] as num).toDouble(),
        sellingPrice: (item['sellingPrice'] as num).toDouble(),
        totalQuantity: (item['totalQuantity'] as num).toDouble(),
        locations: locations,
        isLowStock: (item['totalQuantity'] as num).toDouble() <= (item['reorderLevel'] as num).toDouble(),
        isCritical: (item['totalQuantity'] as num).toDouble() <= ((item['reorderLevel'] as num).toDouble() * 0.5),
        reorderLevel: (item['reorderLevel'] as num).toDouble(),
      );
    } catch (e) {
      throw Exception('SKU search failed: $e');
    }
  }

  /// SEARCH BY BARCODE (Fast exact match)
  static Future<StockSearchResult?> searchByBarcode(String barcode) async {
    final db = await DatabaseService.database;

    try {
      final results = await db.rawQuery('''
        SELECT
          ii.id,
          ii.sku,
          ii.name,
          ii.barcode,
          ii.category,
          ii.unit,
          ii.costPrice,
          ii.sellingPrice,
          ii.reorderLevel,
          COALESCE(SUM(st.quantity), 0) as totalQuantity
        FROM inventory_items ii
        LEFT JOIN stocks st ON ii.id = st.itemId
        WHERE ii.barcode = ?
        GROUP BY ii.id
      ''', [barcode]);

      if (results.isEmpty) return null;

      final item = results.first;
      final itemId = item['id'] as String;
      final locations = await _getItemLocations(itemId);

      return StockSearchResult(
        itemId: itemId,
        itemName: item['name'] as String,
        sku: item['sku'] as String,
        barcode: item['barcode'] as String?,
        category: item['category'] as String,
        unit: item['unit'] as String,
        costPrice: (item['costPrice'] as num).toDouble(),
        sellingPrice: (item['sellingPrice'] as num).toDouble(),
        totalQuantity: (item['totalQuantity'] as num).toDouble(),
        locations: locations,
        isLowStock: (item['totalQuantity'] as num).toDouble() <= (item['reorderLevel'] as num).toDouble(),
        isCritical: (item['totalQuantity'] as num).toDouble() <= ((item['reorderLevel'] as num).toDouble() * 0.5),
        reorderLevel: (item['reorderLevel'] as num).toDouble(),
      );
    } catch (e) {
      throw Exception('Barcode search failed: $e');
    }
  }

  /// Get all locations where an item is stored with quantities
  static Future<List<LocationStockDetail>> _getItemLocations(String itemId) async {
    final db = await DatabaseService.database;

    try {
      final results = await db.rawQuery('''
        SELECT
          st.id,
          st.quantity,
          st.batchNumber,
          st.expiryDate,
          st.updatedAt,
          w.id as warehouseId,
          w.name as warehouseName,
          z.id as zoneId,
          z.name as zoneName,
          r.id as rackId,
          r.name as rackName,
          sh.id as shelfId,
          sh.name as shelfName,
          b.id as binId,
          b.name as binName
        FROM stocks st
        INNER JOIN warehouses w ON st.warehouseId = w.id
        LEFT JOIN zones z ON st.zoneId = z.id
        LEFT JOIN racks r ON st.rackId = r.id
        LEFT JOIN shelves sh ON st.shelfId = sh.id
        LEFT JOIN bins b ON st.binId = b.id
        WHERE st.itemId = ? AND st.quantity > 0
        ORDER BY w.name, z.name, r.name, sh.name, b.name
      ''', [itemId]);

      return results.map((m) => LocationStockDetail.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Location query failed: $e');
    }
  }

  /// Get stock at specific location
  static Future<double> getLocationStock({
    required String itemId,
    required String warehouseId,
    String? zoneId,
    String? rackId,
    String? shelfId,
    String? binId,
  }) async {
    final db = await DatabaseService.database;

    try {
      String query = 'SELECT SUM(quantity) as total FROM stocks WHERE itemId = ? AND warehouseId = ?';
      List<dynamic> args = [itemId, warehouseId];

      if (zoneId != null) {
        query += ' AND zoneId = ?';
        args.add(zoneId);
      }
      if (rackId != null) {
        query += ' AND rackId = ?';
        args.add(rackId);
      }
      if (shelfId != null) {
        query += ' AND shelfId = ?';
        args.add(shelfId);
      }
      if (binId != null) {
        query += ' AND binId = ?';
        args.add(binId);
      }

      final result = await db.rawQuery(query, args);
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Stock query failed: $e');
    }
  }

  /// Get stock summary by warehouse for an item
  static Future<List<Map<String, dynamic>>> getItemStockByWarehouse(String itemId) async {
    final db = await DatabaseService.database;

    try {
      return await db.rawQuery('''
        SELECT
          w.id,
          w.name,
          w.code,
          COALESCE(SUM(st.quantity), 0) as totalQuantity,
          COUNT(DISTINCT st.id) as locationCount
        FROM warehouses w
        LEFT JOIN stocks st ON w.id = st.warehouseId AND st.itemId = ?
        GROUP BY w.id
        ORDER BY w.name
      ''', [itemId]);
    } catch (e) {
      throw Exception('Warehouse stock query failed: $e');
    }
  }

  /// Get recent stock movements for an item (last N transactions)
  static Future<List<Map<String, dynamic>>> getItemMovementHistory(
    String itemId, {
    int limit = 10,
  }) async {
    final db = await DatabaseService.database;

    try {
      return await db.rawQuery('''
        SELECT
          t.id,
          t.type,
          t.quantity,
          t.unitPrice,
          t.totalAmount,
          t.transactionDate,
          t.referenceNumber,
          w.name as warehouseName
        FROM transactions t
        INNER JOIN warehouses w ON t.warehouseId = w.id
        WHERE t.itemId = ?
        ORDER BY t.transactionDate DESC
        LIMIT ?
      ''', [itemId, limit]);
    } catch (e) {
      throw Exception('Movement history query failed: $e');
    }
  }

  /// Find out-of-stock locations for an item
  static Future<List<Map<String, dynamic>>> getOutOfStockLocations() async {
    final db = await DatabaseService.database;

    try {
      return await db.rawQuery('''
        SELECT
          ii.id,
          ii.sku,
          ii.name,
          COUNT(DISTINCT w.id) as warehouseCount
        FROM inventory_items ii
        LEFT JOIN stocks st ON ii.id = st.itemId
        LEFT JOIN warehouses w ON st.warehouseId = w.id
        WHERE COALESCE(SUM(st.quantity), 0) = 0
        GROUP BY ii.id
        ORDER BY ii.name
      ''');
    } catch (e) {
      throw Exception('Out of stock query failed: $e');
    }
  }

  /// Fast text search with wildcard support
  static Future<List<StockSearchResult>> advancedSearch({
    String? skuPattern,
    String? namePattern,
    String? category,
    String? warehouseId,
    bool? isLowStock,
    bool? isCritical,
  }) async {
    final db = await DatabaseService.database;
    String query = '''
      SELECT DISTINCT
        ii.id,
        ii.sku,
        ii.name,
        ii.barcode,
        ii.category,
        ii.unit,
        ii.costPrice,
        ii.sellingPrice,
        ii.reorderLevel,
        COALESCE(SUM(st.quantity), 0) as totalQuantity
      FROM inventory_items ii
      LEFT JOIN stocks st ON ii.id = st.itemId
      WHERE 1=1
    ''';

    List<dynamic> args = [];

    if (skuPattern != null) {
      query += ' AND ii.sku LIKE ?';
      args.add('%$skuPattern%');
    }

    if (namePattern != null) {
      query += ' AND ii.name LIKE ?';
      args.add('%$namePattern%');
    }

    if (category != null) {
      query += ' AND ii.category = ?';
      args.add(category);
    }

    if (warehouseId != null) {
      query += ' AND st.warehouseId = ?';
      args.add(warehouseId);
    }

    query += ' GROUP BY ii.id';

    if (isLowStock == true) {
      query += ' HAVING totalQuantity <= ii.reorderLevel';
    }

    if (isCritical == true) {
      query += ' HAVING totalQuantity <= (ii.reorderLevel * 0.5)';
    }

    query += ' ORDER BY ii.name';

    try {
      final itemResults = await db.rawQuery(query, args);
      List<StockSearchResult> results = [];

      for (var item in itemResults) {
        final itemId = item['id'] as String;
        final totalQty = (item['totalQuantity'] as num).toDouble();
        final locations = await _getItemLocations(itemId);

        results.add(StockSearchResult(
          itemId: itemId,
          itemName: item['name'] as String,
          sku: item['sku'] as String,
          barcode: item['barcode'] as String?,
          category: item['category'] as String,
          unit: item['unit'] as String,
          costPrice: (item['costPrice'] as num).toDouble(),
          sellingPrice: (item['sellingPrice'] as num).toDouble(),
          totalQuantity: totalQty,
          locations: locations,
          isLowStock: totalQty <= (item['reorderLevel'] as num).toDouble(),
          isCritical: totalQty <= ((item['reorderLevel'] as num).toDouble() * 0.5),
          reorderLevel: (item['reorderLevel'] as num).toDouble(),
        ));
      }

      return results;
    } catch (e) {
      throw Exception('Advanced search failed: $e');
    }
  }
}
```

---

## 2. STOCK SEARCH PROVIDER
**File**: `lib/providers/stock_search_provider.dart`

Manages search state and UI updates.

```dart
import 'package:flutter/foundation.dart';
import '../services/stock_search_service.dart';

class StockSearchProvider with ChangeNotifier {
  List<StockSearchResult> _searchResults = [];
  StockSearchResult? _selectedResult;
  bool _isSearching = false;
  String _lastQuery = '';
  String? _lastError;
  
  List<StockSearchResult> get searchResults => _searchResults;
  StockSearchResult? get selectedResult => _selectedResult;
  bool get isSearching => _isSearching;
  String? get lastError => _lastError;

  /// Global search by SKU, name, or barcode
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _lastQuery = '';
      _lastError = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _lastQuery = query;
    _lastError = null;
    notifyListeners();

    try {
      _searchResults = await StockSearchService.globalSearch(query);
    } catch (e) {
      _lastError = e.toString();
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Quick search by SKU
  Future<void> searchBySku(String sku) async {
    _isSearching = true;
    _lastError = null;
    notifyListeners();

    try {
      final result = await StockSearchService.searchBySku(sku);
      if (result != null) {
        _searchResults = [result];
        _selectedResult = result;
      } else {
        _searchResults = [];
        _lastError = 'SKU not found';
      }
    } catch (e) {
      _lastError = e.toString();
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Quick search by barcode
  Future<void> searchByBarcode(String barcode) async {
    _isSearching = true;
    _lastError = null;
    notifyListeners();

    try {
      final result = await StockSearchService.searchByBarcode(barcode);
      if (result != null) {
        _searchResults = [result];
        _selectedResult = result;
      } else {
        _searchResults = [];
        _lastError = 'Barcode not found';
      }
    } catch (e) {
      _lastError = e.toString();
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Advanced search with filters
  Future<void> advancedSearch({
    String? skuPattern,
    String? namePattern,
    String? category,
    String? warehouseId,
    bool? isLowStock,
    bool? isCritical,
  }) async {
    _isSearching = true;
    _lastError = null;
    notifyListeners();

    try {
      _searchResults = await StockSearchService.advancedSearch(
        skuPattern: skuPattern,
        namePattern: namePattern,
        category: category,
        warehouseId: warehouseId,
        isLowStock: isLowStock,
        isCritical: isCritical,
      );
    } catch (e) {
      _lastError = e.toString();
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Select a result to view details
  void selectResult(StockSearchResult result) {
    _selectedResult = result;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchResults = [];
    _selectedResult = null;
    _lastQuery = '';
    _lastError = null;
    notifyListeners();
  }
}
```

This implementation provides enterprise-grade stock search. Shall I continue with the **Stock Search UI Screen** and **Enhanced Dashboard**?
