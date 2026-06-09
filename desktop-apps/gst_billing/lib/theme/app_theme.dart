/// App Theme - Modern Clean Fintech Design
/// BillEase Accounts+ - Professional GST Billing Desktop Application
/// "Well-Mannered" (polite, predictable) & "Modern" (clean, spacious)
library;

import 'package:flutter/material.dart';

class AppTheme {
  // ============ DESIGN SYSTEM COLORS - "Clean Fintech" Look ============
  
  // Primary Brand - Deep "Try Sarthi" Navy (Sidebar)
  static const Color sidebarColor = Color(0xFF0f172a);  // Deep Navy
  static const Color sidebarHover = Color(0xFF1e293b);
  static const Color sidebarSelected = Color(0xFF2563eb);
  
  // Canvas - Modern Light Backgrounds
  static const Color canvasColor = Color(0xFFF8FAFC);  // Soft light background
  static const Color canvasSecondary = Color(0xFFEFF6FF);  // Soft blue for sections
  
  // Cards - Pure White with subtle shadows
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // Primary Action Blue - Royal Blue for "Save/Print"
  static const Color primaryColor = Color(0xFF2563eb);
  static const Color primaryHover = Color(0xFF1d4ed8);
  static const Color primaryLight = Color(0xFFdbeafe);
  
  // Secondary Teal
  static const Color secondaryColor = Color(0xFF14b8a6);
  static const Color secondaryLight = Color(0xFFccfbf1);
  
  // Accent Orange (for gentle warnings)
  static const Color accentColor = Color(0xFFf97316);
  static const Color accentLight = Color(0xFFfed7aa);
  
  // ============ SEMANTIC COLORS - Transaction Backgrounds ============
  // Soft Green for Credits/Income (use as row backgrounds)
  static const Color creditBg = Color(0xFFdcfce7);
  static const Color creditText = Color(0xFF166534);
  static const Color creditBorder = Color(0xFFbbf7d0);
  
  // Soft Red for Debits/Expenses (use as row backgrounds)
  static const Color debitBg = Color(0xFFfee2e2);
  static const Color debitText = Color(0xFFdc2626);
  static const Color debitBorder = Color(0xFFfecaca);
  
  // ============ SLATE TEXT COLORS ============
  static const Color slate900 = Color(0xFF0f172a);  // Darkest headers
  static const Color slate800 = Color(0xFF1e293b);  // Headers
  static const Color slate700 = Color(0xFF334155);  // Subheaders
  static const Color slate600 = Color(0xFF475569);  // Body text (Labels)
  static const Color slate500 = Color(0xFF64748b);  // Secondary labels
  static const Color slate400 = Color(0xFF94a3b8);  // Placeholders
  static const Color slate300 = Color(0xFFcbd5e1);  // Borders
  static const Color slate200 = Color(0xFFe2e8f0);  // Dividers
  static const Color slate100 = Color(0xFFf1f5f9);  // Hover bg
  static const Color slate50 = Color(0xFFf8fafc);   // Lightest bg
  
  // ============ STATUS COLORS ============
  static const Color successColor = Color(0xFF22c55e);
  static const Color successLight = Color(0xFFdcfce7);
  static const Color warningColor = Color(0xFFeab308);
  static const Color warningLight = Color(0xFFfef9c3);
  static const Color errorColor = Color(0xFFef4444);
  static const Color errorLight = Color(0xFFfee2e2);
  static const Color infoColor = Color(0xFF0ea5e9);
  static const Color infoLight = Color(0xFFe0f2fe);
  
  // ============ GST COLORS ============
  static const Color cgstColor = Color(0xFF3b82f6);
  static const Color sgstColor = Color(0xFF22c55e);
  static const Color igstColor = Color(0xFFf97316);
  static const Color cessColor = Color(0xFF8b5cf6);
  
  // ============ CHART COLORS ============
  static const List<Color> chartColors = [
    Color(0xFF3b82f6),
    Color(0xFF22c55e),
    Color(0xFFf97316),
    Color(0xFF8b5cf6),
    Color(0xFFec4899),
    Color(0xFF14b8a6),
  ];
  
  // ============ SPACING & SIZING ============
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  
  // ============ SHADOWS ============
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> cardShadowLarge = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  
  // ============ LIGHT THEME ============
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      tertiary: accentColor,
      error: errorColor,
      surface: cardColor,
      onSurface: slate800,
      surfaceContainerHighest: slate100,
    ),
    scaffoldBackgroundColor: canvasColor,
    
    // AppBar - Clean white header
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      backgroundColor: cardColor,
      foregroundColor: slate800,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: slate800,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    ),
    
    // Card - White with subtle shadow
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.05),
    ),
    
    // Input - Clean with slate borders
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: slate300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: slate300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: slate600),
      hintStyle: const TextStyle(color: slate400),
      prefixIconColor: slate500,
      suffixIconColor: slate500,
    ),
    
    // Elevated Button - Primary blue
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),
    
    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: slate700,
        side: const BorderSide(color: slate300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
    ),
    
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
    ),
    
    // DataTable - No stripes, hover highlight
    dataTableTheme: const DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(slate100),
      headingTextStyle: TextStyle(
        color: slate700,
        fontWeight: FontWeight.w600,
        fontSize: 13,
        fontFamily: 'Inter',
      ),
      dataTextStyle: TextStyle(
        color: slate600,
        fontSize: 13,
        fontFamily: 'Inter',
      ),
      horizontalMargin: 16,
      columnSpacing: 24,
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: slate200,
      thickness: 1,
      space: 1,
    ),
    
    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: slate100,
      selectedColor: primaryLight,
      labelStyle: const TextStyle(color: slate700, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      side: BorderSide.none,
    ),
    
    // TabBar
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: slate500,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Inter',
      ),
    ),
    
    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: const TextStyle(
        color: slate800,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    ),
    
    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: CircleBorder(),
    ),
    
    // Navigation Rail - Deep Navy Blue
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: sidebarColor,
      indicatorColor: sidebarSelected,
      selectedIconTheme: IconThemeData(color: Colors.white, size: 22),
      unselectedIconTheme: IconThemeData(color: slate400, size: 22),
      selectedLabelTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        fontFamily: 'Inter',
      ),
      unselectedLabelTextStyle: TextStyle(
        color: slate400,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        fontFamily: 'Inter',
      ),
      labelType: NavigationRailLabelType.all,
      minWidth: 80,
      useIndicator: true,
    ),
    
    // SnackBar (Toast notifications)
    snackBarTheme: SnackBarThemeData(
      backgroundColor: slate800,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Inter',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),
    
    // Tooltip
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: slate800,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'Inter',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    
    // Icon
    iconTheme: const IconThemeData(
      color: slate600,
      size: 20,
    ),
    
    // Text Theme - Slate color hierarchy
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: slate900,
        fontFamily: 'Inter',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: slate900,
        fontFamily: 'Inter',
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: slate800,
        fontFamily: 'Inter',
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: slate800,
        fontFamily: 'Inter',
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: slate800,
        fontFamily: 'Inter',
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: slate800,
        fontFamily: 'Inter',
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: slate700,
        fontFamily: 'Inter',
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: slate700,
        fontFamily: 'Inter',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: slate600,
        fontFamily: 'Inter',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: slate600,
        fontFamily: 'Inter',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: slate500,
        fontFamily: 'Inter',
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: slate600,
        fontFamily: 'Inter',
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: slate500,
        fontFamily: 'Inter',
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: slate400,
        fontFamily: 'Inter',
      ),
    ),
  );
  
  // ============ DARK THEME ============
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      surface: Color(0xFF1e293b),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0f172a),
    
    // AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Color(0xFF1e293b),
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    
    // Card
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF1e293b),
    ),
    
    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF334155),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Navigation Rail
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFF0f172a),
      indicatorColor: primaryColor,
      selectedIconTheme: IconThemeData(color: Colors.white),
      unselectedIconTheme: IconThemeData(color: Color(0xFF94a3b8)),
      labelType: NavigationRailLabelType.all,
    ),
    
    // DataTable
    dataTableTheme: const DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(Color(0xFF334155)),
      headingTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      dataTextStyle: TextStyle(
        color: Color(0xFFe2e8f0),
        fontSize: 13,
      ),
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: Color(0xFF334155),
      thickness: 1,
    ),
  );
}

/// Custom styles
class AppStyles {
  // Currency text style
  static TextStyle currencyStyle(BuildContext context, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }
  
  // Status badge style
  static BoxDecoration statusBadge(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
    );
  }
  
  // Section header
  static Widget sectionHeader(BuildContext context, String title, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider()),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }
  
  // Amount display
  static Widget amountDisplay(BuildContext context, String label, double amount, {
    Color? color,
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          amount.toCurrencyString(),
          style: currencyStyle(context,
            color: color,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            fontSize: highlight ? 18 : 14,
          ),
        ),
      ],
    );
  }
}

/// Currency extension
extension CurrencyString on double {
  String toCurrencyString({String symbol = '₹', int decimals = 2}) {
    final parts = toStringAsFixed(decimals).split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';
    
    // Indian number formatting
    String formatted = '';
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      count++;
      formatted = intPart[i] + formatted;
      if (i > 0 && intPart[i - 1] != '-') {
        if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
          formatted = ',$formatted';
        }
      }
    }
    
    return '$symbol$formatted${decPart.isNotEmpty ? '.$decPart' : ''}';
  }
}

// ============================================================================
// FINTECH UI COMPONENTS - "Well-Mannered" Design System
// ============================================================================

/// Status Pill Widget - Used for Paid/Unpaid/Overdue status
enum InvoiceStatus { paid, unpaid, overdue, partial }

class StatusPill extends StatelessWidget {
  final InvoiceStatus status;
  final String? customLabel;
  
  const StatusPill({
    super.key,
    required this.status,
    this.customLabel,
  });
  
  @override
  Widget build(BuildContext context) {
    final (color, bgColor, label) = switch (status) {
      InvoiceStatus.paid => (const Color(0xFF166534), AppTheme.creditBg, 'Paid'),
      InvoiceStatus.unpaid => (AppTheme.slate600, AppTheme.slate100, 'Unpaid'),
      InvoiceStatus.overdue => (const Color(0xFFdc2626), AppTheme.debitBg, 'Overdue'),
      InvoiceStatus.partial => (const Color(0xFFd97706), const Color(0xFFfef3c7), 'Partial'),
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        customLabel ?? label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Monospaced Amount Text - For aligned financial columns
class MonoAmount extends StatelessWidget {
  final double amount;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showSign;
  
  const MonoAmount({
    super.key,
    required this.amount,
    this.color,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.showSign = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final displayAmount = showSign && amount > 0 ? '+${amount.toCurrencyString()}' : amount.toCurrencyString();
    return Text(
      displayAmount,
      style: TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? (amount >= 0 ? AppTheme.creditText : AppTheme.debitText),
        letterSpacing: -0.5,
      ),
    );
  }
}

/// Empty State Widget - Friendly illustration with action button
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onAction;
  
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onAction,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.slate100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.slate400),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.slate500,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gentle Validation Helper - Orange helper text instead of aggressive red borders
class GentleValidationText extends StatelessWidget {
  final String? message;
  final bool isWarning;
  
  const GentleValidationText({
    super.key,
    this.message,
    this.isWarning = true,
  });
  
  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          Icon(
            isWarning ? Icons.info_outline : Icons.check_circle_outline,
            size: 14,
            color: isWarning ? AppTheme.accentColor : AppTheme.successColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(
                fontSize: 12,
                color: isWarning ? AppTheme.accentColor : AppTheme.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Transaction Row Container - Semantic background colors
class TransactionRow extends StatelessWidget {
  final bool isCredit;
  final Widget child;
  final VoidCallback? onTap;
  
  const TransactionRow({
    super.key,
    required this.isCredit,
    required this.child,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCredit ? AppTheme.creditBg : AppTheme.debitBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 56, // Comfortable density - 56px row height
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isCredit ? AppTheme.creditBorder : AppTheme.debitBorder,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Bento Card - Dashboard metric card with icon
class BentoCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  
  const BentoCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.slate200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(Icons.arrow_forward, size: 16, color: AppTheme.slate400),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.slate500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// GST Slab Dropdown - Common slabs for quick selection
class GSTSlabDropdown extends StatelessWidget {
  final double? value;
  final ValueChanged<double> onChanged;
  
  const GSTSlabDropdown({
    super.key,
    this.value,
    required this.onChanged,
  });
  
  static const List<double> commonSlabs = [0, 5, 12, 18, 28];
  
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<double>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'GST %',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: commonSlabs.map((slab) => DropdownMenuItem(
        value: slab,
        child: Text('${slab.toInt()}%', style: const TextStyle(fontFamily: 'JetBrains Mono')),
      )).toList(),
      onChanged: (v) => onChanged(v ?? 18),
    );
  }
}

