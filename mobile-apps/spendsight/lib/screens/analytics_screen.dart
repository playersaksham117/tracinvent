import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0;
  final List<String> _periods = ['Week', 'Month', 'Year'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text(
            'Analytics',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Period Selector
              Card(
                color: colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: List.generate(_periods.length, (index) {
                      final isSelected = _selectedPeriod == index;
                      return Expanded(
                        child: Material(
                          color: isSelected ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPeriod = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              child: Text(
                                _periods[index],
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected 
                                      ? colorScheme.onPrimary 
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Total Spending Card
              Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Spent',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$1,143.50',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.trending_down,
                            color: Colors.green[700],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '12% less than last month',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onErrorContainer.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Spending by Category
              Text(
                'Spending by Category',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 250,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: [
                              PieChartSectionData(
                                value: 385,
                                title: '\$385',
                                color: Colors.orange,
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              PieChartSectionData(
                                value: 250,
                                title: '\$250',
                                color: Colors.purple,
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              PieChartSectionData(
                                value: 180,
                                title: '\$180',
                                color: Colors.blue,
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              PieChartSectionData(
                                value: 328,
                                title: '\$328',
                                color: Colors.red,
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _CategoryLegend(
                        items: [
                          _LegendItem('Food', Colors.orange, 385),
                          _LegendItem('Shopping', Colors.purple, 250),
                          _LegendItem('Transport', Colors.blue, 180),
                          _LegendItem('Bills', Colors.red, 328),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Trends
              Text(
                'Spending Trends',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
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
                                  color: colorScheme.surfaceVariant,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                    if (value.toInt() >= 0 && value.toInt() < months.length) {
                                      return Text(
                                        months[value.toInt()],
                                        style: Theme.of(context).textTheme.bodySmall,
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [
                                  FlSpot(0, 800),
                                  FlSpot(1, 950),
                                  FlSpot(2, 750),
                                  FlSpot(3, 1100),
                                  FlSpot(4, 900),
                                  FlSpot(5, 1143),
                                ],
                                isCurved: true,
                                color: colorScheme.primary,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: colorScheme.primary.withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  final List<_LegendItem> items;

  const _CategoryLegend({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '\$${item.value.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  final double value;

  _LegendItem(this.label, this.color, this.value);
}
