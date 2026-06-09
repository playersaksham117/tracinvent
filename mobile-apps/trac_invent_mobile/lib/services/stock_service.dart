import '../core/constants.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../database/database_helper.dart';

/// Service for stock operations with transactional safety
class StockService {
  final StockRepository _stockRepository = StockRepository();
  final MovementRepository _movementRepository = MovementRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // ==================== STOCK QUERIES ====================
  
  /// Get stock for an item with location details
  Future<List<Stock>> getStockByItem(String itemId) async {
    return _stockRepository.getByItemWithDetails(itemId);
  }
  
  /// Get stock at a location with item details
  Future<List<Stock>> getStockByLocation(String locationId) async {
    return _stockRepository.getByLocationWithDetails(locationId);
  }
  
  /// Get stock by warehouse
  Future<List<Stock>> getStockByWarehouse(String warehouseId) async {
    return _stockRepository.getByWarehouseWithDetails(warehouseId);
  }
  
  /// Get total quantity for an item
  Future<double> getTotalQuantity(String itemId) async {
    return _stockRepository.getTotalQuantity(itemId);
  }
  
  /// Get stock summaries with pagination
  Future<List<StockSummary>> getStockSummaries({
    String? searchQuery,
    String? warehouseId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final offset = (page - 1) * pageSize;
    return _stockRepository.getStockSummaries(
      searchQuery: searchQuery,
      warehouseId: warehouseId,
      limit: pageSize,
      offset: offset,
    );
  }
  
  /// Get expiring stock
  Future<List<Stock>> getExpiringStock({int daysAhead = 30}) async {
    return _stockRepository.getExpiringStock(daysAhead: daysAhead);
  }
  
  // ==================== STOCK IN ====================
  
  /// Stock In - Add items to a location
  Future<Movement> stockIn({
    required String itemId,
    required String locationId,
    required double quantity,
    required String userId,
    String? batchNumber,
    DateTime? expiryDate,
    String? referenceNumber,
    String? notes,
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }
    
    // Validate location is active and is a bin
    final location = await _locationRepository.getById(locationId);
    if (location == null) throw Exception('Location not found');
    if (!location.isActive) throw Exception('Location is not active');
    if (!location.isBin) throw Exception('Can only stock into bin locations');
    
    // Generate reference number if not provided
    final refNo = referenceNumber ?? 
        await _movementRepository.generateReferenceNumber(MovementType.stockIn);
    
    return await _dbHelper.transaction((txn) async {
      // Get current quantity
      final currentQty = await _getCurrentQuantity(
        txn, itemId, locationId, batchNumber,
      );
      
      final newQty = currentQty + quantity;
      
      // Update stock
      await _updateStock(
        txn, itemId, locationId, newQty, 
        batchNumber: batchNumber, 
        expiryDate: expiryDate,
      );
      
      // Create movement record
      final movement = Movement(
        id: 'mv_${DateTime.now().millisecondsSinceEpoch}',
        type: MovementType.stockIn,
        itemId: itemId,
        toLocationId: locationId,
        quantity: quantity,
        previousQuantity: currentQty,
        newQuantity: newQty,
        batchNumber: batchNumber,
        expiryDate: expiryDate,
        referenceNumber: refNo,
        notes: notes,
        userId: userId,
        createdAt: DateTime.now(),
      );
      
      await txn.insert('movements', movement.toMap());
      
      return movement;
    });
  }
  
  // ==================== STOCK OUT ====================
  
  /// Stock Out - Remove items from a location
  Future<Movement> stockOut({
    required String itemId,
    required String locationId,
    required double quantity,
    required String userId,
    String? batchNumber,
    String? referenceNumber,
    String? reason,
    String? notes,
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }
    
    // Validate location
    final location = await _locationRepository.getById(locationId);
    if (location == null) throw Exception('Location not found');
    if (!location.isActive) throw Exception('Location is not active');
    
    // Generate reference number if not provided
    final refNo = referenceNumber ?? 
        await _movementRepository.generateReferenceNumber(MovementType.stockOut);
    
    return await _dbHelper.transaction((txn) async {
      // Get current quantity
      final currentQty = await _getCurrentQuantity(
        txn, itemId, locationId, batchNumber,
      );
      
      // Validate sufficient stock
      if (currentQty < quantity) {
        throw Exception(
          'Insufficient stock: available $currentQty, requested $quantity',
        );
      }
      
      final newQty = currentQty - quantity;
      
      // Update stock
      await _updateStock(txn, itemId, locationId, newQty, batchNumber: batchNumber);
      
      // Create movement record
      final movement = Movement(
        id: 'mv_${DateTime.now().millisecondsSinceEpoch}',
        type: MovementType.stockOut,
        itemId: itemId,
        fromLocationId: locationId,
        quantity: quantity,
        previousQuantity: currentQty,
        newQuantity: newQty,
        batchNumber: batchNumber,
        referenceNumber: refNo,
        reason: reason,
        notes: notes,
        userId: userId,
        createdAt: DateTime.now(),
      );
      
      await txn.insert('movements', movement.toMap());
      
      return movement;
    });
  }
  
  // ==================== TRANSFER ====================
  
  /// Transfer - Move items between locations (atomic)
  Future<Movement> transfer({
    required String itemId,
    required String fromLocationId,
    required String toLocationId,
    required double quantity,
    required String userId,
    String? batchNumber,
    String? referenceNumber,
    String? notes,
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }
    
    if (fromLocationId == toLocationId) {
      throw Exception('Source and destination must be different');
    }
    
    // Validate locations
    final fromLocation = await _locationRepository.getById(fromLocationId);
    final toLocation = await _locationRepository.getById(toLocationId);
    
    if (fromLocation == null) throw Exception('Source location not found');
    if (toLocation == null) throw Exception('Destination location not found');
    if (!fromLocation.isActive) throw Exception('Source location is not active');
    if (!toLocation.isActive) throw Exception('Destination location is not active');
    if (!toLocation.isBin) throw Exception('Can only transfer to bin locations');
    
    // Generate reference number if not provided
    final refNo = referenceNumber ?? 
        await _movementRepository.generateReferenceNumber(MovementType.transfer);
    
    return await _dbHelper.transaction((txn) async {
      // Get current quantities
      final fromQty = await _getCurrentQuantity(
        txn, itemId, fromLocationId, batchNumber,
      );
      final toQty = await _getCurrentQuantity(
        txn, itemId, toLocationId, batchNumber,
      );
      
      // Validate sufficient stock
      if (fromQty < quantity) {
        throw Exception(
          'Insufficient stock: available $fromQty, requested $quantity',
        );
      }
      
      final newFromQty = fromQty - quantity;
      final newToQty = toQty + quantity;
      
      // Update source stock
      await _updateStock(
        txn, itemId, fromLocationId, newFromQty, 
        batchNumber: batchNumber,
      );
      
      // Update destination stock
      await _updateStock(
        txn, itemId, toLocationId, newToQty, 
        batchNumber: batchNumber,
      );
      
      // Create movement record
      final movement = Movement(
        id: 'mv_${DateTime.now().millisecondsSinceEpoch}',
        type: MovementType.transfer,
        itemId: itemId,
        fromLocationId: fromLocationId,
        toLocationId: toLocationId,
        quantity: quantity,
        previousQuantity: fromQty,
        newQuantity: newFromQty,
        batchNumber: batchNumber,
        referenceNumber: refNo,
        notes: notes,
        userId: userId,
        createdAt: DateTime.now(),
      );
      
      await txn.insert('movements', movement.toMap());
      
      return movement;
    });
  }
  
  // ==================== ADJUSTMENT ====================
  
  /// Adjustment - Set stock to a specific quantity with reason
  Future<Movement> adjustment({
    required String itemId,
    required String locationId,
    required double newQuantity,
    required String reason,
    required String userId,
    String? batchNumber,
    String? referenceNumber,
    String? notes,
  }) async {
    if (newQuantity < 0) {
      throw Exception('Quantity cannot be negative');
    }
    
    // Generate reference number if not provided
    final refNo = referenceNumber ?? 
        await _movementRepository.generateReferenceNumber(MovementType.adjustment);
    
    return await _dbHelper.transaction((txn) async {
      // Get current quantity
      final currentQty = await _getCurrentQuantity(
        txn, itemId, locationId, batchNumber,
      );
      
      final variance = newQuantity - currentQty;
      
      // Update stock
      await _updateStock(
        txn, itemId, locationId, newQuantity, 
        batchNumber: batchNumber,
      );
      
      // Create movement record
      final movement = Movement(
        id: 'mv_${DateTime.now().millisecondsSinceEpoch}',
        type: MovementType.adjustment,
        itemId: itemId,
        toLocationId: locationId,
        quantity: variance.abs(),
        previousQuantity: currentQty,
        newQuantity: newQuantity,
        batchNumber: batchNumber,
        referenceNumber: refNo,
        reason: reason,
        notes: notes,
        userId: userId,
        createdAt: DateTime.now(),
      );
      
      await txn.insert('movements', movement.toMap());
      
      return movement;
    });
  }
  
  // ==================== CYCLE COUNT ====================
  
  /// Cycle Count - Record counted quantity and create adjustment if needed
  Future<CycleCountResult> cycleCount({
    required String itemId,
    required String locationId,
    required double countedQuantity,
    required String userId,
    String? batchNumber,
    String? notes,
  }) async {
    final currentQty = await _stockRepository.getTotalQuantity(itemId);
    final variance = countedQuantity - currentQty;
    
    if (variance != 0) {
      // Create adjustment for variance
      await adjustment(
        itemId: itemId,
        locationId: locationId,
        newQuantity: countedQuantity,
        reason: AdjustmentReason.correction,
        userId: userId,
        batchNumber: batchNumber,
        notes: 'Cycle count variance: System: $currentQty, Counted: $countedQuantity${notes != null ? '\n$notes' : ''}',
      );
    }
    
    return CycleCountResult(
      itemId: itemId,
      locationId: locationId,
      systemQuantity: currentQty,
      countedQuantity: countedQuantity,
      variance: variance,
    );
  }
  
  /// Bulk Cycle Count - Process multiple counts
  Future<List<CycleCountResult>> bulkCycleCount({
    required List<Map<String, dynamic>> counts,
    required String userId,
  }) async {
    final results = <CycleCountResult>[];
    
    for (final count in counts) {
      final result = await cycleCount(
        itemId: count['itemId'] as String,
        locationId: count['locationId'] as String,
        countedQuantity: (count['countedQuantity'] as num).toDouble(),
        userId: userId,
        batchNumber: count['batchNumber'] as String?,
      );
      results.add(result);
    }
    
    return results;
  }
  
  // ==================== MOVEMENT HISTORY ====================
  
  /// Get movement history
  Future<List<Movement>> getMovements({MovementFilter? filter}) async {
    return _movementRepository.getMovementsWithDetails(filter: filter);
  }
  
  /// Get recent movements
  Future<List<Movement>> getRecentMovements({int limit = 10}) async {
    return _movementRepository.getRecentMovements(limit: limit);
  }
  
  /// Get today's movements
  Future<List<Movement>> getTodayMovements() async {
    return _movementRepository.getTodayMovements();
  }
  
  /// Get movement statistics
  Future<Map<String, dynamic>> getMovementStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return _movementRepository.getStatistics(
      fromDate: fromDate,
      toDate: toDate,
    );
  }
  
  // ==================== PRIVATE HELPERS ====================
  
  /// Get current quantity from transaction
  Future<double> _getCurrentQuantity(
    dynamic txn,
    String itemId,
    String locationId,
    String? batchNumber,
  ) async {
    var where = 'item_id = ? AND location_id = ?';
    final whereArgs = <Object?>[itemId, locationId];
    
    if (batchNumber != null) {
      where += ' AND batch_number = ?';
      whereArgs.add(batchNumber);
    } else {
      where += ' AND batch_number IS NULL';
    }
    
    final result = await txn.query(
      'stock',
      where: where,
      whereArgs: whereArgs,
    );
    
    if (result.isEmpty) return 0;
    return (result.first['quantity'] as num).toDouble();
  }
  
  /// Update stock within transaction
  Future<void> _updateStock(
    dynamic txn,
    String itemId,
    String locationId,
    double quantity, {
    String? batchNumber,
    DateTime? expiryDate,
  }) async {
    var where = 'item_id = ? AND location_id = ?';
    final whereArgs = <Object?>[itemId, locationId];
    
    if (batchNumber != null) {
      where += ' AND batch_number = ?';
      whereArgs.add(batchNumber);
    } else {
      where += ' AND batch_number IS NULL';
    }
    
    final existing = await txn.query('stock', where: where, whereArgs: whereArgs);
    final now = DateTime.now().toIso8601String();
    
    if (existing.isEmpty) {
      if (quantity > 0) {
        await txn.insert('stock', {
          'id': 'stk_${DateTime.now().millisecondsSinceEpoch}',
          'item_id': itemId,
          'location_id': locationId,
          'quantity': quantity,
          'batch_number': batchNumber,
          'expiry_date': expiryDate?.toIso8601String(),
          'created_at': now,
          'updated_at': now,
        });
      }
    } else {
      final stockId = existing.first['id'] as String;
      if (quantity <= 0) {
        await txn.delete('stock', where: 'id = ?', whereArgs: [stockId]);
      } else {
        await txn.update(
          'stock',
          {
            'quantity': quantity,
            'expiry_date': expiryDate?.toIso8601String(),
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [stockId],
        );
      }
    }
  }
}
