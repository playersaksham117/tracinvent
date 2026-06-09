import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/inventory/inventory_list_screen.dart';
import '../screens/inventory/item_detail_screen.dart';
import '../screens/inventory/add_item_screen.dart';
import '../screens/warehouse/warehouse_list_screen.dart';
import '../screens/warehouse/warehouse_detail_screen.dart';
import '../screens/warehouse/location_browser_screen.dart';
import '../screens/stock/stock_in_screen.dart';
import '../screens/stock/stock_out_screen.dart';
import '../screens/stock/transfer_screen.dart';
import '../screens/stock/cycle_count_screen.dart';
import '../screens/stock/adjustment_screen.dart';
import '../screens/movements/movement_history_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/scanner/barcode_scanner_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String main = '/main';
  static const String dashboard = '/dashboard';
  
  // Inventory
  static const String inventoryList = '/inventory';
  static const String itemDetail = '/inventory/detail';
  static const String addItem = '/inventory/add';
  static const String editItem = '/inventory/edit';
  
  // Warehouse
  static const String warehouseList = '/warehouses';
  static const String warehouseDetail = '/warehouses/detail';
  static const String locationBrowser = '/warehouses/locations';
  
  // Stock Operations
  static const String stockIn = '/stock/in';
  static const String stockOut = '/stock/out';
  static const String transfer = '/stock/transfer';
  static const String cycleCount = '/stock/cycle-count';
  static const String adjustment = '/stock/adjustment';
  
  // Movement History
  static const String movements = '/movements';
  
  // Search & Scanner
  static const String search = '/search';
  static const String scanner = '/scanner';
  
  // Settings
  static const String settings = '/settings';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen(), settings);
      
      case login:
        return _slideRoute(const LoginScreen(), settings);
      
      case main:
        return _fadeRoute(const MainShell(), settings);
      
      case dashboard:
        return _fadeRoute(const DashboardScreen(), settings);
      
      case inventoryList:
        return _slideRoute(const InventoryListScreen(), settings);
      
      case itemDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          ItemDetailScreen(itemId: args?['itemId']),
          settings,
        );
      
      case addItem:
        return _slideRoute(const AddItemScreen(), settings);
      
      case editItem:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          AddItemScreen(itemId: args?['itemId']),
          settings,
        );
      
      case warehouseList:
        return _slideRoute(const WarehouseListScreen(), settings);
      
      case warehouseDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          WarehouseDetailScreen(warehouseId: args?['warehouseId']),
          settings,
        );
      
      case locationBrowser:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          LocationBrowserScreen(
            warehouseId: args?['warehouseId'],
            parentId: args?['parentId'],
          ),
          settings,
        );
      
      case stockIn:
        return _slideRoute(const StockInScreen(), settings);
      
      case stockOut:
        return _slideRoute(const StockOutScreen(), settings);
      
      case transfer:
        return _slideRoute(const TransferScreen(), settings);
      
      case cycleCount:
        return _slideRoute(const CycleCountScreen(), settings);
      
      case adjustment:
        return _slideRoute(const AdjustmentScreen(), settings);
      
      case movements:
        return _slideRoute(const MovementHistoryScreen(), settings);
      
      case search:
        return _slideRoute(const SearchScreen(), settings);
      
      case scanner:
        return _slideRoute(const BarcodeScannerScreen(), settings);
      
      case AppRoutes.settings:
        return _slideRoute(const SettingsScreen(), settings);
      
      default:
        return _fadeRoute(const SplashScreen(), settings);
    }
  }
  
  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
  
  static PageRouteBuilder _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
