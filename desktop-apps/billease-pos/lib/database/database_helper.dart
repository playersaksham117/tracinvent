import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('billease_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Get the executable directory (current running directory)
    String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // For desktop, use executable directory
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent.path;
      final dataDir = Directory(join(exeDir, 'data'));
      
      // Create data directory if it doesn't exist
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }
      
      dbPath = join(dataDir.path, filePath);
    } else {
      // For mobile, use application documents directory
      final directory = await getApplicationDocumentsDirectory();
      dbPath = join(directory.path, filePath);
    }

    return await openDatabase(
      dbPath,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Products Table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        tenant_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sku TEXT UNIQUE NOT NULL,
        barcode TEXT,
        description TEXT,
        category TEXT,
        brand TEXT,
        unit TEXT DEFAULT 'piece',
        price REAL NOT NULL DEFAULT 0,
        cost REAL DEFAULT 0,
        tax_rate REAL DEFAULT 0,
        stock_quantity INTEGER DEFAULT 0,
        low_stock_threshold INTEGER DEFAULT 10,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        tenant_id TEXT NOT NULL,
        customer_code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        postal_code TEXT,
        country TEXT DEFAULT 'India',
        customer_group TEXT DEFAULT 'regular',
        gstin TEXT,
        loyalty_points INTEGER DEFAULT 0,
        total_purchases REAL DEFAULT 0,
        total_orders INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Sales Table
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        tenant_id TEXT NOT NULL,
        sale_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        customer_phone TEXT,
        subtotal REAL NOT NULL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        total_amount REAL NOT NULL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        due_amount REAL DEFAULT 0,
        change_amount REAL DEFAULT 0,
        payment_method TEXT NOT NULL,
        payment_reference TEXT,
        notes TEXT,
        status TEXT DEFAULT 'completed',
        payment_status TEXT DEFAULT 'paid',
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Sale Items Table
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        sku TEXT NOT NULL,
        barcode TEXT,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit_price REAL NOT NULL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        tax_rate REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        total_amount REAL NOT NULL DEFAULT 0,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Stock Adjustments Table
    await db.execute('''
      CREATE TABLE stock_adjustments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        tenant_id TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        adjustment_type TEXT NOT NULL,
        quantity_change INTEGER NOT NULL,
        reason TEXT,
        performed_by TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Payment Methods Table
    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        tenant_id TEXT NOT NULL,
        name TEXT NOT NULL,
        icon TEXT,
        is_active INTEGER DEFAULT 1,
        requires_reference INTEGER DEFAULT 0,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Discounts Table
    await db.execute('''
      CREATE TABLE discounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        tenant_id TEXT NOT NULL,
        code TEXT UNIQUE NOT NULL,
        description TEXT,
        discount_type TEXT NOT NULL,
        discount_value REAL NOT NULL,
        max_discount_amount REAL,
        min_purchase_amount REAL DEFAULT 0,
        valid_from TEXT,
        valid_until TEXT,
        usage_limit INTEGER,
        times_used INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Branches Table
    await db.execute('''
      CREATE TABLE branches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        tenant_id TEXT NOT NULL,
        branch_code TEXT UNIQUE NOT NULL,
        branch_name TEXT NOT NULL,
        address TEXT,
        city TEXT,
        state TEXT,
        postal_code TEXT,
        phone TEXT,
        email TEXT,
        gstin TEXT,
        manager_name TEXT,
        is_active INTEGER DEFAULT 1,
        is_head_office INTEGER DEFAULT 0,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Stock Transfers Table
    await db.execute('''
      CREATE TABLE stock_transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        tenant_id TEXT NOT NULL,
        transfer_number TEXT UNIQUE NOT NULL,
        from_branch_id INTEGER NOT NULL,
        from_branch_name TEXT NOT NULL,
        to_branch_id INTEGER NOT NULL,
        to_branch_name TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        notes TEXT,
        approved_by TEXT,
        approved_at TEXT,
        received_by TEXT,
        received_at TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (from_branch_id) REFERENCES branches (id),
        FOREIGN KEY (to_branch_id) REFERENCES branches (id)
      )
    ''');

    // Stock Transfer Items Table
    await db.execute('''
      CREATE TABLE stock_transfer_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transfer_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        sku TEXT,
        requested_quantity INTEGER NOT NULL,
        approved_quantity INTEGER,
        received_quantity INTEGER,
        notes TEXT,
        FOREIGN KEY (transfer_id) REFERENCES stock_transfers (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Branch Stock Table (tracks stock per branch)
    await db.execute('''
      CREATE TABLE branch_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        branch_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER DEFAULT 0,
        reserved_quantity INTEGER DEFAULT 0,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (branch_id) REFERENCES branches (id),
        FOREIGN KEY (product_id) REFERENCES products (id),
        UNIQUE(branch_id, product_id)
      )
    ''');

    // Payment Vouchers Table
    await db.execute('''
      CREATE TABLE payment_vouchers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        tenant_id TEXT NOT NULL,
        voucher_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        sale_id INTEGER,
        invoice_number TEXT,
        amount REAL NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL,
        payment_reference TEXT,
        notes TEXT,
        received_by TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (sale_id) REFERENCES sales (id)
      )
    ''');

    // Create Indexes
    await db.execute('CREATE INDEX idx_products_sku ON products(sku)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
    await db.execute('CREATE INDEX idx_sales_number ON sales(sale_number)');
    await db.execute('CREATE INDEX idx_sales_created_at ON sales(created_at)');
    await db.execute('CREATE INDEX idx_sync_queue_status ON sync_queue(table_name, operation)');
    await db.execute('CREATE INDEX idx_branches_code ON branches(branch_code)');
    await db.execute('CREATE INDEX idx_stock_transfers_number ON stock_transfers(transfer_number)');
    await db.execute('CREATE INDEX idx_branch_stock_lookup ON branch_stock(branch_id, product_id)');
    await db.execute('CREATE INDEX idx_payment_vouchers_number ON payment_vouchers(voucher_number)');
    await db.execute('CREATE INDEX idx_payment_vouchers_customer ON payment_vouchers(customer_id)');

    // Insert default payment methods
    await _insertDefaultData(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add branches and stock transfer tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS branches (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id TEXT,
          tenant_id TEXT NOT NULL,
          branch_code TEXT UNIQUE NOT NULL,
          branch_name TEXT NOT NULL,
          address TEXT,
          city TEXT,
          state TEXT,
          postal_code TEXT,
          phone TEXT,
          email TEXT,
          gstin TEXT,
          manager_name TEXT,
          is_active INTEGER DEFAULT 1,
          is_head_office INTEGER DEFAULT 0,
          sync_status INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock_transfers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id TEXT,
          tenant_id TEXT NOT NULL,
          transfer_number TEXT UNIQUE NOT NULL,
          from_branch_id INTEGER NOT NULL,
          from_branch_name TEXT NOT NULL,
          to_branch_id INTEGER NOT NULL,
          to_branch_name TEXT NOT NULL,
          status TEXT DEFAULT 'pending',
          notes TEXT,
          approved_by TEXT,
          approved_at TEXT,
          received_by TEXT,
          received_at TEXT,
          sync_status INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock_transfer_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transfer_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          product_name TEXT NOT NULL,
          sku TEXT,
          requested_quantity INTEGER NOT NULL,
          approved_quantity INTEGER,
          received_quantity INTEGER,
          notes TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS branch_stock (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          branch_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          quantity INTEGER DEFAULT 0,
          reserved_quantity INTEGER DEFAULT 0,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(branch_id, product_id)
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_branches_code ON branches(branch_code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_transfers_number ON stock_transfers(transfer_number)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_branch_stock_lookup ON branch_stock(branch_id, product_id)');

      // Insert default head office branch
      await db.insert('branches', {
        'tenant_id': 'default',
        'branch_code': 'HO',
        'branch_name': 'Head Office',
        'is_active': 1,
        'is_head_office': 1,
      });
    }
    
    if (oldVersion < 3) {
      // Add payment_status and due_amount to sales table
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN payment_status TEXT DEFAULT "paid"');
      } catch (e) {
        debugPrint('Column payment_status may already exist: $e');
      }
      
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN due_amount REAL DEFAULT 0');
      } catch (e) {
        debugPrint('Column due_amount may already exist: $e');
      }
      
      // Add barcode to sale_items table
      try {
        await db.execute('ALTER TABLE sale_items ADD COLUMN barcode TEXT');
      } catch (e) {
        debugPrint('Column barcode may already exist: $e');
      }
    }
    
    if (oldVersion < 4) {
      // Add gstin and is_active columns to customers table
      try {
        await db.execute('ALTER TABLE customers ADD COLUMN gstin TEXT');
      } catch (e) {
        debugPrint('Column gstin may already exist: $e');
      }
      
      try {
        await db.execute('ALTER TABLE customers ADD COLUMN is_active INTEGER DEFAULT 1');
      } catch (e) {
        debugPrint('Column is_active may already exist: $e');
      }
    }
    
    if (oldVersion < 5) {
      // Add payment vouchers table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payment_vouchers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id TEXT,
          tenant_id TEXT NOT NULL,
          voucher_number TEXT UNIQUE NOT NULL,
          customer_id INTEGER,
          customer_name TEXT,
          sale_id INTEGER,
          invoice_number TEXT,
          amount REAL NOT NULL DEFAULT 0,
          payment_method TEXT NOT NULL,
          payment_reference TEXT,
          notes TEXT,
          received_by TEXT,
          sync_status INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (customer_id) REFERENCES customers (id),
          FOREIGN KEY (sale_id) REFERENCES sales (id)
        )
      ''');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_vouchers_number ON payment_vouchers(voucher_number)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_vouchers_customer ON payment_vouchers(customer_id)');
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    // Insert only essential payment methods, no demo products or customers
    final defaultPaymentMethods = [
      {'name': 'Cash', 'icon': '💵', 'is_active': 1, 'requires_reference': 0},
      {'name': 'Card', 'icon': '💳', 'is_active': 1, 'requires_reference': 1},
      {'name': 'UPI', 'icon': '📱', 'is_active': 1, 'requires_reference': 1},
      {'name': 'Wallet', 'icon': '👛', 'is_active': 1, 'requires_reference': 1},
      {'name': 'Bank Transfer', 'icon': '🏦', 'is_active': 1, 'requires_reference': 1},
    ];

    for (var method in defaultPaymentMethods) {
      await db.insert('payment_methods', {
        ...method,
        'tenant_id': 'default',
      });
    }
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    data['sync_status'] = 0; // Mark as not synced
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(String table, Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    data['sync_status'] = 0; // Mark as not synced
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // ============================================================================
  // SALES OPERATIONS
  // ============================================================================

  /// Generate invoice number with format: BERP/0001/25-26
  Future<String> generateInvoiceNumber() async {
    final now = DateTime.now();
    final financialYearStart = now.month >= 4 ? now.year : now.year - 1;
    final financialYearEnd = (financialYearStart + 1) % 100;
    final fyCode = '${financialYearStart.toString().substring(2)}-${financialYearEnd.toString().padLeft(2, '0')}';
    
    // Get the count of invoices in current financial year
    final db = await database;
    final startDate = DateTime(financialYearStart, 4, 1);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sales WHERE created_at >= ?',
      [startDate.toIso8601String()]
    );
    
    final count = (result.first['count'] as int?) ?? 0;
    final sequenceNumber = (count + 1).toString().padLeft(4, '0');
    
    return 'BERP/$sequenceNumber/$fyCode';
  }

  Future<int> insertSale(Map<String, dynamic> sale) async {
    final db = await database;
    return await db.insert('sales', sale);
  }

  Future<int> insertSaleItem(Map<String, dynamic> saleItem) async {
    final db = await database;
    return await db.insert('sale_items', saleItem);
  }

  Future<List<Map<String, dynamic>>> getAllSales({
    String? status,
    String? paymentStatus,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (status != null && paymentStatus != null) {
      where = 'status = ? AND payment_status = ?';
      whereArgs = [status, paymentStatus];
    } else if (status != null) {
      where = 'status = ?';
      whereArgs = [status];
    } else if (paymentStatus != null) {
      where = 'payment_status = ?';
      whereArgs = [paymentStatus];
    }

    return await db.query(
      'sales',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> getSaleById(int id) async {
    final db = await database;
    final results = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getSaleByNumber(String saleNumber) async {
    final db = await database;
    final results = await db.query('sales', where: 'sale_number = ?', whereArgs: [saleNumber]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getSaleItems(int saleId) async {
    final db = await database;
    return await db.query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
  }

  Future<int> updateSale(int id, Map<String, dynamic> sale) async {
    final db = await database;
    return await db.update('sales', sale, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSale(int id) async {
    final db = await database;
    return await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  // Get pending/credit sales
  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    return await getAllSales(
      status: 'completed',
      paymentStatus: 'partial',
    );
  }

  Future<List<Map<String, dynamic>>> getCreditSales() async {
    return await getAllSales(
      status: 'completed',
      paymentStatus: 'credit',
    );
  }

  // ============================================================================
  // CUSTOMER OPERATIONS
  // ============================================================================

  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    
    // Add required fields if not present
    customer['tenant_id'] = customer['tenant_id'] ?? 'default';
    
    // Generate customer code if not provided
    if (customer['customer_code'] == null) {
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
      final customerCount = count.first['count'] as int;
      customer['customer_code'] = 'CUST${(customerCount + 1).toString().padLeft(4, '0')}';
    }
    
    customer['created_at'] = DateTime.now().toIso8601String();
    customer['updated_at'] = DateTime.now().toIso8601String();
    return await db.insert('customers', customer);
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return await db.query('customers', 
      where: 'is_active = ?', 
      whereArgs: [1],
      orderBy: 'name ASC'
    );
  }

  Future<Map<String, dynamic>?> getCustomerById(int id) async {
    final db = await database;
    final results = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getCustomerByPhone(String phone) async {
    final db = await database;
    final results = await db.query('customers', where: 'phone = ?', whereArgs: [phone]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    customer['updated_at'] = DateTime.now().toIso8601String();
    // Ensure tenant_id is present
    customer['tenant_id'] = customer['tenant_id'] ?? 'default';
    final id = customer['id'];
    customer.remove('id');
    return await db.update('customers', customer, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.update('customers', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateCustomerLoyaltyPoints(int customerId, int points) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE customers SET loyalty_points = loyalty_points + ? WHERE id = ?',
      [points, customerId]
    );
  }

  Future<List<Map<String, dynamic>>> getCustomerSales(int customerId) async {
    final db = await database;
    return await db.query('sales',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC'
    );
  }

  // ============================================================================
  // BRANCH OPERATIONS
  // ============================================================================

  Future<int> insertBranch(Map<String, dynamic> branch) async {
    return await insert('branches', branch);
  }

  Future<List<Map<String, dynamic>>> getAllBranches() async {
    return await query('branches', orderBy: 'branch_name ASC');
  }

  Future<List<Map<String, dynamic>>> getActiveBranches() async {
    return await query('branches', 
      where: 'is_active = ?', 
      whereArgs: [1],
      orderBy: 'branch_name ASC'
    );
  }

  Future<Map<String, dynamic>?> getBranchById(int id) async {
    final results = await query('branches', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getBranchByCode(String code) async {
    final results = await query('branches', where: 'branch_code = ?', whereArgs: [code]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateBranch(int id, Map<String, dynamic> branch) async {
    return await update('branches', branch, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBranch(int id) async {
    return await delete('branches', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================================
  // STOCK TRANSFER OPERATIONS
  // ============================================================================

  Future<int> insertStockTransfer(Map<String, dynamic> transfer) async {
    return await insert('stock_transfers', transfer);
  }

  Future<int> insertStockTransferItem(Map<String, dynamic> item) async {
    return await insert('stock_transfer_items', item);
  }

  Future<List<Map<String, dynamic>>> getAllStockTransfers() async {
    return await query('stock_transfers', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getStockTransfersByBranch(int branchId) async {
    return await query('stock_transfers',
      where: 'from_branch_id = ? OR to_branch_id = ?',
      whereArgs: [branchId, branchId],
      orderBy: 'created_at DESC'
    );
  }

  Future<Map<String, dynamic>?> getStockTransferById(int id) async {
    final results = await query('stock_transfers', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getStockTransferItems(int transferId) async {
    return await query('stock_transfer_items', 
      where: 'transfer_id = ?', 
      whereArgs: [transferId]
    );
  }

  Future<int> updateStockTransfer(int id, Map<String, dynamic> transfer) async {
    return await update('stock_transfers', transfer, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateStockTransferStatus(int id, String status, {
    String? approvedBy,
    String? receivedBy,
  }) async {
    final data = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (approvedBy != null) {
      data['approved_by'] = approvedBy;
      data['approved_at'] = DateTime.now().toIso8601String();
    }
    
    if (receivedBy != null) {
      data['received_by'] = receivedBy;
      data['received_at'] = DateTime.now().toIso8601String();
    }
    
    return await update('stock_transfers', data, where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================================
  // BRANCH STOCK OPERATIONS
  // ============================================================================

  Future<int> updateBranchStock(int branchId, int productId, int quantity) async {
    final db = await database;
    
    // Check if record exists
    final existing = await db.query(
      'branch_stock',
      where: 'branch_id = ? AND product_id = ?',
      whereArgs: [branchId, productId],
    );
    
    if (existing.isEmpty) {
      return await db.insert('branch_stock', {
        'branch_id': branchId,
        'product_id': productId,
        'quantity': quantity,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      return await db.update(
        'branch_stock',
        {
          'quantity': quantity,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'branch_id = ? AND product_id = ?',
        whereArgs: [branchId, productId],
      );
    }
  }

  Future<Map<String, dynamic>?> getBranchStock(int branchId, int productId) async {
    final results = await query('branch_stock',
      where: 'branch_id = ? AND product_id = ?',
      whereArgs: [branchId, productId]
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllBranchStock(int branchId) async {
    return await query('branch_stock',
      where: 'branch_id = ?',
      whereArgs: [branchId]
    );
  }

  Future<void> transferStock(int fromBranchId, int toBranchId, int productId, int quantity) async {
    final db = await database;
    await db.transaction((txn) async {
      // Deduct from source branch
      final fromStock = await txn.query(
        'branch_stock',
        where: 'branch_id = ? AND product_id = ?',
        whereArgs: [fromBranchId, productId],
      );
      
      if (fromStock.isNotEmpty) {
        final currentQty = fromStock.first['quantity'] as int;
        await txn.update(
          'branch_stock',
          {
            'quantity': currentQty - quantity,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'branch_id = ? AND product_id = ?',
          whereArgs: [fromBranchId, productId],
        );
      }
      
      // Add to destination branch
      final toStock = await txn.query(
        'branch_stock',
        where: 'branch_id = ? AND product_id = ?',
        whereArgs: [toBranchId, productId],
      );
      
      if (toStock.isEmpty) {
        await txn.insert('branch_stock', {
          'branch_id': toBranchId,
          'product_id': productId,
          'quantity': quantity,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        final currentQty = toStock.first['quantity'] as int;
        await txn.update(
          'branch_stock',
          {
            'quantity': currentQty + quantity,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'branch_id = ? AND product_id = ?',
          whereArgs: [toBranchId, productId],
        );
      }
    });
  }

  // Payment Voucher Methods
  Future<int> insertPaymentVoucher(Map<String, dynamic> voucher) async {
    final db = await database;
    return await db.transaction((txn) async {
      // Insert voucher
      final voucherId = await txn.insert('payment_vouchers', {
        ...voucher,
        'tenant_id': 'default',
        'sync_status': 0,
      });

      // Update sale if sale_id provided
      if (voucher['sale_id'] != null) {
        final saleId = voucher['sale_id'] as int;
        final amount = voucher['amount'] as double;

        // Get current sale
        final sales = await txn.query('sales', where: 'id = ?', whereArgs: [saleId]);
        if (sales.isNotEmpty) {
          final sale = sales.first;
          final paidAmount = (sale['paid_amount'] as double?) ?? 0.0;
          final totalAmount = sale['total_amount'] as double;

          final newPaidAmount = paidAmount + amount;
          final newDueAmount = totalAmount - newPaidAmount;

          String paymentStatus = 'paid';
          if (newDueAmount > 0.01) {
            paymentStatus = 'partial';
          } else if (newDueAmount < -0.01) {
            paymentStatus = 'paid';
          }

          await txn.update(
            'sales',
            {
              'paid_amount': newPaidAmount,
              'due_amount': newDueAmount > 0 ? newDueAmount : 0,
              'payment_status': paymentStatus,
            },
            where: 'id = ?',
            whereArgs: [saleId],
          );
        }
      }

      return voucherId;
    });
  }

  Future<List<Map<String, dynamic>>> getPaymentVouchers({
    int? saleId,
    int? customerId,
    String? orderBy,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (saleId != null && customerId != null) {
      where = 'sale_id = ? OR customer_id = ?';
      whereArgs = [saleId, customerId];
    } else if (saleId != null) {
      where = 'sale_id = ?';
      whereArgs = [saleId];
    } else if (customerId != null) {
      where = 'customer_id = ?';
      whereArgs = [customerId];
    }

    return await db.query(
      'payment_vouchers',
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy ?? 'created_at DESC',
    );
  }

  Future<String> generateVoucherNumber() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM payment_vouchers WHERE DATE(created_at) = DATE("now")'
    );
    final count = result.first['count'] as int;
    final today = DateTime.now();
    return 'PV${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}-${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<int> deletePaymentVoucher(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      // Get voucher details first
      final vouchers = await txn.query('payment_vouchers', where: 'id = ?', whereArgs: [id]);
      if (vouchers.isEmpty) return 0;

      final voucher = vouchers.first;
      final saleId = voucher['sale_id'] as int?;
      final amount = voucher['amount'] as double;

      // Delete voucher
      final deleted = await txn.delete('payment_vouchers', where: 'id = ?', whereArgs: [id]);

      // Reverse sale payment if applicable
      if (saleId != null) {
        final sales = await txn.query('sales', where: 'id = ?', whereArgs: [saleId]);
        if (sales.isNotEmpty) {
          final sale = sales.first;
          final paidAmount = (sale['paid_amount'] as double?) ?? 0.0;
          final totalAmount = sale['total_amount'] as double;

          final newPaidAmount = paidAmount - amount;
          final newDueAmount = totalAmount - newPaidAmount;

          String paymentStatus = 'credit';
          if (newPaidAmount > 0.01 && newDueAmount > 0.01) {
            paymentStatus = 'partial';
          } else if (newDueAmount <= 0.01) {
            paymentStatus = 'paid';
          }

          await txn.update(
            'sales',
            {
              'paid_amount': newPaidAmount > 0 ? newPaidAmount : 0,
              'due_amount': newDueAmount > 0 ? newDueAmount : 0,
              'payment_status': paymentStatus,
            },
            where: 'id = ?',
            whereArgs: [saleId],
          );
        }
      }

      return deleted;
    });
  }

  // Reports and Analytics Methods
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final db = await database;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Today's sales
    final todaySales = await db.rawQuery('''
      SELECT 
        COUNT(*) as count,
        COALESCE(SUM(total_amount), 0) as total,
        COALESCE(SUM(CASE WHEN payment_status = 'paid' THEN total_amount ELSE 0 END), 0) as paid_total
      FROM sales 
      WHERE DATE(created_at) = ?
    ''', [todayStr]);

    // This week's sales
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekStartStr = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    
    final weekSales = await db.rawQuery('''
      SELECT COALESCE(SUM(total_amount), 0) as total
      FROM sales 
      WHERE DATE(created_at) >= ?
    ''', [weekStartStr]);

    // Outstanding dues
    final dues = await db.rawQuery('''
      SELECT COALESCE(SUM(due_amount), 0) as total
      FROM sales 
      WHERE payment_status IN ('partial', 'credit')
    ''');

    // Top products (last 30 days)
    final monthAgo = today.subtract(const Duration(days: 30));
    final monthAgoStr = '${monthAgo.year}-${monthAgo.month.toString().padLeft(2, '0')}-${monthAgo.day.toString().padLeft(2, '0')}';
    
    final topProducts = await db.rawQuery('''
      SELECT 
        si.product_name,
        SUM(si.quantity) as total_quantity,
        SUM(si.total_amount) as total_revenue
      FROM sale_items si
      JOIN sales s ON si.sale_id = s.id
      WHERE DATE(s.created_at) >= ?
      GROUP BY si.product_name
      ORDER BY total_revenue DESC
      LIMIT 5
    ''', [monthAgoStr]);

    // Payment method breakdown (last 30 days)
    final paymentBreakdown = await db.rawQuery('''
      SELECT 
        payment_method,
        COUNT(*) as count,
        COALESCE(SUM(paid_amount), 0) as total
      FROM sales 
      WHERE DATE(created_at) >= ?
      GROUP BY payment_method
    ''', [monthAgoStr]);

    return {
      'todaySales': todaySales.first['count'],
      'todayRevenue': todaySales.first['total'],
      'todayPaidRevenue': todaySales.first['paid_total'],
      'weekRevenue': weekSales.first['total'],
      'outstandingDues': dues.first['total'],
      'topProducts': topProducts,
      'paymentBreakdown': paymentBreakdown,
    };
  }

  Future<List<Map<String, dynamic>>> getCreditInvoices() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        s.*,
        c.name as customer_name,
        c.phone as customer_phone
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.payment_status IN ('partial', 'credit')
      ORDER BY s.created_at DESC
    ''');
  }

  Future<Map<String, dynamic>> getCustomerStatement(int customerId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    
    String dateFilter = '';
    List<dynamic> args = [customerId];
    
    if (startDate != null && endDate != null) {
      final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      dateFilter = ' AND DATE(created_at) BETWEEN ? AND ?';
      args.addAll([startStr, endStr]);
    }

    // Get customer details
    final customers = await db.query('customers', where: 'id = ?', whereArgs: [customerId]);
    if (customers.isEmpty) return {};

    // Get sales
    final sales = await db.rawQuery('''
      SELECT * FROM sales 
      WHERE customer_id = ?$dateFilter
      ORDER BY created_at DESC
    ''', args);

    // Get payment vouchers
    final vouchers = await db.rawQuery('''
      SELECT * FROM payment_vouchers 
      WHERE customer_id = ?${dateFilter.replaceAll('created_at', 'created_at')}
      ORDER BY created_at DESC
    ''', args);

    // Calculate totals
    double totalSales = 0;
    double totalPaid = 0;
    double totalDue = 0;

    for (var sale in sales) {
      totalSales += sale['total_amount'] as double;
      totalPaid += (sale['paid_amount'] as double?) ?? 0;
      totalDue += (sale['due_amount'] as double?) ?? 0;
    }

    return {
      'customer': customers.first,
      'sales': sales,
      'vouchers': vouchers,
      'totalSales': totalSales,
      'totalPaid': totalPaid,
      'totalDue': totalDue,
    };
  }
}

