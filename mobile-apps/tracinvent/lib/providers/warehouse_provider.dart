import 'package:flutter/foundation.dart';
import '../models/warehouse.dart';
import '../services/database_service.dart';

class WarehouseProvider with ChangeNotifier {
  List<Warehouse> _warehouses = [];
  List<StorageLocation> _locations = [];
  
  List<Warehouse> get warehouses => _warehouses;
  List<StorageLocation> get locations => _locations;
  
  List<Warehouse> get activeWarehouses => 
    _warehouses.where((w) => w.isActive).toList();

  Future<void> loadWarehouses() async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('warehouses');
    _warehouses = maps.map((map) => Warehouse.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> addWarehouse(Warehouse warehouse) async {
    final db = await DatabaseService.database;
    await db.insert('warehouses', warehouse.toMap());
    await loadWarehouses();
  }

  Future<void> updateWarehouse(Warehouse warehouse) async {
    final db = await DatabaseService.database;
    await db.update(
      'warehouses',
      warehouse.toMap(),
      where: 'id = ?',
      whereArgs: [warehouse.id],
    );
    await loadWarehouses();
  }

  Future<void> deleteWarehouse(String id) async {
    final db = await DatabaseService.database;
    await db.delete('warehouses', where: 'id = ?', whereArgs: [id]);
    await loadWarehouses();
  }

  Future<void> loadStorageLocations(String warehouseId) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cells',
      where: 'warehouseId = ?',
      whereArgs: [warehouseId],
    );
    _locations = maps.map((map) => StorageLocation.fromMap({
      'id': map['id'],
      'warehouseId': map['warehouseId'],
      'code': map['code'],
      'name': map['name'],
      'type': 'cell',
    })).toList();
    notifyListeners();
  }

  Future<void> addStorageLocation(StorageLocation location) async {
    final db = await DatabaseService.database;
    await db.insert('storage_locations', location.toMap());
    await loadStorageLocations(location.warehouseId);
  }

  Future<void> updateStorageLocation(StorageLocation location) async {
    final db = await DatabaseService.database;
    await db.update(
      'storage_locations',
      location.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
    await loadStorageLocations(location.warehouseId);
  }

  Future<void> deleteStorageLocation(String id, String warehouseId) async {
    final db = await DatabaseService.database;
    await db.delete('storage_locations', where: 'id = ?', whereArgs: [id]);
    await loadStorageLocations(warehouseId);
  }
}
