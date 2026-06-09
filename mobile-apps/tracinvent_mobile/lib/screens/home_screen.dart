import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/warehouse_provider.dart';
import 'adjustment_screen.dart';
import 'cell_stock_view_screen.dart';
import 'daily_transactions_screen.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'stock_location_screen.dart';
import 'transactions_screen.dart';
import 'warehouses_screen.dart';

/// Mobile shell: bottom navigation for primary flows + drawer for all other screens
/// (same screen widgets and navigation indices as desktop TracInvent).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = const [
    DashboardScreen(),
    InventoryScreen(),
    InventoryScreen(),
    StockLocationScreen(),
    CellStockViewScreen(),
    DailyTransactionsScreen(),
    AdjustmentScreen(),
    WarehousesScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  static const List<_BottomTab> _bottomTabs = [
    _BottomTab(NavigationIndex.dashboard, 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _BottomTab(NavigationIndex.inventory, 'Inventory', Icons.inventory_2_outlined, Icons.inventory_2),
    _BottomTab(NavigationIndex.warehouses, 'Warehouses', Icons.warehouse_outlined, Icons.warehouse),
    _BottomTab(NavigationIndex.stockInOut, 'Activity', Icons.swap_horiz_outlined, Icons.swap_horiz),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final warehouseProvider = Provider.of<WarehouseProvider>(context, listen: false);
    await inventoryProvider.loadInventoryItems();
    await warehouseProvider.loadWarehouses();
  }

  String _titleForIndex(int index) {
    switch (index) {
      case NavigationIndex.dashboard:
        return 'Dashboard';
      case NavigationIndex.inventory:
        return 'Inventory';
      case NavigationIndex.stockLocations:
        return 'Stock locations';
      case NavigationIndex.cellStockView:
        return 'Cell stock';
      case NavigationIndex.dailyLog:
        return 'Daily log';
      case NavigationIndex.adjustments:
        return 'Adjustments';
      case NavigationIndex.warehouses:
        return 'Warehouses';
      case NavigationIndex.stockInOut:
        return 'Stock in / out';
      case NavigationIndex.reports:
        return 'Reports';
      case NavigationIndex.settings:
        return 'Settings';
      default:
        return 'TracInvent';
    }
  }

  void _goTo(int index) {
    Provider.of<NavigationProvider>(context, listen: false).navigateTo(index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _onRefresh() async {
    await _loadData();
    if (!mounted) return;
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    if (syncProvider.isOnline && syncProvider.syncStatus != SyncStatus.syncing) {
      await syncProvider.forceSyncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final selectedIndex = navigationProvider.selectedIndex;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titleForIndex(selectedIndex)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Consumer<SyncProvider>(
              builder: (context, syncProvider, _) {
                final chipColor =
                    syncProvider.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
                final iconColor =
                    syncProvider.isOnline ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
                return Container(
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        syncProvider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                        size: 16,
                        color: iconColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          syncProvider.isOnline ? 'Connected to desktop sync' : 'Offline mode active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: iconColor,
                          ),
                        ),
                      ),
                      if (syncProvider.pendingChangesCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${syncProvider.pendingChangesCount} pending',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.inventory_2, size: 40, color: Color(0xFF2563EB)),
                    SizedBox(height: 8),
                    Text(
                      'TracInvent',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Inventory (mobile)',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _drawerSection('Overview'),
                    _drawerTile(selectedIndex, NavigationIndex.dashboard, Icons.dashboard, 'Dashboard'),
                    _drawerTile(selectedIndex, NavigationIndex.inventory, Icons.inventory_2, 'Inventory'),
                    _drawerSection('Stock tracking'),
                    _drawerTile(selectedIndex, NavigationIndex.stockLocations, Icons.location_on, 'Stock locations'),
                    _drawerTile(selectedIndex, NavigationIndex.cellStockView, Icons.grid_view, 'Cell stock view'),
                    _drawerTile(selectedIndex, NavigationIndex.dailyLog, Icons.calendar_today, 'Daily log'),
                    _drawerSection('Adjustments'),
                    _drawerTile(selectedIndex, NavigationIndex.adjustments, Icons.tune, 'Adjustments & batches'),
                    _drawerSection('Management'),
                    _drawerTile(selectedIndex, NavigationIndex.warehouses, Icons.warehouse, 'Warehouses'),
                    _drawerTile(selectedIndex, NavigationIndex.stockInOut, Icons.add_shopping_cart, 'Stock in / out'),
                    _drawerTile(selectedIndex, NavigationIndex.reports, Icons.assessment, 'Reports'),
                    _drawerSection('System'),
                    _drawerTile(selectedIndex, NavigationIndex.settings, Icons.settings, 'Settings'),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Consumer<SyncProvider>(
                  builder: (context, syncProvider, _) {
                    return ListTile(
                      leading: Icon(
                        syncProvider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                        color: syncProvider.isOnline
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                      title: Text(syncProvider.isOnline ? 'Online' : 'Offline'),
                      subtitle: syncProvider.pendingChangesCount > 0
                          ? Text('${syncProvider.pendingChangesCount} pending')
                          : null,
                      trailing: syncProvider.isOnline && syncProvider.syncStatus != SyncStatus.syncing
                          ? IconButton(
                              icon: const Icon(Icons.sync),
                              onPressed: () => syncProvider.forceSyncNow(),
                            )
                          : syncProvider.syncStatus == SyncStatus.syncing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: IndexedStack(
          index: selectedIndex.clamp(0, _screens.length - 1),
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomNavIndexForScreen(selectedIndex),
        onDestinationSelected: (i) {
          navigationProvider.navigateTo(_bottomTabs[i].navIndex);
        },
        destinations: [
          for (final t in _bottomTabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }

  int _bottomNavIndexForScreen(int screenIndex) {
    for (var i = 0; i < _bottomTabs.length; i++) {
      if (_bottomTabs[i].navIndex == screenIndex) return i;
    }
    return 0;
  }

  Widget _drawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _drawerTile(int selected, int index, IconData icon, String label) {
    final selectedHere = selected == index;
    return ListTile(
      leading: Icon(icon, color: selectedHere ? const Color(0xFF2563EB) : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selectedHere ? FontWeight.w600 : FontWeight.w500,
          color: selectedHere ? const Color(0xFF2563EB) : null,
        ),
      ),
      selected: selectedHere,
      onTap: () => _goTo(index),
    );
  }
}

class _BottomTab {
  final int navIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _BottomTab(this.navIndex, this.label, this.icon, this.selectedIcon);
}
