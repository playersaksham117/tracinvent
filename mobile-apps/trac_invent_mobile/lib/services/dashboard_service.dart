import '../models/models.dart';
import '../repositories/repositories.dart';

/// Service for dashboard statistics and analytics
class DashboardService {
  final InventoryItemRepository _itemRepository = InventoryItemRepository();
  final WarehouseRepository _warehouseRepository = WarehouseRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final StockRepository _stockRepository = StockRepository();
  final MovementRepository _movementRepository = MovementRepository();
  
  /// Get comprehensive dashboard statistics
  Future<DashboardStats> getDashboardStats() async {
    // Get item counts
    final itemCounts = await _itemRepository.getItemCounts();
    
    // Get low/critical/out of stock counts
    final lowStockItems = await _itemRepository.getLowStockItems();
    final criticalStockItems = await _itemRepository.getCriticalStockItems();
    final outOfStockItems = await _itemRepository.getOutOfStockItems();
    
    // Get warehouse count
    final warehouses = await _warehouseRepository.getActiveWarehouses();
    
    // Get total stock quantity
    final stockSummary = await _stockRepository.rawQuery('''
      SELECT 
        COALESCE(SUM(s.quantity), 0) as total_quantity,
        COUNT(DISTINCT s.location_id) as location_count
      FROM stock s
      WHERE s.quantity > 0
    ''');
    
    // Get today's movement stats
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final todayStats = await _movementRepository.getStatistics(
      fromDate: startOfDay,
    );
    
    final todayQuantities = await _movementRepository.getQuantitiesByType(
      fromDate: startOfDay,
    );
    
    // Get recent movements
    final recentMovements = await _movementRepository.getRecentMovements(limit: 10);
    
    // Get warehouse distribution
    final warehouseDistribution = await _getWarehouseDistribution();
    
    // Get category distribution
    final categoryDistribution = await _getCategoryDistribution();
    
    return DashboardStats(
      totalSkus: itemCounts['active'] ?? 0,
      totalQuantity: (stockSummary.first['total_quantity'] as num?)?.toDouble() ?? 0,
      lowStockCount: lowStockItems.length,
      criticalStockCount: criticalStockItems.length,
      outOfStockCount: outOfStockItems.length,
      warehouseCount: warehouses.length,
      locationCount: (stockSummary.first['location_count'] as int?) ?? 0,
      todayMovements: (todayStats['total_movements'] as int?) ?? 0,
      todayStockIn: todayQuantities['STOCK_IN'] ?? 0,
      todayStockOut: todayQuantities['STOCK_OUT'] ?? 0,
      recentMovements: recentMovements,
      warehouseDistribution: warehouseDistribution,
      categoryDistribution: categoryDistribution,
    );
  }
  
  /// Get warehouse distribution
  Future<List<WarehouseDistribution>> _getWarehouseDistribution() async {
    final results = await _stockRepository.rawQuery('''
      SELECT 
        w.id as warehouse_id,
        w.name as warehouse_name,
        COUNT(DISTINCT s.item_id) as item_count,
        COALESCE(SUM(s.quantity), 0) as total_quantity
      FROM warehouses w
      LEFT JOIN locations l ON w.id = l.warehouse_id
      LEFT JOIN stock s ON l.id = s.location_id AND s.quantity > 0
      WHERE w.is_active = 1
      GROUP BY w.id
      ORDER BY total_quantity DESC
    ''');
    
    // Calculate total for percentages
    final total = results.fold<double>(
      0,
      (sum, r) => sum + ((r['total_quantity'] as num?)?.toDouble() ?? 0),
    );
    
    return results.map((r) {
      final qty = (r['total_quantity'] as num?)?.toDouble() ?? 0;
      return WarehouseDistribution(
        warehouseId: r['warehouse_id'] as String,
        warehouseName: r['warehouse_name'] as String,
        itemCount: (r['item_count'] as int?) ?? 0,
        totalQuantity: qty,
        percentage: total > 0 ? (qty / total) * 100 : 0,
      );
    }).toList();
  }
  
  /// Get category distribution
  Future<List<CategoryDistribution>> _getCategoryDistribution() async {
    final results = await _stockRepository.rawQuery('''
      SELECT 
        c.id as category_id,
        COALESCE(c.name, 'Uncategorized') as category_name,
        COUNT(DISTINCT i.id) as item_count,
        COALESCE(SUM(s.quantity), 0) as total_quantity
      FROM inventory_items i
      LEFT JOIN categories c ON i.category_id = c.id
      LEFT JOIN stock s ON i.id = s.item_id
      WHERE i.is_active = 1
      GROUP BY c.id
      ORDER BY total_quantity DESC
    ''');
    
    // Calculate total for percentages
    final total = results.fold<double>(
      0,
      (sum, r) => sum + ((r['total_quantity'] as num?)?.toDouble() ?? 0),
    );
    
    return results.map((r) {
      final qty = (r['total_quantity'] as num?)?.toDouble() ?? 0;
      return CategoryDistribution(
        categoryId: r['category_id'] as String?,
        categoryName: r['category_name'] as String,
        itemCount: (r['item_count'] as int?) ?? 0,
        totalQuantity: qty,
        percentage: total > 0 ? (qty / total) * 100 : 0,
      );
    }).toList();
  }
  
  /// Get movement trends for charts (last N days)
  Future<List<Map<String, dynamic>>> getMovementTrends({int days = 7}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    final results = await _movementRepository.rawQuery('''
      SELECT 
        date(created_at) as date,
        SUM(CASE WHEN type = 'STOCK_IN' THEN quantity ELSE 0 END) as stock_in,
        SUM(CASE WHEN type = 'STOCK_OUT' THEN quantity ELSE 0 END) as stock_out,
        SUM(CASE WHEN type = 'TRANSFER' THEN quantity ELSE 0 END) as transfers,
        COUNT(*) as total_movements
      FROM movements
      WHERE created_at >= ? AND created_at <= ?
      GROUP BY date(created_at)
      ORDER BY date ASC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    
    return results;
  }
  
  /// Get top moving items
  Future<List<Map<String, dynamic>>> getTopMovingItems({
    int limit = 10,
    int days = 30,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    
    return await _movementRepository.rawQuery('''
      SELECT 
        i.id,
        i.name,
        i.sku,
        SUM(m.quantity) as total_quantity,
        COUNT(*) as movement_count
      FROM movements m
      INNER JOIN inventory_items i ON m.item_id = i.id
      WHERE m.created_at >= ?
      GROUP BY i.id
      ORDER BY total_quantity DESC
      LIMIT ?
    ''', [startDate.toIso8601String(), limit]);
  }
  
  /// Get stock alerts (low, critical, expiring)
  Future<Map<String, List<dynamic>>> getStockAlerts() async {
    final lowStock = await _itemRepository.getLowStockItems();
    final criticalStock = await _itemRepository.getCriticalStockItems();
    final expiringStock = await _stockRepository.getExpiringStock(daysAhead: 30);
    
    return {
      'lowStock': lowStock,
      'criticalStock': criticalStock,
      'expiringStock': expiringStock,
    };
  }
}
