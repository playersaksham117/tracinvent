import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  bool _isLoading = true;
  Map<String, String>? _currentUser;
  String? _errorMessage;
  bool _pinEnabled = false;
  String? _savedUserId;
  bool _needsPinSetup = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  Map<String, String>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get pinEnabled => _pinEnabled;
  String? get savedUserId => _savedUserId;
  bool get needsPinSetup => _needsPinSetup;
  bool get isAdmin => _currentUser?['role'] == 'admin';
  String get userId => _currentUser?['id'] ?? '';

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    await _authService.initializeUsersTable();
    _isLoggedIn = await _authService.isLoggedIn();
    _pinEnabled = await _authService.isPinEnabled();
    _savedUserId = await _authService.getSavedUserId();

    if (_isLoggedIn) {
      _currentUser = await _authService.getCurrentUser();
      if (_currentUser != null) {
        final hasPin = await _authService.currentUserHasPinInDb(_currentUser!['id']!);
        final skipped = await _authService.isPinSetupSkipped();
        _needsPinSetup = !hasPin && !skipped;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> loginWithPin(String pin) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.loginWithPin(pin);

    if (result['success'] == true) {
      _isLoggedIn = true;
      _currentUser = Map<String, String>.from(result['user'] as Map);
      _needsPinSetup = false;
      notifyListeners();
      return true;
    }

    _errorMessage = result['message'] as String?;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result['success'] == true) {
      _isLoggedIn = true;
      _currentUser = Map<String, String>.from(result['user'] as Map);
      _pinEnabled = await _authService.isPinEnabled();
      _savedUserId = _currentUser?['id'];

      if (_currentUser != null) {
        final hasPin = await _authService.currentUserHasPinInDb(_currentUser!['id']!);
        final skipped = await _authService.isPinSetupSkipped();
        _needsPinSetup = !hasPin && !skipped;
      }

      notifyListeners();
      return true;
    }

    _errorMessage = result['message'] as String?;
    notifyListeners();
    return false;
  }

  Future<bool> signup(String name, String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signup(name, email, password);

    if (result['success'] == true) {
      _isLoggedIn = true;
      _currentUser = Map<String, String>.from(result['user'] as Map);
      _pinEnabled = false;
      _savedUserId = _currentUser?['id'];
      _needsPinSetup = true;
      notifyListeners();
      return true;
    }

    _errorMessage = result['message'] as String?;
    notifyListeners();
    return false;
  }

  Future<bool> setPin(String pin) async {
    if (_currentUser == null) return false;

    final result = await _authService.setPin(_currentUser!['id']!, pin);

    if (result['success'] == true) {
      _pinEnabled = true;
      _needsPinSetup = false;
      notifyListeners();
      return true;
    }

    _errorMessage = result['message'] as String?;
    notifyListeners();
    return false;
  }

  Future<void> skipPinSetup() async {
    await _authService.markPinSetupSkipped();
    _needsPinSetup = false;
    notifyListeners();
  }

  Future<bool> enablePin(String userId, String pin) async {
    if (!isAdmin) {
      _errorMessage = 'Only admins can enable PIN';
      notifyListeners();
      return false;
    }

    final result = await _authService.enablePin(userId, pin);

    if (result['success'] == true) {
      if (userId == _currentUser?['id']) {
        _pinEnabled = true;
      }
      notifyListeners();
      return true;
    }

    _errorMessage = result['message'] as String?;
    notifyListeners();
    return false;
  }

  Future<bool> disablePin(String userId) async {
    if (!isAdmin) {
      _errorMessage = 'Only admins can disable PIN';
      notifyListeners();
      return false;
    }

    final result = await _authService.disablePin(userId);

    if (result['success'] == true) {
      if (userId == _currentUser?['id']) {
        _pinEnabled = false;
      }
      notifyListeners();
      return true;
    }

    _errorMessage = result['message'] as String?;
    notifyListeners();
    return false;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    if (!isAdmin) return [];
    return _authService.getAllUsers();
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> completeLogout() async {
    await _authService.completeLogout();
    _isLoggedIn = false;
    _currentUser = null;
    _pinEnabled = false;
    _savedUserId = null;
    _needsPinSetup = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
