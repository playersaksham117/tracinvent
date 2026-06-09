import 'package:equatable/equatable.dart';

/// Warehouse Model - Top level location
class Warehouse extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? address;
  final String? city;
  final String? country;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final double? totalCapacity;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Computed fields
  final int? zoneCount;
  final int? itemCount;
  final double? usedCapacity;

  const Warehouse({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    this.city,
    this.country,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    this.totalCapacity,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.zoneCount,
    this.itemCount,
    this.usedCapacity,
  });

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      city: map['city'] as String?,
      country: map['country'] as String?,
      contactPerson: map['contact_person'] as String?,
      contactPhone: map['contact_phone'] as String?,
      contactEmail: map['contact_email'] as String?,
      totalCapacity: (map['total_capacity'] as num?)?.toDouble(),
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      zoneCount: map['zone_count'] as int?,
      itemCount: map['item_count'] as int?,
      usedCapacity: (map['used_capacity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'address': address,
      'city': city,
      'country': country,
      'contact_person': contactPerson,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'total_capacity': totalCapacity,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Warehouse copyWith({
    String? id,
    String? code,
    String? name,
    String? address,
    String? city,
    String? country,
    String? contactPerson,
    String? contactPhone,
    String? contactEmail,
    double? totalCapacity,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? zoneCount,
    int? itemCount,
    double? usedCapacity,
  }) {
    return Warehouse(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      zoneCount: zoneCount ?? this.zoneCount,
      itemCount: itemCount ?? this.itemCount,
      usedCapacity: usedCapacity ?? this.usedCapacity,
    );
  }

  @override
  List<Object?> get props => [id, code, name];
}

/// Location Model - Hierarchical: Zone → Rack → Shelf → Bin
class Location extends Equatable {
  final String id;
  final String warehouseId;
  final String? parentId;
  final String code;
  final String name;
  final String type; // ZONE, RACK, SHELF, BIN
  final double? capacity;
  final int? sequence;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Computed/joined fields
  final String? warehouseName;
  final String? parentPath;
  final String? fullPath;
  final int? childCount;
  final double? usedCapacity;
  final int? itemCount;

  const Location({
    required this.id,
    required this.warehouseId,
    this.parentId,
    required this.code,
    required this.name,
    required this.type,
    this.capacity,
    this.sequence,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.warehouseName,
    this.parentPath,
    this.fullPath,
    this.childCount,
    this.usedCapacity,
    this.itemCount,
  });

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'] as String,
      warehouseId: map['warehouse_id'] as String,
      parentId: map['parent_id'] as String?,
      code: map['code'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      capacity: (map['capacity'] as num?)?.toDouble(),
      sequence: map['sequence'] as int?,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      warehouseName: map['warehouse_name'] as String?,
      parentPath: map['parent_path'] as String?,
      fullPath: map['full_path'] as String?,
      childCount: map['child_count'] as int?,
      usedCapacity: (map['used_capacity'] as num?)?.toDouble(),
      itemCount: map['item_count'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'warehouse_id': warehouseId,
      'parent_id': parentId,
      'code': code,
      'name': name,
      'type': type,
      'capacity': capacity,
      'sequence': sequence,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Location copyWith({
    String? id,
    String? warehouseId,
    String? parentId,
    String? code,
    String? name,
    String? type,
    double? capacity,
    int? sequence,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? warehouseName,
    String? parentPath,
    String? fullPath,
    int? childCount,
    double? usedCapacity,
    int? itemCount,
  }) {
    return Location(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      parentId: parentId ?? this.parentId,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      sequence: sequence ?? this.sequence,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      warehouseName: warehouseName ?? this.warehouseName,
      parentPath: parentPath ?? this.parentPath,
      fullPath: fullPath ?? this.fullPath,
      childCount: childCount ?? this.childCount,
      usedCapacity: usedCapacity ?? this.usedCapacity,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  /// Check if this is a bin (leaf node that can hold stock)
  bool get isBin => type == 'BIN';
  
  /// Check if this location can have children
  bool get canHaveChildren => type != 'BIN';

  @override
  List<Object?> get props => [id, warehouseId, code, type];
}
