# TracInvent Database Schema Documentation

## Database Version: 4

## Overview
TracInvent uses SQLite database with a comprehensive schema supporting:
- User authentication with PIN support
- Multi-warehouse inventory management
- Hierarchical location system (Warehouse → Zone → Rack → Shelf → Bin)
- Stock tracking with batch and expiry management
- Transaction history
- Stock movements and transfers
- Currency support

---

## Table Structures

### 1. Users Table
Stores user accounts with authentication credentials and roles.

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',  -- 'admin' or 'user'
  pin TEXT,                            -- 4-digit PIN for quick login
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
```

**Fields:**
- `id`: Unique identifier (UUID)
- `name`: User's full name
- `email`: Unique email address (used for login)
- `password`: Hashed password
- `role`: User role ('admin' or 'user')
- `pin`: Optional 4-digit PIN for quick login (admin-controlled)
- `createdAt`: Account creation timestamp
- `updatedAt`: Last update timestamp

**Sample Data:**
```sql
INSERT INTO users VALUES (
  'admin-001',
  'Admin User',
  'admin@tracinvent.com',
  'admin123',  -- Should be hashed in production
  'admin',
  NULL,
  '2024-01-01T00:00:00.000Z',
  '2024-01-01T00:00:00.000Z'
);
```

---

### 2. Warehouses Table
Main storage facilities with location details.

```sql
CREATE TABLE warehouses (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  address TEXT NOT NULL,
  city TEXT,
  state TEXT,
  zipCode TEXT,
  country TEXT,
  contactPerson TEXT,
  contactEmail TEXT,
  contactPhone TEXT,
  isActive INTEGER DEFAULT 1,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);

-- Indexes
CREATE INDEX idx_warehouses_code ON warehouses(code);
CREATE INDEX idx_warehouses_active ON warehouses(isActive);
```

**Fields:**
- `id`: Unique identifier
- `name`: Warehouse name
- `code`: Unique warehouse code (e.g., "WH-001")
- `address`: Street address
- `city`, `state`, `zipCode`, `country`: Location details
- `contactPerson`, `contactEmail`, `contactPhone`: Contact information
- `isActive`: Status flag (1=active, 0=inactive)
- `createdAt`, `updatedAt`: Timestamps

---

### 3. Zones Table
First level of hierarchical location within warehouses.

```sql
CREATE TABLE zones (
  id TEXT PRIMARY KEY,
  warehouseId TEXT NOT NULL,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  description TEXT,
  isActive INTEGER DEFAULT 1,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (warehouseId) REFERENCES warehouses(id) ON DELETE CASCADE,
  UNIQUE(warehouseId, code)
);

-- Indexes
CREATE INDEX idx_zones_warehouse ON zones(warehouseId);
CREATE INDEX idx_zones_code ON zones(code);
```

**Fields:**
- `id`: Unique identifier
- `warehouseId`: Parent warehouse (FK)
- `name`: Zone name (e.g., "Zone A")
- `code`: Unique code within warehouse
- `description`: Optional description
- `isActive`: Status flag
- `createdAt`, `updatedAt`: Timestamps

**Constraints:**
- Foreign key to warehouses (cascade delete)
- Unique constraint on (warehouseId, code)

---

### 4. Racks Table
Second level of hierarchical location within zones.

```sql
CREATE TABLE racks (
  id TEXT PRIMARY KEY,
  zoneId TEXT NOT NULL,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  description TEXT,
  isActive INTEGER DEFAULT 1,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (zoneId) REFERENCES zones(id) ON DELETE CASCADE,
  UNIQUE(zoneId, code)
);

-- Indexes
CREATE INDEX idx_racks_zone ON racks(zoneId);
CREATE INDEX idx_racks_code ON racks(code);
```

**Fields:**
- `id`: Unique identifier
- `zoneId`: Parent zone (FK)
- `name`: Rack name (e.g., "A1")
- `code`: Unique code within zone
- `description`: Optional description
- `isActive`: Status flag
- `createdAt`, `updatedAt`: Timestamps

---

### 5. Shelves Table
Third level of hierarchical location within racks.

```sql
CREATE TABLE shelves (
  id TEXT PRIMARY KEY,
  rackId TEXT NOT NULL,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  level INTEGER,
  description TEXT,
  isActive INTEGER DEFAULT 1,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (rackId) REFERENCES racks(id) ON DELETE CASCADE,
  UNIQUE(rackId, code)
);

-- Indexes
CREATE INDEX idx_shelves_rack ON shelves(rackId);
CREATE INDEX idx_shelves_code ON shelves(code);
```

**Fields:**
- `id`: Unique identifier
- `rackId`: Parent rack (FK)
- `name`: Shelf name
- `code`: Unique code within rack
- `level`: Shelf level number
- `description`: Optional description
- `isActive`: Status flag
- `createdAt`, `updatedAt`: Timestamps

---

### 6. Bins Table
Fourth and final level of hierarchical location within shelves.

```sql
CREATE TABLE bins (
  id TEXT PRIMARY KEY,
  shelfId TEXT NOT NULL,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  capacity REAL,
  description TEXT,
  isActive INTEGER DEFAULT 1,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (shelfId) REFERENCES shelves(id) ON DELETE CASCADE,
  UNIQUE(shelfId, code)
);

-- Indexes
CREATE INDEX idx_bins_shelf ON bins(shelfId);
CREATE INDEX idx_bins_code ON bins(code);
```

**Fields:**
- `id`: Unique identifier
- `shelfId`: Parent shelf (FK)
- `name`: Bin name
- `code`: Unique code within shelf
- `capacity`: Maximum capacity
- `description`: Optional description
- `isActive`: Status flag
- `createdAt`, `updatedAt`: Timestamps

---

### 7. Inventory Items Table
Master list of all inventory items/products.

```sql
CREATE TABLE inventory_items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  sku TEXT UNIQUE NOT NULL,
  barcode TEXT,
  description TEXT,
  category TEXT NOT NULL,
  unit TEXT NOT NULL,
  reorderLevel REAL NOT NULL,
  minStockLevel REAL NOT NULL,
  costPrice REAL NOT NULL,
  sellingPrice REAL NOT NULL,
  supplierName TEXT,
  supplierContact TEXT,
  brand TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);

-- Indexes
CREATE INDEX idx_items_sku ON inventory_items(sku);
CREATE INDEX idx_items_barcode ON inventory_items(barcode);
CREATE INDEX idx_items_category ON inventory_items(category);
```

**Fields:**
- `id`: Unique identifier
- `name`: Item name
- `sku`: Stock Keeping Unit (unique)
- `barcode`: Barcode/QR code
- `description`: Detailed description
- `category`: Item category
- `unit`: Unit of measurement (kg, pcs, liters, etc.)
- `reorderLevel`: Level at which to reorder
- `minStockLevel`: Minimum stock alert level
- `costPrice`: Purchase/cost price
- `sellingPrice`: Selling price
- `supplierName`, `supplierContact`: Supplier details
- `brand`: Brand name
- `createdAt`, `updatedAt`: Timestamps

---

### 8. Stocks Table
Current stock levels with hierarchical location tracking.

```sql
CREATE TABLE stocks (
  id TEXT PRIMARY KEY,
  itemId TEXT NOT NULL,
  warehouseId TEXT NOT NULL,
  zoneId TEXT,
  rackId TEXT,
  shelfId TEXT,
  binId TEXT,
  quantity REAL NOT NULL,
  batchNumber TEXT,
  serialNumber TEXT,
  expiryDate TEXT,
  manufactureDate TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (itemId) REFERENCES inventory_items(id) ON DELETE CASCADE,
  FOREIGN KEY (warehouseId) REFERENCES warehouses(id) ON DELETE CASCADE,
  FOREIGN KEY (zoneId) REFERENCES zones(id) ON DELETE SET NULL,
  FOREIGN KEY (rackId) REFERENCES racks(id) ON DELETE SET NULL,
  FOREIGN KEY (shelfId) REFERENCES shelves(id) ON DELETE SET NULL,
  FOREIGN KEY (binId) REFERENCES bins(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX idx_stocks_item ON stocks(itemId);
CREATE INDEX idx_stocks_warehouse ON stocks(warehouseId);
CREATE INDEX idx_stocks_location ON stocks(warehouseId, zoneId, rackId, shelfId, binId);
CREATE INDEX idx_stocks_batch ON stocks(batchNumber);
CREATE INDEX idx_stocks_expiry ON stocks(expiryDate);
```

**Fields:**
- `id`: Unique identifier
- `itemId`: Reference to inventory item (FK)
- `warehouseId`: Warehouse location (FK)
- `zoneId`, `rackId`, `shelfId`, `binId`: Hierarchical location (FK, optional)
- `quantity`: Current stock quantity
- `batchNumber`: Batch identifier
- `serialNumber`: Serial number for tracked items
- `expiryDate`: Expiration date
- `manufactureDate`: Manufacturing date
- `createdAt`, `updatedAt`: Timestamps

**Note:** Location fields are nullable to support flexible storage. Use all levels for precise tracking or just warehouse for simple storage.

---

### 9. Transactions Table
Record of all inventory transactions (purchases, sales, adjustments).

```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,  -- 'purchase', 'sale', 'adjustment', 'return'
  itemId TEXT NOT NULL,
  warehouseId TEXT NOT NULL,
  quantity REAL NOT NULL,
  unitPrice REAL NOT NULL,
  totalAmount REAL NOT NULL,
  currency TEXT DEFAULT 'INR',
  referenceNumber TEXT,
  supplier TEXT,
  customer TEXT,
  notes TEXT,
  transactionDate TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  FOREIGN KEY (itemId) REFERENCES inventory_items(id),
  FOREIGN KEY (warehouseId) REFERENCES warehouses(id)
);

-- Indexes
CREATE INDEX idx_transactions_item ON transactions(itemId);
CREATE INDEX idx_transactions_warehouse ON transactions(warehouseId);
CREATE INDEX idx_transactions_date ON transactions(transactionDate);
CREATE INDEX idx_transactions_type ON transactions(type);
```

**Fields:**
- `id`: Unique identifier
- `type`: Transaction type (purchase/sale/adjustment/return)
- `itemId`: Item reference (FK)
- `warehouseId`: Warehouse reference (FK)
- `quantity`: Quantity transacted
- `unitPrice`: Price per unit
- `totalAmount`: Total transaction amount
- `currency`: Currency code (INR, USD, EUR, GBP)
- `referenceNumber`: External reference
- `supplier`: Supplier name (for purchases)
- `customer`: Customer name (for sales)
- `notes`: Additional notes
- `transactionDate`: Date of transaction
- `createdAt`: Record creation timestamp

---

### 10. Stock Movements Table
Track all stock movements between locations.

```sql
CREATE TABLE stock_movements (
  id TEXT PRIMARY KEY,
  itemId TEXT NOT NULL,
  fromWarehouseId TEXT,
  fromZoneId TEXT,
  fromRackId TEXT,
  fromShelfId TEXT,
  fromBinId TEXT,
  toWarehouseId TEXT,
  toZoneId TEXT,
  toRackId TEXT,
  toShelfId TEXT,
  toBinId TEXT,
  quantity REAL NOT NULL,
  movementType TEXT NOT NULL,  -- 'transfer', 'adjustment', 'return'
  reason TEXT,
  userId TEXT,
  movementDate TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  FOREIGN KEY (itemId) REFERENCES inventory_items(id),
  FOREIGN KEY (fromWarehouseId) REFERENCES warehouses(id),
  FOREIGN KEY (toWarehouseId) REFERENCES warehouses(id),
  FOREIGN KEY (userId) REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_movements_item ON stock_movements(itemId);
CREATE INDEX idx_movements_from_warehouse ON stock_movements(fromWarehouseId);
CREATE INDEX idx_movements_to_warehouse ON stock_movements(toWarehouseId);
CREATE INDEX idx_movements_date ON stock_movements(movementDate);
CREATE INDEX idx_movements_type ON stock_movements(movementType);
```

**Fields:**
- `id`: Unique identifier
- `itemId`: Item reference (FK)
- `fromWarehouseId`, `fromZoneId`, `fromRackId`, `fromShelfId`, `fromBinId`: Source location
- `toWarehouseId`, `toZoneId`, `toRackId`, `toShelfId`, `toBinId`: Destination location
- `quantity`: Quantity moved
- `movementType`: Type of movement
- `reason`: Reason for movement
- `userId`: User who initiated movement (FK)
- `movementDate`: Date of movement
- `createdAt`: Record creation timestamp

---

## Database Functions

### Initialization Functions

#### `DatabaseInitializer.initializeAllTables()`
Creates all database tables with proper schema and foreign keys.

```dart
await DatabaseInitializer.initializeAllTables();
```

#### `DatabaseInitializer.insertSampleData()`
Inserts sample data for testing:
- Admin user (admin@tracinvent.com / admin123)
- Main Warehouse (WH-001)
- Sample zones (Zone A, Zone B)
- Sample rack and shelf

```dart
await DatabaseInitializer.insertSampleData();
```

#### `DatabaseInitializer.resetDatabase()`
Drops all tables and recreates them (WARNING: Data loss).

```dart
await DatabaseInitializer.resetDatabase();
```

#### `DatabaseInitializer.verifyDatabase()`
Returns status of all tables with record counts.

```dart
Map<String, dynamic> status = await DatabaseInitializer.verifyDatabase();
// Returns: {"users": {"exists": true, "count": 1}, ...}
```

---

## Usage Examples

### Creating a New Warehouse
```dart
final db = await DatabaseService.database;
await db.insert('warehouses', {
  'id': uuid(),
  'name': 'North Warehouse',
  'code': 'WH-002',
  'address': '123 Storage Street',
  'city': 'Mumbai',
  'state': 'Maharashtra',
  'zipCode': '400001',
  'country': 'India',
  'contactPerson': 'John Doe',
  'contactEmail': 'john@example.com',
  'contactPhone': '+91 9876543210',
  'isActive': 1,
  'createdAt': DateTime.now().toIso8601String(),
  'updatedAt': DateTime.now().toIso8601String(),
});
```

### Adding Stock to Specific Location
```dart
final db = await DatabaseService.database;
await db.insert('stocks', {
  'id': uuid(),
  'itemId': 'item-123',
  'warehouseId': 'warehouse-001',
  'zoneId': 'zone-a',
  'rackId': 'rack-a1',
  'shelfId': 'shelf-a1-1',
  'binId': 'bin-a1-1-1',
  'quantity': 100,
  'batchNumber': 'BATCH-2024-001',
  'expiryDate': '2025-12-31',
  'createdAt': DateTime.now().toIso8601String(),
  'updatedAt': DateTime.now().toIso8601String(),
});
```

### Recording a Transaction
```dart
final db = await DatabaseService.database;
await db.insert('transactions', {
  'id': uuid(),
  'type': 'purchase',
  'itemId': 'item-123',
  'warehouseId': 'warehouse-001',
  'quantity': 100,
  'unitPrice': 50.00,
  'totalAmount': 5000.00,
  'currency': 'INR',
  'referenceNumber': 'PO-2024-001',
  'supplier': 'ABC Suppliers',
  'transactionDate': DateTime.now().toIso8601String(),
  'createdAt': DateTime.now().toIso8601String(),
});
```

### Tracking Stock Movement
```dart
final db = await DatabaseService.database;
await db.insert('stock_movements', {
  'id': uuid(),
  'itemId': 'item-123',
  'fromWarehouseId': 'warehouse-001',
  'fromZoneId': 'zone-a',
  'toWarehouseId': 'warehouse-001',
  'toZoneId': 'zone-b',
  'quantity': 20,
  'movementType': 'transfer',
  'reason': 'Reorganization',
  'userId': 'user-001',
  'movementDate': DateTime.now().toIso8601String(),
  'createdAt': DateTime.now().toIso8601String(),
});
```

---

## Query Examples

### Get Low Stock Items
```dart
final db = await DatabaseService.database;
final results = await db.rawQuery('''
  SELECT i.*, SUM(s.quantity) as totalStock
  FROM inventory_items i
  LEFT JOIN stocks s ON i.id = s.itemId
  GROUP BY i.id
  HAVING totalStock <= i.reorderLevel
''');
```

### Get Stock by Location
```dart
final db = await DatabaseService.database;
final results = await db.rawQuery('''
  SELECT 
    s.*,
    i.name as itemName,
    i.sku,
    w.name as warehouseName,
    z.name as zoneName,
    r.name as rackName,
    sh.name as shelfName,
    b.name as binName
  FROM stocks s
  JOIN inventory_items i ON s.itemId = i.id
  JOIN warehouses w ON s.warehouseId = w.id
  LEFT JOIN zones z ON s.zoneId = z.id
  LEFT JOIN racks r ON s.rackId = r.id
  LEFT JOIN shelves sh ON s.shelfId = sh.id
  LEFT JOIN bins b ON s.binId = b.id
  WHERE w.id = ?
''', [warehouseId]);
```

### Get Transaction History
```dart
final db = await DatabaseService.database;
final results = await db.rawQuery('''
  SELECT 
    t.*,
    i.name as itemName,
    i.sku,
    w.name as warehouseName
  FROM transactions t
  JOIN inventory_items i ON t.itemId = i.id
  JOIN warehouses w ON t.warehouseId = w.id
  WHERE t.transactionDate BETWEEN ? AND ?
  ORDER BY t.transactionDate DESC
''', [startDate, endDate]);
```

---

## Model Classes with Equality Operators

All location models (Zone, Rack, Shelf, Bin) now include proper equality operators to prevent dropdown errors:

```dart
class Zone {
  final String id;
  // ... other fields ...

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Zone && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

This ensures dropdown widgets can properly compare values by ID instead of object identity.

---

## Best Practices

1. **Always use transactions** for operations that modify multiple tables
2. **Use prepared statements** with parameters to prevent SQL injection
3. **Index frequently queried columns** for better performance
4. **Cascade deletes** are set up for parent-child relationships
5. **Set NULL on delete** for optional foreign keys (like location fields in stocks)
6. **Use ISO 8601 format** for all datetime fields
7. **Generate UUIDs** for all primary keys
8. **Validate data** before inserting into database
9. **Use batch operations** for multiple inserts/updates
10. **Regular backups** of the database file

---

## Database Location
Windows: `C:\Users\{USERNAME}\Documents\tracinvent.db`

---

## Schema Version History
- **v1**: Initial schema with basic inventory
- **v2**: Added hierarchical locations (zones, racks, shelves, bins)
- **v3**: Added stock monitoring and transfers
- **v4**: Added user authentication with PIN support and comprehensive indexes

---

## Maintenance Commands

### Check Database Integrity
```sql
PRAGMA integrity_check;
```

### Analyze Query Performance
```sql
EXPLAIN QUERY PLAN
SELECT * FROM stocks WHERE itemId = ?;
```

### Vacuum Database (Optimize)
```sql
VACUUM;
```

### Get Table Info
```sql
PRAGMA table_info(warehouses);
```

---

This documentation covers all tables, relationships, and functions in the TracInvent database. The schema supports a complete inventory management system with multi-level location tracking, user authentication, and comprehensive transaction history.
