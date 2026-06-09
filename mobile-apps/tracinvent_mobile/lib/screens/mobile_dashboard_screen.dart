import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/warehouse_provider.dart';

/// Phone-friendly dashboard: scrollable KPIs, compact chart, alerts, recent moves.
class MobileDashboardScreen extends StatelessWidget {
  const MobileDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<InventoryProvider, WarehouseProvider>(
      builder: (context, inventoryProvider, warehouseProvider, _) {
        final totalItems = inventoryProvider.items.length;
        final lowStock = inventoryProvider.lowStockItems.length;
        final critical = inventoryProvider.criticalStockItems.length;
        final whCount = warehouseProvider.activeWarehouses.length;
        double value = 0;
        for (final item in inventoryProvider.items) {
          value += inventoryProvider.getTotalStock(item.id) * item.costPrice;
        }
        final fmt = NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN');

        return ColoredBox(
          color: const Color(0xFFF8FAFC),
          child: RefreshIndicator(
            onRefresh: () async {
              await inventoryProvider.loadInventoryItems();
              await warehouseProvider.loadWarehouses();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeroSyncCard(
                  title: 'Today\'s overview',
                  subtitle: 'Track stock movement, alerts and recent activity.',
                  onInventoryTap: () => context.read<NavigationProvider>().goToInventory(),
                  onTransactionsTap: () => context.read<NavigationProvider>().goToStockInOut(),
                  onAdjustmentsTap: () => context.read<NavigationProvider>().goToAdjustments(),
                ),
                const SizedBox(height: 14),
                _sectionTitle(context, 'Overview'),
                const SizedBox(height: 10),
                _kpiGrid([
                  _Kpi('Items', '$totalItems', Icons.inventory_2_outlined, const Color(0xFF3B82F6)),
                  _Kpi('Value', fmt.format(value), Icons.currency_rupee, const Color(0xFF8B5CF6)),
                  _Kpi('Low', '$lowStock', Icons.trending_down, const Color(0xFFF59E0B)),
                  _Kpi('Critical', '$critical', Icons.warning_amber_rounded, const Color(0xFFEF4444)),
                  _Kpi('Sites', '$whCount', Icons.warehouse_outlined, const Color(0xFF10B981)),
                ]),
                const SizedBox(height: 20),
                _sectionTitle(context, 'Movement (7 days)'),
                const SizedBox(height: 8),
                _SurfaceCard(
                  child: SizedBox(height: 200, child: _MiniBarChart(inventoryProvider: inventoryProvider)),
                ),
                const SizedBox(height: 20),
                _sectionTitle(context, 'Alerts'),
                const SizedBox(height: 8),
                if (inventoryProvider.items.isEmpty)
                  const _LoadingSkeletonList(rows: 3)
                else
                  _AlertsList(inventoryProvider: inventoryProvider),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle(context, 'Recent activity'),
                    TextButton(
                      onPressed: () => context.read<NavigationProvider>().goToStockInOut(),
                      child: const Text('Open'),
                    ),
                  ],
                ),
                if (inventoryProvider.transactions.isEmpty && inventoryProvider.items.isEmpty)
                  const _LoadingSkeletonList(rows: 4)
                else
                  _RecentList(inventoryProvider: inventoryProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
    );
  }

  Widget _kpiGrid(List<_Kpi> items) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: items.map((k) => _KpiCard(k)).toList(),
    );
  }
}

class _Kpi {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  _Kpi(this.title, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _Kpi k;
  const _KpiCard(this.k);

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: k.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(k.icon, color: k.color, size: 18),
          ),
          const Spacer(),
          Text(k.title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(
            k.value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HeroSyncCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onInventoryTap;
  final VoidCallback onTransactionsTap;
  final VoidCallback onAdjustmentsTap;

  const _HeroSyncCard({
    required this.title,
    required this.subtitle,
    required this.onInventoryTap,
    required this.onTransactionsTap,
    required this.onAdjustmentsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFDBEAFE),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickChip('Inventory', Icons.inventory_2_outlined, onInventoryTap),
              _quickChip('Stock In/Out', Icons.swap_horiz, onTransactionsTap),
              _quickChip('Adjustments', Icons.tune, onAdjustmentsTap),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSkeletonList extends StatelessWidget {
  final int rows;
  const _LoadingSkeletonList({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows, (index) {
        return Container(
          height: 62,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
        );
      }),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final InventoryProvider inventoryProvider;
  const _MiniBarChart({required this.inventoryProvider});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final incoming = <int, double>{for (var i = 0; i < 7; i++) i: 0};
    final outgoing = <int, double>{for (var i = 0; i < 7; i++) i: 0};
    for (final t in inventoryProvider.transactions) {
      final d = now.difference(t.transactionDate).inDays;
      if (d < 7) {
        final idx = 6 - d;
        if (t.type == 'purchase') {
          incoming[idx] = (incoming[idx] ?? 0) + t.quantity;
        } else if (t.type == 'sale') {
          outgoing[idx] = (outgoing[idx] ?? 0) + t.quantity;
        }
      }
    }
    double maxY = 10;
    for (final v in [...incoming.values, ...outgoing.values]) {
      if (v > maxY) maxY = v;
    }
    maxY *= 1.2;
    if (maxY < 10) maxY = 10;

    if (inventoryProvider.transactions.isEmpty) {
      return Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey.shade500)));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                final date = now.subtract(Duration(days: 6 - v.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, m) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: incoming[i] ?? 0, color: const Color(0xFF10B981), width: 8),
              BarChartRodData(toY: outgoing[i] ?? 0, color: const Color(0xFFEF4444), width: 8),
            ],
          );
        }),
      ),
    );
  }
}

class _AlertsList extends StatelessWidget {
  final InventoryProvider inventoryProvider;
  const _AlertsList({required this.inventoryProvider});

  @override
  Widget build(BuildContext context) {
    final critical = inventoryProvider.criticalStockItems;
    final low = inventoryProvider.lowStockItems;
    final alerts = [...critical, ...low.where((e) => !critical.contains(e))];
    if (alerts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: Text('Stock levels OK', style: TextStyle(color: Colors.grey.shade600))),
        ),
      );
    }
    return Column(
      children: alerts.take(8).map((item) {
        final stock = inventoryProvider.getTotalStock(item.id);
        final isCrit = critical.contains(item);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.warning_amber_rounded, color: isCrit ? Colors.red : Colors.orange),
            title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('SKU ${item.sku}'),
            trailing: Text(
              stock.toStringAsFixed(0),
              style: TextStyle(fontWeight: FontWeight.w700, color: isCrit ? Colors.red : Colors.orange),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RecentList extends StatelessWidget {
  final InventoryProvider inventoryProvider;
  const _RecentList({required this.inventoryProvider});

  @override
  Widget build(BuildContext context) {
    final recent = inventoryProvider.transactions.take(8).toList();
    if (recent.isEmpty) {
      return Text('No transactions', style: TextStyle(color: Colors.grey.shade500));
    }
    return Column(
      children: recent.map((t) {
        InventoryItem item;
        try {
          item = inventoryProvider.items.firstWhere((i) => i.id == t.itemId);
        } catch (_) {
          item = inventoryProvider.items.isNotEmpty
              ? inventoryProvider.items.first
              : InventoryItem(
                  id: '',
                  name: 'Unknown',
                  sku: '',
                  category: '',
                  unit: '',
                  reorderLevel: 0,
                  minStockLevel: 0,
                  costPrice: 0,
                  sellingPrice: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${t.type} · ${DateFormat.MMMd().format(t.transactionDate)}'),
            trailing: Text('${t.quantity.toStringAsFixed(0)} ${item.unit}'),
          ),
        );
      }).toList(),
    );
  }
}
