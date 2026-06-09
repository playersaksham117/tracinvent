import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'unified_database_manager.dart';

/// Default bootstrap credentials (first install / empty users table).
class DefaultAdminCredentials {
  static const String email = 'admin@123';
  static const String username = 'admin@123';
  static const String password = 'admin123';
  static const String displayName = 'Administrator';
}

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserRole = 'user_role';
  static const String _keyPinEnabled = 'pin_enabled';
  static const String _keyUserPinHash = 'user_pin_hash';
  static const String _keyPinSetupSkipped = 'pin_setup_skipped';

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  Map<String, String> _mapUser(Map<String, Object?> user) {
    return {
      'id': user['id'] as String,
      'email': (user['email'] as String?) ?? (user['username'] as String? ?? ''),
      'name': user['displayName'] as String? ?? user['username'] as String? ?? '',
      'role': user['role'] as String? ?? 'operator',
    };
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyIsLoggedIn) ?? false)) return null;

    return {
      'id': prefs.getString(_keyUserId) ?? '',
      'email': prefs.getString(_keyUserEmail) ?? '',
      'name': prefs.getString(_keyUserName) ?? '',
      'role': prefs.getString(_keyUserRole) ?? 'operator',
    };
  }

  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPinEnabled) ?? false;
  }

  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  Future<bool> isPinSetupSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPinSetupSkipped) ?? false;
  }

  Future<void> markPinSetupSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPinSetupSkipped, true);
  }

  Future<void> clearPinSetupSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPinSetupSkipped);
  }

  Future<bool> currentUserHasPinInDb(String userId) async {
    final db = await DatabaseManager.instance.database;
    final results = await db.query(
      'users',
      columns: ['pinHash'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (results.isEmpty) return false;
    final pinHash = results.first['pinHash'] as String?;
    return pinHash != null && pinHash.isNotEmpty;
  }

  Future<Map<String, dynamic>> loginWithPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPinHash = prefs.getString(_keyUserPinHash);
      final userId = prefs.getString(_keyUserId);

      if (savedPinHash == null || userId == null) {
        return {
          'success': false,
          'message': 'PIN not configured. Please use email login.',
        };
      }

      if (savedPinHash != _hashPin(pin)) {
        return {
          'success': false,
          'message': 'Incorrect PIN',
        };
      }

      final db = await DatabaseManager.instance.database;
      final results = await db.query(
        'users',
        where: 'id = ? AND isDeleted = 0 AND isActive = 1',
        whereArgs: [userId],
      );

      if (results.isEmpty) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      final user = results.first;
      await _saveSession(prefs, user);

      return {
        'success': true,
        'user': _mapUser(user),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'PIN login failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final db = await DatabaseManager.instance.database;
      final passwordHash = _hashPassword(password);

      final results = await db.query(
        'users',
        where: '(email = ? OR username = ?) AND passwordHash = ? AND isDeleted = 0 AND isActive = 1',
        whereArgs: [identifier, identifier, passwordHash],
      );

      if (results.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid email/user ID or password',
        };
      }

      final user = results.first;
      final prefs = await SharedPreferences.getInstance();
      await _saveSession(prefs, user);

      return {
        'success': true,
        'user': _mapUser(user),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {
      final db = await DatabaseManager.instance.database;

      final existing = await db.query(
        'users',
        where: '(email = ? OR username = ?) AND isDeleted = 0',
        whereArgs: [email, email],
      );

      if (existing.isNotEmpty) {
        return {
          'success': false,
          'message': 'Email or user ID already registered',
        };
      }

      final now = DateTime.now().toIso8601String();
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      await db.insert('users', {
        'id': userId,
        'username': email,
        'email': email,
        'displayName': name,
        'passwordHash': _hashPassword(password),
        'role': 'admin',
        'isActive': 1,
        'loginAttempts': 0,
        'createdAt': now,
        'updatedAt': now,
        'syncStatus': 'local',
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPinSetupSkipped, false);

      final user = {
        'id': userId,
        'username': email,
        'email': email,
        'displayName': name,
        'role': 'admin',
        'pinHash': null,
      };
      await _saveSession(prefs, user);

      return {
        'success': true,
        'user': _mapUser(user),
        'needsPinSetup': true,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Signup failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> setPin(String userId, String pin) async {
    try {
      if (pin.length != 4 || !RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
        return {
          'success': false,
          'message': 'PIN must be exactly 4 digits',
        };
      }

      final pinHash = _hashPin(pin);
      final db = await DatabaseManager.instance.database;
      await db.update(
        'users',
        {
          'pinHash': pinHash,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString(_keyUserId);

      if (currentUserId == userId) {
        await prefs.setBool(_keyPinEnabled, true);
        await prefs.setString(_keyUserPinHash, pinHash);
        await prefs.remove(_keyPinSetupSkipped);
      }

      return {
        'success': true,
        'message': 'PIN set successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to set PIN: $e',
      };
    }
  }

  Future<Map<String, dynamic>> enablePin(String userId, String pin) async {
    return setPin(userId, pin);
  }

  Future<Map<String, dynamic>> disablePin(String userId) async {
    try {
      final db = await DatabaseManager.instance.database;
      await db.update(
        'users',
        {
          'pinHash': null,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString(_keyUserId);

      if (currentUserId == userId) {
        await prefs.setBool(_keyPinEnabled, false);
        await prefs.remove(_keyUserPinHash);
      }

      return {
        'success': true,
        'message': 'PIN disabled successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to disable PIN: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final db = await DatabaseManager.instance.database;
      final rows = await db.query(
        'users',
        where: 'isDeleted = 0',
        orderBy: 'displayName ASC',
      );

      return rows.map((row) {
        return {
          'id': row['id'],
          'name': row['displayName'] ?? row['username'],
          'email': row['email'] ?? row['username'],
          'role': row['role'] ?? 'operator',
          'pin': row['pinHash'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  Future<void> completeLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyPinEnabled);
    await prefs.remove(_keyUserPinHash);
    await prefs.remove(_keyPinSetupSkipped);
  }

  Future<void> ensureDefaultAdmin() async {
    final db = await DatabaseManager.instance.database;
    final now = DateTime.now().toIso8601String();
    final passwordHash = _hashPassword(DefaultAdminCredentials.password);

    final existing = await db.query(
      'users',
      where: 'email = ? OR username = ?',
      whereArgs: [
        DefaultAdminCredentials.email,
        DefaultAdminCredentials.username,
      ],
    );

    if (existing.isEmpty) {
      await db.insert('users', {
        'id': 'admin-default',
        'username': DefaultAdminCredentials.username,
        'email': DefaultAdminCredentials.email,
        'displayName': DefaultAdminCredentials.displayName,
        'passwordHash': passwordHash,
        'role': 'admin',
        'isActive': 1,
        'loginAttempts': 0,
        'createdAt': now,
        'updatedAt': now,
        'syncStatus': 'local',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return;
    }

    await db.update(
      'users',
      {
        'username': DefaultAdminCredentials.username,
        'email': DefaultAdminCredentials.email,
        'displayName': DefaultAdminCredentials.displayName,
        'passwordHash': passwordHash,
        'role': 'admin',
        'isActive': 1,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [existing.first['id']],
    );
  }

  Future<void> initializeUsersTable() async {
    await ensureDefaultAdmin();
  }

  Future<void> _saveSession(
    SharedPreferences prefs,
    Map<String, Object?> user,
  ) async {
    final pinHash = user['pinHash'] as String?;
    final hasPin = pinHash != null && pinHash.isNotEmpty;

    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, user['id'] as String);
    await prefs.setString(
      _keyUserEmail,
      (user['email'] as String?) ?? (user['username'] as String? ?? ''),
    );
    await prefs.setString(
      _keyUserName,
      user['displayName'] as String? ?? user['username'] as String? ?? '',
    );
    await prefs.setString(_keyUserRole, user['role'] as String? ?? 'operator');
    await prefs.setBool(_keyPinEnabled, hasPin);

    if (hasPin) {
      await prefs.setString(_keyUserPinHash, pinHash);
    } else {
      await prefs.remove(_keyUserPinHash);
    }
  }
}
