# Add Stock to Warehouse - Complete Documentation

## Overview
A production-ready warehouse stock entry module for ERP/WMS systems with hierarchical location management following the structure: **Warehouse → Zone → Rack → Shelf → Bin**.

## Features Implemented

### ✅ Core Functionality
1. **Hierarchical Location Selection**
   - Zone → Rack → Shelf → Bin (Cell) hierarchy
   - Dependent dropdowns with auto-load
   - Inline creation of locations without leaving the screen
   - Duplicate location prevention per hierarchy level

2. **Stock Entry Workflow**
   - Step 1: Select Warehouse
   - Step 2: Select or Create Location (Zone/Rack/Shelf/Bin)
   - Step 3: Select Item (with SKU and current stock display)
   - Step 4: Enter Quantity (with batch and expiry tracking)

3. **Validation Rules**
   - ✅ Warehouse is mandatory
   - ✅ Complete location path (Zone → Rack → Shelf → Bin) is mandatory
   - ✅ Item is mandatory
   - ✅ Quantity must be greater than zero
   - ✅ Duplicate location prevention within same hierarchy level
   - ✅ Case-insensitive location name checking

4. **Location Code Generation**
   - Human-readable codes: `WH-01/A/R03/S02/B05`
   - Format: `WarehouseCode/ZoneCode/RackCode/ShelfCode/BinCode`
   - Auto-sanitizes names to extract meaningful codes

5. **UX Enhancements**
   - Visual step-by-step progress indicator
   - Auto-focus to quantity field after item selection
   - Full location path display before saving
   - Inline location creation with quick add/cancel
   - Success/error notifications
   - Form reset after successful entry

---

## Database Schema

### Tables

#### 1. Zones Table
```sql
CREATE TABLE zones (
  id TEXT PRIMARY KEY,
  warehouseId TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (warehouseId) REFERENCES warehouses (id) ON DELETE CASCADE
);
CREATE INDEX idx_zones_warehouse ON zones(warehouseId);
```

#### 2. Racks Table
```sql
CREATE TABLE racks (
  id TEXT PRIMARY KEY,
  zoneId TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (zoneId) REFERENCES zones (id) ON DELETE CASCADE
);
CREATE INDEX idx_racks_zone ON racks(zoneId);
```

#### 3. Shelves Table
```sql
CREATE TABLE shelves (
  id TEXT PRIMARY KEY,
  rackId TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (rackId) REFERENCES racks (id) ON DELETE CASCADE
);
CREATE INDEX idx_shelves_rack ON shelves(rackId);
```

#### 4. Bins Table
```sql
CREATE TABLE bins (
  id TEXT PRIMARY KEY,
  shelfId TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  maxCapacity REAL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (shelfId) REFERENCES shelves (id) ON DELETE CASCADE
);
CREATE INDEX idx_bins_shelf ON bins(shelfId);
```

#### 5. Stock Table (Updated)
```sql
CREATE TABLE stock (
  id TEXT PRIMARY KEY,
  itemId TEXT NOT NULL,
  warehouseId TEXT NOT NULL,
  zoneId TEXT,
  rackId TEXT,
  shelfId TEXT,
  binId TEXT,
  quantity REAL NOT NULL,
  batchNumber TEXT,
  expiryDate TEXT,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (itemId) REFERENCES inventory_items (id),
  FOREIGN KEY (warehouseId) REFERENCES warehouses (id),
  FOREIGN KEY (zoneId) REFERENCES zones (id),
  FOREIGN KEY (rackId) REFERENCES racks (id),
  FOREIGN KEY (shelfId) REFERENCES shelves (id),
  FOREIGN KEY (binId) REFERENCES bins (id)
);
CREATE INDEX idx_stock_item ON stock(itemId);
CREATE INDEX idx_stock_warehouse ON stock(warehouseId);
CREATE INDEX idx_stock_bin ON stock(binId);
CREATE INDEX idx_stock_expiry ON stock(expiryDate);
```

---

## API Data Structures

### Request Payload for Stock Entry

```json
{
  "itemId": "uuid-v4",
  "warehouseId": "uuid-v4",
  "location": {
    "zoneId": "uuid-v4",
    "zoneName": "Zone A",
    "rackId": "uuid-v4",
    "rackName": "Rack 3",
    "shelfId": "uuid-v4",
    "shelfName": "Shelf 2",
    "binId": "uuid-v4",
    "binName": "Bin 5",
    "locationCode": "WH-01/A/R03/S02/B05"
  },
  "quantity": 100.0,
  "batchNumber": "BATCH-2026-001",
  "expiryDate": "2027-01-21T00:00:00Z"
}
```

### Response Payload

```json
{
  "success": true,
  "message": "Stock added successfully at WH-01/A/R03/S02/B05",
  "stockEntry": {
    "id": "stock-uuid",
    "itemId": "item-uuid",
    "itemName": "Product XYZ",
    "itemSku": "SKU-12345",
    "warehouseId": "warehouse-uuid",
    "warehouseName": "Main Warehouse",
    "zoneId": "zone-uuid",
    "rackId": "rack-uuid",
    "shelfId": "shelf-uuid",
    "binId": "bin-uuid",
    "locationCode": "WH-01/A/R03/S02/B05",
    "locationPath": "Main Warehouse → Zone A → Rack 3 → Shelf 2 → Bin 5",
    "quantity": 100.0,
    "batchNumber": "BATCH-2026-001",
    "expiryDate": "2027-01-21T00:00:00Z",
    "updatedAt": "2026-01-21T10:30:00Z"
  }
}
```

### Location Creation Payload

```json
{
  "type": "zone|rack|shelf|bin",
  "parentId": "parent-uuid",
  "name": "Zone A",
  "description": "Main storage zone",
  "maxCapacity": 1000.0  // Optional, for bins only
}
```

---

## Provider API (StockEntryProvider)

### Location Management Methods

```dart
// Load locations by parent
Future<List<Zone>> loadZones(String warehouseId)
Future<List<Rack>> loadRacks(String zoneId)
Future<List<Shelf>> loadShelves(String rackId)
Future<List<Bin>> loadBins(String shelfId)

// Create locations with duplicate prevention
Future<Zone> createZone({
  required String warehouseId,
  required String name,
  String? description,
})

Future<Rack> createRack({
  required String zoneId,
  required String name,
  String? description,
})

Future<Shelf> createShelf({
  required String rackId,
  required String name,
  String? description,
})

Future<Bin> createBin({
  required String shelfId,
  required String name,
  String? description,
  double? maxCapacity,
})
```

### Stock Entry Method

```dart
Future<void> addStockEntry({
  required String itemId,
  required String warehouseId,
  required String zoneId,
  required String rackId,
  required String shelfId,
  required String binId,
  required double quantity,
  String? batchNumber,
  DateTime? expiryDate,
})
```

### Utility Methods

```dart
// Generate human-readable location code
String generateLocationCode({
  required String warehouseName,
  required String zoneName,
  required String rackName,
  required String shelfName,
  required String binName,
})

// Get full location path for display
Future<LocationPath?> getLocationPath({
  String? warehouseId,
  String? zoneId,
  String? rackId,
  String? shelfId,
  String? binId,
})

// Check if location exists
Future<bool> checkLocationExists({
  required String warehouseId,
  required String zoneName,
  required String rackName,
  required String shelfName,
  required String binName,
})
```

---

## Usage Examples

### 1. Basic Stock Entry Flow

```dart
// Initialize provider
final stockProvider = Provider.of<StockEntryProvider>(context, listen: false);

// Load locations for selected warehouse
final zones = await stockProvider.loadZones(warehouseId);

// Create new zone if needed
final newZone = await stockProvider.createZone(
  warehouseId: warehouseId,
  name: 'Zone A',
  description: 'Primary storage zone',
);

// Continue with rack, shelf, bin...

// Add stock entry
await stockProvider.addStockEntry(
  itemId: selectedItem.id,
  warehouseId: selectedWarehouse.id,
  zoneId: selectedZone.id,
  rackId: selectedRack.id,
  shelfId: selectedShelf.id,
  binId: selectedBin.id,
  quantity: 100.0,
  batchNumber: 'BATCH-001',
  expiryDate: DateTime(2027, 1, 21),
);
```

### 2. Generate Location Code

```dart
final locationCode = stockProvider.generateLocationCode(
  warehouseName: 'Main Warehouse',
  zoneName: 'Zone A',
  rackName: 'Rack 3',
  shelfName: 'Shelf 2',
  binName: 'Bin 5',
);
// Output: "WH01/A/R03/S02/B05"
```

### 3. Get Full Location Path

```dart
final locationPath = await stockProvider.getLocationPath(
  warehouseId: warehouseId,
  zoneId: zoneId,
  rackId: rackId,
  shelfId: shelfId,
  binId: binId,
);
print(locationPath.fullPath);
// Output: "Main Warehouse → Zone A → Rack 3 → Shelf 2 → Bin 5"
```

---

## Validation Rules Implementation

### 1. Duplicate Prevention
Each location level prevents duplicate names (case-insensitive):
```dart
final existing = await db.query(
  'zones',
  where: 'warehouseId = ? AND LOWER(name) = ?',
  whereArgs: [warehouseId, name.toLowerCase()],
);

if (existing.isNotEmpty) {
  throw Exception('Zone "$name" already exists in this warehouse');
}
```

### 2. Quantity Validation
```dart
if (quantity <= 0) {
  throw Exception('Quantity must be greater than zero');
}
```

### 3. Required Field Validation
All critical fields are validated before submission:
- Warehouse selection
- Complete location hierarchy (Zone → Rack → Shelf → Bin)
- Item selection
- Positive quantity

---

## UI Components

### 1. Step Indicator
Visual progress tracker showing completed steps:
- Warehouse ✓
- Location ✓
- Item ✓
- Quantity

### 2. Hierarchical Location Builder
Dependent dropdowns with inline creation:
- Zone dropdown with "+" button
- Rack dropdown (appears after Zone)
- Shelf dropdown (appears after Rack)
- Bin dropdown (appears after Shelf)

### 3. Location Code Display
Shows generated code and full path before saving:
```
Location Code: WH-01/A/R03/S02/B05
Path: Main Warehouse → Zone A → Rack 3 → Shelf 2 → Bin 5
```

---

## Integration Points

### Access Points Added:
1. **Dashboard Screen**: Green "Add Stock" button in top bar
2. **Inventory Screen**: "Add Stock to Warehouse" icon button in app bar
3. **Direct Navigation**: `AddStockScreen()` widget

---

## Future Enhancements (Optional)

### 1. Barcode/QR Support
```dart
// Scan bin barcode to auto-select location
String? scannedCode = await BarcodeScanner.scan();
if (scannedCode != null) {
  final bin = await findBinByBarcode(scannedCode);
  // Auto-populate location hierarchy
}
```

### 2. Permission-Based Access
```dart
if (user.hasPermission('warehouse.stock.add')) {
  // Show Add Stock button
}
```

### 3. Bulk Import
```dart
Future<void> importStockFromCSV(String filePath) async {
  // Parse CSV and create stock entries
}
```

### 4. Location QR Code Generation
```dart
String generateLocationQRCode(Bin bin) {
  final data = {
    'type': 'location',
    'binId': bin.id,
    'code': locationCode,
  };
  return jsonEncode(data);
}
```

---

## Testing Checklist

- [x] Create Zone with duplicate name prevention
- [x] Create Rack under Zone
- [x] Create Shelf under Rack
- [x] Create Bin under Shelf
- [x] Add stock with complete location
- [x] Validate quantity > 0
- [x] Generate location codes correctly
- [x] Update existing stock at same location
- [x] Display full location path
- [x] Form reset after successful entry
- [x] Navigation from Dashboard
- [x] Navigation from Inventory screen

---

## Scalability Considerations

1. **Database Indexes**: Created on all foreign keys for fast lookups
2. **Cascade Deletes**: Automatic cleanup when parent locations are deleted
3. **Caching**: Location lists cached in provider for quick access
4. **Lazy Loading**: Locations loaded only when needed (on-demand)
5. **Batch Operations**: Can be extended for bulk stock imports

---

## Production Deployment Notes

1. Ensure database migration runs before first use (version 2 schema)
2. Test with existing data to verify CASCADE delete behavior
3. Consider adding audit logs for stock movements
4. Implement backup strategy for location data
5. Monitor query performance on large datasets

---

## Support & Maintenance

For issues or enhancements, refer to:
- Provider: `lib/providers/stock_entry_provider.dart`
- Screen: `lib/screens/add_stock_screen.dart`
- Models: `lib/models/location.dart`, `lib/models/stock.dart`
- Database: `lib/services/database_service.dart`

---

**Last Updated**: January 21, 2026
**Version**: 1.0.0
**Status**: Production Ready ✅
