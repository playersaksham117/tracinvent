import '../models/stock.dart';
import 'base_repository.dart';

/// Repository for stock operations
class StockRepository extends BaseRepository<Stock> {
  @override
  String get tableName => 'stock';
  
  @override
  Stock fromMap(Map<String, dynamic> map) => Stock.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(Stock item) => item.toMap();
  
  /// Get stock by item and location
  Future<Stock?> getByItemAndLocation(
    String itemId, 
    String locationId, {
    String? batchNumber,
  }) async {
    var where = 'item_id = ? AND location_id = ?';
    final whereArgs = <Object?>[itemId, locationId];
    
    if (batchNumber != null) {
      where += ' AND batch_number = ?';
      whereArgs.add(batchNumber);
    } else {
      where += ' AND batch_number IS NULL';
    }
    
    final stocks = await getAll(where: where, whereArgs: whereArgs);
    return stocks.isEmpty ? null : stocks.first;
  }
  
  /// Get all stock for an item with location details
  Future<List<Stock>> getByItemWithDetails(String itemId) async {
    final maps = await rawQuery('''
      SELECT 
        s.*,
        i.name as item_name,
        i.sku as item_sku,
        i.barcode as item_barcode,
        i.reorder_level,
        i.min_level,
        i.unit,
        l.code as location_code,
        l.warehouse_id,
        w.name as warehouse_name
      FROM stock s
      INNER JOIN inventory_items i ON s.item_id = i.id
      INNER JOIN locations l ON s.location_id = l.id
      INNER JOIN warehouses w ON l.warehouse_id = w.id
      WHERE s.item_id = ? AND s.quantity > 0
      ORDER BY w.name, l.code ASC
    ''', [itemId]);
    
    return maps.map((map) => Stock.fromMap(map)).toList();
  }
  
  /// Get all stock at a location with item details
  Future<List<Stock>> getByLocationWithDetails(String locationId) async {
    final maps = await rawQuery('''
      SELECT 
        s.*,
        i.name as item_name,
        i.sku as item_sku,
        i.barcode as item_barcode,
        i.reorder_level,
        i.min_level,
        i.unit,
        l.code as location_code,
        l.warehouse_id,
        w.name as warehouse_name
      FROM stock s
      INNER JOIN inventory_items i ON s.item_id = i.id
      INNER JOIN locations l ON s.location_id = l.id
      INNER JOIN warehouses w ON l.warehouse_id = w.id
      WHERE s.location_id = ? AND s.quantity > 0
      ORDER BY i.name ASC
    ''', [locationId]);
    
    return maps.map((map) => Stock.fromMap(map)).toList();
  }
  
  /// Get stock by warehouse with details
  Future<List<Stock>> getByWarehouseWithDetails(String warehouseId) async {
    final maps = await rawQuery('''
      SELECT 
        s.*,
        i.name as item_name,
        i.sku as item_sku,
        i.barcode as item_barcode,
        i.reorder_level,
        i.min_level,
        i.unit,
        l.code as location_code,
        l.warehouse_id,
        w.name as warehouse_name
      FROM stock s
      INNER JOIN inventory_items i ON s.item_id = i.id
      INNER JOIN locations l ON s.location_id = l.id
      INNER JOIN warehouses w ON l.warehouse_id = w.id
      WHERE l.warehouse_id = ? AND s.quantity > 0
      ORDER BY i.name, l.code ASC
    ''', [warehouseId]);
    
    return maps.map((map) => Stock.fromMap(map)).toList();
  }
  
  /// Get total quantity for an item across all locations
  Future<double> getTotalQuantity(String itemId) async {
    final result = await rawQuery('''
      SELECT COALESCE(SUM(quantity), 0) as total
      FROM stock
      WHERE item_id = ?
    ''', [itemId]);
    
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
  
  /// Get stock summaries for all items
  Future<List<StockSummary>> getStockSummaries({
    String? searchQuery,
    String? warehouseId,
    int limit = 50,
    int offset = 0,
  }) async {
    var sql = '''
      SELECT 
        i.id as item_id,
        i.name as item_name,
        i.sku as item_sku,
        i.barcode as item_barcode,
        i.unit,
        i.reorder_level,
        i.min_level,
        COALESCE(SUM(s.quantity), 0) as total_quantity,
        COUNT(DISTINCT s.location_id) as location_count,
        COUNT(DISTINCT l.warehouse_id) as warehouse_count
      FROM inventory_items i
      LEFT JOIN stock s ON i.id = s.item_id
      LEFT JOIN locations l ON s.location_id = l.id
      WHERE i.is_active = 1
    ''';
    
    final args = <Object?>[];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      sql += ' AND (i.name LIKE ? OR i.sku LIKE ? OR i.barcode LIKE ?)';
      args.addAll(['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']);
    }
    
    if (warehouseId != null) {
      sql += ' AND l.warehouse_id = ?';
      args.add(warehouseId);
    }
    
    sql += ' GROUP BY i.id ORDER BY i.name ASC LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);
    
    final maps = await rawQuery(sql, args);
    return maps.map((map) => StockSummary.fromMap(map)).toList();
  }
  
  /// Get expiring stock
  Future<List<Stock>> getExpiringStock({int daysAhead = 30}) async {
    final expiryDate = DateTime.now().add(Duration(days: daysAhead));
    
    final maps = await rawQuery('''
      SELECT 
        s.*,
        i.name as item_name,
        i.sku as item_sku,
        i.barcode as item_barcode,
        i.unit,
        l.code as location_code,
        l.warehouse_id,
        w.name as warehouse_name
      FROM stock s
      INNER JOIN inventory_items i ON s.item_id = i.id
      INNER JOIN locations l ON s.location_id = l.id
      INNER JOIN warehouses w ON l.warehouse_id = w.id
      WHERE s.expiry_date IS NOT NULL 
        AND s.expiry_date <= ?
        AND s.quantity > 0
      ORDER BY s.expiry_date ASC
    ''', [expiryDate.toIso8601String()]);
    
    return maps.map((map) => Stock.fromMap(map)).toList();
  }
  
  /// Update stock quantity (atomic operation)
  Future<bool> updateQuantity(
    String itemId,
    String locationId,
    double newQuantity, {
    String? batchNumber,
  }) async {
    await transaction((txn) async {
      // Find existing stock record
      var where = 'item_id = ? AND location_id = ?';
      final whereArgs = <Object?>[itemId, locationId];
      
      if (batchNumber != null) {
        where += ' AND batch_number = ?';
        whereArgs.add(batchNumber);
      } else {
        where += ' AND batch_number IS NULL';
      }
      
      final existing = await txn.query(tableName, where: where, whereArgs: whereArgs);
      
      if (existing.isEmpty) {
        // Create new stock record if quantity > 0
        if (newQuantity > 0) {
          final now = DateTime.now().toIso8601String();
          await txn.insert(tableName, {
            'id': 'stk_${DateTime.now().millisecondsSinceEpoch}',
            'item_id': itemId,
            'location_id': locationId,
            'quantity': newQuantity,
            'batch_number': batchNumber,
            'created_at': now,
            'updated_at': now,
          });
        }
      } else {
        final stockId = existing.first['id'] as String;
        if (newQuantity <= 0) {
          // Delete record if quantity is 0 or less
          await txn.delete(tableName, where: 'id = ?', whereArgs: [stockId]);
        } else {
          // Update quantity
          await txn.update(
            tableName,
            {
              'quantity': newQuantity,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [stockId],
          );
        }
      }
    });
    
    return true;
  }
  
  /// Adjust stock quantity (add or subtract)
  Future<double> adjustQuantity(
    String itemId,
    String locationId,
    double delta, {
    String? batchNumber,
  }) async {
    return await transaction((txn) async {
      var where = 'item_id = ? AND location_id = ?';
      final whereArgs = <Object?>[itemId, locationId];
      
      if (batchNumber != null) {
        where += ' AND batch_number = ?';
        whereArgs.add(batchNumber);
      } else {
        where += ' AND batch_number IS NULL';
      }
      
      final existing = await txn.query(tableName, where: where, whereArgs: whereArgs);
      final currentQty = existing.isEmpty 
          ? 0.0 
          : (existing.first['quantity'] as num).toDouble();
      
      final newQty = currentQty + delta;
      
      if (newQty < 0) {
        throw Exception('Insufficient stock: available $currentQty, requested ${-delta}');
      }
      
      final now = DateTime.now().toIso8601String();
      
      if (existing.isEmpty && newQty > 0) {
        await txn.insert(tableName, {
          'id': 'stk_${DateTime.now().millisecondsSinceEpoch}',
          'item_id': itemId,
          'location_id': locationId,
          'quantity': newQty,
          'batch_number': batchNumber,
          'created_at': now,
          'updated_at': now,
        });
      } else if (!existing.isEmpty) {
        final stockId = existing.first['id'] as String;
        if (newQty <= 0) {
          await txn.delete(tableName, where: 'id = ?', whereArgs: [stockId]);
        } else {
          await txn.update(
            tableName,
            {'quantity': newQty, 'updated_at': now},
            where: 'id = ?',
            whereArgs: [stockId],
          );
        }
      }
      
      return newQty;
    });
  }
  
  /// Delete all stock for an item
  Future<int> deleteByItem(String itemId) async {
    return deleteWhere(where: 'item_id = ?', whereArgs: [itemId]);
  }
  
  /// Delete all stock for a location
  Future<int> deleteByLocation(String locationId) async {
    return deleteWhere(where: 'location_id = ?', whereArgs: [locationId]);
  }
}
