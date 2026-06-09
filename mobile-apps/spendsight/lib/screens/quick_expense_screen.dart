import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../core/design_tokens.dart';
import '../models/expense.dart';
import '../models/account_type.dart';
import '../services/ocr_service.dart';
import '../services/offline_sync_service.dart';

/// Quick expense entry screen with camera scan support
class QuickExpenseScreen extends StatefulWidget {
  final AccountType accountType;
  final VoidCallback? onSaved;

  const QuickExpenseScreen({
    super.key,
    this.accountType = AccountType.individual,
    this.onSaved,
  });

  @override
  State<QuickExpenseScreen> createState() => _QuickExpenseScreenState();
}

class _QuickExpenseScreenState extends State<QuickExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _amountFocusNode = FocusNode();
  
  final _syncService = OfflineSyncService();
  final _ocrService = OCRService();

  String _selectedCategory = 'Food';
  PaymentMode _selectedPaymentMode = PaymentMode.upi;
  DateTime _selectedDate = DateTime.now();
  String? _selectedMember;
  String? _selectedDepartment;
  double? _gstPercentage;
  double? _gstAmount;
  String? _attachmentPath;
  
  bool _isProcessingOCR = false;
  bool _isSaving = false;
  bool _showGSTFields = false;
  OCRResult? _ocrResult;
  
  late AnimationController _saveAnimController;
  late Animation<double> _saveAnimation;

  // Categories with icons
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': AppColors.food},
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': AppColors.transport},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': AppColors.shopping},
    {'name': 'Bills', 'icon': Icons.receipt_long, 'color': AppColors.bills},
    {'name': 'Health', 'icon': Icons.medical_services, 'color': AppColors.health},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': AppColors.entertainment},
    {'name': 'Groceries', 'icon': Icons.local_grocery_store, 'color': AppColors.warning},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': AppColors.primary},
  ];

  // Family members (for Family account)
  final List<String> _familyMembers = ['Self', 'Spouse', 'Child 1', 'Child 2', 'Parent'];
  
  // Departments (for Business account)  
  final List<String> _departments = ['Operations', 'Marketing', 'Sales', 'HR', 'IT', 'Finance', 'Other'];

  // GST percentages
  final List<double> _gstRates = [0, 5, 12, 18, 28];

  @override
  void initState() {
    super.initState();
    _saveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _saveAnimation = CurvedAnimation(
      parent: _saveAnimController,
      curve: Curves.easeInOut,
    );
    
    // Auto-focus amount field for quick entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _gstNumberController.dispose();
    _amountFocusNode.dispose();
    _saveAnimController.dispose();
    super.dispose();
  }

  bool get _isBusinessAccount => widget.accountType == AccountType.business;
  bool get _isFamilyAccount => widget.accountType == AccountType.family;

  /// Simulate camera capture and OCR
  Future<void> _scanReceipt() async {
    setState(() => _isProcessingOCR = true);
    
    // In production: Use image_picker to capture/select image
    // final picker = ImagePicker();
    // final image = await picker.pickImage(source: ImageSource.camera);
    
    // Simulate camera capture
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      // Process with OCR
      final result = await _ocrService.processReceipt('/simulated/path.jpg');
      
      setState(() {
        _ocrResult = result;
        _isProcessingOCR = false;
        
        // Auto-fill from OCR
        if (result.amount != null) {
          _amountController.text = result.amount!.toStringAsFixed(2);
        }
        if (result.category != null) {
          _selectedCategory = result.category!;
        }
        if (result.cgst != null && result.sgst != null) {
          _showGSTFields = true;
          _gstAmount = (result.cgst ?? 0) + (result.sgst ?? 0);
          _gstPercentage = 18; // Common GST rate
        }
        if (result.gstNumber != null && _isBusinessAccount) {
          _gstNumberController.text = result.gstNumber!;
        }
        _attachmentPath = '/simulated/receipt.jpg';
      });

      _showOCRConfirmation(result);
    } catch (e) {
      setState(() => _isProcessingOCR = false);
      _showError('Failed to process receipt');
    }
  }

  void _showOCRConfirmation(OCRResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Receipt scanned! Amount: ₹${result.amount?.toStringAsFixed(2) ?? 'N/A'}',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Edit',
          textColor: Colors.white,
          onPressed: () => _amountFocusNode.requestFocus(),
        ),
      ),
    );
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

  /// Save expense with offline support
  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    setState(() => _isSaving = true);
    _saveAnimController.forward();

    final expense = Expense(
      amount: amount,
      category: _selectedCategory,
      paymentMode: _selectedPaymentMode,
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      attachmentPath: _attachmentPath,
      gstAmount: _gstAmount,
      gstPercentage: _gstPercentage,
      gstNumber: _gstNumberController.text.isEmpty ? null : _gstNumberController.text,
      member: _selectedMember,
      department: _selectedDepartment,
      ocrRawText: _ocrResult?.rawText,
      ocrExtractedData: _ocrResult?.extractedData,
    );

    try {
      // Save locally (offline-first)
      await _syncService.saveExpenseLocally(expense);
      
      // Quick success feedback
      if (mounted) {
        HapticFeedback.mediumImpact();
        
        // Show success and close
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('₹${amount.toStringAsFixed(0)} expense saved!'),
                const Spacer(),
                if (!_syncService.isOnline)
                  const Chip(
                    label: Text('Offline', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        widget.onSaved?.call();
        Navigator.of(context).pop(expense);
      }
    } catch (e) {
      _showError('Failed to save expense');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        _saveAnimController.reverse();
      }
    }
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
        title: const Text('Add Expense'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Offline indicator
          StreamBuilder<SyncStatusUpdate>(
            stream: _syncService.syncStatusStream,
            builder: (context, snapshot) {
              final pending = _syncService.pendingCount;
              if (pending > 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    label: Text('$pending'),
                    backgroundColor: colorScheme.secondaryContainer,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Camera scan button
                    _buildScanButton(),
                    
                    const SizedBox(height: 24),
                    
                    // Amount input (prominent)
                    _buildAmountField(),
                    
                    const SizedBox(height: 24),
                    
                    // Category selection
                    _buildCategorySelector(),
                    
                    const SizedBox(height: 20),
                    
                    // Payment mode
                    _buildPaymentModeSelector(),
                    
                    const SizedBox(height: 20),
                    
                    // Date selector
                    _buildDateSelector(),
                    
                    // GST Fields (Business only)
                    if (_isBusinessAccount) ...[
                      const SizedBox(height: 20),
                      _buildGSTSection(),
                    ],
                    
                    // Member/Department
                    if (_isFamilyAccount || _isBusinessAccount) ...[
                      const SizedBox(height: 20),
                      _buildMemberDepartmentSelector(),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Note field
                    _buildNoteField(),
                    
                    // Attachment preview
                    if (_attachmentPath != null) ...[
                      const SizedBox(height: 16),
                      _buildAttachmentPreview(),
                    ],
                    
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating save button
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildScanButton() {
    return Material(
      color: AppColors.primaryContainer,
      borderRadius: AppRadius.largeRadius,
      child: InkWell(
        onTap: _isProcessingOCR ? null : _scanReceipt,
        borderRadius: AppRadius.largeRadius,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessingOCR)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              const SizedBox(width: 12),
              Text(
                _isProcessingOCR ? 'Processing...' : 'Scan Receipt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              if (!_isProcessingOCR) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Auto-fill',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: AppRadius.largeRadius,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
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
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
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
            final isSelected = _selectedCategory == cat['name'];
            final color = cat['color'] as Color;
            
            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(cat['name'] as String),
                ],
              ),
              selectedColor: color,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
              onSelected: (selected) {
                setState(() => _selectedCategory = cat['name'] as String);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Mode',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: PaymentMode.values.map((mode) {
              final isSelected = _selectedPaymentMode == mode;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mode.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(mode.displayName),
                    ],
                  ),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedPaymentMode = mode);
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
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.calendar_today, color: AppColors.primary),
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

  Widget _buildGSTSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GST Toggle
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'GST Applicable',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: const Text('Add GST details for business expenses'),
          value: _showGSTFields,
          onChanged: (value) => setState(() => _showGSTFields = value),
        ),
        
        if (_showGSTFields) ...[
          const SizedBox(height: 12),
          
          // GST Rate selector
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<double>(
                  value: _gstPercentage,
                  decoration: InputDecoration(
                    labelText: 'GST Rate',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: _gstRates.map((rate) {
                    return DropdownMenuItem(
                      value: rate,
                      child: Text('$rate%'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _gstPercentage = value;
                      // Calculate GST amount
                      final amount = double.tryParse(_amountController.text) ?? 0;
                      _gstAmount = amount * (value ?? 0) / 100;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GST Amount',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '₹${(_gstAmount ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // GST Number field
          TextFormField(
            controller: _gstNumberController,
            decoration: InputDecoration(
              labelText: 'GST Number (Optional)',
              hintText: '22AAAAA0000A1Z5',
              prefixIcon: const Icon(Icons.receipt_long),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ],
    );
  }

  Widget _buildMemberDepartmentSelector() {
    final items = _isFamilyAccount ? _familyMembers : _departments;
    final label = _isFamilyAccount ? 'Family Member' : 'Department';
    final value = _isFamilyAccount ? _selectedMember : _selectedDepartment;
    
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          _isFamilyAccount ? Icons.person : Icons.business,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: (value) {
        setState(() {
          if (_isFamilyAccount) {
            _selectedMember = value;
          } else {
            _selectedDepartment = value;
          }
        });
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Note (Optional)',
        hintText: 'Add a note...',
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.attachment, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receipt attached',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                if (_ocrResult != null)
                  Text(
                    'Confidence: ${(_ocrResult!.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _attachmentPath = null;
                _ocrResult = null;
              });
            },
          ),
        ],
      ),
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
        child: AnimatedBuilder(
          animation: _saveAnimation,
          builder: (context, child) {
            return FilledButton.icon(
              onPressed: _isSaving ? null : _saveExpense,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _isSaving 
                  ? AppColors.success 
                  : AppColors.primary,
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
                _isSaving ? 'Saving...' : 'Save Expense',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
