/// Statements Screen
/// View firm's credit and debit ledger with invoices, notes, payments, and balance
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StatementsScreen extends StatefulWidget {
  const StatementsScreen({super.key});

  @override
  State<StatementsScreen> createState() => _StatementsScreenState();
}

class _StatementsScreenState extends State<StatementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _apiService;

  // Data
  List<Ledger> _parties = [];
  PartyStatement? _currentStatement;
  Ledger? _selectedParty;

  // Filters
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 180));
  DateTime _toDate = DateTime.now();
  StatementTransactionType? _selectedTransactionType;

  // UI State
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _apiService = ApiService();
    _loadParties();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadParties() async {
    try {
      setState(() => _isLoading = true);
      final partiesData = await _apiService.getParties();
      // Convert Map<String, dynamic> to Ledger objects
      final ledgers = partiesData.map((p) => Ledger.fromJson(p)).toList();
      setState(() {
        _parties = ledgers;
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

  Future<void> _loadStatement() async {
    if (_selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a party first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final statement = await _apiService.getPartyStatement(
        partyId: _selectedParty!.id!,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      setState(() {
        _currentStatement = statement;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load statement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTransactionTypeLabel(StatementTransactionType type) {
    switch (type) {
      case StatementTransactionType.invoice:
        return 'Invoice';
      case StatementTransactionType.creditNote:
        return 'Credit Note';
      case StatementTransactionType.debitNote:
        return 'Debit Note';
      case StatementTransactionType.payment:
        return 'Payment';
      case StatementTransactionType.receipt:
        return 'Receipt';
      case StatementTransactionType.openingBalance:
        return 'Opening Balance';
      case StatementTransactionType.closingBalance:
        return 'Closing Balance';
    }
  }

  Color _getTransactionColor(StatementTransactionType type) {
    switch (type) {
      case StatementTransactionType.invoice:
      case StatementTransactionType.debitNote:
        return Colors.red;
      case StatementTransactionType.creditNote:
      case StatementTransactionType.payment:
      case StatementTransactionType.receipt:
        return Colors.green;
      case StatementTransactionType.openingBalance:
      case StatementTransactionType.closingBalance:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statements'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Party Selection
                  _buildPartySelector(),

                  if (_selectedParty != null) ...[
                    // Date Range & Filters
                    _buildFilters(),

                    // Load Statement Button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loadStatement,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Load Statement'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    // Statement Summary
                    if (_currentStatement != null) ...[
                      _buildStatementSummary(),
                      const SizedBox(height: 12),
                    ],

                    // Tabbed Transaction View
                    if (_currentStatement != null)
                      _buildTransactionTabs(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPartySelector() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Party',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Autocomplete<Ledger>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _parties;
              }
              return _parties
                  .where((party) => party.name
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()))
                  .toList();
            },
            onSelected: (Ledger selection) {
              setState(() => _selectedParty = selection);
            },
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Search party by name or GSTIN',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Material(
                elevation: 4,
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      title: Text(option.name),
                      subtitle: Text(option.gstin ?? 'No GSTIN'),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              );
            },
          ),
          if (_selectedParty != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: Text(_selectedParty!.name),
                onDeleted: () =>
                    setState(() => _selectedParty = null),
                backgroundColor: AppTheme.primaryColor,
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date Range Selection
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'From Date',
                  selectedDate: _fromDate,
                  onDateChanged: (date) =>
                      setState(() => _fromDate = date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  label: 'To Date',
                  selectedDate: _toDate,
                  onDateChanged: (date) =>
                      setState(() => _toDate = date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Transaction Type Filter
          DropdownButtonFormField<StatementTransactionType>(
            value: _selectedTransactionType,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Transactions'),
              ),
              ...StatementTransactionType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_getTransactionTypeLabel(type)),
                    ),
                  )
                  .toList(),
            ],
            onChanged: (value) =>
                setState(() => _selectedTransactionType = value),
            decoration: InputDecoration(
              labelText: 'Transaction Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime selectedDate,
    required Function(DateTime) onDateChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('dd/MM/yyyy').format(selectedDate),
        ),
      ),
    );
  }

  Widget _buildStatementSummary() {
    final summary = _currentStatement!.summary;
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statement Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryBox(
                      label: 'Opening Balance',
                      amount: summary.openingBalance,
                      type: summary.openingBalanceType,
                      formatter: formatter,
                      bgColor: Colors.blue[50],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryBox(
                      label: 'Total Debit',
                      amount: summary.totalDebit,
                      type: 'DR',
                      formatter: formatter,
                      bgColor: Colors.red[50],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryBox(
                      label: 'Total Credit',
                      amount: summary.totalCredit,
                      type: 'CR',
                      formatter: formatter,
                      bgColor: Colors.green[50],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryBox(
                      label: 'Closing Balance',
                      amount: summary.closingBalance.abs(),
                      type: summary.closingBalanceType,
                      formatter: formatter,
                      bgColor: Colors.purple[50],
                      isHighlight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Credit Limit',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${formatter.format(summary.creditLimit)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Credit',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${formatter.format(summary.availableCredit.abs())}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: summary.availableCredit >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Last Transaction',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary.lastTransactionDate != null
                              ? DateFormat('dd/MM/yyyy')
                                  .format(summary.lastTransactionDate!)
                              : 'Never',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _buildSummaryBox({
    required String label,
    required double amount,
    required String type,
    required NumberFormat formatter,
    Color? bgColor,
    bool isHighlight = false,
  }) {
    final isDebit = type == 'DR';
    final isCredit = type == 'CR';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: isHighlight
            ? Border.all(color: Colors.purple, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: '₹',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                TextSpan(
                  text: formatter.format(amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDebit
                        ? Colors.red
                        : isCredit
                            ? Colors.green
                            : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isDebit ? 'Debit' : 'Credit',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTabs() {
    final statement = _currentStatement!;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(
              icon: const Icon(Icons.receipt_long),
              text: 'All (${statement.transactions.length})',
            ),
            Tab(
              icon: const Icon(Icons.document_scanner),
              text: 'Invoices (${statement.invoices.length})',
            ),
            Tab(
              icon: const Icon(Icons.note_add),
              text: 'Credit Notes (${statement.creditNotes.length})',
            ),
            Tab(
              icon: const Icon(Icons.note_add),
              text: 'Debit Notes (${statement.debitNotes.length})',
            ),
            Tab(
              icon: const Icon(Icons.payment),
              text: 'Payments (${statement.payments.length})',
            ),
          ],
        ),
        Container(
          color: Colors.white,
          height: 500, // Adjust height as needed
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionList(statement.transactions),
              _buildTransactionList(statement.invoices),
              _buildTransactionList(statement.creditNotes),
              _buildTransactionList(statement.debitNotes),
              _buildTransactionList(statement.payments),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<StatementTransaction> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final formatter = NumberFormat('#,##,##0.00', 'en_IN');

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final txn = transactions[index];
        final color = _getTransactionColor(txn.type);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.receipt_long,
                color: color,
                size: 20,
              ),
            ),
            title: Text(
              txn.referenceNumber,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTransactionTypeLabel(txn.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(txn.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (txn.debitAmount > 0)
                  Text(
                    '₹${formatter.format(txn.debitAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                if (txn.creditAmount > 0)
                  Text(
                    '₹${formatter.format(txn.creditAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '₹${formatter.format(txn.runningBalance.abs())}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              _showTransactionDetails(txn);
            },
          ),
        );
      },
    );
  }

  void _showTransactionDetails(StatementTransaction txn) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Reference Number', txn.referenceNumber),
              _buildDetailRow(
                'Date',
                DateFormat('dd MMM yyyy').format(txn.date),
              ),
              _buildDetailRow(
                'Type',
                _getTransactionTypeLabel(txn.type),
              ),
              _buildDetailRow(
                'Description',
                txn.description,
              ),
              if (txn.debitAmount > 0)
                _buildDetailRow(
                  'Debit Amount',
                  '₹${formatter.format(txn.debitAmount)}',
                  color: Colors.red,
                ),
              if (txn.creditAmount > 0)
                _buildDetailRow(
                  'Credit Amount',
                  '₹${formatter.format(txn.creditAmount)}',
                  color: Colors.green,
                ),
              _buildDetailRow(
                'Running Balance',
                '₹${formatter.format(txn.runningBalance.abs())}',
                color: Colors.blue,
              ),
              if (txn.narration != null)
                _buildDetailRow('Narration', txn.narration!),
            ],
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
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
