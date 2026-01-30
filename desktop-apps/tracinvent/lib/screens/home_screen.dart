import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/warehouse_provider.dart';
import '../providers/sync_provider.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'warehouses_screen.dart';
import 'transactions_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'stock_search_screen.dart';
import 'stock_location_screen.dart';
import 'daily_transactions_screen.dart';
import 'cell_stock_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const InventoryScreen(),
    const StockSearchScreen(),
    const StockLocationScreen(),
    const CellStockViewScreen(),
    const DailyTransactionsScreen(),
    const WarehousesScreen(),
    const TransactionsScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Enhanced Sidebar Navigation
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Logo + App Name
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          size: 32,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TracInvent',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Inventory System',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Divider(height: 1, color: Colors.grey.shade200),
                
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    children: [
                      _buildNavItem(
                        context,
                        0,
                        Icons.dashboard_outlined,
                        Icons.dashboard,
                        'Dashboard',
                      ),
                      _buildNavItem(
                        context,
                        1,
                        Icons.inventory_outlined,
                        Icons.inventory,
                        'Inventory',
                      ),
                      _buildNavItem(
                        context,
                        2,
                        Icons.search_outlined,
                        Icons.search,
                        'Stock Search',
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'STOCK TRACKING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      _buildNavItem(
                        context,
                        3,
                        Icons.location_on_outlined,
                        Icons.location_on,
                        'Stock Locations',
                      ),
                      _buildNavItem(
                        context,
                        4,
                        Icons.grid_view_outlined,
                        Icons.grid_view,
                        'Cell Stock View',
                      ),
                      _buildNavItem(
                        context,
                        5,
                        Icons.calendar_today_outlined,
                        Icons.calendar_today,
                        'Daily Log',
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'MANAGEMENT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      _buildNavItem(
                        context,
                        6,
                        Icons.warehouse_outlined,
                        Icons.warehouse,
                        'Warehouses',
                      ),
                      _buildNavItem(
                        context,
                        7,
                        Icons.add_shopping_cart_outlined,
                        Icons.add_shopping_cart,
                        'Stock In/Out',
                      ),
                      _buildNavItem(
                        context,
                        8,
                        Icons.assessment_outlined,
                        Icons.assessment,
                        'Reports',
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'SYSTEM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      _buildNavItem(
                        context,
                        9,
                        Icons.settings_outlined,
                        Icons.settings,
                        'Settings',
                      ),
                    ],
                  ),
                ),
                
                // User Profile Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Sync Status
                      Consumer<SyncProvider>(
                        builder: (context, syncProvider, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: syncProvider.isOnline
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  syncProvider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                                  size: 16,
                                  color: syncProvider.isOnline
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    syncProvider.isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: syncProvider.isOnline
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                                if (syncProvider.pendingChangesCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${syncProvider.pendingChangesCount}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                if (syncProvider.syncStatus == SyncStatus.syncing)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                if (syncProvider.isOnline &&
                                    syncProvider.syncStatus != SyncStatus.syncing)
                                  IconButton(
                                    icon: const Icon(Icons.sync, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => syncProvider.forceSyncNow(),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      // User Profile
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                            child: const Text(
                              'A',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Admin User',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'admin@tracinvent.com',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedIndex = index);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2563EB).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
