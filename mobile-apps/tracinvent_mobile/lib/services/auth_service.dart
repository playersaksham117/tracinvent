import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserRole = 'user_role';
  static const String _keyPinEnabled = 'pin_enabled';
  static const String _keyUserPin = 'user_pin';

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get current user details
  Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    
    if (!isLoggedIn) return null;

    return {
      'id': prefs.getString(_keyUserId) ?? '',
      'email': prefs.getString(_keyUserEmail) ?? '',
      'name': prefs.getString(_keyUserName) ?? '',
      'role': prefs.getString(_keyUserRole) ?? 'user',
    };
  }

  // Check if PIN is enabled for current user
  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPinEnabled) ?? false;
  }

  // Get user ID for PIN login context
  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // Login with PIN
  Future<Map<String, dynamic>> loginWithPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString(_keyUserPin);
      final userId = prefs.getString(_keyUserId);

      if (savedPin == null || userId == null) {
        return {
          'success': false,
          'message': 'PIN not configured. Please use email login.',
        };
      }

      if (savedPin != pin) {
        return {
          'success': false,
          'message': 'Incorrect PIN',
        };
      }

      // Fetch user details from database
      final db = await DatabaseService.database;
      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (results.isEmpty) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      final user = results.first;
      
      // Update login state
      await prefs.setBool(_keyIsLoggedIn, true);

      return {
        'success': true,
        'user': {
          'id': user['id'],
          'email': user['email'],
          'name': user['name'],
          'role': user['role'] ?? 'user',
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'PIN login failed: $e',
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final db = await DatabaseService.database;
      
      final results = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      if (results.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      }

      final user = results.first;
      
      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserId, user['id'] as String);
      await prefs.setString(_keyUserEmail, user['email'] as String);
      await prefs.setString(_keyUserName, user['name'] as String);
      await prefs.setString(_keyUserRole, user['role'] as String? ?? 'user');
      
      // Save PIN status
      final hasPin = user['pin'] != null && (user['pin'] as String).isNotEmpty;
      await prefs.setBool(_keyPinEnabled, hasPin);
      if (hasPin) {
        await prefs.setString(_keyUserPin, user['pin'] as String);
      }

      return {
        'success': true,
        'user': {
          'id': user['id'],
          'email': user['email'],
          'name': user['name'],
          'role': user['role'] ?? 'user',
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
  }

  // Signup user
  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {
      final db = await DatabaseService.database;
      
      // Check if user already exists
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existing.isNotEmpty) {
        return {
          'success': false,
          'message': 'Email already registered',
        };
      }

      // Create user
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      await db.insert('users', {
        'id': userId,
        'name': name,
        'email': email,
        'password': password, // In production, hash this!
        'role': 'admin',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Auto-login after signup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyUserName, name);
      await prefs.setString(_keyUserRole, 'admin');
      await prefs.setBool(_keyPinEnabled, false);

      return {
        'success': true,
        'user': {
          'id': userId,
          'email': email,
          'name': name,
          'role': 'admin',
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Signup failed: $e',
      };
    }
  }

  // Enable PIN for user (admin only action)
  Future<Map<String, dynamic>> enablePin(String userId, String pin) async {
    try {
      if (pin.length != 4 || !RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
        return {
          'success': false,
          'message': 'PIN must be exactly 4 digits',
        };
      }

      final db = await DatabaseService.database;
      await db.update(
        'users',
        {
          'pin': pin,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Update current session if it's the logged-in user
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString(_keyUserId);
      
      if (currentUserId == userId) {
        await prefs.setBool(_keyPinEnabled, true);
        await prefs.setString(_keyUserPin, pin);
      }

      return {
        'success': true,
        'message': 'PIN enabled successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to enable PIN: $e',
      };
    }
  }

  // Disable PIN for user (admin only action)
  Future<Map<String, dynamic>> disablePin(String userId) async {
    try {
      final db = await DatabaseService.database;
      await db.update(
        'users',
        {
          'pin': null,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Update current session if it's the logged-in user
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString(_keyUserId);
      
      if (currentUserId == userId) {
        await prefs.setBool(_keyPinEnabled, false);
        await prefs.remove(_keyUserPin);
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

  // Get all users (admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final db = await DatabaseService.database;
      return await db.query('users', orderBy: 'name ASC');
    } catch (e) {
      return [];
    }
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    // Keep user ID and PIN for quick re-login
    // Only remove session state
  }

  // Complete logout (clear all data)
  Future<void> completeLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyPinEnabled);
    await prefs.remove(_keyUserPin);
  }

  // Initialize users table
  Future<void> initializeUsersTable() async {
    final db = await DatabaseService.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'user',
        pin TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }
}
