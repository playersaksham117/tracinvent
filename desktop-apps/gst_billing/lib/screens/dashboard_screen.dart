/// Modern Dashboard Screen - Command Center
/// BillEase Accounts+ - Clean Corporate Design
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Dashboard Data Models
class DashboardStats {
  final double todaySales;
  final double todayProfit;
  final int lowStockCount;
  final int pendingOrders;
  final double salesChange;
  final double profitChange;

  DashboardStats({
    required this.todaySales,
    required this.todayProfit,
    required this.lowStockCount,
    required this.pendingOrders,
    this.salesChange = 0,
    this.profitChange = 0,
  });
}

class GSTData {
  final double taxLiability;
  final double inputCredit;

  const GSTData({
    required this.taxLiability,
    required this.inputCredit,
  });
}

class SalesDataPoint {
  final DateTime date;
  final double amount;

  SalesDataPoint({required this.date, required this.amount});
}

class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime timestamp;

  ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.timestamp,
  });
}

/// Main Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardStats> _statsFuture;
  late Future<List<SalesDataPoint>> _chartFuture;
  late Future<List<ActivityItem>> _activityFuture;
  late Future<GSTData> _gstDataFuture;
  late final ApiService _api;
  String _selectedChartPeriod = '7 Days';

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _loadData();
  }

  void _loadData() {
    _statsFuture = _fetchDashboardStats();
    _chartFuture = _fetchSalesHistory(days: _chartPeriodDays);
    _activityFuture = _fetchRecentActivity();
    _gstDataFuture = _fetchGSTData();
  }

  int get _chartPeriodDays {
    switch (_selectedChartPeriod) {
      case '30 Days':
        return 30;
      case '90 Days':
        return 90;
      case '7 Days':
      default:
        return 7;
    }
  }

  /// Fetch dashboard stats from Python backend
  Future<DashboardStats> _fetchDashboardStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      // Sales for today and yesterday
      final todaySummary = await _api.getSalesSummary(today, today);
      final yesterdaySummary = await _api.getSalesSummary(yesterday, yesterday);

      final todaySales = (todaySummary['total_sales'] as num?)?.toDouble() ?? 0;
      final yesterdaySales =
          (yesterdaySummary['total_sales'] as num?)?.toDouble() ?? 0;

      // Approximate profit as taxable amount minus purchase (if available)
      final todayTaxable =
          (todaySummary['taxable_amount'] as num?)?.toDouble() ?? 0;
      final todayPurchase =
          (todaySummary['purchase_amount'] as num?)?.toDouble() ?? 0;
      final todayProfit = todayTaxable - todayPurchase;

      // Low stock count
      final lowStock = await _api.getStockSummary(lowStockOnly: true);

      // Pending invoices = outstanding invoices
      final outstanding = await _api.getOutstandingInvoices();

      final salesChange = yesterdaySales > 0
          ? ((todaySales - yesterdaySales) / yesterdaySales) * 100
          : 0;

      // Profit change (simple day-on-day % based on taxable)
      final yesterdayTaxable =
          (yesterdaySummary['taxable_amount'] as num?)?.toDouble() ?? 0;
      final yesterdayPurchase =
          (yesterdaySummary['purchase_amount'] as num?)?.toDouble() ?? 0;
      final yesterdayProfit = yesterdayTaxable - yesterdayPurchase;
      final profitChange = yesterdayProfit.abs() > 0
          ? ((todayProfit - yesterdayProfit) / yesterdayProfit.abs()) * 100
          : 0;

      return DashboardStats(
        todaySales: todaySales,
        todayProfit: todayProfit,
        lowStockCount: lowStock.length,
        pendingOrders: outstanding.length,
        salesChange: salesChange.toDouble(),
        profitChange: profitChange.toDouble(),
      );
    } catch (e) {
      _showErrorToast(
        'Unable to load dashboard stats. Please check connection.',
      );
      rethrow;
    }
  }

  /// Fetch sales history for chart from Python backend
  Future<List<SalesDataPoint>> _fetchSalesHistory({int days = 7}) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Last N days (including today)
      final points = <SalesDataPoint>[];
      for (int i = days - 1; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        final summary = await _api.getSalesSummary(day, day);
        final amount = (summary['total_sales'] as num?)?.toDouble() ?? 0;
        points.add(SalesDataPoint(date: day, amount: amount));
      }
      return points;
    } catch (e) {
      _showErrorToast('Unable to load sales chart. Please check connection.');
      rethrow;
    }
  }

  /// Fetch recent activity from Python backend
  Future<List<ActivityItem>> _fetchRecentActivity() async {
    try {
      final invoices = await _api.getInvoices(
        status: 'CONFIRMED',
        page: 1,
        pageSize: 5,
      );

      return invoices.map((inv) {
        final amount = inv.grandTotal;
        final party = inv.partyName;
        return ActivityItem(
          id: (inv.id ?? '').toString(),
          title: 'Invoice #${inv.invoiceNumber ?? inv.id ?? ''}',
          subtitle: amount > 0
              ? '₹${amount.toStringAsFixed(2)} from $party'
              : 'For $party',
          icon: Icons.receipt_long,
          color: AppTheme.primaryColor,
          timestamp: inv.invoiceDate,
        );
      }).toList();
    } catch (e) {
      _showErrorToast('Unable to load activity feed. Please check connection.');
      rethrow;
    }
  }

  /// Fetch GST summary data from Python backend (current month)
  Future<GSTData> _fetchGSTData() async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      final gstSummary = await _api.getGSTSummary(firstDayOfMonth, lastDayOfMonth);

      final taxLiability = (gstSummary['tax_liability'] as num?)?.toDouble() ?? 0;
      final inputCredit = (gstSummary['input_credit'] as num?)?.toDouble() ?? 0;

      return GSTData(
        taxLiability: taxLiability,
        inputCredit: inputCredit,
      );
    } catch (e) {
      debugPrint('Error fetching GST data: $e');
      // Return zero values if API fails instead of crashing
      return const GSTData(taxLiability: 0, inputCredit: 0);
    }
  }

  void _showErrorToast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _loadData());
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive: Switch from 4 to 2 columns on narrow screens
            final isWide = constraints.maxWidth > 1200;
            final isMedium = constraints.maxWidth > 800;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions Bar
                  _buildQuickActions(),
                  const SizedBox(height: 32),

                  // GST Bento Overview Cards
                  _buildGSTBentoCards(isWide, isMedium),

                  const SizedBox(height: 24),

                  // Glance Cards Row
                  _buildGlanceCardsSection(isWide, isMedium),

                  const SizedBox(height: 24),

                  // Chart + Activity Row
                  if (isWide) _buildWideLayout() else _buildNarrowLayout(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard'),
          Text(
            _getGreeting(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: AppTheme.slate500,
            ),
          ),
        ],
      ),
      actions: [
        // Refresh Button
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Data',
          onPressed: () => setState(() => _loadData()),
        ),
        const SizedBox(width: 8),
        // Search Bar (Pill-shaped)
        Container(
          width: 280,
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search invoices, parties...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppTheme.slate100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  Widget _buildQuickActions() {
    final actions = [
      {'label': 'New Sale', 'icon': Icons.point_of_sale, 'color': AppTheme.primaryColor},
      {'label': 'New Purchase', 'icon': Icons.shopping_cart, 'color': AppTheme.successColor},
      {'label': 'Add Party', 'icon': Icons.person_add, 'color': AppTheme.accentColor},
      {'label': 'Add Item', 'icon': Icons.add_box, 'color': AppTheme.warningColor},
    ];

    return Row(
      children: actions.map((action) {
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // Navigation to be implemented in respective routes
                // E.g., context.read<AppProvider>().navigateTo(...)
              },
              hoverColor: (action['color'] as Color).withOpacity(0.05),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.slate200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      action['label'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// GST Bento Overview - Tax Liability & Input Credit Cards
  Widget _buildGSTBentoCards(bool isWide, bool isMedium) {
    return FutureBuilder<GSTData>(
      future: _gstDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGSTCards(isWide, isMedium);
        }

        final gstData = snapshot.data ?? const GSTData(taxLiability: 0, inputCredit: 0);
        final taxLiability = gstData.taxLiability;
        final inputCredit = gstData.inputCredit;
        final netPosition = taxLiability - inputCredit;

        final cards = [
          // Tax Liability Card - Orange/Red accent (you owe)
          _GSTBentoCard(
            title: 'Tax Liability',
            subtitle: 'GST you owe',
            value: taxLiability,
            icon: Icons.trending_up,
            color: AppTheme.accentColor, // Orange for liability
            bgColor: const Color(0xFFFFF7ED), // Orange shade 50
          ),
          // Input Credit Card - Green accent (owed to you)
          _GSTBentoCard(
            title: 'Input Credit',
            subtitle: 'GST owed to you',
            value: inputCredit,
            icon: Icons.trending_down,
            color: AppTheme.creditText, // Green
            bgColor: AppTheme.creditBg, // Green shade 50
          ),
          // Net Position Card - Blue accent
          _GSTBentoCard(
            title: 'Net Position',
            subtitle: netPosition >= 0 ? 'Amount to pay' : 'Refund due',
            value: netPosition.abs(),
            icon: netPosition >= 0 ? Icons.payment : Icons.account_balance,
            color: AppTheme.primaryColor, // Blue
            bgColor: AppTheme.primaryLight, // Blue shade 50
            isNetPosition: true,
            netPositive: netPosition >= 0,
          ),
        ];

        if (isWide || isMedium) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
              const SizedBox(width: 16),
              Expanded(child: cards[2]),
            ],
          );
        } else {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: card,
                  ),
                )
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildLoadingGSTCards(bool isWide, bool isMedium) {
    final loadingCard = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(24),
      child: const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    if (isWide || isMedium) {
      return Row(
        children: [
          Expanded(child: loadingCard),
          const SizedBox(width: 16),
          Expanded(child: loadingCard),
          const SizedBox(width: 16),
          Expanded(child: loadingCard),
        ],
      );
    } else {
      return Column(
        children: [
          loadingCard,
          const SizedBox(height: 16),
          loadingCard,
          const SizedBox(height: 16),
          loadingCard,
        ],
      );
    }
  }

  Widget _buildGlanceCardsSection(bool isWide, bool isMedium) {
    return FutureBuilder<DashboardStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCards(isWide ? 4 : (isMedium ? 2 : 1));
        }

        if (snapshot.hasError) {
          return _buildErrorCard('Failed to load statistics');
        }

        final stats = snapshot.data!;
        final cards = [
          _GlanceCard(
            title: 'Today\'s Sales',
            value: stats.todaySales.toCurrencyString(),
            change: stats.salesChange,
            icon: Icons.trending_up,
            iconColor: AppTheme.primaryColor,
            iconBgColor: AppTheme.primaryLight,
          ),
          _GlanceCard(
            title: 'Today\'s Profit',
            value: stats.todayProfit.toCurrencyString(),
            change: stats.profitChange,
            icon: Icons.account_balance_wallet,
            iconColor: AppTheme.successColor,
            iconBgColor: AppTheme.successLight,
          ),
          _GlanceCard(
            title: 'Low Stock Items',
            value: stats.lowStockCount.toString(),
            subtitle: 'Items need reorder',
            icon: Icons.inventory_2,
            iconColor: AppTheme.warningColor,
            iconBgColor: AppTheme.warningLight,
            isWarning: stats.lowStockCount > 10,
          ),
          _GlanceCard(
            title: 'Pending Orders',
            value: stats.pendingOrders.toString(),
            subtitle: 'Awaiting fulfillment',
            icon: Icons.pending_actions,
            iconColor: AppTheme.accentColor,
            iconBgColor: AppTheme.accentLight,
          ),
        ];

        // Responsive grid
        if (isWide) {
          return Row(
            children:
                cards
                    .map(
                      (card) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: card,
                        ),
                      ),
                    )
                    .toList()
                  ..last = Expanded(child: cards.last),
          );
        } else if (isMedium) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: card,
                  ),
                )
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildLoadingCards(int count) {
    return Row(
      children: List.generate(
        count,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < count - 1 ? 16 : 0),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.errorLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor),
          const SizedBox(width: 12),
          Text(message, style: const TextStyle(color: AppTheme.errorColor)),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _loadData()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sales Chart (2/3 width)
        Expanded(flex: 2, child: _buildSalesChartCard()),
        const SizedBox(width: 24),
        // Activity Feed (1/3 width)
        Expanded(flex: 1, child: _buildActivityFeedCard()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildSalesChartCard(),
        const SizedBox(height: 24),
        _buildActivityFeedCard(),
      ],
    );
  }

  Widget _buildSalesChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.slate200.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate800,
                ),
              ),
              // Period Selector
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.slate100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<String>(
                  value: _selectedChartPeriod,
                  underline: const SizedBox(),
                  isDense: true,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.slate600,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '7 Days',
                      child: Text('Last 7 Days'),
                    ),
                    DropdownMenuItem(
                      value: '30 Days',
                      child: Text('Last 30 Days'),
                    ),
                    DropdownMenuItem(
                      value: '90 Days',
                      child: Text('Last 90 Days'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedChartPeriod = value;
                      _chartFuture = _fetchSalesHistory(days: _chartPeriodDays);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: FutureBuilder<List<SalesDataPoint>>(
              future: _chartFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.slate400,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load chart',
                          style: TextStyle(color: AppTheme.slate500),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _chartFuture = _fetchSalesHistory(
                              days: _chartPeriodDays,
                            );
                          }),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return _SalesLineChart(data: snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.slate200.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate800,
                ),
              ),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('All Activity'),
                      content: SizedBox(
                        width: 520,
                        child: FutureBuilder<List<ActivityItem>>(
                          future: _activityFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return const Text(
                                'Unable to load activity right now.',
                              );
                            }
                            final items = snapshot.data ?? [];
                            if (items.isEmpty) {
                              return const Text('No activity found.');
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return ListTile(
                                  leading: Icon(item.icon, color: item.color),
                                  title: Text(item.title),
                                  subtitle: Text(item.subtitle),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<ActivityItem>>(
            future: _activityFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.slate400),
                      const SizedBox(height: 8),
                      const Text(
                        'Failed to load',
                        style: TextStyle(color: AppTheme.slate500),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _activityFuture = _fetchRecentActivity();
                        }),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: snapshot.data!
                    .map((item) => _ActivityListItem(item: item))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// GST Bento Card Widget - For Tax Liability & Input Credit
class _GSTBentoCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final double value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isNetPosition;
  final bool netPositive;

  const _GSTBentoCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.isNetPosition = false,
    this.netPositive = true,
  });

  @override
  State<_GSTBentoCard> createState() => _GSTBentoCardState();
}

class _GSTBentoCardState extends State<_GSTBentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isNetPosition ? widget.color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.isNetPosition
                ? Colors.transparent
                : AppTheme.slate200.withOpacity(_isHovered ? 0 : 1),
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: widget.color.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon and badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isNetPosition
                        ? Colors.white.withOpacity(0.2)
                        : widget.bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.isNetPosition ? Colors.white : widget.color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                if (widget.isNetPosition)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.netPositive
                          ? Colors.white.withOpacity(0.2)
                          : Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.netPositive
                              ? Icons.arrow_outward
                              : Icons.call_received,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.netPositive ? 'PAYABLE' : 'CLAIMABLE',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Title label
            Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: widget.isNetPosition
                    ? Colors.white.withOpacity(0.9)
                    : AppTheme.slate500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            // Amount with FittedBox to prevent overflow
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                widget.value.toCurrencyString(),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: widget.isNetPosition ? Colors.white : widget.color,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            Text(
              widget.subtitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: widget.isNetPosition
                    ? Colors.white.withOpacity(0.7)
                    : AppTheme.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glance Card Widget - Big Text Left, Icon Right
class _GlanceCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final double? change;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isWarning;

  const _GlanceCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.change,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.isWarning = false,
  });

  @override
  State<_GlanceCard> createState() => _GlanceCardState();
}

class _GlanceCardState extends State<_GlanceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: widget.iconColor.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
          border: widget.isWarning
              ? Border.all(
                  color: AppTheme.warningColor.withOpacity(0.5),
                  width: 2,
                )
              : Border.all(
                  color: AppTheme.slate200.withOpacity(_isHovered ? 0 : 0.5),
                ),
        ),
        child: Row(
          children: [
            // Left: Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.slate500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.value,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (widget.change != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.change! >= 0
                                ? AppTheme.successLight
                                : AppTheme.errorLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.change! >= 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 12,
                                color: widget.change! >= 0
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${widget.change!.abs().toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: widget.change! >= 0
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'vs yesterday',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.slate400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.subtitle != null && widget.change == null) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.slate400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Right: Icon
            AnimatedScale(
              scale: _isHovered ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sales Line Chart Widget using fl_chart
class _SalesLineChart extends StatelessWidget {
  final List<SalesDataPoint> data;

  const _SalesLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No sales data available'));
    }

    final maxY = data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    final minY = data.map((d) => d.amount).reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;

    // Avoid zero-range issues when all points are equal (or zero)
    final padding = range == 0 ? (maxY == 0 ? 1 : maxY * 0.1) : range * 0.1;
    final horizontalInterval = range == 0
        ? (maxY == 0 ? 1.0 : (maxY / 4).clamp(1.0, double.infinity))
        : (range / 4).clamp(1e-6, double.infinity);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: horizontalInterval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppTheme.slate200,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '₹${(value / 1000).toStringAsFixed(0)}K',
                    style: const TextStyle(
                      color: AppTheme.slate400,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                        color: AppTheme.slate400,
                        fontSize: 11,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppTheme.slate800,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '₹${spot.y.toCurrencyString(symbol: '')}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i].amount),
            ),
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppTheme.primaryColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.2),
                  AppTheme.primaryColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Activity List Item Widget
class _ActivityListItem extends StatefulWidget {
  final ActivityItem item;

  const _ActivityListItem({required this.item});

  @override
  State<_ActivityListItem> createState() => _ActivityListItemState();
}

class _ActivityListItemState extends State<_ActivityListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.slate100 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.item.icon, color: widget.item.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.slate800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.item.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.slate500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatTime(widget.item.timestamp),
              style: const TextStyle(fontSize: 11, color: AppTheme.slate400),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
