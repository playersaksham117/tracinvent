/// Expense & Other Income Screen
library;

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ExpenseIncomeScreen extends StatefulWidget {
  const ExpenseIncomeScreen({super.key});

  @override
  State<ExpenseIncomeScreen> createState() => _ExpenseIncomeScreenState();
}

class _ExpenseIncomeScreenState extends State<ExpenseIncomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  late Future<List<Map<String, dynamic>>> _expenseFuture;
  late Future<List<Map<String, dynamic>>> _categoryFuture;
  late Future<List<Ledger>> _vendorFuture;
  late Future<List<Map<String, dynamic>>> _incomeFuture;
  late Future<List<Map<String, dynamic>>> _recurringFuture;

  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_currentTab != _tabController.index) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    _loadData();
  }

  void _loadData() {
    _expenseFuture = _api.getExpenses();
    _categoryFuture = _api.getExpenseCategories();
    _vendorFuture = _api.getLedgers(isParty: true);
    _incomeFuture = _api.getOtherIncome();
    _recurringFuture = _api.getRecurringExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: AppBar(
        title: const Text('Expenses & Other Income'),
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.slate400,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Expenses'),
            Tab(icon: Icon(Icons.currency_rupee), text: 'Other Income'),
            Tab(icon: Icon(Icons.repeat), text: 'Recurring'),
            Tab(icon: Icon(Icons.category), text: 'Categories'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_loadData),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpensesTab(),
          _buildOtherIncomeTab(),
          _buildRecurringTab(),
          _buildCategoriesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _currentTab == 0
            ? _showExpenseDialog
            : _currentTab == 1
                ? _showIncomeDialog
                : _currentTab == 2
                    ? _showRecurringDialog
                    : _showCategoryDialog,
        icon: const Icon(Icons.add),
        label: Text(_currentTab == 0
            ? 'Add Expense'
            : _currentTab == 1
                ? 'Add Income'
                : _currentTab == 2
                    ? 'Add Recurring'
                    : 'Add Category'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildExpensesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _expenseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _buildErrorState('Failed to load expenses');
        }
        final expenses = snapshot.data ?? [];
        if (expenses.isEmpty) {
          return _buildEmptyState('No expenses recorded');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _buildExpenseCard(expenses[index]),
        );
      },
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final total = (expense['total_amount'] ?? 0).toStringAsFixed(0);
    final status = expense['payment_status']?.toString() ?? 'UNPAID';
    final vendor = expense['vendor_name']?.toString() ?? 'No vendor';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        title: Text(expense['category_name']?.toString() ?? 'Expense'),
        subtitle: Text('${expense['expense_date'] ?? '-'} • $vendor'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹$total', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            _statusChip(status, status == 'PAID' ? Colors.green : AppTheme.warningColor),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherIncomeTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _incomeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _buildErrorState('Failed to load income');
        }
        final income = snapshot.data ?? [];
        if (income.isEmpty) {
          return _buildEmptyState('No other income recorded');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: income.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _buildIncomeCard(income[index]),
        );
      },
    );
  }

  Widget _buildIncomeCard(Map<String, dynamic> entry) {
    final amount = (entry['amount'] ?? 0).toStringAsFixed(0);
    final ledger = entry['ledger_name']?.toString() ?? 'Other Income';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        title: Text(ledger),
        subtitle: Text('${entry['income_date'] ?? '-'} • ${entry['description'] ?? ''}'),
        trailing: Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildRecurringTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _recurringFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _buildErrorState('Failed to load recurring expenses');
        }
        final recurring = snapshot.data ?? [];
        if (recurring.isEmpty) {
          return _buildEmptyState('No recurring templates');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: recurring.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _buildRecurringCard(recurring[index]),
        );
      },
    );
  }

  Widget _buildRecurringCard(Map<String, dynamic> entry) {
    final amount = (entry['taxable_amount'] ?? 0).toStringAsFixed(0);
    final nextRun = entry['next_run_date']?.toString() ?? '-';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        title: Text(entry['template_name']?.toString() ?? 'Recurring'),
        subtitle: Text('${entry['category_name'] ?? ''} • Next: $nextRun'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Run now',
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () async {
                await _api.runRecurringExpense(entry['id']);
                setState(_loadData);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _categoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _buildErrorState('Failed to load categories');
        }
        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return _buildEmptyState('No categories configured');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                title: Text(category['name']?.toString() ?? 'Category'),
                subtitle: Text('Class: ${category['classification'] ?? '-'}'),
                trailing: Text('GST: ${category['gst_eligible'] == 1 ? 'Yes' : 'No'}'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Text(message, style: TextStyle(color: Colors.grey.shade600)));
  }

  Widget _buildErrorState(String message) {
    return Center(child: Text(message, style: TextStyle(color: Colors.red.shade300)));
  }

  String? _paymentModeToApi(PaymentMode? mode) {
    if (mode == null) return null;
    switch (mode) {
      case PaymentMode.cash:
        return 'CASH';
      case PaymentMode.credit:
        return 'CREDIT';
      case PaymentMode.card:
        return 'CARD';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.neft:
        return 'NEFT';
      case PaymentMode.cheque:
        return 'CHEQUE';
      case PaymentMode.online:
        return 'ONLINE';
    }
  }

  Future<void> _showExpenseDialog() async {
    final categories = await _categoryFuture;
    final vendors = await _vendorFuture;

    final dateController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final refController = TextEditingController();
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final gstController = TextEditingController(text: '0');
    final paidController = TextEditingController(text: '0');
    final dueController = TextEditingController();
    final attachmentPath = TextEditingController();
    final attachmentName = TextEditingController();

    int? categoryId = categories.isNotEmpty ? categories.first['id'] as int? : null;
    int? vendorId;
    bool itcEligible = true;
    bool isCredit = false;
    PaymentMode? paymentMode = PaymentMode.cash;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Expense'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Date (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((category) => DropdownMenuItem<int>(
                              value: category['id'] as int?,
                              child: Text(category['name']?.toString() ?? '-'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => categoryId = value),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: vendorId,
                    decoration: const InputDecoration(
                      labelText: 'Vendor (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: vendors
                        .map((vendor) => DropdownMenuItem<int>(
                              value: vendor.id,
                              child: Text(vendor.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => vendorId = value),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: refController,
                    decoration: const InputDecoration(
                      labelText: 'Reference / Bill No',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Taxable Amount',
                            border: OutlineInputBorder(),
                            prefixText: '₹ ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: gstController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'GST Rate %',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<PaymentMode>(
                          initialValue: paymentMode,
                          decoration: const InputDecoration(
                            labelText: 'Payment Mode',
                            border: OutlineInputBorder(),
                          ),
                          items: PaymentMode.values
                              .map((mode) => DropdownMenuItem<PaymentMode>(
                                    value: mode,
                                    child: Text(mode.name.toUpperCase()),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => paymentMode = value),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: paidController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Paid Amount',
                            border: OutlineInputBorder(),
                            prefixText: '₹ ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dueController,
                          decoration: const InputDecoration(
                            labelText: 'Due Date (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('ITC Eligible'),
                          value: itcEligible,
                          onChanged: (value) => setState(() => itcEligible = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Is Credit (Payable)'),
                    value: isCredit,
                    onChanged: (value) => setState(() => isCredit = value),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: attachmentPath,
                    decoration: const InputDecoration(
                      labelText: 'Bill File Path (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: attachmentName,
                    decoration: const InputDecoration(
                      labelText: 'Bill File Name (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (categoryId == null) return;
                final response = await _api.createExpense({
                  'expense_date': dateController.text.trim(),
                  'category_id': categoryId,
                  'vendor_ledger_id': vendorId,
                  'reference_no': refController.text.trim(),
                  'description': descController.text.trim(),
                  'taxable_amount': double.tryParse(amountController.text.trim()) ?? 0,
                  'gst_rate': double.tryParse(gstController.text.trim()) ?? 0,
                  'itc_eligible': itcEligible,
                  'payment_mode': _paymentModeToApi(paymentMode),
                  'paid_amount': double.tryParse(paidController.text.trim()) ?? 0,
                  'due_date': dueController.text.trim().isEmpty ? null : dueController.text.trim(),
                  'is_credit': isCredit,
                });

                if (attachmentPath.text.trim().isNotEmpty) {
                  await _api.addExpenseAttachment(response['id'], {
                    'file_path': attachmentPath.text.trim(),
                    'file_name': attachmentName.text.trim().isEmpty
                        ? attachmentPath.text.trim().replaceAll('\\', '/').split('/').last
                        : attachmentName.text.trim(),
                  });
                }

                if (mounted) Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) setState(_loadData);
  }

  Future<void> _showIncomeDialog() async {
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final refController = TextEditingController();
    final descController = TextEditingController();
    final amountController = TextEditingController();
    PaymentMode? paymentMode = PaymentMode.cash;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Other Income'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Income Date (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: refController,
                  decoration: const InputDecoration(
                    labelText: 'Reference',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<PaymentMode>(
                  initialValue: paymentMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode',
                    border: OutlineInputBorder(),
                  ),
                  items: PaymentMode.values
                      .map((mode) => DropdownMenuItem<PaymentMode>(
                            value: mode,
                            child: Text(mode.name.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => paymentMode = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                await _api.createOtherIncome({
                  'income_date': dateController.text.trim(),
                  'reference_no': refController.text.trim(),
                  'description': descController.text.trim(),
                  'amount': double.tryParse(amountController.text.trim()) ?? 0,
                  'payment_mode': _paymentModeToApi(paymentMode),
                });
                if (mounted) Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) setState(_loadData);
  }

  Future<void> _showRecurringDialog() async {
    final categories = await _categoryFuture;
    final vendors = await _vendorFuture;

    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final gstController = TextEditingController(text: '0');
    final nextRunController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final descController = TextEditingController();

    int? categoryId = categories.isNotEmpty ? categories.first['id'] as int? : null;
    int? vendorId;
    bool itcEligible = true;
    bool isCredit = false;
    PaymentMode? paymentMode = PaymentMode.cash;
    String frequency = 'MONTHLY';

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Recurring Expense'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Template Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((category) => DropdownMenuItem<int>(
                              value: category['id'] as int?,
                              child: Text(category['name']?.toString() ?? '-'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => categoryId = value),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: vendorId,
                    decoration: const InputDecoration(
                      labelText: 'Vendor (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: vendors
                        .map((vendor) => DropdownMenuItem<int>(
                              value: vendor.id,
                              child: Text(vendor.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => vendorId = value),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Taxable Amount',
                            border: OutlineInputBorder(),
                            prefixText: '₹ ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: gstController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'GST Rate %',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<PaymentMode>(
                    initialValue: paymentMode,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                      border: OutlineInputBorder(),
                    ),
                    items: PaymentMode.values
                        .map((mode) => DropdownMenuItem<PaymentMode>(
                              value: mode,
                              child: Text(mode.name.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => paymentMode = value),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: frequency,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'WEEKLY', child: Text('WEEKLY')),
                      DropdownMenuItem(value: 'MONTHLY', child: Text('MONTHLY')),
                      DropdownMenuItem(value: 'QUARTERLY', child: Text('QUARTERLY')),
                      DropdownMenuItem(value: 'YEARLY', child: Text('YEARLY')),
                    ],
                    onChanged: (value) => setState(() => frequency = value ?? 'MONTHLY'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nextRunController,
                    decoration: const InputDecoration(
                      labelText: 'Next Run Date (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('ITC Eligible'),
                    value: itcEligible,
                    onChanged: (value) => setState(() => itcEligible = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Is Credit (Payable)'),
                    value: isCredit,
                    onChanged: (value) => setState(() => isCredit = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (categoryId == null || nameController.text.trim().isEmpty) return;
                await _api.createRecurringExpense({
                  'template_name': nameController.text.trim(),
                  'category_id': categoryId,
                  'vendor_ledger_id': vendorId,
                  'description': descController.text.trim(),
                  'taxable_amount': double.tryParse(amountController.text.trim()) ?? 0,
                  'gst_rate': double.tryParse(gstController.text.trim()) ?? 0,
                  'itc_eligible': itcEligible,
                  'payment_mode': _paymentModeToApi(paymentMode),
                  'is_credit': isCredit,
                  'frequency': frequency,
                  'next_run_date': nextRunController.text.trim(),
                });
                if (mounted) Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) setState(_loadData);
  }

  Future<void> _showCategoryDialog() async {
    final nameController = TextEditingController();
    String classification = 'INDIRECT';
    bool gstEligible = true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Expense Category'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: classification,
                  decoration: const InputDecoration(
                    labelText: 'Classification',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'DIRECT', child: Text('DIRECT')),
                    DropdownMenuItem(value: 'INDIRECT', child: Text('INDIRECT')),
                    DropdownMenuItem(value: 'CAPITAL', child: Text('CAPITAL')),
                  ],
                  onChanged: (value) => setState(() => classification = value ?? 'INDIRECT'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('GST Eligible'),
                  value: gstEligible,
                  onChanged: (value) => setState(() => gstEligible = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await _api.createExpenseCategory({
                  'name': nameController.text.trim(),
                  'classification': classification,
                  'gst_eligible': gstEligible,
                });
                if (mounted) Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) setState(_loadData);
  }
}
