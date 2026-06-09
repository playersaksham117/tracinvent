import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Authentication state
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthStateData> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(const AuthStateData());
  
  /// Initialize and try to restore session
  Future<void> initialize() async {
    state = state.copyWith(state: AuthState.loading);
    
    try {
      final restored = await _authService.restoreSession();
      if (restored) {
        state = state.copyWith(
          state: AuthState.authenticated,
          user: _authService.currentUser,
        );
      } else {
        state = state.copyWith(state: AuthState.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  /// Login
  Future<bool> login(String username, String password) async {
    state = state.copyWith(state: AuthState.loading, errorMessage: null);
    
    try {
      final user = await _authService.login(username, password);
      if (user != null) {
        state = state.copyWith(
          state: AuthState.authenticated,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          state: AuthState.unauthenticated,
          errorMessage: 'Invalid username or password',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    state = state.copyWith(
      state: AuthState.unauthenticated,
      user: null,
    );
  }
  
  /// Check permission
  bool hasPermission(String permission) {
    return _authService.hasPermission(permission);
  }
}

/// Auth state data
class AuthStateData {
  final AuthState state;
  final User? user;
  final String? errorMessage;
  
  const AuthStateData({
    this.state = AuthState.initial,
    this.user,
    this.errorMessage,
  });
  
  AuthStateData copyWith({
    AuthState? state,
    User? user,
    String? errorMessage,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
  
  bool get isAuthenticated => state == AuthState.authenticated;
  bool get isLoading => state == AuthState.loading;
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Is admin provider
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role == 'ADMIN';
});
