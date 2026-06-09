import 'package:equatable/equatable.dart';

/// Inventory Item Model - Master data for products/materials
class InventoryItem extends Equatable {
  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final String? categoryId;
  final String unit;
  final double reorderLevel;
  final double minLevel;
  final double? weight;
  final String? brand;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Computed/joined fields
  final String? categoryName;
  final double? totalQuantity;
  
  const InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    this.categoryId,
    required this.unit,
    this.reorderLevel = 0,
    this.minLevel = 0,
    this.weight,
    this.brand,
    this.description,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.totalQuantity,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      sku: map['sku'] as String,
      barcode: map['barcode'] as String?,
      categoryId: map['category_id'] as String?,
      unit: map['unit'] as String? ?? 'PCS',
      reorderLevel: (map['reorder_level'] as num?)?.toDouble() ?? 0,
      minLevel: (map['min_level'] as num?)?.toDouble() ?? 0,
      weight: (map['weight'] as num?)?.toDouble(),
      brand: map['brand'] as String?,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      categoryName: map['category_name'] as String?,
      totalQuantity: (map['total_quantity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category_id': categoryId,
      'unit': unit,
      'reorder_level': reorderLevel,
      'min_level': minLevel,
      'weight': weight,
      'brand': brand,
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? sku,
    String? barcode,
    String? categoryId,
    String? unit,
    double? reorderLevel,
    double? minLevel,
    double? weight,
    String? brand,
    String? description,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    double? totalQuantity,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      minLevel: minLevel ?? this.minLevel,
      weight: weight ?? this.weight,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      totalQuantity: totalQuantity ?? this.totalQuantity,
    );
  }

  @override
  List<Object?> get props => [id, sku, barcode, name, categoryId, unit];
}

/// Category model for item classification
class Category extends Equatable {
  final String id;
  final String name;
  final String? parentId;
  final String? description;
  final String? color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.description,
    this.color,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      parentId: map['parent_id'] as String?,
      description: map['description'] as String?,
      color: map['color'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'description': description,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, parentId];
}
