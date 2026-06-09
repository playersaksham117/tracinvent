import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design_tokens.dart';
import '../core/modern_colors.dart';
import '../models/budget_item.dart';
import '../models/account_type.dart';
import '../providers/account_provider.dart';

/// Adaptive budget screen based on account type
class AdaptiveBudgetScreen extends StatefulWidget {
  const AdaptiveBudgetScreen({super.key});

  @override
  State<AdaptiveBudgetScreen> createState() => _AdaptiveBudgetScreenState();
}

class _AdaptiveBudgetScreenState extends State<AdaptiveBudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Sample budgets (in production, load from provider/database)
  List<BudgetItem> _budgets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSampleBudgets();
  }

  void _loadSampleBudgets() {
    final accountType = context.read<AccountProvider>().accountType;
    _budgets = _getSampleBudgets(accountType);
  }

  List<BudgetItem> _getSampleBudgets(AccountType accountType) {
    switch (accountType) {
      case AccountType.individual:
        return _getIndividualBudgets();
      case AccountType.family:
        return _getFamilyBudgets();
      case AccountType.business:
        return _getBusinessBudgets();
    }
  }

  List<BudgetItem> _getIndividualBudgets() {
    return [
      BudgetItem(name: 'Food & Dining', type: BudgetType.category, category: 'Food', limit: 8000, spent: 6500),
      BudgetItem(name: 'Transport', type: BudgetType.category, category: 'Transport', limit: 3000, spent: 2800),
      BudgetItem(name: 'Shopping', type: BudgetType.category, category: 'Shopping', limit: 5000, spent: 5200),
      BudgetItem(name: 'Entertainment', type: BudgetType.category, category: 'Entertainment', limit: 2000, spent: 1200),
      BudgetItem(name: 'Bills & Utilities', type: BudgetType.category, category: 'Bills', limit: 4000, spent: 3800),
      BudgetItem(name: 'Health', type: BudgetType.category, category: 'Health', limit: 2000, spent: 500),
    ];
  }

  List<BudgetItem> _getFamilyBudgets() {
    return [
      // Shared budgets
      BudgetItem(name: 'Household', type: BudgetType.shared, limit: 15000, spent: 12500),
      BudgetItem(name: 'Groceries', type: BudgetType.shared, category: 'Groceries', limit: 10000, spent: 8200),
      BudgetItem(name: 'Utilities', type: BudgetType.shared, category: 'Bills', limit: 5000, spent: 4500),
      // Member budgets
      BudgetItem(name: 'Self', type: BudgetType.member, memberId: '1', memberName: 'Self', limit: 8000, spent: 6000),
      BudgetItem(name: 'Spouse', type: BudgetType.member, memberId: '2', memberName: 'Spouse', limit: 8000, spent: 7500),
      BudgetItem(name: 'Child 1', type: BudgetType.member, memberId: '3', memberName: 'Child 1', limit: 3000, spent: 2800),
    ];
  }

  List<BudgetItem> _getBusinessBudgets() {
    return [
      BudgetItem(name: 'Operations', type: BudgetType.department, departmentId: '1', departmentName: 'Operations', limit: 50000, spent: 42000),
      BudgetItem(name: 'Marketing', type: BudgetType.department, departmentId: '2', departmentName: 'Marketing', limit: 30000, spent: 28500),
      BudgetItem(name: 'Sales', type: BudgetType.department, departmentId: '3', departmentName: 'Sales', limit: 25000, spent: 18000),
      BudgetItem(name: 'IT & Software', type: BudgetType.department, departmentId: '4', departmentName: 'IT', limit: 20000, spent: 21000),
      BudgetItem(name: 'HR & Admin', type: BudgetType.department, departmentId: '5', departmentName: 'HR', limit: 15000, spent: 12000),
      BudgetItem(name: 'Travel & Expenses', type: BudgetType.category, category: 'Transport', limit: 10000, spent: 8500),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, accountProvider, _) {
        final accountType = accountProvider.accountType;
        _budgets = _getSampleBudgets(accountType);
        
        return Scaffold(
          backgroundColor: ModernColors.background,
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: ModernColors.background,
                title: Text(
                  'Budgets',
                  style: TextStyle(
                    color: ModernColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _showAddBudgetSheet(accountType),
                  ),
                ],
              ),

              // Summary Card
              SliverToBoxAdapter(
                child: _buildSummaryCard(),
              ),

              // Alert Badges
              if (_budgets.where((b) => b.shouldAlert).isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildAlertSection(),
                ),

              // Budget List based on account type
              SliverToBoxAdapter(
                child: _buildBudgetSection(accountType),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    final totalLimit = _budgets.fold<double>(0, (sum, b) => sum + b.limit);
    final totalSpent = _budgets.fold<double>(0, (sum, b) => sum + b.spent);
    final overallProgress = totalLimit > 0 ? totalSpent / totalLimit : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ModernColors.primary.withOpacity(0.9),
            ModernColors.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ModernColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Overview',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(overallProgress * 100).toInt()}% used',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${totalSpent.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'of ₹${totalLimit.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: overallProgress.clamp(0, 1),
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(
                        overallProgress >= 1 
                            ? AppColors.error 
                            : Colors.white,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${(overallProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overallProgress.clamp(0, 1),
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                overallProgress >= 1 
                    ? AppColors.error.withOpacity(0.8)
                    : Colors.white.withOpacity(0.9),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSection() {
    final alertBudgets = _budgets.where((b) => b.shouldAlert).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, 
                   color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Alerts',
                style: TextStyle(
                  color: ModernColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alertBudgets.map((budget) => _buildAlertCard(budget)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BudgetItem budget) {
    final isExceeded = budget.alertStatus == BudgetAlertStatus.exceeded;
    final color = isExceeded ? AppColors.error : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isExceeded ? Icons.error_outline : Icons.warning_amber_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.name,
                  style: TextStyle(
                    color: ModernColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isExceeded 
                      ? 'Budget exceeded by ₹${(-budget.remaining).toStringAsFixed(0)}'
                      : '${budget.percentage.toInt()}% used - ₹${budget.remaining.toStringAsFixed(0)} left',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isExceeded ? 'EXCEEDED' : '80%+',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(AccountType accountType) {
    switch (accountType) {
      case AccountType.individual:
        return _buildIndividualBudgets();
      case AccountType.family:
        return _buildFamilyBudgets();
      case AccountType.business:
        return _buildBusinessBudgets();
    }
  }

  /// Individual: Category sliders
  Widget _buildIndividualBudgets() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Budgets',
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ..._budgets.map((budget) => _buildCategorySliderCard(budget)),
        ],
      ),
    );
  }

  Widget _buildCategorySliderCard(BudgetItem budget) {
    final category = BudgetCategory.expenseCategories.firstWhere(
      (c) => c['name'] == budget.category,
      orElse: () => {'name': budget.name, 'icon': '💰', 'color': 0xFF607D8B},
    );
    final color = Color(category['color'] as int);
    final progress = budget.progress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    category['icon'] as String,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: TextStyle(
                        color: ModernColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹${budget.spent.toStringAsFixed(0)} / ₹${budget.limit.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: ModernColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(budget),
            ],
          ),
          const SizedBox(height: 16),
          // Progress slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 8,
              activeTrackColor: _getProgressColor(budget),
              inactiveTrackColor: color.withOpacity(0.15),
              thumbColor: _getProgressColor(budget),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: progress,
              onChanged: null, // Read-only
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${budget.daysRemaining} days left',
                style: TextStyle(
                  color: ModernColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              Text(
                '₹${budget.dailyBudgetRemaining.toStringAsFixed(0)}/day remaining',
                style: TextStyle(
                  color: ModernColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Family: Shared + Member budgets
  Widget _buildFamilyBudgets() {
    final sharedBudgets = _budgets.where((b) => b.type == BudgetType.shared).toList();
    final memberBudgets = _budgets.where((b) => b.type == BudgetType.member).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shared budgets section
          Text(
            'Shared Household Budgets',
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...sharedBudgets.map((budget) => _buildProgressCard(budget, Colors.blue)),
          
          const SizedBox(height: 24),
          
          // Member budgets section
          Text(
            'Member Budgets',
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...memberBudgets.map((budget) => _buildMemberBudgetCard(budget)),
        ],
      ),
    );
  }

  Widget _buildMemberBudgetCard(BudgetItem budget) {
    final member = BudgetCategory.familyMembers.firstWhere(
      (m) => m['name'] == budget.memberName,
      orElse: () => {'name': budget.name, 'icon': '👤', 'color': 0xFF2196F3},
    );
    final color = Color(member['color'] as int);

    return _buildProgressCard(budget, color, icon: member['icon'] as String);
  }

  /// Business: Department/Category budgets
  Widget _buildBusinessBudgets() {
    final deptBudgets = _budgets.where((b) => b.type == BudgetType.department).toList();
    final categoryBudgets = _budgets.where((b) => b.type == BudgetType.category).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Department budgets
          Text(
            'Department Budgets',
            style: TextStyle(
              color: ModernColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...deptBudgets.map((budget) => _buildDepartmentBudgetCard(budget)),
          
          if (categoryBudgets.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Expense Category Budgets',
              style: TextStyle(
                color: ModernColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryBudgets.map((budget) => _buildCategorySliderCard(budget)),
          ],
        ],
      ),
    );
  }

  Widget _buildDepartmentBudgetCard(BudgetItem budget) {
    final dept = BudgetCategory.departments.firstWhere(
      (d) => d['name'] == budget.departmentName,
      orElse: () => {'name': budget.name, 'icon': '🏢', 'color': 0xFF607D8B},
    );
    final color = Color(dept['color'] as int);

    return _buildProgressCard(budget, color, icon: dept['icon'] as String);
  }

  Widget _buildProgressCard(BudgetItem budget, Color color, {String? icon}) {
    final progress = budget.progress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.account_balance_wallet, color: color),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: TextStyle(
                        color: ModernColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${budget.remaining.toStringAsFixed(0)} remaining',
                      style: TextStyle(
                        color: budget.isOverBudget 
                            ? AppColors.error 
                            : ModernColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${budget.spent.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: ModernColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'of ₹${budget.limit.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: ModernColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getProgressColor(budget),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(budget),
              Text(
                '${budget.percentage.toInt()}%',
                style: TextStyle(
                  color: _getProgressColor(budget),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BudgetItem budget) {
    final status = budget.alertStatus;
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case BudgetAlertStatus.safe:
        color = AppColors.success;
        text = 'On Track';
        icon = Icons.check_circle_outline;
        break;
      case BudgetAlertStatus.warning:
        color = AppColors.warning;
        text = '80%+ Used';
        icon = Icons.warning_amber_rounded;
        break;
      case BudgetAlertStatus.exceeded:
        color = AppColors.error;
        text = 'Exceeded';
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(BudgetItem budget) {
    switch (budget.alertStatus) {
      case BudgetAlertStatus.safe:
        return AppColors.success;
      case BudgetAlertStatus.warning:
        return AppColors.warning;
      case BudgetAlertStatus.exceeded:
        return AppColors.error;
    }
  }

  void _showAddBudgetSheet(AccountType accountType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddBudgetSheet(accountType: accountType),
    );
  }
}

/// Add Budget Sheet
class _AddBudgetSheet extends StatefulWidget {
  final AccountType accountType;

  const _AddBudgetSheet({required this.accountType});

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  final _limitController = TextEditingController();
  String? _selectedCategory;
  String? _selectedMember;
  String? _selectedDepartment;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  bool _alertEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ModernColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create Budget',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ModernColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Budget limit
            TextField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Budget Limit',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Period selector
            DropdownButtonFormField<BudgetPeriod>(
              value: _selectedPeriod,
              decoration: InputDecoration(
                labelText: 'Period',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: BudgetPeriod.values.map((p) {
                return DropdownMenuItem(value: p, child: Text(p.displayName));
              }).toList(),
              onChanged: (v) => setState(() => _selectedPeriod = v!),
            ),
            const SizedBox(height: 16),

            // Category/Member/Department based on account type
            _buildTypeSpecificField(),
            const SizedBox(height: 16),

            // Alert toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Alerts'),
              subtitle: const Text('Notify at 80% and when exceeded'),
              value: _alertEnabled,
              onChanged: (v) => setState(() => _alertEnabled = v),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _saveBudget,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: ModernColors.primary,
              ),
              child: const Text('Create Budget'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificField() {
    switch (widget.accountType) {
      case AccountType.individual:
        return DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: BudgetCategory.expenseCategories.map((c) {
            return DropdownMenuItem(
              value: c['name'] as String,
              child: Row(
                children: [
                  Text(c['icon'] as String),
                  const SizedBox(width: 8),
                  Text(c['name'] as String),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v),
        );

      case AccountType.family:
        return Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category (Shared Budget)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: BudgetCategory.expenseCategories.map((c) {
                return DropdownMenuItem(
                  value: c['name'] as String,
                  child: Row(
                    children: [
                      Text(c['icon'] as String),
                      const SizedBox(width: 8),
                      Text(c['name'] as String),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMember,
              decoration: InputDecoration(
                labelText: 'Or Member Budget',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: BudgetCategory.familyMembers.map((m) {
                return DropdownMenuItem(
                  value: m['name'] as String,
                  child: Row(
                    children: [
                      Text(m['icon'] as String),
                      const SizedBox(width: 8),
                      Text(m['name'] as String),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedMember = v),
            ),
          ],
        );

      case AccountType.business:
        return DropdownButtonFormField<String>(
          value: _selectedDepartment,
          decoration: InputDecoration(
            labelText: 'Department',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: BudgetCategory.departments.map((d) {
            return DropdownMenuItem(
              value: d['name'] as String,
              child: Row(
                children: [
                  Text(d['icon'] as String),
                  const SizedBox(width: 8),
                  Text(d['name'] as String),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedDepartment = v),
        );
    }
  }

  void _saveBudget() {
    final limit = double.tryParse(_limitController.text);
    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget limit')),
      );
      return;
    }

    // In production, save to provider/database
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Budget created successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
