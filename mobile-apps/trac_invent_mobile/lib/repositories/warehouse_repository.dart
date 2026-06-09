import '../models/warehouse.dart';
import 'base_repository.dart';

/// Repository for warehouse operations
class WarehouseRepository extends BaseRepository<Warehouse> {
  @override
  String get tableName => 'warehouses';
  
  @override
  Warehouse fromMap(Map<String, dynamic> map) => Warehouse.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(Warehouse item) => item.toMap();
  
  /// Get all warehouses with statistics
  Future<List<Warehouse>> getAllWithStats() async {
    final maps = await rawQuery('''
      SELECT 
        w.*,
        (SELECT COUNT(*) FROM locations WHERE warehouse_id = w.id AND type = 'ZONE') as zone_count,
        (SELECT COUNT(DISTINCT s.item_id) FROM stock s 
         INNER JOIN locations l ON s.location_id = l.id 
         WHERE l.warehouse_id = w.id AND s.quantity > 0) as item_count,
        (SELECT COALESCE(SUM(s.quantity), 0) FROM stock s 
         INNER JOIN locations l ON s.location_id = l.id 
         WHERE l.warehouse_id = w.id) as used_capacity
      FROM warehouses w
      WHERE w.is_active = 1
      ORDER BY w.name ASC
    ''');
    return maps.map((map) => Warehouse.fromMap(map)).toList();
  }
  
  /// Get warehouse by code
  Future<Warehouse?> getByCode(String code) async {
    final warehouses = await getAll(
      where: 'code = ?',
      whereArgs: [code],
    );
    return warehouses.isEmpty ? null : warehouses.first;
  }
  
  /// Get warehouse with details by ID
  Future<Warehouse?> getByIdWithStats(String id) async {
    final maps = await rawQuery('''
      SELECT 
        w.*,
        (SELECT COUNT(*) FROM locations WHERE warehouse_id = w.id AND type = 'ZONE') as zone_count,
        (SELECT COUNT(DISTINCT s.item_id) FROM stock s 
         INNER JOIN locations l ON s.location_id = l.id 
         WHERE l.warehouse_id = w.id AND s.quantity > 0) as item_count,
        (SELECT COALESCE(SUM(s.quantity), 0) FROM stock s 
         INNER JOIN locations l ON s.location_id = l.id 
         WHERE l.warehouse_id = w.id) as used_capacity
      FROM warehouses w
      WHERE w.id = ?
    ''', [id]);
    
    if (maps.isEmpty) return null;
    return Warehouse.fromMap(maps.first);
  }
  
  /// Get active warehouses
  Future<List<Warehouse>> getActiveWarehouses() async {
    return getAll(
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
  }
  
  /// Check if code exists
  Future<bool> codeExists(String code, {String? excludeId}) async {
    var sql = 'SELECT COUNT(*) as count FROM $tableName WHERE code = ?';
    final args = <Object?>[code];
    
    if (excludeId != null) {
      sql += ' AND id != ?';
      args.add(excludeId);
    }
    
    final result = await rawQuery(sql, args);
    return (result.first['count'] as int) > 0;
  }
}

/// Repository for location operations (Zone → Rack → Shelf → Bin)
class LocationRepository extends BaseRepository<Location> {
  @override
  String get tableName => 'locations';
  
  @override
  Location fromMap(Map<String, dynamic> map) => Location.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(Location item) => item.toMap();
  
  /// Get locations by warehouse
  Future<List<Location>> getByWarehouse(
    String warehouseId, {
    String? type,
    bool activeOnly = true,
  }) async {
    var where = 'warehouse_id = ?';
    final whereArgs = <Object?>[warehouseId];
    
    if (type != null) {
      where += ' AND type = ?';
      whereArgs.add(type);
    }
    
    if (activeOnly) {
      where += ' AND is_active = 1';
    }
    
    return getAll(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'sequence ASC, code ASC',
    );
  }
  
  /// Get child locations
  Future<List<Location>> getChildren(String parentId, {bool activeOnly = true}) async {
    var where = 'parent_id = ?';
    final whereArgs = <Object?>[parentId];
    
    if (activeOnly) {
      where += ' AND is_active = 1';
    }
    
    return getAll(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'sequence ASC, code ASC',
    );
  }
  
  /// Get root locations (zones) for a warehouse
  Future<List<Location>> getZones(String warehouseId, {bool activeOnly = true}) async {
    var where = 'warehouse_id = ? AND parent_id IS NULL AND type = ?';
    final whereArgs = <Object?>[warehouseId, 'ZONE'];
    
    if (activeOnly) {
      where += ' AND is_active = 1';
    }
    
    return getAll(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'sequence ASC, code ASC',
    );
  }
  
  /// Get all bins (leaf locations) for a warehouse
  Future<List<Location>> getBins(String warehouseId, {bool activeOnly = true}) async {
    final maps = await rawQuery('''
      SELECT l.*, w.name as warehouse_name
      FROM locations l
      INNER JOIN warehouses w ON l.warehouse_id = w.id
      WHERE l.warehouse_id = ? AND l.type = 'BIN'
      ${activeOnly ? 'AND l.is_active = 1' : ''}
      ORDER BY l.code ASC
    ''', [warehouseId]);
    
    return maps.map((map) => Location.fromMap(map)).toList();
  }
  
  /// Get location with full path
  Future<Location?> getByIdWithPath(String id) async {
    final maps = await rawQuery('''
      WITH RECURSIVE location_path AS (
        SELECT id, warehouse_id, parent_id, code, name, type, capacity, 
               sequence, description, is_active, created_at, updated_at,
               name as full_path
        FROM locations WHERE id = ?
        
        UNION ALL
        
        SELECT l.id, l.warehouse_id, l.parent_id, l.code, l.name, l.type, 
               l.capacity, l.sequence, l.description, l.is_active, 
               l.created_at, l.updated_at,
               p.name || ' > ' || lp.full_path
        FROM locations l
        INNER JOIN location_path lp ON l.id = lp.parent_id
        INNER JOIN locations p ON l.id = p.id
      )
      SELECT lp.*, w.name as warehouse_name
      FROM location_path lp
      INNER JOIN warehouses w ON lp.warehouse_id = w.id
      ORDER BY length(lp.full_path) DESC
      LIMIT 1
    ''', [id]);
    
    if (maps.isEmpty) {
      // Fallback to simple query
      final simple = await rawQuery('''
        SELECT l.*, w.name as warehouse_name
        FROM locations l
        INNER JOIN warehouses w ON l.warehouse_id = w.id
        WHERE l.id = ?
      ''', [id]);
      if (simple.isEmpty) return null;
      return Location.fromMap(simple.first);
    }
    
    return Location.fromMap(maps.first);
  }
  
  /// Build full path for a location
  Future<String> getFullPath(String locationId) async {
    final parts = <String>[];
    String? currentId = locationId;
    
    while (currentId != null) {
      final location = await getById(currentId);
      if (location == null) break;
      parts.insert(0, location.name);
      currentId = location.parentId;
    }
    
    return parts.join(' > ');
  }
  
  /// Get locations with stock info
  Future<List<Location>> getLocationsWithStock(String warehouseId) async {
    final maps = await rawQuery('''
      SELECT 
        l.*,
        w.name as warehouse_name,
        (SELECT COUNT(DISTINCT s.item_id) FROM stock s WHERE s.location_id = l.id AND s.quantity > 0) as item_count,
        (SELECT COALESCE(SUM(s.quantity), 0) FROM stock s WHERE s.location_id = l.id) as used_capacity,
        (SELECT COUNT(*) FROM locations c WHERE c.parent_id = l.id AND c.is_active = 1) as child_count
      FROM locations l
      INNER JOIN warehouses w ON l.warehouse_id = w.id
      WHERE l.warehouse_id = ? AND l.is_active = 1
      ORDER BY l.type, l.sequence ASC, l.code ASC
    ''', [warehouseId]);
    
    return maps.map((map) => Location.fromMap(map)).toList();
  }
  
  /// Search locations by code
  Future<List<Location>> searchByCode(String query, {String? warehouseId, int limit = 20}) async {
    var sql = '''
      SELECT l.*, w.name as warehouse_name
      FROM locations l
      INNER JOIN warehouses w ON l.warehouse_id = w.id
      WHERE l.is_active = 1 AND (l.code LIKE ? OR l.name LIKE ?)
    ''';
    final args = <Object?>['%$query%', '%$query%'];
    
    if (warehouseId != null) {
      sql += ' AND l.warehouse_id = ?';
      args.add(warehouseId);
    }
    
    sql += ' ORDER BY l.code ASC LIMIT ?';
    args.add(limit);
    
    final maps = await rawQuery(sql, args);
    return maps.map((map) => Location.fromMap(map)).toList();
  }
  
  /// Check if code exists in warehouse
  Future<bool> codeExistsInWarehouse(
    String warehouseId,
    String code, {
    String? excludeId,
  }) async {
    var sql = '''
      SELECT COUNT(*) as count FROM $tableName 
      WHERE warehouse_id = ? AND code = ?
    ''';
    final args = <Object?>[warehouseId, code];
    
    if (excludeId != null) {
      sql += ' AND id != ?';
      args.add(excludeId);
    }
    
    final result = await rawQuery(sql, args);
    return (result.first['count'] as int) > 0;
  }
  
  /// Get location counts by type
  Future<Map<String, int>> getCountsByType(String warehouseId) async {
    final result = await rawQuery('''
      SELECT type, COUNT(*) as count
      FROM locations
      WHERE warehouse_id = ? AND is_active = 1
      GROUP BY type
    ''', [warehouseId]);
    
    final counts = <String, int>{};
    for (final row in result) {
      counts[row['type'] as String] = (row['count'] as int?) ?? 0;
    }
    return counts;
  }
}
