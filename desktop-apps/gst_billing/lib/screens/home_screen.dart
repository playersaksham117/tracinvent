/// Main Dashboard / Home Screen
/// BillEase Accounts+ - Clean Corporate Design with Navy Sidebar
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'sales_entry_screen.dart';
import 'purchase_entry_screen.dart';
import 'credit_debit_notes_screen.dart';
import 'party_master_screen.dart';
import 'payments_statements_screen.dart';
import 'product_management_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Sales',
    ),
    NavigationDestination(
      icon: Icon(Icons.shopping_cart_outlined),
      selectedIcon: Icon(Icons.shopping_cart),
      label: 'Purchase',
    ),
    NavigationDestination(
      icon: Icon(Icons.note_outlined),
      selectedIcon: Icon(Icons.note),
      label: 'Notes',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Products & Inventory',
    ),
    NavigationDestination(
      icon: Icon(Icons.business_outlined),
      selectedIcon: Icon(Icons.business),
      label: 'Parties',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: 'Payments',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'Reports',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const SalesEntryScreen();
      case 2:
        return const PurchaseEntryScreen();
      case 3:
        return const CreditDebitNotesScreen();
      case 4:
        return const ProductManagementScreen();
      case 5:
        return const PartyMasterScreen();
      case 6:
        return const PaymentsStatementsScreen();
      case 7:
        return const ReportsScreen();
      case 8:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      body: Row(
        children: [
          // Navigation Rail - Deep Navy Blue Sidebar
          if (isWide)
            Container(
              width: 88,
              color: AppTheme.sidebarColor,
              child: Column(
                children: [
                  // Logo/Brand Section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'BillEase',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppTheme.slate700, height: 1),

                  // Navigation Items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _destinations.length,
                      itemBuilder: (context, index) {
                        final dest = _destinations[index];
                        final isSelected = _selectedIndex == index;

                        return _NavRailItem(
                          icon: isSelected
                              ? (dest.selectedIcon ?? dest.icon)
                              : dest.icon,
                          label: dest.label,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedIndex = index),
                        );
                      },
                    ),
                  ),

                  // Bottom User Section
                  const Divider(color: AppTheme.slate700, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _NavRailItem(
                      icon: const Icon(Icons.help_outline),
                      label: 'Help',
                      isSelected: false,
                      onTap: () {
                        // Show help dialog
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Main content area
          Expanded(child: _getScreen(_selectedIndex)),
        ],
      ),
      // Bottom navigation for mobile
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              backgroundColor: AppTheme.sidebarColor,
              indicatorColor: AppTheme.primaryColor,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: _destinations,
            ),
    );
  }
}

/// Custom Navigation Rail Item with hover effect
class _NavRailItem extends StatefulWidget {
  final Widget icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavRailItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavRailItem> createState() => _NavRailItemState();
}

class _NavRailItemState extends State<_NavRailItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.primaryColor
                : _isHovered
                ? AppTheme.sidebarHover
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: widget.isSelected || _isHovered
                      ? Colors.white
                      : AppTheme.slate400,
                  size: 22,
                ),
                child: widget.icon,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: widget.isSelected || _isHovered
                      ? Colors.white
                      : AppTheme.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashboard Content
class DashboardContent extends StatelessWidget {
  final ValueChanged<int>? onNavigate;

  const DashboardContent({super.key, this.onNavigate});

  void _navigateTo(int index) {
    onNavigate?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.companyProfile?.companyName ?? 'BillEase Accounts+'),
            if (app.companyProfile?.gstin != null)
              Text(
                'GSTIN: ${app.companyProfile!.gstin}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          // Connection status
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  app.isServerConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: app.isServerConnected
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  app.isServerConnected ? 'Connected' : 'Offline',
                  style: TextStyle(
                    color: app.isServerConnected
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _QuickActionCard(
                  icon: Icons.add_shopping_cart,
                  label: 'New Sale',
                  color: AppTheme.primaryColor,
                  onTap: () => _navigateTo(1),
                ),
                _QuickActionCard(
                  icon: Icons.shopping_bag_outlined,
                  label: 'New Purchase',
                  color: AppTheme.secondaryColor,
                  onTap: () => _navigateTo(2),
                ),
                _QuickActionCard(
                  icon: Icons.person_add,
                  label: 'Add Party',
                  color: AppTheme.accentColor,
                  onTap: () => _navigateTo(5),
                ),
                _QuickActionCard(
                  icon: Icons.inventory,
                  label: 'Add Item',
                  color: Colors.purple,
                  onTap: () => _navigateTo(4),
                ),
                _QuickActionCard(
                  icon: Icons.payments,
                  label: 'Payment In',
                  color: AppTheme.successColor,
                  onTap: () => _navigateTo(6),
                ),
                _QuickActionCard(
                  icon: Icons.account_balance_wallet,
                  label: 'Payment Out',
                  color: AppTheme.errorColor,
                  onTap: () => _navigateTo(6),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Summary Cards
            Text(
              'Today\'s Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Sales',
                    value: '₹0.00',
                    subtitle: '0 invoices',
                    icon: Icons.trending_up,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Purchases',
                    value: '₹0.00',
                    subtitle: '0 bills',
                    icon: Icons.trending_down,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Cash',
                    value: '₹0.00',
                    subtitle: 'In hand',
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Receivables',
                    value: '₹0.00',
                    subtitle: '0 pending',
                    icon: Icons.receipt_long,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Recent Activity
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activity',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _navigateTo(1),
                        child: const Text('Create First Invoice'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '$title - Coming Soon',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
