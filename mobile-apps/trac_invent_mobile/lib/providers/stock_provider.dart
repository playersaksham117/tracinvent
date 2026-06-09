import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/stock_service.dart';

/// Stock service provider
final stockServiceProvider = Provider<StockService>((ref) {
  return StockService();
});

/// Stock by item provider
final stockByItemProvider = 
    FutureProvider.family<List<Stock>, String>((ref, itemId) async {
  final service = ref.watch(stockServiceProvider);
  return service.getStockByItem(itemId);
});

/// Stock by location provider
final stockByLocationProvider = 
    FutureProvider.family<List<Stock>, String>((ref, locationId) async {
  final service = ref.watch(stockServiceProvider);
  return service.getStockByLocation(locationId);
});

/// Stock by warehouse provider
final stockByWarehouseProvider = 
    FutureProvider.family<List<Stock>, String>((ref, warehouseId) async {
  final service = ref.watch(stockServiceProvider);
  return service.getStockByWarehouse(warehouseId);
});

/// Stock summaries provider
final stockSummariesProvider = 
    FutureProvider.family<List<StockSummary>, StockSummaryParams>((ref, params) async {
  final service = ref.watch(stockServiceProvider);
  return service.getStockSummaries(
    searchQuery: params.searchQuery,
    warehouseId: params.warehouseId,
    page: params.page,
    pageSize: params.pageSize,
  );
});

/// Stock summary params
class StockSummaryParams {
  final String? searchQuery;
  final String? warehouseId;
  final int page;
  final int pageSize;
  
  const StockSummaryParams({
    this.searchQuery,
    this.warehouseId,
    this.page = 1,
    this.pageSize = 50,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockSummaryParams &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          warehouseId == other.warehouseId &&
          page == other.page &&
          pageSize == other.pageSize;
  
  @override
  int get hashCode =>
      searchQuery.hashCode ^
      warehouseId.hashCode ^
      page.hashCode ^
      pageSize.hashCode;
}

/// Expiring stock provider
final expiringStockProvider = FutureProvider<List<Stock>>((ref) async {
  final service = ref.watch(stockServiceProvider);
  return service.getExpiringStock(daysAhead: 30);
});

/// Stock operation state
class StockOperationState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final Movement? lastMovement;
  
  const StockOperationState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.lastMovement,
  });
  
  StockOperationState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    Movement? lastMovement,
  }) {
    return StockOperationState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      lastMovement: lastMovement ?? this.lastMovement,
    );
  }
}

/// Stock operation notifier for performing stock operations
class StockOperationNotifier extends StateNotifier<StockOperationState> {
  final StockService _service;
  final String userId;
  
  StockOperationNotifier(this._service, this.userId) 
      : super(const StockOperationState());
  
  /// Stock In
  Future<bool> stockIn({
    required String itemId,
    required String locationId,
    required double quantity,
    String? batchNumber,
    DateTime? expiryDate,
    String? referenceNumber,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      final movement = await _service.stockIn(
        itemId: itemId,
        locationId: locationId,
        quantity: quantity,
        userId: userId,
        batchNumber: batchNumber,
        expiryDate: expiryDate,
        referenceNumber: referenceNumber,
        notes: notes,
      );
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        lastMovement: movement,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: e.toString(),
      );
      return false;
    }
  }
  
  /// Stock Out
  Future<bool> stockOut({
    required String itemId,
    required String locationId,
    required double quantity,
    String? batchNumber,
    String? referenceNumber,
    String? reason,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      final movement = await _service.stockOut(
        itemId: itemId,
        locationId: locationId,
        quantity: quantity,
        userId: userId,
        batchNumber: batchNumber,
        referenceNumber: referenceNumber,
        reason: reason,
        notes: notes,
      );
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        lastMovement: movement,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: e.toString(),
      );
      return false;
    }
  }
  
  /// Transfer
  Future<bool> transfer({
    required String itemId,
    required String fromLocationId,
    required String toLocationId,
    required double quantity,
    String? batchNumber,
    String? referenceNumber,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      final movement = await _service.transfer(
        itemId: itemId,
        fromLocationId: fromLocationId,
        toLocationId: toLocationId,
        quantity: quantity,
        userId: userId,
        batchNumber: batchNumber,
        referenceNumber: referenceNumber,
        notes: notes,
      );
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        lastMovement: movement,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: e.toString(),
      );
      return false;
    }
  }
  
  /// Adjustment
  Future<bool> adjustment({
    required String itemId,
    required String locationId,
    required double newQuantity,
    required String reason,
    String? batchNumber,
    String? referenceNumber,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      final movement = await _service.adjustment(
        itemId: itemId,
        locationId: locationId,
        newQuantity: newQuantity,
        reason: reason,
        userId: userId,
        batchNumber: batchNumber,
        referenceNumber: referenceNumber,
        notes: notes,
      );
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        lastMovement: movement,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: e.toString(),
      );
      return false;
    }
  }
  
  /// Cycle Count
  Future<CycleCountResult?> cycleCount({
    required String itemId,
    required String locationId,
    required double countedQuantity,
    String? batchNumber,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      final result = await _service.cycleCount(
        itemId: itemId,
        locationId: locationId,
        countedQuantity: countedQuantity,
        userId: userId,
        batchNumber: batchNumber,
        notes: notes,
      );
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: e.toString(),
      );
      return null;
    }
  }
  
  /// Reset state
  void reset() {
    state = const StockOperationState();
  }
}

/// Stock operation provider factory
final stockOperationProvider = StateNotifierProvider.family<
    StockOperationNotifier, StockOperationState, String>((ref, userId) {
  final service = ref.watch(stockServiceProvider);
  return StockOperationNotifier(service, userId);
});
