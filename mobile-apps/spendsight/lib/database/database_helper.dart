import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart' as models;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_storage_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      // Web doesn't need real database, we'll use in-memory storage
      throw UnsupportedError('Web uses WebStorageHelper instead');
    }
    if (_database != null) return _database!;
    _database = await _initDB('spendsight.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        title $textType,
        category $textType,
        amount $realType,
        date $textType,
        note TEXT,
        isExpense $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id $idType,
        category $textType,
        amount $realType,
        startDate $textType,
        endDate $textType
      )
    ''');
  }

  // Transaction CRUD
  Future<models.Transaction> createTransaction(models.Transaction transaction) async {
    if (kIsWeb) {
      WebStorageHelper.addTransaction(transaction.toMap());
      return transaction;
    }
    final db = await instance.database;
    await db.insert('transactions', transaction.toMap());
    return transaction;
  }

  Future<List<models.Transaction>> readAllTransactions() async {
    if (kIsWeb) {
      final result = WebStorageHelper.getTransactions();
      return result.map((json) => models.Transaction.fromMap(json)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    final db = await instance.database;
    const orderBy = 'date DESC';
    final result = await db.query('transactions', orderBy: orderBy);
    return result.map((json) => models.Transaction.fromMap(json)).toList();
  }

  Future<List<models.Transaction>> readTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    if (kIsWeb) {
      final all = WebStorageHelper.getTransactions();
      return all
          .map((json) => models.Transaction.fromMap(json))
          .where((t) =>
              t.date.isAfter(start.subtract(const Duration(days: 1))) &&
              t.date.isBefore(end.add(const Duration(days: 1))))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((json) => models.Transaction.fromMap(json)).toList();
  }

  Future<int> updateTransaction(models.Transaction transaction) async {
    if (kIsWeb) {
      WebStorageHelper.deleteTransaction(transaction.id);
      WebStorageHelper.addTransaction(transaction.toMap());
      return 1;
    }
    final db = await instance.database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    if (kIsWeb) {
      WebStorageHelper.deleteTransaction(id);
      return 1;
    }
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Budget CRUD
  Future<models.Budget> createBudget(models.Budget budget) async {
    if (kIsWeb) {
      WebStorageHelper.addBudget(budget.toMap());
      return budget;
    }
    final db = await instance.database;
    await db.insert('budgets', budget.toMap());
    return budget;
  }

  Future<List<models.Budget>> readAllBudgets() async {
    if (kIsWeb) {
      final result = WebStorageHelper.getBudgets();
      return result.map((json) => models.Budget.fromMap(json)).toList();
    }
    final db = await instance.database;
    final result = await db.query('budgets');
    return result.map((json) => models.Budget.fromMap(json)).toList();
  }

  Future<int> updateBudget(models.Budget budget) async {
    if (kIsWeb) {
      WebStorageHelper.deleteBudget(budget.id);
      WebStorageHelper.addBudget(budget.toMap());
      return 1;
    }
    final db = await instance.database;
    return db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteBudget(String id) async {
    if (kIsWeb) {
      WebStorageHelper.deleteBudget(id);
      return 1;
    }
    final db = await instance.database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    if (kIsWeb) return;
    final db = await instance.database;
    db.close();
  }
}
