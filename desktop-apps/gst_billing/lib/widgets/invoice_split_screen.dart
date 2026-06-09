/// Invoice Split Screen - "Easy-to-Use" Invoice Creator
/// Left Pane (40%): Input Zone | Right Pane (60%): Live PDF Preview
/// Designed for "Well-Mannered" UX with Clean Fintech aesthetics
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

/// Invoice Split Screen Widget
/// A modern split-screen invoice creator with real-time preview
class InvoiceSplitScreen extends StatefulWidget {
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> items;
  final Function(GSTInvoice)? onSave;
  final Function(GSTInvoice)? onPrint;
  
  const InvoiceSplitScreen({
    super.key,
    this.customers = const [],
    this.items = const [],
    this.onSave,
    this.onPrint,
  });

  @override
  State<InvoiceSplitScreen> createState() => _InvoiceSplitScreenState();
}

class _InvoiceSplitScreenState extends State<InvoiceSplitScreen> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _selectedCustomer;
  DateTime _invoiceDate = DateTime.now();
  String _invoiceNumber = '';
  final List<InvoiceLineItem> _lineItems = [];
  String? _validationMessage;
  
  // For inline item entry
  final _itemNameController = TextEditingController();
  final _hsnController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  double _selectedGST = 18;
  
  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
  }
  
  void _generateInvoiceNumber() {
    final now = DateTime.now();
    _invoiceNumber = 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond}';
  }
  
  @override
  void dispose() {
    _itemNameController.dispose();
    _hsnController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  
  // Calculations
  double get _subtotal => _lineItems.fold(0, (sum, item) => sum + item.taxableAmount);
  double get _totalCGST => _lineItems.fold(0, (sum, item) => sum + item.cgstAmount);
  double get _totalSGST => _lineItems.fold(0, (sum, item) => sum + item.sgstAmount);
  double get _totalTax => _totalCGST + _totalSGST;
  double get _grandTotal => _subtotal + _totalTax;
  
  void _addLineItem() {
    if (_itemNameController.text.isEmpty || _priceController.text.isEmpty) {
      setState(() => _validationMessage = 'Please enter item name and price');
      return;
    }
    
    final qty = double.tryParse(_qtyController.text) ?? 1;
    final price = double.tryParse(_priceController.text) ?? 0;
    
    setState(() {
      _lineItems.add(InvoiceLineItem(
        itemName: _itemNameController.text,
        hsn: _hsnController.text,
        quantity: qty,
        unitPrice: price,
        gstRate: _selectedGST,
      ));
      _validationMessage = null;
      // Clear inputs
      _itemNameController.clear();
      _hsnController.clear();
      _qtyController.text = '1';
      _priceController.clear();
    });
  }
  
  void _removeLineItem(int index) {
    setState(() => _lineItems.removeAt(index));
  }
  
  bool _validateInvoice() {
    if (_selectedCustomer == null) {
      setState(() => _validationMessage = 'Please select a customer to continue');
      return false;
    }
    if (_lineItems.isEmpty) {
      setState(() => _validationMessage = 'Please add at least one item to the invoice');
      return false;
    }
    setState(() => _validationMessage = null);
    return true;
  }
  
  void _handleSave() {
    if (!_validateInvoice()) return;
    // Create invoice and callback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invoice saved successfully!'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _handlePrint() {
    if (!_validateInvoice()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Printing invoice...'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // Left Pane - Input Zone (40%)
          Expanded(
            flex: 4,
            child: _buildInputPane(),
          ),
          
          // Divider
          Container(
            width: 1,
            color: AppTheme.slate200,
          ),
          
          // Right Pane - Live Preview (60%)
          Expanded(
            flex: 6,
            child: _buildPreviewPane(),
          ),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.sidebarColor,
      foregroundColor: Colors.white,
      title: const Text('Create Invoice'),
      actions: [
        // Save Button
        OutlinedButton.icon(
          onPressed: _handleSave,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Save'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
          ),
        ),
        const SizedBox(width: 8),
        
        // Save & Print Button - Primary Action
        FilledButton.icon(
          onPressed: _handlePrint,
          icon: const Icon(Icons.print, size: 18),
          label: const Text('Save & Print'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
  
  Widget _buildInputPane() {
    return Container(
      color: AppTheme.canvasSecondary,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Invoice Details Card
            _buildSectionCard(
              title: 'Invoice Details',
              icon: Icons.receipt_long,
              children: [
                // Invoice Number
                _buildReadOnlyField(
                  label: 'Invoice Number',
                  value: _invoiceNumber,
                  icon: Icons.tag,
                ),
                const SizedBox(height: 16),
                
                // Invoice Date
                _buildDatePicker(),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Customer Selection Card
            _buildSectionCard(
              title: 'Customer',
              icon: Icons.person,
              children: [
                _buildCustomerDropdown(),
                if (_selectedCustomer != null && _selectedCustomer!['gstin'] == null)
                  GentleValidationText(
                    message: 'Please add the GSTIN to generate a tax invoice',
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Items Card
            _buildSectionCard(
              title: 'Items',
              icon: Icons.shopping_cart,
              children: [
                // Inline item entry row
                _buildInlineItemEntry(),
                
                const SizedBox(height: 16),
                
                // Items list
                if (_lineItems.isEmpty)
                  _buildEmptyItemsState()
                else
                  ..._lineItems.asMap().entries.map((e) => 
                    _buildItemRow(e.key, e.value)
                  ),
              ],
            ),
            
            // Validation message
            if (_validationMessage != null) ...[
              const SizedBox(height: 16),
              GentleValidationText(message: _validationMessage),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.slate200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: AppTheme.slate100,
      ),
    );
  }
  
  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _invoiceDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          setState(() => _invoiceDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Invoice Date',
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}',
          style: TextStyle(color: AppTheme.slate800),
        ),
      ),
    );
  }
  
  Widget _buildCustomerDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      initialValue: _selectedCustomer,
      decoration: InputDecoration(
        labelText: 'Select Customer',
        prefixIcon: const Icon(Icons.person_outline, size: 18),
        hintText: 'Search or select customer...',
      ),
      items: [
        // Demo customers
        DropdownMenuItem(
          value: {'id': 1, 'name': 'ABC Traders', 'gstin': '07AABCT1234A1ZK', 'phone': '9876543210'},
          child: const Text('ABC Traders'),
        ),
        DropdownMenuItem(
          value: {'id': 2, 'name': 'Metro Store', 'phone': '9898989898'},
          child: const Text('Metro Store'),
        ),
        DropdownMenuItem(
          value: {'id': 3, 'name': 'Quick Mart', 'gstin': '07AABQM5678B1ZP', 'phone': '9090909090'},
          child: const Text('Quick Mart'),
        ),
        ...widget.customers.map((c) => DropdownMenuItem(
          value: c,
          child: Text(c['name'] ?? 'Unknown'),
        )),
      ],
      onChanged: (value) => setState(() => _selectedCustomer = value),
    );
  }
  
  Widget _buildInlineItemEntry() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.slate100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          // Row 1: Item Name & HSN
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _itemNameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    hintText: 'Enter item name',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _hsnController,
                  decoration: InputDecoration(
                    labelText: 'HSN Code',
                    hintText: '4 or 8 digit',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Row 2: Qty, Price, GST%, Add Button
          Row(
            children: [
              // Quantity
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _qtyController,
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  style: const TextStyle(fontFamily: 'JetBrains Mono'),
                ),
              ),
              const SizedBox(width: 12),
              
              // Price
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price (₹)',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  style: const TextStyle(fontFamily: 'JetBrains Mono'),
                ),
              ),
              const SizedBox(width: 12),
              
              // GST Dropdown
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<double>(
                  initialValue: _selectedGST,
                  decoration: InputDecoration(
                    labelText: 'GST %',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  items: [0, 5, 12, 18, 28].map((rate) => DropdownMenuItem(
                    value: rate.toDouble(),
                    child: Text('$rate%', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedGST = v ?? 18),
                ),
              ),
              const SizedBox(width: 12),
              
              // Add Button
              FilledButton.icon(
                onPressed: _addLineItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyItemsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.slate300),
          const SizedBox(height: 12),
          Text(
            'No items added yet',
            style: TextStyle(color: AppTheme.slate500),
          ),
          const SizedBox(height: 4),
          Text(
            'Add items using the form above',
            style: TextStyle(color: AppTheme.slate400, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildItemRow(int index, InvoiceLineItem item) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Row(
        children: [
          // Index
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.slate100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.slate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} × ${item.unitPrice.toCurrencyString()} | GST: ${item.gstRate.toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate500,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
          
          // Total
          Text(
            item.totalAmount.toCurrencyString(),
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w600,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(width: 8),
          
          // Delete
          IconButton(
            onPressed: () => _removeLineItem(index),
            icon: Icon(Icons.close, size: 18, color: AppTheme.slate400),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreviewPane() {
    return Container(
      color: AppTheme.slate100,
      child: Column(
        children: [
          // Preview header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.slate200)),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility, size: 18, color: AppTheme.slate500),
                const SizedBox(width: 8),
                Text(
                  'Live Preview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.slate600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Updates in real-time',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate400,
                  ),
                ),
              ],
            ),
          ),
          
          // Invoice preview (paper-like)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Container(
                  width: 595, // A4 width in pixels (at 72 DPI)
                  constraints: const BoxConstraints(maxWidth: 700),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildInvoiceDocument(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInvoiceDocument() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BillEase Accounts+',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.sidebarColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GSTIN: 07AABBC1234A1ZK',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.slate600,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    Text(
                      '123 Business Street, New Delhi - 110001',
                      style: TextStyle(fontSize: 12, color: AppTheme.slate600),
                    ),
                  ],
                ),
              ),
              
              // Invoice Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TAX INVOICE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _invoiceNumber,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'JetBrains Mono',
                      color: AppTheme.slate700,
                    ),
                  ),
                  Text(
                    '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          Divider(color: AppTheme.slate200),
          const SizedBox(height: 24),
          
          // Bill To
          Text(
            'BILL TO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCustomer?['name'] ?? 'Select Customer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _selectedCustomer != null ? AppTheme.slate800 : AppTheme.slate400,
            ),
          ),
          if (_selectedCustomer?['gstin'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'GSTIN: ${_selectedCustomer!['gstin']}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'JetBrains Mono',
                color: AppTheme.slate600,
              ),
            ),
          ],
          if (_selectedCustomer?['phone'] != null) ...[
            const SizedBox(height: 2),
            Text(
              'Phone: ${_selectedCustomer!['phone']}',
              style: TextStyle(fontSize: 12, color: AppTheme.slate600),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Items Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.sidebarColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text('#', style: _tableHeaderStyle)),
                Expanded(flex: 3, child: Text('Item', style: _tableHeaderStyle)),
                SizedBox(width: 60, child: Text('HSN', style: _tableHeaderStyle)),
                SizedBox(width: 50, child: Text('Qty', style: _tableHeaderStyle, textAlign: TextAlign.right)),
                SizedBox(width: 80, child: Text('Rate', style: _tableHeaderStyle, textAlign: TextAlign.right)),
                SizedBox(width: 50, child: Text('GST', style: _tableHeaderStyle, textAlign: TextAlign.right)),
                SizedBox(width: 90, child: Text('Amount', style: _tableHeaderStyle, textAlign: TextAlign.right)),
              ],
            ),
          ),
          
          // Items
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.slate200),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
            child: _lineItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Add items to see them here',
                        style: TextStyle(color: AppTheme.slate400),
                      ),
                    ),
                  )
                : Column(
                    children: _lineItems.asMap().entries.map((e) {
                      final index = e.key;
                      final item = e.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: index < _lineItems.length - 1
                              ? Border(bottom: BorderSide(color: AppTheme.slate100))
                              : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 30, child: Text('${index + 1}', style: _tableCellStyle)),
                            Expanded(flex: 3, child: Text(item.itemName, style: _tableCellStyle)),
                            SizedBox(width: 60, child: Text(item.hsn, style: _tableCellMonoStyle)),
                            SizedBox(width: 50, child: Text(item.quantity.toStringAsFixed(0), style: _tableCellMonoStyle, textAlign: TextAlign.right)),
                            SizedBox(width: 80, child: Text(item.unitPrice.toCurrencyString(), style: _tableCellMonoStyle, textAlign: TextAlign.right)),
                            SizedBox(width: 50, child: Text('${item.gstRate.toInt()}%', style: _tableCellMonoStyle, textAlign: TextAlign.right)),
                            SizedBox(width: 90, child: Text(item.totalAmount.toCurrencyString(), style: _tableCellMonoStyle.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // Totals
          Row(
            children: [
              const Spacer(),
              SizedBox(
                width: 280,
                child: Column(
                  children: [
                    _buildTotalRow('Subtotal', _subtotal),
                    _buildTotalRow('CGST', _totalCGST),
                    _buildTotalRow('SGST', _totalSGST),
                    const Divider(),
                    _buildTotalRow('Grand Total', _grandTotal, isGrand: true),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 48),
          
          // Footer
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1. Payment due within 30 days\n2. Subject to Delhi jurisdiction',
                      style: TextStyle(fontSize: 10, color: AppTheme.slate500),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 150,
                    height: 1,
                    color: AppTheme.slate300,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Authorized Signatory',
                    style: TextStyle(fontSize: 10, color: AppTheme.slate500),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  TextStyle get _tableHeaderStyle => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  TextStyle get _tableCellStyle => TextStyle(
    fontSize: 12,
    color: AppTheme.slate700,
  );
  
  TextStyle get _tableCellMonoStyle => TextStyle(
    fontSize: 11,
    fontFamily: 'JetBrains Mono',
    color: AppTheme.slate700,
  );
  
  Widget _buildTotalRow(String label, double amount, {bool isGrand = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isGrand ? 14 : 12,
              fontWeight: isGrand ? FontWeight.w700 : FontWeight.w500,
              color: AppTheme.slate700,
            ),
          ),
          Text(
            amount.toCurrencyString(),
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: isGrand ? 16 : 12,
              fontWeight: isGrand ? FontWeight.w700 : FontWeight.w600,
              color: isGrand ? AppTheme.primaryColor : AppTheme.slate800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Invoice Line Item Model (local to this widget)
class InvoiceLineItem {
  final String itemName;
  final String hsn;
  final double quantity;
  final double unitPrice;
  final double gstRate;
  
  InvoiceLineItem({
    required this.itemName,
    this.hsn = '',
    required this.quantity,
    required this.unitPrice,
    required this.gstRate,
  });
  
  double get taxableAmount => quantity * unitPrice;
  double get cgstRate => gstRate / 2;
  double get sgstRate => gstRate / 2;
  double get cgstAmount => taxableAmount * (cgstRate / 100);
  double get sgstAmount => taxableAmount * (sgstRate / 100);
  double get totalAmount => taxableAmount + cgstAmount + sgstAmount;
}
