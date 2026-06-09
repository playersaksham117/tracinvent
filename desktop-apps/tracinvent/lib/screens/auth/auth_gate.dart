import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'pin_login_screen.dart';
import 'set_pin_screen.dart';

class AuthGate extends StatelessWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking authentication...'),
                ],
              ),
            ),
          );
        }

        if (auth.isLoggedIn) {
          if (auth.needsPinSetup) {
            return SetPinScreen(onComplete: child);
          }
          return child;
        }

        if (auth.pinEnabled && auth.savedUserId != null) {
          return const PinLoginScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
