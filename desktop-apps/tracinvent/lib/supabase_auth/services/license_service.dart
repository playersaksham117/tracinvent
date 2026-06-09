import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_init.dart';
import 'offline_grace_service.dart';
import 'hardware_fingerprint_service.dart';
import '../models/device_info.dart';
import '../models/license.dart';

/// Communicates with Python licensing backend for all license operations.
/// Falls back to cached validation during offline grace period.
class LicenseService {
  static const String _backendBase = String.fromEnvironment(
    'LICENSING_API_URL',
    defaultValue: 'https://your-licensing-api.com',
  );

  SupabaseClient get _sb => SupabaseConfig.client;

  /// Register this device in Supabase and return the device ID.
  Future<String?> registerDevice({
    required String userId,
    required String appVersion,
  }) async {
    try {
      final info = await HardwareFingerprintService.collect();
      final regMap = info.toRegistrationMap(appVersion);
      regMap['user_id'] = userId;

      final existing = await _sb
          .from('devices')
          .select('id')
          .eq('user_id', userId)
          .eq('fingerprint_hash', info.fingerprintHash)
          .maybeSingle();

      if (existing != null) {
        await _sb.from('devices').update({'last_seen': DateTime.now().toIso8601String()}).eq(
            'id', existing['id']);
        return existing['id'] as String;
      }

      final res = await _sb
          .from('devices')
          .insert(regMap)
          .select('id')
          .single();
      return res['id'] as String;
    } catch (e) {
      return null;
    }
  }

  /// Activate a license key — calls Python backend (which uses service role).
  Future<LicenseActivationResult> activateLicense({
    required String licenseKey,
    required String userId,
    required String appVersion,
  }) async {
    final info = await HardwareFingerprintService.collect();
    final deviceId = await registerDevice(userId: userId, appVersion: appVersion);
    if (deviceId == null) {
      return const LicenseActivationResult(
          success: false, error: 'Failed to register device');
    }

    try {
      final jwt = _sb.auth.currentSession?.accessToken;
      final response = await http
          .post(
            Uri.parse('$_backendBase/api/v1/licenses/activate'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({
              'license_key': licenseKey,
              'device_id': deviceId,
              'fingerprint_hash': info.fingerprintHash,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['ok'] == true) {
        final validation = CachedValidation(
          validatedAt: DateTime.now(),
          licenseType: body['license_type'] as String,
          expiryDate: body['expiry_date'] != null
              ? DateTime.tryParse(body['expiry_date'] as String)
              : null,
          fingerprintHash: info.fingerprintHash,
        );
        await OfflineGraceService.saveValidation(validation);
        return LicenseActivationResult(
          success: true,
          licenseType: body['license_type'] as String,
          expiryDate: body['expiry_date'] != null
              ? DateTime.tryParse(body['expiry_date'] as String)
              : null,
        );
      }
      return LicenseActivationResult(
          success: false, error: body['error'] as String? ?? 'Activation failed');
    } catch (e) {
      return LicenseActivationResult(success: false, error: e.toString());
    }
  }

  /// Validate license on startup — tries online first, falls back to cache.
  Future<LicenseValidationResult> validateOnStartup({
    required String userId,
    required String appVersion,
  }) async {
    final info = await HardwareFingerprintService.collect();

    try {
      final jwt = _sb.auth.currentSession?.accessToken;
      final response = await http
          .post(
            Uri.parse('$_backendBase/api/v1/licenses/validate'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({
              'fingerprint_hash': info.fingerprintHash,
              'app_version': appVersion,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['ok'] == true) {
        final validation = CachedValidation(
          validatedAt: DateTime.now(),
          licenseType: body['license_type'] as String,
          expiryDate: body['expiry_date'] != null
              ? DateTime.tryParse(body['expiry_date'] as String)
              : null,
          fingerprintHash: info.fingerprintHash,
        );
        await OfflineGraceService.saveValidation(validation);
        return LicenseValidationResult(
          isValid: true,
          licenseType: body['license_type'] as String,
          source: ValidationSource.online,
        );
      }
      return LicenseValidationResult(
          isValid: false,
          error: body['error'] as String? ?? 'Invalid license',
          source: ValidationSource.online);
    } catch (_) {
      // Offline — check grace period cache
      final cached = await OfflineGraceService.loadValidation();
      if (cached != null &&
          cached.fingerprintHash == info.fingerprintHash &&
          cached.isValid) {
        return LicenseValidationResult(
          isValid: true,
          licenseType: cached.licenseType,
          source: ValidationSource.cache,
          daysRemaining: 7 - DateTime.now().difference(cached.validatedAt).inDays,
        );
      }
      return LicenseValidationResult(
          isValid: false,
          error: 'Cannot verify license. Grace period expired.',
          source: ValidationSource.cache);
    }
  }

  Future<List<RegisteredDevice>> getMyDevices(String userId) async {
    try {
      final data = await _sb
          .from('devices')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('last_seen', ascending: false);
      return (data as List)
          .map((m) => RegisteredDevice.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

// ─── Result types ────────────────────────────────────────────
enum ValidationSource { online, cache }

class LicenseActivationResult {
  final bool success;
  final String? error;
  final String? licenseType;
  final DateTime? expiryDate;
  const LicenseActivationResult(
      {required this.success, this.error, this.licenseType, this.expiryDate});
}

class LicenseValidationResult {
  final bool isValid;
  final String? error;
  final String? licenseType;
  final ValidationSource source;
  final int? daysRemaining;
  const LicenseValidationResult({
    required this.isValid,
    this.error,
    this.licenseType,
    required this.source,
    this.daysRemaining,
  });
}
