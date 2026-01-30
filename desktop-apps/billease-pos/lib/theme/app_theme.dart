import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// =============================================================================
/// TRY SARTHI ADMIN - DESIGN SYSTEM
/// A stable, modern, enterprise-grade design system
/// =============================================================================

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFDBEAFE);

  // Navy (Sidebar)
  static const Color navyDark = Color(0xFF0F172A);
  static const Color navyMedium = Color(0xFF1E293B);
  static const Color navyLight = Color(0xFF334155);

  // Slate (Text)
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  // Background
  static const Color background = Color(0xFFF3F4F6);
  static const Color surface = Colors.white;
  static const Color surfaceHover = Color(0xFFF9FAFB);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF065F46);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF991B1B);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E40AF);

  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class AppRadius {
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double full = 9999.0;
}

class AppShadows {
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

/// =============================================================================
/// THEME DATA CONFIGURATION
/// =============================================================================

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.slate600,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      // Typography
      textTheme: GoogleFonts.interTextTheme().copyWith(
        // Display
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.slate900,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.slate900,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
        // Headlines
        headlineLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
        // Title
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.slate800,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.slate800,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.slate800,
        ),
        // Body
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.slate600,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.slate600,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.slate500,
        ),
        // Labels
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.slate700,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.slate600,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.slate500,
          letterSpacing: 0.5,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.slate900,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // Elevated Button Theme (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined Button Theme (Secondary)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.slate700,
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.slate400,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.slate600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.slate900,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.white,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
      ),

      // Popup Menu Theme
      popupMenuTheme: PopupMenuThemeData(
        elevation: 4,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.slate700,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.slate900,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
