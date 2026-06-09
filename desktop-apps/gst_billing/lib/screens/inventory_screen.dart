/// Inventory Management Screen
/// Live stock, low stock alerts, batch/expiry, categories, stock history, valuation
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  ItemCategory? _selectedCategory;
  StockStatus? _statusFilter;
  StockValuationMethod _valuationMethod = StockValuationMethod.fifo;
  bool _preventNegativeStock = true;
  final ApiService _api = ApiService();
  late Future<List<StockMovement>> _movementFuture;
  late Future<List<_AgingBucket>> _agingFuture;
  late Future<List<_ReportItem>> _deadStockFuture;
  late Future<List<_ReportItem>> _fastMovingFuture;
  late Future<_ValuationSummary> _valuationFuture;

  // Live stock data (loaded from API)
  final List<StockItem> _stockItems = [];
  final List<ItemCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadInventoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInventoryData() {
    _loadStockSummary();
    _movementFuture = _fetchMovements();
    _agingFuture = _fetchAging();
    _deadStockFuture = _fetchDeadStock();
    _fastMovingFuture = _fetchFastMoving();
    _valuationFuture = _fetchValuation(_valuationMethod);
  }

  Future<void> _loadStockSummary() async {
    try {
      final data = await _api.getStockSummary(lowStockOnly: false);
      final items = data.map((row) {
        return StockItem(
          id: (row['id'] ?? '').toString(),
          itemCode: (row['sku'] ?? row['barcode'] ?? '').toString(),
          name: row['name']?.toString() ?? '',
          description: null,
          hsnCode: row['hsn_code']?.toString(),
          categoryId: '',
          categoryName: null,
          unit: row['unit']?.toString() ?? 'pcs',
          alternateUnits: const [],
          currentStock: (row['current_stock'] as num?)?.toDouble() ?? 0,
          minStockLevel: (row['min_stock_level'] as num?)?.toDouble() ?? 0,
          maxStockLevel: 0,
          reorderLevel: (row['min_stock_level'] as num?)?.toDouble() ?? 0,
          purchasePrice: (row['cost_price'] as num?)?.toDouble() ?? 0,
          sellingPrice: (row['selling_price'] as num?)?.toDouble() ?? 0,
          mrp: (row['mrp'] as num?)?.toDouble() ?? 0,
          gstRate: 0,
          cessRate: 0,
          trackBatch: false,
          trackExpiry: false,
          trackSerial: false,
          batches: const [],
          valuationMethod: StockValuationMethod.fifo,
          averageCost: 0,
          stockValue: (row['stock_value'] as num?)?.toDouble() ?? 0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: null,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _stockItems
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load stock summary. Please check connection.',
          ),
        ),
      );
    }
  }

  Future<List<StockMovement>> _fetchMovements() async {
    final data = await _api.getInventoryMovements(limit: 20);
    return data.map((row) {
      return StockMovement(
        id: row['id'].toString(),
        itemId: row['item_id'].toString(),
        itemName: row['item_name'] ?? 'Item',
        movementDate: DateTime.parse(row['transaction_date']),
        type: _mapMovementType(row['reference_type'], row['transaction_type']),
        quantity: (row['quantity'] as num?)?.toDouble() ?? 0,
        previousStock: (row['balance_before'] as num?)?.toDouble() ?? 0,
        newStock: (row['balance_after'] as num?)?.toDouble() ?? 0,
        rate: (row['rate'] as num?)?.toDouble() ?? 0,
        referenceId: row['reference_id']?.toString(),
        referenceNumber: row['voucher_number']?.toString(),
        batchNumber: row['batch_number']?.toString(),
        notes: row['narration']?.toString(),
        createdAt: DateTime.parse(row['transaction_date']),
      );
    }).toList();
  }

  Future<List<_AgingBucket>> _fetchAging() async {
    final data = await _api.getInventoryAging();
    return data.map((row) {
      return _AgingBucket(
        row['label']?.toString() ?? '-',
        (row['sku_count'] as num?)?.toInt() ?? 0,
        (row['value'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  Future<List<_ReportItem>> _fetchDeadStock() async {
    final data = await _api.getDeadStock(days: 90);
    return data.map((row) {
      return _ReportItem(
        row['name']?.toString() ?? '-',
        row['sku']?.toString() ?? '-',
        (row['days'] as num?)?.toInt() ?? 0,
        (row['value'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  Future<List<_ReportItem>> _fetchFastMoving() async {
    final data = await _api.getFastMoving(days: 30, limit: 10);
    return data.map((row) {
      return _ReportItem(
        row['name']?.toString() ?? '-',
        row['sku']?.toString() ?? '-',
        (row['quantity'] as num?)?.toInt() ?? 0,
        (row['value'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  Future<_ValuationSummary> _fetchValuation(StockValuationMethod method) async {
    final data = await _api.getInventoryValuation(
      method: method == StockValuationMethod.average ? 'average' : 'fifo',
    );
    return _ValuationSummary(
      totalItems: (data['total_items'] as num?)?.toInt() ?? 0,
      totalQuantity: (data['total_quantity'] as num?)?.toDouble() ?? 0,
      totalPurchaseValue:
          (data['total_purchase_value'] as num?)?.toDouble() ?? 0,
      totalSellingValue: (data['total_selling_value'] as num?)?.toDouble() ?? 0,
      potentialProfit: (data['potential_profit'] as num?)?.toDouble() ?? 0,
    );
  }

  MovementType _mapMovementType(
    String? referenceType,
    String? transactionType,
  ) {
    switch (referenceType) {
      case 'PURCHASE':
        return MovementType.purchase;
      case 'SALE':
        return MovementType.sale;
      case 'TRANSFER_OUT':
        return MovementType.transferOut;
      case 'TRANSFER_IN':
        return MovementType.transferIn;
      case 'DAMAGE':
        return MovementType.damaged;
      case 'ADJUSTMENT':
        return transactionType == 'IN'
            ? MovementType.stockAdjustmentIn
            : MovementType.stockAdjustmentOut;
      default:
        return transactionType == 'IN'
            ? MovementType.stockAdjustmentIn
            : MovementType.stockAdjustmentOut;
    }
  }

  List<StockItem> get _filteredItems {
    return _stockItems.where((item) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.itemCode.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == null || item.categoryId == _selectedCategory!.id;
      final matchesStatus =
          _statusFilter == null || item.stockStatus == _statusFilter;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.slate500,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.inventory_2), text: 'Master'),
                Tab(icon: Icon(Icons.swap_horiz), text: 'Operations'),
                Tab(icon: Icon(Icons.analytics), text: 'Valuation'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
                Tab(icon: Icon(Icons.verified), text: 'Audit'),
              ],
            ),
          ),
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMasterTab(),
                _buildOperationsTab(),
                _buildValuationTab(),
                _buildReportsTab(),
                _buildAuditTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Inventory Management'),
      backgroundColor: AppTheme.sidebarColor,
      foregroundColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              // Search
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              // Category filter
              _buildFilterChip(
                label: _selectedCategory?.name ?? 'All Categories',
                icon: Icons.category,
                onTap: _showCategoryFilter,
              ),
              const SizedBox(width: 8),
              // Status filter
              _buildFilterChip(
                label: _statusFilter?.displayName ?? 'All Status',
                icon: Icons.filter_list,
                color: _statusFilter?.color,
                onTap: _showStatusFilter,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color ?? Colors.white70),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color ?? Colors.white70)),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: color ?? Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Category'),
        children: [
          ListTile(
            title: const Text('All Categories'),
            selected: _selectedCategory == null,
            onTap: () {
              setState(() => _selectedCategory = null);
              Navigator.pop(context);
            },
          ),
          ..._categories.map(
            (cat) => ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getCategoryIcon(cat.name),
                  size: 18,
                  color: cat.color,
                ),
              ),
              title: Text(cat.name),
              subtitle: Text('${cat.itemCount} items'),
              selected: _selectedCategory?.id == cat.id,
              onTap: () {
                setState(() => _selectedCategory = cat);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusFilter() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Status'),
        children: [
          ListTile(
            title: const Text('All Status'),
            selected: _statusFilter == null,
            onTap: () {
              setState(() => _statusFilter = null);
              Navigator.pop(context);
            },
          ),
          ...StockStatus.values.map(
            (status) => ListTile(
              leading: Icon(status.icon, color: status.color),
              title: Text(status.displayName),
              selected: _statusFilter == status,
              onTap: () {
                setState(() => _statusFilter = status);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterTab() {
    final items = _filteredItems;

    return Column(
      children: [
        // Summary cards
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.canvasSecondary,
          child: SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatCard(
                  'Total Items',
                  '${_stockItems.length}',
                  Icons.inventory_2,
                  AppTheme.primaryColor,
                ),
                _buildStatCard(
                  'In Stock',
                  '${_stockItems.where((i) => i.stockStatus == StockStatus.inStock).length}',
                  Icons.check_circle,
                  Color(0xFF10B981),
                ),
                _buildStatCard(
                  'Low Stock',
                  '${_stockItems.where((i) => i.stockStatus == StockStatus.lowStock).length}',
                  Icons.warning_amber_rounded,
                  Color(0xFFF59E0B),
                ),
                _buildStatCard(
                  'Out of Stock',
                  '${_stockItems.where((i) => i.stockStatus == StockStatus.outOfStock).length}',
                  Icons.error_outline,
                  Color(0xFFEF4444),
                ),
                _buildStatCard(
                  'Total Value',
                  '₹${_stockItems.fold<double>(0, (sum, i) => sum + i.stockValue).toStringAsFixed(0)}',
                  Icons.currency_rupee,
                  Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFeatureChip('SKU Master', Icons.qr_code_2, AppTheme.primaryColor),
                  _buildFeatureChip('HSN/SAC', Icons.category, Color(0xFF4F46E5)),
                  _buildFeatureChip('Units', Icons.straighten, Color(0xFF06B6D4)),
                  _buildFeatureChip(
                    'Batch & Expiry',
                    Icons.date_range,
                    Color(0xFFF59E0B),
                  ),
                  _buildFeatureChip(
                    'Serial Tracking',
                    Icons.confirmation_number,
                    Color(0xFF8B5CF6),
                  ),
                  _buildFeatureChip(
                    'Reorder Level',
                    Icons.refresh,
                    Color(0xFF10B981),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Items table
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(color: AppTheme.slate200),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Table header + horizontal scroll
                Container(
                  color: AppTheme.primaryLight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 260,
                            child: Text(
                              'Item',
                              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.slate900),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'SKU',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Stock',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(
                              'Reorder',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text(
                              'Tracking',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Cost',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'MRP',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Margin',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text(
                              'Status',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(width: 60),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),

                // Items list with horizontal scroll
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No items found',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 1090,
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) =>
                                  _buildItemRow(items[index]),
                            ),
                          ),
                        ),
                ),
              ],
            ),
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
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.slate500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingBadges(StockItem item) {
    final badges = <Widget>[];
    if (item.trackBatch) {
      badges.add(_miniBadge('Batch', Colors.indigo));
    }
    if (item.trackExpiry) {
      badges.add(_miniBadge('Expiry', Colors.teal));
    }
    if (item.trackSerial) {
      badges.add(_miniBadge('Serial', Colors.purple));
    }
    if (badges.isEmpty) {
      badges.add(_miniBadge('None', Colors.grey));
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: badges,
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildItemRow(StockItem item) {
    return InkWell(
      onTap: () => _showItemDetails(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.stockStatus.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: item.stockStatus.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.hsnCode ?? 'No HSN',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 100, child: Text(item.itemCode)),
            SizedBox(
              width: 80,
              child: Text(
                '${item.currentStock.toInt()} ${item.unit}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: item.stockStatus.color,
                ),
              ),
            ),
            SizedBox(
              width: 90,
              child: Text(
                item.reorderLevel > 0
                    ? item.reorderLevel.toInt().toString()
                    : '-',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: item.reorderLevel > 0
                      ? Colors.grey.shade700
                      : Colors.grey.shade400,
                ),
              ),
            ),
            SizedBox(width: 100, child: _buildTrackingBadges(item)),
            SizedBox(
              width: 80,
              child: Text(
                '₹${item.purchasePrice.toStringAsFixed(0)}',
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                '₹${item.sellingPrice.toStringAsFixed(0)}',
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.profitMargin > 20
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.profitMargin.toStringAsFixed(1)}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: item.profitMargin > 20
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.stockStatus.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.stockStatus.icon,
                        size: 14,
                        color: item.stockStatus.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.stockStatus.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: item.stockStatus.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 50,
              child: PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 20),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'adjust', child: Text('Adjust Stock')),
                  PopupMenuItem(value: 'history', child: Text('View History')),
                ],
                onSelected: (value) {
                  // Handle menu actions
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsTab() {
    final actions = [
      _OperationAction(
        'Purchase In',
        'Receive stock from vendors',
        Icons.call_received,
        Colors.green,
        MovementType.purchase,
      ),
      _OperationAction(
        'Sale Out',
        'Issue stock to customers',
        Icons.call_made,
        Colors.red,
        MovementType.sale,
      ),
      _OperationAction(
        'Transfer',
        'Move stock between locations',
        Icons.swap_horiz,
        Colors.blue,
        MovementType.transferOut,
      ),
      _OperationAction(
        'Damage',
        'Write-off damaged stock',
        Icons.report_gmailerrorred,
        Colors.orange,
        MovementType.damaged,
      ),
      _OperationAction(
        'Physical Adjust',
        'Stock count adjustment',
        Icons.tune,
        Colors.purple,
        MovementType.stockAdjustmentOut,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions.map(_buildOperationCard).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Recent Operations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<StockMovement>>(
            future: _movementFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Failed to load movements',
                  style: TextStyle(color: Colors.grey.shade600),
                );
              }
              final movements = snapshot.data ?? [];
              if (movements.isEmpty) {
                return Text(
                  'No movements yet',
                  style: TextStyle(color: Colors.grey.shade600),
                );
              }
              return Column(
                children: movements.take(6).map((movement) {
                  final isIncrease = movement.isInward;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (isIncrease ? Colors.green : Colors.red)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isIncrease
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline,
                          color: isIncrease ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(movement.itemName),
                      subtitle: Text(
                        '${movement.type.displayName} • ${_formatDate(movement.movementDate)}',
                      ),
                      trailing: Text(
                        '${isIncrease ? '+' : ''}${movement.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isIncrease ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCard(_OperationAction action) {
    return SizedBox(
      width: 240,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, color: action.color),
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                action.subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _showMovementDialog(action),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    final reportCards = [
      _ReportCard(
        'Aging',
        'Inventory aging buckets and expiry risk',
        Icons.hourglass_bottom,
        Colors.orange,
      ),
      _ReportCard(
        'Dead Stock',
        'Zero movement items beyond threshold',
        Icons.block,
        Colors.red,
      ),
      _ReportCard(
        'Fast Moving',
        'Top selling SKUs with high velocity',
        Icons.trending_up,
        Colors.green,
      ),
      _ReportCard(
        'Stock Valuation',
        'Snapshot by FIFO / Weighted Avg',
        Icons.account_balance_wallet,
        Colors.blue,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: reportCards.map(_buildReportCard).toList(),
          ),
          const SizedBox(height: 20),
          Text('Aging Buckets', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          FutureBuilder<List<_AgingBucket>>(
            future: _agingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Failed to load aging',
                  style: TextStyle(color: Colors.grey.shade600),
                );
              }
              return _buildAgingBuckets(snapshot.data ?? []);
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Dead Stock (90+ days)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<_ReportItem>>(
            future: _deadStockFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Failed to load dead stock',
                  style: TextStyle(color: Colors.grey.shade600),
                );
              }
              return _buildReportItemList(
                snapshot.data ?? [],
                Colors.red,
                metricLabel: 'days',
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Fast Moving (30 days)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<_ReportItem>>(
            future: _fastMovingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Failed to load fast moving',
                  style: TextStyle(color: Colors.grey.shade600),
                );
              }
              return _buildReportItemList(
                snapshot.data ?? [],
                Colors.green,
                metricLabel: 'qty',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(_ReportCard report) {
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: report.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(report.icon, color: report.color),
              ),
              const SizedBox(height: 12),
              Text(
                report.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                report.subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opened ${report.title}')),
                  );
                },
                child: const Text('View'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgingBuckets(List<_AgingBucket> buckets) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: buckets.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No aging data',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ]
              : buckets.map((bucket) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(bucket.label)),
                        Text(
                          '${bucket.skuCount} SKUs',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₹${bucket.value.toStringAsFixed(0)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportItemList(
    List<_ReportItem> items,
    Color color, {
    String metricLabel = 'days',
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: items.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No data',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ]
            : items.map((item) {
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.inventory_2_outlined, color: color),
                  ),
                  title: Text(item.name),
                  subtitle: Text('SKU ${item.sku} • ${item.days} $metricLabel'),
                  trailing: Text(
                    '₹${item.value.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
      ),
    );
  }

  Widget _buildAuditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _preventNegativeStock,
                  onChanged: (value) =>
                      setState(() => _preventNegativeStock = value),
                  title: const Text('Prevent Negative Stock'),
                  subtitle: const Text(
                    'Block sales or transfers below available stock',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: true,
                  onChanged: (_) {},
                  title: const Text('Track Movement History'),
                  subtitle: const Text(
                    'Maintain audit trail for all operations',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Movement History',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<StockMovement>>(
            future: _movementFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Failed to load movement history',
                  style: TextStyle(color: Colors.grey.shade600),
                );
              }
              final movements = snapshot.data ?? [];
              if (movements.isEmpty) {
                return Text(
                  'No movements yet',
                  style: TextStyle(color: Colors.grey.shade600),
                );
              }
              return Column(
                children: movements.take(8).map((movement) {
                  final isIncrease = movement.isInward;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (isIncrease ? Colors.green : Colors.red)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isIncrease
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline,
                          color: isIncrease ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(movement.itemName),
                      subtitle: Text(
                        '${movement.type.displayName} • ${movement.referenceNumber ?? 'N/A'}',
                      ),
                      trailing: Text(
                        '${isIncrease ? '+' : ''}${movement.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isIncrease ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Accounting Entries',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildAccountingEntries(),
        ],
      ),
    );
  }

  Widget _buildValuationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary cards
          FutureBuilder<_ValuationSummary>(
            future: _valuationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Failed to load valuation',
                  style: TextStyle(color: Colors.grey.shade600),
                );
              }
              final valuation = snapshot.data ?? _ValuationSummary.empty();
              return Row(
                children: [
                  Expanded(
                    child: _buildValuationCard(
                      'Total Stock Value',
                      '₹${valuation.totalSellingValue.toStringAsFixed(0)}',
                      Icons.account_balance_wallet,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildValuationCard(
                      'Total Cost',
                      '₹${valuation.totalPurchaseValue.toStringAsFixed(0)}',
                      Icons.shopping_cart,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildValuationCard(
                      'Potential Profit',
                      '₹${valuation.potentialProfit.toStringAsFixed(0)}',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Category-wise valuation
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category-wise Valuation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _categories.asMap().entries.map((entry) {
                          final colors = [
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                          ];
                          return PieChartSectionData(
                            value: entry.value.itemCount.toDouble() * 1000,
                            color: colors[entry.key % colors.length],
                            title: entry.value.name,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            radius: 60,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._categories.asMap().entries.map((entry) {
                    final colors = [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                      Colors.teal,
                    ];
                    final value = entry.value.itemCount * 1000.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[entry.key % colors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.value.name)),
                          Text(
                            '₹${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Valuation method
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Valuation Method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<StockValuationMethod>(
                    segments: const [
                      ButtonSegment(
                        value: StockValuationMethod.fifo,
                        label: Text('FIFO'),
                      ),
                      ButtonSegment(
                        value: StockValuationMethod.average,
                        label: Text('Weighted Avg'),
                      ),
                    ],
                    selected: {_valuationMethod},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _valuationMethod = selection.first;
                        _valuationFuture = _fetchValuation(_valuationMethod);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _valuationMethod == StockValuationMethod.fifo
                        ? 'Using First-In-First-Out method for stock valuation'
                        : 'Using Weighted Average method for stock valuation',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuationCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildAccountingEntries() {
    // TODO: Fetch real accounting entries from API
    // For now, show placeholder until real data is available
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade400, size: 32),
            const SizedBox(height: 16),
            Text(
              'Accounting entries will be calculated from inventory data',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(StockItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('SKU', item.itemCode),
              _detailRow('HSN', item.hsnCode ?? '-'),
              _detailRow(
                'Current Stock',
                '${item.currentStock.toInt()} ${item.unit}',
              ),
              _detailRow(
                'Min Stock Level',
                '${item.minStockLevel.toInt()} ${item.unit}',
              ),
              _detailRow(
                'Reorder Level',
                item.reorderLevel > 0
                    ? '${item.reorderLevel.toInt()} ${item.unit}'
                    : '-',
              ),
              _detailRow(
                'Cost Price',
                '₹${item.purchasePrice.toStringAsFixed(2)}',
              ),
              _detailRow(
                'Selling Price',
                '₹${item.sellingPrice.toStringAsFixed(2)}',
              ),
              _detailRow(
                'Profit Margin',
                '${item.profitMargin.toStringAsFixed(1)}%',
              ),
              _detailRow(
                'Stock Value',
                '₹${item.stockValue.toStringAsFixed(2)}',
              ),
              _detailRow('GST Rate', '${item.gstRate.toInt()}%'),
              _detailRow('Tracking', _formatTracking(item)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Open edit dialog
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTracking(StockItem item) {
    final parts = <String>[];
    if (item.trackBatch) parts.add('Batch');
    if (item.trackExpiry) parts.add('Expiry');
    if (item.trackSerial) parts.add('Serial');
    if (parts.isEmpty) return 'None';
    return parts.join(', ');
  }

  void _showAddItemDialog() {
    // Show add item dialog
    showDialog(
      context: context,
      builder: (context) => const _AddStockItemDialog(),
    );
  }

  Future<void> _showMovementDialog(_OperationAction action) async {
    final posted = await showDialog<bool>(
      context: context,
      builder: (context) => _StockMovementDialog(action: action, api: _api),
    );

    if (posted == true) {
      setState(() => _loadInventoryData());
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'accessories':
        return Icons.headphones;
      case 'office supplies':
        return Icons.work;
      case 'furniture':
        return Icons.chair;
      default:
        return Icons.category;
    }
  }
}

class _OperationAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final MovementType type;

  _OperationAction(this.title, this.subtitle, this.icon, this.color, this.type);
}

class _ReportCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _ReportCard(this.title, this.subtitle, this.icon, this.color);
}

class _AgingBucket {
  final String label;
  final int skuCount;
  final double value;

  _AgingBucket(this.label, this.skuCount, this.value);
}

class _ReportItem {
  final String name;
  final String sku;
  final int days;
  final double value;

  _ReportItem(this.name, this.sku, this.days, this.value);
}

class _ValuationSummary {
  final int totalItems;
  final double totalQuantity;
  final double totalPurchaseValue;
  final double totalSellingValue;
  final double potentialProfit;

  const _ValuationSummary({
    required this.totalItems,
    required this.totalQuantity,
    required this.totalPurchaseValue,
    required this.totalSellingValue,
    required this.potentialProfit,
  });

  factory _ValuationSummary.empty() {
    return const _ValuationSummary(
      totalItems: 0,
      totalQuantity: 0,
      totalPurchaseValue: 0,
      totalSellingValue: 0,
      potentialProfit: 0,
    );
  }
}

class _AddStockItemDialog extends StatefulWidget {
  const _AddStockItemDialog();

  @override
  State<_AddStockItemDialog> createState() => _AddStockItemDialogState();
}

class _AddStockItemDialogState extends State<_AddStockItemDialog> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _hsnSacController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _reorderController = TextEditingController();
  double _gstRate = 18;
  String _unit = 'PCS';
  bool _trackBatch = false;
  bool _trackExpiry = false;
  bool _trackSerial = false;
  bool _useHsn = true; // Toggle: true = HSN, false = SAC

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _hsnSacController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _reorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate900,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppTheme.slate400),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing24),
              
              // Content
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: const BorderSide(color: AppTheme.slate300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.slate50,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU *',
                        hintText: 'e.g., SKU-001',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Barcode *',
                        hintText: 'Product barcode',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        hintText: 'Manufacturer/Brand',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model/Variant',
                        hintText: 'e.g., 9W, Cool White',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hsnSacController,
                      decoration: InputDecoration(
                        labelText: _useHsn ? 'HSN Code' : 'SAC Code',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Code Type',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('HSN')),
                            ButtonSegment(value: false, label: Text('SAC')),
                          ],
                          selected: {_useHsn},
                          onSelectionChanged: (value) {
                            setState(() => _useHsn = value.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _costController,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mrpController,
                decoration: const InputDecoration(
                  labelText: 'MRP',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Maximum Retail Price (Optional)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Opening Stock',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _minStockController,
                      decoration: const InputDecoration(
                        labelText: 'Min Stock Level',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const ['PCS', 'BOX', 'KG', 'LTR', 'SET']
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _unit = value ?? 'PCS'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _reorderController,
                      decoration: const InputDecoration(
                        labelText: 'Reorder Level',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<double>(
                initialValue: _gstRate,
                decoration: const InputDecoration(
                  labelText: 'GST Rate',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [0, 5, 12, 18, 28]
                    .map(
                      (rate) => DropdownMenuItem(
                        value: rate.toDouble(),
                        child: Text('$rate%'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _gstRate = value ?? 18),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tracking Options',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _trackBatch,
                onChanged: (value) =>
                    setState(() => _trackBatch = value ?? false),
                title: const Text('Track Batch'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _trackExpiry,
                onChanged: (value) =>
                    setState(() => _trackExpiry = value ?? false),
                title: const Text('Track Expiry'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _trackSerial,
                onChanged: (value) =>
                    setState(() => _trackSerial = value ?? false),
                title: const Text('Track Serial'),
              ),
              const SizedBox(height: AppTheme.spacing24),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24, vertical: AppTheme.spacing12),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.slate600, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              FilledButton(
                onPressed: () {
                  // Validate and save
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24, vertical: AppTheme.spacing12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                ),
                child: const Text(
                  'Add Item',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockMovementDialog extends StatefulWidget {
  final _OperationAction action;
  final ApiService api;

  const _StockMovementDialog({required this.action, required this.api});

  @override
  State<_StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<_StockMovementDialog> {
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _batchController = TextEditingController();
  final _narrationController = TextEditingController();
  final _serialsController = TextEditingController();

  ItemSearchResult? _selectedItem;
  Item? _itemDetails;
  bool _loadingItem = false;
  bool _submitting = false;
  DateTime? _mfgDate;
  DateTime? _expiryDate;
  String _movementOverride = '';

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _batchController.dispose();
    _narrationController.dispose();
    _serialsController.dispose();
    super.dispose();
  }

  Future<void> _selectItem() async {
    final item = await showDialog<ItemSearchResult>(
      context: context,
      builder: (context) => ItemSearchDialog(
        onItemSelected: (selected) => Navigator.pop(context, selected),
      ),
    );

    if (item == null) return;

    setState(() {
      _selectedItem = item;
      _itemDetails = null;
      _loadingItem = true;
      _itemController.text = item.name;
    });

    try {
      final details = await widget.api.getItem(item.id);
      setState(() {
        _itemDetails = details;
        _loadingItem = false;
        _applyDefaultRate(details);
      });
    } catch (_) {
      setState(() => _loadingItem = false);
      _showMessage('Failed to load item details');
    }
  }

  void _applyDefaultRate(Item details) {
    final rate = widget.action.type == MovementType.sale
        ? details.sellingPrice
        : details.costPrice;
    _rateController.text = rate.toStringAsFixed(0);
  }

  Future<void> _pickDate(bool isExpiry) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      if (isExpiry) {
        _expiryDate = picked;
      } else {
        _mfgDate = picked;
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _movementCode() {
    if (_movementOverride.isNotEmpty) return _movementOverride;
    switch (widget.action.type) {
      case MovementType.purchase:
        return 'PURCHASE_IN';
      case MovementType.sale:
        return 'SALE_OUT';
      case MovementType.transferIn:
        return 'TRANSFER_IN';
      case MovementType.transferOut:
        return 'TRANSFER_OUT';
      case MovementType.damaged:
        return 'DAMAGE';
      case MovementType.stockAdjustmentIn:
        return 'ADJUSTMENT_IN';
      case MovementType.stockAdjustmentOut:
        return 'ADJUSTMENT_OUT';
      default:
        return 'ADJUSTMENT_OUT';
    }
  }

  List<String> _parseSerials() {
    return _serialsController.text
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (_selectedItem == null || _itemDetails == null) {
      _showMessage('Select an item');
      return;
    }

    final quantity = double.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showMessage('Enter valid quantity');
      return;
    }

    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    final serials = _parseSerials();

    if (_itemDetails!.serialTracking && serials.length != quantity.toInt()) {
      _showMessage('Serial count must match quantity');
      return;
    }

    if (_itemDetails!.batchTracking && _batchController.text.trim().isEmpty) {
      _showMessage('Batch number required');
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.api.createInventoryMovement({
        'item_id': _itemDetails!.id,
        'movement': _movementCode(),
        'quantity': quantity,
        'rate': rate,
        'batch_number': _batchController.text.trim().isEmpty
            ? null
            : _batchController.text.trim(),
        'manufacturing_date': _mfgDate?.toIso8601String().split('T')[0],
        'expiry_date': _expiryDate?.toIso8601String().split('T')[0],
        'serial_numbers': serials.isEmpty ? null : serials,
        'narration': _narrationController.text.trim().isEmpty
            ? null
            : _narrationController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showMessage('Failed to post movement');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemDetails = _itemDetails;
    final showBatch =
        itemDetails?.batchTracking == true ||
        itemDetails?.expiryTracking == true;
    final showSerial = itemDetails?.serialTracking == true;
    final isTransfer = widget.action.type == MovementType.transferOut;
    final isAdjust = widget.action.type == MovementType.stockAdjustmentOut;

    return AlertDialog(
      title: Text(widget.action.title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      controller: _itemController,
                      decoration: const InputDecoration(
                        labelText: 'Item',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _selectItem,
                    child: const Text('Select'),
                  ),
                ],
              ),
              if (_loadingItem) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (itemDetails != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Stock: ${itemDetails.currentStock.toStringAsFixed(2)} ${itemDetails.unitCode ?? 'NOS'}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (isTransfer) ...[
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'TRANSFER_OUT',
                      label: Text('Transfer Out'),
                    ),
                    ButtonSegment(
                      value: 'TRANSFER_IN',
                      label: Text('Transfer In'),
                    ),
                  ],
                  selected: {
                    _movementOverride.isEmpty
                        ? 'TRANSFER_OUT'
                        : _movementOverride,
                  },
                  onSelectionChanged: (selection) {
                    setState(() => _movementOverride = selection.first);
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (isAdjust) ...[
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'ADJUSTMENT_OUT',
                      label: Text('Decrease'),
                    ),
                    ButtonSegment(
                      value: 'ADJUSTMENT_IN',
                      label: Text('Increase'),
                    ),
                  ],
                  selected: {
                    _movementOverride.isEmpty
                        ? 'ADJUSTMENT_OUT'
                        : _movementOverride,
                  },
                  onSelectionChanged: (selection) {
                    setState(() => _movementOverride = selection.first);
                  },
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _rateController,
                      decoration: const InputDecoration(
                        labelText: 'Rate',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (showBatch) ...[
                TextField(
                  controller: _batchController,
                  decoration: const InputDecoration(
                    labelText: 'Batch Number',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(false),
                        child: Text(
                          _mfgDate == null
                              ? 'Manufacturing Date'
                              : 'Mfg: ${_mfgDate!.toIso8601String().split('T')[0]}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(true),
                        child: Text(
                          _expiryDate == null
                              ? 'Expiry Date'
                              : 'Exp: ${_expiryDate!.toIso8601String().split('T')[0]}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (showSerial) ...[
                TextField(
                  controller: _serialsController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Serial Numbers (one per line)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _narrationController,
                decoration: const InputDecoration(
                  labelText: 'Narration',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Post Movement'),
        ),
      ],
    );
  }
}


