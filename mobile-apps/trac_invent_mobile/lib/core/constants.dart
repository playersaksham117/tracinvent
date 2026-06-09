/// Application constants
class AppConstants {
  // App Info
  static const String appName = 'Trac Invent';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'trac_invent.db';
  static const int databaseVersion = 1;
  
  // Pagination
  static const int defaultPageSize = 50;
  static const int maxPageSize = 200;
  
  // Search
  static const int minSearchLength = 2;
  static const int searchDebounceMs = 300;
  
  // Stock Levels
  static const double lowStockThreshold = 0.25; // 25% of reorder level
  static const double criticalStockThreshold = 0.10; // 10% of min level
  
  // Cache
  static const int cacheExpirationMinutes = 5;
  
  // Animation Durations
  static const int shortAnimationMs = 150;
  static const int mediumAnimationMs = 300;
  static const int longAnimationMs = 500;
  
  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  
  // Validation
  static const int maxSkuLength = 50;
  static const int maxBarcodeLength = 100;
  static const int maxNameLength = 255;
  static const int maxDescriptionLength = 1000;
  static const int maxNotesLength = 500;
}

/// Shared Preferences Keys
class PrefKeys {
  static const String currentUserId = 'current_user_id';
  static const String currentWarehouseId = 'current_warehouse_id';
  static const String authToken = 'auth_token';
  static const String themeMode = 'theme_mode';
  static const String lastSyncTimestamp = 'last_sync_timestamp';
  static const String offlineMode = 'offline_mode';
}

/// Movement Types
class MovementType {
  static const String stockIn = 'STOCK_IN';
  static const String stockOut = 'STOCK_OUT';
  static const String transfer = 'TRANSFER';
  static const String adjustment = 'ADJUSTMENT';
  static const String cycleCount = 'CYCLE_COUNT';
  static const String initialStock = 'INITIAL_STOCK';
}

/// Adjustment Reasons
class AdjustmentReason {
  static const String damaged = 'DAMAGED';
  static const String expired = 'EXPIRED';
  static const String lost = 'LOST';
  static const String found = 'FOUND';
  static const String correction = 'CORRECTION';
  static const String theft = 'THEFT';
  static const String return_ = 'RETURN';
  static const String other = 'OTHER';
  
  static List<String> get all => [
    damaged, expired, lost, found, correction, theft, return_, other,
  ];
  
  static String getLabel(String reason) {
    switch (reason) {
      case damaged: return 'Damaged';
      case expired: return 'Expired';
      case lost: return 'Lost';
      case found: return 'Found';
      case correction: return 'Count Correction';
      case theft: return 'Theft/Shrinkage';
      case return_: return 'Customer Return';
      case other: return 'Other';
      default: return reason;
    }
  }
}

/// User Roles
class UserRole {
  static const String admin = 'ADMIN';
  static const String manager = 'MANAGER';
  static const String operator = 'OPERATOR';
  static const String viewer = 'VIEWER';
  
  static List<String> get all => [admin, manager, operator, viewer];
  
  static String getLabel(String role) {
    switch (role) {
      case admin: return 'Administrator';
      case manager: return 'Manager';
      case operator: return 'Operator';
      case viewer: return 'Viewer';
      default: return role;
    }
  }
}

/// Location Types
class LocationType {
  static const String warehouse = 'WAREHOUSE';
  static const String zone = 'ZONE';
  static const String rack = 'RACK';
  static const String shelf = 'SHELF';
  static const String bin = 'BIN';
  
  static List<String> get all => [warehouse, zone, rack, shelf, bin];
  
  static String getLabel(String type) {
    switch (type) {
      case warehouse: return 'Warehouse';
      case zone: return 'Zone';
      case rack: return 'Rack';
      case shelf: return 'Shelf';
      case bin: return 'Bin';
      default: return type;
    }
  }
  
  static String? getChildType(String type) {
    switch (type) {
      case warehouse: return zone;
      case zone: return rack;
      case rack: return shelf;
      case shelf: return bin;
      case bin: return null;
      default: return null;
    }
  }
}

/// Stock Status
enum StockStatus {
  inStock('IN_STOCK', 'In Stock'),
  lowStock('LOW_STOCK', 'Low Stock'),
  criticalStock('CRITICAL', 'Critical'),
  outOfStock('OUT_OF_STOCK', 'Out of Stock');
  
  final String code;
  final String label;
  
  const StockStatus(this.code, this.label);
}
