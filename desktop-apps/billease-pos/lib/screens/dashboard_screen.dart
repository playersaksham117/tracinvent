import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

class KPIData {
  final String title;
  final double value;
  final double changePercent;
  final IconData icon;
  final Color iconColor;

  const KPIData({
    required this.title,
    required this.value,
    required this.changePercent,
    required this.icon,
    required this.iconColor,
  });
}

class SalesDataPoint {
  final String label;
  final double value;

  const SalesDataPoint({required this.label, required this.value});
}

class TopSellingItem {
  final String name;
  final double amount;
  final int unitsSold;

  const TopSellingItem({
    required this.name,
    required this.amount,
    required this.unitsSold,
  });
}

// ============================================================================
// COLOR PALETTE - Clean Enterprise Theme
// ============================================================================

class _DashboardColors {
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const primary = Color(0xFF3B82F6);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFDCFCE7);
  static const successDark = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const errorLight = Color(0xFFFEE2E2);
  static const errorDark = Color(0xFFDC2626);
  static const purple = Color(0xFF8B5CF6);
  static const pink = Color(0xFFEC4899);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFF1F5F9);
}

// ============================================================================
// MAIN DASHBOARD SCREEN
// ============================================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'This Week';

  // KPI Data
  double _totalRevenue = 0;
  double _revenueChange = 0;
  int _ordersToday = 0;
  double _ordersChange = 0;
  double _avgOrderValue = 0;
  double _avgChange = 0;
  int _activeCustomers = 0;
  double _customersChange = 0;

  // Chart Data
  List<SalesDataPoint> _salesData = [];

  // Top Selling
  List<TopSellingItem> _topSelling = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final lastWeekStart = weekStart.subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month, 1);

      DateTime periodStart;
      DateTime compareStart;
      DateTime compareEnd;

      switch (_selectedPeriod) {
        case 'Today':
          periodStart = todayStart;
          compareStart = todayStart.subtract(const Duration(days: 1));
          compareEnd = todayStart;
          break;
        case 'This Month':
          periodStart = monthStart;
          compareStart = DateTime(now.year, now.month - 1, 1);
          compareEnd = monthStart;
          break;
        default:
          periodStart = weekStart;
          compareStart = lastWeekStart;
          compareEnd = weekStart;
      }

      // Total Revenue
      final revenueResult = await db.rawQuery('''
        SELECT COALESCE(SUM(total_amount), 0) as total 
        FROM sales 
        WHERE datetime(created_at) >= datetime(?)
      ''', [periodStart.toIso8601String()]);
      _totalRevenue = (revenueResult.first['total'] as num?)?.toDouble() ?? 0;

      final lastRevenueResult = await db.rawQuery('''
        SELECT COALESCE(SUM(total_amount), 0) as total 
        FROM sales 
        WHERE datetime(created_at) >= datetime(?) AND datetime(created_at) < datetime(?)
      ''', [compareStart.toIso8601String(), compareEnd.toIso8601String()]);
      final lastRevenue = (lastRevenueResult.first['total'] as num?)?.toDouble() ?? 0;
      _revenueChange = lastRevenue > 0 ? ((_totalRevenue - lastRevenue) / lastRevenue * 100) : 0;

      // Orders Today
      final ordersResult = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM sales 
        WHERE datetime(created_at) >= datetime(?)
      ''', [todayStart.toIso8601String()]);
      _ordersToday = (ordersResult.first['count'] as int?) ?? 0;

      final yesterdayStart = todayStart.subtract(const Duration(days: 1));
      final lastOrdersResult = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM sales 
        WHERE datetime(created_at) >= datetime(?) AND datetime(created_at) < datetime(?)
      ''', [yesterdayStart.toIso8601String(), todayStart.toIso8601String()]);
      final lastOrders = (lastOrdersResult.first['count'] as int?) ?? 0;
      _ordersChange = lastOrders > 0 ? ((_ordersToday - lastOrders) / lastOrders * 100) : 0;

      // Average Order Value
      final avgResult = await db.rawQuery('''
        SELECT COALESCE(AVG(total_amount), 0) as avg_value 
        FROM sales 
        WHERE datetime(created_at) >= datetime(?)
      ''', [periodStart.toIso8601String()]);
      _avgOrderValue = (avgResult.first['avg_value'] as num?)?.toDouble() ?? 0;

      final lastAvgResult = await db.rawQuery('''
        SELECT COALESCE(AVG(total_amount), 0) as avg_value 
        FROM sales 
        WHERE datetime(created_at) >= datetime(?) AND datetime(created_at) < datetime(?)
      ''', [compareStart.toIso8601String(), compareEnd.toIso8601String()]);
      final lastAvg = (lastAvgResult.first['avg_value'] as num?)?.toDouble() ?? 0;
      _avgChange = lastAvg > 0 ? ((_avgOrderValue - lastAvg) / lastAvg * 100) : 0;

      // Active Customers
      final customersResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT customer_name) as count 
        FROM sales 
        WHERE datetime(created_at) >= datetime(?) AND customer_name IS NOT NULL AND customer_name != ''
      ''', [periodStart.toIso8601String()]);
      _activeCustomers = (customersResult.first['count'] as int?) ?? 0;

      final lastCustomersResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT customer_name) as count 
        FROM sales 
        WHERE datetime(created_at) >= datetime(?) AND datetime(created_at) < datetime(?)
          AND customer_name IS NOT NULL AND customer_name != ''
      ''', [compareStart.toIso8601String(), compareEnd.toIso8601String()]);
      final lastCustomers = (lastCustomersResult.first['count'] as int?) ?? 0;
      _customersChange = lastCustomers > 0 ? ((_activeCustomers - lastCustomers) / lastCustomers * 100) : 0;

      _salesData = await _loadSalesChartData(db);
      _topSelling = await _loadTopSellingProducts(db, periodStart);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      _loadMockData();
    }

    setState(() => _isLoading = false);
  }

  Future<List<SalesDataPoint>> _loadSalesChartData(dynamic db) async {
    final List<SalesDataPoint> data = [];
    final now = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(total_amount), 0) as total 
        FROM sales 
        WHERE datetime(created_at) >= datetime(?) AND datetime(created_at) < datetime(?)
      ''', [dayStart.toIso8601String(), dayEnd.toIso8601String()]);

      final total = (result.first['total'] as num?)?.toDouble() ?? 0;
      data.add(SalesDataPoint(label: dayNames[date.weekday - 1], value: total));
    }

    return data;
  }

  Future<List<TopSellingItem>> _loadTopSellingProducts(dynamic db, DateTime periodStart) async {
    final List<TopSellingItem> items = [];

    try {
      final result = await db.rawQuery('''
        SELECT 
          si.product_name,
          SUM(si.quantity) as total_qty,
          SUM(si.total_amount) as total_amount
        FROM sale_items si
        INNER JOIN sales s ON si.sale_id = s.id
        WHERE datetime(s.created_at) >= datetime(?)
        GROUP BY si.product_name
        ORDER BY total_amount DESC
        LIMIT 5
      ''', [periodStart.toIso8601String()]);

      for (final row in result) {
        items.add(TopSellingItem(
          name: row['product_name'] as String? ?? 'Unknown Product',
          amount: (row['total_amount'] as num?)?.toDouble() ?? 0,
          unitsSold: (row['total_qty'] as num?)?.toInt() ?? 0,
        ));
      }
    } catch (e) {
      debugPrint('Error loading top selling: $e');
    }

    return items;
  }

  void _loadMockData() {
    _totalRevenue = 124500;
    _revenueChange = 12.5;
    _ordersToday = 156;
    _ordersChange = 8.2;
    _avgOrderValue = 798.40;
    _avgChange = -2.1;
    _activeCustomers = 2847;
    _customersChange = 5.7;

    _salesData = const [
      SalesDataPoint(label: 'Mon', value: 12400),
      SalesDataPoint(label: 'Tue', value: 18200),
      SalesDataPoint(label: 'Wed', value: 15800),
      SalesDataPoint(label: 'Thu', value: 22400),
      SalesDataPoint(label: 'Fri', value: 28600),
      SalesDataPoint(label: 'Sat', value: 32100),
      SalesDataPoint(label: 'Sun', value: 24500),
    ];

    _topSelling = const [
      TopSellingItem(name: 'Premium Basmati Rice', amount: 45600, unitsSold: 32),
      TopSellingItem(name: 'Organic Wheat Flour', amount: 38200, unitsSold: 28),
      TopSellingItem(name: 'Pure Desi Ghee', amount: 32800, unitsSold: 15),
      TopSellingItem(name: 'Refined Sunflower Oil', amount: 24500, unitsSold: 67),
      TopSellingItem(name: 'Toor Dal Premium', amount: 18900, unitsSold: 12),
    ];
  }

  List<KPIData> get _kpis => [
    KPIData(
      title: 'Total Revenue',
      value: _totalRevenue,
      changePercent: _revenueChange,
      icon: Icons.currency_rupee_rounded,
      iconColor: _DashboardColors.primary,
    ),
    KPIData(
      title: 'Orders Today',
      value: _ordersToday.toDouble(),
      changePercent: _ordersChange,
      icon: Icons.shopping_bag_outlined,
      iconColor: _DashboardColors.success,
    ),
    KPIData(
      title: 'Avg. Order Value',
      value: _avgOrderValue,
      changePercent: _avgChange,
      icon: Icons.analytics_outlined,
      iconColor: _DashboardColors.warning,
    ),
    KPIData(
      title: 'Active Customers',
      value: _activeCustomers.toDouble(),
      changePercent: _customersChange,
      icon: Icons.people_outline_rounded,
      iconColor: _DashboardColors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DashboardColors.background,
      body: _isLoading ? _buildLoadingState() : _buildDashboard(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: _DashboardColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _DashboardColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive breakpoints
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 800 && constraints.maxWidth < 1200;
        final isMobile = constraints.maxWidth < 800;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _DashboardHeader(
                selectedPeriod: _selectedPeriod,
                onPeriodChanged: (period) {
                  setState(() => _selectedPeriod = period);
                  _loadDashboardData();
                },
                onRefresh: _loadDashboardData,
              ),
              const SizedBox(height: 24),

              // KPI Cards - Using Wrap for natural flow
              _KPICardsSection(
                kpis: _kpis,
                isDesktop: isDesktop,
                isTablet: isTablet,
              ),
              const SizedBox(height: 24),

              // Main Content Area
              _buildMainContent(isDesktop, isTablet, isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(bool isDesktop, bool isTablet, bool isMobile) {
    // Calculate trend for chart header
    double totalChange = 0;
    if (_salesData.length >= 2) {
      final recent = _salesData.sublist(_salesData.length - 3).map((e) => e.value).fold(0.0, (a, b) => a + b);
      final earlier = _salesData.sublist(0, 3).map((e) => e.value).fold(0.0, (a, b) => a + b);
      totalChange = earlier > 0 ? ((recent - earlier) / earlier * 100) : 0;
    }

    if (isDesktop) {
      // Side by side layout - use CrossAxisAlignment.stretch to match heights
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _RevenueChartCard(
              salesData: _salesData,
              trendChange: totalChange,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: _TopSellingCard(items: _topSelling),
          ),
        ],
      );
    } else {
      // Stacked layout for tablet/mobile
      return Column(
        children: [
          _RevenueChartCard(
            salesData: _salesData,
            trendChange: totalChange,
          ),
          const SizedBox(height: 24),
          _TopSellingCard(items: _topSelling),
        ],
      );
    }
  }
}

// ============================================================================
// DASHBOARD HEADER WIDGET
// ============================================================================

class _DashboardHeader extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onRefresh;

  const _DashboardHeader({
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildPeriodSelector()),
                  const SizedBox(width: 12),
                  _buildRefreshButton(),
                ],
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTitle(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRefreshButton(),
                const SizedBox(width: 12),
                _buildPeriodSelector(),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sales Dashboard',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _DashboardColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track your business performance',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _DashboardColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return _CardContainer(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: onRefresh,
        borderRadius: BorderRadius.circular(8),
        child: const Icon(
          Icons.refresh_rounded,
          size: 20,
          color: _DashboardColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return _CardContainer(
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Today', 'This Week', 'This Month'].map((period) {
          final isSelected = selectedPeriod == period;
          return GestureDetector(
            onTap: () => onPeriodChanged(period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _DashboardColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                period,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : _DashboardColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// KPI CARDS SECTION - Using Wrap for responsive flow
// ============================================================================

class _KPICardsSection extends StatelessWidget {
  final List<KPIData> kpis;
  final bool isDesktop;
  final bool isTablet;

  const _KPICardsSection({
    required this.kpis,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate card width based on available space
        final cardWidth = isDesktop
            ? (constraints.maxWidth - 60) / 4 // 4 cards with 3 gaps of 20px
            : isTablet
                ? (constraints.maxWidth - 20) / 2 // 2 cards with 1 gap
                : constraints.maxWidth; // Full width for mobile

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: kpis.map((kpi) {
            return SizedBox(
              width: cardWidth,
              child: _MetricCard(data: kpi),
            );
          }).toList(),
        );
      },
    );
  }
}

// ============================================================================
// METRIC CARD WIDGET - No fixed height, content-driven
// ============================================================================

class _MetricCard extends StatelessWidget {
  final KPIData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: data.value >= 1000 ? 0 : 2,
    );

    final isPositive = data.changePercent >= 0;
    final isCurrency = data.title.contains('Revenue') ||
        data.title.contains('Value') ||
        data.title.contains('Amount');
    final formattedValue = isCurrency
        ? currencyFormat.format(data.value)
        : NumberFormat.compact().format(data.value);

    return _CardContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // CRITICAL: Content-driven height
        children: [
          // Header Row: Title + Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _DashboardColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, size: 20, color: data.iconColor),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Big Value
          Text(
            formattedValue,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _DashboardColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Trend Pill
          _TrendPill(
            changePercent: data.changePercent,
            isPositive: isPositive,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TREND PILL WIDGET
// ============================================================================

class _TrendPill extends StatelessWidget {
  final double changePercent;
  final bool isPositive;

  const _TrendPill({
    required this.changePercent,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPositive ? _DashboardColors.successLight : _DashboardColors.errorLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: isPositive ? _DashboardColors.successDark : _DashboardColors.errorDark,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPositive ? _DashboardColors.successDark : _DashboardColors.errorDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REVENUE CHART CARD
// ============================================================================

class _RevenueChartCard extends StatelessWidget {
  final List<SalesDataPoint> salesData;
  final double trendChange;

  const _RevenueChartCard({
    required this.salesData,
    required this.trendChange,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Overview',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last 7 days performance',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _DashboardColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _TrendPill(
                changePercent: trendChange,
                isPositive: trendChange >= 0,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Chart with fixed height instead of AspectRatio for more control
          SizedBox(
            height: 280,
            child: _SalesLineChart(data: salesData),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SALES LINE CHART WIDGET
// ============================================================================

class _SalesLineChart extends StatefulWidget {
  final List<SalesDataPoint> data;

  const _SalesLineChart({required this.data});

  @override
  State<_SalesLineChart> createState() => _SalesLineChartState();
}

class _SalesLineChartState extends State<_SalesLineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty || widget.data.every((e) => e.value == 0)) {
      return _buildEmptyState();
    }

    final maxY = widget.data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final roundedMaxY = maxY == 0 ? 10000.0 : ((maxY / 10000).ceil() * 10000).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (widget.data.length - 1).toDouble(),
        minY: 0,
        maxY: roundedMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: roundedMaxY / 4,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: _DashboardColors.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: roundedMaxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '₹${NumberFormat.compact().format(value)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _DashboardColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= widget.data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.data[index].label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _DashboardColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => _DashboardColors.textPrimary,
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(spot.y),
                  GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                );
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
              setState(() => _touchedIndex = response.lineBarSpots!.first.spotIndex);
            } else {
              setState(() => _touchedIndex = null);
            }
          },
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: widget.data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: _DashboardColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isTouched = index == _touchedIndex;
                return FlDotCirclePainter(
                  radius: isTouched ? 6 : 4,
                  color: Colors.white,
                  strokeWidth: isTouched ? 3 : 2,
                  strokeColor: _DashboardColors.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _DashboardColors.primary.withValues(alpha: 0.3),
                  _DashboardColors.primary.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _DashboardColors.divider,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: _DashboardColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No sales data available',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _DashboardColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sales will appear here once recorded',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _DashboardColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TOP SELLING CARD
// ============================================================================

class _TopSellingCard extends StatelessWidget {
  final List<TopSellingItem> items;

  const _TopSellingCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Selling',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _DashboardColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/products'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _DashboardColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List or Empty State
          if (items.isEmpty || (items.length == 1 && items.first.amount == 0))
            _buildEmptyState()
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TopSellingListItem(item: item, rank: index + 1),
                    if (index < items.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: _DashboardColors.divider),
                      ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _DashboardColors.divider,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: _DashboardColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No products sold yet',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _DashboardColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start selling to see top products',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _DashboardColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TOP SELLING LIST ITEM
// ============================================================================

class _TopSellingListItem extends StatelessWidget {
  final TopSellingItem item;
  final int rank;

  const _TopSellingListItem({required this.item, required this.rank});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    
    final avatarColors = [
      _DashboardColors.primary,
      _DashboardColors.success,
      _DashboardColors.warning,
      _DashboardColors.purple,
      _DashboardColors.pink,
    ];
    final avatarColor = avatarColors[(rank - 1) % avatarColors.length];

    return Row(
      children: [
        // Rank Badge
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: rank <= 3 ? _DashboardColors.warningLight : _DashboardColors.divider,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: rank <= 3 ? _DashboardColors.warning : _DashboardColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Product Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: avatarColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              item.name.isNotEmpty ? item.name.substring(0, 1).toUpperCase() : '?',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: avatarColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Product Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _DashboardColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${item.unitsSold} units sold',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _DashboardColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        // Amount
        Text(
          currencyFormat.format(item.amount),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _DashboardColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CARD CONTAINER - Reusable card wrapper (no shadows, subtle border)
// ============================================================================

class _CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CardContainer({
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _DashboardColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DashboardColors.border),
      ),
      child: child,
    );
  }
}
