import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/warehouse.dart';
import '../services/warehouse_service.dart';

/// Warehouse service provider
final warehouseServiceProvider = Provider<WarehouseService>((ref) {
  return WarehouseService();
});

/// Warehouses list provider
final warehousesProvider = FutureProvider<List<Warehouse>>((ref) async {
  final service = ref.watch(warehouseServiceProvider);
  return service.getWarehouses();
});

/// Single warehouse provider
final warehouseProvider = 
    FutureProvider.family<Warehouse?, String>((ref, warehouseId) async {
  final service = ref.watch(warehouseServiceProvider);
  return service.getWarehouseById(warehouseId);
});

/// Selected warehouse state
class SelectedWarehouseNotifier extends StateNotifier<String?> {
  SelectedWarehouseNotifier() : super(null);
  
  void select(String? warehouseId) {
    state = warehouseId;
  }
}

/// Selected warehouse provider
final selectedWarehouseProvider = 
    StateNotifierProvider<SelectedWarehouseNotifier, String?>((ref) {
  return SelectedWarehouseNotifier();
});

/// Zones for warehouse provider
final zonesProvider = 
    FutureProvider.family<List<Location>, String>((ref, warehouseId) async {
  final service = ref.watch(warehouseServiceProvider);
  return service.getZones(warehouseId);
});

/// Location children provider
final locationChildrenProvider = 
    FutureProvider.family<List<Location>, String>((ref, parentId) async {
  final service = ref.watch(warehouseServiceProvider);
  return service.getLocationChildren(parentId);
});

/// Bins for warehouse provider
final binsProvider = 
    FutureProvider.family<List<Location>, String>((ref, warehouseId) async {
  final service = ref.watch(warehouseServiceProvider);
  return service.getBins(warehouseId);
});

/// Single location provider
final locationProvider = 
    FutureProvider.family<Location?, String>((ref, locationId) async {
  final service = ref.watch(warehouseServiceProvider);
  return service.getLocationById(locationId);
});

/// Location search provider
final locationSearchProvider = 
    FutureProvider.family<List<Location>, LocationSearchParams>((ref, params) async {
  final service = ref.watch(warehouseServiceProvider);
  return service.searchLocations(
    params.query,
    warehouseId: params.warehouseId,
  );
});

/// Location search params
class LocationSearchParams {
  final String query;
  final String? warehouseId;
  
  const LocationSearchParams({
    required this.query,
    this.warehouseId,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationSearchParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          warehouseId == other.warehouseId;
  
  @override
  int get hashCode => query.hashCode ^ warehouseId.hashCode;
}

/// Location hierarchy state for browser
class LocationBrowserState {
  final String warehouseId;
  final List<Location> breadcrumb;
  final List<Location> currentLocations;
  final bool isLoading;
  final String? error;
  
  const LocationBrowserState({
    required this.warehouseId,
    this.breadcrumb = const [],
    this.currentLocations = const [],
    this.isLoading = false,
    this.error,
  });
  
  LocationBrowserState copyWith({
    String? warehouseId,
    List<Location>? breadcrumb,
    List<Location>? currentLocations,
    bool? isLoading,
    String? error,
  }) {
    return LocationBrowserState(
      warehouseId: warehouseId ?? this.warehouseId,
      breadcrumb: breadcrumb ?? this.breadcrumb,
      currentLocations: currentLocations ?? this.currentLocations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
  
  Location? get currentLocation => 
      breadcrumb.isEmpty ? null : breadcrumb.last;
}

/// Location browser notifier
class LocationBrowserNotifier extends StateNotifier<LocationBrowserState?> {
  final WarehouseService _service;
  
  LocationBrowserNotifier(this._service) : super(null);
  
  /// Initialize browser for warehouse
  Future<void> initialize(String warehouseId) async {
    state = LocationBrowserState(warehouseId: warehouseId, isLoading: true);
    
    try {
      final zones = await _service.getZones(warehouseId);
      state = state?.copyWith(
        currentLocations: zones,
        isLoading: false,
      );
    } catch (e) {
      state = state?.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Navigate into a location
  Future<void> navigateTo(Location location) async {
    if (state == null) return;
    
    state = state!.copyWith(isLoading: true);
    
    try {
      final children = await _service.getLocationChildren(location.id);
      state = state!.copyWith(
        breadcrumb: [...state!.breadcrumb, location],
        currentLocations: children,
        isLoading: false,
      );
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Navigate back
  Future<void> navigateBack() async {
    if (state == null || state!.breadcrumb.isEmpty) return;
    
    state = state!.copyWith(isLoading: true);
    
    try {
      final newBreadcrumb = [...state!.breadcrumb]..removeLast();
      
      List<Location> locations;
      if (newBreadcrumb.isEmpty) {
        locations = await _service.getZones(state!.warehouseId);
      } else {
        locations = await _service.getLocationChildren(newBreadcrumb.last.id);
      }
      
      state = state!.copyWith(
        breadcrumb: newBreadcrumb,
        currentLocations: locations,
        isLoading: false,
      );
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Navigate to root
  Future<void> navigateToRoot() async {
    if (state == null) return;
    
    state = state!.copyWith(isLoading: true);
    
    try {
      final zones = await _service.getZones(state!.warehouseId);
      state = state!.copyWith(
        breadcrumb: [],
        currentLocations: zones,
        isLoading: false,
      );
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Navigate to breadcrumb index
  Future<void> navigateToBreadcrumb(int index) async {
    if (state == null || index >= state!.breadcrumb.length) return;
    
    // Navigate back multiple times
    final stepsBack = state!.breadcrumb.length - index - 1;
    for (var i = 0; i < stepsBack; i++) {
      await navigateBack();
    }
  }
}

/// Location browser provider
final locationBrowserProvider = 
    StateNotifierProvider<LocationBrowserNotifier, LocationBrowserState?>((ref) {
  final service = ref.watch(warehouseServiceProvider);
  return LocationBrowserNotifier(service);
});
