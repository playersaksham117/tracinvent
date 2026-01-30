import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dbHelper = DatabaseHelper.instance;
  
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _creditInvoices = [];
  List<Map<String, dynamic>> _customers = [];
  int? _selectedCustomerId;
  Map<String, dynamic> _customerStatement = {};
  List<Map<String, dynamic>> _paymentVouchers = [];
  
  DateTimeRange? _dateRange;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadDashboard(),
      _loadCreditInvoices(),
      _loadCustomers(),
      _loadPaymentVouchers(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadDashboard() async {
    final data = await _dbHelper.getDashboardMetrics();
    setState(() => _dashboardData = data);
  }

  Future<void> _loadCreditInvoices() async {
    final invoices = await _dbHelper.getCreditInvoices();
    setState(() => _creditInvoices = invoices);
  }

  Future<void> _loadCustomers() async {
    final customers = await _dbHelper.query('customers', orderBy: 'name');
    setState(() => _customers = customers);
  }

  Future<void> _loadPaymentVouchers() async {
    final vouchers = await _dbHelper.getPaymentVouchers();
    setState(() => _paymentVouchers = vouchers);
  }

  Future<void> _loadCustomerStatement() async {
    if (_selectedCustomerId == null) return;
    
    setState(() => _isLoading = true);
    final statement = await _dbHelper.getCustomerStatement(
      _selectedCustomerId!,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
    setState(() {
      _customerStatement = statement;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildSalesAnalyticsTab(),
                _buildCreditInvoicesTab(),
                _buildCustomerStatementTab(),
                _buildPaymentVouchersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Color(0xFF3B82F6),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports & Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Business insights and financial tracking',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildDateRangeButton(),
        ],
      ),
    );
  }

  Widget _buildDateRangeButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: _dateRange,
        );
        if (picked != null) {
          setState(() => _dateRange = picked);
          if (_tabController.index == 3 && _selectedCustomerId != null) {
            _loadCustomerStatement();
          }
        }
      },
      icon: const Icon(Icons.date_range, size: 18),
      label: Text(
        _dateRange == null
            ? 'All Time'
            : '${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
        style: const TextStyle(fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF3B82F6),
        labelColor: const Color(0xFF3B82F6),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'Sales Analytics'),
          Tab(text: 'Credit Invoices'),
          Tab(text: 'Customer Statements'),
          Tab(text: 'Payment Vouchers'),
        ],
      ),
    );
  }

  // Dashboard Tab
  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsGrid(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTopProductsCard()),
              const SizedBox(width: 24),
              Expanded(child: _buildPaymentMethodsCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Today\'s Sales',
            '${_dashboardData['todaySales'] ?? 0}',
            '₹${_formatNumber(_dashboardData['todayRevenue'] ?? 0)}',
            Icons.shopping_cart_outlined,
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Week\'s Revenue',
            '₹${_formatNumber(_dashboardData['weekRevenue'] ?? 0)}',
            '',
            Icons.trending_up,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Outstanding Dues',
            '₹${_formatNumber(_dashboardData['outstandingDues'] ?? 0)}',
            '',
            Icons.account_balance_wallet_outlined,
            const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Today Paid',
            '₹${_formatNumber(_dashboardData['todayPaidRevenue'] ?? 0)}',
            '',
            Icons.payments_outlined,
            const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopProductsCard() {
    final topProducts = _dashboardData['topProducts'] as List<Map<String, dynamic>>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Top Products (Last 30 Days)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Icon(Icons.star_outline, size: 20, color: Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 16),
          if (topProducts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No sales data available',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < topProducts.length - 1 ? 12 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['product_name'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '${product['total_quantity']} units sold',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${_formatNumber(product['total_revenue'])}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
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

  Widget _buildPaymentMethodsCard() {
    final paymentBreakdown = _dashboardData['paymentBreakdown'] as List<Map<String, dynamic>>? ?? [];
    final total = paymentBreakdown.fold(0.0, (sum, item) => sum + (item['total'] as double));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Payment Methods (Last 30 Days)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              const Icon(Icons.payment, size: 20, color: Color(0xFF3B82F6)),
            ],
          ),
          const SizedBox(height: 16),
          if (paymentBreakdown.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No payment data available',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...paymentBreakdown.asMap().entries.map((entry) {
              final index = entry.key;
              final method = entry.value;
              final percentage = total > 0 ? ((method['total'] as double) / total * 100) : 0.0;
              final colors = [
                const Color(0xFF3B82F6),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
                const Color(0xFFEF4444),
                const Color(0xFF8B5CF6),
              ];
              final color = colors[index % colors.length];

              return Padding(
                padding: EdgeInsets.only(bottom: index < paymentBreakdown.length - 1 ? 16 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          method['payment_method'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${_formatNumber(method['total'])}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: color.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
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

  // Sales Analytics Tab
  Widget _buildSalesAnalyticsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 16),
            Text(
              'Advanced Analytics Coming Soon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Charts and detailed revenue analytics will be available here',
              style: TextStyle(color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Credit Invoices Tab
  Widget _buildCreditInvoicesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${_creditInvoices.length} Outstanding Invoices',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _loadCreditInvoices,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _creditInvoices.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF10B981)),
                      SizedBox(height: 16),
                      Text(
                        'No Outstanding Invoices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All invoices have been fully paid',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _creditInvoices.length,
                  itemBuilder: (context, index) {
                    final invoice = _creditInvoices[index];
                    return _buildCreditInvoiceCard(invoice);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCreditInvoiceCard(Map<String, dynamic> invoice) {
    final dueAmount = invoice['due_amount'] as double? ?? 0.0;
    final totalAmount = invoice['total_amount'] as double;
    final paidAmount = (invoice['paid_amount'] as double?) ?? 0.0;
    final paymentStatus = invoice['payment_status'] as String;

    Color statusColor = paymentStatus == 'partial' 
        ? const Color(0xFFF59E0B) 
        : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      invoice['sale_number'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        paymentStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  invoice['customer_name'] ?? 'Walk-in Customer',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip('Total: ₹${_formatNumber(totalAmount)}'),
                    const SizedBox(width: 8),
                    _buildInfoChip('Paid: ₹${_formatNumber(paidAmount)}', const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    _buildInfoChip('Due: ₹${_formatNumber(dueAmount)}', const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showRecordPaymentDialog(invoice),
            icon: const Icon(Icons.payment, size: 18),
            label: const Text('Record Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFF64748B)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color ?? const Color(0xFF64748B),
        ),
      ),
    );
  }

  // Customer Statement Tab
  Widget _buildCustomerStatementTab() {
    return Row(
      children: [
        // Customer List Sidebar
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: const Text(
                  'Select Customer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    final isSelected = customer['id'] == _selectedCustomerId;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: const Color(0xFF3B82F6)) : null,
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() => _selectedCustomerId = customer['id']);
                          _loadCustomerStatement();
                        },
                        dense: true,
                        title: Text(
                          customer['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(
                          customer['phone'] ?? 'No phone',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Statement Content
        Expanded(
          child: _selectedCustomerId == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 64, color: Color(0xFF94A3B8)),
                      SizedBox(height: 16),
                      Text(
                        'Select a Customer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Choose a customer from the list to view their statement',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : _buildCustomerStatementContent(),
        ),
      ],
    );
  }

  Widget _buildCustomerStatementContent() {
    if (_isLoading || _customerStatement.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final customer = _customerStatement['customer'] as Map<String, dynamic>;
    final sales = _customerStatement['sales'] as List<Map<String, dynamic>>;
    final vouchers = _customerStatement['vouchers'] as List<Map<String, dynamic>>;
    final totalSales = _customerStatement['totalSales'] as double;
    final totalPaid = _customerStatement['totalPaid'] as double;
    final totalDue = _customerStatement['totalDue'] as double;

    return Column(
      children: [
        // Customer Info Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  (customer['name'] as String? ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer['phone'] ?? 'No phone',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatementSummaryCard('Total Sales', totalSales, const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _buildStatementSummaryCard('Total Paid', totalPaid, const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _buildStatementSummaryCard('Balance Due', totalDue, const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _printCustomerStatement(customer, sales, vouchers),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Print Statement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        // Transactions List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (sales.isNotEmpty) ...[
                const Text(
                  'Sales Invoices',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                ...sales.map((sale) => _buildStatementRow(
                      date: sale['created_at'] ?? '',
                      description: 'Invoice ${sale['sale_number']}',
                      debit: sale['total_amount'] as double,
                      credit: 0.0,
                      balance: (sale['due_amount'] as double?) ?? 0.0,
                    )),
              ],
              if (vouchers.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Payment Vouchers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                ...vouchers.map((voucher) => _buildStatementRow(
                      date: voucher['created_at'] ?? '',
                      description: 'Payment ${voucher['voucher_number']} - ${voucher['payment_method']}',
                      debit: 0.0,
                      credit: voucher['amount'] as double,
                      balance: 0.0,
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatementSummaryCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${_formatNumber(value)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementRow({
    required String date,
    required String description,
    required double debit,
    required double credit,
    required double balance,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              DateFormat('dd MMM yyyy').format(DateTime.parse(date)),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              debit > 0 ? '₹${_formatNumber(debit)}' : '-',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(
              credit > 0 ? '₹${_formatNumber(credit)}' : '-',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Payment Vouchers Tab
  Widget _buildPaymentVouchersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${_paymentVouchers.length} Payment Vouchers',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showRecordPaymentDialog(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Voucher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _paymentVouchers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFF94A3B8)),
                      SizedBox(height: 16),
                      Text(
                        'No Payment Vouchers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start recording payments to track them here',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _paymentVouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = _paymentVouchers[index];
                    return _buildVoucherCard(voucher);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_outlined,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher['voucher_number'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${voucher['customer_name'] ?? 'Unknown'} • ${voucher['payment_method']}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (voucher['invoice_number'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Against Invoice: ${voucher['invoice_number']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatNumber(voucher['amount'] as double)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy').format(DateTime.parse(voucher['created_at'])),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _deleteVoucher(voucher['id']),
            icon: const Icon(Icons.delete_outline, size: 20),
            color: const Color(0xFFEF4444),
            tooltip: 'Delete Voucher',
          ),
        ],
      ),
    );
  }

  // Record Payment Dialog
  void _showRecordPaymentDialog(Map<String, dynamic>? invoice) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    final notesController = TextEditingController();
    
    int? selectedSaleId = invoice?['id'];
    int? selectedCustomerId = invoice?['customer_id'];
    String? selectedInvoiceNumber = invoice?['sale_number'];
    String? selectedCustomerName = invoice?['customer_name'];
    String paymentMethod = 'Cash';
    
    final maxAmount = invoice != null ? (invoice['due_amount'] as double? ?? 0.0) : double.infinity;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer/Invoice Selection
                  if (invoice == null) ...[
                    DropdownButtonFormField<int>(
                      value: selectedCustomerId,
                      decoration: const InputDecoration(
                        labelText: 'Customer',
                        border: OutlineInputBorder(),
                      ),
                      items: _customers.map((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setDialogState(() => selectedCustomerId = value);
                        if (value != null) {
                          // Load customer's credit invoices
                          final creditInvoices = await _dbHelper.query(
                            'sales',
                            where: 'customer_id = ? AND payment_status IN (?, ?)',
                            whereArgs: [value, 'partial', 'credit'],
                          );
                          // Show invoice selector if customer has credit invoices
                          if (creditInvoices.isNotEmpty && context.mounted) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Select Invoice'),
                                content: SizedBox(
                                  width: 400,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: creditInvoices.length + 1,
                                    itemBuilder: (ctx, i) {
                                      if (i == 0) {
                                        return ListTile(
                                          title: const Text('General Payment (No specific invoice)'),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            setDialogState(() {
                                              selectedSaleId = null;
                                              selectedInvoiceNumber = null;
                                            });
                                          },
                                        );
                                      }
                                      final inv = creditInvoices[i - 1];
                                      return ListTile(
                                        title: Text(inv['sale_number'] ?? 'N/A'),
                                        subtitle: Text('Due: ₹${_formatNumber(inv['due_amount'] ?? 0)}'),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          setDialogState(() {
                                            selectedSaleId = inv['id'];
                                            selectedInvoiceNumber = inv['sale_number'];
                                            amountController.text = (inv['due_amount'] ?? 0).toString();
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    TextFormField(
                      initialValue: selectedInvoiceNumber,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: selectedCustomerName ?? 'Walk-in Customer',
                      decoration: const InputDecoration(
                        labelText: 'Customer',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Amount
                  TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: const OutlineInputBorder(),
                      prefixText: '₹',
                      helperText: invoice != null ? 'Maximum: ₹${_formatNumber(maxAmount)}' : null,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) return 'Invalid amount';
                      if (invoice != null && amount > maxAmount) return 'Exceeds due amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Payment Method
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Cash', 'Card', 'UPI', 'Bank Transfer', 'Cheque'].map((method) {
                      return DropdownMenuItem(value: method, child: Text(method));
                    }).toList(),
                    onChanged: (value) => setDialogState(() => paymentMethod = value ?? 'Cash'),
                  ),
                  const SizedBox(height: 16),
                  // Reference
                  TextFormField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Reference Number (Optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Transaction ID, Cheque No., etc.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Notes
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate() && selectedCustomerId != null) {
                  final voucherNumber = await _dbHelper.generateVoucherNumber();
                  
                  await _dbHelper.insertPaymentVoucher({
                    'voucher_number': voucherNumber,
                    'customer_id': selectedCustomerId,
                    'customer_name': selectedCustomerName ?? _customers.firstWhere((c) => c['id'] == selectedCustomerId)['name'],
                    'sale_id': selectedSaleId,
                    'invoice_number': selectedInvoiceNumber,
                    'amount': double.parse(amountController.text),
                    'payment_method': paymentMethod,
                    'payment_reference': referenceController.text.isEmpty ? null : referenceController.text,
                    'notes': notesController.text.isEmpty ? null : notesController.text,
                    'received_by': 'Admin',
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment voucher $voucherNumber created'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                    _loadInitialData();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteVoucher(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voucher'),
        content: const Text('Are you sure you want to delete this payment voucher? This will reverse the payment on the invoice.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deletePaymentVoucher(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voucher deleted'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        _loadInitialData();
      }
    }
  }

  Future<void> _printCustomerStatement(
    Map<String, dynamic> customer,
    List<Map<String, dynamic>> sales,
    List<Map<String, dynamic>> vouchers,
  ) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Customer Statement',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Customer: ${customer['name']}'),
              pw.Text('Phone: ${customer['phone'] ?? 'N/A'}'),
              if (_dateRange != null)
                pw.Text('Period: ${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}'),
              pw.SizedBox(height: 20),
              pw.Text('Transactions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...sales.map((sale) => pw.Text(
                '${DateFormat('dd/MM/yyyy').format(DateTime.parse(sale['created_at']))} - ${sale['sale_number']} - ₹${_formatNumber(sale['total_amount'])}',
              )),
              ...vouchers.map((voucher) => pw.Text(
                '${DateFormat('dd/MM/yyyy').format(DateTime.parse(voucher['created_at']))} - Payment ${voucher['voucher_number']} - ₹${_formatNumber(voucher['amount'])}',
              )),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  String _formatNumber(dynamic value) {
    final number = value is int ? value.toDouble() : (value as double? ?? 0.0);
    return number.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
