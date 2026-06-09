import 'package:equatable/equatable.dart';

import '../core/constants.dart';

/// Stock Model - Tracks quantity of items at specific locations
class Stock extends Equatable {
  final String id;
  final String itemId;
  final String locationId;
  final double quantity;
  final String? batchNumber;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined fields
  final String? itemName;
  final String? itemSku;
  final String? itemBarcode;
  final String? locationCode;
  final String? locationPath;
  final String? warehouseId;
  final String? warehouseName;
  final double? reorderLevel;
  final double? minLevel;
  final String? unit;

  const Stock({
    required this.id,
    required this.itemId,
    required this.locationId,
    required this.quantity,
    this.batchNumber,
    this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
    this.itemName,
    this.itemSku,
    this.itemBarcode,
    this.locationCode,
    this.locationPath,
    this.warehouseId,
    this.warehouseName,
    this.reorderLevel,
    this.minLevel,
    this.unit,
  });

  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      locationId: map['location_id'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      batchNumber: map['batch_number'] as String?,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      itemName: map['item_name'] as String?,
      itemSku: map['item_sku'] as String?,
      itemBarcode: map['item_barcode'] as String?,
      locationCode: map['location_code'] as String?,
      locationPath: map['location_path'] as String?,
      warehouseId: map['warehouse_id'] as String?,
      warehouseName: map['warehouse_name'] as String?,
      reorderLevel: (map['reorder_level'] as num?)?.toDouble(),
      minLevel: (map['min_level'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'location_id': locationId,
      'quantity': quantity,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Stock copyWith({
    String? id,
    String? itemId,
    String? locationId,
    double? quantity,
    String? batchNumber,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? itemName,
    String? itemSku,
    String? itemBarcode,
    String? locationCode,
    String? locationPath,
    String? warehouseId,
    String? warehouseName,
    double? reorderLevel,
    double? minLevel,
    String? unit,
  }) {
    return Stock(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      locationId: locationId ?? this.locationId,
      quantity: quantity ?? this.quantity,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemName: itemName ?? this.itemName,
      itemSku: itemSku ?? this.itemSku,
      itemBarcode: itemBarcode ?? this.itemBarcode,
      locationCode: locationCode ?? this.locationCode,
      locationPath: locationPath ?? this.locationPath,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      minLevel: minLevel ?? this.minLevel,
      unit: unit ?? this.unit,
    );
  }

  /// Get stock status based on quantity vs reorder/min levels
  StockStatus get status {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (minLevel != null && quantity <= minLevel!) return StockStatus.criticalStock;
    if (reorderLevel != null && quantity <= reorderLevel!) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  /// Check if item is expired
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  /// Check if item is expiring soon (within 30 days)
  bool get isExpiringSoon =>
      expiryDate != null &&
      expiryDate!.isBefore(DateTime.now().add(const Duration(days: 30))) &&
      !isExpired;

  @override
  List<Object?> get props => [id, itemId, locationId, batchNumber];
}

/// Stock Summary - Aggregated stock for an item across all locations
class StockSummary extends Equatable {
  final String itemId;
  final String itemName;
  final String itemSku;
  final String? itemBarcode;
  final String unit;
  final double totalQuantity;
  final double reorderLevel;
  final double minLevel;
  final int locationCount;
  final int warehouseCount;

  const StockSummary({
    required this.itemId,
    required this.itemName,
    required this.itemSku,
    this.itemBarcode,
    required this.unit,
    required this.totalQuantity,
    required this.reorderLevel,
    required this.minLevel,
    required this.locationCount,
    required this.warehouseCount,
  });

  factory StockSummary.fromMap(Map<String, dynamic> map) {
    return StockSummary(
      itemId: map['item_id'] as String,
      itemName: map['item_name'] as String,
      itemSku: map['item_sku'] as String,
      itemBarcode: map['item_barcode'] as String?,
      unit: map['unit'] as String? ?? 'PCS',
      totalQuantity: (map['total_quantity'] as num?)?.toDouble() ?? 0,
      reorderLevel: (map['reorder_level'] as num?)?.toDouble() ?? 0,
      minLevel: (map['min_level'] as num?)?.toDouble() ?? 0,
      locationCount: (map['location_count'] as int?) ?? 0,
      warehouseCount: (map['warehouse_count'] as int?) ?? 0,
    );
  }

  /// Get stock status
  StockStatus get status {
    if (totalQuantity <= 0) return StockStatus.outOfStock;
    if (totalQuantity <= minLevel) return StockStatus.criticalStock;
    if (totalQuantity <= reorderLevel) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  @override
  List<Object?> get props => [itemId, totalQuantity];
}
