/// Item Model
/// Represents inventory items with GST details
library;

class Item {
  final int? id;
  final String name;
  final String? alias;
  final String? barcode;
  final String? sku;
  final int? categoryId;
  final int? hsnSacId;
  final String? hsnCode;
  final int? unitId;
  final String? unitCode;

  // Pricing
  final double costPrice;
  final double sellingPrice;
  final double mrp;
  final double wholesalePrice;
  final double minSellingPrice;
  final bool priceInclusiveTax;

  // GST Rates
  final double gstRate;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final double cessRate;
  final double cessAmount;

  // Inventory
  final double openingStock;
  final double currentStock;
  final double minStockLevel;
  final double maxStockLevel;
  final double reorderLevel;

  // Additional Info
  final String? description;
  final String? manufacturer;
  final bool batchTracking;
  final bool serialTracking;
  final bool expiryTracking;

  final bool isService;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Item({
    this.id,
    required this.name,
    this.alias,
    this.barcode,
    this.sku,
    this.categoryId,
    this.hsnSacId,
    this.hsnCode,
    this.unitId,
    this.unitCode = 'NOS',
    this.costPrice = 0,
    this.sellingPrice = 0,
    this.mrp = 0,
    this.wholesalePrice = 0,
    this.minSellingPrice = 0,
    this.priceInclusiveTax = false,
    this.gstRate = 0,
    this.cgstRate = 0,
    this.sgstRate = 0,
    this.igstRate = 0,
    this.cessRate = 0,
    this.cessAmount = 0,
    this.openingStock = 0,
    this.currentStock = 0,
    this.minStockLevel = 0,
    this.maxStockLevel = 0,
    this.reorderLevel = 0,
    this.description,
    this.manufacturer,
    this.batchTracking = false,
    this.serialTracking = false,
    this.expiryTracking = false,
    this.isService = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if stock is low
  bool get isLowStock => currentStock <= reorderLevel;

  /// Check if out of stock
  bool get isOutOfStock => currentStock <= 0;

  /// Get stock value (at cost price)
  double get stockValue => currentStock * costPrice;

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      alias: json['alias'] as String?,
      barcode: json['barcode'] as String?,
      sku: json['sku'] as String?,
      categoryId: json['category_id'] as int?,
      hsnSacId: json['hsn_sac_id'] as int?,
      hsnCode: json['hsn_code'] as String?,
      unitId: json['unit_id'] as int?,
      unitCode: json['unit_code'] as String? ?? 'NOS',
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0,
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0,
      wholesalePrice: (json['wholesale_price'] as num?)?.toDouble() ?? 0,
      minSellingPrice: (json['min_selling_price'] as num?)?.toDouble() ?? 0,
      priceInclusiveTax: (json['price_inclusive_tax'] as int?) == 1,
      gstRate: (json['gst_rate'] as num?)?.toDouble() ?? 0,
      cgstRate: (json['cgst_rate'] as num?)?.toDouble() ?? 0,
      sgstRate: (json['sgst_rate'] as num?)?.toDouble() ?? 0,
      igstRate: (json['igst_rate'] as num?)?.toDouble() ?? 0,
      cessRate: (json['cess_rate'] as num?)?.toDouble() ?? 0,
      cessAmount: (json['cess_amount'] as num?)?.toDouble() ?? 0,
      openingStock: (json['opening_stock'] as num?)?.toDouble() ?? 0,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0,
      minStockLevel: (json['min_stock_level'] as num?)?.toDouble() ?? 0,
      maxStockLevel: (json['max_stock_level'] as num?)?.toDouble() ?? 0,
      reorderLevel: (json['reorder_level'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      manufacturer: json['manufacturer'] as String?,
      batchTracking: (json['batch_tracking'] as int?) == 1,
      serialTracking: (json['serial_tracking'] as int?) == 1,
      expiryTracking: (json['expiry_tracking'] as int?) == 1,
      isService: (json['is_service'] as int?) == 1,
      isActive: (json['is_active'] as int?) == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'alias': alias,
      'barcode': barcode,
      'sku': sku,
      'category_id': categoryId,
      'hsn_code': hsnCode,
      'unit_id': unitId,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'mrp': mrp,
      'wholesale_price': wholesalePrice,
      'min_selling_price': minSellingPrice,
      'price_inclusive_tax': priceInclusiveTax,
      'gst_rate': gstRate,
      'cess_rate': cessRate,
      'opening_stock': openingStock,
      'min_stock_level': minStockLevel,
      'reorder_level': reorderLevel,
      'description': description,
      'manufacturer': manufacturer,
      'batch_tracking': batchTracking,
      'serial_tracking': serialTracking,
      'expiry_tracking': expiryTracking,
      'is_service': isService,
    };
  }

  Item copyWith({
    int? id,
    String? name,
    String? alias,
    String? barcode,
    String? sku,
    int? categoryId,
    int? hsnSacId,
    String? hsnCode,
    int? unitId,
    String? unitCode,
    double? costPrice,
    double? sellingPrice,
    double? mrp,
    double? wholesalePrice,
    double? minSellingPrice,
    bool? priceInclusiveTax,
    double? gstRate,
    double? cgstRate,
    double? sgstRate,
    double? igstRate,
    double? cessRate,
    double? cessAmount,
    double? openingStock,
    double? currentStock,
    double? minStockLevel,
    double? maxStockLevel,
    double? reorderLevel,
    String? description,
    String? manufacturer,
    bool? batchTracking,
    bool? serialTracking,
    bool? expiryTracking,
    bool? isService,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      categoryId: categoryId ?? this.categoryId,
      hsnSacId: hsnSacId ?? this.hsnSacId,
      hsnCode: hsnCode ?? this.hsnCode,
      unitId: unitId ?? this.unitId,
      unitCode: unitCode ?? this.unitCode,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      mrp: mrp ?? this.mrp,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      minSellingPrice: minSellingPrice ?? this.minSellingPrice,
      priceInclusiveTax: priceInclusiveTax ?? this.priceInclusiveTax,
      gstRate: gstRate ?? this.gstRate,
      cgstRate: cgstRate ?? this.cgstRate,
      sgstRate: sgstRate ?? this.sgstRate,
      igstRate: igstRate ?? this.igstRate,
      cessRate: cessRate ?? this.cessRate,
      cessAmount: cessAmount ?? this.cessAmount,
      openingStock: openingStock ?? this.openingStock,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      maxStockLevel: maxStockLevel ?? this.maxStockLevel,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      description: description ?? this.description,
      manufacturer: manufacturer ?? this.manufacturer,
      batchTracking: batchTracking ?? this.batchTracking,
      serialTracking: serialTracking ?? this.serialTracking,
      expiryTracking: expiryTracking ?? this.expiryTracking,
      isService: isService ?? this.isService,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Item(id: $id, name: $name, barcode: $barcode, sellingPrice: $sellingPrice, currentStock: $currentStock)';
  }
}

/// Item Search Result (lightweight for quick search)
class ItemSearchResult {
  final int id;
  final String name;
  final String? barcode;
  final String? sku;
  final String? hsnCode;
  final double sellingPrice;
  final double mrp;
  final double gstRate;
  final double currentStock;
  final String unitCode;

  ItemSearchResult({
    required this.id,
    required this.name,
    this.barcode,
    this.sku,
    this.hsnCode,
    this.sellingPrice = 0,
    this.mrp = 0,
    this.gstRate = 0,
    this.currentStock = 0,
    this.unitCode = 'NOS',
  });

  factory ItemSearchResult.fromJson(Map<String, dynamic> json) {
    return ItemSearchResult(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      barcode: json['barcode'] as String?,
      sku: json['sku'] as String?,
      hsnCode: json['hsn_code'] as String?,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0,
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0,
      gstRate: (json['gst_rate'] as num?)?.toDouble() ?? 0,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0,
      unitCode: json['unit_code'] as String? ?? 'NOS',
    );
  }
}

/// Item Category
class ItemCategory {
  final int? id;
  final String name;
  final int? parentId;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;

  ItemCategory({
    this.id,
    required this.name,
    this.parentId,
    this.description,
    this.isActive = true,
    this.createdAt,
  });

  factory ItemCategory.fromJson(Map<String, dynamic> json) {
    return ItemCategory(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      parentId: json['parent_id'] as int?,
      description: json['description'] as String?,
      isActive: (json['is_active'] as int?) == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'parent_id': parentId,
      'description': description,
    };
  }
}

/// Unit of Measurement
class Unit {
  final int? id;
  final String code;
  final String name;
  final int decimalPlaces;
  final bool isActive;

  Unit({
    this.id,
    required this.code,
    required this.name,
    this.decimalPlaces = 2,
    this.isActive = true,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as int?,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      decimalPlaces: json['decimal_places'] as int? ?? 2,
      isActive: (json['is_active'] as int?) == 1,
    );
  }
}
