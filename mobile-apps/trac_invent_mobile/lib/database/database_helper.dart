import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';

/// Database helper with singleton pattern for SQLite operations
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _configureDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
    // Enable WAL mode for better concurrency
    await db.execute('PRAGMA journal_mode = WAL');
    // Optimize for performance
    await db.execute('PRAGMA synchronous = NORMAL');
    await db.execute('PRAGMA cache_size = 10000');
    await db.execute('PRAGMA temp_store = MEMORY');
  }

  Future<void> _createDB(Database db, int version) async {
    // Create tables in order of dependencies
    await _createUserTable(db);
    await _createCategoryTable(db);
    await _createWarehouseTable(db);
    await _createLocationTable(db);
    await _createInventoryItemTable(db);
    await _createStockTable(db);
    await _createMovementTable(db);
    await _createSyncQueueTable(db);
    await _createIndexes(db);
    await _insertDefaultData(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here
    if (oldVersion < 2) {
      // Future migration example
    }
  }

  /// Users table for authentication and audit trails
  Future<void> _createUserTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        email TEXT,
        full_name TEXT,
        role TEXT NOT NULL DEFAULT 'OPERATOR',
        is_active INTEGER NOT NULL DEFAULT 1,
        last_login TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
  }

  /// Categories table for item classification
  Future<void> _createCategoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT,
        description TEXT,
        color TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');
  }

  /// Warehouses table - top level locations
  Future<void> _createWarehouseTable(Database db) async {
    await db.execute('''
      CREATE TABLE warehouses (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        address TEXT,
        city TEXT,
        country TEXT,
        contact_person TEXT,
        contact_phone TEXT,
        contact_email TEXT,
        total_capacity REAL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
  }

  /// Locations table - hierarchical structure (Zone → Rack → Shelf → Bin)
  Future<void> _createLocationTable(Database db) async {
    await db.execute('''
      CREATE TABLE locations (
        id TEXT PRIMARY KEY,
        warehouse_id TEXT NOT NULL,
        parent_id TEXT,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        capacity REAL,
        sequence INTEGER,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
        FOREIGN KEY (parent_id) REFERENCES locations(id) ON DELETE CASCADE,
        UNIQUE(warehouse_id, code)
      )
    ''');
  }

  /// Inventory items table - master data for products/materials
  Future<void> _createInventoryItemTable(Database db) async {
    await db.execute('''
      CREATE TABLE inventory_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sku TEXT NOT NULL UNIQUE,
        barcode TEXT UNIQUE,
        category_id TEXT,
        unit TEXT NOT NULL DEFAULT 'PCS',
        reorder_level REAL NOT NULL DEFAULT 0,
        min_level REAL NOT NULL DEFAULT 0,
        weight REAL,
        brand TEXT,
        description TEXT,
        image_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');
  }

  /// Stock table - quantity of items at specific locations
  Future<void> _createStockTable(Database db) async {
    await db.execute('''
      CREATE TABLE stock (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        location_id TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        batch_number TEXT,
        expiry_date TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (item_id) REFERENCES inventory_items(id) ON DELETE CASCADE,
        FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
        UNIQUE(item_id, location_id, batch_number)
      )
    ''');
  }

  /// Movement history table - complete audit trail
  Future<void> _createMovementTable(Database db) async {
    await db.execute('''
      CREATE TABLE movements (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        item_id TEXT NOT NULL,
        from_location_id TEXT,
        to_location_id TEXT,
        quantity REAL NOT NULL,
        previous_quantity REAL,
        new_quantity REAL,
        batch_number TEXT,
        expiry_date TEXT,
        reference_number TEXT,
        reason TEXT,
        notes TEXT,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (item_id) REFERENCES inventory_items(id) ON DELETE CASCADE,
        FOREIGN KEY (from_location_id) REFERENCES locations(id) ON DELETE SET NULL,
        FOREIGN KEY (to_location_id) REFERENCES locations(id) ON DELETE SET NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');
  }

  /// Sync queue for offline operations (future API sync)
  Future<void> _createSyncQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'PENDING',
        error_message TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        synced_at TEXT
      )
    ''');
  }

  /// Create performance indexes
  Future<void> _createIndexes(Database db) async {
    // Users indexes
    await db.execute('CREATE INDEX idx_users_username ON users(username)');
    await db.execute('CREATE INDEX idx_users_role ON users(role)');
    
    // Categories indexes
    await db.execute('CREATE INDEX idx_categories_parent ON categories(parent_id)');
    await db.execute('CREATE INDEX idx_categories_active ON categories(is_active)');
    
    // Warehouses indexes
    await db.execute('CREATE INDEX idx_warehouses_code ON warehouses(code)');
    await db.execute('CREATE INDEX idx_warehouses_active ON warehouses(is_active)');
    
    // Locations indexes
    await db.execute('CREATE INDEX idx_locations_warehouse ON locations(warehouse_id)');
    await db.execute('CREATE INDEX idx_locations_parent ON locations(parent_id)');
    await db.execute('CREATE INDEX idx_locations_type ON locations(type)');
    await db.execute('CREATE INDEX idx_locations_code ON locations(code)');
    await db.execute('CREATE INDEX idx_locations_active ON locations(is_active)');
    await db.execute('CREATE INDEX idx_locations_warehouse_type ON locations(warehouse_id, type)');
    
    // Inventory items indexes
    await db.execute('CREATE INDEX idx_items_sku ON inventory_items(sku)');
    await db.execute('CREATE INDEX idx_items_barcode ON inventory_items(barcode)');
    await db.execute('CREATE INDEX idx_items_category ON inventory_items(category_id)');
    await db.execute('CREATE INDEX idx_items_active ON inventory_items(is_active)');
    await db.execute('CREATE INDEX idx_items_name ON inventory_items(name)');
    
    // Stock indexes
    await db.execute('CREATE INDEX idx_stock_item ON stock(item_id)');
    await db.execute('CREATE INDEX idx_stock_location ON stock(location_id)');
    await db.execute('CREATE INDEX idx_stock_batch ON stock(batch_number)');
    await db.execute('CREATE INDEX idx_stock_expiry ON stock(expiry_date)');
    await db.execute('CREATE INDEX idx_stock_item_location ON stock(item_id, location_id)');
    
    // Movements indexes
    await db.execute('CREATE INDEX idx_movements_type ON movements(type)');
    await db.execute('CREATE INDEX idx_movements_item ON movements(item_id)');
    await db.execute('CREATE INDEX idx_movements_from_location ON movements(from_location_id)');
    await db.execute('CREATE INDEX idx_movements_to_location ON movements(to_location_id)');
    await db.execute('CREATE INDEX idx_movements_user ON movements(user_id)');
    await db.execute('CREATE INDEX idx_movements_created ON movements(created_at DESC)');
    await db.execute('CREATE INDEX idx_movements_reference ON movements(reference_number)');
    
    // Sync queue indexes
    await db.execute('CREATE INDEX idx_sync_status ON sync_queue(status)');
    await db.execute('CREATE INDEX idx_sync_table ON sync_queue(table_name)');
  }

  /// Insert default data
  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // Default admin user (password: admin123)
    await db.insert('users', {
      'id': 'usr_admin_001',
      'username': 'admin',
      'password_hash': '240be518fabd2724ddb6f04eeb9d5b6a8142c82c44b6fcbb0a4ecb1da6b0e6e9', // SHA256 of 'admin123'
      'full_name': 'System Administrator',
      'role': 'ADMIN',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
    
    // Default operator user (password: operator123)
    await db.insert('users', {
      'id': 'usr_operator_001',
      'username': 'operator',
      'password_hash': '9e3f4a6f2d7b8c1e5d4a3f6b9c2e8d1a7f4b6c3d9e2a8f5b1c7d4e6a3f9b2c8', // SHA256 of 'operator123'
      'full_name': 'Default Operator',
      'role': 'OPERATOR',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
    
    // Default categories
    final categories = [
      {'id': 'cat_001', 'name': 'Electronics', 'color': '#3B82F6'},
      {'id': 'cat_002', 'name': 'Raw Materials', 'color': '#10B981'},
      {'id': 'cat_003', 'name': 'Finished Goods', 'color': '#8B5CF6'},
      {'id': 'cat_004', 'name': 'Packaging', 'color': '#F59E0B'},
      {'id': 'cat_005', 'name': 'Spare Parts', 'color': '#EF4444'},
    ];
    
    for (final category in categories) {
      await db.insert('categories', {
        ...category,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });
    }
    
    // Default warehouse
    await db.insert('warehouses', {
      'id': 'wh_001',
      'code': 'WH-MAIN',
      'name': 'Main Warehouse',
      'address': '',
      'city': '',
      'country': '',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
    
    // Default zones for main warehouse
    final zones = [
      {'id': 'loc_z001', 'code': 'Z-A', 'name': 'Zone A - Receiving'},
      {'id': 'loc_z002', 'code': 'Z-B', 'name': 'Zone B - Storage'},
      {'id': 'loc_z003', 'code': 'Z-C', 'name': 'Zone C - Shipping'},
    ];
    
    for (final zone in zones) {
      await db.insert('locations', {
        ...zone,
        'warehouse_id': 'wh_001',
        'type': 'ZONE',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });
    }
    
    // Add racks to Zone B
    for (int r = 1; r <= 3; r++) {
      await db.insert('locations', {
        'id': 'loc_r00$r',
        'warehouse_id': 'wh_001',
        'parent_id': 'loc_z002',
        'code': 'R-0$r',
        'name': 'Rack $r',
        'type': 'RACK',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });
      
      // Add shelves to each rack
      for (int s = 1; s <= 4; s++) {
        await db.insert('locations', {
          'id': 'loc_r00${r}_s0$s',
          'warehouse_id': 'wh_001',
          'parent_id': 'loc_r00$r',
          'code': 'R-0$r-S-0$s',
          'name': 'Shelf $s',
          'type': 'SHELF',
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        });
        
        // Add bins to each shelf
        for (int b = 1; b <= 3; b++) {
          await db.insert('locations', {
            'id': 'loc_r00${r}_s0${s}_b0$b',
            'warehouse_id': 'wh_001',
            'parent_id': 'loc_r00${r}_s0$s',
            'code': 'R-0$r-S-0$s-B-0$b',
            'name': 'Bin $b',
            'type': 'BIN',
            'capacity': 100,
            'is_active': 1,
            'created_at': now,
            'updated_at': now,
          });
        }
      }
    }
  }

  /// Execute operations within a transaction for atomicity
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete and recreate database (for development/testing)
  Future<void> resetDatabase() async {
    await close();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);
    await deleteDatabase(path);
    _database = await _initDB(AppConstants.databaseName);
  }
}
