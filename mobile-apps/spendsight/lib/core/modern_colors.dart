import 'package:flutter/material.dart';

/// Modern vibrant color scheme for financial dashboard
class ModernColors {
  // Primary - Vibrant Purple/Blue gradient
  static const primary = Color(0xFF6C63FF);
  static const primaryDark = Color(0xFF5848E8);
  static const primaryLight = Color(0xFF8B84FF);
  
  // Accent colors - Vibrant
  static const accent = Color(0xFFFF6584);
  static const accentLight = Color(0xFFFF8BA7);
  
  // Success - Vibrant Green
  static const success = Color(0xFF00D9A3);
  static const successDark = Color(0xFF00C48F);
  
  // Warning - Vibrant Orange
  static const warning = Color(0xFFFFB84D);
  static const warningDark = Color(0xFFFF9F1C);
  
  // Error - Vibrant Red/Pink
  static const error = Color(0xFFFF6B6B);
  static const errorDark = Color(0xFFEE5A52);
  
  // Neutrals - Modern
  static const background = Color(0xFFF7F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFFAFBFD);
  static const border = Color(0xFFE5E9F2);
  
  // Text
  static const textPrimary = Color(0xFF1A1D1F);
  static const textSecondary = Color(0xFF6F767E);
  static const textTertiary = Color(0xFF9A9FA5);
  
  // Category Colors - Vibrant
  static const food = Color(0xFFFF9066);
  static const transport = Color(0xFF6DD3F5);
  static const shopping = Color(0xFFBD7AF3);
  static const bills = Color(0xFF5FC88F);
  static const health = Color(0xFFFF7EB3);
  static const entertainment = Color(0xFFFFC542);
  static const salary = Color(0xFF00D9A3);
  static const freelance = Color(0xFF6C63FF);
  
  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF5848E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const successGradient = LinearGradient(
    colors: [Color(0xFF00D9A3), Color(0xFF00C48F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const errorGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
