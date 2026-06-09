/// Inventory Models - BillEase Accounts+
/// Live stock, low stock alerts, batch/expiry, categories, profit margin, valuation
library;

import 'package:flutter/material.dart';

/// Stock Item - Master item with inventory tracking
class StockItem {
  final String id;
  final String itemCode;
  final String name;
  final String? description;
  final String? hsnCode;
  final String categoryId;
  final String? categoryName;
  final String unit;
  final List<String> alternateUnits;
  final double currentStock;
  final double minStockLevel;
  final double maxStockLevel;
  final double reorderLevel;
  final double purchasePrice;
  final double sellingPrice;
  final double mrp;
  final double gstRate;
  final double cessRate;
  final bool trackBatch;
  final bool trackExpiry;
  final bool trackSerial;
  final List<StockBatch> batches;
  final StockValuationMethod valuationMethod;
  final double averageCost;
  final double stockValue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StockItem({
    required this.id,
    required this.itemCode,
    required this.name,
    this.description,
    this.hsnCode,
    required this.categoryId,
    this.categoryName,
    this.unit = 'pcs',
    this.alternateUnits = const [],
    this.currentStock = 0,
    this.minStockLevel = 0,
    this.maxStockLevel = 0,
    this.reorderLevel = 0,
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.mrp = 0,
    this.gstRate = 0,
    this.cessRate = 0,
    this.trackBatch = false,
    this.trackExpiry = false,
    this.trackSerial = false,
    this.batches = const [],
    this.valuationMethod = StockValuationMethod.fifo,
    this.averageCost = 0,
    this.stockValue = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Stock status
  StockStatus get stockStatus {
    if (currentStock <= 0) return StockStatus.outOfStock;
    if (currentStock <= minStockLevel) return StockStatus.lowStock;
    if (currentStock >= maxStockLevel) return StockStatus.overstock;
    return StockStatus.inStock;
  }

  // Profit margin calculations
  double get profitMargin => sellingPrice > 0 
      ? ((sellingPrice - purchasePrice) / sellingPrice) * 100 
      : 0;

  double get profitAmount => sellingPrice - purchasePrice;

  double get markupPercent => purchasePrice > 0 
      ? ((sellingPrice - purchasePrice) / purchasePrice) * 100 
      : 0;

  // Check if any batch is expiring soon
  bool get hasExpiringBatches => batches.any((b) => b.isExpiringSoon);
  
  bool get hasExpiredBatches => batches.any((b) => b.isExpired);

  // Get total stock from batches if tracking batch
  double get totalBatchStock => batches.fold(0, (sum, b) => sum + b.quantity);

  StockItem copyWith({
    String? id,
    String? itemCode,
    String? name,
    String? description,
    String? hsnCode,
    String? categoryId,
    String? categoryName,
    String? unit,
    List<String>? alternateUnits,
    double? currentStock,
    double? minStockLevel,
    double? maxStockLevel,
    double? reorderLevel,
    double? purchasePrice,
    double? sellingPrice,
    double? mrp,
    double? gstRate,
    double? cessRate,
    bool? trackBatch,
    bool? trackExpiry,
    bool? trackSerial,
    List<StockBatch>? batches,
    StockValuationMethod? valuationMethod,
    double? averageCost,
    double? stockValue,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      name: name ?? this.name,
      description: description ?? this.description,
      hsnCode: hsnCode ?? this.hsnCode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unit: unit ?? this.unit,
      alternateUnits: alternateUnits ?? this.alternateUnits,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      maxStockLevel: maxStockLevel ?? this.maxStockLevel,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      mrp: mrp ?? this.mrp,
      gstRate: gstRate ?? this.gstRate,
      cessRate: cessRate ?? this.cessRate,
      trackBatch: trackBatch ?? this.trackBatch,
      trackExpiry: trackExpiry ?? this.trackExpiry,
      trackSerial: trackSerial ?? this.trackSerial,
      batches: batches ?? this.batches,
      valuationMethod: valuationMethod ?? this.valuationMethod,
      averageCost: averageCost ?? this.averageCost,
      stockValue: stockValue ?? this.stockValue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemCode': itemCode,
    'name': name,
    'description': description,
    'hsnCode': hsnCode,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'unit': unit,
    'alternateUnits': alternateUnits,
    'currentStock': currentStock,
    'minStockLevel': minStockLevel,
    'maxStockLevel': maxStockLevel,
    'reorderLevel': reorderLevel,
    'purchasePrice': purchasePrice,
    'sellingPrice': sellingPrice,
    'mrp': mrp,
    'gstRate': gstRate,
    'cessRate': cessRate,
    'trackBatch': trackBatch,
    'trackExpiry': trackExpiry,
    'trackSerial': trackSerial,
    'batches': batches.map((b) => b.toJson()).toList(),
    'valuationMethod': valuationMethod.name,
    'averageCost': averageCost,
    'stockValue': stockValue,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
    id: json['id'],
    itemCode: json['itemCode'],
    name: json['name'],
    description: json['description'],
    hsnCode: json['hsnCode'],
    categoryId: json['categoryId'],
    categoryName: json['categoryName'],
    unit: json['unit'] ?? 'pcs',
    alternateUnits: List<String>.from(json['alternateUnits'] ?? []),
    currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0,
    minStockLevel: (json['minStockLevel'] as num?)?.toDouble() ?? 0,
    maxStockLevel: (json['maxStockLevel'] as num?)?.toDouble() ?? 0,
    reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0,
    purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0,
    sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
    mrp: (json['mrp'] as num?)?.toDouble() ?? 0,
    gstRate: (json['gstRate'] as num?)?.toDouble() ?? 0,
    cessRate: (json['cessRate'] as num?)?.toDouble() ?? 0,
    trackBatch: json['trackBatch'] ?? false,
    trackExpiry: json['trackExpiry'] ?? false,
    trackSerial: json['trackSerial'] ?? false,
    batches: (json['batches'] as List?)?.map((b) => StockBatch.fromJson(b)).toList() ?? [],
    valuationMethod: StockValuationMethod.values.firstWhere(
      (e) => e.name == json['valuationMethod'],
      orElse: () => StockValuationMethod.fifo,
    ),
    averageCost: (json['averageCost'] as num?)?.toDouble() ?? 0,
    stockValue: (json['stockValue'] as num?)?.toDouble() ?? 0,
    isActive: json['isActive'] ?? true,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );
}

/// Stock Batch - For batch and expiry tracking
class StockBatch {
  final String id;
  final String itemId;
  final String batchNumber;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;
  final double quantity;
  final double purchasePrice;
  final double sellingPrice;
  final String? location;
  final DateTime createdAt;

  StockBatch({
    required this.id,
    required this.itemId,
    required this.batchNumber,
    this.manufacturingDate,
    this.expiryDate,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    this.location,
    required this.createdAt,
  });

  // Days until expiry
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final days = daysUntilExpiry;
    return days != null && days > 0 && days <= 30;
  }

  ExpiryStatus get expiryStatus {
    if (expiryDate == null) return ExpiryStatus.noExpiry;
    final days = daysUntilExpiry!;
    if (days < 0) return ExpiryStatus.expired;
    if (days <= 7) return ExpiryStatus.critical;
    if (days <= 30) return ExpiryStatus.warning;
    if (days <= 90) return ExpiryStatus.approaching;
    return ExpiryStatus.good;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'batchNumber': batchNumber,
    'manufacturingDate': manufacturingDate?.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
    'quantity': quantity,
    'purchasePrice': purchasePrice,
    'sellingPrice': sellingPrice,
    'location': location,
    'createdAt': createdAt.toIso8601String(),
  };

  factory StockBatch.fromJson(Map<String, dynamic> json) => StockBatch(
    id: json['id'],
    itemId: json['itemId'],
    batchNumber: json['batchNumber'],
    manufacturingDate: json['manufacturingDate'] != null 
        ? DateTime.parse(json['manufacturingDate']) : null,
    expiryDate: json['expiryDate'] != null 
        ? DateTime.parse(json['expiryDate']) : null,
    quantity: (json['quantity'] as num).toDouble(),
    purchasePrice: (json['purchasePrice'] as num).toDouble(),
    sellingPrice: (json['sellingPrice'] as num).toDouble(),
    location: json['location'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// Stock Movement - History of all stock changes
class StockMovement {
  final String id;
  final String itemId;
  final String itemName;
  final DateTime movementDate;
  final MovementType type;
  final double quantity;
  final double previousStock;
  final double newStock;
  final double rate;
  final String? referenceId;
  final String? referenceNumber;
  final String? batchNumber;
  final String? notes;
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.movementDate,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.rate,
    this.referenceId,
    this.referenceNumber,
    this.batchNumber,
    this.notes,
    required this.createdAt,
  });

  bool get isInward => type == MovementType.purchase ||
      type == MovementType.salesReturn ||
      type == MovementType.stockAdjustmentIn ||
      type == MovementType.openingStock ||
      type == MovementType.transferIn;

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'itemName': itemName,
    'movementDate': movementDate.toIso8601String(),
    'type': type.name,
    'quantity': quantity,
    'previousStock': previousStock,
    'newStock': newStock,
    'rate': rate,
    'referenceId': referenceId,
    'referenceNumber': referenceNumber,
    'batchNumber': batchNumber,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
    id: json['id'],
    itemId: json['itemId'],
    itemName: json['itemName'],
    movementDate: DateTime.parse(json['movementDate']),
    type: MovementType.values.firstWhere((e) => e.name == json['type']),
    quantity: (json['quantity'] as num).toDouble(),
    previousStock: (json['previousStock'] as num).toDouble(),
    newStock: (json['newStock'] as num).toDouble(),
    rate: (json['rate'] as num).toDouble(),
    referenceId: json['referenceId'],
    referenceNumber: json['referenceNumber'],
    batchNumber: json['batchNumber'],
    notes: json['notes'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// Item Category
class ItemCategory {
  final String id;
  final String name;
  final String? parentId;
  final String? description;
  final Color color;
  final IconData? icon;
  final int itemCount;
  final double totalStockValue;
  final bool isActive;
  final DateTime createdAt;

  ItemCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.description,
    this.color = Colors.blue,
    this.icon,
    this.itemCount = 0,
    this.totalStockValue = 0,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'parentId': parentId,
    'description': description,
    'color': color.value,
    'itemCount': itemCount,
    'totalStockValue': totalStockValue,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ItemCategory.fromJson(Map<String, dynamic> json) => ItemCategory(
    id: json['id'],
    name: json['name'],
    parentId: json['parentId'],
    description: json['description'],
    color: Color(json['color'] ?? Colors.blue.value),
    itemCount: json['itemCount'] ?? 0,
    totalStockValue: (json['totalStockValue'] as num?)?.toDouble() ?? 0,
    isActive: json['isActive'] ?? true,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// Low Stock Alert
class LowStockAlert {
  final String itemId;
  final String itemCode;
  final String itemName;
  final String categoryName;
  final double currentStock;
  final double minStockLevel;
  final double reorderLevel;
  final String unit;
  final AlertSeverity severity;
  final DateTime alertDate;

  LowStockAlert({
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.categoryName,
    required this.currentStock,
    required this.minStockLevel,
    required this.reorderLevel,
    required this.unit,
    required this.severity,
    required this.alertDate,
  });

  double get stockDeficit => reorderLevel - currentStock;
}

/// Stock Valuation Summary
class StockValuation {
  final DateTime valuationDate;
  final int totalItems;
  final double totalQuantity;
  final double totalPurchaseValue;
  final double totalSellingValue;
  final double potentialProfit;
  final StockValuationMethod method;
  final List<CategoryValuation> categoryWise;

  StockValuation({
    required this.valuationDate,
    required this.totalItems,
    required this.totalQuantity,
    required this.totalPurchaseValue,
    required this.totalSellingValue,
    required this.potentialProfit,
    required this.method,
    required this.categoryWise,
  });

  double get potentialProfitMargin => totalSellingValue > 0
      ? (potentialProfit / totalSellingValue) * 100
      : 0;
}

class CategoryValuation {
  final String categoryId;
  final String categoryName;
  final int itemCount;
  final double totalQuantity;
  final double purchaseValue;
  final double sellingValue;

  CategoryValuation({
    required this.categoryId,
    required this.categoryName,
    required this.itemCount,
    required this.totalQuantity,
    required this.purchaseValue,
    required this.sellingValue,
  });
}

/// Enums
enum StockStatus { 
  outOfStock, 
  lowStock, 
  inStock, 
  overstock 
}

enum StockValuationMethod { 
  fifo,  // First In First Out
  lifo,  // Last In First Out
  average, // Weighted Average
  specific // Specific Identification
}

enum MovementType {
  purchase,
  purchaseReturn,
  sale,
  salesReturn,
  stockAdjustmentIn,
  stockAdjustmentOut,
  openingStock,
  transferIn,
  transferOut,
  damaged,
  expired,
}

enum ExpiryStatus {
  noExpiry,
  good,
  approaching,
  warning,
  critical,
  expired,
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

/// Extensions
extension StockStatusExt on StockStatus {
  String get displayName {
    switch (this) {
      case StockStatus.outOfStock: return 'Out of Stock';
      case StockStatus.lowStock: return 'Low Stock';
      case StockStatus.inStock: return 'In Stock';
      case StockStatus.overstock: return 'Overstock';
    }
  }

  Color get color {
    switch (this) {
      case StockStatus.outOfStock: return Colors.red;
      case StockStatus.lowStock: return Colors.orange;
      case StockStatus.inStock: return Colors.green;
      case StockStatus.overstock: return Colors.blue;
    }
  }

  IconData get icon {
    switch (this) {
      case StockStatus.outOfStock: return Icons.remove_circle;
      case StockStatus.lowStock: return Icons.warning;
      case StockStatus.inStock: return Icons.check_circle;
      case StockStatus.overstock: return Icons.inventory;
    }
  }
}

extension MovementTypeExt on MovementType {
  String get displayName {
    switch (this) {
      case MovementType.purchase: return 'Purchase';
      case MovementType.purchaseReturn: return 'Purchase Return';
      case MovementType.sale: return 'Sale';
      case MovementType.salesReturn: return 'Sales Return';
      case MovementType.stockAdjustmentIn: return 'Stock In';
      case MovementType.stockAdjustmentOut: return 'Stock Out';
      case MovementType.openingStock: return 'Opening Stock';
      case MovementType.transferIn: return 'Transfer In';
      case MovementType.transferOut: return 'Transfer Out';
      case MovementType.damaged: return 'Damaged';
      case MovementType.expired: return 'Expired';
    }
  }

  Color get color {
    switch (this) {
      case MovementType.purchase:
      case MovementType.salesReturn:
      case MovementType.stockAdjustmentIn:
      case MovementType.openingStock:
      case MovementType.transferIn:
        return Colors.green;
      case MovementType.sale:
      case MovementType.purchaseReturn:
      case MovementType.stockAdjustmentOut:
      case MovementType.transferOut:
      case MovementType.damaged:
      case MovementType.expired:
        return Colors.red;
    }
  }

  bool get isInward {
    return this == MovementType.purchase ||
        this == MovementType.salesReturn ||
        this == MovementType.stockAdjustmentIn ||
        this == MovementType.openingStock ||
        this == MovementType.transferIn;
  }
}

extension ExpiryStatusExt on ExpiryStatus {
  String get displayName {
    switch (this) {
      case ExpiryStatus.noExpiry: return 'No Expiry';
      case ExpiryStatus.good: return 'Good';
      case ExpiryStatus.approaching: return 'Approaching';
      case ExpiryStatus.warning: return 'Warning';
      case ExpiryStatus.critical: return 'Critical';
      case ExpiryStatus.expired: return 'Expired';
    }
  }

  Color get color {
    switch (this) {
      case ExpiryStatus.noExpiry: return Colors.grey;
      case ExpiryStatus.good: return Colors.green;
      case ExpiryStatus.approaching: return Colors.blue;
      case ExpiryStatus.warning: return Colors.orange;
      case ExpiryStatus.critical: return Colors.deepOrange;
      case ExpiryStatus.expired: return Colors.red;
    }
  }
}

extension AlertSeverityExt on AlertSeverity {
  String get displayName {
    switch (this) {
      case AlertSeverity.low: return 'Low';
      case AlertSeverity.medium: return 'Medium';
      case AlertSeverity.high: return 'High';
      case AlertSeverity.critical: return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case AlertSeverity.low: return Colors.blue;
      case AlertSeverity.medium: return Colors.orange;
      case AlertSeverity.high: return Colors.deepOrange;
      case AlertSeverity.critical: return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case AlertSeverity.low: return Icons.info_outline;
      case AlertSeverity.medium: return Icons.warning_amber;
      case AlertSeverity.high: return Icons.warning;
      case AlertSeverity.critical: return Icons.error;
    }
  }
}
