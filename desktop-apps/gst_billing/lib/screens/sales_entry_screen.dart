/// Sales Entry Screen
/// Main billing/invoice creation screen with barcode scanning and HSN lookup
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

/// Keyboard shortcuts for quick actions
class BillingShortcuts {
  static const newInvoice = SingleActivator(
    LogicalKeyboardKey.keyN,
    control: true,
  );
  static const saveInvoice = SingleActivator(
    LogicalKeyboardKey.keyS,
    control: true,
  );
  static const printInvoice = SingleActivator(
    LogicalKeyboardKey.keyP,
    control: true,
  );
  static const shareInvoice = SingleActivator(
    LogicalKeyboardKey.keyW,
    control: true,
    shift: true,
  );
  static const searchItem = SingleActivator(LogicalKeyboardKey.f2);
  static const hsnLookup = SingleActivator(LogicalKeyboardKey.f3);
  static const selectParty = SingleActivator(LogicalKeyboardKey.f4);
  static const paymentDialog = SingleActivator(LogicalKeyboardKey.f5);
  static const focusBarcode = SingleActivator(LogicalKeyboardKey.f1);
  static const toggleTaxInclusive = SingleActivator(
    LogicalKeyboardKey.keyT,
    control: true,
  );
}

/// Intent for void callbacks
class VoidCallbackIntent extends Intent {
  final VoidCallback callback;
  const VoidCallbackIntent(this.callback);
}

class SalesEntryScreen extends StatefulWidget {
  const SalesEntryScreen({super.key});

  @override
  State<SalesEntryScreen> createState() => _SalesEntryScreenState();
}

class _SalesEntryScreenState extends State<SalesEntryScreen> {
  final _barcodeController = TextEditingController();
  final _barcodeFocus = FocusNode();
  final _searchController = TextEditingController();

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _barcodeFocus.requestFocus();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Keyboard shortcut handlers
  void _handleNewInvoice() {
    context.read<BillingProvider>().newInvoice();
    _barcodeFocus.requestFocus();
  }

  Future<void> _handleSaveAndPrint() async {
    final billing = context.read<BillingProvider>();
    final result = await billing.saveInvoice();
    if (result != null) {
      _showSnackBar('Invoice saved!', isSuccess: true);
      await billing.printInvoice();
    }
  }

  Future<void> _handlePrint() async {
    await context.read<BillingProvider>().printInvoice();
  }

  Future<void> _handleShare() async {
    await context.read<BillingProvider>().shareInvoice();
  }

  void _toggleTaxInclusive() {
    final billing = context.read<BillingProvider>();
    billing.setTaxInclusiveMode(!billing.priceIncludesTax);
    _showSnackBar(
      billing.priceIncludesTax
          ? 'Tax-inclusive pricing ON'
          : 'Tax-exclusive pricing ON',
      isSuccess: true,
    );
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    if (barcode.isEmpty) return;

    final billing = context.read<BillingProvider>();

    try {
      final item = await _api.getItemByBarcode(barcode);
      if (item != null) {
        final added = billing.addItemFromSearch(item);
        if (added) {
          _barcodeController.clear();
          _showSnackBar('Added: ${item.name}', isSuccess: true);
        } else {
          _showSnackBar(billing.error ?? 'Unable to add item', isError: true);
        }
      } else {
        _showSnackBar('Item not found: $barcode', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }

    _barcodeFocus.requestFocus();
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

  Future<void> _selectParty() async {
    final app = context.read<AppProvider>();
    final billing = context.read<BillingProvider>();

    final party = await showDialog<Ledger>(
      context: context,
      builder: (context) => PartySelectionDialog(
        parties: app.parties,
        onSearch: app.searchParties,
        onCreateNew: () async {
          // Show create party dialog
          final newParty = await showDialog<Ledger>(
            context: context,
            builder: (context) => const CreatePartyDialog(),
          );
          return newParty;
        },
      ),
    );

    if (party != null) {
      billing.setParty(party);
    }
  }

  Future<void> _showPaymentDialog() async {
    final billing = context.read<BillingProvider>();

    await showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        grandTotal: billing.grandTotal,
        currentPaid: billing.currentInvoice.paidAmount,
        onSave: (mode, amount, reference) {
          billing.setPaymentDetails(
            mode: mode,
            paidAmount: amount,
            reference: reference,
          );
        },
      ),
    );
  }

  Future<void> _saveInvoice() async {
    final billing = context.read<BillingProvider>();

    final validationErrors = billing.validateInvoiceForPosting();
    if (validationErrors.isNotEmpty) {
      _showSnackBar(validationErrors.first, isError: true);
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Party: ${billing.currentInvoice.partyName}'),
            Text('Items: ${billing.items.length}'),
            const SizedBox(height: 8),
            Text(
              'Grand Total: ${billing.grandTotal.toCurrencyString()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save & Print'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await billing.saveInvoice();

    if (result != null) {
      _showSnackBar(
        'Invoice ${result['invoice_number']} saved successfully!',
        isSuccess: true,
      );
      await billing.printInvoice();
    } else if (billing.error != null) {
      _showSnackBar(billing.error!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        BillingShortcuts.newInvoice: VoidCallbackIntent(_handleNewInvoice),
        BillingShortcuts.saveInvoice: VoidCallbackIntent(_handleSaveAndPrint),
        BillingShortcuts.printInvoice: VoidCallbackIntent(_handlePrint),
        BillingShortcuts.shareInvoice: VoidCallbackIntent(_handleShare),
        BillingShortcuts.searchItem: VoidCallbackIntent(_showItemSearchDialog),
        BillingShortcuts.hsnLookup: VoidCallbackIntent(_showHSNLookupDialog),
        BillingShortcuts.selectParty: VoidCallbackIntent(_selectParty),
        BillingShortcuts.paymentDialog: VoidCallbackIntent(_showPaymentDialog),
        BillingShortcuts.focusBarcode: VoidCallbackIntent(
          () => _barcodeFocus.requestFocus(),
        ),
        BillingShortcuts.toggleTaxInclusive: VoidCallbackIntent(
          _toggleTaxInclusive,
        ),
      },
      child: Actions(
        actions: {
          VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
            onInvoke: (intent) => intent.callback(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Sales Invoice'),
              elevation: 0,
              actions: [
                // Tax inclusive toggle
                Consumer<BillingProvider>(
                  builder: (context, billing, _) {
                    return TextButton.icon(
                      onPressed: _toggleTaxInclusive,
                      icon: Icon(
                        billing.priceIncludesTax
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 18,
                      ),
                      label: const Text('Tax Incl.'),
                      style: TextButton.styleFrom(
                        foregroundColor: billing.priceIncludesTax
                            ? AppTheme.successColor
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Save button
                Consumer<BillingProvider>(
                  builder: (context, billing, _) {
                    return Tooltip(
                      message: 'Save Invoice (Ctrl+S)',
                      child: FilledButton.tonalIcon(
                        onPressed: billing.items.isNotEmpty
                            ? _handleSaveAndPrint
                            : null,
                        icon: const Icon(Icons.save, size: 20),
                        label: const Text('Save'),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Print button
                Consumer<BillingProvider>(
                  builder: (context, billing, _) {
                    return Tooltip(
                      message: 'Print Invoice (Ctrl+P)',
                      child: FilledButton.tonalIcon(
                        onPressed: billing.items.isNotEmpty
                            ? _handlePrint
                            : null,
                        icon: const Icon(Icons.print, size: 20),
                        label: const Text('Print'),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Share button
                Consumer<BillingProvider>(
                  builder: (context, billing, _) {
                    return Tooltip(
                      message: 'Share Invoice (Ctrl+Shift+W)',
                      child: FilledButton.tonalIcon(
                        onPressed: billing.items.isNotEmpty
                            ? _handleShare
                            : null,
                        icon: const Icon(Icons.share, size: 20),
                        label: const Text('Share'),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // New Invoice button
                FilledButton.tonalIcon(
                  onPressed: _handleNewInvoice,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('New'),
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: Row(
              children: [
                // Left Panel - Items Entry
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Barcode & Search Section
                      _buildSearchSection(),

                      // Items Table
                      Expanded(child: _buildItemsTable()),

                      // Tax Summary at bottom
                      _buildTaxSummary(),
                    ],
                  ),
                ),

                // Right Panel - Invoice Details
                Container(
                  width: 360,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      left: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: _buildInvoicePanel(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Barcode Input
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  focusNode: _barcodeFocus,
                  decoration: InputDecoration(
                    hintText: 'Scan barcode or enter item code... (F1)',
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () =>
                          _handleBarcodeScan(_barcodeController.text),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _handleBarcodeScan,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Search Button
              FilledButton.tonalIcon(
                onPressed: _showItemSearchDialog,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Search (F2)'),
              ),
              const SizedBox(width: 8),

              // HSN Lookup Button
              FilledButton.tonalIcon(
                onPressed: _showHSNLookupDialog,
                icon: const Icon(Icons.category, size: 18),
                label: const Text('HSN (F3)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Consumer<BillingProvider>(
      builder: (context, billing, _) {
        if (billing.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Scan barcode or search items to add',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'F1: Barcode | F2: Search | F3: HSN | F4: Party | F5: Payment',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ctrl+N: New | Ctrl+S: Save | Ctrl+P: Print | Ctrl+Shift+W: Share',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: DataTable(
            columnSpacing: 16,
            headingRowHeight: 48,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Item')),
              DataColumn(label: Text('HSN')),
              DataColumn(label: Text('Qty'), numeric: true),
              DataColumn(label: Text('Rate'), numeric: true),
              DataColumn(label: Text('Disc'), numeric: true),
              DataColumn(label: Text('Taxable'), numeric: true),
              DataColumn(label: Text('GST'), numeric: true),
              DataColumn(label: Text('Amount'), numeric: true),
              DataColumn(label: Text('')),
            ],
            rows: billing.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return DataRow(
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.barcode != null)
                          Text(
                            item.barcode!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  DataCell(Text(item.hsnCode ?? '-')),
                  DataCell(
                    _buildEditableCell(
                      value: item.quantity,
                      onChanged: (val) => billing.updateQuantity(index, val),
                    ),
                  ),
                  DataCell(
                    _buildEditableCell(
                      value: item.rate,
                      onChanged: (val) => billing.updateRate(index, val),
                    ),
                  ),
                  DataCell(Text(item.discountAmount.toStringAsFixed(2))),
                  DataCell(Text(item.taxableAmount.toStringAsFixed(2))),
                  DataCell(
                    Text(
                      '${item.gstRate.toStringAsFixed(0)}%',
                      style: TextStyle(color: AppTheme.infoColor),
                    ),
                  ),
                  DataCell(
                    Text(
                      item.totalAmount.toStringAsFixed(2),
                      style: AppStyles.currencyStyle(context),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                      onPressed: () => billing.removeItem(index),
                      iconSize: 20,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEditableCell({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final result = await showDialog<double>(
          context: context,
          builder: (context) =>
              NumberInputDialog(title: 'Enter Value', initialValue: value),
        );
        if (result != null) {
          onChanged(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(value.toStringAsFixed(2)),
      ),
    );
  }

  Widget _buildTaxSummary() {
    return Consumer<BillingProvider>(
      builder: (context, billing, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'TAX SUMMARY',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!billing.isInterState) ...[
                    Expanded(child: _taxChip('CGST', billing.totalCGST, AppTheme.cgstColor)),
                    const SizedBox(width: 8),
                    Expanded(child: _taxChip('SGST', billing.totalSGST, AppTheme.sgstColor)),
                  ] else
                    Expanded(child: _taxChip('IGST', billing.totalIGST, AppTheme.igstColor)),
                  if (billing.totalCess > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(child: _taxChip('CESS', billing.totalCess, AppTheme.cessColor)),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Tax',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          billing.totalTax.toCurrencyString(),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          billing.grandTotal.toCurrencyString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _taxChip(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount.toCurrencyString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicePanel() {
    return Consumer2<BillingProvider, AppProvider>(
      builder: (context, billing, app, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Party Selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppStyles.sectionHeader(context, 'Customer'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectParty,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.05),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: billing.selectedParty != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  billing.selectedParty!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (billing.selectedParty!.gstin != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'GSTIN: ${billing.selectedParty!.gstin}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                if (billing.selectedParty!.phone != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Phone: ${billing.selectedParty!.phone}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Row(
                              children: [
                                Icon(
                                  Icons.person_add,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Tap to select or add customer',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Invoice Details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice Info Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.03),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.15),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date
                          _buildDetailRow(
                            'Invoice Date',
                            _formatDate(billing.currentInvoice.invoiceDate),
                            icon: Icons.calendar_today,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    billing.currentInvoice.invoiceDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 7)),
                              );
                              if (date != null) {
                                billing.setInvoiceDate(date);
                              }
                            },
                          ),
                          const SizedBox(height: 8),

                          // Place of Supply
                          _buildDetailRow(
                            'Place of Supply',
                            app
                                    .getStateByCode(
                                      billing.currentInvoice.placeOfSupply ??
                                          app.companyStateCode,
                                    )
                                    ?.name ??
                                'Select',
                            icon: Icons.location_on,
                            highlight: billing.isInterState,
                            highlightText: billing.isInterState
                                ? '(Inter-State)'
                                : null,
                            onTap: () async {
                              final state = await showDialog<IndianState>(
                                context: context,
                                builder: (context) =>
                                    StateSelectionDialog(states: app.states),
                              );
                              if (state != null) {
                                billing.setPlaceOfSupply(state.code);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    AppStyles.sectionHeader(context, 'Amount Summary'),

                    // Amount breakdown
                    AppStyles.amountDisplay(
                      context,
                      'Subtotal',
                      billing.subtotal,
                    ),
                    const SizedBox(height: 8),
                    AppStyles.amountDisplay(
                      context,
                      'Discount',
                      -billing.totalDiscount,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(height: 8),
                    AppStyles.amountDisplay(
                      context,
                      'Taxable Amount',
                      billing.totalTaxable,
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (!billing.isInterState) ...[
                            AppStyles.amountDisplay(
                              context,
                              'CGST',
                              billing.totalCGST,
                              color: AppTheme.cgstColor,
                            ),
                            const SizedBox(height: 6),
                            AppStyles.amountDisplay(
                              context,
                              'SGST',
                              billing.totalSGST,
                              color: AppTheme.sgstColor,
                            ),
                          ] else
                            AppStyles.amountDisplay(
                              context,
                              'IGST',
                              billing.totalIGST,
                              color: AppTheme.igstColor,
                            ),
                          if (billing.totalCess > 0) ...[
                            const SizedBox(height: 6),
                            AppStyles.amountDisplay(
                              context,
                              'Cess',
                              billing.totalCess,
                              color: AppTheme.cessColor,
                            ),
                          ],
                          const SizedBox(height: 6),
                          AppStyles.amountDisplay(
                            context,
                            'Round Off',
                            billing.currentInvoice.roundOffAmount,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    AppStyles.amountDisplay(
                      context,
                      'Grand Total',
                      billing.grandTotal,
                      highlight: true,
                    ),

                    const SizedBox(height: 20),
                    AppStyles.sectionHeader(context, 'Payment Method'),

                    // Payment Mode Toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: SegmentedButton<PaymentMode>(
                        segments: const [
                          ButtonSegment(
                            value: PaymentMode.cash,
                            label: Text('Cash'),
                            icon: Icon(Icons.money, size: 18),
                          ),
                          ButtonSegment(
                            value: PaymentMode.credit,
                            label: Text('Credit'),
                            icon: Icon(Icons.credit_card, size: 18),
                          ),
                        ],
                        selected: {billing.currentInvoice.paymentMode ?? PaymentMode.cash},
                        onSelectionChanged: (Set<PaymentMode> newSelection) {
                          final selectedMode = newSelection.first;
                          if (selectedMode == PaymentMode.cash) {
                            billing.setPaymentDetails(
                              mode: PaymentMode.cash,
                              paidAmount: billing.grandTotal,
                            );
                          } else {
                            billing.setAsCreditSale();
                          }
                        },
                        showSelectedIcon: true,
                        multiSelectionEnabled: false,
                        style: SegmentedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                    // Payment details card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.05),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                billing.currentInvoice.paymentMode ==
                                        PaymentMode.credit
                                    ? 'Credit Outstanding'
                                    : 'Amount Received',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                billing.currentInvoice.paymentMode ==
                                        PaymentMode.credit
                                    ? billing.outstandingBalance
                                        .toCurrencyString()
                                    : billing.currentInvoice.paidAmount
                                        .toCurrencyString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: billing.currentInvoice.paymentMode ==
                                          PaymentMode.credit
                                      ? AppTheme.warningColor
                                      : AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (billing.currentInvoice.paymentMode ==
                              PaymentMode.cash)
                            InkWell(
                              onTap: _showPaymentDialog,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Edit Payment',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 12,
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
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: billing.items.isNotEmpty
                          ? _saveInvoice
                          : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: billing.items.isNotEmpty
                                ? Colors.white
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Save Invoice',
                            style: TextStyle(
                              fontSize: 16,
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
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    IconData? icon,
    VoidCallback? onTap,
    bool highlight = false,
    String? highlightText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 8),
            ],
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: highlight ? AppTheme.warningColor : null,
              ),
            ),
            if (highlightText != null) ...[
              const SizedBox(width: 4),
              Text(
                highlightText,
                style: TextStyle(fontSize: 11, color: AppTheme.warningColor),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showItemSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => ItemSearchDialog(
        onItemSelected: (item) {
          final billing = context.read<BillingProvider>();
          final added = billing.addItemFromSearch(item);
          if (!added) {
            _showSnackBar(billing.error ?? 'Unable to add item', isError: true);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showHSNLookupDialog() {
    showDialog(context: context, builder: (context) => const HSNLookupDialog());
  }
}
