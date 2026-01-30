import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/transaction_provider.dart';
import 'providers/account_provider.dart';
import 'core/modern_colors.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
      ],
      child: const SpendSightApp(),
    ),
  );
}

class SpendSightApp extends StatelessWidget {
  const SpendSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendSight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ModernColors.primary,
          brightness: Brightness.light,
          primary: ModernColors.primary,
          secondary: ModernColors.accent,
          error: ModernColors.error,
          surface: ModernColors.surface,
          background: ModernColors.background,
        ),
        scaffoldBackgroundColor: ModernColors.background,
        textTheme: GoogleFonts.interTextTheme(),
        cardTheme: const CardThemeData(
          elevation: 0,
          shadowColor: Color(0x0A000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          color: ModernColors.surface,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: ModernColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: ModernColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: ModernColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: ModernColors.textPrimary),
          titleTextStyle: GoogleFonts.inter(
            color: ModernColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C5FE8),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        cardTheme: const CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
