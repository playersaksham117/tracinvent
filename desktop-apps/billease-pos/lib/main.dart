import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'screens/dashboard_screen.dart';
import 'screens/branch_management_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/customer_management_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_layout.dart';
import 'theme/app_theme.dart';

void main() {
  // Initialize FFI for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const BillEasePOSApp());
}

class BillEasePOSApp extends StatelessWidget {
  const BillEasePOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BillEase POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget screen;
        String route = settings.name ?? '/';
        
        switch (route) {
          case '/':
            screen = DashboardScreen();
            break;
          case '/billing':
            screen = const BillingScreen();
            break;
          case '/products':
            screen = const ProductsScreen();
            break;
          case '/customers':
            screen = const CustomerManagementScreen();
            break;
          case '/sales-history':
            screen = const SalesHistoryScreen();
            break;
          case '/branches':
            screen = const BranchManagementScreen();
            break;
          case '/settings':
            screen = const SettingsScreen();
            break;
          case '/reports':
            screen = const ReportsScreen();
            break;
          default:
            screen = DashboardScreen();
        }
        
        return MaterialPageRoute(
          builder: (context) => AppLayout(
            currentRoute: route,
            child: screen,
          ),
          settings: settings,
        );
      },
    );
  }
}
