/// Credit & Debit Notes Entry Screen
/// Combined module for Sales Returns (Credit Notes) and Purchase Returns (Debit Notes)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/services.dart';

class CreditDebitNotesScreen extends StatefulWidget {
  const CreditDebitNotesScreen({super.key});

  @override
  State<CreditDebitNotesScreen> createState() => _CreditDebitNotesScreenState();
}

class _CreditDebitNotesScreenState extends State<CreditDebitNotesScreen> {
  final _barcodeController = TextEditingController();
  final _barcodeFocus = FocusNode();
  final ApiService _api = ApiService();

  // Note type: 'credit' for sales return, 'debit' for purchase return
  String _noteType = 'credit';
  Map<String, dynamic>? _referenceInvoice;
  List<InvoiceItem> _returnItems = [];

  @override
  void initState() {
    super.initState();
    _barcodeFocus.requestFocus();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _selectReferenceInvoice() async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_noteType == 'credit' ? 'Select Sales Invoice' : 'Select Purchase Invoice'),
          content: const SizedBox(
            width: 600,
            child: Center(
              child: Text('Load invoices for selection'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Error loading invoices: $e');
    }
  }

  void _addReturnItem() {
    if (_referenceInvoice == null) {
      _showSnackBar('Select an invoice first');
      return;
    }
    _showSnackBar('Add items from barcode scan or select from reference invoice');
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    if (barcode.isEmpty) return;
    _barcodeController.clear();

    try {
      final item = await _api.getItemByBarcode(barcode);
      if (!mounted) return;
      
      if (item == null) {
        _showSnackBar('Item not found');
        _barcodeFocus.requestFocus();
        return;
      }

      final returnItem = InvoiceItem(
        itemName: item.name,
        quantity: 1,
        rate: 0,
      );

      setState(() {
        _returnItems.add(returnItem);
      });

      _showSnackBar('Item: ${item.name} added to return', isSuccess: true);
      _barcodeFocus.requestFocus();
    } catch (e) {
      _showSnackBar('Error: $e');
      _barcodeFocus.requestFocus();
    }
  }

  Future<void> _saveNote() async {
    if (_returnItems.isEmpty) {
      _showSnackBar('Add at least one item to return');
      return;
    }

    try {
      // Determine voucher type: SRET for credit note, PRET for debit note
      const creditNoteVoucherTypeId = 2; // Sales Return
      const debitNoteVoucherTypeId = 4;  // Purchase Return

      final voucherTypeId = _noteType == 'credit' ? creditNoteVoucherTypeId : debitNoteVoucherTypeId;

      final invoice = GSTInvoice(
        voucherTypeId: voucherTypeId,
        invoiceDate: DateTime.now(),
        partyName: _referenceInvoice?['party_name'] ?? 'Unknown',
        partyId: _referenceInvoice?['party_id'],
        items: _returnItems,
      );

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saving return note...'),
            ],
          ),
        ),
      );

      await _api.createInvoice(invoice);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      _showSnackBar('Return note saved successfully!', isSuccess: true);
      setState(() {
        _referenceInvoice = null;
        _returnItems = [];
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Error saving return note: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _returnItems.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.rate),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit & Debit Notes'),
        actions: [
          // Note Type Selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'credit', label: Text('Credit Note')),
                ButtonSegment(value: 'debit', label: Text('Debit Note')),
              ],
              selected: {_noteType},
              onSelectionChanged: (selected) {
                setState(() {
                  _noteType = selected.first;
                  _referenceInvoice = null;
                  _returnItems = [];
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          // Save button
          ElevatedButton.icon(
            onPressed: _saveNote,
            icon: const Icon(Icons.save),
            label: const Text('Save Note'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left Panel - Return Items
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Reference Invoice Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).cardColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: _referenceInvoice == null
                            ? const Text('No invoice selected')
                            : Text(
                                'Ref: ${_referenceInvoice!['invoice_number']} - ${_referenceInvoice!['party_name']}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectReferenceInvoice,
                        icon: const Icon(Icons.search),
                        label: const Text('Select Invoice'),
                      ),
                    ],
                  ),
                ),

                // Barcode/Item Scanner
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _barcodeController,
                          focusNode: _barcodeFocus,
                          decoration: InputDecoration(
                            hintText: 'Scan item barcode... (F1)',
                            prefixIcon: const Icon(Icons.qr_code_scanner),
                          ),
                          onSubmitted: _handleBarcodeScan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _addReturnItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                ),

                // Return Items Table
                Expanded(
                  child: _returnItems.isEmpty
                      ? const Center(
                          child: Text('Scan barcodes to add return items'),
                        )
                      : SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Item')),
                              DataColumn(label: Text('Qty')),
                              DataColumn(label: Text('Rate')),
                              DataColumn(label: Text('Amount')),
                              DataColumn(label: Text('')),
                            ],
                            rows: _returnItems
                                .asMap()
                                .entries
                                .map(
                                  (entry) => DataRow(
                                    cells: [
                                      DataCell(Text(entry.value.itemName)),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: TextField(
                                            decoration: const InputDecoration(isDense: true),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              setState(() {
                                                _returnItems[entry.key] = entry.value.copyWith(
                                                  quantity: double.tryParse(value) ?? 0,
                                                );
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: TextField(
                                            decoration: const InputDecoration(isDense: true),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              setState(() {
                                                _returnItems[entry.key] = entry.value.copyWith(
                                                  rate: double.tryParse(value) ?? 0,
                                                );
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '₹${(entry.value.quantity * entry.value.rate).toStringAsFixed(2)}',
                                        ),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _returnItems.removeAt(entry.key);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Right Panel - Return Summary
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                left: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Return Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Note Type', _noteType == 'credit' ? 'Credit Note' : 'Debit Note'),
                  _buildInfoRow('Items', '${_returnItems.length}'),
                  const Divider(),
                  _buildInfoRow('Subtotal', '₹${totalAmount.toStringAsFixed(2)}'),
                  _buildInfoRow('CGST (9%)', '₹${(totalAmount * 0.09).toStringAsFixed(2)}'),
                  _buildInfoRow('SGST (9%)', '₹${(totalAmount * 0.09).toStringAsFixed(2)}'),
                  const Divider(),
                  _buildInfoRow(
                    'Total',
                    '₹${(totalAmount * 1.18).toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
