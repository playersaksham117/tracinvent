import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/license.dart';

/// Stores the last successful validation result locally.
/// Allows up to 7 days of offline operation.
class OfflineGraceService {
  static const _key = 'supabase_auth_last_validation';

  static Future<void> saveValidation(CachedValidation v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(v.toMap()));
  }

  static Future<CachedValidation?> loadValidation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      return CachedValidation.fromMap(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
