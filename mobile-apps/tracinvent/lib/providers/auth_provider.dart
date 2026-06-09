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

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  Map<String, String>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get pinEnabled => _pinEnabled;
  String? get savedUserId => _savedUserId;
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
      _currentUser = result['user'] as Map<String, String>?;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] as String?;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result['success'] == true) {
      _isLoggedIn = true;
      _currentUser = result['user'] as Map<String, String>?;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] as String?;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signup(name, email, password);

    if (result['success'] == true) {
      _isLoggedIn = true;
      _currentUser = result['user'] as Map<String, String>?;
      _pinEnabled = false;
      _savedUserId = _currentUser?['id'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] as String?;
      notifyListeners();
      return false;
    }
  }

  Future<bool> enablePin(String userId, String pin) async {
    if (!isAdmin) {
      _errorMessage = 'Only admins can enable PIN';
      notifyListeners();
      return false;
    }

    final result = await _authService.enablePin(userId, pin);
    
    if (result['success'] == true) {
      // Refresh PIN status if it's the current user
      if (userId == _currentUser?['id']) {
        _pinEnabled = true;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] as String?;
      notifyListeners();
      return false;
    }
  }

  Future<bool> disablePin(String userId) async {
    if (!isAdmin) {
      _errorMessage = 'Only admins can disable PIN';
      notifyListeners();
      return false;
    }

    final result = await _authService.disablePin(userId);
    
    if (result['success'] == true) {
      // Refresh PIN status if it's the current user
      if (userId == _currentUser?['id']) {
        _pinEnabled = false;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] as String?;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    if (!isAdmin) return [];
    return await _authService.getAllUsers();
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    // Keep currentUser data for PIN re-login
    notifyListeners();
  }

  Future<void> completeLogout() async {
    await _authService.completeLogout();
    _isLoggedIn = false;
    _currentUser = null;
    _pinEnabled = false;
    _savedUserId = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
