/// App Provider
/// Global app state management
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _api;
  Timer? _connectionMonitor;
  bool _connectionCheckInProgress = false;
  bool _backendStarted = false;

  // App state
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  bool _isServerConnected = false;

  // Cached data
  CompanyProfile? _companyProfile;
  List<IndianState> _states = [];
  List<Unit> _units = [];
  List<VoucherType> _voucherTypes = [];
  List<Ledger> _parties = [];

  // Active financial year
  FinancialYear? _activeFY;

  AppProvider({ApiService? apiService}) : _api = apiService ?? ApiService();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isServerConnected => _isServerConnected;

  CompanyProfile? get companyProfile => _companyProfile;
  List<IndianState> get states => _states;
  List<Unit> get units => _units;
  List<VoucherType> get voucherTypes => _voucherTypes;
  List<Ledger> get parties => _parties;
  FinancialYear? get activeFY => _activeFY;
  ThemeMode get themeMode => ThemeMode.system;

  String get companyStateCode => _companyProfile?.stateCode ?? '27';

  /// Initialize app - load essential data
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Start backend first
      debugPrint('Starting backend...');
      _backendStarted = await BackendService.startBackend();
      
      if (_backendStarted) {
        debugPrint('Backend started successfully');
      } else {
        debugPrint('Failed to start backend');
      }
      
      // Check server connection
      _isServerConnected = await _api.healthCheck();

      if (_isServerConnected) {
        await _loadEssentialData();
      }

      _startConnectionMonitoring();

      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadEssentialData() async {
    await Future.wait([
      _loadCompanyProfile(),
      _loadStates(),
      _loadUnits(),
      _loadVoucherTypes(),
      _loadParties(),
    ]);
  }

  void _startConnectionMonitoring() {
    _connectionMonitor?.cancel();
    _connectionMonitor = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectionAndRecover();
    });
  }

  Future<void> _checkConnectionAndRecover() async {
    if (_connectionCheckInProgress) return;
    _connectionCheckInProgress = true;

    try {
      final wasConnected = _isServerConnected;
      final nowConnected = await _api.healthCheck();

      if (nowConnected != wasConnected) {
        _isServerConnected = nowConnected;
        notifyListeners();
      }

      if (!wasConnected && nowConnected) {
        await _loadEssentialData();
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Connection monitor error: $e');
    } finally {
      _connectionCheckInProgress = false;
    }
  }

  Future<void> _loadCompanyProfile() async {
    try {
      _companyProfile = await _api.getCompanyProfile();
    } catch (e) {
      debugPrint('Failed to load company profile: $e');
    }
  }

  Future<void> _loadStates() async {
    try {
      _states = await _api.getStates();
    } catch (e) {
      debugPrint('Failed to load states: $e');
    }
  }

  Future<void> _loadUnits() async {
    try {
      _units = await _api.getUnits();
    } catch (e) {
      debugPrint('Failed to load units: $e');
    }
  }

  Future<void> _loadVoucherTypes() async {
    try {
      _voucherTypes = await _api.getVoucherTypes();
    } catch (e) {
      debugPrint('Failed to load voucher types: $e');
    }
  }

  Future<void> _loadParties() async {
    try {
      _parties = await _api.getLedgers(isParty: true);
    } catch (e) {
      debugPrint('Failed to load parties: $e');
    }
  }

  /// Refresh parties list
  Future<void> refreshParties() async {
    await _loadParties();
    notifyListeners();
  }

  /// Save company profile
  Future<bool> saveCompanyProfile(CompanyProfile profile) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.saveCompanyProfile(profile);
      _companyProfile = profile;
      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to save company profile: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new party/ledger
  Future<Ledger?> createParty(Ledger ledger) async {
    try {
      final id = await _api.createLedger(ledger);
      final newLedger = ledger.copyWith(id: id);
      _parties.add(newLedger);
      notifyListeners();
      return newLedger;
    } catch (e) {
      _error = 'Failed to create party: $e';
      notifyListeners();
      return null;
    }
  }

  /// Search parties
  Future<List<Ledger>> searchParties(String query) async {
    if (query.isEmpty) return _parties;

    try {
      return await _api.getLedgers(isParty: true, search: query);
    } catch (e) {
      // Fall back to local search
      final lowerQuery = query.toLowerCase();
      return _parties
          .where(
            (p) =>
                p.name.toLowerCase().contains(lowerQuery) ||
                (p.gstin?.toLowerCase().contains(lowerQuery) ?? false) ||
                (p.phone?.contains(query) ?? false),
          )
          .toList();
    }
  }

  /// Get state by code
  IndianState? getStateByCode(String code) {
    try {
      return _states.firstWhere((s) => s.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Retry initialization
  Future<void> retry() async {
    _isInitialized = false;
    _error = null;
    await initialize();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionMonitor?.cancel();
    _api.dispose();
    
    // Stop backend when app is disposed
    if (_backendStarted) {
      BackendService.stopBackend();
    }
    
    super.dispose();
  }
}
