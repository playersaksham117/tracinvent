/// Unified Payments & Statements Screen
/// Combined module for payment ledger management and party statements
/// Two main tabs: Payments and Statements - each with full independent functionality
library;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'payments_ledger_screen.dart';
import 'statements_screen.dart';

class PaymentsStatementsScreen extends StatefulWidget {
  const PaymentsStatementsScreen({super.key});

  @override
  State<PaymentsStatementsScreen> createState() =>
      _PaymentsStatementsScreenState();
}

class _PaymentsStatementsScreenState extends State<PaymentsStatementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Statements'),
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.slate500,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.account_balance_wallet),
                  text: 'Payments',
                ),
                Tab(
                  icon: Icon(Icons.description),
                  text: 'Statements',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Payments Tab - Full PaymentsLedgerScreen
          PaymentsLedgerScreen(),
          // Statements Tab - Full StatementsScreen
          StatementsScreen(),
        ],
      ),
    );
  }
}
