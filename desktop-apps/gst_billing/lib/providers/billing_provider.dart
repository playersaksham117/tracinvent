/// Billing Provider
/// State management for invoice creation and editing
library;

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/gst_invoice.dart' as gst;
import '../services/services.dart';

class BillingProvider extends ChangeNotifier {
  final ApiService _api;
  
  // Current invoice state
  GSTInvoice _currentInvoice;
  final List<InvoiceItem> _items = [];
  
  // Company state code for GST calculations
  String _companyStateCode = '27'; // Default Maharashtra
  
  // Loading states
  bool _isLoading = false;
  String? _error;
  
  // Selected party
  Ledger? _selectedParty;
  
  // Tax-inclusive pricing mode
  bool _priceIncludesTax = false;
  
  // Company profile for PDF generation
  CompanyProfile? _companyProfile;
  
  BillingProvider({ApiService? apiService}) 
      : _api = apiService ?? ApiService(),
        _currentInvoice = GSTInvoice(
          invoiceDate: DateTime.now(),
          partyName: '',
        );
  
  // Getters
  GSTInvoice get currentInvoice => _currentInvoice;
  List<InvoiceItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;
  Ledger? get selectedParty => _selectedParty;
  String get companyStateCode => _companyStateCode;
  bool get priceIncludesTax => _priceIncludesTax;
  CompanyProfile? get companyProfile => _companyProfile;
  
  // Calculated amount getters
  double get subtotal => _items.fold(0, (sum, item) => sum + item.grossAmount);
  double get totalDiscount => _items.fold(0, (sum, item) => sum + item.discountAmount);
  double get totalTaxable => _items.fold(0, (sum, item) => sum + item.taxableAmount);
  double get totalCGST => _items.fold(0, (sum, item) => sum + item.cgstAmount);
  double get totalSGST => _items.fold(0, (sum, item) => sum + item.sgstAmount);
  double get totalIGST => _items.fold(0, (sum, item) => sum + item.igstAmount);
  double get totalCess => _items.fold(0, (sum, item) => sum + item.cessAmount);
  double get totalTax => totalCGST + totalSGST + totalIGST + totalCess;
  double get grandTotal => _currentInvoice.grandTotal;
  
  bool get isInterState {
    final pos = _currentInvoice.placeOfSupply ?? _selectedParty?.billingStateCode;
    return pos != null && pos != _companyStateCode;
  }
  
  /// Initialize provider with company profile
  Future<void> initialize() async {
    try {
      final company = await _api.getCompanyProfile();
      if (company != null) {
        _companyStateCode = company.stateCode;
        _companyProfile = company;
      }
    } catch (e) {
      debugPrint('Failed to load company profile: $e');
    }
  }
  
  /// Toggle tax-inclusive pricing mode
  void setTaxInclusiveMode(bool inclusive) {
    _priceIncludesTax = inclusive;
    _recalculate();
    notifyListeners();
  }
  
  /// Start new invoice
  void newInvoice({int voucherTypeId = 1}) {
    _items.clear();
    _selectedParty = null;
    _currentInvoice = GSTInvoice(
      voucherTypeId: voucherTypeId,
      invoiceDate: DateTime.now(),
      partyName: '',
    );
    _error = null;
    notifyListeners();
  }
  
  /// Set party for invoice
  void setParty(Ledger? party) {
    _selectedParty = party;
    if (party != null) {
      _currentInvoice = _currentInvoice.copyWith(
        partyId: party.id,
        partyName: party.name,
        partyGstin: party.gstin,
        partyStateCode: party.billingStateCode,
        partyAddress: party.fullBillingAddress,
        billingName: party.name,
        billingAddress: party.billingAddress,
        billingCity: party.billingCity,
        billingStateCode: party.billingStateCode,
        billingPincode: party.billingPincode,
        placeOfSupply: party.billingStateCode,
      );
      _recalculate();
    }
    notifyListeners();
  }
  
  /// Set place of supply
  void setPlaceOfSupply(String stateCode) {
    _currentInvoice = _currentInvoice.copyWith(placeOfSupply: stateCode);
    _recalculate();
    notifyListeners();
  }
  
  /// Add item to invoice
  void addItem(InvoiceItem item) {
    _items.add(item.copyWith(serialNumber: _items.length + 1));
    _recalculate();
    notifyListeners();
  }
  
  /// Add item from search result
  bool addItemFromSearch(ItemSearchResult searchItem, {
    double quantity = 1,
    double discount = 0,
    DiscountType discountType = DiscountType.amount,
    bool allowOutOfStock = false,
  }) {
    if (!allowOutOfStock && searchItem.currentStock < quantity) {
      _error = 'Insufficient stock for ${searchItem.name}';
      notifyListeners();
      return false;
    }
    final item = InvoiceItem(
      itemId: searchItem.id,
      itemName: searchItem.name,
      hsnCode: searchItem.hsnCode,
      barcode: searchItem.barcode,
      quantity: quantity,
      rate: searchItem.sellingPrice,
      mrp: searchItem.mrp,
      gstRate: searchItem.gstRate,
      unitCode: searchItem.unitCode,
      discountType: discountType,
      discountValue: discount,
      serialNumber: _items.length + 1,
    );
    
    _items.add(item);
    _recalculate();
    notifyListeners();
    return true;
  }
  
  /// Update item at index
  void updateItem(int index, InvoiceItem item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item.copyWith(serialNumber: index + 1);
      _recalculate();
      notifyListeners();
    }
  }
  
  /// Update item quantity
  void updateQuantity(int index, double quantity) {
    if (index >= 0 && index < _items.length && quantity > 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      _recalculate();
      notifyListeners();
    }
  }
  
  /// Update item rate
  void updateRate(int index, double rate) {
    if (index >= 0 && index < _items.length && rate >= 0) {
      _items[index] = _items[index].copyWith(rate: rate);
      _recalculate();
      notifyListeners();
    }
  }
  
  /// Update item discount
  void updateDiscount(int index, double discount, DiscountType type) {
    if (index >= 0 && index < _items.length && discount >= 0) {
      _items[index] = _items[index].copyWith(
        discountValue: discount,
        discountType: type,
      );
      _recalculate();
      notifyListeners();
    }
  }
  
  /// Remove item at index
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      // Update serial numbers
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(serialNumber: i + 1);
      }
      _recalculate();
      notifyListeners();
    }
  }
  
  /// Clear all items
  void clearItems() {
    _items.clear();
    _recalculate();
    notifyListeners();
  }
  
  /// Set invoice discount
  void setInvoiceDiscount(double value, DiscountType type) {
    _currentInvoice = _currentInvoice.copyWith(
      discountValue: value,
      discountType: type,
    );
    _recalculate();
    notifyListeners();
  }
  
  /// Set other charges
  void setOtherCharges({
    double? transport,
    double? packing,
    double? other,
  }) {
    _currentInvoice = _currentInvoice.copyWith(
      transportCharges: transport ?? _currentInvoice.transportCharges,
      packingCharges: packing ?? _currentInvoice.packingCharges,
      otherCharges: other ?? _currentInvoice.otherCharges,
    );
    _recalculate();
    notifyListeners();
  }
  
  /// Set payment details
  void setPaymentDetails({
    PaymentMode? mode,
    double? paidAmount,
    String? reference,
  }) {
    _currentInvoice = _currentInvoice.copyWith(
      paymentMode: mode ?? _currentInvoice.paymentMode,
      paidAmount: paidAmount ?? _currentInvoice.paidAmount,
      paymentReference: reference ?? _currentInvoice.paymentReference,
    );
    _recalculate();
    notifyListeners();
  }
  
  /// Set invoice date
  void setInvoiceDate(DateTime date) {
    _currentInvoice = _currentInvoice.copyWith(invoiceDate: date);
    notifyListeners();
  }
  
  /// Set due date
  void setDueDate(DateTime? date) {
    _currentInvoice = _currentInvoice.copyWith(dueDate: date);
    notifyListeners();
  }
  
  /// Set notes
  void setNotes(String notes) {
    _currentInvoice = _currentInvoice.copyWith(notes: notes);
    notifyListeners();
  }
  
  /// Recalculate invoice totals
  void _recalculate() {
    // Calculate each item
    final gstType = GSTCalculator.determineGSTType(
      companyStateCode: _companyStateCode,
      placeOfSupply: _currentInvoice.placeOfSupply ?? _companyStateCode,
      isExport: _currentInvoice.isExport,
    );
    
    for (int i = 0; i < _items.length; i++) {
      _items[i] = GSTCalculator.calculateItemTax(
        _items[i], 
        gstType,
        priceIncludesTax: _priceIncludesTax,
      );
    }
    
    // Update invoice with items and recalculate
    _currentInvoice = _currentInvoice.copyWith(items: _items);
    _currentInvoice = GSTCalculator.calculateInvoice(
      _currentInvoice,
      _companyStateCode,
      priceIncludesTax: _priceIncludesTax,
    );
  }
  
  /// Save current invoice
  Future<Map<String, dynamic>?> saveInvoice() async {
    final validationErrors = validateInvoiceForPosting();
    if (validationErrors.isNotEmpty) {
      _error = validationErrors.first;
      notifyListeners();
      return null;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Prepare invoice with latest items
      final invoiceToSave = _currentInvoice.copyWith(items: _items);
      
      // Call API
      final result = await _api.createInvoice(invoiceToSave);
      
      // Clear current invoice
      newInvoice();
      
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get HSN-wise summary
  List<TaxSummary> getHSNSummary() {
    return GSTCalculator.getHSNWiseSummary(_items);
  }
  
  /// Print current invoice
  Future<void> printInvoice({bool isDuplicate = false}) async {
    if (_companyProfile == null) {
      _error = 'Company profile not loaded';
      notifyListeners();
      return;
    }
    
    try {
      await InvoicePdfService.printInvoice(
        invoice: _currentInvoice.copyWith(items: _items),
        company: _companyProfile!,
        isDuplicate: isDuplicate,
      );
    } catch (e) {
      _error = 'Failed to print: $e';
      notifyListeners();
    }
  }
  
  /// Share invoice via system share (WhatsApp, Email, etc.)
  Future<void> shareInvoice() async {
    if (_companyProfile == null) {
      _error = 'Company profile not loaded';
      notifyListeners();
      return;
    }
    
    try {
      await InvoicePdfService.shareInvoice(
        invoice: _currentInvoice.copyWith(items: _items),
        company: _companyProfile!,
      );
    } catch (e) {
      _error = 'Failed to share: $e';
      notifyListeners();
    }
  }
  
  /// Generate PDF bytes for preview
  Future<List<int>?> generatePdfPreview() async {
    if (_companyProfile == null) {
      _error = 'Company profile not loaded';
      notifyListeners();
      return null;
    }
    
    try {
      final pdfBytes = await InvoicePdfService.generateInvoicePdf(
        invoice: _currentInvoice.copyWith(items: _items),
        company: _companyProfile!,
      );
      return pdfBytes;
    } catch (e) {
      _error = 'Failed to generate preview: $e';
      notifyListeners();
      return null;
    }
  }
  
  /// Check if this is a credit sale (payment less than total)
  bool get isCreditSale {
    return _currentInvoice.paidAmount < _currentInvoice.grandTotal && 
           _currentInvoice.paymentMode == PaymentMode.credit;
  }
  
  /// Get outstanding balance for current invoice
  double get outstandingBalance {
    return _currentInvoice.grandTotal - _currentInvoice.paidAmount;
  }
  
  /// Set as credit sale (Udhar)
  void setAsCreditSale({double? partialPayment}) {
    final paid = partialPayment ?? 0;
    _currentInvoice = _currentInvoice.copyWith(
      paymentMode: PaymentMode.credit,
      paidAmount: paid,
      balanceAmount: _currentInvoice.grandTotal - paid,
      paymentStatus: paid > 0 ? gst.PaymentStatus.partial : gst.PaymentStatus.unpaid,
    );
    notifyListeners();
  }
  
  /// Record partial payment
  void recordPartialPayment({
    required double amount,
    required PaymentMode mode,
    String? reference,
  }) {
    final newPaid = _currentInvoice.paidAmount + amount;
    final newBalance = _currentInvoice.grandTotal - newPaid;
    
    _currentInvoice = _currentInvoice.copyWith(
      paidAmount: newPaid,
      balanceAmount: newBalance > 0 ? newBalance : 0,
      paymentStatus: newBalance <= 0 ? gst.PaymentStatus.paid : gst.PaymentStatus.partial,
      paymentMode: mode,
      paymentReference: reference,
    );
    notifyListeners();
  }
  
  /// Quick add item by barcode
  Future<bool> addItemByBarcode(String barcode) async {
    if (barcode.isEmpty) return false;
    
    try {
      final item = await _api.getItemByBarcode(barcode);
      if (item != null) {
        return addItemFromSearch(item);
      }
      return false;
    } catch (e) {
      _error = 'Failed to find item: $e';
      notifyListeners();
      return false;
    }
  }

  /// Validate invoice before posting to accounting
  List<String> validateInvoiceForPosting() {
    final errors = <String>[];

    if (_items.isEmpty) {
      errors.add('Invoice must have at least one item');
    }

    if (_currentInvoice.partyName.trim().isEmpty) {
      errors.add('Party name is required');
    }

    final placeOfSupply = _currentInvoice.placeOfSupply ?? _companyStateCode;
    if (placeOfSupply.trim().isEmpty) {
      errors.add('Place of supply is required');
    }

    final isComposition =
        _selectedParty?.gstRegistrationType == GSTRegistrationType.composition;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final line = i + 1;

      if (item.itemName.trim().isEmpty) {
        errors.add('Line $line: item name is required');
      }
      if (item.quantity <= 0) {
        errors.add('Line $line: quantity must be greater than 0');
      }
      if (item.rate < 0) {
        errors.add('Line $line: rate must be 0 or more');
      }

      if (!_isValidGstRate(item.gstRate)) {
        errors.add('Line $line: GST rate must be a valid slab');
      }

      final hasHsn = item.hsnCode != null && item.hsnCode!.trim().isNotEmpty;
      if (item.gstRate > 0 && !hasHsn) {
        errors.add('Line $line: HSN/SAC required for taxable items');
      }

      if (isComposition && item.gstRate > 0) {
        errors.add('Line $line: composition customers must be billed without GST');
      }
    }

    if (_currentInvoice.paidAmount < 0) {
      errors.add('Paid amount must be 0 or more');
    }

    if (_currentInvoice.grandTotal > 0 &&
        _currentInvoice.paidAmount > _currentInvoice.grandTotal + 0.01) {
      errors.add('Paid amount cannot exceed grand total');
    }

    if (_currentInvoice.paymentMode != null &&
        _currentInvoice.paymentMode != PaymentMode.credit &&
        _currentInvoice.paidAmount <= 0) {
      errors.add('Paid amount must be greater than 0 for non-credit payments');
    }

    return errors;
  }

  static bool _isValidGstRate(double rate) {
    for (final slab in GSTSlabs.validRates) {
      if ((slab - rate).abs() <= 0.001) {
        return true;
      }
    }
    return false;
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
