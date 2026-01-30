import 'package:flutter/material.dart';

/// Design system colors for SpendSight
/// Soft, fintech-focused color palette
class AppColors {
  // Primary - Soft Purple (Trust & Stability)
  static const primary = Color(0xFF7C5FE8);
  static const primaryContainer = Color(0xFFE8E1FF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF2B1B5C);

  // Success - Soft Green (Income)
  static const success = Color(0xFF4CAF50);
  static const successLight = Color(0xFFE8F5E9);

  // Error - Soft Red (Expense)
  static const error = Color(0xFFEF5350);
  static const errorLight = Color(0xFFFFEBEE);

  // Warning - Soft Orange
  static const warning = Color(0xFFFF9800);
  static const warningLight = Color(0xFFFFF3E0);

  // Neutral - Clean Grays
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF3F4F6);
  static const onSurface = Color(0xFF1F2937);
  static const onSurfaceVariant = Color(0xFF6B7280);

  // Category Colors
  static const food = Color(0xFFFF9800);
  static const transport = Color(0xFF2196F3);
  static const shopping = Color(0xFF9C27B0);
  static const bills = Color(0xFF009688);
  static const health = Color(0xFFE91E63);
  static const entertainment = Color(0xFF00BCD4);
}

/// Spacing constants following 8pt grid system
class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius constants
class AppRadius {
  static const double small = 12.0;
  static const double medium = 16.0;
  static const double large = 20.0;
  static const double xlarge = 24.0;

  static BorderRadius circular(double radius) => BorderRadius.circular(radius);
  
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(large));
  static const BorderRadius xlargeRadius = BorderRadius.all(Radius.circular(xlarge));
}

/// Elevation and shadow configurations
class AppShadows {
  static List<BoxShadow> level1 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> level2 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> level3 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
