import '../models/inventory_item.dart';
import 'base_repository.dart';

/// Repository for inventory item operations
class InventoryItemRepository extends BaseRepository<InventoryItem> {
  @override
  String get tableName => 'inventory_items';
  
  @override
  InventoryItem fromMap(Map<String, dynamic> map) => InventoryItem.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(InventoryItem item) => item.toMap();
  
  /// Get all items with category name and total quantity
  Future<List<InventoryItem>> getAllWithDetails({
    String? searchQuery,
    String? categoryId,
    bool? activeOnly,
    String? orderBy,
    int limit = 50,
    int offset = 0,
  }) async {
    var sql = '''
      SELECT 
        i.*,
        c.name as category_name,
        COALESCE(SUM(s.quantity), 0) as total_quantity
      FROM inventory_items i
      LEFT JOIN categories c ON i.category_id = c.id
      LEFT JOIN stock s ON i.id = s.item_id
    ''';
    
    final conditions = <String>[];
    final args = <Object?>[];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(i.name LIKE ? OR i.sku LIKE ? OR i.barcode LIKE ?)');
      args.addAll(['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']);
    }
    
    if (categoryId != null) {
      conditions.add('i.category_id = ?');
      args.add(categoryId);
    }
    
    if (activeOnly == true) {
      conditions.add('i.is_active = 1');
    }
    
    if (conditions.isNotEmpty) {
      sql += ' WHERE ${conditions.join(' AND ')}';
    }
    
    sql += ' GROUP BY i.id';
    sql += ' ORDER BY ${orderBy ?? 'i.name ASC'}';
    sql += ' LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);
    
    final maps = await rawQuery(sql, args);
    return maps.map((map) => InventoryItem.fromMap(map)).toList();
  }
  
  /// Get item by SKU
  Future<InventoryItem?> getBySku(String sku) async {
    final items = await getAll(
      where: 'sku = ?',
      whereArgs: [sku],
    );
    return items.isEmpty ? null : items.first;
  }
  
  /// Get item by barcode
  Future<InventoryItem?> getByBarcode(String barcode) async {
    final items = await getAll(
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    return items.isEmpty ? null : items.first;
  }
  
  /// Get item with details by ID
  Future<InventoryItem?> getByIdWithDetails(String id) async {
    final maps = await rawQuery('''
      SELECT 
        i.*,
        c.name as category_name,
        COALESCE(SUM(s.quantity), 0) as total_quantity
      FROM inventory_items i
      LEFT JOIN categories c ON i.category_id = c.id
      LEFT JOIN stock s ON i.id = s.item_id
      WHERE i.id = ?
      GROUP BY i.id
    ''', [id]);
    
    if (maps.isEmpty) return null;
    return InventoryItem.fromMap(maps.first);
  }
  
  /// Get low stock items
  Future<List<InventoryItem>> getLowStockItems() async {
    final maps = await rawQuery('''
      SELECT 
        i.*,
        c.name as category_name,
        COALESCE(SUM(s.quantity), 0) as total_quantity
      FROM inventory_items i
      LEFT JOIN categories c ON i.category_id = c.id
      LEFT JOIN stock s ON i.id = s.item_id
      WHERE i.is_active = 1
      GROUP BY i.id
      HAVING total_quantity <= i.reorder_level AND total_quantity > i.min_level
      ORDER BY total_quantity ASC
    ''');
    return maps.map((map) => InventoryItem.fromMap(map)).toList();
  }
  
  /// Get critical stock items (below min level)
  Future<List<InventoryItem>> getCriticalStockItems() async {
    final maps = await rawQuery('''
      SELECT 
        i.*,
        c.name as category_name,
        COALESCE(SUM(s.quantity), 0) as total_quantity
      FROM inventory_items i
      LEFT JOIN categories c ON i.category_id = c.id
      LEFT JOIN stock s ON i.id = s.item_id
      WHERE i.is_active = 1
      GROUP BY i.id
      HAVING total_quantity <= i.min_level AND i.min_level > 0
      ORDER BY total_quantity ASC
    ''');
    return maps.map((map) => InventoryItem.fromMap(map)).toList();
  }
  
  /// Get out of stock items
  Future<List<InventoryItem>> getOutOfStockItems() async {
    final maps = await rawQuery('''
      SELECT 
        i.*,
        c.name as category_name,
        COALESCE(SUM(s.quantity), 0) as total_quantity
      FROM inventory_items i
      LEFT JOIN categories c ON i.category_id = c.id
      LEFT JOIN stock s ON i.id = s.item_id
      WHERE i.is_active = 1
      GROUP BY i.id
      HAVING total_quantity <= 0
      ORDER BY i.name ASC
    ''');
    return maps.map((map) => InventoryItem.fromMap(map)).toList();
  }
  
  /// Search items by SKU, barcode, or name
  Future<List<InventoryItem>> search(String query, {int limit = 20}) async {
    final maps = await rawQuery('''
      SELECT 
        i.*,
        c.name as category_name,
        COALESCE(SUM(s.quantity), 0) as total_quantity
      FROM inventory_items i
      LEFT JOIN categories c ON i.category_id = c.id
      LEFT JOIN stock s ON i.id = s.item_id
      WHERE i.is_active = 1 AND (
        i.sku LIKE ? OR 
        i.barcode LIKE ? OR 
        i.name LIKE ?
      )
      GROUP BY i.id
      ORDER BY 
        CASE 
          WHEN i.sku = ? THEN 1
          WHEN i.barcode = ? THEN 2
          WHEN i.sku LIKE ? THEN 3
          ELSE 4
        END,
        i.name ASC
      LIMIT ?
    ''', [
      '%$query%', '%$query%', '%$query%',
      query, query, '$query%',
      limit,
    ]);
    return maps.map((map) => InventoryItem.fromMap(map)).toList();
  }
  
  /// Check if SKU exists
  Future<bool> skuExists(String sku, {String? excludeId}) async {
    var sql = 'SELECT COUNT(*) as count FROM $tableName WHERE sku = ?';
    final args = <Object?>[sku];
    
    if (excludeId != null) {
      sql += ' AND id != ?';
      args.add(excludeId);
    }
    
    final result = await rawQuery(sql, args);
    return (result.first['count'] as int) > 0;
  }
  
  /// Check if barcode exists
  Future<bool> barcodeExists(String barcode, {String? excludeId}) async {
    var sql = 'SELECT COUNT(*) as count FROM $tableName WHERE barcode = ?';
    final args = <Object?>[barcode];
    
    if (excludeId != null) {
      sql += ' AND id != ?';
      args.add(excludeId);
    }
    
    final result = await rawQuery(sql, args);
    return (result.first['count'] as int) > 0;
  }
  
  /// Get total item count
  Future<Map<String, int>> getItemCounts() async {
    final result = await rawQuery('''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) as active,
        SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) as inactive
      FROM inventory_items
    ''');
    
    final map = result.first;
    return {
      'total': (map['total'] as int?) ?? 0,
      'active': (map['active'] as int?) ?? 0,
      'inactive': (map['inactive'] as int?) ?? 0,
    };
  }
}

/// Repository for category operations
class CategoryRepository extends BaseRepository<Category> {
  @override
  String get tableName => 'categories';
  
  @override
  Category fromMap(Map<String, dynamic> map) => Category.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(Category item) => item.toMap();
  
  /// Get root categories (no parent)
  Future<List<Category>> getRootCategories() async {
    return getAll(
      where: 'parent_id IS NULL AND is_active = 1',
      orderBy: 'name ASC',
    );
  }
  
  /// Get child categories
  Future<List<Category>> getChildren(String parentId) async {
    return getAll(
      where: 'parent_id = ? AND is_active = 1',
      whereArgs: [parentId],
      orderBy: 'name ASC',
    );
  }
  
  /// Get all active categories
  Future<List<Category>> getActiveCategories() async {
    return getAll(
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
  }
  
  /// Get category with item count
  Future<List<Map<String, dynamic>>> getCategoriesWithItemCount() async {
    return rawQuery('''
      SELECT 
        c.*,
        COUNT(i.id) as item_count
      FROM categories c
      LEFT JOIN inventory_items i ON c.id = i.category_id AND i.is_active = 1
      WHERE c.is_active = 1
      GROUP BY c.id
      ORDER BY c.name ASC
    ''');
  }
}
