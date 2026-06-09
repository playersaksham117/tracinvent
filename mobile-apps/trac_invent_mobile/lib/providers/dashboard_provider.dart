import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/dashboard_service.dart';

/// Dashboard service provider
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

/// Dashboard stats provider
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getDashboardStats();
});

/// Dashboard stats with auto-refresh
class DashboardNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  final DashboardService _service;
  
  DashboardNotifier(this._service) : super(const AsyncValue.loading());
  
  /// Load dashboard stats
  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _service.getDashboardStats();
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  /// Refresh dashboard stats
  Future<void> refresh() async {
    try {
      final stats = await _service.getDashboardStats();
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Dashboard notifier provider
final dashboardNotifierProvider = 
    StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardStats>>((ref) {
  final service = ref.watch(dashboardServiceProvider);
  return DashboardNotifier(service);
});

/// Movement trends provider
final movementTrendsProvider = 
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getMovementTrends(days: days);
});

/// Top moving items provider
final topMovingItemsProvider = 
    FutureProvider.family<List<Map<String, dynamic>>, TopMovingParams>((ref, params) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getTopMovingItems(
    limit: params.limit,
    days: params.days,
  );
});

/// Top moving params
class TopMovingParams {
  final int limit;
  final int days;
  
  const TopMovingParams({this.limit = 10, this.days = 30});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopMovingParams &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          days == other.days;
  
  @override
  int get hashCode => limit.hashCode ^ days.hashCode;
}

/// Stock alerts provider
final stockAlertsProvider = 
    FutureProvider<Map<String, List<dynamic>>>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getStockAlerts();
});
