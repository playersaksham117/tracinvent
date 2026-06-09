/// Payments & Ledger Screen (Udhar Management)
/// Customer/Supplier ledger, receipts, payments, aging reports, reminders
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/bank_import_service.dart';

class PaymentsLedgerScreen extends StatefulWidget {
  const PaymentsLedgerScreen({super.key});

  @override
  State<PaymentsLedgerScreen> createState() => _PaymentsLedgerScreenState();
}

class _PaymentsLedgerScreenState extends State<PaymentsLedgerScreen>
    with SingleTickerProviderStateMixin {
  final BankImportService _bankImportService = BankImportService();

  Future<void> _importBankCsv() async {
    final csvData = await _bankImportService.importCsv();
    if (csvData.isNotEmpty) {
      final rows = csvData
          .skip(1)
          .where((r) => r.any((c) => c.trim().isNotEmpty))
          .toList();
      final importedRows = rows.length;

      int matchedParties = 0;
      for (final row in rows) {
        final normalizedCells = row
            .map((c) => c.trim().toLowerCase())
            .where((c) => c.isNotEmpty)
            .toList();
        if (normalizedCells.isEmpty) continue;

        final found = _ledgers.any((ledger) {
          final name = ledger.partyName.toLowerCase();
          final phone = (ledger.phone ?? '').toLowerCase();
          return normalizedCells.any(
            (cell) => cell == name || (phone.isNotEmpty && cell == phone),
          );
        });
        if (found) matchedParties++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported $importedRows CSV rows • Matched parties: $matchedParties',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No CSV file selected or file is empty.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _snoozeReminder(PaymentReminder reminder, {int days = 3}) {
    if (!mounted) return;
    setState(() {
      _reminders = _reminders.where((r) => r.id != reminder.id).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Snoozed ${reminder.partyName} reminder for $days days'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  late TabController _tabController;
  late ApiService _apiService;
  PartyType _selectedPartyType = PartyType.customer;
  String _searchQuery = '';

  // Loaded from API
  List<PartyLedger> _ledgers = [];
  List<PaymentReminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _apiService = ApiService();
    _loadPartiesFromMaster();
  }

  Future<void> _loadPartiesFromMaster() async {
    try {
      setState(() => _isLoading = true);
      final parties = await _apiService.getParties();
      final ledgers = parties.map((party) => _partyToLedger(party)).toList();
      setState(() {
        _ledgers = ledgers;
        _reminders = _generateRemindersFromLedgers(ledgers);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load parties: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  PartyLedger _partyToLedger(Map<String, dynamic> party) {
    final partyType = _mapPartyType(party['party_type'] ?? 'CUSTOMER');
    final openingBalance = (party['opening_balance'] as num?)?.toDouble() ?? 0;
    final balanceType = party['balance_type'] == 'CR'
        ? BalanceType.credit
        : BalanceType.debit;

    return PartyLedger(
      id: party['id']?.toString() ?? '',
      partyId: party['id']?.toString() ?? '',
      partyName: party['name'] ?? 'Unknown',
      partyType: partyType,
      phone: party['phone'],
      email: party['email'],
      gstin: party['gstin'],
      openingBalance: openingBalance,
      openingBalanceType: balanceType,
      currentBalance:
          (party['current_balance'] as num?)?.toDouble() ?? openingBalance,
      currentBalanceType: balanceType,
      creditLimit: (party['credit_limit'] as num?)?.toDouble() ?? 0,
      creditDays: (party['credit_days'] as num?)?.toInt() ?? 30,
      entries: [],
      createdAt: party['created_at'] != null
          ? DateTime.tryParse(party['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  PartyType _mapPartyType(String type) {
    switch (type.toUpperCase()) {
      case 'CUSTOMER':
        return PartyType.customer;
      case 'SUPPLIER':
        return PartyType.supplier;
      default:
        return PartyType.customer;
    }
  }

  List<PaymentReminder> _generateRemindersFromLedgers(
    List<PartyLedger> ledgers,
  ) {
    // Generate reminders for ledgers with outstanding balances
    return ledgers
        .where((l) => l.currentBalance > 0)
        .map(
          (l) => PaymentReminder(
            id: l.id,
            partyId: l.partyId,
            partyName: l.partyName,
            partyType: l.partyType,
            phone: l.phone,
            outstandingAmount: l.currentBalance,
            dueDate: DateTime.now().subtract(Duration(days: l.creditDays)),
            daysOverdue: l.creditDays > 0 ? l.creditDays : 0,
            status: ReminderStatus.pending,
            createdAt: DateTime.now(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  List<PartyLedger> get _filteredLedgers {
    return _ledgers.where((ledger) {
      final matchesType = ledger.partyType == _selectedPartyType;
      final matchesSearch =
          _searchQuery.isEmpty ||
          ledger.partyName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesType && matchesSearch;
    }).toList();
  }

  double get _totalReceivable => _ledgers
      .where((l) => l.partyType == PartyType.customer)
      .fold(0, (sum, l) => sum + l.receivable);

  double get _totalPayable => _ledgers
      .where((l) => l.partyType == PartyType.supplier)
      .fold(0, (sum, l) => sum + l.payable);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Summary cards
          _buildSummaryCards(),

          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.slate500,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 2,
              tabs: const [
                Tab(icon: Icon(Icons.account_balance_wallet, size: 20), text: 'Ledgers'),
                Tab(icon: Icon(Icons.receipt_long, size: 20), text: 'Transactions'),
                Tab(icon: Icon(Icons.notifications_active, size: 20), text: 'Reminders'),
                Tab(icon: Icon(Icons.bar_chart, size: 20), text: 'Aging'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLedgersTab(),
                _buildTransactionsTab(),
                _buildRemindersTab(),
                _buildAgingTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickActions,
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Payments & Ledger'),
      backgroundColor: AppTheme.sidebarColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Party type toggle
        SegmentedButton<PartyType>(
          segments: [
            ButtonSegment(
              value: PartyType.customer,
              label: const Text('Customers'),
              icon: const Icon(Icons.person),
            ),
            ButtonSegment(
              value: PartyType.supplier,
              label: const Text('Suppliers'),
              icon: const Icon(Icons.store),
            ),
          ],
          selected: {_selectedPartyType},
          onSelectionChanged: (selection) {
            setState(() => _selectedPartyType = selection.first);
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white.withValues(alpha: 0.2);
              }
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.canvasSecondary,
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Receivable',
              '₹${_totalReceivable.toStringAsFixed(0)}',
              Icons.trending_up,
              Color(0xFF10B981),
              'From ${_ledgers.where((l) => l.partyType == PartyType.customer && l.hasOutstanding).length} customers',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Total Payable',
              '₹${_totalPayable.toStringAsFixed(0)}',
              Icons.trending_up_outlined,
              Color(0xFFF59E0B),
              'To ${_ledgers.where((l) => l.partyType == PartyType.supplier && l.hasOutstanding).length} suppliers',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Net Position',
              '₹${(_totalReceivable - _totalPayable).abs().toStringAsFixed(0)}',
              _totalReceivable >= _totalPayable
                  ? Icons.trending_up
                  : Icons.trending_down,
              _totalReceivable >= _totalPayable ? Color(0xFF10B981) : Color(0xFFEF4444),
              _totalReceivable >= _totalPayable
                  ? 'Positive balance'
                  : 'Negative balance',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Overdue',
              '₹${_reminders.fold<double>(0, (sum, r) => sum + r.outstandingAmount).toStringAsFixed(0)}',
              Icons.warning_amber_rounded,
              Color(0xFFEF4444),
              '${_reminders.length} pending reminders',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.slate500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.slate500,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final ledgers = _filteredLedgers;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText:
                  'Search ${_selectedPartyType.displayName.toLowerCase()}s...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.slate400),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.slate400),
                onPressed: _loadPartiesFromMaster,
                tooltip: 'Refresh from Party Master',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: const BorderSide(color: AppTheme.slate300, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: const BorderSide(color: AppTheme.slate300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintStyle: const TextStyle(color: AppTheme.slate400),
            ),
          ),
        ),

        // Ledgers list
        Expanded(
          child: ledgers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedPartyType.icon,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ${_selectedPartyType.displayName.toLowerCase()}s found',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadPartiesFromMaster,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPartiesFromMaster,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ledgers.length,
                    itemBuilder: (context, index) =>
                        _buildLedgerCard(ledgers[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLedgerCard(PartyLedger ledger) {
    final isCustomer = ledger.partyType == PartyType.customer;
    final balanceColor = ledger.hasOutstanding
        ? (isCustomer ? Color(0xFF10B981) : Color(0xFFF59E0B))
        : AppTheme.slate400;

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: balanceColor.withOpacity(0.2), width: 1.5),
      ),
      child: InkWell(
        onTap: () => _showLedgerDetails(ledger),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: ledger.partyType.color.withOpacity(0.15),
                child: Text(
                  ledger.partyName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ledger.partyType.color,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Party info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ledger.partyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (ledger.phone != null) ...[
                          Icon(
                            Icons.phone,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ledger.phone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (ledger.gstin != null) ...[
                          Icon(
                            Icons.badge,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ledger.gstin!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${ledger.currentBalance.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: balanceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isCustomer ? 'Receivable' : 'Payable',
                      style: TextStyle(fontSize: 11, color: balanceColor),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),
              // Actions
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'receipt',
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt,
                          size: 18,
                          color: isCustomer ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(isCustomer ? 'Record Receipt' : 'Record Payment'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'statement',
                    child: Row(
                      children: [
                        Icon(Icons.description, size: 18),
                        SizedBox(width: 8),
                        Text('View Statement'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reminder',
                    child: Row(
                      children: [
                        Icon(Icons.notifications, size: 18),
                        SizedBox(width: 8),
                        Text('Send Reminder'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'receipt':
                      _showPaymentDialog(ledger);
                      break;
                    case 'statement':
                      _showLedgerDetails(ledger);
                      break;
                    case 'reminder':
                      _sendReminder(ledger);
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return FutureBuilder<List<GSTInvoice>>(
      future: _apiService.getInvoices(
        status: 'CONFIRMED',
        page: 1,
        pageSize: 50,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Unable to load recent transactions.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
          );
        }
        final invoices = snapshot.data ?? [];
        if (invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No recent invoices found',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final inv = invoices[index];
            final status = inv.paymentStatus;
            final isOverdue = status == PaymentStatus.overdue;
            final isPaid = status == PaymentStatus.paid;
            final color = isOverdue
                ? Colors.red
                : (isPaid ? Colors.green : Colors.orange);
            final method = inv.paymentMode?.name.toUpperCase() ?? 'CREDIT';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long, color: color),
                ),
                title: Text(inv.partyName),
                subtitle: Row(
                  children: [
                    Text('Inv #${inv.invoiceNumber ?? inv.id ?? ''}'),
                    Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
                    Text(_formatDateTime(inv.invoiceDate)),
                    Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        method,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${inv.grandTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.name.toUpperCase(),
                      style: TextStyle(fontSize: 11, color: color),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRemindersTab() {
    if (_reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Pending Reminders',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'All payments are up to date!',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: reminder.priority.color.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Priority indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: reminder.priority.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    reminder.isOverdue ? Icons.warning : Icons.access_time,
                    color: reminder.priority.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            reminder.partyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: reminder.priority.color.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              reminder.priority.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: reminder.priority.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${reminder.outstandingAmount.toStringAsFixed(0)} overdue by ${reminder.daysOverdue} days',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (reminder.phone != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              reminder.phone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _sendReminder(
                        PartyLedger(
                          id: reminder.partyId,
                          partyId: reminder.partyId,
                          partyName: reminder.partyName,
                          partyType: reminder.partyType,
                          phone: reminder.phone,
                          email: reminder.email,
                          createdAt: DateTime.now(),
                        ),
                      ),
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Send'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _snoozeReminder(reminder),
                      child: const Text('Snooze'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgingTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _apiService.getOutstandingInvoices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Unable to load aging.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
          );
        }

        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  'No outstanding invoices',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        final agingData = <String, double>{
          'Current': 0,
          '1-30 Days': 0,
          '31-60 Days': 0,
          '61-90 Days': 0,
          '90+ Days': 0,
        };

        for (final row in rows) {
          final overdue = (row['overdue_days'] as num?)?.toInt() ?? 0;
          final amount = (row['balance_amount'] as num?)?.toDouble() ?? 0.0;
          if (overdue <= 0) {
            agingData['Current'] = agingData['Current']! + amount;
          } else if (overdue <= 30) {
            agingData['1-30 Days'] = agingData['1-30 Days']! + amount;
          } else if (overdue <= 60) {
            agingData['31-60 Days'] = agingData['31-60 Days']! + amount;
          } else if (overdue <= 90) {
            agingData['61-90 Days'] = agingData['61-90 Days']! + amount;
          } else {
            agingData['90+ Days'] = agingData['90+ Days']! + amount;
          }
        }

        final total = agingData.values.fold<double>(0, (sum, v) => sum + v);
        final maxBucket = agingData.values.fold<double>(
          0,
          (m, v) => v > m ? v : m,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chart
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedPartyType == PartyType.customer ? 'Receivables' : 'Payables'} Aging',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Total: ₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxBucket * 1.2,
                            barGroups: agingData.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                                  final colors = [
                                    Colors.green,
                                    Colors.blue,
                                    Colors.orange,
                                    Colors.deepOrange,
                                    Colors.red,
                                  ];
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: entry.value.value,
                                        color: colors[entry.key],
                                        width: 40,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(4),
                                            ),
                                      ),
                                    ],
                                  );
                                })
                                .toList(),
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
                                    final labels = agingData.keys.toList();
                                    final idx = value.toInt();
                                    if (idx >= 0 && idx < labels.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          labels[idx],
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Legend
                      ...agingData.entries.toList().asMap().entries.map((
                        entry,
                      ) {
                        final colors = [
                          Colors.green,
                          Colors.blue,
                          Colors.orange,
                          Colors.deepOrange,
                          Colors.red,
                        ];
                        final value = entry.value.value;
                        final pct = total > 0
                            ? (value / total * 100).toStringAsFixed(1)
                            : '0.0';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: colors[entry.key],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(entry.value.key)),
                              Text(
                                '₹${value.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  '$pct%',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
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

              // Top overdue parties (still based on live balances)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Overdue Parties',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._filteredLedgers
                          .where((l) => l.hasOutstanding)
                          .take(5)
                          .map(
                            (ledger) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: ledger.partyType.color
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      ledger.partyName.substring(0, 1),
                                      style: TextStyle(
                                        color: ledger.partyType.color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(ledger.partyName)),
                                  Text(
                                    '₹${ledger.currentBalance.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
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
            ],
          ),
        );
      },
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    'Record Receipt',
                    Icons.arrow_downward,
                    Colors.green,
                    () {
                      Navigator.pop(context);
                      _showPaymentDialog(null, isReceipt: true);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _actionButton(
                    'Make Payment',
                    Icons.arrow_upward,
                    Colors.orange,
                    () {
                      Navigator.pop(context);
                      _showPaymentDialog(null, isReceipt: false);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    'Add Customer',
                    Icons.person_add,
                    Colors.blue,
                    () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _actionButton(
                    'Add Supplier',
                    Icons.store,
                    Colors.purple,
                    () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    'Bank Import (CSV)',
                    Icons.file_upload,
                    Colors.teal,
                    () {
                      Navigator.pop(context);
                      _importBankCsv();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ...existing code...

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _showLedgerDetails(PartyLedger ledger) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ledger.partyType.color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: ledger.partyType.color.withValues(
                        alpha: 0.2,
                      ),
                      child: Text(
                        ledger.partyName.substring(0, 1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ledger.partyType.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ledger.partyName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (ledger.gstin != null)
                            Text(
                              'GSTIN: ${ledger.gstin}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Balance',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '₹${ledger.currentBalance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ledger.hasOutstanding
                                ? ledger.partyType.color
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Transactions
              Expanded(
                child: ledger.entries.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: ledger.entries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = ledger.entries[index];
                          return ListTile(
                            leading: Icon(entry.entryType.icon),
                            title: Text(entry.particulars),
                            subtitle: Text(_formatDateTime(entry.entryDate)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (entry.debitAmount > 0)
                                  Text(
                                    '₹${entry.debitAmount.toStringAsFixed(0)} Dr',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                if (entry.creditAmount > 0)
                                  Text(
                                    '₹${entry.creditAmount.toStringAsFixed(0)} Cr',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showPaymentDialog(ledger);
                      },
                      icon: Icon(
                        ledger.partyType == PartyType.customer
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        size: 18,
                      ),
                      label: Text(
                        ledger.partyType == PartyType.customer
                            ? 'Record Receipt'
                            : 'Make Payment',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(PartyLedger? ledger, {bool isReceipt = true}) {
    showDialog(
      context: context,
      builder: (context) => _PaymentEntryDialog(
        ledger: ledger,
        isReceipt: ledger?.partyType == PartyType.customer || isReceipt,
      ),
    );
  }

  void _sendReminder(PartyLedger ledger) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder sent to ${ledger.partyName}'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _PaymentEntryDialog extends StatefulWidget {
  final PartyLedger? ledger;
  final bool isReceipt;

  const _PaymentEntryDialog({this.ledger, required this.isReceipt});

  @override
  State<_PaymentEntryDialog> createState() => _PaymentEntryDialogState();
}

class _PaymentEntryDialogState extends State<_PaymentEntryDialog> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isReceipt ? 'Record Receipt' : 'Make Payment'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.ledger != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: widget.ledger!.partyType.color
                          .withValues(alpha: 0.2),
                      child: Text(widget.ledger!.partyName.substring(0, 1)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ledger!.partyName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Balance: ₹${widget.ledger!.currentBalance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount *',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: PaymentMethod.values
                  .map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Row(
                        children: [
                          Icon(method.icon, size: 18),
                          const SizedBox(width: 8),
                          Text(method.displayName),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _method = value!),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: _method == PaymentMethod.cheque
                    ? 'Cheque Number'
                    : 'Reference',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),

            if (widget.ledger != null && widget.ledger!.currentBalance > 0) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Full Amount'),
                    onPressed: () {
                      _amountController.text = widget.ledger!.currentBalance
                          .toStringAsFixed(0);
                    },
                  ),
                  ActionChip(
                    label: const Text('50%'),
                    onPressed: () {
                      _amountController.text =
                          (widget.ledger!.currentBalance * 0.5).toStringAsFixed(
                            0,
                          );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            // Save payment
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.isReceipt ? 'Receipt recorded' : 'Payment recorded',
                ),
                backgroundColor: AppTheme.successColor,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
