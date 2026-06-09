import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_init.dart';
import '../models/user_profile.dart';

class AuthResult {
  final bool success;
  final String? error;
  final UserProfile? profile;
  const AuthResult({required this.success, this.error, this.profile});
}

class AuthService {
  SupabaseClient get _sb => SupabaseConfig.client;

  /// Register user: creates Supabase auth account.
  /// Profile row is created AFTER email verification via [createProfile].
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required String mobileNumber,
    required String country,
    String? companyName,
    required String securityPin,
  }) async {
    try {
      final res = await _sb.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'mobile_number': mobileNumber,
          'company_name': companyName,
          'country': country,
          'security_pin_hash': _hashPin(securityPin),
        },
      );
      if (res.user == null) {
        return const AuthResult(success: false, error: 'Registration failed');
      }
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Login with email + password.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _sb.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) {
        return const AuthResult(success: false, error: 'Login failed');
      }
      if (res.user!.emailConfirmedAt == null) {
        return const AuthResult(
            success: false, error: 'EMAIL_NOT_VERIFIED');
      }
      final profile = await getProfile(res.user!.id);
      if (profile != null) {
        await _sb
            .from('profiles')
            .update({'last_login': DateTime.now().toIso8601String()})
            .eq('id', res.user!.id);
      }
      return AuthResult(success: true, profile: profile);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Called after email is verified — inserts profile row.
  Future<AuthResult> createProfile({
    required String userId,
    required String email,
    required String fullName,
    required String mobileNumber,
    required String country,
    String? companyName,
    required String securityPin,
  }) async {
    try {
      await _sb.from('profiles').upsert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'mobile_number': mobileNumber,
        'company_name': companyName,
        'country': country,
        'security_pin_hash': _hashPin(securityPin),
        'license_status': 'inactive',
        'license_type': 'free',
        'device_count': 0,
      });
      final profile = await getProfile(userId);
      return AuthResult(success: true, profile: profile);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  Future<UserProfile?> getProfile(String userId) async {
    try {
      final data =
          await _sb.from('profiles').select().eq('id', userId).single();
      return UserProfile.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _sb.auth.signOut();
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _sb.auth.resetPasswordForEmail(email);
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    }
  }

  Future<AuthResult> resendVerificationEmail(String email) async {
    try {
      await _sb.auth.resend(type: OtpType.signup, email: email);
      return const AuthResult(success: true);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Verify 6-digit PIN (for PIN recovery flow).
  Future<bool> verifyPin(String userId, String pin) async {
    try {
      final data = await _sb
          .from('profiles')
          .select('security_pin_hash')
          .eq('id', userId)
          .single();
      return data['security_pin_hash'] == _hashPin(pin);
    } catch (_) {
      return false;
    }
  }

  Future<AuthResult> updatePin(String userId, String newPin) async {
    try {
      await _sb.from('profiles').update(
          {'security_pin_hash': _hashPin(newPin)}).eq('id', userId);
      return const AuthResult(success: true);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  User? get currentUser => _sb.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'tracinvent_pin_salt_2026');
    return sha256.convert(bytes).toString();
  }
}
