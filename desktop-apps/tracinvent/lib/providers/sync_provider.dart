import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../services/api_client.dart';
import '../services/database_service.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncProvider with ChangeNotifier {
  final ApiClient _apiClient;
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _lastSyncTime;
  String? _errorMessage;
  bool _isOnline = false;
  List<Map<String, dynamic>> _pendingChanges = [];
  
  StreamSubscription? _connectivitySubscription;
  Timer? _autoSyncTimer;
  
  SyncProvider({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient() {
    _initialize();
  }
  
  // Getters
  SyncStatus get syncStatus => _syncStatus;
  String? get lastSyncTime => _lastSyncTime;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;
  int get pendingChangesCount => _pendingChanges.length;
  
  Future<void> _initialize() async {
    await _loadLastSyncTime();
    await _loadPendingChanges();
    await _checkConnectivity();
    _setupConnectivityListener();
    _setupAutoSync();
  }
  
  // ========== Connectivity ==========
  
  Future<void> _checkConnectivity() async {
    try {
      final isHealthy = await _apiClient.checkHealth();
      _isOnline = isHealthy;
      notifyListeners();
      
      if (_isOnline && _pendingChanges.isNotEmpty) {
        await sync();
      }
    } catch (e) {
      _isOnline = false;
      notifyListeners();
    }
  }
  
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (result != ConnectivityResult.none) {
        await _checkConnectivity();
      } else {
        _isOnline = false;
        notifyListeners();
      }
    });
  }
  
  void _setupAutoSync() {
    // Auto-sync every 5 minutes when online
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline && _syncStatus != SyncStatus.syncing) {
        sync();
      }
    });
  }
  
  // ========== Sync Operations ==========
  
  Future<void> sync() async {
    if (_syncStatus == SyncStatus.syncing) return;
    
    _syncStatus = SyncStatus.syncing;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Check if server is available
      final isHealthy = await _apiClient.checkHealth();
      if (!isHealthy) {
        throw Exception('Server is not available');
      }
      
      // Prepare changes to send
      final changes = <String, dynamic>{};
      
      // Add pending changes
      if (_pendingChanges.isNotEmpty) {
        for (var change in _pendingChanges) {
          final table = change['table'] as String;
          if (!changes.containsKey(table)) {
            changes[table] = [];
          }
          changes[table].add(change['data']);
        }
      }
      
      // Call sync endpoint
      final result = await _apiClient.sync(
        lastSync: _lastSyncTime,
        changes: changes,
      );
      
      if (result['success'] == true) {
        final serverChanges = result['data']['changes'] as Map<String, dynamic>;
        
        // Apply server changes to local database
        await _applyServerChanges(serverChanges);
        
        // Clear pending changes
        _pendingChanges.clear();
        await _savePendingChanges();
        
        // Update last sync time
        _lastSyncTime = result['data']['timestamp'];
        await _saveLastSyncTime();
        
        _syncStatus = SyncStatus.success;
        _isOnline = true;
      } else {
        throw Exception(result['error'] ?? 'Sync failed');
      }
    } catch (e) {
      _syncStatus = SyncStatus.error;
      _errorMessage = e.toString();
      _isOnline = false;
    }
    
    notifyListeners();
  }
  
  Future<void> _applyServerChanges(Map<String, dynamic> serverChanges) async {
    final db = await DatabaseService.database;
    
    // Apply inventory changes
    if (serverChanges.containsKey('inventory')) {
      for (var item in serverChanges['inventory']) {
        await db.insert(
          'inventory_items',
          _convertFromApi(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    
    // Apply warehouse changes
    if (serverChanges.containsKey('warehouses')) {
      for (var warehouse in serverChanges['warehouses']) {
        await db.insert(
          'warehouses',
          _convertFromApi(warehouse),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    
    // Apply stock changes
    if (serverChanges.containsKey('stock')) {
      for (var stock in serverChanges['stock']) {
        await db.insert(
          'stock',
          _convertFromApi(stock),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    
    // Apply transaction changes
    if (serverChanges.containsKey('transactions')) {
      for (var txn in serverChanges['transactions']) {
        await db.insert(
          'transactions',
          _convertFromApi(txn),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }
  
  Map<String, dynamic> _convertFromApi(Map<String, dynamic> data) {
    // Convert camelCase API fields to snake_case database fields
    final converted = <String, dynamic>{};
    data.forEach((key, value) {
      final snakeKey = _camelToSnake(key);
      converted[snakeKey] = value;
    });
    return converted;
  }
  
  String _camelToSnake(String str) {
    return str.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }
  
  // ========== Queue Changes ==========
  
  Future<void> queueChange(String table, Map<String, dynamic> data) async {
    _pendingChanges.add({
      'table': table,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await _savePendingChanges();
    notifyListeners();
    
    // Try to sync if online
    if (_isOnline && _syncStatus != SyncStatus.syncing) {
      await sync();
    }
  }
  
  // ========== Persistence ==========
  
  Future<void> _loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSyncTime = prefs.getString('last_sync_time');
  }
  
  Future<void> _saveLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastSyncTime != null) {
      await prefs.setString('last_sync_time', _lastSyncTime!);
    }
  }
  
  Future<void> _loadPendingChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final changesJson = prefs.getString('pending_changes');
    if (changesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(changesJson);
        _pendingChanges = decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        _pendingChanges = [];
      }
    }
  }
  
  Future<void> _savePendingChanges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_changes', jsonEncode(_pendingChanges));
  }
  
  // ========== Manual Sync Control ==========
  
  Future<void> forceSyncNow() async {
    await sync();
  }
  
  void clearError() {
    _errorMessage = null;
    _syncStatus = SyncStatus.idle;
    notifyListeners();
  }
  
  // ========== Cleanup ==========
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _autoSyncTimer?.cancel();
    _apiClient.dispose();
    super.dispose();
  }
}
