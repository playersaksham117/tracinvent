import 'package:flutter/material.dart';
import '../widgets/overview_tab.dart';
import 'budgets_screen.dart';
import 'analytics_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const OverviewTab(),
    const BudgetsScreen(),
    const AnalyticsScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  void _onFabPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(isExpense: true),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _onFabPressed,
              icon: const Icon(Icons.add),
              label: const Text('Expense'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.wallet_outlined),
            selectedIcon: Icon(Icons.wallet),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
