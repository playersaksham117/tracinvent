/// Reusable Dialog Widgets for GST Billing
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';

/// Item Search Dialog
class ItemSearchDialog extends StatefulWidget {
  final Function(ItemSearchResult) onItemSelected;

  const ItemSearchDialog({super.key, required this.onItemSelected});

  @override
  State<ItemSearchDialog> createState() => _ItemSearchDialogState();
}

class _ItemSearchDialogState extends State<ItemSearchDialog> {
  final _searchController = TextEditingController();
  final _api = ApiService();
  List<ItemSearchResult> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      _results = await _api.searchItems('');
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _loadItems();
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      _results = await _api.searchItems(query);
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Item',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search by name, barcode, or HSN...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, 
                                size: 48, 
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              const Text('No items found'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    item.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.barcode ?? 'No Barcode'} | HSN: ${item.hsnCode ?? 'N/A'} | GST: ${item.gstRate}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    item.sellingPrice.toCurrencyString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Stock: ${item.currentStock}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: item.currentStock > 0 
                                          ? AppTheme.successColor 
                                          : AppTheme.errorColor,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => widget.onItemSelected(item),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// HSN Lookup Dialog
class HSNLookupDialog extends StatefulWidget {
  const HSNLookupDialog({super.key});

  @override
  State<HSNLookupDialog> createState() => _HSNLookupDialogState();
}

class _HSNLookupDialogState extends State<HSNLookupDialog> {
  final _searchController = TextEditingController();
  final _api = ApiService();
  List<HSNCode> _results = [];
  bool _isLoading = false;

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      _results = await _api.searchHSNCodes(query);
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HSN/SAC Code Lookup',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search HSN code or description...',
                prefixIcon: Icon(Icons.category),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category_outlined, 
                                size: 48, 
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              const Text('Enter HSN code or description to search'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final hsn = _results[index];
                            return Card(
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8, 
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        hsn.code,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('GST: ${hsn.gstRate}%'),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(hsn.description),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Party Selection Dialog
class PartySelectionDialog extends StatefulWidget {
  final List<Ledger> parties;
  final Function(String) onSearch;
  final Future<Ledger?> Function() onCreateNew;

  const PartySelectionDialog({
    super.key,
    required this.parties,
    required this.onSearch,
    required this.onCreateNew,
  });

  @override
  State<PartySelectionDialog> createState() => _PartySelectionDialogState();
}

class _PartySelectionDialogState extends State<PartySelectionDialog> {
  final _searchController = TextEditingController();
  List<Ledger> _filteredParties = [];

  @override
  void initState() {
    super.initState();
    _filteredParties = widget.parties;
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredParties = widget.parties);
      return;
    }
    
    setState(() {
      _filteredParties = widget.parties.where((p) {
        final name = p.name.toLowerCase();
        final gstin = p.gstin?.toLowerCase() ?? '';
        final phone = p.phone?.toLowerCase() ?? '';
        final q = query.toLowerCase();
        return name.contains(q) || gstin.contains(q) || phone.contains(q);
      }).toList();
    });
    
    widget.onSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Party',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () async {
                    final newParty = await widget.onCreateNew();
                    if (newParty != null && context.mounted) {
                      Navigator.pop(context, newParty);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Party'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search by name, GSTIN, or phone...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredParties.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search, 
                            size: 48, 
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          const Text('No parties found'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final newParty = await widget.onCreateNew();
                              if (newParty != null && context.mounted) {
                                Navigator.pop(context, newParty);
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create New'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredParties.length,
                      itemBuilder: (context, index) {
                        final party = _filteredParties[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: Text(
                              party.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(party.name),
                          subtitle: Text(
                            party.gstin ?? party.phone ?? 'No details',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: party.currentBalance != 0
                              ? Text(
                                  party.currentBalance.toCurrencyString(),
                                  style: TextStyle(
                                    color: party.currentBalance > 0
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, party),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Create Party Dialog
class CreatePartyDialog extends StatefulWidget {
  const CreatePartyDialog({super.key});

  @override
  State<CreatePartyDialog> createState() => _CreatePartyDialogState();
}

class _CreatePartyDialogState extends State<CreatePartyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _partyType = 'CUSTOMER';
  final String _stateCode = '27'; // Maharashtra default
  bool _isSaving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final api = ApiService();
      // Create Party (backend auto-assigns ledger group by business type)
      final partyData = await api.createParty({
        'party_type': _partyType,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gstin': _gstinController.text.isEmpty ? null : _gstinController.text.trim(),
        'billing_address': _addressController.text.isEmpty ? null : _addressController.text.trim(),
        'billing_state_code': _stateCode,
      });

      final ledgerId = partyData['ledger_id'] as int?;
      if (ledgerId == null) {
        throw Exception('Party created but ledger not returned');
      }

      final createdLedger = await api.getLedger(ledgerId);
      
      if (context.mounted) {
        Navigator.pop(context, createdLedger);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
    
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Party',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Party Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _partyType,
                decoration: const InputDecoration(
                  labelText: 'Business Type *',
                  prefixIcon: Icon(Icons.business),
                ),
                items: const [
                  DropdownMenuItem(value: 'CUSTOMER', child: Text('Customer (Sundry Debtors)')),
                  DropdownMenuItem(value: 'SUPPLIER', child: Text('Supplier (Sundry Creditors)')),
                  DropdownMenuItem(value: 'BANK', child: Text('Bank (Bank Accounts)')),
                  DropdownMenuItem(value: 'EMPLOYEE', child: Text('Employee (Loans & Advances)')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _partyType = v ?? 'CUSTOMER'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gstinController,
                decoration: const InputDecoration(
                  labelText: 'GSTIN',
                  prefixIcon: Icon(Icons.badge),
                  hintText: '22AAAAA0000A1Z5',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                  LengthLimitingTextInputFormatter(15),
                  UpperCaseTextFormatter(),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.trim().isEmpty ?? true ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// State Selection Dialog
class StateSelectionDialog extends StatelessWidget {
  final List<IndianState> states;

  const StateSelectionDialog({super.key, required this.states});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select State',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: states.length,
                itemBuilder: (context, index) {
                  final state = states[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        state.code,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(state.name),
                    onTap: () => Navigator.pop(context, state),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Number Input Dialog
class NumberInputDialog extends StatefulWidget {
  final String title;
  final double initialValue;

  const NumberInputDialog({
    super.key,
    required this.title,
    required this.initialValue,
  });

  @override
  State<NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<NumberInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.toStringAsFixed(2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          hintText: 'Enter value',
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
        onSubmitted: (_) {
          final value = double.tryParse(_controller.text) ?? widget.initialValue;
          Navigator.pop(context, value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(_controller.text) ?? widget.initialValue;
            Navigator.pop(context, value);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Payment Dialog
class PaymentDialog extends StatefulWidget {
  final double grandTotal;
  final double currentPaid;
  final Function(PaymentMode, double, String?) onSave;

  const PaymentDialog({
    super.key,
    required this.grandTotal,
    required this.currentPaid,
    required this.onSave,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  PaymentMode _mode = PaymentMode.cash;
  late final TextEditingController _amountController;
  final _referenceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.currentPaid > 0 ? widget.currentPaid : widget.grandTotal)
          .toStringAsFixed(2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Grand Total: ${widget.grandTotal.toCurrencyString()}',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Payment Mode
            Text(
              'Payment Mode',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PaymentMode.values.map((mode) {
                final isSelected = _mode == mode;
                return ChoiceChip(
                  label: Text(mode.name.toUpperCase()),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _mode = mode),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Amount
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Paid',
                prefixText: '₹ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            
            const SizedBox(height: 16),
            
            // Reference (for non-cash)
            if (_mode != PaymentMode.cash)
              TextField(
                controller: _referenceController,
                decoration: InputDecoration(
                  labelText: _mode == PaymentMode.upi
                      ? 'UPI Reference'
                      : _mode == PaymentMode.card
                          ? 'Card Last 4 Digits'
                          : 'Reference Number',
                ),
              ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(_amountController.text) ?? 0;
                    widget.onSave(
                      _mode,
                      amount,
                      _referenceController.text.isEmpty 
                          ? null 
                          : _referenceController.text,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Upper case text formatter for GSTIN
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
