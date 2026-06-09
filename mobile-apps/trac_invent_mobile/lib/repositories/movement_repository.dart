import '../models/movement.dart';
import '../core/constants.dart';
import 'base_repository.dart';

/// Repository for movement history operations
class MovementRepository extends BaseRepository<Movement> {
  @override
  String get tableName => 'movements';
  
  @override
  Movement fromMap(Map<String, dynamic> map) => Movement.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(Movement item) => item.toMap();
  
  /// Get movements with full details
  Future<List<Movement>> getMovementsWithDetails({
    MovementFilter? filter,
  }) async {
    var sql = '''
      SELECT 
        m.*,
        i.name as item_name,
        i.sku as item_sku,
        fl.code as from_location_code,
        tl.code as to_location_code,
        fw.name as from_warehouse_name,
        tw.name as to_warehouse_name,
        u.full_name as user_name
      FROM movements m
      INNER JOIN inventory_items i ON m.item_id = i.id
      LEFT JOIN locations fl ON m.from_location_id = fl.id
      LEFT JOIN locations tl ON m.to_location_id = tl.id
      LEFT JOIN warehouses fw ON fl.warehouse_id = fw.id
      LEFT JOIN warehouses tw ON tl.warehouse_id = tw.id
      LEFT JOIN users u ON m.user_id = u.id
      WHERE 1=1
    ''';
    
    final args = <Object?>[];
    
    if (filter != null) {
      if (filter.itemId != null) {
        sql += ' AND m.item_id = ?';
        args.add(filter.itemId);
      }
      
      if (filter.locationId != null) {
        sql += ' AND (m.from_location_id = ? OR m.to_location_id = ?)';
        args.addAll([filter.locationId, filter.locationId]);
      }
      
      if (filter.warehouseId != null) {
        sql += ' AND (fl.warehouse_id = ? OR tl.warehouse_id = ?)';
        args.addAll([filter.warehouseId, filter.warehouseId]);
      }
      
      if (filter.type != null) {
        sql += ' AND m.type = ?';
        args.add(filter.type);
      }
      
      if (filter.userId != null) {
        sql += ' AND m.user_id = ?';
        args.add(filter.userId);
      }
      
      if (filter.fromDate != null) {
        sql += ' AND m.created_at >= ?';
        args.add(filter.fromDate!.toIso8601String());
      }
      
      if (filter.toDate != null) {
        sql += ' AND m.created_at <= ?';
        args.add(filter.toDate!.toIso8601String());
      }
      
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        sql += ' AND (i.name LIKE ? OR i.sku LIKE ? OR m.reference_number LIKE ?)';
        args.addAll([
          '%${filter.searchQuery}%',
          '%${filter.searchQuery}%',
          '%${filter.searchQuery}%',
        ]);
      }
      
      sql += ' ORDER BY m.created_at DESC LIMIT ? OFFSET ?';
      args.addAll([filter.limit, filter.offset]);
    } else {
      sql += ' ORDER BY m.created_at DESC LIMIT 50';
    }
    
    final maps = await rawQuery(sql, args);
    return maps.map((map) => Movement.fromMap(map)).toList();
  }
  
  /// Get recent movements
  Future<List<Movement>> getRecentMovements({int limit = 10}) async {
    return getMovementsWithDetails(
      filter: MovementFilter(limit: limit, offset: 0),
    );
  }
  
  /// Get movements for an item
  Future<List<Movement>> getByItem(String itemId, {int limit = 50, int offset = 0}) async {
    return getMovementsWithDetails(
      filter: MovementFilter(itemId: itemId, limit: limit, offset: offset),
    );
  }
  
  /// Get movements for a location
  Future<List<Movement>> getByLocation(String locationId, {int limit = 50, int offset = 0}) async {
    return getMovementsWithDetails(
      filter: MovementFilter(locationId: locationId, limit: limit, offset: offset),
    );
  }
  
  /// Get movements by type
  Future<List<Movement>> getByType(String type, {int limit = 50, int offset = 0}) async {
    return getMovementsWithDetails(
      filter: MovementFilter(type: type, limit: limit, offset: offset),
    );
  }
  
  /// Get today's movements
  Future<List<Movement>> getTodayMovements() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getMovementsWithDetails(
      filter: MovementFilter(
        fromDate: startOfDay,
        toDate: endOfDay,
        limit: 100,
      ),
    );
  }
  
  /// Get movement counts by type for date range
  Future<Map<String, int>> getCountsByType({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var sql = '''
      SELECT type, COUNT(*) as count
      FROM movements
      WHERE 1=1
    ''';
    final args = <Object?>[];
    
    if (fromDate != null) {
      sql += ' AND created_at >= ?';
      args.add(fromDate.toIso8601String());
    }
    
    if (toDate != null) {
      sql += ' AND created_at <= ?';
      args.add(toDate.toIso8601String());
    }
    
    sql += ' GROUP BY type';
    
    final result = await rawQuery(sql, args);
    final counts = <String, int>{};
    for (final row in result) {
      counts[row['type'] as String] = (row['count'] as int?) ?? 0;
    }
    return counts;
  }
  
  /// Get total quantities moved by type for date range
  Future<Map<String, double>> getQuantitiesByType({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var sql = '''
      SELECT type, COALESCE(SUM(quantity), 0) as total
      FROM movements
      WHERE 1=1
    ''';
    final args = <Object?>[];
    
    if (fromDate != null) {
      sql += ' AND created_at >= ?';
      args.add(fromDate.toIso8601String());
    }
    
    if (toDate != null) {
      sql += ' AND created_at <= ?';
      args.add(toDate.toIso8601String());
    }
    
    sql += ' GROUP BY type';
    
    final result = await rawQuery(sql, args);
    final quantities = <String, double>{};
    for (final row in result) {
      quantities[row['type'] as String] = (row['total'] as num?)?.toDouble() ?? 0;
    }
    return quantities;
  }
  
  /// Generate next reference number
  Future<String> generateReferenceNumber(String type) async {
    final today = DateTime.now();
    final prefix = switch (type) {
      MovementType.stockIn => 'SI',
      MovementType.stockOut => 'SO',
      MovementType.transfer => 'TR',
      MovementType.adjustment => 'AD',
      MovementType.cycleCount => 'CC',
      _ => 'MV',
    };
    
    final datePrefix = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    
    // Get count for today
    final startOfDay = DateTime(today.year, today.month, today.day);
    final count = await rawQuery('''
      SELECT COUNT(*) as count FROM movements
      WHERE type = ? AND created_at >= ?
    ''', [type, startOfDay.toIso8601String()]);
    
    final sequence = ((count.first['count'] as int?) ?? 0) + 1;
    
    return '$prefix-$datePrefix-${sequence.toString().padLeft(4, '0')}';
  }
  
  /// Get movement summary statistics
  Future<Map<String, dynamic>> getStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var whereClause = '';
    final args = <Object?>[];
    
    if (fromDate != null) {
      whereClause += ' AND created_at >= ?';
      args.add(fromDate.toIso8601String());
    }
    
    if (toDate != null) {
      whereClause += ' AND created_at <= ?';
      args.add(toDate.toIso8601String());
    }
    
    final result = await rawQuery('''
      SELECT
        COUNT(*) as total_movements,
        SUM(CASE WHEN type = 'STOCK_IN' THEN quantity ELSE 0 END) as total_stock_in,
        SUM(CASE WHEN type = 'STOCK_OUT' THEN quantity ELSE 0 END) as total_stock_out,
        SUM(CASE WHEN type = 'TRANSFER' THEN quantity ELSE 0 END) as total_transferred,
        SUM(CASE WHEN type = 'ADJUSTMENT' THEN quantity ELSE 0 END) as total_adjusted,
        COUNT(DISTINCT item_id) as unique_items,
        COUNT(DISTINCT user_id) as unique_users
      FROM movements
      WHERE 1=1 $whereClause
    ''', args);
    
    return result.first;
  }
}
