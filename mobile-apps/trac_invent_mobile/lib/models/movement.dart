import 'package:equatable/equatable.dart';

/// Movement Model - Complete audit trail for all stock operations
class Movement extends Equatable {
  final String id;
  final String type; // STOCK_IN, STOCK_OUT, TRANSFER, ADJUSTMENT, CYCLE_COUNT
  final String itemId;
  final String? fromLocationId;
  final String? toLocationId;
  final double quantity;
  final double? previousQuantity;
  final double? newQuantity;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? referenceNumber;
  final String? reason;
  final String? notes;
  final String userId;
  final DateTime createdAt;
  
  // Joined fields
  final String? itemName;
  final String? itemSku;
  final String? fromLocationCode;
  final String? fromLocationPath;
  final String? toLocationCode;
  final String? toLocationPath;
  final String? fromWarehouseName;
  final String? toWarehouseName;
  final String? userName;

  const Movement({
    required this.id,
    required this.type,
    required this.itemId,
    this.fromLocationId,
    this.toLocationId,
    required this.quantity,
    this.previousQuantity,
    this.newQuantity,
    this.batchNumber,
    this.expiryDate,
    this.referenceNumber,
    this.reason,
    this.notes,
    required this.userId,
    required this.createdAt,
    this.itemName,
    this.itemSku,
    this.fromLocationCode,
    this.fromLocationPath,
    this.toLocationCode,
    this.toLocationPath,
    this.fromWarehouseName,
    this.toWarehouseName,
    this.userName,
  });

  factory Movement.fromMap(Map<String, dynamic> map) {
    return Movement(
      id: map['id'] as String,
      type: map['type'] as String,
      itemId: map['item_id'] as String,
      fromLocationId: map['from_location_id'] as String?,
      toLocationId: map['to_location_id'] as String?,
      quantity: (map['quantity'] as num).toDouble(),
      previousQuantity: (map['previous_quantity'] as num?)?.toDouble(),
      newQuantity: (map['new_quantity'] as num?)?.toDouble(),
      batchNumber: map['batch_number'] as String?,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      referenceNumber: map['reference_number'] as String?,
      reason: map['reason'] as String?,
      notes: map['notes'] as String?,
      userId: map['user_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      itemName: map['item_name'] as String?,
      itemSku: map['item_sku'] as String?,
      fromLocationCode: map['from_location_code'] as String?,
      fromLocationPath: map['from_location_path'] as String?,
      toLocationCode: map['to_location_code'] as String?,
      toLocationPath: map['to_location_path'] as String?,
      fromWarehouseName: map['from_warehouse_name'] as String?,
      toWarehouseName: map['to_warehouse_name'] as String?,
      userName: map['user_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'item_id': itemId,
      'from_location_id': fromLocationId,
      'to_location_id': toLocationId,
      'quantity': quantity,
      'previous_quantity': previousQuantity,
      'new_quantity': newQuantity,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String(),
      'reference_number': referenceNumber,
      'reason': reason,
      'notes': notes,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Movement copyWith({
    String? id,
    String? type,
    String? itemId,
    String? fromLocationId,
    String? toLocationId,
    double? quantity,
    double? previousQuantity,
    double? newQuantity,
    String? batchNumber,
    DateTime? expiryDate,
    String? referenceNumber,
    String? reason,
    String? notes,
    String? userId,
    DateTime? createdAt,
    String? itemName,
    String? itemSku,
    String? fromLocationCode,
    String? fromLocationPath,
    String? toLocationCode,
    String? toLocationPath,
    String? fromWarehouseName,
    String? toWarehouseName,
    String? userName,
  }) {
    return Movement(
      id: id ?? this.id,
      type: type ?? this.type,
      itemId: itemId ?? this.itemId,
      fromLocationId: fromLocationId ?? this.fromLocationId,
      toLocationId: toLocationId ?? this.toLocationId,
      quantity: quantity ?? this.quantity,
      previousQuantity: previousQuantity ?? this.previousQuantity,
      newQuantity: newQuantity ?? this.newQuantity,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      itemName: itemName ?? this.itemName,
      itemSku: itemSku ?? this.itemSku,
      fromLocationCode: fromLocationCode ?? this.fromLocationCode,
      fromLocationPath: fromLocationPath ?? this.fromLocationPath,
      toLocationCode: toLocationCode ?? this.toLocationCode,
      toLocationPath: toLocationPath ?? this.toLocationPath,
      fromWarehouseName: fromWarehouseName ?? this.fromWarehouseName,
      toWarehouseName: toWarehouseName ?? this.toWarehouseName,
      userName: userName ?? this.userName,
    );
  }

  /// Get display label for movement type
  String get typeLabel {
    switch (type) {
      case 'STOCK_IN': return 'Stock In';
      case 'STOCK_OUT': return 'Stock Out';
      case 'TRANSFER': return 'Transfer';
      case 'ADJUSTMENT': return 'Adjustment';
      case 'CYCLE_COUNT': return 'Cycle Count';
      case 'INITIAL_STOCK': return 'Initial Stock';
      default: return type;
    }
  }

  /// Is this an inbound movement?
  bool get isInbound =>
      type == 'STOCK_IN' ||
      type == 'INITIAL_STOCK' ||
      (type == 'ADJUSTMENT' && (newQuantity ?? 0) > (previousQuantity ?? 0));

  /// Is this an outbound movement?
  bool get isOutbound =>
      type == 'STOCK_OUT' ||
      (type == 'ADJUSTMENT' && (newQuantity ?? 0) < (previousQuantity ?? 0));

  @override
  List<Object?> get props => [id, type, itemId, createdAt];
}

/// Movement filter for queries
class MovementFilter {
  final String? itemId;
  final String? locationId;
  final String? warehouseId;
  final String? type;
  final String? userId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? searchQuery;
  final int limit;
  final int offset;

  const MovementFilter({
    this.itemId,
    this.locationId,
    this.warehouseId,
    this.type,
    this.userId,
    this.fromDate,
    this.toDate,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });

  MovementFilter copyWith({
    String? itemId,
    String? locationId,
    String? warehouseId,
    String? type,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) {
    return MovementFilter(
      itemId: itemId ?? this.itemId,
      locationId: locationId ?? this.locationId,
      warehouseId: warehouseId ?? this.warehouseId,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      searchQuery: searchQuery ?? this.searchQuery,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}
