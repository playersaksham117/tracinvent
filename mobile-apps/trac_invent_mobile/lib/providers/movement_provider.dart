import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movement.dart';
import '../services/stock_service.dart';
import 'stock_provider.dart';

/// Movement list state
class MovementListState {
  final List<Movement> movements;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final MovementFilter filter;
  
  const MovementListState({
    this.movements = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.filter = const MovementFilter(),
  });
  
  MovementListState copyWith({
    List<Movement>? movements,
    bool? isLoading,
    bool? hasMore,
    String? error,
    MovementFilter? filter,
  }) {
    return MovementListState(
      movements: movements ?? this.movements,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      filter: filter ?? this.filter,
    );
  }
}

/// Movement list notifier
class MovementListNotifier extends StateNotifier<MovementListState> {
  final StockService _service;
  static const _pageSize = 50;
  
  MovementListNotifier(this._service) : super(const MovementListState());
  
  /// Load movements
  Future<void> load({MovementFilter? filter}) async {
    final newFilter = filter ?? state.filter;
    state = MovementListState(isLoading: true, filter: newFilter);
    
    try {
      final movements = await _service.getMovements(
        filter: newFilter.copyWith(limit: _pageSize, offset: 0),
      );
      
      state = state.copyWith(
        movements: movements,
        isLoading: false,
        hasMore: movements.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Load more movements
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final offset = state.movements.length;
      final movements = await _service.getMovements(
        filter: state.filter.copyWith(limit: _pageSize, offset: offset),
      );
      
      state = state.copyWith(
        movements: [...state.movements, ...movements],
        isLoading: false,
        hasMore: movements.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Filter by type
  Future<void> filterByType(String? type) async {
    await load(filter: state.filter.copyWith(type: type));
  }
  
  /// Filter by item
  Future<void> filterByItem(String? itemId) async {
    await load(filter: state.filter.copyWith(itemId: itemId));
  }
  
  /// Filter by date range
  Future<void> filterByDateRange(DateTime? fromDate, DateTime? toDate) async {
    await load(filter: state.filter.copyWith(
      fromDate: fromDate,
      toDate: toDate,
    ));
  }
  
  /// Search
  Future<void> search(String query) async {
    await load(filter: state.filter.copyWith(
      searchQuery: query.isEmpty ? null : query,
    ));
  }
  
  /// Refresh
  Future<void> refresh() async {
    await load();
  }
  
  /// Clear filters
  Future<void> clearFilters() async {
    await load(filter: const MovementFilter());
  }
}

/// Movement list provider
final movementListProvider = 
    StateNotifierProvider<MovementListNotifier, MovementListState>((ref) {
  final service = ref.watch(stockServiceProvider);
  return MovementListNotifier(service);
});

/// Recent movements provider
final recentMovementsProvider = FutureProvider<List<Movement>>((ref) async {
  final service = ref.watch(stockServiceProvider);
  return service.getRecentMovements(limit: 10);
});

/// Today's movements provider
final todayMovementsProvider = FutureProvider<List<Movement>>((ref) async {
  final service = ref.watch(stockServiceProvider);
  return service.getTodayMovements();
});

/// Movements by item provider
final movementsByItemProvider = 
    FutureProvider.family<List<Movement>, String>((ref, itemId) async {
  final service = ref.watch(stockServiceProvider);
  return service.getMovements(
    filter: MovementFilter(itemId: itemId, limit: 50),
  );
});

/// Movement statistics provider
final movementStatsProvider = 
    FutureProvider.family<Map<String, dynamic>, DateRangeParams>((ref, params) async {
  final service = ref.watch(stockServiceProvider);
  return service.getMovementStatistics(
    fromDate: params.fromDate,
    toDate: params.toDate,
  );
});

/// Date range params
class DateRangeParams {
  final DateTime? fromDate;
  final DateTime? toDate;
  
  const DateRangeParams({this.fromDate, this.toDate});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRangeParams &&
          runtimeType == other.runtimeType &&
          fromDate == other.fromDate &&
          toDate == other.toDate;
  
  @override
  int get hashCode => fromDate.hashCode ^ toDate.hashCode;
}
