import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

/// Base repository with common CRUD operations
abstract class BaseRepository<T> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  /// Table name for this repository
  String get tableName;
  
  /// Convert map to model
  T fromMap(Map<String, dynamic> map);
  
  /// Convert model to map
  Map<String, dynamic> toMap(T item);
  
  /// Get primary key field name
  String get primaryKey => 'id';
  
  /// Get database instance
  Future<Database> get db => _dbHelper.database;
  
  /// Execute within a transaction
  Future<R> transaction<R>(Future<R> Function(Transaction txn) action) {
    return _dbHelper.transaction(action);
  }
  
  /// Get all records
  Future<List<T>> getAll({
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => fromMap(map)).toList();
  }
  
  /// Get single record by ID
  Future<T?> getById(String id) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: '$primaryKey = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }
  
  /// Insert a new record
  Future<String> insert(T item) async {
    final database = await db;
    final map = toMap(item);
    await database.insert(tableName, map);
    return map[primaryKey] as String;
  }
  
  /// Insert many records
  Future<void> insertAll(List<T> items) async {
    if (items.isEmpty) return;
    await transaction((txn) async {
      final batch = txn.batch();
      for (final item in items) {
        batch.insert(tableName, toMap(item));
      }
      await batch.commit(noResult: true);
    });
  }
  
  /// Update an existing record
  Future<int> update(T item) async {
    final database = await db;
    final map = toMap(item);
    return database.update(
      tableName,
      map,
      where: '$primaryKey = ?',
      whereArgs: [map[primaryKey]],
    );
  }
  
  /// Delete a record by ID
  Future<int> delete(String id) async {
    final database = await db;
    return database.delete(
      tableName,
      where: '$primaryKey = ?',
      whereArgs: [id],
    );
  }
  
  /// Delete all records matching condition
  Future<int> deleteWhere({
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final database = await db;
    return database.delete(
      tableName,
      where: where,
      whereArgs: whereArgs,
    );
  }
  
  /// Count records
  Future<int> count({String? where, List<Object?>? whereArgs}) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName'
      '${where != null ? " WHERE $where" : ""}',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  /// Check if record exists
  Future<bool> exists(String id) async {
    final item = await getById(id);
    return item != null;
  }
  
  /// Execute raw query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final database = await db;
    return database.rawQuery(sql, arguments);
  }
  
  /// Execute raw update/insert/delete
  Future<int> rawExecute(String sql, [List<Object?>? arguments]) async {
    final database = await db;
    return database.rawUpdate(sql, arguments);
  }
}
