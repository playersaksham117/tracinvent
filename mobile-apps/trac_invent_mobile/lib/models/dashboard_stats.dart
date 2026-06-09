import 'package:equatable/equatable.dart';

import 'movement.dart';

/// Dashboard statistics model
class DashboardStats extends Equatable {
  final int totalSkus;
  final double totalQuantity;
  final int lowStockCount;
  final int criticalStockCount;
  final int outOfStockCount;
  final int warehouseCount;
  final int locationCount;
  final int todayMovements;
  final double todayStockIn;
  final double todayStockOut;
  final List<Movement> recentMovements;
  final List<WarehouseDistribution> warehouseDistribution;
  final List<CategoryDistribution> categoryDistribution;

  const DashboardStats({
    this.totalSkus = 0,
    this.totalQuantity = 0,
    this.lowStockCount = 0,
    this.criticalStockCount = 0,
    this.outOfStockCount = 0,
    this.warehouseCount = 0,
    this.locationCount = 0,
    this.todayMovements = 0,
    this.todayStockIn = 0,
    this.todayStockOut = 0,
    this.recentMovements = const [],
    this.warehouseDistribution = const [],
    this.categoryDistribution = const [],
  });

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      totalSkus: (map['total_skus'] as int?) ?? 0,
      totalQuantity: (map['total_quantity'] as num?)?.toDouble() ?? 0,
      lowStockCount: (map['low_stock_count'] as int?) ?? 0,
      criticalStockCount: (map['critical_stock_count'] as int?) ?? 0,
      outOfStockCount: (map['out_of_stock_count'] as int?) ?? 0,
      warehouseCount: (map['warehouse_count'] as int?) ?? 0,
      locationCount: (map['location_count'] as int?) ?? 0,
      todayMovements: (map['today_movements'] as int?) ?? 0,
      todayStockIn: (map['today_stock_in'] as num?)?.toDouble() ?? 0,
      todayStockOut: (map['today_stock_out'] as num?)?.toDouble() ?? 0,
    );
  }

  DashboardStats copyWith({
    int? totalSkus,
    double? totalQuantity,
    int? lowStockCount,
    int? criticalStockCount,
    int? outOfStockCount,
    int? warehouseCount,
    int? locationCount,
    int? todayMovements,
    double? todayStockIn,
    double? todayStockOut,
    List<Movement>? recentMovements,
    List<WarehouseDistribution>? warehouseDistribution,
    List<CategoryDistribution>? categoryDistribution,
  }) {
    return DashboardStats(
      totalSkus: totalSkus ?? this.totalSkus,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      criticalStockCount: criticalStockCount ?? this.criticalStockCount,
      outOfStockCount: outOfStockCount ?? this.outOfStockCount,
      warehouseCount: warehouseCount ?? this.warehouseCount,
      locationCount: locationCount ?? this.locationCount,
      todayMovements: todayMovements ?? this.todayMovements,
      todayStockIn: todayStockIn ?? this.todayStockIn,
      todayStockOut: todayStockOut ?? this.todayStockOut,
      recentMovements: recentMovements ?? this.recentMovements,
      warehouseDistribution: warehouseDistribution ?? this.warehouseDistribution,
      categoryDistribution: categoryDistribution ?? this.categoryDistribution,
    );
  }

  @override
  List<Object?> get props => [
    totalSkus,
    totalQuantity,
    lowStockCount,
    criticalStockCount,
    warehouseCount,
    todayMovements,
  ];
}

/// Warehouse distribution for charts
class WarehouseDistribution extends Equatable {
  final String warehouseId;
  final String warehouseName;
  final int itemCount;
  final double totalQuantity;
  final double percentage;

  const WarehouseDistribution({
    required this.warehouseId,
    required this.warehouseName,
    required this.itemCount,
    required this.totalQuantity,
    this.percentage = 0,
  });

  factory WarehouseDistribution.fromMap(Map<String, dynamic> map) {
    return WarehouseDistribution(
      warehouseId: map['warehouse_id'] as String,
      warehouseName: map['warehouse_name'] as String,
      itemCount: (map['item_count'] as int?) ?? 0,
      totalQuantity: (map['total_quantity'] as num?)?.toDouble() ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [warehouseId, itemCount, totalQuantity];
}

/// Category distribution for charts
class CategoryDistribution extends Equatable {
  final String? categoryId;
  final String categoryName;
  final int itemCount;
  final double totalQuantity;
  final double percentage;

  const CategoryDistribution({
    this.categoryId,
    required this.categoryName,
    required this.itemCount,
    required this.totalQuantity,
    this.percentage = 0,
  });

  factory CategoryDistribution.fromMap(Map<String, dynamic> map) {
    return CategoryDistribution(
      categoryId: map['category_id'] as String?,
      categoryName: (map['category_name'] as String?) ?? 'Uncategorized',
      itemCount: (map['item_count'] as int?) ?? 0,
      totalQuantity: (map['total_quantity'] as num?)?.toDouble() ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [categoryId, itemCount, totalQuantity];
}

/// Cycle count result model
class CycleCountResult extends Equatable {
  final String itemId;
  final String locationId;
  final double systemQuantity;
  final double countedQuantity;
  final double variance;
  final bool hasVariance;
  
  const CycleCountResult({
    required this.itemId,
    required this.locationId,
    required this.systemQuantity,
    required this.countedQuantity,
    required this.variance,
  }) : hasVariance = variance != 0;

  @override
  List<Object?> get props => [itemId, locationId, systemQuantity, countedQuantity];
}
