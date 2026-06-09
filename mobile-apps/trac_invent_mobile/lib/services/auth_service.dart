import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

/// Service for authentication operations
class AuthService {
  final UserRepository _userRepository = UserRepository();
  User? _currentUser;
  
  /// Get current logged in user
  User? get currentUser => _currentUser;
  
  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;
  
  /// Check if current user is admin
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  
  /// Hash password using SHA256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Login with username and password
  Future<User?> login(String username, String password) async {
    final passwordHash = _hashPassword(password);
    final user = await _userRepository.authenticate(username, passwordHash);
    
    if (user != null) {
      _currentUser = user;
      await _saveSession(user);
    }
    
    return user;
  }
  
  /// Logout current user
  Future<void> logout() async {
    _currentUser = null;
    await _clearSession();
  }
  
  /// Try to restore session from storage
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(PrefKeys.currentUserId);
    
    if (userId == null) return false;
    
    final user = await _userRepository.getById(userId);
    if (user != null && user.isActive) {
      _currentUser = user;
      return true;
    }
    
    await _clearSession();
    return false;
  }
  
  /// Save session to storage
  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.currentUserId, user.id);
  }
  
  /// Clear session from storage
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefKeys.currentUserId);
  }
  
  /// Change password for current user
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;
    
    // Verify current password
    final currentHash = _hashPassword(currentPassword);
    final verified = await _userRepository.authenticate(
      _currentUser!.username,
      currentHash,
    );
    
    if (verified == null) return false;
    
    // Update password
    final newHash = _hashPassword(newPassword);
    await _userRepository.updatePassword(_currentUser!.id, newHash);
    
    return true;
  }
  
  /// Create new user (admin only)
  Future<User?> createUser({
    required String username,
    required String password,
    required String role,
    String? fullName,
    String? email,
  }) async {
    if (!isAdmin) return null;
    
    // Check if username exists
    final existing = await _userRepository.getByUsername(username);
    if (existing != null) return null;
    
    final now = DateTime.now();
    final user = User(
      id: 'usr_${now.millisecondsSinceEpoch}',
      username: username,
      role: role,
      fullName: fullName,
      email: email,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    
    await _userRepository.insert(user);
    
    // Store password hash separately
    await _userRepository.updatePassword(user.id, _hashPassword(password));
    
    return user;
  }
  
  /// Get all users (admin only)
  Future<List<User>> getAllUsers() async {
    if (!isAdmin) return [];
    return _userRepository.getActiveUsers();
  }
  
  /// Check if user has permission
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    
    // Admin has all permissions
    if (_currentUser!.role == UserRole.admin) return true;
    
    // Define role permissions
    final permissions = <String, List<String>>{
      UserRole.manager: [
        'view_dashboard',
        'view_inventory',
        'edit_inventory',
        'view_stock',
        'edit_stock',
        'view_movements',
        'view_reports',
      ],
      UserRole.operator: [
        'view_dashboard',
        'view_inventory',
        'view_stock',
        'edit_stock',
        'view_movements',
      ],
      UserRole.viewer: [
        'view_dashboard',
        'view_inventory',
        'view_stock',
        'view_movements',
      ],
    };
    
    final rolePermissions = permissions[_currentUser!.role] ?? [];
    return rolePermissions.contains(permission);
  }
}
