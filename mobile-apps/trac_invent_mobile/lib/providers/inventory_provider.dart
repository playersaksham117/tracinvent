import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import '../services/inventory_service.dart';

/// Inventory service provider
final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService();
});

/// Inventory list state
class InventoryListState {
  final List<InventoryItem> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final String? searchQuery;
  final String? categoryId;
  final int currentPage;
  
  const InventoryListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.searchQuery,
    this.categoryId,
    this.currentPage = 1,
  });
  
  InventoryListState copyWith({
    List<InventoryItem>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    String? searchQuery,
    String? categoryId,
    int? currentPage,
  }) {
    return InventoryListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryId: categoryId ?? this.categoryId,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Inventory list notifier
class InventoryListNotifier extends StateNotifier<InventoryListState> {
  final InventoryService _service;
  static const _pageSize = 50;
  
  InventoryListNotifier(this._service) : super(const InventoryListState());
  
  /// Load items (initial or refresh)
  Future<void> loadItems({
    String? searchQuery,
    String? categoryId,
    bool refresh = false,
  }) async {
    if (refresh) {
      state = const InventoryListState(isLoading: true);
    } else {
      state = state.copyWith(
        isLoading: true,
        searchQuery: searchQuery,
        categoryId: categoryId,
      );
    }
    
    try {
      final items = await _service.getItems(
        searchQuery: searchQuery ?? state.searchQuery,
        categoryId: categoryId ?? state.categoryId,
        page: 1,
        pageSize: _pageSize,
      );
      
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length >= _pageSize,
        currentPage: 1,
        searchQuery: searchQuery ?? state.searchQuery,
        categoryId: categoryId ?? state.categoryId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Load more items (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final nextPage = state.currentPage + 1;
      final items = await _service.getItems(
        searchQuery: state.searchQuery,
        categoryId: state.categoryId,
        page: nextPage,
        pageSize: _pageSize,
      );
      
      state = state.copyWith(
        items: [...state.items, ...items],
        isLoading: false,
        hasMore: items.length >= _pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Search items
  Future<void> search(String query) async {
    await loadItems(searchQuery: query.isEmpty ? null : query, refresh: true);
  }
  
  /// Filter by category
  Future<void> filterByCategory(String? categoryId) async {
    await loadItems(categoryId: categoryId, refresh: true);
  }
  
  /// Refresh list
  Future<void> refresh() async {
    await loadItems(refresh: true);
  }
  
  /// Add item to list
  void addItem(InventoryItem item) {
    state = state.copyWith(items: [item, ...state.items]);
  }
  
  /// Update item in list
  void updateItem(InventoryItem item) {
    final index = state.items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      final updated = [...state.items];
      updated[index] = item;
      state = state.copyWith(items: updated);
    }
  }
  
  /// Remove item from list
  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
    );
  }
}

/// Inventory list provider
final inventoryListProvider = 
    StateNotifierProvider<InventoryListNotifier, InventoryListState>((ref) {
  final service = ref.watch(inventoryServiceProvider);
  return InventoryListNotifier(service);
});

/// Single item provider
final inventoryItemProvider = 
    FutureProvider.family<InventoryItem?, String>((ref, itemId) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getItemById(itemId);
});

/// Categories provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getCategories();
});

/// Low stock items provider
final lowStockItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getLowStockItems();
});

/// Critical stock items provider
final criticalStockItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getCriticalStockItems();
});

/// Item search provider
final itemSearchProvider = 
    FutureProvider.family<List<InventoryItem>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final service = ref.watch(inventoryServiceProvider);
  return service.searchItems(query);
});
