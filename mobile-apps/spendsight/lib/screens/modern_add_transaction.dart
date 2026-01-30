import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/modern_colors.dart';
import '../models/models.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;

  final List<String> _expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Entertainment',
  ];

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Business',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isExpense = _tabController.index == 0;
        _selectedCategory = _isExpense ? _expenseCategories[0] : _incomeCategories[0];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.background,
      appBar: AppBar(
        title: const Text('Add Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveTransaction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTabBar(),
              const SizedBox(height: 24),
              _buildAmountInput(),
              const SizedBox(height: 24),
              _buildTitleInput(),
              const SizedBox(height: 24),
              _buildCategorySelection(),
              const SizedBox(height: 24),
              _buildDateSelector(),
              const SizedBox(height: 24),
              _buildNoteInput(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.border, width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: _tabController.index == 0
              ? ModernColors.errorGradient
              : ModernColors.successGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: ModernColors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Expense'),
          Tab(text: 'Income'),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: TextStyle(
            color: ModernColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ModernColors.border, width: 1),
          ),
          child: TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 20, right: 8),
                child: Text(
                  '\$',
                  style: TextStyle(
                    color: ModernColors.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(),
              hintText: '0.00',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: TextStyle(
            color: ModernColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ModernColors.border, width: 1),
          ),
          child: TextFormField(
            controller: _titleController,
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g., Grocery shopping',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelection() {
    final categories = _isExpense ? _expenseCategories : _incomeCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            color: ModernColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((category) {
            final isSelected = category == _selectedCategory;
            final color = _getCategoryColor(category);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color : ModernColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : ModernColors.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 20,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : ModernColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: TextStyle(
            color: ModernColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: ModernColors.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ModernColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ModernColors.border, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: ModernColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: TextStyle(
                    color: ModernColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note (Optional)',
          style: TextStyle(
            color: ModernColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ModernColors.border, width: 1),
          ),
          child: TextFormField(
            controller: _noteController,
            maxLines: 3,
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: 'Add a note...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: _saveTransaction,
        style: FilledButton.styleFrom(
          backgroundColor: ModernColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Save Transaction',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        id: const Uuid().v4(),
        title: _titleController.text,
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        isExpense: _isExpense,
      );

      await context.read<TransactionProvider>().addTransaction(transaction);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction added successfully'),
            backgroundColor: ModernColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return ModernColors.food;
      case 'transport':
        return ModernColors.transport;
      case 'shopping':
        return ModernColors.shopping;
      case 'bills':
        return ModernColors.bills;
      case 'health':
        return ModernColors.health;
      case 'entertainment':
        return ModernColors.entertainment;
      case 'salary':
        return ModernColors.salary;
      case 'freelance':
        return ModernColors.freelance;
      default:
        return ModernColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_rounded;
      case 'health':
        return Icons.health_and_safety_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'salary':
        return Icons.attach_money_rounded;
      case 'freelance':
        return Icons.work_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
