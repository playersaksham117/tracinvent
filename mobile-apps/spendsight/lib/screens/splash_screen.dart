import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'new_home_screen.dart';
import '../core/modern_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToAuth();
  }

  _navigateToAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.insights,
                size: 64,
                color: ModernColors.primary,
              ),
            ).animate()
              .scale(duration: 600.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 400.ms),
            
            const SizedBox(height: 24),
            
            // App Name
            Text(
              'SpendSight',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ).animate()
              .fadeIn(delay: 300.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0, duration: 500.ms),
            
            const SizedBox(height: 8),
            
            Text(
              'See your money clearly',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ).animate()
              .fadeIn(delay: 500.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
