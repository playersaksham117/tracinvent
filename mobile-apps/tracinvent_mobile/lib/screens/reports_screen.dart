import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/inventory_provider.dart';
import '../providers/warehouse_provider.dart';
import '../providers/settings_provider.dart';
import '../services/pdf_service.dart';
import '../services/excel_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReportType = 'stock_valuation';
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer3<InventoryProvider, WarehouseProvider, SettingsProvider>(
      builder: (context, inventoryProvider, warehouseProvider, settingsProvider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Column(
            children: [
              _buildTopBar(context, inventoryProvider, settingsProvider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReportTypeSelector(),
                      const SizedBox(height: 24),
                      _buildReportContent(inventoryProvider, warehouseProvider, settingsProvider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, InventoryProvider inventoryProvider, SettingsProvider settingsProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assessment_outlined,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports & Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Generate and export inventory reports',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _isExporting ? null : () => _exportToExcel(inventoryProvider, settingsProvider),
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.table_chart, size: 18),
            label: const Text('Export to Excel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF10B981)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _isExporting ? null : () => _exportToPDF(inventoryProvider, settingsProvider),
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Export to PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildReportTypeButton('stock_valuation', 'Stock Valuation', Icons.inventory_2_outlined),
          _buildReportTypeButton('low_stock', 'Low Stock', Icons.warning_amber_rounded),
          _buildReportTypeButton('transactions', 'Transactions', Icons.receipt_long_outlined),
          _buildReportTypeButton('warehouse', 'By Warehouse', Icons.warehouse_outlined),
        ],
      ),
    );
  }

  Widget _buildReportTypeButton(String type, String label, IconData icon) {
    final isSelected = _selectedReportType == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilledButton.icon(
        onPressed: () {
          setState(() {
            _selectedReportType = type;
          });
        },
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : const Color(0xFF64748B),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildReportContent(InventoryProvider inventoryProvider, WarehouseProvider warehouseProvider, SettingsProvider settingsProvider) {
    switch (_selectedReportType) {
      case 'stock_valuation':
        return _buildStockValuationReport(inventoryProvider, settingsProvider);
      case 'low_stock':
        return _buildLowStockReport(inventoryProvider);
      case 'transactions':
        return _buildTransactionsReport(inventoryProvider, settingsProvider);
      case 'warehouse':
        return _buildWarehouseReport(inventoryProvider, warehouseProvider);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStockValuationReport(InventoryProvider inventoryProvider, SettingsProvider settingsProvider) {
    final items = inventoryProvider.items;
    final stocks = inventoryProvider.stocks;

    double totalValue = 0;
    for (var item in items) {
      final itemStocks = stocks.where((s) => s.itemId == item.id);
      final totalQty = itemStocks.fold<double>(0, (sum, s) => sum + s.quantity);
      totalValue += totalQty * item.costPrice;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Total Items', items.length.toString(), Icons.inventory_2, const Color(0xFF3B82F6))),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard('Total Stock Units', stocks.fold<double>(0, (sum, s) => sum + s.quantity).toStringAsFixed(0), Icons.widgets, const Color(0xFF8B5CF6))),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard('Total Value', settingsProvider.formatCurrency(totalValue, compact: true), Icons.currency_rupee, const Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 24),

        // Stock Table
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.table_chart, color: Color(0xFF64748B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Stock Valuation Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'No inventory items found',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Item Name')),
                      DataColumn(label: Text('SKU')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Stock Qty')),
                      DataColumn(label: Text('Unit Price')),
                      DataColumn(label: Text('Total Value')),
                    ],
                    rows: items.map((item) {
                      final itemStocks = stocks.where((s) => s.itemId == item.id);
                      final totalQty = itemStocks.fold<double>(0, (sum, s) => sum + s.quantity);
                      final value = totalQty * item.costPrice;

                      return DataRow(cells: [
                        DataCell(Text(item.name)),
                        DataCell(Text(item.sku)),
                        DataCell(Text(item.category)),
                        DataCell(Text(totalQty.toStringAsFixed(0))),
                        DataCell(Text(settingsProvider.formatCurrency(item.costPrice))),
                        DataCell(Text(settingsProvider.formatCurrency(value))),
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockReport(InventoryProvider inventoryProvider) {
    final lowStockItems = inventoryProvider.lowStockItems;
    final criticalStockItems = inventoryProvider.criticalStockItems;
    final allAlertItems = [...criticalStockItems, ...lowStockItems];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Low Stock Alert',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${criticalStockItems.length} Critical',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${lowStockItems.length} Low',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (allAlertItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'All stock levels are healthy!',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            ...allAlertItems.map((item) {
              final stock = inventoryProvider.getTotalStock(item.id);
              final isCritical = criticalStockItems.contains(item);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCritical ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
                      color: isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'SKU: ${item.sku} | Current: ${stock.toInt()} ${item.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCritical ? 'CRITICAL' : 'LOW STOCK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTransactionsReport(InventoryProvider inventoryProvider, SettingsProvider settingsProvider) {
    final transactions = inventoryProvider.transactions.take(50).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: Color(0xFF64748B), size: 20),
              SizedBox(width: 8),
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No transactions found',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('Quantity')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Notes')),
                ],
                rows: transactions.map((trans) {
                  final item = inventoryProvider.items.firstWhere(
                    (i) => i.id == trans.itemId,
                    orElse: () => inventoryProvider.items.first,
                  );

                  return DataRow(cells: [
                    DataCell(Text(trans.transactionDate.toString().substring(0, 10))),
                    DataCell(Text(trans.type)),
                    DataCell(Text(item.name)),
                    DataCell(Text(trans.quantity.toStringAsFixed(0))),
                    DataCell(Text(settingsProvider.formatCurrency(trans.totalAmount))),
                    DataCell(Text(trans.notes ?? '-')),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWarehouseReport(InventoryProvider inventoryProvider, WarehouseProvider warehouseProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warehouse_outlined, color: Color(0xFF64748B), size: 20),
              SizedBox(width: 8),
              Text(
                'Warehouse Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...warehouseProvider.warehouses.map((warehouse) {
            final warehouseStocks = inventoryProvider.stocks.where((s) => s.warehouseId == warehouse.id);
            final totalUnits = warehouseStocks.fold<double>(0, (sum, s) => sum + s.quantity);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warehouse, color: Color(0xFF3B82F6)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warehouse.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          warehouse.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        totalUnits.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      Text(
                        'Units',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF(InventoryProvider inventoryProvider, SettingsProvider settingsProvider) async {
    setState(() => _isExporting = true);

    try {
      await PDFService.generateStockReport(
        items: inventoryProvider.items,
        stocks: inventoryProvider.stocks,
        currencySymbol: settingsProvider.currency.symbol,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF report generated successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportToExcel(InventoryProvider inventoryProvider, SettingsProvider settingsProvider) async {
    setState(() => _isExporting = true);

    try {
      final filePath = await ExcelService.generateStockReport(
        items: inventoryProvider.items,
        stocks: inventoryProvider.stocks,
        currencySymbol: settingsProvider.currency.symbol,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel report saved to: $filePath'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                // Open file location
                if (Platform.isWindows) {
                  Process.run('explorer', ['/select,', filePath]);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating Excel: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
