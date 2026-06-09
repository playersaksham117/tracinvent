import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/license_service.dart';
import '../services/offline_grace_service.dart';

enum AuthState { unknown, unauthenticated, awaitingVerification, authenticated }

enum LicenseState { unknown, unlicensed, validating, valid, invalid, gracePeriod }

class SupabaseAuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final LicenseService _lic = LicenseService();

  AuthState _authState = AuthState.unknown;
  LicenseState _licenseState = LicenseState.unknown;
  UserProfile? _profile;
  String? _error;
  bool _loading = false;
  int? _graceDaysRemaining;

  AuthState get authState => _authState;
  LicenseState get licenseState => _licenseState;
  UserProfile? get profile => _profile;
  String? get error => _error;
  bool get loading => _loading;
  int? get graceDaysRemaining => _graceDaysRemaining;

  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isLicenseValid =>
      _licenseState == LicenseState.valid ||
      _licenseState == LicenseState.gracePeriod;

  // ── Registration ──────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String mobile,
    required String country,
    String? company,
    required String pin,
  }) async {
    _setLoading(true);
    final result = await _auth.register(
      email: email,
      password: password,
      fullName: fullName,
      mobileNumber: mobile,
      country: country,
      companyName: company,
      securityPin: pin,
    );
    if (result.success) {
      _authState = AuthState.awaitingVerification;
    }
    _setError(result.error);
    _setLoading(false);
    return result.success;
  }

  // ── Login ─────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    final result = await _auth.login(email: email, password: password);
    if (result.success && result.profile != null) {
      _profile = result.profile;
      _authState = AuthState.authenticated;
      await _validateLicenseOnLogin();
    } else if (result.error == 'EMAIL_NOT_VERIFIED') {
      _authState = AuthState.awaitingVerification;
    }
    _setError(result.error == 'EMAIL_NOT_VERIFIED' ? null : result.error);
    _setLoading(false);
    return result.success;
  }

  Future<void> _validateLicenseOnLogin() async {
    _licenseState = LicenseState.validating;
    notifyListeners();
    final user = _auth.currentUser;
    if (user == null) {
      _licenseState = LicenseState.invalid;
      notifyListeners();
      return;
    }
    final result = await _lic.validateOnStartup(
      userId: user.id,
      appVersion: '1.1.0',
    );
    if (result.isValid) {
      _licenseState = result.source == ValidationSource.cache
          ? LicenseState.gracePeriod
          : LicenseState.valid;
      _graceDaysRemaining = result.daysRemaining;
    } else {
      _licenseState = LicenseState.invalid;
    }
    notifyListeners();
  }

  // ── License activation ────────────────────────────────────
  Future<bool> activateLicense(String licenseKey) async {
    _setLoading(true);
    final user = _auth.currentUser;
    if (user == null) {
      _setError('Not signed in');
      _setLoading(false);
      return false;
    }
    final result = await _lic.activateLicense(
      licenseKey: licenseKey,
      userId: user.id,
      appVersion: '1.1.0',
    );
    if (result.success) {
      _licenseState = LicenseState.valid;
      _profile = await _auth.getProfile(user.id);
    }
    _setError(result.error);
    _setLoading(false);
    return result.success;
  }

  // ── Password / PIN ────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    final r = await _auth.sendPasswordReset(email);
    _setError(r.error);
    return r.success;
  }

  Future<bool> verifyPin(String pin) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return _auth.verifyPin(user.id, pin);
  }

  Future<bool> resendVerification(String email) async {
    final r = await _auth.resendVerificationEmail(email);
    _setError(r.error);
    return r.success;
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.logout();
    await OfflineGraceService.clear();
    _profile = null;
    _authState = AuthState.unauthenticated;
    _licenseState = LicenseState.unknown;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────
  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    if (e != null) notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
