import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/individual_dashboard.dart';
import '../widgets/family_dashboard.dart';
import '../widgets/business_dashboard.dart';
import '../screens/quick_expense_screen.dart';
import '../screens/quick_income_screen.dart';
import '../screens/adaptive_budget_screen.dart';
import '../providers/account_provider.dart';
import '../models/account_type.dart';
import '../core/modern_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().loadAccountType();
    });
  }

  Widget _getAdaptiveDashboard(AccountType accountType) {
    switch (accountType) {
      case AccountType.individual:
        return const IndividualDashboard();
      case AccountType.family:
        return const FamilyDashboard();
      case AccountType.business:
        return const BusinessDashboard();
    }
  }

  List<Widget> _getScreens(AccountType accountType) {
    return [
      _getAdaptiveDashboard(accountType),
      const Center(child: Text('Analytics')),
      const AdaptiveBudgetScreen(),
      _buildSettingsScreen(),
    ];
  }

  Widget _buildSettingsScreen() {
    return Consumer<AccountProvider>(
      builder: (context, accountProvider, _) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  color: ModernColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Account Type',
                style: TextStyle(
                  fontSize: 16,
                  color: ModernColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...AccountType.values.map((type) {
                final isSelected = type == accountProvider.accountType;
                return GestureDetector(
                  onTap: () async {
                    await accountProvider.setAccountType(type);
                    setState(() {
                      _selectedIndex = 0; // Go back to dashboard
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ModernColors.primary.withOpacity(0.1)
                          : ModernColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? ModernColors.primary
                            : ModernColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          type == AccountType.individual
                              ? Icons.person_rounded
                              : type == AccountType.family
                                  ? Icons.people_rounded
                                  : Icons.business_rounded,
                          color: isSelected
                              ? ModernColors.primary
                              : ModernColors.textSecondary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.displayName,
                                style: TextStyle(
                                  color: isSelected
                                      ? ModernColors.primary
                                      : ModernColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type.description,
                                style: TextStyle(
                                  color: ModernColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: ModernColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, accountProvider, _) {
        final screens = _getScreens(accountProvider.accountType);
        
        return Scaffold(
          backgroundColor: ModernColors.background,
          body: SafeArea(
            child: screens[_selectedIndex],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showAddTransactionSheet(context, accountProvider.accountType);
            },
            backgroundColor: ModernColors.primary,
            child: const Icon(Icons.add_rounded, size: 28),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            color: ModernColors.surface,
            elevation: 0,
            notchMargin: 8,
            shape: const CircularNotchedRectangle(),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Home', 0),
                  _buildNavItem(Icons.pie_chart_rounded, 'Analytics', 1),
                  const SizedBox(width: 40), // Space for FAB
                  _buildNavItem(Icons.wallet_rounded, 'Budgets', 2),
                  _buildNavItem(Icons.settings_rounded, 'Settings', 3),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? ModernColors.primary : ModernColors.textTertiary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? ModernColors.primary : ModernColors.textTertiary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context, AccountType accountType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: ModernColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ModernColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Transaction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ModernColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildTransactionOption(
                    context: context,
                    icon: Icons.arrow_downward_rounded,
                    label: 'Expense',
                    subtitle: 'Record spending',
                    color: const Color(0xFFEF5350),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuickExpenseScreen(
                            accountType: accountType,
                            onSaved: () => setState(() {}),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTransactionOption(
                    context: context,
                    icon: Icons.arrow_upward_rounded,
                    label: 'Income',
                    subtitle: 'Record earnings',
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuickIncomeScreen(
                            accountType: accountType,
                            onSaved: () => setState(() {}),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ModernColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: ModernColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
