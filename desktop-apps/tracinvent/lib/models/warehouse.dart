class Warehouse {
  final String id;
  final String name;
  final String type; // warehouse, branch, godown
  final String address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? contactPerson;
  final String? contactPhone;
  final bool isActive;
  final DateTime createdAt;

  Warehouse({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.city,
    this.state,
    this.pincode,
    this.contactPerson,
    this.contactPhone,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      pincode: map['pincode'],
      contactPerson: map['contactPerson'],
      contactPhone: map['contactPhone'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class StorageLocation {
  final String id;
  final String warehouseId;
  final String type; // cell, rack, zone
  final String code;
  final String? description;
  final int? row;
  final int? column;
  final int? level;
  final String zoneId;
  final String zoneName;

  StorageLocation({
    required this.id,
    required this.warehouseId,
    required this.type,
    required this.code,
    this.description,
    this.row,
    this.column,
    this.level,
    this.zoneId = '',
    this.zoneName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'warehouseId': warehouseId,
      'type': type,
      'code': code,
      'description': description,
      'row': row,
      'column': column,
      'level': level,
      'zoneId': zoneId,
      'zoneName': zoneName,
    };
  }

  factory StorageLocation.fromMap(Map<String, dynamic> map) {
    return StorageLocation(
      id: map['id'],
      warehouseId: map['warehouseId'],
      type: map['type'],
      code: map['code'],
      description: map['description'],
      row: map['row'],
      column: map['column'],
      level: map['level'],
      zoneId: map['zoneId'] ?? '',
      zoneName: map['zoneName'] ?? '',
    );
  }
}
