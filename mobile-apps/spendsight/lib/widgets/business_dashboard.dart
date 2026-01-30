import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/modern_colors.dart';
import '../providers/transaction_provider.dart';

class BusinessDashboard extends StatelessWidget {
  const BusinessDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final cashBalance = provider.balance;
        final todayIncome = _getTodayIncome(provider);
        final todayExpense = _getTodayExpense(provider);

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
                    _buildCashBalanceCard(cashBalance)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTodayIncomeCard(todayIncome)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 100.ms)
                              .slideX(begin: -0.2, end: 0),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTodayExpenseCard(todayExpense)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 200.ms)
                              .slideX(begin: 0.2, end: 0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildCashFlowChart(provider)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms)
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Recent Transactions'),
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
                color: ModernColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business_rounded, size: 16, color: ModernColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Business Account',
                    style: TextStyle(
                      color: ModernColors.success,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('MMM dd, yyyy').format(DateTime.now()),
              style: TextStyle(
                color: ModernColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Cash Flow Overview',
          style: TextStyle(
            fontSize: 28,
            color: ModernColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCashBalanceCard(double balance) {
    final isPositive = balance >= 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [
                  ModernColors.success.withOpacity(0.9),
                  ModernColors.success,
                ]
              : [
                  ModernColors.error.withOpacity(0.9),
                  ModernColors.error,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? ModernColors.success : ModernColors.error)
                .withOpacity(0.3),
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
                child: Icon(
                  isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Current Cash Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayIncomeCard(double income) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.success.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ModernColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: ModernColors.success,
                  size: 20,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_upward_rounded,
                color: ModernColors.success,
                size: 16,
              ),
              Text(
                '12%',
                style: TextStyle(
                  color: ModernColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Today Income',
            style: TextStyle(
              color: ModernColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${income.toStringAsFixed(2)}',
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayExpenseCard(double expense) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.error.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ModernColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: ModernColors.error,
                  size: 20,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_downward_rounded,
                color: ModernColors.error,
                size: 16,
              ),
              Text(
                '8%',
                style: TextStyle(
                  color: ModernColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Today Expense',
            style: TextStyle(
              color: ModernColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${expense.toStringAsFixed(2)}',
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowChart(TransactionProvider provider) {
    // Mock 7-day data - in real app, calculate from transactions
    final last7Days = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return {
        'day': DateFormat('EEE').format(date),
        'income': (i * 200 + 300).toDouble(),
        'expense': (i * 150 + 200).toDouble(),
      };
    });

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Cash Flow',
                style: TextStyle(
                  color: ModernColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem('Income', ModernColors.success),
                  const SizedBox(width: 16),
                  _buildLegendItem('Expense', ModernColors.error),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 200,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: ModernColors.border,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= last7Days.length) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            last7Days[value.toInt()]['day'] as String,
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
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Income line
                  LineChartBarData(
                    spots: last7Days.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['income'] as double,
                      );
                    }).toList(),
                    isCurved: true,
                    color: ModernColors.success,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: ModernColors.success,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: ModernColors.success.withOpacity(0.1),
                    ),
                  ),
                  // Expense line
                  LineChartBarData(
                    spots: last7Days.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['expense'] as double,
                      );
                    }).toList(),
                    isCurved: true,
                    color: ModernColors.error,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: ModernColors.error,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: ModernColors.error.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: ModernColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
              'No business transactions yet',
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
          return _buildTransactionTile(transaction);
        },
        childCount: recentTransactions.length,
      ),
    );
  }

  Widget _buildTransactionTile(transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: transaction.isExpense
              ? ModernColors.error.withOpacity(0.2)
              : ModernColors.success.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (transaction.isExpense
                      ? ModernColors.error
                      : ModernColors.success)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              transaction.isExpense
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: transaction.isExpense
                  ? ModernColors.error
                  : ModernColors.success,
              size: 24,
            ),
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
                      DateFormat('HH:mm').format(transaction.date),
                      style: TextStyle(
                        color: ModernColors.textTertiary,
                        fontSize: 13,
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
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  double _getTodayIncome(TransactionProvider provider) {
    final today = DateTime.now();
    return provider.transactions
        .where((t) =>
            !t.isExpense &&
            t.date.year == today.year &&
            t.date.month == today.month &&
            t.date.day == today.day)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double _getTodayExpense(TransactionProvider provider) {
    final today = DateTime.now();
    return provider.transactions
        .where((t) =>
            t.isExpense &&
            t.date.year == today.year &&
            t.date.month == today.month &&
            t.date.day == today.day)
        .fold(0, (sum, t) => sum + t.amount);
  }
}
