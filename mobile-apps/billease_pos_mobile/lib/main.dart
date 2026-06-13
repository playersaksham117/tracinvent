import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:billease_pos/theme/app_theme.dart';
import 'package:billease_pos/screens/dashboard_screen.dart';
import 'package:billease_pos/screens/billing_screen.dart';
import 'package:billease_pos/screens/products_screen.dart';
import 'package:billease_pos/screens/customer_management_screen.dart';
import 'package:billease_pos/screens/sales_history_screen.dart';
import 'package:billease_pos/screens/reports_screen.dart';
import 'package:billease_pos/screens/settings_screen.dart';
import 'package:billease_pos/screens/data_import_export_screen.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const BillEasePOSMobileApp());
}

class BillEasePOSMobileApp extends StatelessWidget {
  const BillEasePOSMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BillEase POS Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MobileShell(),
    );
  }
}

class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _selectedIndex = 0;

  final List<_MobileNavItem> _items = const [
    _MobileNavItem('Dashboard', Icons.dashboard_rounded),
    _MobileNavItem('Billing', Icons.point_of_sale_rounded),
    _MobileNavItem('Products', Icons.inventory_2_rounded),
    _MobileNavItem('Customers', Icons.people_rounded),
    _MobileNavItem('Sales', Icons.receipt_long_rounded),
    _MobileNavItem('Reports', Icons.analytics_rounded),
    _MobileNavItem('Settings', Icons.settings_rounded),
    _MobileNavItem('Import/Export', Icons.import_export_rounded),
  ];

  Widget _screenForIndex(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const BillingScreen();
      case 2:
        return const ProductsScreen();
      case 3:
        return const CustomerManagementScreen();
      case 4:
        return const SalesHistoryScreen();
      case 5:
        return const ReportsScreen();
      case 6:
        return const SettingsScreen();
      case 7:
        return const DataImportExportScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _items[_selectedIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(selected.title),
      ),
      drawer: Drawer(
        child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return ListTile(
              leading: Icon(item.icon),
              title: Text(item.title),
              selected: _selectedIndex == index,
              onTap: () {
                setState(() => _selectedIndex = index);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      body: _screenForIndex(_selectedIndex),
    );
  }
}

class _MobileNavItem {
  final String title;
  final IconData icon;

  const _MobileNavItem(this.title, this.icon);
}
