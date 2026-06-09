import '../models/inventory_item.dart';
import '../repositories/inventory_repository.dart';

/// Service for inventory item operations
class InventoryService {
  final InventoryItemRepository _itemRepository = InventoryItemRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  
  /// Get all items with pagination and filtering
  Future<List<InventoryItem>> getItems({
    String? searchQuery,
    String? categoryId,
    bool activeOnly = true,
    String? orderBy,
    int page = 1,
    int pageSize = 50,
  }) async {
    final offset = (page - 1) * pageSize;
    return _itemRepository.getAllWithDetails(
      searchQuery: searchQuery,
      categoryId: categoryId,
      activeOnly: activeOnly,
      orderBy: orderBy,
      limit: pageSize,
      offset: offset,
    );
  }
  
  /// Get item by ID with details
  Future<InventoryItem?> getItemById(String id) async {
    return _itemRepository.getByIdWithDetails(id);
  }
  
  /// Get item by SKU
  Future<InventoryItem?> getItemBySku(String sku) async {
    return _itemRepository.getBySku(sku);
  }
  
  /// Get item by barcode
  Future<InventoryItem?> getItemByBarcode(String barcode) async {
    return _itemRepository.getByBarcode(barcode);
  }
  
  /// Search items by SKU, barcode, or name
  Future<List<InventoryItem>> searchItems(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];
    return _itemRepository.search(query, limit: limit);
  }
  
  /// Create new item
  Future<InventoryItem> createItem({
    required String name,
    required String sku,
    String? barcode,
    String? categoryId,
    String unit = 'PCS',
    double reorderLevel = 0,
    double minLevel = 0,
    double? weight,
    String? brand,
    String? description,
  }) async {
    // Validate SKU uniqueness
    if (await _itemRepository.skuExists(sku)) {
      throw Exception('SKU already exists: $sku');
    }
    
    // Validate barcode uniqueness if provided
    if (barcode != null && barcode.isNotEmpty) {
      if (await _itemRepository.barcodeExists(barcode)) {
        throw Exception('Barcode already exists: $barcode');
      }
    }
    
    final now = DateTime.now();
    final item = InventoryItem(
      id: 'item_${now.millisecondsSinceEpoch}',
      name: name,
      sku: sku,
      barcode: barcode?.isEmpty == true ? null : barcode,
      categoryId: categoryId,
      unit: unit,
      reorderLevel: reorderLevel,
      minLevel: minLevel,
      weight: weight,
      brand: brand,
      description: description,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    
    await _itemRepository.insert(item);
    return item;
  }
  
  /// Update item
  Future<InventoryItem> updateItem(InventoryItem item) async {
    // Validate SKU uniqueness
    if (await _itemRepository.skuExists(item.sku, excludeId: item.id)) {
      throw Exception('SKU already exists: ${item.sku}');
    }
    
    // Validate barcode uniqueness if provided
    if (item.barcode != null && item.barcode!.isNotEmpty) {
      if (await _itemRepository.barcodeExists(item.barcode!, excludeId: item.id)) {
        throw Exception('Barcode already exists: ${item.barcode}');
      }
    }
    
    final updatedItem = item.copyWith(updatedAt: DateTime.now());
    await _itemRepository.update(updatedItem);
    return updatedItem;
  }
  
  /// Delete item (soft delete)
  Future<void> deleteItem(String id) async {
    final item = await _itemRepository.getById(id);
    if (item == null) throw Exception('Item not found');
    
    final deactivated = item.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
    await _itemRepository.update(deactivated);
  }
  
  /// Get low stock items
  Future<List<InventoryItem>> getLowStockItems() async {
    return _itemRepository.getLowStockItems();
  }
  
  /// Get critical stock items
  Future<List<InventoryItem>> getCriticalStockItems() async {
    return _itemRepository.getCriticalStockItems();
  }
  
  /// Get out of stock items
  Future<List<InventoryItem>> getOutOfStockItems() async {
    return _itemRepository.getOutOfStockItems();
  }
  
  /// Get item counts
  Future<Map<String, int>> getItemCounts() async {
    return _itemRepository.getItemCounts();
  }
  
  /// Get all categories
  Future<List<Category>> getCategories() async {
    return _categoryRepository.getActiveCategories();
  }
  
  /// Create category
  Future<Category> createCategory({
    required String name,
    String? parentId,
    String? description,
    String? color,
  }) async {
    final now = DateTime.now();
    final category = Category(
      id: 'cat_${now.millisecondsSinceEpoch}',
      name: name,
      parentId: parentId,
      description: description,
      color: color,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    
    await _categoryRepository.insert(category);
    return category;
  }
  
  /// Generate next SKU
  Future<String> generateSku({String prefix = 'SKU'}) async {
    final counts = await _itemRepository.getItemCounts();
    final nextNumber = (counts['total'] ?? 0) + 1;
    return '$prefix-${nextNumber.toString().padLeft(6, '0')}';
  }
}
