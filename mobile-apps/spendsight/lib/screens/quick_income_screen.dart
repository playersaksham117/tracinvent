import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design_tokens.dart';
import '../models/income.dart';
import '../models/account_type.dart';

/// Quick income entry screen with clean validation
class QuickIncomeScreen extends StatefulWidget {
  final AccountType accountType;
  final VoidCallback? onSaved;

  const QuickIncomeScreen({
    super.key,
    this.accountType = AccountType.individual,
    this.onSaved,
  });

  @override
  State<QuickIncomeScreen> createState() => _QuickIncomeScreenState();
}

class _QuickIncomeScreenState extends State<QuickIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _amountFocusNode = FocusNode();

  IncomeCategory _selectedCategory = IncomeCategory.sales;
  IncomeSource _selectedSource = IncomeSource.cash;
  DateTime _selectedDate = DateTime.now();
  bool _showCustomerFields = false;
  bool _isSaving = false;

  // Individual categories
  final List<IncomeCategory> _individualCategories = [
    IncomeCategory.salary,
    IncomeCategory.freelance,
    IncomeCategory.investment,
    IncomeCategory.gift,
    IncomeCategory.refund,
    IncomeCategory.other,
  ];

  // Business categories
  final List<IncomeCategory> _businessCategories = [
    IncomeCategory.sales,
    IncomeCategory.services,
    IncomeCategory.investment,
    IncomeCategory.rental,
    IncomeCategory.refund,
    IncomeCategory.other,
  ];

  @override
  void initState() {
    super.initState();
    // Set default category based on account type
    _selectedCategory = _isBusinessAccount 
        ? IncomeCategory.sales 
        : IncomeCategory.salary;
    
    // Auto-focus amount field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _invoiceController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  bool get _isBusinessAccount => widget.accountType == AccountType.business;

  List<IncomeCategory> get _categories => 
      _isBusinessAccount ? _businessCategories : _individualCategories;

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    setState(() => _isSaving = true);

    final income = Income(
      amount: amount,
      category: _selectedCategory,
      source: _selectedSource,
      date: _selectedDate,
      description: _descriptionController.text.isEmpty 
          ? null 
          : _descriptionController.text,
      customerName: _showCustomerFields && _customerNameController.text.isNotEmpty
          ? _customerNameController.text
          : null,
      customerPhone: _showCustomerFields && _customerPhoneController.text.isNotEmpty
          ? _customerPhoneController.text
          : null,
      invoiceNumber: _invoiceController.text.isNotEmpty
          ? _invoiceController.text
          : null,
    );

    // Simulate save (in production, use a provider/service)
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      HapticFeedback.mediumImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('₹${amount.toStringAsFixed(0)} income recorded!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onSaved?.call();
      Navigator.of(context).pop(income);
    }

    setState(() => _isSaving = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add Income'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount input (prominent)
                    _buildAmountField(),

                    const SizedBox(height: 24),

                    // Category selection
                    _buildCategorySelector(),

                    const SizedBox(height: 20),

                    // Source tagging (POS/Bank)
                    _buildSourceSelector(),

                    const SizedBox(height: 20),

                    // Date selector
                    _buildDateSelector(),

                    const SizedBox(height: 20),

                    // Description field
                    _buildDescriptionField(),

                    // Invoice/Reference (Business)
                    if (_isBusinessAccount) ...[
                      const SizedBox(height: 20),
                      _buildInvoiceField(),
                    ],

                    // Customer section (optional)
                    const SizedBox(height: 20),
                    _buildCustomerSection(),

                    const SizedBox(height: 100), // Space for save button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount Received',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: AppRadius.largeRadius,
            border: Border.all(
              color: AppColors.success.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Invalid amount';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;

            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(cat.displayName),
                ],
              ),
              selectedColor: AppColors.success,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
              onSelected: (selected) {
                setState(() => _selectedCategory = cat);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSourceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Source',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: IncomeSource.values.map((source) {
              final isSelected = _selectedSource == source;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(source.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(source.displayName),
                    ],
                  ),
                  selectedColor: AppColors.transport,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedSource = source);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final isToday = _selectedDate.day == now.day &&
        _selectedDate.month == now.month &&
        _selectedDate.year == now.year;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.calendar_today, color: AppColors.success),
      ),
      title: const Text('Date'),
      subtitle: Text(
        isToday
            ? 'Today'
            : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _selectDate,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Description (Optional)',
        hintText: 'e.g., Payment for services...',
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildInvoiceField() {
    return TextFormField(
      controller: _invoiceController,
      decoration: InputDecoration(
        labelText: 'Invoice/Reference Number (Optional)',
        hintText: 'INV-001',
        prefixIcon: const Icon(Icons.receipt_long),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer toggle
        InkWell(
          onTap: () {
            setState(() => _showCustomerFields = !_showCustomerFields);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _showCustomerFields
                  ? AppColors.primaryContainer.withOpacity(0.5)
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showCustomerFields
                    ? AppColors.primary.withOpacity(0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_add_outlined,
                  color: _showCustomerFields
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Customer (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _showCustomerFields
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Track who paid you',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showCustomerFields
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        // Customer fields (expandable)
        if (_showCustomerFields) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _customerNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Customer Name',
              hintText: 'John Doe',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number (Optional)',
              hintText: '+91 98765 43210',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: _isSaving ? null : _saveIncome,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.success,
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(Icons.check),
          label: Text(
            _isSaving ? 'Saving...' : 'Record Income',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
