/// Purchase Entry Screen
/// Purchase bill creation with supplier selection, items, tax, and expense tagging
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../models/gst_invoice.dart' as gst;
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Keyboard shortcuts for purchase entry
class PurchaseShortcuts {
  static const newPurchase = SingleActivator(
    LogicalKeyboardKey.keyN,
    control: true,
  );
  static const savePurchase = SingleActivator(
    LogicalKeyboardKey.keyS,
    control: true,
  );
  static const selectSupplier = SingleActivator(LogicalKeyboardKey.f4);
  static const addItem = SingleActivator(LogicalKeyboardKey.f2);
  static const focusBarcode = SingleActivator(LogicalKeyboardKey.f1);
  static const paymentDialog = SingleActivator(LogicalKeyboardKey.f5);
  static const expenseTag = SingleActivator(LogicalKeyboardKey.f6);
}

/// Intent for void callbacks
class _VoidCallbackIntent extends Intent {
  final VoidCallback callback;
  const _VoidCallbackIntent(this.callback);
}

class PurchaseEntryScreen extends StatefulWidget {
  const PurchaseEntryScreen({super.key});

  @override
  State<PurchaseEntryScreen> createState() => _PurchaseEntryScreenState();
}

class _PurchaseEntryScreenState extends State<PurchaseEntryScreen> {
  late ApiService _apiService;

  // Controllers
  final _barcodeController = TextEditingController();
  final _barcodeFocus = FocusNode();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();

  // State
  String? _selectedSupplierId;
  String _selectedSupplierName = '';
  Map<String, dynamic>? _selectedSupplier;
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  final List<PurchaseItem> _items = [];
  ExpenseCategory _expenseCategory = ExpenseCategory.inventory;
  PaymentStatus _paymentStatus = PaymentStatus.unpaid;
  double _paidAmount = 0;
  bool _priceIncludesTax = false;
  bool _isSaving = false;
  int? _purchaseVoucherTypeId;

  // Computed totals
  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.taxableAmount);
  double get _totalTax =>
      _items.fold(0, (sum, item) => sum + item.cgstAmount + item.sgstAmount);
  double get _grandTotal =>
      _items.fold(0, (sum, item) => sum + item.totalAmount);
  double get _balanceAmount => _grandTotal - _paidAmount;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }

  @override
  void dispose() {
    _apiService.dispose();
    _barcodeController.dispose();
    _barcodeFocus.dispose();
    _invoiceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleNewPurchase() {
    setState(() {
      _selectedSupplierId = null;
      _selectedSupplierName = '';
      _selectedSupplier = null;
      _invoiceNumberController.clear();
      _invoiceDate = DateTime.now();
      _dueDate = null;
      _items.clear();
      _expenseCategory = ExpenseCategory.inventory;
      _paymentStatus = PaymentStatus.unpaid;
      _paidAmount = 0;
      _notesController.clear();
    });
    _barcodeFocus.requestFocus();
  }

  Future<void> _selectSupplier() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SupplierSelectionDialog(apiService: _apiService),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedSupplierId = result['id']?.toString();
        _selectedSupplierName = result['name']?.toString() ?? '';
        _selectedSupplier = result;
        // Auto-set due date based on supplier credit days
        final creditDays = result['creditDays'] as int? ?? 30;
        _dueDate = _invoiceDate.add(Duration(days: creditDays));
      });
    }
  }

  Future<void> _addItem() async {
    final result = await showDialog<PurchaseItem>(
      context: context,
      builder: (context) =>
          _AddPurchaseItemDialog(priceIncludesTax: _priceIncludesTax),
    );

    if (result != null && mounted) {
      setState(() => _items.add(result));
    }
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _editItem(int index) async {
    final result = await showDialog<PurchaseItem>(
      context: context,
      builder: (context) => _AddPurchaseItemDialog(
        priceIncludesTax: _priceIncludesTax,
        editItem: _items[index],
      ),
    );

    if (result != null && mounted) {
      setState(() => _items[index] = result);
    }
  }

  Future<void> _showPaymentDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PaymentEntryDialog(
        grandTotal: _grandTotal,
        currentPaid: _paidAmount,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _paidAmount = result['amount'];
        _paymentStatus = result['status'];
      });
    }
  }

  Future<void> _selectExpenseTag() async {
    final result = await showDialog<ExpenseCategory>(
      context: context,
      builder: (context) =>
          _ExpenseTagDialog(currentCategory: _expenseCategory),
    );

    if (result != null && mounted) {
      setState(() => _expenseCategory = result);
    }
  }

  Future<void> _handleBarcodeSubmit(String rawValue) async {
    final barcode = rawValue.trim();
    if (barcode.isEmpty) return;

    try {
      final foundItem = await _apiService.getItemByBarcode(barcode);
      if (foundItem == null) {
        _showSnackBar('Item not found for barcode: $barcode', isError: true);
        return;
      }

      final existingIndex = _items.indexWhere(
        (item) => item.itemId == foundItem.id.toString(),
      );

      if (existingIndex >= 0) {
        final current = _items[existingIndex];
        setState(() {
          _items[existingIndex] = _createPurchaseItemFromSearch(
            foundItem,
            quantity: current.quantity + 1,
            batchNumber: current.batchNumber,
          );
        });
      } else {
        setState(() {
          _items.add(_createPurchaseItemFromSearch(foundItem));
        });
      }
      _showSnackBar('Added: ${foundItem.name}', isSuccess: true);
    } catch (e) {
      _showSnackBar('Failed to scan barcode: $e', isError: true);
    } finally {
      _barcodeController.clear();
      _barcodeFocus.requestFocus();
    }
  }

  PurchaseItem _createPurchaseItemFromSearch(
    ItemSearchResult item, {
    double quantity = 1,
    String? batchNumber,
  }) {
    final rate = item.sellingPrice > 0 ? item.sellingPrice : item.mrp;
    final amount = quantity * rate;
    final taxableAmount = _priceIncludesTax
        ? amount / (1 + item.gstRate / 100)
        : amount;
    final taxAmount = taxableAmount * item.gstRate / 100;

    return PurchaseItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      itemId: item.id.toString(),
      itemName: item.name,
      hsnCode: item.hsnCode,
      quantity: quantity,
      unit: item.unitCode,
      purchasePrice: rate,
      mrp: item.mrp,
      sellingPrice: item.sellingPrice,
      taxableAmount: taxableAmount,
      gstRate: item.gstRate,
      cgstAmount: taxAmount / 2,
      sgstAmount: taxAmount / 2,
      totalAmount: taxableAmount + taxAmount,
      batchNumber: batchNumber,
    );
  }

  Future<int> _getPurchaseVoucherTypeId() async {
    if (_purchaseVoucherTypeId != null) return _purchaseVoucherTypeId!;

    final voucherTypes = await _apiService.getVoucherTypes();
    for (final voucherType in voucherTypes) {
      if (voucherType.type.toUpperCase() == 'PURCHASE' &&
          voucherType.id != null) {
        _purchaseVoucherTypeId = voucherType.id;
        break;
      }
    }

    if (_purchaseVoucherTypeId == null) {
      throw Exception('Purchase voucher type not configured');
    }
    return _purchaseVoucherTypeId!;
  }

  gst.PaymentStatus _toInvoicePaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return gst.PaymentStatus.paid;
      case PaymentStatus.partiallyPaid:
        return gst.PaymentStatus.partial;
      case PaymentStatus.overdue:
        return gst.PaymentStatus.overdue;
      case PaymentStatus.unpaid:
        return gst.PaymentStatus.unpaid;
    }
  }

  Future<void> _savePurchase() async {
    if (_isSaving) return;

    if (_selectedSupplierId == null) {
      _showSnackBar('Select a supplier first', isError: true);
      return;
    }

    if (_items.isEmpty) {
      _showSnackBar('Add at least one item', isError: true);
      return;
    }

    if (_invoiceNumberController.text.isEmpty) {
      _showSnackBar('Enter supplier invoice number', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final voucherTypeId = await _getPurchaseVoucherTypeId();
      final invoiceItems = <gst.InvoiceItem>[];

      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        invoiceItems.add(
          gst.InvoiceItem(
            itemId: int.tryParse(item.itemId),
            itemName: item.itemName,
            hsnCode: item.hsnCode,
            quantity: item.quantity,
            unitCode: item.unit,
            rate: item.purchasePrice,
            mrp: item.mrp,
            discountType: gst.DiscountType.amount,
            discountValue: 0,
            gstRate: item.gstRate,
            cgstRate: item.gstRate / 2,
            sgstRate: item.gstRate / 2,
            cessRate: item.cessRate,
            serialNumber: i + 1,
          ),
        );
      }

      final invoice = GSTInvoice(
        voucherTypeId: voucherTypeId,
        invoiceNumber: _invoiceNumberController.text.trim(),
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        partyId: int.tryParse(_selectedSupplierId!),
        partyName: _selectedSupplierName,
        partyGstin: _selectedSupplier?['gstin'] as String?,
        partyStateCode: _selectedSupplier?['billing_state_code'] as String?,
        partyAddress: _selectedSupplier?['billing_address'] as String?,
        billingName: _selectedSupplierName,
        billingAddress: _selectedSupplier?['billing_address'] as String?,
        billingCity: _selectedSupplier?['billing_city'] as String?,
        billingStateCode: _selectedSupplier?['billing_state_code'] as String?,
        billingPincode: _selectedSupplier?['billing_pincode'] as String?,
        paymentStatus: _toInvoicePaymentStatus(_paymentStatus),
        paidAmount: _paidAmount,
        balanceAmount: _balanceAmount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        items: invoiceItems,
      );

      final created = await _apiService.createInvoice(invoice);
      final number =
          created['invoice_number']?.toString() ??
          _invoiceNumberController.text;
      _showSnackBar('Purchase saved: $number', isSuccess: true);
      _handleNewPurchase();
    } catch (e) {
      _showSnackBar('Failed to save purchase: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(
    String message, {
    bool isSuccess = false,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? AppTheme.successColor
            : (isError ? AppTheme.errorColor : null),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        PurchaseShortcuts.newPurchase: _VoidCallbackIntent(_handleNewPurchase),
        PurchaseShortcuts.savePurchase: _VoidCallbackIntent(_savePurchase),
        PurchaseShortcuts.selectSupplier: _VoidCallbackIntent(_selectSupplier),
        PurchaseShortcuts.addItem: _VoidCallbackIntent(_addItem),
        PurchaseShortcuts.focusBarcode: _VoidCallbackIntent(
          () => _barcodeFocus.requestFocus(),
        ),
        PurchaseShortcuts.paymentDialog: _VoidCallbackIntent(
          _showPaymentDialog,
        ),
        PurchaseShortcuts.expenseTag: _VoidCallbackIntent(_selectExpenseTag),
      },
      child: Actions(
        actions: {
          _VoidCallbackIntent: CallbackAction<_VoidCallbackIntent>(
            onInvoke: (intent) => intent.callback(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: AppTheme.canvasColor,
            appBar: _buildAppBar(),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Item entry panel
                Expanded(flex: 3, child: _buildItemsPanel()),
                // Right: Summary panel
                SizedBox(width: 360, child: _buildSummaryPanel()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Purchase Entry'),
      backgroundColor: AppTheme.sidebarColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Tax inclusive toggle
        TextButton.icon(
          onPressed: () =>
              setState(() => _priceIncludesTax = !_priceIncludesTax),
          icon: Icon(
            _priceIncludesTax ? Icons.check_box : Icons.check_box_outline_blank,
            size: 18,
            color: _priceIncludesTax ? AppTheme.successColor : Colors.white70,
          ),
          label: const Text(
            'Tax Incl.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(width: 8),
        // Expense tag
        TextButton.icon(
          onPressed: _selectExpenseTag,
          icon: Icon(_expenseCategory.icon, size: 18, color: Colors.white70),
          label: Text(
            _expenseCategory.displayName,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(width: 8),
        // New button
        OutlinedButton.icon(
          onPressed: _handleNewPurchase,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New (Ctrl+N)'),
        ),
        const SizedBox(width: 8),
        // Save button
        FilledButton.icon(
          onPressed: _isSaving ? null : _savePurchase,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save, size: 18),
          label: Text(_isSaving ? 'Saving...' : 'Save (Ctrl+S)'),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildItemsPanel() {
    return Column(
      children: [
        // Supplier & Invoice Info
        _buildSupplierSection(),

        // Barcode/Item Entry
        _buildBarcodeSection(),

        // Items Table
        Expanded(child: _buildItemsTable()),

        // Keyboard shortcuts help
        _buildShortcutsHelp(),
      ],
    );
  }

  Widget _buildSupplierSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Supplier selection
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: _selectSupplier,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.store,
                        color: _selectedSupplierName.isEmpty
                            ? Colors.grey
                            : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedSupplierName.isEmpty
                                  ? 'Select Supplier (F4)'
                                  : _selectedSupplierName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _selectedSupplierName.isEmpty
                                    ? Colors.grey
                                    : AppTheme.slate800,
                              ),
                            ),
                            if (_selectedSupplierName.isNotEmpty)
                              Text(
                                'Tap to change',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Invoice number
            Expanded(
              child: TextField(
                controller: _invoiceNumberController,
                decoration: InputDecoration(
                  labelText: 'Supplier Invoice #',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Invoice date
            _buildDatePicker(
              label: 'Invoice Date',
              value: _invoiceDate,
              onChanged: (date) => setState(() => _invoiceDate = date),
            ),
            const SizedBox(width: 16),
            // Due date
            _buildDatePicker(
              label: 'Due Date',
              value: _dueDate ?? _invoiceDate.add(const Duration(days: 30)),
              onChanged: (date) => setState(() => _dueDate = date),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime value,
    required Function(DateTime) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) onChanged(date);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              '${value.day}/${value.month}/${value.year}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Barcode input
          Expanded(
            child: TextField(
              controller: _barcodeController,
              focusNode: _barcodeFocus,
              decoration: InputDecoration(
                hintText: 'Scan barcode or enter item code (F1)',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onSubmitted: _handleBarcodeSubmit,
            ),
          ),
          const SizedBox(width: 12),
          // Add item button
          FilledButton.icon(
            onPressed: _addItem,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Item (F2)'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: AppTheme.sidebarColor.withValues(alpha: 0.05),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 40,
                  child: Text(
                    '#',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Item',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(
                  width: 80,
                  child: Text(
                    'HSN',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(
                  width: 60,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Rate',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(
                  width: 60,
                  child: Text(
                    'GST%',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(
                  width: 100,
                  child: Text(
                    'Amount',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items list
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items added',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Press F2 or click "Add Item" to add items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) => _buildItemRow(index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    return InkWell(
      onTap: () => _editItem(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 40, child: Text('${index + 1}')),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (item.batchNumber != null)
                    Text(
                      'Batch: ${item.batchNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 80, child: Text(item.hsnCode ?? '-')),
            SizedBox(
              width: 60,
              child: Text('${item.quantity}', textAlign: TextAlign.center),
            ),
            SizedBox(
              width: 80,
              child: Text(
                item.purchasePrice.toStringAsFixed(2),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                '${item.gstRate.toInt()}%',
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                item.totalAmount.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(
              width: 50,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppTheme.errorColor,
                onPressed: () => _removeItem(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutsHelp() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.sidebarColor.withValues(alpha: 0.03),
      child: Row(
        children: [
          _shortcutChip('F1', 'Barcode'),
          _shortcutChip('F2', 'Add Item'),
          _shortcutChip('F4', 'Supplier'),
          _shortcutChip('F5', 'Payment'),
          _shortcutChip('F6', 'Expense Tag'),
          _shortcutChip('Ctrl+S', 'Save'),
          _shortcutChip('Ctrl+N', 'New'),
        ],
      ),
    );
  }

  Widget _shortcutChip(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              key,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.sidebarColor),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'Purchase Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Summary details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Items count
                  _summaryRow('Items', '${_items.length}'),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Total Quantity',
                    _items
                        .fold<int>(0, (sum, i) => sum + i.quantity.toInt())
                        .toString(),
                  ),

                  const Divider(height: 32),

                  // Amounts
                  _summaryRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _summaryRow('CGST', '₹${(_totalTax / 2).toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _summaryRow('SGST', '₹${(_totalTax / 2).toStringAsFixed(2)}'),

                  const Divider(height: 32),

                  // Grand total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '₹${_grandTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment section
                  InkWell(
                    onTap: _showPaymentDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: _paymentStatus.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Payment (F5)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.slate800,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _paymentStatus.color.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _paymentStatus.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _paymentStatus.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _summaryRow(
                            'Paid Amount',
                            '₹${_paidAmount.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 4),
                          _summaryRow(
                            'Balance Due',
                            '₹${_balanceAmount.toStringAsFixed(2)}',
                            valueColor: _balanceAmount > 0
                                ? AppTheme.errorColor
                                : AppTheme.successColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.slate500)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppTheme.slate800,
          ),
        ),
      ],
    );
  }
}

/// Supplier selection dialog
class _SupplierSelectionDialog extends StatefulWidget {
  final ApiService apiService;

  const _SupplierSelectionDialog({required this.apiService});

  @override
  State<_SupplierSelectionDialog> createState() =>
      _SupplierSelectionDialogState();
}

class _SupplierSelectionDialogState extends State<_SupplierSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _suppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _loading = true);
    try {
      final suppliers = await widget.apiService.getParties(
        partyType: 'SUPPLIER',
      );
      if (!mounted) return;
      setState(() {
        _suppliers
          ..clear()
          ..addAll(suppliers);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredSuppliers {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _suppliers;
    return _suppliers.where((supplier) {
      final name = (supplier['name'] ?? '').toString().toLowerCase();
      final gstin = (supplier['gstin'] ?? '').toString().toLowerCase();
      final phone = (supplier['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || gstin.contains(q) || phone.contains(q);
    }).toList();
  }

  Future<void> _createSupplier() async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _CreateSupplierDialog(),
    );
    if (payload == null) return;

    try {
      final created = await widget.apiService.createParty(payload);
      final createdId = created['id'];
      await _loadSuppliers();

      Map<String, dynamic>? selected;
      for (final supplier in _suppliers) {
        if (supplier['id'] == createdId) {
          selected = supplier;
          break;
        }
      }

      if (!mounted) return;
      if (selected != null) {
        Navigator.pop(context, {
          ...selected,
          'creditDays': selected['credit_days'] ?? 30,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier created. Select from list.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create supplier: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = _filteredSuppliers;

    return AlertDialog(
      title: const Text('Select Supplier'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search suppliers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : suppliers.isEmpty
                  ? const Center(child: Text('No suppliers found'))
                  : ListView.builder(
                      itemCount: suppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = suppliers[index];
                        final creditDays = supplier['credit_days'] ?? 30;
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.store)),
                          title: Text(
                            supplier['name'] as String? ?? 'Supplier',
                          ),
                          subtitle: Text(
                            (supplier['gstin'] as String?)?.isNotEmpty == true
                                ? 'GSTIN: ${supplier['gstin']}'
                                : (supplier['phone'] as String?)?.isNotEmpty ==
                                      true
                                ? 'Phone: ${supplier['phone']}'
                                : 'No details',
                          ),
                          trailing: Text('$creditDays days credit'),
                          onTap: () => Navigator.pop(context, {
                            ...supplier,
                            'creditDays': creditDays,
                          }),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _createSupplier,
          icon: const Icon(Icons.add),
          label: const Text('New Supplier'),
        ),
      ],
    );
  }
}

class _CreateSupplierDialog extends StatefulWidget {
  const _CreateSupplierDialog();

  @override
  State<_CreateSupplierDialog> createState() => _CreateSupplierDialogState();
}

class _CreateSupplierDialogState extends State<_CreateSupplierDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  final _creditDaysController = TextEditingController(text: '30');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _creditDaysController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final gstin = _gstinController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone are required')),
      );
      return;
    }

    if (gstin.isNotEmpty && gstin.length != 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GSTIN must be 15 characters')),
      );
      return;
    }

    Navigator.pop(context, {
      'party_type': 'SUPPLIER',
      'name': name,
      'phone': phone,
      'gstin': gstin.isEmpty ? null : gstin,
      'credit_days': int.tryParse(_creditDaysController.text.trim()) ?? 30,
      'credit_limit': 0,
      'opening_balance': 0,
      'balance_type': 'CR',
      'gst_registration_type': 'UNREGISTERED',
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Supplier'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Supplier Name *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gstinController,
              maxLength: 15,
              decoration: const InputDecoration(
                labelText: 'GSTIN',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _creditDaysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Credit Days',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}

/// Add purchase item dialog
class _AddPurchaseItemDialog extends StatefulWidget {
  final bool priceIncludesTax;
  final PurchaseItem? editItem;

  const _AddPurchaseItemDialog({required this.priceIncludesTax, this.editItem});

  @override
  State<_AddPurchaseItemDialog> createState() => _AddPurchaseItemDialogState();
}

class _AddPurchaseItemDialogState extends State<_AddPurchaseItemDialog> {
  final _nameController = TextEditingController();
  final _hsnController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _rateController = TextEditingController();
  final _batchController = TextEditingController();
  final _expiryController = TextEditingController();
  double _gstRate = 18;

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      _nameController.text = widget.editItem!.itemName;
      _hsnController.text = widget.editItem!.hsnCode ?? '';
      _qtyController.text = widget.editItem!.quantity.toString();
      _rateController.text = widget.editItem!.purchasePrice.toString();
      _batchController.text = widget.editItem!.batchNumber ?? '';
      _gstRate = widget.editItem!.gstRate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hsnController.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    _batchController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final qty = double.tryParse(_qtyController.text) ?? 1;
    final rate = double.tryParse(_rateController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter item name')));
      return;
    }

    if (rate <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid rate')));
      return;
    }

    final amount = qty * rate;
    final taxableAmount = widget.priceIncludesTax
        ? amount / (1 + _gstRate / 100)
        : amount;
    final taxAmount = taxableAmount * _gstRate / 100;

    final item = PurchaseItem(
      id:
          widget.editItem?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      itemId:
          widget.editItem?.itemId ??
          'ITEM-${DateTime.now().millisecondsSinceEpoch}',
      itemName: name,
      hsnCode: _hsnController.text.isEmpty ? null : _hsnController.text,
      quantity: qty,
      unit: 'PCS',
      purchasePrice: rate,
      mrp: rate * 1.3,
      sellingPrice: rate * 1.2,
      taxableAmount: taxableAmount,
      gstRate: _gstRate,
      cgstAmount: taxAmount / 2,
      sgstAmount: taxAmount / 2,
      totalAmount: taxableAmount + taxAmount,
      batchNumber: _batchController.text.isEmpty ? null : _batchController.text,
    );

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.editItem != null ? 'Edit Item' : 'Add Purchase Item'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hsnController,
                      decoration: const InputDecoration(
                        labelText: 'HSN Code',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<double>(
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
                      onChanged: (value) =>
                          setState(() => _gstRate = value ?? 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
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
                      decoration: InputDecoration(
                        labelText: 'Rate *',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        helperText: widget.priceIncludesTax
                            ? 'Tax Inclusive'
                            : 'Tax Exclusive',
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
                    child: TextField(
                      controller: _batchController,
                      decoration: const InputDecoration(
                        labelText: 'Batch Number',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'MM/YYYY',
                      ),
                    ),
                  ),
                ],
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
        FilledButton(
          onPressed: _save,
          child: Text(widget.editItem != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

/// Payment entry dialog
class _PaymentEntryDialog extends StatefulWidget {
  final double grandTotal;
  final double currentPaid;

  const _PaymentEntryDialog({
    required this.grandTotal,
    required this.currentPaid,
  });

  @override
  State<_PaymentEntryDialog> createState() => _PaymentEntryDialogState();
}

class _PaymentEntryDialogState extends State<_PaymentEntryDialog> {
  late TextEditingController _amountController;
  PaymentStatus _status = PaymentStatus.unpaid;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.currentPaid > 0 ? widget.currentPaid.toString() : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment Details'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grand Total: ₹${widget.grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Payment Status',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: PaymentStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(status.displayName),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _status = value ?? PaymentStatus.unpaid;
                  if (_status == PaymentStatus.paid) {
                    _amountController.text = widget.grandTotal.toString();
                  } else if (_status == PaymentStatus.unpaid) {
                    _amountController.text = '0';
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Paid',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              enabled: _status == PaymentStatus.partiallyPaid,
            ),
            const SizedBox(height: 8),
            // Quick amount buttons
            if (_status == PaymentStatus.partiallyPaid)
              Wrap(
                spacing: 8,
                children: [25, 50, 75, 100].map((pct) {
                  final amount = widget.grandTotal * pct / 100;
                  return ActionChip(
                    label: Text('$pct%'),
                    onPressed: () =>
                        _amountController.text = amount.toStringAsFixed(0),
                  );
                }).toList(),
              ),
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
            final amount = double.tryParse(_amountController.text) ?? 0;
            Navigator.pop(context, {'amount': amount, 'status': _status});
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Expense tag dialog
class _ExpenseTagDialog extends StatelessWidget {
  final ExpenseCategory currentCategory;

  const _ExpenseTagDialog({required this.currentCategory});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Expense Category'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ExpenseCategory.values.map((category) {
            final isSelected = category == currentCategory;
            return ListTile(
              leading: Icon(
                category.icon,
                color: isSelected ? AppTheme.primaryColor : null,
              ),
              title: Text(category.displayName),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              selected: isSelected,
              onTap: () => Navigator.pop(context, category),
            );
          }).toList(),
        ),
      ),
    );
  }
}
