import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'providers/inventory_provider.dart';
import 'providers/warehouse_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/stock_entry_provider.dart';
import 'providers/update_provider.dart';
import 'providers/stock_search_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/update_dialog.dart';

void main() {
  // Initialize FFI for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const TracInventApp());
}

class _AppInitializer extends StatefulWidget {
  final Widget child;
  
  const _AppInitializer({required this.child});

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Check for updates on startup (after a short delay)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
        updateProvider.checkForUpdates(silent: true).then((_) {
          if (mounted && updateProvider.hasUpdate) {
            // Show update dialog
            showUpdateDialog(context);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class TracInventApp extends StatelessWidget {
  const TracInventApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => WarehouseProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => StockEntryProvider()),
        ChangeNotifierProvider(create: (_) => StockSearchProvider()),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
      ],
      child: MaterialApp(
        title: 'TracInvent - Inventory Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: _AppInitializer(
          child: const HomeScreen(),
        ),
      ),
    );
  }
}
