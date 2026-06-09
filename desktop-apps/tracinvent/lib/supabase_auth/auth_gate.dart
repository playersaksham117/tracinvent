import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/supabase_auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/license_activation_screen.dart';
import 'screens/email_verification_screen.dart';

/// AuthGate wraps the entire app shell.
///
/// ⚠️ NOT ACTIVE — to activate, replace the root widget in main.dart:
///
///   // In main():
///   await SupabaseConfig.initialize();
///
///   // In runApp():
///   MultiProvider(
///     providers: [
///       ChangeNotifierProvider(create: (_) => SupabaseAuthProvider()),
///       // ... other providers ...
///     ],
///     child: MaterialApp(
///       home: AuthGate(child: const HomeScreen()),
///     ),
///   );
class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseAuthProvider>(
      builder: (context, auth, _) {
        switch (auth.authState) {
          case AuthState.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );

          case AuthState.unauthenticated:
            return const SupabaseLoginScreen();

          case AuthState.awaitingVerification:
            return EmailVerificationScreen(
              email: auth.profile?.email ?? '',
            );

          case AuthState.authenticated:
            switch (auth.licenseState) {
              case LicenseState.unknown:
              case LicenseState.validating:
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Validating license...'),
                      ],
                    ),
                  ),
                );

              case LicenseState.unlicensed:
              case LicenseState.invalid:
                return const LicenseActivationScreen();

              case LicenseState.gracePeriod:
                return _GracePeriodBanner(
                  daysRemaining: auth.graceDaysRemaining ?? 0,
                  child: child,
                );

              case LicenseState.valid:
                return child;
            }
        }
      },
    );
  }
}

/// Non-blocking banner shown when app is in offline grace period.
class _GracePeriodBanner extends StatelessWidget {
  final int daysRemaining;
  final Widget child;
  const _GracePeriodBanner(
      {required this.daysRemaining, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: MaterialBanner(
            backgroundColor: Colors.orange.shade50,
            content: Text(
              'Offline mode — $daysRemaining day(s) remaining before license revalidation required.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
            leading: Icon(Icons.wifi_off, color: Colors.orange.shade700),
            actions: [
              TextButton(
                onPressed: () =>
                    context.read<SupabaseAuthProvider>().logout(),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
