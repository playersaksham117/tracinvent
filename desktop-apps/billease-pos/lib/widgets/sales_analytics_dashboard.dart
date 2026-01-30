import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
  final String imageUrl;
  final double amount;
  final int unitsSold;

  const TopSellingItem({
    required this.name,
    required this.imageUrl,
    required this.amount,
    required this.unitsSold,
  });
}

// ============================================================================
// MOCK DATA PROVIDER
// ============================================================================

class MockDashboardData {
  static List<KPIData> getKPIs() => const [
        KPIData(
          title: 'Total Revenue',
          value: 124500,
          changePercent: 12.5,
          icon: Icons.currency_rupee_rounded,
          iconColor: Color(0xFF3B82F6),
        ),
        KPIData(
          title: 'Orders Today',
          value: 156,
          changePercent: 8.2,
          icon: Icons.shopping_bag_outlined,
          iconColor: Color(0xFF10B981),
        ),
        KPIData(
          title: 'Avg. Order Value',
          value: 798.40,
          changePercent: -2.1,
          icon: Icons.analytics_outlined,
          iconColor: Color(0xFFF59E0B),
        ),
        KPIData(
          title: 'Active Customers',
          value: 2847,
          changePercent: 5.7,
          icon: Icons.people_outline_rounded,
          iconColor: Color(0xFF8B5CF6),
        ),
      ];

  static List<SalesDataPoint> getSalesData() => const [
        SalesDataPoint(label: 'Mon', value: 12400),
        SalesDataPoint(label: 'Tue', value: 18200),
        SalesDataPoint(label: 'Wed', value: 15800),
        SalesDataPoint(label: 'Thu', value: 22400),
        SalesDataPoint(label: 'Fri', value: 28600),
        SalesDataPoint(label: 'Sat', value: 32100),
        SalesDataPoint(label: 'Sun', value: 24500),
      ];

  static List<TopSellingItem> getTopSelling() => const [
        TopSellingItem(
          name: 'iPhone 15 Pro Max',
          imageUrl: 'https://via.placeholder.com/48',
          amount: 45600,
          unitsSold: 32,
        ),
        TopSellingItem(
          name: 'Samsung Galaxy S24',
          imageUrl: 'https://via.placeholder.com/48',
          amount: 38200,
          unitsSold: 28,
        ),
        TopSellingItem(
          name: 'MacBook Air M3',
          imageUrl: 'https://via.placeholder.com/48',
          amount: 32800,
          unitsSold: 15,
        ),
        TopSellingItem(
          name: 'AirPods Pro 2',
          imageUrl: 'https://via.placeholder.com/48',
          amount: 24500,
          unitsSold: 67,
        ),
        TopSellingItem(
          name: 'iPad Pro 12.9"',
          imageUrl: 'https://via.placeholder.com/48',
          amount: 18900,
          unitsSold: 12,
        ),
      ];
}

// ============================================================================
// MAIN DASHBOARD WIDGET
// ============================================================================

class SalesAnalyticsDashboard extends StatefulWidget {
  const SalesAnalyticsDashboard({super.key});

  @override
  State<SalesAnalyticsDashboard> createState() => _SalesAnalyticsDashboardState();
}

class _SalesAnalyticsDashboardState extends State<SalesAnalyticsDashboard> {
  final List<KPIData> _kpis = MockDashboardData.getKPIs();
  final List<SalesDataPoint> _salesData = MockDashboardData.getSalesData();
  final List<TopSellingItem> _topSelling = MockDashboardData.getTopSelling();
  String _selectedPeriod = 'This Week';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1100;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // KPI Cards Row
              _buildKPISection(constraints),
              const SizedBox(height: 24),

              // Main Content: Chart + Top Selling
              if (isWide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 2, child: _buildMainChartSection()),
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: _buildTopSellingSection()),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    _buildMainChartSection(),
                    const SizedBox(height: 24),
                    _buildTopSellingSection(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Analytics',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your business performance',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        _buildPeriodSelector(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return _buildCardContainer(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Today', 'This Week', 'This Month'].map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                period,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKPISection(BoxConstraints constraints) {
    final crossAxisCount = constraints.maxWidth > 1200
        ? 4
        : constraints.maxWidth > 800
            ? 2
            : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: crossAxisCount == 1 ? 3.5 : 2.2,
      ),
      itemCount: _kpis.length,
      itemBuilder: (context, index) => KPICard(data: _kpis[index]),
    );
  }

  Widget _buildMainChartSection() {
    return _buildCardContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Overview',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily sales performance',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+18.2% vs last week',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 280,
            child: SalesLineChart(data: _salesData),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingSection() {
    return _buildCardContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Selling',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _topSelling.length,
              separatorBuilder: (_, __) => const Divider(
                height: 24,
                color: Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, index) {
                final item = _topSelling[index];
                return TopSellingListItem(item: item, rank: index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({
    required Widget child,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================================
// KPI CARD WIDGET
// ============================================================================

class KPICard extends StatelessWidget {
  final KPIData data;

  const KPICard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: data.value >= 1000 ? 0 : 2,
    );

    final isPositive = data.changePercent >= 0;
    final formattedValue = data.title.contains('Revenue') ||
            data.title.contains('Value') ||
            data.title.contains('Amount')
        ? currencyFormat.format(data.value)
        : NumberFormat.compact().format(data.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  data.icon,
                  size: 20,
                  color: data.iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formattedValue,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          _TrendIndicator(
            changePercent: data.changePercent,
            isPositive: isPositive,
          ),
        ],
      ),
    );
  }
}

class _TrendIndicator extends StatelessWidget {
  final double changePercent;
  final bool isPositive;

  const _TrendIndicator({
    required this.changePercent,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 14,
            color: isPositive
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPositive
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SALES LINE CHART WIDGET
// ============================================================================

class SalesLineChart extends StatefulWidget {
  final List<SalesDataPoint> data;

  const SalesLineChart({super.key, required this.data});

  @override
  State<SalesLineChart> createState() => _SalesLineChartState();
}

class _SalesLineChartState extends State<SalesLineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final maxY = widget.data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final roundedMaxY = ((maxY / 10000).ceil() * 10000).toDouble();

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
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFFF1F5F9),
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
                    color: const Color(0xFF94A3B8),
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
                      color: const Color(0xFF94A3B8),
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
            getTooltipColor: (spot) => const Color(0xFF1E293B),
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final currencyFormat = NumberFormat.currency(
                  locale: 'en_IN',
                  symbol: '₹',
                  decimalDigits: 0,
                );
                return LineTooltipItem(
                  currencyFormat.format(spot.y),
                  GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
              setState(() {
                _touchedIndex = response.lineBarSpots!.first.spotIndex;
              });
            } else {
              setState(() {
                _touchedIndex = null;
              });
            }
          },
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: widget.data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF3B82F6),
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
                  strokeColor: const Color(0xFF3B82F6),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.3),
                  const Color(0xFF3B82F6).withOpacity(0.05),
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
}

// ============================================================================
// TOP SELLING LIST ITEM WIDGET
// ============================================================================

class TopSellingListItem extends StatelessWidget {
  final TopSellingItem item;
  final int rank;

  const TopSellingListItem({
    super.key,
    required this.item,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // Generate colors based on rank
    final avatarColors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    final avatarColor = avatarColors[(rank - 1) % avatarColors.length];

    return Row(
      children: [
        // Rank Badge
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: rank <= 3
                ? const Color(0xFFFEF3C7)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: rank <= 3
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Product Avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: avatarColor.withOpacity(0.15),
          child: Text(
            item.name.substring(0, 1).toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: avatarColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Product Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${item.unitsSold} units sold',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
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
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
