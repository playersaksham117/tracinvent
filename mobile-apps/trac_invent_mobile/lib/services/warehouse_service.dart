import '../models/warehouse.dart';
import '../repositories/warehouse_repository.dart';

/// Service for warehouse and location operations
class WarehouseService {
  final WarehouseRepository _warehouseRepository = WarehouseRepository();
  final LocationRepository _locationRepository = LocationRepository();
  
  // ==================== WAREHOUSES ====================
  
  /// Get all warehouses with statistics
  Future<List<Warehouse>> getWarehouses() async {
    return _warehouseRepository.getAllWithStats();
  }
  
  /// Get warehouse by ID
  Future<Warehouse?> getWarehouseById(String id) async {
    return _warehouseRepository.getByIdWithStats(id);
  }
  
  /// Get warehouse by code
  Future<Warehouse?> getWarehouseByCode(String code) async {
    return _warehouseRepository.getByCode(code);
  }
  
  /// Create warehouse
  Future<Warehouse> createWarehouse({
    required String code,
    required String name,
    String? address,
    String? city,
    String? country,
    String? contactPerson,
    String? contactPhone,
    String? contactEmail,
    double? totalCapacity,
  }) async {
    // Validate code uniqueness
    if (await _warehouseRepository.codeExists(code)) {
      throw Exception('Warehouse code already exists: $code');
    }
    
    final now = DateTime.now();
    final warehouse = Warehouse(
      id: 'wh_${now.millisecondsSinceEpoch}',
      code: code.toUpperCase(),
      name: name,
      address: address,
      city: city,
      country: country,
      contactPerson: contactPerson,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      totalCapacity: totalCapacity,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    
    await _warehouseRepository.insert(warehouse);
    return warehouse;
  }
  
  /// Update warehouse
  Future<Warehouse> updateWarehouse(Warehouse warehouse) async {
    if (await _warehouseRepository.codeExists(warehouse.code, excludeId: warehouse.id)) {
      throw Exception('Warehouse code already exists: ${warehouse.code}');
    }
    
    final updated = warehouse.copyWith(updatedAt: DateTime.now());
    await _warehouseRepository.update(updated);
    return updated;
  }
  
  /// Delete warehouse (soft delete)
  Future<void> deleteWarehouse(String id) async {
    final warehouse = await _warehouseRepository.getById(id);
    if (warehouse == null) throw Exception('Warehouse not found');
    
    final deactivated = warehouse.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
    await _warehouseRepository.update(deactivated);
  }
  
  // ==================== LOCATIONS ====================
  
  /// Get zones for a warehouse
  Future<List<Location>> getZones(String warehouseId) async {
    return _locationRepository.getZones(warehouseId);
  }
  
  /// Get children of a location
  Future<List<Location>> getLocationChildren(String parentId) async {
    return _locationRepository.getChildren(parentId);
  }
  
  /// Get all bins for a warehouse
  Future<List<Location>> getBins(String warehouseId) async {
    return _locationRepository.getBins(warehouseId);
  }
  
  /// Get location by ID with full path
  Future<Location?> getLocationById(String id) async {
    return _locationRepository.getByIdWithPath(id);
  }
  
  /// Get full path for a location
  Future<String> getLocationPath(String locationId) async {
    return _locationRepository.getFullPath(locationId);
  }
  
  /// Search locations by code
  Future<List<Location>> searchLocations(String query, {String? warehouseId}) async {
    if (query.isEmpty) return [];
    return _locationRepository.searchByCode(query, warehouseId: warehouseId);
  }
  
  /// Create location
  Future<Location> createLocation({
    required String warehouseId,
    String? parentId,
    required String code,
    required String name,
    required String type,
    double? capacity,
    int? sequence,
    String? description,
  }) async {
    // Validate code uniqueness in warehouse
    if (await _locationRepository.codeExistsInWarehouse(warehouseId, code)) {
      throw Exception('Location code already exists in this warehouse: $code');
    }
    
    // Validate hierarchy
    if (parentId != null) {
      final parent = await _locationRepository.getById(parentId);
      if (parent == null) throw Exception('Parent location not found');
      
      // Ensure parent can have children
      if (!parent.canHaveChildren) {
        throw Exception('Cannot add children to a bin location');
      }
      
      // Ensure type is correct child type
      final expectedType = _getChildType(parent.type);
      if (expectedType != type) {
        throw Exception('Invalid location type. Expected: $expectedType');
      }
    } else {
      // No parent means this should be a zone
      if (type != 'ZONE') {
        throw Exception('Root locations must be zones');
      }
    }
    
    final now = DateTime.now();
    final location = Location(
      id: 'loc_${now.millisecondsSinceEpoch}',
      warehouseId: warehouseId,
      parentId: parentId,
      code: code.toUpperCase(),
      name: name,
      type: type,
      capacity: capacity,
      sequence: sequence,
      description: description,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    
    await _locationRepository.insert(location);
    return location;
  }
  
  /// Update location
  Future<Location> updateLocation(Location location) async {
    if (await _locationRepository.codeExistsInWarehouse(
      location.warehouseId,
      location.code,
      excludeId: location.id,
    )) {
      throw Exception('Location code already exists: ${location.code}');
    }
    
    final updated = location.copyWith(updatedAt: DateTime.now());
    await _locationRepository.update(updated);
    return updated;
  }
  
  /// Delete location (soft delete)
  Future<void> deleteLocation(String id) async {
    final location = await _locationRepository.getById(id);
    if (location == null) throw Exception('Location not found');
    
    // Check if has children
    final children = await _locationRepository.getChildren(id);
    if (children.isNotEmpty) {
      throw Exception('Cannot delete location with children');
    }
    
    final deactivated = location.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
    await _locationRepository.update(deactivated);
  }
  
  /// Get expected child type
  String? _getChildType(String parentType) {
    switch (parentType) {
      case 'WAREHOUSE': return 'ZONE';
      case 'ZONE': return 'RACK';
      case 'RACK': return 'SHELF';
      case 'SHELF': return 'BIN';
      default: return null;
    }
  }
  
  /// Get locations with stock info
  Future<List<Location>> getLocationsWithStock(String warehouseId) async {
    return _locationRepository.getLocationsWithStock(warehouseId);
  }
  
  /// Get location counts by type
  Future<Map<String, int>> getLocationCounts(String warehouseId) async {
    return _locationRepository.getCountsByType(warehouseId);
  }
  
  /// Bulk create locations (for wizard)
  Future<List<Location>> bulkCreateLocations({
    required String warehouseId,
    required int zoneCount,
    required int racksPerZone,
    required int shelvesPerRack,
    required int binsPerShelf,
  }) async {
    final created = <Location>[];
    final now = DateTime.now();
    var counter = 0;
    
    for (int z = 1; z <= zoneCount; z++) {
      final zoneCode = 'Z-${z.toString().padLeft(2, '0')}';
      final zone = await createLocation(
        warehouseId: warehouseId,
        code: zoneCode,
        name: 'Zone $z',
        type: 'ZONE',
      );
      created.add(zone);
      
      for (int r = 1; r <= racksPerZone; r++) {
        final rackCode = '$zoneCode-R-${r.toString().padLeft(2, '0')}';
        final rack = await createLocation(
          warehouseId: warehouseId,
          parentId: zone.id,
          code: rackCode,
          name: 'Rack $r',
          type: 'RACK',
        );
        created.add(rack);
        
        for (int s = 1; s <= shelvesPerRack; s++) {
          final shelfCode = '$rackCode-S-${s.toString().padLeft(2, '0')}';
          final shelf = await createLocation(
            warehouseId: warehouseId,
            parentId: rack.id,
            code: shelfCode,
            name: 'Shelf $s',
            type: 'SHELF',
          );
          created.add(shelf);
          
          for (int b = 1; b <= binsPerShelf; b++) {
            final binCode = '$shelfCode-B-${b.toString().padLeft(2, '0')}';
            final bin = await createLocation(
              warehouseId: warehouseId,
              parentId: shelf.id,
              code: binCode,
              name: 'Bin $b',
              type: 'BIN',
              capacity: 100,
            );
            created.add(bin);
            counter++;
          }
        }
      }
    }
    
    return created;
  }
}
