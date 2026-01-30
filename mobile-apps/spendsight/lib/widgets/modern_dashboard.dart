import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/modern_colors.dart';
import '../providers/transaction_provider.dart';
import '../models/models.dart';

class ModernDashboard extends StatefulWidget {
  const ModernDashboard({super.key});

  @override
  State<ModernDashboard> createState() => _ModernDashboardState();
}

class _ModernDashboardState extends State<ModernDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildBalanceCard(provider),
                    const SizedBox(height: 24),
                    _buildQuickStats(provider),
                    const SizedBox(height: 24),
                    _buildSpendingChart(provider),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Recent Transactions'),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: provider.transactions.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptyState(),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final transaction = provider.transactions[index];
                          return _buildTransactionTile(transaction, provider);
                        },
                        childCount: provider.transactions.length > 10
                            ? 10
                            : provider.transactions.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good ${_getGreeting()}!',
          style: TextStyle(
            fontSize: 16,
            color: ModernColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your Financial Overview',
          style: TextStyle(
            fontSize: 28,
            color: ModernColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildBalanceCard(TransactionProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: ModernColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ModernColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${provider.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'Income',
                  provider.currentMonthIncome,
                  ModernColors.success,
                  Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBalanceItem(
                  'Expense',
                  provider.currentMonthExpense,
                  ModernColors.error,
                  Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(TransactionProvider provider) {
    final categoryExpenses = provider.getCategoryExpenses();
    final topCategories = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Transactions',
            '${provider.currentMonthTransactions.length}',
            Icons.receipt_long_rounded,
            ModernColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Top Category',
            topCategories.isNotEmpty ? topCategories.first.key : 'None',
            Icons.category_rounded,
            ModernColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: ModernColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(TransactionProvider provider) {
    final categoryExpenses = provider.getCategoryExpenses();
    
    if (categoryExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: categoryExpenses.values.reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final categories = categoryExpenses.keys.toList();
                        if (value.toInt() >= categories.length) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            categories[value.toInt()].substring(0, 3),
                            style: TextStyle(
                              color: ModernColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: ModernColors.border,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: categoryExpenses.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final categoryEntry = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: categoryEntry.value,
                        gradient: LinearGradient(
                          colors: [
                            ModernColors.primary.withOpacity(0.8),
                            ModernColors.primary,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 24,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: ModernColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'See All',
            style: TextStyle(
              color: ModernColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(
    Transaction transaction,
    TransactionProvider provider,
  ) {
    final color = _getCategoryColor(transaction.category);
    final icon = _getCategoryIcon(transaction.category);

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: ModernColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) {
        provider.deleteTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            backgroundColor: ModernColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ModernColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ModernColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: TextStyle(
                      color: ModernColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        transaction.category,
                        style: TextStyle(
                          color: ModernColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: ModernColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd').format(transaction.date),
                        style: TextStyle(
                          color: ModernColors.textTertiary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${transaction.isExpense ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: transaction.isExpense
                    ? ModernColors.error
                    : ModernColors.success,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ModernColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: ModernColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Transactions Yet',
              style: TextStyle(
                color: ModernColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your expenses and income\nby adding your first transaction',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ModernColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return ModernColors.food;
      case 'transport':
        return ModernColors.transport;
      case 'shopping':
        return ModernColors.shopping;
      case 'bills':
        return ModernColors.bills;
      case 'health':
        return ModernColors.health;
      case 'entertainment':
        return ModernColors.entertainment;
      case 'salary':
        return ModernColors.salary;
      case 'freelance':
        return ModernColors.freelance;
      default:
        return ModernColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_rounded;
      case 'health':
        return Icons.health_and_safety_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'salary':
        return Icons.attach_money_rounded;
      case 'freelance':
        return Icons.work_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
