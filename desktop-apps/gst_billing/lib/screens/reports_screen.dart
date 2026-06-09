/// Reports Screen - Statutory Compliance
/// ITR: Trial Balance, P&L, Balance Sheet, Depreciation, Loans, Capital Movement
/// Books: Day book, Cash book, Bank book, Sales/Purchase/Journal registers
/// GST: GSTR-1, GSTR-3B, ITC, Mismatch Alerts, Amendments
library;

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  DateTime _asOnDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initDates();
  }

  void _initDates() {
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
    _asOnDate = now;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statutory Compliance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export for CA',
            onPressed: () => _exportForCA(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ITR'),
            Tab(text: 'Books'),
            Tab(text: 'GST'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildITRTab(),
          _buildBooksTab(),
          _buildGSTTab(),
        ],
      ),
    );
  }

  Future<void> _exportForCA() async {
    try {
      final data = await _api.exportForCA(
        _fromDate,
        _toDate,
        ['trial_balance', 'pl', 'balance_sheet', 'day_book', 'cash_book', 'bank_book', 'sales_register', 'purchase_register', 'journal_register'],
      );
      if (mounted) {
        _showReport('CA Export', () async => data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Widget _buildITRTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ReportCard(
                icon: Icons.balance,
                title: 'Trial Balance',
                subtitle: 'All ledgers Dr/Cr - CA verification',
                color: AppTheme.primaryColor,
                onTap: () => _showReport('Trial Balance', () => _api.getTrialBalance(_fromDate, _toDate)),
              ),
              _ReportCard(
                icon: Icons.trending_up,
                title: 'P&L',
                subtitle: 'Profit & Loss',
                color: AppTheme.successColor,
                onTap: () => _showReport('P&L', _loadPandL),
              ),
              _ReportCard(
                icon: Icons.account_balance,
                title: 'Balance Sheet',
                subtitle: 'Assets & Liabilities',
                color: AppTheme.primaryColor,
                onTap: () => _showReport('Balance Sheet', _loadBalanceSheet),
              ),
              _ReportCard(
                icon: Icons.straighten,
                title: 'Depreciation',
                subtitle: 'Fixed Assets Depreciation',
                color: AppTheme.secondaryColor,
                onTap: () => _showReport('Depreciation', _loadDepreciation),
              ),
              _ReportCard(
                icon: Icons.savings,
                title: 'Capital Account',
                subtitle: 'Capital Account Ledgers',
                color: AppTheme.accentColor,
                onTap: () => _showReport('Capital Account', _loadCapitalAccount),
              ),
              _ReportCard(
                icon: Icons.trending_flat,
                title: 'Capital Movement',
                subtitle: 'Opening, Profit, Drawings',
                color: AppTheme.accentColor,
                onTap: () => _showReport('Capital Movement', () => _api.getCapitalMovement(_fromDate, _toDate)),
              ),
              _ReportCard(
                icon: Icons.credit_card,
                title: 'Loan Schedules',
                subtitle: 'EMI & Principal Breakdown',
                color: Colors.purple,
                onTap: () => _showReport('Loan Schedules', _loadLoanSchedules),
              ),
              _ReportCard(
                icon: Icons.summarize,
                title: 'Turnover Summary',
                subtitle: 'For ITR',
                color: AppTheme.infoColor,
                onTap: () => _showReport('Turnover', () => _api.getTurnoverSummary(_fromDate, _toDate)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBooksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ReportCard(
                icon: Icons.book,
                title: 'Day Book',
                subtitle: 'All transactions by date',
                color: AppTheme.primaryColor,
                onTap: () => _showListReport('Day Book', () => _api.getDayBook(_fromDate, _toDate)),
              ),
              _ReportCard(
                icon: Icons.payments,
                title: 'Cash Book',
                subtitle: 'Cash ledger transactions',
                color: AppTheme.successColor,
                onTap: () => _showListReport('Cash Book', () => _api.getCashBook(_fromDate, _toDate)),
              ),
              _ReportCard(
                icon: Icons.account_balance,
                title: 'Bank Book',
                subtitle: 'Bank ledger transactions',
                color: AppTheme.primaryColor,
                onTap: () => _showListReport('Bank Book', () => _api.getBankBook(_fromDate, _toDate)),
              ),
              _ReportCard(
                icon: Icons.sell,
                title: 'Sales Register',
                subtitle: 'Sales invoices',
                color: AppTheme.successColor,
                onTap: () => _showListReport('Sales Register', () => _api.getSalesRegister(_fromDate, _toDate)),
              ),
              _ReportCard(
                icon: Icons.shopping_cart,
                title: 'Purchase Register',
                subtitle: 'Purchase invoices',
                color: AppTheme.errorColor,
                onTap: () => _showListReport('Purchase Register', () => _api.getPurchaseRegister(_fromDate, _toDate)),
              ),
              _ReportCard(
                icon: Icons.menu_book,
                title: 'Journal Register',
                subtitle: 'Journal vouchers',
                color: AppTheme.secondaryColor,
                onTap: () => _showListReport('Journal Register', () => _api.getJournalRegister(_fromDate, _toDate)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGSTTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ReportCard(
                icon: Icons.description,
                title: 'GSTR-1',
                subtitle: 'B2B, B2C, Export, HSN',
                color: AppTheme.primaryColor,
                onTap: () => _showReport('GSTR-1 Data', () => _api.getGSTR1Data(_fromDate, _toDate)),
              ),
              _ReportCard(
                icon: Icons.summarize,
                title: 'GSTR-3B',
                subtitle: 'Outward tax, ITC, Net payable',
                color: AppTheme.secondaryColor,
                onTap: () => _showReport('GSTR-3B', () => _api.getGSTR3BSummary(_fromDate, _toDate)),
              ),
              _ReportCard(
                icon: Icons.category,
                title: 'Invoice Classification',
                subtitle: 'B2B, B2C, Export',
                color: AppTheme.primaryColor,
                onTap: () => _showReport('Invoice Classification', _loadInvoiceClassification),
              ),
              _ReportCard(
                icon: Icons.table_chart,
                title: 'HSN Summary',
                subtitle: 'HSN-wise Tax Summary',
                color: AppTheme.secondaryColor,
                onTap: () => _showReport('HSN Summary', _loadHSNSummary),
              ),
              _ReportCard(
                icon: Icons.input,
                title: 'ITC',
                subtitle: 'Input Tax Credit',
                color: AppTheme.successColor,
                onTap: () => _showReport('ITC', _loadITC),
              ),
              _ReportCard(
                icon: Icons.track_changes,
                title: 'ITC Tracking',
                subtitle: 'Eligible/ineligible, supplier match',
                color: AppTheme.successColor,
                onTap: () => _showListReport('ITC Tracking', () => _api.getITCTracking(_fromDate, _toDate)),
              ),
              _ReportCard(
                icon: Icons.warning_amber,
                title: 'Mismatch Alerts',
                subtitle: 'ITC 2B, books vs portal',
                color: AppTheme.warningColor,
                onTap: () => _showListReport('Mismatch Alerts', () => _api.getMismatchAlerts()),
              ),
              _ReportCard(
                icon: Icons.payments,
                title: 'Tax Payable',
                subtitle: 'Output Tax - ITC',
                color: AppTheme.errorColor,
                onTap: () => _showReport('Tax Payable', _loadTaxPayable),
              ),
              _ReportCard(
                icon: Icons.edit_note,
                title: 'Amendment',
                subtitle: 'GST Amendments',
                color: AppTheme.accentColor,
                onTap: () => _showReport('Amendments', _loadAmendments),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;
            final fields = [
              _DateField(
                label: 'From',
                date: _fromDate,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _fromDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _fromDate = d);
                },
              ),
              _DateField(
                label: 'To',
                date: _toDate,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _toDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _toDate = d);
                },
              ),
              _DateField(
                label: 'As On (Balance Sheet)',
                date: _asOnDate,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _asOnDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _asOnDate = d);
                },
              ),
            ];

            if (isNarrow) {
              return Column(
                children: [
                  for (int i = 0; i < fields.length; i++) ...[
                    SizedBox(width: double.infinity, child: fields[i]),
                    if (i != fields.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: fields[0]),
                const SizedBox(width: 16),
                Expanded(child: fields[1]),
                const SizedBox(width: 16),
                Expanded(child: fields[2]),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadPandL() =>
      _api.getProfitLoss(_fromDate, _toDate);

  Future<Map<String, dynamic>> _loadBalanceSheet() =>
      _api.getBalanceSheet(_asOnDate);

  Future<Map<String, dynamic>> _loadDepreciation() =>
      _api.getDepreciationReport(_fromDate, _toDate);

  Future<Map<String, dynamic>> _loadCapitalAccount() =>
      _api.getCapitalAccountReport(_fromDate, _toDate);

  Future<Map<String, dynamic>> _loadLoanSchedules() =>
      _api.getLoanSchedules();

  Future<Map<String, dynamic>> _loadInvoiceClassification() =>
      _api.getInvoiceClassification(_fromDate, _toDate);

  Future<Map<String, dynamic>> _loadHSNSummary() async {
    final list = await _api.getGSTHSNSummary(_fromDate, _toDate);
    return {'data': list};
  }

  Future<Map<String, dynamic>> _loadITC() =>
      _api.getITCReport(_fromDate, _toDate);

  Future<Map<String, dynamic>> _loadTaxPayable() =>
      _api.getTaxPayableReport(_fromDate, _toDate);

  Future<Map<String, dynamic>> _loadAmendments() =>
      _api.getGSTAmendments(fromDate: _fromDate, toDate: _toDate);

  void _showReport(String title, Future<Map<String, dynamic>> Function() loader) {
    showDialog(
      context: context,
      builder: (context) => _ReportDialog(
        title: title,
        loader: loader,
      ),
    );
  }

  void _showListReport(String title, Future<List<dynamic>> Function() loader) {
    showDialog(
      context: context,
      builder: (context) => _ReportDialog(
        title: title,
        loader: () async {
          final list = await loader();
          return {'data': list};
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.slate500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  final String title;
  final Future<Map<String, dynamic>> Function() loader;

  const _ReportDialog({
    required this.title,
    required this.loader,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.loader();
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loading ? null : _load,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: AppTheme.errorColor),
                              const SizedBox(height: 16),
                              Text(_error!, textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildReportContent(_data!),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(Map<String, dynamic> data) {
    // Build appropriate content based on report type
    if (data.containsKey('ledgers') && data.containsKey('total_debit')) {
      return _buildTrialBalanceContent(data);
    }
    if (data.containsKey('income') || data.containsKey('expenses') || data.containsKey('sales_revenue')) {
      return _buildPLContent(data);
    }
    if (data.containsKey('assets') || data.containsKey('liabilities') || data.containsKey('capital')) {
      return _buildBalanceSheetContent(data);
    }
    if (data.containsKey('depreciation_schedule')) {
      return _buildDepreciationContent(data);
    }
    if (data.containsKey('ledgers') && !data.containsKey('total_debit')) {
      return _buildCapitalAccountContent(data);
    }
    if (data.containsKey('schedules') || data.containsKey('loans')) {
      return _buildLoanSchedulesContent(data);
    }
    if (data.containsKey('classifications')) {
      return _buildInvoiceClassificationContent(data);
    }
    if (data.containsKey('data') && data['data'] is List) {
      final list = data['data'] as List;
      if (list.isNotEmpty && list.first is Map) {
        return _buildGenericListContent(list);
      }
      return _buildHSNSummaryContent(list);
    }
    if (data.containsKey('b2b') || data.containsKey('b2c_small')) {
      return _buildGSTR1Content(data);
    }
    if (data.containsKey('outward_tax') && data.containsKey('net_payable')) {
      return _buildGSTR3BContent(data);
    }
    if (data.containsKey('total_itc')) {
      return _buildITCContent(data);
    }
    if (data.containsKey('tax_payable')) {
      return _buildTaxPayableContent(data);
    }
    if (data.containsKey('amendments')) {
      return _buildAmendmentsContent(data);
    }
    if (data.containsKey('total_turnover')) {
      return _buildTurnoverContent(data);
    }
    if (data.containsKey('movements')) {
      return _buildCapitalMovementContent(data);
    }

    return _buildGenericContent(data);
  }

  Widget _buildTrialBalanceContent(Map<String, dynamic> data) {
    final ledgers = (data['ledgers'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DataTable(
          columns: const [
            DataColumn(label: Text('Ledger')),
            DataColumn(label: Text('Group')),
            DataColumn(label: Text('Debit'), numeric: true),
            DataColumn(label: Text('Credit'), numeric: true),
          ],
          rows: ledgers.map((r) => DataRow(
            cells: [
              DataCell(Text(r['name']?.toString() ?? '')),
              DataCell(Text(r['group_name']?.toString() ?? '')),
              DataCell(Text(_formatCurrency(r['total_debit']))),
              DataCell(Text(_formatCurrency(r['total_credit']))),
            ],
          )).toList(),
        ),
        const SizedBox(height: 16),
        Text('Total Debit: ${_formatCurrency(data['total_debit'])}  |  Total Credit: ${_formatCurrency(data['total_credit'])}  |  Balanced: ${data['balanced'] ?? false}'),
      ],
    );
  }

  Widget _buildGSTR1Content(Map<String, dynamic> data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((data['b2b'] as List?)?.isNotEmpty == true) ...[
            const Text('B2B Invoices', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${(data['b2b'] as List).length} invoices'),
            const SizedBox(height: 12),
          ],
          if ((data['b2c_small'] as List?)?.isNotEmpty == true) ...[
            const Text('B2C Small', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${(data['b2c_small'] as List).length} invoices'),
            const SizedBox(height: 12),
          ],
          if ((data['b2c_large'] as List?)?.isNotEmpty == true) ...[
            const Text('B2C Large', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${(data['b2c_large'] as List).length} invoices'),
            const SizedBox(height: 12),
          ],
          if ((data['export'] as List?)?.isNotEmpty == true) ...[
            const Text('Export', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${(data['export'] as List).length} invoices'),
            const SizedBox(height: 12),
          ],
          if ((data['hsn_summary'] as List?)?.isNotEmpty == true) ...[
            const Text('HSN Summary', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildHSNSummaryContent(data['hsn_summary'] as List),
          ],
        ],
      ),
    );
  }

  Widget _buildGSTR3BContent(Map<String, dynamic> data) {
    final outward = data['outward_tax'] as Map? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryRow('Outward CGST', outward['cgst']),
        _summaryRow('Outward SGST', outward['sgst']),
        _summaryRow('Outward IGST', outward['igst']),
        _summaryRow('Outward Cess', outward['cess']),
        _summaryRow('Total Outward', outward['total']),
        const Divider(),
        _summaryRow('ITC Available', data['itc_available']),
        _summaryRow('Net Payable', data['net_payable'], bold: true),
      ],
    );
  }

  Widget _buildTurnoverContent(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryRow('Total Turnover', data['total_turnover']),
        _summaryRow('Invoice Count', data['invoice_count']),
      ],
    );
  }

  Widget _buildCapitalMovementContent(Map<String, dynamic> data) {
    final movements = (data['movements'] as List?) ?? [];
    if (movements.isEmpty) {
      return const Text('No capital movement data.');
    }
    return _buildGenericListContent(movements);
  }

  Widget _buildGenericListContent(List<dynamic> list) {
    if (list.isEmpty) return const Text('No data.');
    final first = list.first;
    if (first is! Map) return Text('${list.length} items');
    final keys = first.keys.map((k) => k.toString()).toList();
    return DataTable(
      columns: keys.map((k) => DataColumn(label: Text(k))).toList(),
      rows: list.take(100).map((r) => DataRow(
        cells: keys.map((k) => DataCell(Text(r[k]?.toString() ?? ''))).toList(),
      )).toList(),
    );
  }

  Widget _buildPLContent(Map<String, dynamic> data) {
    final income = (data['income'] as List?) ?? (data['sales_revenue'] as List?) ?? [];
    final otherIncome = (data['other_income'] as List?) ?? [];
    final expenses = (data['expenses'] as List?) ?? (data['direct_expenses'] as List?) ?? [];
    final indirectExp = (data['indirect_expenses'] as List?) ?? [];
    final totalRev = data['total_income'] ?? data['total_revenue'] ?? 0;
    final totalExp = data['total_expenses'] ?? (double.tryParse((data['total_direct_expenses'] ?? 0).toString()) ?? 0) + (double.tryParse((data['total_indirect_expenses'] ?? 0).toString()) ?? 0);
    final netProfit = data['net_profit'] ?? 0;

    final allIncome = [...income, ...otherIncome];
    final allExpenses = [...expenses, ...indirectExp];

    return DataTable(
      columns: const [
        DataColumn(label: Text('Group')),
        DataColumn(label: Text('Ledger')),
        DataColumn(label: Text('Amount'), numeric: true),
      ],
      rows: [
        ...allIncome.map((r) => DataRow(
              cells: [
                DataCell(Text(r['group_name']?.toString() ?? '')),
                DataCell(Text(r['name']?.toString() ?? r['ledger_name']?.toString() ?? '')),
                DataCell(Text(_formatCurrency(r['amount']))),
              ],
            )),
        DataRow(cells: [
          const DataCell(Text('')),
          DataCell(Text('Total Income', style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(_formatCurrency(totalRev), style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
        ...allExpenses.map((r) => DataRow(
              cells: [
                DataCell(Text(r['group_name']?.toString() ?? '')),
                DataCell(Text(r['name']?.toString() ?? r['ledger_name']?.toString() ?? '')),
                DataCell(Text(_formatCurrency(r['amount']))),
              ],
            )),
        DataRow(cells: [
          const DataCell(Text('')),
          DataCell(Text('Total Expenses', style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(_formatCurrency(totalExp), style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
        DataRow(cells: [
          const DataCell(Text('')),
          DataCell(Text('Net Profit', style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(_formatCurrency(netProfit), style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
      ],
    );
  }

  static String _formatCurrency(dynamic value) {
    if (value == null) return '₹0.00';
    final n = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
    return '₹${n.toStringAsFixed(2)}';
  }

  Widget _buildBalanceSheetContent(Map<String, dynamic> data) {
    final assets = (data['assets'] as List?) ?? [];
    final liabilities = (data['liabilities'] as List?) ?? [];
    final capital = (data['capital'] as List?) ?? [];
    return DataTable(
      columns: const [
        DataColumn(label: Text('Group')),
        DataColumn(label: Text('Ledger')),
        DataColumn(label: Text('Balance'), numeric: true),
      ],
      rows: [
        ...assets.map((r) => DataRow(
              cells: [
                DataCell(Text(r['group_name']?.toString() ?? '')),
                DataCell(Text(r['name']?.toString() ?? r['ledger_name']?.toString() ?? '')),
                DataCell(Text(_formatCurrency(r['balance'] ?? r['current_balance']))),
              ],
            )),
        if (data.containsKey('total_assets'))
          DataRow(cells: [
            const DataCell(Text('')),
            DataCell(Text('Total Assets', style: TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(_formatCurrency(data['total_assets']), style: TextStyle(fontWeight: FontWeight.bold))),
          ]),
        ...liabilities.map((r) => DataRow(
              cells: [
                DataCell(Text(r['group_name']?.toString() ?? '')),
                DataCell(Text(r['name']?.toString() ?? r['ledger_name']?.toString() ?? '')),
                DataCell(Text(_formatCurrency(r['balance'] ?? r['current_balance']))),
              ],
            )),
        ...capital.map((r) => DataRow(
              cells: [
                const DataCell(Text('Capital')),
                DataCell(Text(r['name']?.toString() ?? '')),
                DataCell(Text(_formatCurrency(r['current_balance'] ?? r['balance']))),
              ],
            )),
        if (data.containsKey('total_liabilities'))
          DataRow(cells: [
            const DataCell(Text('')),
            DataCell(Text('Total Liabilities & Capital', style: TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(_formatCurrency(data['total_liabilities']), style: TextStyle(fontWeight: FontWeight.bold))),
          ]),
      ],
    );
  }

  Widget _buildDepreciationContent(Map<String, dynamic> data) {
    final schedule = (data['depreciation_schedule'] as List?) ?? [];
    if (schedule.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No depreciation data. Add fixed assets first.'),
      );
    }
    return DataTable(
      columns: const [
        DataColumn(label: Text('Asset')),
        DataColumn(label: Text('Period')),
        DataColumn(label: Text('Depreciation'), numeric: true),
        DataColumn(label: Text('Closing WDV'), numeric: true),
      ],
      rows: schedule.map((r) => DataRow(
            cells: [
              DataCell(Text(r['asset_name']?.toString() ?? '')),
              DataCell(Text('${r['period_from']} to ${r['period_to']}')),
              DataCell(Text(_formatCurrency(r['depreciation_amount']))),
              DataCell(Text(_formatCurrency(r['closing_wdv']))),
            ],
          )).toList(),
    );
  }

  Widget _buildCapitalAccountContent(Map<String, dynamic> data) {
    final ledgers = (data['ledgers'] as List?) ?? [];
    if (ledgers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No capital account ledgers found.'),
      );
    }
    return DataTable(
      columns: const [
        DataColumn(label: Text('Ledger')),
        DataColumn(label: Text('Debit'), numeric: true),
        DataColumn(label: Text('Credit'), numeric: true),
        DataColumn(label: Text('Balance'), numeric: true),
      ],
      rows: [
        ...ledgers.map((r) => DataRow(
              cells: [
                DataCell(Text(r['name']?.toString() ?? '')),
                DataCell(Text(_formatCurrency(r['total_debit']))),
                DataCell(Text(_formatCurrency(r['total_credit']))),
                DataCell(Text(_formatCurrency(r['current_balance']))),
              ],
            )),
        DataRow(cells: [
          DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text(_formatCurrency(data['total']), style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
      ],
    );
  }

  Widget _buildLoanSchedulesContent(Map<String, dynamic> data) {
    final schedules = (data['schedules'] as List?) ?? [];
    final loans = (data['loans'] as List?) ?? [];
    if (schedules.isEmpty && loans.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No loan schedules. Add loans first.'),
      );
    }
    if (schedules.isNotEmpty) {
      return DataTable(
        columns: const [
          DataColumn(label: Text('Installment')),
          DataColumn(label: Text('Due Date')),
          DataColumn(label: Text('Principal'), numeric: true),
          DataColumn(label: Text('Interest'), numeric: true),
          DataColumn(label: Text('EMI'), numeric: true),
          DataColumn(label: Text('Status')),
        ],
        rows: schedules.map((r) => DataRow(
              cells: [
                DataCell(Text(r['installment_number']?.toString() ?? '')),
                DataCell(Text(r['due_date']?.toString() ?? '')),
                DataCell(Text(_formatCurrency(r['principal_amount']))),
                DataCell(Text(_formatCurrency(r['interest_amount']))),
                DataCell(Text(_formatCurrency(r['emi_amount']))),
                DataCell(Text(r['status']?.toString() ?? '')),
              ],
            )).toList(),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text('${loans.length} loan(s) found. Select a loan to view schedule.'),
    );
  }

  Widget _buildInvoiceClassificationContent(Map<String, dynamic> data) {
    final classifications = (data['classifications'] as List?) ?? [];
    return DataTable(
      columns: const [
        DataColumn(label: Text('Classification')),
        DataColumn(label: Text('Invoices'), numeric: true),
        DataColumn(label: Text('Taxable'), numeric: true),
        DataColumn(label: Text('CGST'), numeric: true),
        DataColumn(label: Text('SGST'), numeric: true),
        DataColumn(label: Text('IGST'), numeric: true),
        DataColumn(label: Text('Total Tax'), numeric: true),
      ],
      rows: classifications.map((r) => DataRow(
            cells: [
              DataCell(Text(r['classification']?.toString() ?? '')),
              DataCell(Text(r['invoice_count']?.toString() ?? '0')),
              DataCell(Text(_formatCurrency(r['taxable_amount']))),
              DataCell(Text(_formatCurrency(r['cgst']))),
              DataCell(Text(_formatCurrency(r['sgst']))),
              DataCell(Text(_formatCurrency(r['igst']))),
              DataCell(Text(_formatCurrency(r['total_tax']))),
            ],
          )).toList(),
    );
  }

  Widget _buildHSNSummaryContent(List<dynamic> data) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No HSN summary data for selected period.'),
      );
    }
    return DataTable(
      columns: const [
        DataColumn(label: Text('HSN')),
        DataColumn(label: Text('Qty'), numeric: true),
        DataColumn(label: Text('Taxable'), numeric: true),
        DataColumn(label: Text('GST %'), numeric: true),
        DataColumn(label: Text('CGST'), numeric: true),
        DataColumn(label: Text('SGST'), numeric: true),
        DataColumn(label: Text('IGST'), numeric: true),
        DataColumn(label: Text('Total Tax'), numeric: true),
      ],
      rows: data.map((r) => DataRow(
            cells: [
              DataCell(Text(r['hsn_code']?.toString() ?? '')),
              DataCell(Text(r['quantity']?.toString() ?? '0')),
              DataCell(Text(_formatCurrency(r['taxable_amount']))),
              DataCell(Text('${r['gst_rate'] ?? 0}%')),
              DataCell(Text(_formatCurrency(r['cgst_amount']))),
              DataCell(Text(_formatCurrency(r['sgst_amount']))),
              DataCell(Text(_formatCurrency(r['igst_amount']))),
              DataCell(Text(_formatCurrency(r['total_tax']))),
            ],
          )).toList(),
    );
  }

  Widget _buildITCContent(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryRow('Total ITC', data['total_itc']),
        if (data['expense_itc'] != null)
          ...(data['expense_itc'] as List).map((e) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Category ${e['category_id']}: ${_formatCurrency(e['itc_amount'])}'),
              )),
      ],
    );
  }

  Widget _buildTaxPayableContent(Map<String, dynamic> data) {
    final output = data['output_tax'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryRow('Output Tax (CGST)', output['cgst']),
        _summaryRow('Output Tax (SGST)', output['sgst']),
        _summaryRow('Output Tax (IGST)', output['igst']),
        _summaryRow('Output Tax (Cess)', output['cess']),
        _summaryRow('Total Output', output['total']),
        const Divider(),
        _summaryRow('ITC Available', data['itc_available']),
        _summaryRow('Tax Payable', data['tax_payable'], bold: true),
      ],
    );
  }

  Widget _summaryRow(String label, dynamic value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(_formatCurrency(value), style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildAmendmentsContent(Map<String, dynamic> data) {
    final amendments = (data['amendments'] as List?) ?? [];
    if (amendments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No amendments for selected period.'),
      );
    }
    return DataTable(
      columns: const [
        DataColumn(label: Text('Invoice')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Original')),
        DataColumn(label: Text('Revised')),
        DataColumn(label: Text('Date')),
      ],
      rows: amendments.map((r) => DataRow(
            cells: [
              DataCell(Text(r['invoice_number']?.toString() ?? '')),
              DataCell(Text(r['amendment_type']?.toString() ?? '')),
              DataCell(Text(_formatCurrency(r['original_value']))),
              DataCell(Text(_formatCurrency(r['revised_value']))),
              DataCell(Text(r['amendment_date']?.toString() ?? '')),
            ],
          )).toList(),
    );
  }

  Widget _buildGenericContent(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('${e.key}: ${e.value}'),
          )).toList(),
    );
  }
}
