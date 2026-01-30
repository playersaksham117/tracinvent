import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/modern_colors.dart';
import '../providers/transaction_provider.dart';

class FamilyDashboard extends StatelessWidget {
  const FamilyDashboard({super.key});

  // Mock family members - in real app, get from database
  final List<String> members = const ['Dad', 'Mom', 'John', 'Sarah'];

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final householdSpend = provider.currentMonthExpense;
        final sharedBudget = 5000.0;
        final budgetUsed = (householdSpend / sharedBudget * 100).clamp(0.0, 100.0);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildHouseholdSpendCard(householdSpend)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 16),
                    if (budgetUsed > 80)
                      _buildBudgetAlert(budgetUsed)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .shake(duration: 600.ms),
                    const SizedBox(height: 24),
                    _buildMemberWiseChart()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Family Activity'),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _buildTransactionsList(provider),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ModernColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_rounded, size: 16, color: ModernColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Family Account',
                    style: TextStyle(
                      color: ModernColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Household Overview',
          style: TextStyle(
            fontSize: 28,
            color: ModernColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildHouseholdSpendCard(double spend) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ModernColors.accent.withOpacity(0.9),
            ModernColors.accent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ModernColors.accent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'This Month',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Total Household Spending',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${spend.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: members.map((member) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    member[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetAlert(double percentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.warning, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ModernColors.warning,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Alert!',
                  style: TextStyle(
                    color: ModernColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'ve used ${percentage.toInt()}% of your shared budget',
                  style: TextStyle(
                    color: ModernColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberWiseChart() {
    // Mock data - in real app, calculate from transactions with member field
    final memberSpending = {
      'Dad': 450.0,
      'Mom': 380.0,
      'John': 120.0,
      'Sarah': 90.0,
    };

    final maxSpend = memberSpending.values.reduce((a, b) => a > b ? a : b);

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
            'Member-wise Spending',
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxSpend * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final members = memberSpending.keys.toList();
                        if (value.toInt() >= members.length) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            members[value.toInt()],
                            style: TextStyle(
                              color: ModernColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
                barGroups: memberSpending.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final memberEntry = entry.value;
                  
                  final colors = [
                    ModernColors.primary,
                    ModernColors.accent,
                    ModernColors.success,
                    ModernColors.warning,
                  ];

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: memberEntry.value,
                        gradient: LinearGradient(
                          colors: [
                            colors[index % colors.length].withOpacity(0.7),
                            colors[index % colors.length],
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 32,
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
    return Text(
      title,
      style: TextStyle(
        color: ModernColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTransactionsList(TransactionProvider provider) {
    if (provider.transactions.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              'No family transactions yet',
              style: TextStyle(
                color: ModernColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    final recentTransactions = provider.transactions.take(5).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = recentTransactions[index];
          // In real app, show member avatar from transaction.member field
          final memberInitial = members[index % members.length][0];
          return _buildTransactionTile(transaction, memberInitial);
        },
        childCount: recentTransactions.length,
      ),
    );
  }

  Widget _buildTransactionTile(transaction, String memberInitial) {
    final color = _getCategoryColor(transaction.category);
    final icon = _getCategoryIcon(transaction.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.border, width: 1),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: ModernColors.primary,
                  child: Text(
                    memberInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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
                Text(
                  transaction.category,
                  style: TextStyle(
                    color: ModernColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
      default:
        return Icons.category_rounded;
    }
  }
}
