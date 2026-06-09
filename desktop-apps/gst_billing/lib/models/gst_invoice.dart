/// GST Invoice Model
/// Matches the SQLite schema and includes toJson/fromJson methods
library;

enum PaymentMode { cash, credit, card, upi, neft, cheque, online }

enum PaymentStatus { unpaid, partial, paid, overdue }

enum InvoiceStatus { draft, confirmed, cancelled, void_ }

enum DiscountType { percentage, amount }

enum GSTRegistrationType {
  regular,
  composition,
  unregistered,
  consumer,
  overseas,
  sez
}

/// Invoice Item (Line Item)
class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int? itemId;
  final int? batchId;
  final String itemName;
  final String? itemDescription;
  final String? hsnCode;
  final String? barcode;
  final double quantity;
  final int? unitId;
  final String? unitCode;
  final double freeQuantity;
  final double rate;
  final double mrp;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final double taxableAmount;
  final double gstRate;
  final double cgstRate;
  final double cgstAmount;
  final double sgstRate;
  final double sgstAmount;
  final double igstRate;
  final double igstAmount;
  final double cessRate;
  final double cessAmount;
  final double totalTaxAmount;
  final double totalAmount;
  final int serialNumber;

  InvoiceItem({
    this.id,
    this.invoiceId,
    this.itemId,
    this.batchId,
    required this.itemName,
    this.itemDescription,
    this.hsnCode,
    this.barcode,
    required this.quantity,
    this.unitId,
    this.unitCode = 'NOS',
    this.freeQuantity = 0,
    required this.rate,
    this.mrp = 0,
    this.discountType = DiscountType.amount,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.taxableAmount = 0,
    this.gstRate = 0,
    this.cgstRate = 0,
    this.cgstAmount = 0,
    this.sgstRate = 0,
    this.sgstAmount = 0,
    this.igstRate = 0,
    this.igstAmount = 0,
    this.cessRate = 0,
    this.cessAmount = 0,
    this.totalTaxAmount = 0,
    this.totalAmount = 0,
    this.serialNumber = 0,
  });

  /// Calculate gross amount (quantity * rate)
  double get grossAmount => quantity * rate;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as int?,
      invoiceId: json['invoice_id'] as int?,
      itemId: json['item_id'] as int?,
      batchId: json['batch_id'] as int?,
      itemName: json['item_name'] as String? ?? '',
      itemDescription: json['item_description'] as String?,
      hsnCode: json['hsn_code'] as String?,
      barcode: json['barcode'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitId: json['unit_id'] as int?,
      unitCode: json['unit_code'] as String? ?? 'NOS',
      freeQuantity: (json['free_quantity'] as num?)?.toDouble() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0,
      discountType: json['discount_type'] == 'PERCENTAGE'
          ? DiscountType.percentage
          : DiscountType.amount,
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      taxableAmount: (json['taxable_amount'] as num?)?.toDouble() ?? 0,
      gstRate: (json['gst_rate'] as num?)?.toDouble() ?? 0,
      cgstRate: (json['cgst_rate'] as num?)?.toDouble() ?? 0,
      cgstAmount: (json['cgst_amount'] as num?)?.toDouble() ?? 0,
      sgstRate: (json['sgst_rate'] as num?)?.toDouble() ?? 0,
      sgstAmount: (json['sgst_amount'] as num?)?.toDouble() ?? 0,
      igstRate: (json['igst_rate'] as num?)?.toDouble() ?? 0,
      igstAmount: (json['igst_amount'] as num?)?.toDouble() ?? 0,
      cessRate: (json['cess_rate'] as num?)?.toDouble() ?? 0,
      cessAmount: (json['cess_amount'] as num?)?.toDouble() ?? 0,
      totalTaxAmount: (json['total_tax_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      serialNumber: json['serial_number'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      'item_id': itemId,
      'batch_id': batchId,
      'item_name': itemName,
      'item_description': itemDescription,
      'hsn_code': hsnCode,
      'barcode': barcode,
      'quantity': quantity,
      'unit_id': unitId,
      'unit_code': unitCode,
      'free_quantity': freeQuantity,
      'rate': rate,
      'mrp': mrp,
      'discount_type':
          discountType == DiscountType.percentage ? 'PERCENTAGE' : 'AMOUNT',
      'discount_value': discountValue,
      'gst_rate': gstRate,
      'cess_rate': cessRate,
    };
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? itemId,
    int? batchId,
    String? itemName,
    String? itemDescription,
    String? hsnCode,
    String? barcode,
    double? quantity,
    int? unitId,
    String? unitCode,
    double? freeQuantity,
    double? rate,
    double? mrp,
    DiscountType? discountType,
    double? discountValue,
    double? discountAmount,
    double? taxableAmount,
    double? gstRate,
    double? cgstRate,
    double? cgstAmount,
    double? sgstRate,
    double? sgstAmount,
    double? igstRate,
    double? igstAmount,
    double? cessRate,
    double? cessAmount,
    double? totalTaxAmount,
    double? totalAmount,
    int? serialNumber,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      itemId: itemId ?? this.itemId,
      batchId: batchId ?? this.batchId,
      itemName: itemName ?? this.itemName,
      itemDescription: itemDescription ?? this.itemDescription,
      hsnCode: hsnCode ?? this.hsnCode,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      unitId: unitId ?? this.unitId,
      unitCode: unitCode ?? this.unitCode,
      freeQuantity: freeQuantity ?? this.freeQuantity,
      rate: rate ?? this.rate,
      mrp: mrp ?? this.mrp,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      gstRate: gstRate ?? this.gstRate,
      cgstRate: cgstRate ?? this.cgstRate,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstRate: sgstRate ?? this.sgstRate,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstRate: igstRate ?? this.igstRate,
      igstAmount: igstAmount ?? this.igstAmount,
      cessRate: cessRate ?? this.cessRate,
      cessAmount: cessAmount ?? this.cessAmount,
      totalTaxAmount: totalTaxAmount ?? this.totalTaxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      serialNumber: serialNumber ?? this.serialNumber,
    );
  }
}

/// GST Invoice Main Model
class GSTInvoice {
  final int? id;
  final int voucherTypeId;
  final String? invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final int? financialYearId;

  // Party Details
  final int? partyId;
  final String partyName;
  final String? partyGstin;
  final String? partyStateCode;
  final String? partyAddress;

  // Billing Address
  final String? billingName;
  final String? billingAddress;
  final String? billingCity;
  final String? billingStateCode;
  final String? billingPincode;

  // Shipping Address
  final String? shippingName;
  final String? shippingAddress;
  final String? shippingCity;
  final String? shippingStateCode;
  final String? shippingPincode;

  // GST Details
  final String? placeOfSupply;
  final bool isReverseCharge;
  final bool isExport;
  final String? exportType;

  // Amounts
  final double subtotal;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final double taxableAmount;

  // GST Amounts
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double totalTaxAmount;

  // Other Charges
  final double transportCharges;
  final double packingCharges;
  final double otherCharges;

  // Totals
  final double roundOffAmount;
  final double grandTotal;
  final String? amountInWords;

  // Payment
  final PaymentMode? paymentMode;
  final String? paymentReference;
  final double paidAmount;
  final double balanceAmount;
  final PaymentStatus paymentStatus;

  // E-Way Bill
  final String? ewayBillNumber;
  final DateTime? ewayBillDate;
  final String? vehicleNumber;
  final String? transporterName;
  final String? transporterGstin;
  final String? transportMode;
  final double? distanceKm;

  // E-Invoice
  final String? irn;
  final DateTime? irnDate;
  final String? qrCode;
  final String? ackNumber;
  final DateTime? ackDate;

  // Status
  final InvoiceStatus status;
  final bool isDeleted;
  final String? deletedReason;

  // Notes
  final String? notes;
  final String? termsConditions;
  final String? internalNotes;

  // Audit
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Items
  final List<InvoiceItem> items;

  GSTInvoice({
    this.id,
    this.voucherTypeId = 1,
    this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    this.financialYearId,
    this.partyId,
    required this.partyName,
    this.partyGstin,
    this.partyStateCode,
    this.partyAddress,
    this.billingName,
    this.billingAddress,
    this.billingCity,
    this.billingStateCode,
    this.billingPincode,
    this.shippingName,
    this.shippingAddress,
    this.shippingCity,
    this.shippingStateCode,
    this.shippingPincode,
    this.placeOfSupply,
    this.isReverseCharge = false,
    this.isExport = false,
    this.exportType,
    this.subtotal = 0,
    this.discountType = DiscountType.amount,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.taxableAmount = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.cessAmount = 0,
    this.totalTaxAmount = 0,
    this.transportCharges = 0,
    this.packingCharges = 0,
    this.otherCharges = 0,
    this.roundOffAmount = 0,
    this.grandTotal = 0,
    this.amountInWords,
    this.paymentMode,
    this.paymentReference,
    this.paidAmount = 0,
    this.balanceAmount = 0,
    this.paymentStatus = PaymentStatus.unpaid,
    this.ewayBillNumber,
    this.ewayBillDate,
    this.vehicleNumber,
    this.transporterName,
    this.transporterGstin,
    this.transportMode,
    this.distanceKm,
    this.irn,
    this.irnDate,
    this.qrCode,
    this.ackNumber,
    this.ackDate,
    this.status = InvoiceStatus.draft,
    this.isDeleted = false,
    this.deletedReason,
    this.notes,
    this.termsConditions,
    this.internalNotes,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    List<InvoiceItem>? items,
  }) : items = items ?? [];

  factory GSTInvoice.fromJson(Map<String, dynamic> json) {
    return GSTInvoice(
      id: json['id'] as int?,
      voucherTypeId: json['voucher_type_id'] as int? ?? 1,
      invoiceNumber: json['invoice_number'] as String?,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      financialYearId: json['financial_year_id'] as int?,
      partyId: json['party_id'] as int?,
      partyName: json['party_name'] as String? ?? '',
      partyGstin: json['party_gstin'] as String?,
      partyStateCode: json['party_state_code'] as String?,
      partyAddress: json['party_address'] as String?,
      billingName: json['billing_name'] as String?,
      billingAddress: json['billing_address'] as String?,
      billingCity: json['billing_city'] as String?,
      billingStateCode: json['billing_state_code'] as String?,
      billingPincode: json['billing_pincode'] as String?,
      shippingName: json['shipping_name'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      shippingCity: json['shipping_city'] as String?,
      shippingStateCode: json['shipping_state_code'] as String?,
      shippingPincode: json['shipping_pincode'] as String?,
      placeOfSupply: json['place_of_supply'] as String?,
      isReverseCharge: (json['is_reverse_charge'] as int?) == 1,
      isExport: (json['is_export'] as int?) == 1,
      exportType: json['export_type'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountType: json['discount_type'] == 'PERCENTAGE'
          ? DiscountType.percentage
          : DiscountType.amount,
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      taxableAmount: (json['taxable_amount'] as num?)?.toDouble() ?? 0,
      cgstAmount: (json['cgst_amount'] as num?)?.toDouble() ?? 0,
      sgstAmount: (json['sgst_amount'] as num?)?.toDouble() ?? 0,
      igstAmount: (json['igst_amount'] as num?)?.toDouble() ?? 0,
      cessAmount: (json['cess_amount'] as num?)?.toDouble() ?? 0,
      totalTaxAmount: (json['total_tax_amount'] as num?)?.toDouble() ?? 0,
      transportCharges: (json['transport_charges'] as num?)?.toDouble() ?? 0,
      packingCharges: (json['packing_charges'] as num?)?.toDouble() ?? 0,
      otherCharges: (json['other_charges'] as num?)?.toDouble() ?? 0,
      roundOffAmount: (json['round_off_amount'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0,
      amountInWords: json['amount_in_words'] as String?,
      paymentMode: _parsePaymentMode(json['payment_mode'] as String?),
      paymentReference: json['payment_reference'] as String?,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      balanceAmount: (json['balance_amount'] as num?)?.toDouble() ?? 0,
      paymentStatus: _parsePaymentStatus(json['payment_status'] as String?),
      ewayBillNumber: json['eway_bill_number'] as String?,
      ewayBillDate: json['eway_bill_date'] != null
          ? DateTime.parse(json['eway_bill_date'] as String)
          : null,
      vehicleNumber: json['vehicle_number'] as String?,
      transporterName: json['transporter_name'] as String?,
      transporterGstin: json['transporter_gstin'] as String?,
      transportMode: json['transport_mode'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      irn: json['irn'] as String?,
      irnDate: json['irn_date'] != null
          ? DateTime.parse(json['irn_date'] as String)
          : null,
      qrCode: json['qr_code'] as String?,
      ackNumber: json['ack_number'] as String?,
      ackDate: json['ack_date'] != null
          ? DateTime.parse(json['ack_date'] as String)
          : null,
      status: _parseInvoiceStatus(json['status'] as String?),
      isDeleted: (json['is_deleted'] as int?) == 1,
      deletedReason: json['deleted_reason'] as String?,
      notes: json['notes'] as String?,
      termsConditions: json['terms_conditions'] as String?,
      internalNotes: json['internal_notes'] as String?,
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'voucher_type_id': voucherTypeId,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String().split('T')[0],
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T')[0],
      'party_id': partyId,
      'party_name': partyName,
      'party_gstin': partyGstin,
      'party_state_code': partyStateCode,
      'party_address': partyAddress,
      'billing_name': billingName,
      'billing_address': billingAddress,
      'billing_city': billingCity,
      'billing_state_code': billingStateCode,
      'billing_pincode': billingPincode,
      'shipping_name': shippingName,
      'shipping_address': shippingAddress,
      'shipping_city': shippingCity,
      'shipping_state_code': shippingStateCode,
      'shipping_pincode': shippingPincode,
      'place_of_supply': placeOfSupply,
      'is_reverse_charge': isReverseCharge,
      'is_export': isExport,
      'discount_type':
          discountType == DiscountType.percentage ? 'PERCENTAGE' : 'AMOUNT',
      'discount_value': discountValue,
      'transport_charges': transportCharges,
      'packing_charges': packingCharges,
      'other_charges': otherCharges,
      'payment_mode': _paymentModeToString(paymentMode),
      'payment_reference': paymentReference,
      'paid_amount': paidAmount,
      'eway_bill_number': ewayBillNumber,
      'vehicle_number': vehicleNumber,
      'transporter_name': transporterName,
      'notes': notes,
      'terms_conditions': termsConditions,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  static PaymentMode? _parsePaymentMode(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'CASH':
        return PaymentMode.cash;
      case 'CREDIT':
        return PaymentMode.credit;
      case 'CARD':
        return PaymentMode.card;
      case 'UPI':
        return PaymentMode.upi;
      case 'NEFT':
        return PaymentMode.neft;
      case 'CHEQUE':
        return PaymentMode.cheque;
      case 'ONLINE':
        return PaymentMode.online;
      default:
        return null;
    }
  }

  static String? _paymentModeToString(PaymentMode? mode) {
    if (mode == null) return null;
    return mode.name.toUpperCase();
  }

  static PaymentStatus _parsePaymentStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'PAID':
        return PaymentStatus.paid;
      case 'PARTIAL':
        return PaymentStatus.partial;
      case 'OVERDUE':
        return PaymentStatus.overdue;
      default:
        return PaymentStatus.unpaid;
    }
  }

  static InvoiceStatus _parseInvoiceStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'CONFIRMED':
        return InvoiceStatus.confirmed;
      case 'CANCELLED':
        return InvoiceStatus.cancelled;
      case 'VOID':
        return InvoiceStatus.void_;
      default:
        return InvoiceStatus.draft;
    }
  }

  GSTInvoice copyWith({
    int? id,
    int? voucherTypeId,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    int? financialYearId,
    int? partyId,
    String? partyName,
    String? partyGstin,
    String? partyStateCode,
    String? partyAddress,
    String? billingName,
    String? billingAddress,
    String? billingCity,
    String? billingStateCode,
    String? billingPincode,
    String? shippingName,
    String? shippingAddress,
    String? shippingCity,
    String? shippingStateCode,
    String? shippingPincode,
    String? placeOfSupply,
    bool? isReverseCharge,
    bool? isExport,
    String? exportType,
    double? subtotal,
    DiscountType? discountType,
    double? discountValue,
    double? discountAmount,
    double? taxableAmount,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? cessAmount,
    double? totalTaxAmount,
    double? transportCharges,
    double? packingCharges,
    double? otherCharges,
    double? roundOffAmount,
    double? grandTotal,
    String? amountInWords,
    PaymentMode? paymentMode,
    String? paymentReference,
    double? paidAmount,
    double? balanceAmount,
    PaymentStatus? paymentStatus,
    String? ewayBillNumber,
    DateTime? ewayBillDate,
    String? vehicleNumber,
    String? transporterName,
    String? transporterGstin,
    String? transportMode,
    double? distanceKm,
    String? irn,
    DateTime? irnDate,
    String? qrCode,
    String? ackNumber,
    DateTime? ackDate,
    InvoiceStatus? status,
    bool? isDeleted,
    String? deletedReason,
    String? notes,
    String? termsConditions,
    String? internalNotes,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InvoiceItem>? items,
  }) {
    return GSTInvoice(
      id: id ?? this.id,
      voucherTypeId: voucherTypeId ?? this.voucherTypeId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      financialYearId: financialYearId ?? this.financialYearId,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      partyGstin: partyGstin ?? this.partyGstin,
      partyStateCode: partyStateCode ?? this.partyStateCode,
      partyAddress: partyAddress ?? this.partyAddress,
      billingName: billingName ?? this.billingName,
      billingAddress: billingAddress ?? this.billingAddress,
      billingCity: billingCity ?? this.billingCity,
      billingStateCode: billingStateCode ?? this.billingStateCode,
      billingPincode: billingPincode ?? this.billingPincode,
      shippingName: shippingName ?? this.shippingName,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingStateCode: shippingStateCode ?? this.shippingStateCode,
      shippingPincode: shippingPincode ?? this.shippingPincode,
      placeOfSupply: placeOfSupply ?? this.placeOfSupply,
      isReverseCharge: isReverseCharge ?? this.isReverseCharge,
      isExport: isExport ?? this.isExport,
      exportType: exportType ?? this.exportType,
      subtotal: subtotal ?? this.subtotal,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      cessAmount: cessAmount ?? this.cessAmount,
      totalTaxAmount: totalTaxAmount ?? this.totalTaxAmount,
      transportCharges: transportCharges ?? this.transportCharges,
      packingCharges: packingCharges ?? this.packingCharges,
      otherCharges: otherCharges ?? this.otherCharges,
      roundOffAmount: roundOffAmount ?? this.roundOffAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      amountInWords: amountInWords ?? this.amountInWords,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentReference: paymentReference ?? this.paymentReference,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      ewayBillNumber: ewayBillNumber ?? this.ewayBillNumber,
      ewayBillDate: ewayBillDate ?? this.ewayBillDate,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      transporterName: transporterName ?? this.transporterName,
      transporterGstin: transporterGstin ?? this.transporterGstin,
      transportMode: transportMode ?? this.transportMode,
      distanceKm: distanceKm ?? this.distanceKm,
      irn: irn ?? this.irn,
      irnDate: irnDate ?? this.irnDate,
      qrCode: qrCode ?? this.qrCode,
      ackNumber: ackNumber ?? this.ackNumber,
      ackDate: ackDate ?? this.ackDate,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedReason: deletedReason ?? this.deletedReason,
      notes: notes ?? this.notes,
      termsConditions: termsConditions ?? this.termsConditions,
      internalNotes: internalNotes ?? this.internalNotes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  @override
  String toString() {
    return 'GSTInvoice(id: $id, invoiceNumber: $invoiceNumber, partyName: $partyName, grandTotal: $grandTotal)';
  }
}

/// Tax Summary for HSN-wise breakdown
class TaxSummary {
  final String hsnCode;
  final double quantity;
  final double taxableAmount;
  final double gstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double totalTax;

  TaxSummary({
    required this.hsnCode,
    this.quantity = 0,
    this.taxableAmount = 0,
    this.gstRate = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.cessAmount = 0,
    this.totalTax = 0,
  });

  factory TaxSummary.fromJson(Map<String, dynamic> json) {
    return TaxSummary(
      hsnCode: json['hsn_code'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      taxableAmount: (json['taxable_amount'] as num?)?.toDouble() ?? 0,
      gstRate: (json['gst_rate'] as num?)?.toDouble() ?? 0,
      cgstAmount: (json['cgst_amount'] as num?)?.toDouble() ?? 0,
      sgstAmount: (json['sgst_amount'] as num?)?.toDouble() ?? 0,
      igstAmount: (json['igst_amount'] as num?)?.toDouble() ?? 0,
      cessAmount: (json['cess_amount'] as num?)?.toDouble() ?? 0,
      totalTax: (json['total_tax'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Credit Note / Debit Note Type
enum NoteType { credit, debit }

/// Reason for Credit Note
enum CreditNoteReason {
  salesReturn,
  postSaleDiscount,
  deficiency,
  correction,
  changeInPOS,
  finalization,
  others,
}

/// Credit Note / Debit Note for GST
class GSTCreditNote {
  final int? id;
  final NoteType noteType;
  final String? noteNumber;
  final DateTime noteDate;
  
  // Reference to original invoice
  final int? originalInvoiceId;
  final String? originalInvoiceNumber;
  final DateTime? originalInvoiceDate;
  
  // Party Details
  final int? partyId;
  final String partyName;
  final String? partyGstin;
  final String? partyStateCode;
  
  // Reason
  final CreditNoteReason reason;
  final String? reasonDescription;
  
  // Amounts
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double totalTaxAmount;
  final double grandTotal;
  
  // Place of Supply
  final String? placeOfSupply;
  final bool isReverseCharge;
  
  // Items
  final List<InvoiceItem> items;
  
  // Status
  final InvoiceStatus status;
  final bool isDeleted;
  
  // Audit
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GSTCreditNote({
    this.id,
    required this.noteType,
    this.noteNumber,
    required this.noteDate,
    this.originalInvoiceId,
    this.originalInvoiceNumber,
    this.originalInvoiceDate,
    this.partyId,
    required this.partyName,
    this.partyGstin,
    this.partyStateCode,
    this.reason = CreditNoteReason.salesReturn,
    this.reasonDescription,
    this.taxableAmount = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.cessAmount = 0,
    this.totalTaxAmount = 0,
    this.grandTotal = 0,
    this.placeOfSupply,
    this.isReverseCharge = false,
    List<InvoiceItem>? items,
    this.status = InvoiceStatus.draft,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  }) : items = items ?? [];

  factory GSTCreditNote.fromJson(Map<String, dynamic> json) {
    return GSTCreditNote(
      id: json['id'] as int?,
      noteType: json['note_type'] == 'DEBIT' ? NoteType.debit : NoteType.credit,
      noteNumber: json['note_number'] as String?,
      noteDate: DateTime.parse(json['note_date'] as String),
      originalInvoiceId: json['original_invoice_id'] as int?,
      originalInvoiceNumber: json['original_invoice_number'] as String?,
      originalInvoiceDate: json['original_invoice_date'] != null
          ? DateTime.parse(json['original_invoice_date'] as String)
          : null,
      partyId: json['party_id'] as int?,
      partyName: json['party_name'] as String? ?? '',
      partyGstin: json['party_gstin'] as String?,
      partyStateCode: json['party_state_code'] as String?,
      reason: _parseCreditNoteReason(json['reason'] as String?),
      reasonDescription: json['reason_description'] as String?,
      taxableAmount: (json['taxable_amount'] as num?)?.toDouble() ?? 0,
      cgstAmount: (json['cgst_amount'] as num?)?.toDouble() ?? 0,
      sgstAmount: (json['sgst_amount'] as num?)?.toDouble() ?? 0,
      igstAmount: (json['igst_amount'] as num?)?.toDouble() ?? 0,
      cessAmount: (json['cess_amount'] as num?)?.toDouble() ?? 0,
      totalTaxAmount: (json['total_tax_amount'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0,
      placeOfSupply: json['place_of_supply'] as String?,
      isReverseCharge: (json['is_reverse_charge'] as int?) == 1,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: GSTInvoice._parseInvoiceStatus(json['status'] as String?),
      isDeleted: (json['is_deleted'] as int?) == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'note_type': noteType == NoteType.debit ? 'DEBIT' : 'CREDIT',
      if (noteNumber != null) 'note_number': noteNumber,
      'note_date': noteDate.toIso8601String().split('T')[0],
      'original_invoice_id': originalInvoiceId,
      'original_invoice_number': originalInvoiceNumber,
      'party_id': partyId,
      'party_name': partyName,
      'party_gstin': partyGstin,
      'party_state_code': partyStateCode,
      'reason': _creditNoteReasonToString(reason),
      'reason_description': reasonDescription,
      'place_of_supply': placeOfSupply,
      'is_reverse_charge': isReverseCharge,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  static CreditNoteReason _parseCreditNoteReason(String? value) {
    switch (value?.toUpperCase()) {
      case 'POST_SALE_DISCOUNT':
        return CreditNoteReason.postSaleDiscount;
      case 'DEFICIENCY':
        return CreditNoteReason.deficiency;
      case 'CORRECTION':
        return CreditNoteReason.correction;
      case 'CHANGE_IN_POS':
        return CreditNoteReason.changeInPOS;
      case 'FINALIZATION':
        return CreditNoteReason.finalization;
      case 'OTHERS':
        return CreditNoteReason.others;
      default:
        return CreditNoteReason.salesReturn;
    }
  }

  static String _creditNoteReasonToString(CreditNoteReason reason) {
    switch (reason) {
      case CreditNoteReason.salesReturn:
        return 'SALES_RETURN';
      case CreditNoteReason.postSaleDiscount:
        return 'POST_SALE_DISCOUNT';
      case CreditNoteReason.deficiency:
        return 'DEFICIENCY';
      case CreditNoteReason.correction:
        return 'CORRECTION';
      case CreditNoteReason.changeInPOS:
        return 'CHANGE_IN_POS';
      case CreditNoteReason.finalization:
        return 'FINALIZATION';
      case CreditNoteReason.others:
        return 'OTHERS';
    }
  }
}

/// Payment History Entry for Credit Sales (Udhar) tracking
class PaymentEntry {
  final int? id;
  final int invoiceId;
  final DateTime paymentDate;
  final double amount;
  final PaymentMode mode;
  final String? reference;
  final String? notes;
  final String? receivedBy;
  final DateTime? createdAt;

  PaymentEntry({
    this.id,
    required this.invoiceId,
    required this.paymentDate,
    required this.amount,
    required this.mode,
    this.reference,
    this.notes,
    this.receivedBy,
    this.createdAt,
  });

  factory PaymentEntry.fromJson(Map<String, dynamic> json) {
    return PaymentEntry(
      id: json['id'] as int?,
      invoiceId: json['invoice_id'] as int,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      amount: (json['amount'] as num).toDouble(),
      mode: GSTInvoice._parsePaymentMode(json['payment_mode'] as String?) ?? PaymentMode.cash,
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
      receivedBy: json['received_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'invoice_id': invoiceId,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'amount': amount,
      'payment_mode': mode.name.toUpperCase(),
      'reference': reference,
      'notes': notes,
      'received_by': receivedBy,
    };
  }
}

/// Outstanding balance summary for a party (Udhar tracking)
class PartyOutstanding {
  final int partyId;
  final String partyName;
  final String? gstin;
  final double totalInvoiceAmount;
  final double totalPaid;
  final double totalOutstanding;
  final int invoiceCount;
  final DateTime? oldestDueDate;
  final int overdueDays;

  PartyOutstanding({
    required this.partyId,
    required this.partyName,
    this.gstin,
    this.totalInvoiceAmount = 0,
    this.totalPaid = 0,
    this.totalOutstanding = 0,
    this.invoiceCount = 0,
    this.oldestDueDate,
    this.overdueDays = 0,
  });

  factory PartyOutstanding.fromJson(Map<String, dynamic> json) {
    return PartyOutstanding(
      partyId: json['party_id'] as int,
      partyName: json['party_name'] as String,
      gstin: json['gstin'] as String?,
      totalInvoiceAmount: (json['total_invoice_amount'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
      totalOutstanding: (json['total_outstanding'] as num?)?.toDouble() ?? 0,
      invoiceCount: json['invoice_count'] as int? ?? 0,
      oldestDueDate: json['oldest_due_date'] != null
          ? DateTime.parse(json['oldest_due_date'] as String)
          : null,
      overdueDays: json['overdue_days'] as int? ?? 0,
    );
  }
}

/// Unit conversion for multi-unit handling
class UnitConversion {
  final int? id;
  final int itemId;
  final int fromUnitId;
  final String fromUnitCode;
  final int toUnitId;
  final String toUnitCode;
  final double conversionFactor; // How many 'fromUnit' = 1 'toUnit'

  UnitConversion({
    this.id,
    required this.itemId,
    required this.fromUnitId,
    required this.fromUnitCode,
    required this.toUnitId,
    required this.toUnitCode,
    required this.conversionFactor,
  });

  /// Convert quantity from one unit to another
  double convert(double quantity) {
    return quantity / conversionFactor;
  }

  /// Reverse convert (toUnit -> fromUnit)
  double reverseConvert(double quantity) {
    return quantity * conversionFactor;
  }

  factory UnitConversion.fromJson(Map<String, dynamic> json) {
    return UnitConversion(
      id: json['id'] as int?,
      itemId: json['item_id'] as int,
      fromUnitId: json['from_unit_id'] as int,
      fromUnitCode: json['from_unit_code'] as String,
      toUnitId: json['to_unit_id'] as int,
      toUnitCode: json['to_unit_code'] as String,
      conversionFactor: (json['conversion_factor'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'item_id': itemId,
      'from_unit_id': fromUnitId,
      'from_unit_code': fromUnitCode,
      'to_unit_id': toUnitId,
      'to_unit_code': toUnitCode,
      'conversion_factor': conversionFactor,
    };
  }
}

/// GSTR-1 Summary data structure (for tax filing)
class GSTR1Summary {
  final DateTime fromDate;
  final DateTime toDate;
  
  // B2B Sales (with GSTIN)
  final double b2bTaxableAmount;
  final double b2bTaxAmount;
  final int b2bInvoiceCount;
  
  // B2C Large (> 2.5 lakhs inter-state)
  final double b2clTaxableAmount;
  final double b2clTaxAmount;
  final int b2clInvoiceCount;
  
  // B2C Small
  final double b2csTaxableAmount;
  final double b2csTaxAmount;
  final int b2csInvoiceCount;
  
  // Credit Notes
  final double creditNoteTaxableAmount;
  final double creditNoteTaxAmount;
  final int creditNoteCount;
  
  // Debit Notes
  final double debitNoteTaxableAmount;
  final double debitNoteTaxAmount;
  final int debitNoteCount;
  
  // Exports
  final double exportTaxableAmount;
  final int exportInvoiceCount;
  
  // HSN Summary
  final List<TaxSummary> hsnSummary;

  GSTR1Summary({
    required this.fromDate,
    required this.toDate,
    this.b2bTaxableAmount = 0,
    this.b2bTaxAmount = 0,
    this.b2bInvoiceCount = 0,
    this.b2clTaxableAmount = 0,
    this.b2clTaxAmount = 0,
    this.b2clInvoiceCount = 0,
    this.b2csTaxableAmount = 0,
    this.b2csTaxAmount = 0,
    this.b2csInvoiceCount = 0,
    this.creditNoteTaxableAmount = 0,
    this.creditNoteTaxAmount = 0,
    this.creditNoteCount = 0,
    this.debitNoteTaxableAmount = 0,
    this.debitNoteTaxAmount = 0,
    this.debitNoteCount = 0,
    this.exportTaxableAmount = 0,
    this.exportInvoiceCount = 0,
    List<TaxSummary>? hsnSummary,
  }) : hsnSummary = hsnSummary ?? [];

  factory GSTR1Summary.fromJson(Map<String, dynamic> json) {
    return GSTR1Summary(
      fromDate: DateTime.parse(json['from_date'] as String),
      toDate: DateTime.parse(json['to_date'] as String),
      b2bTaxableAmount: (json['b2b_taxable_amount'] as num?)?.toDouble() ?? 0,
      b2bTaxAmount: (json['b2b_tax_amount'] as num?)?.toDouble() ?? 0,
      b2bInvoiceCount: json['b2b_invoice_count'] as int? ?? 0,
      b2clTaxableAmount: (json['b2cl_taxable_amount'] as num?)?.toDouble() ?? 0,
      b2clTaxAmount: (json['b2cl_tax_amount'] as num?)?.toDouble() ?? 0,
      b2clInvoiceCount: json['b2cl_invoice_count'] as int? ?? 0,
      b2csTaxableAmount: (json['b2cs_taxable_amount'] as num?)?.toDouble() ?? 0,
      b2csTaxAmount: (json['b2cs_tax_amount'] as num?)?.toDouble() ?? 0,
      b2csInvoiceCount: json['b2cs_invoice_count'] as int? ?? 0,
      creditNoteTaxableAmount: (json['credit_note_taxable_amount'] as num?)?.toDouble() ?? 0,
      creditNoteTaxAmount: (json['credit_note_tax_amount'] as num?)?.toDouble() ?? 0,
      creditNoteCount: json['credit_note_count'] as int? ?? 0,
      debitNoteTaxableAmount: (json['debit_note_taxable_amount'] as num?)?.toDouble() ?? 0,
      debitNoteTaxAmount: (json['debit_note_tax_amount'] as num?)?.toDouble() ?? 0,
      debitNoteCount: json['debit_note_count'] as int? ?? 0,
      exportTaxableAmount: (json['export_taxable_amount'] as num?)?.toDouble() ?? 0,
      exportInvoiceCount: json['export_invoice_count'] as int? ?? 0,
      hsnSummary: (json['hsn_summary'] as List<dynamic>?)
          ?.map((e) => TaxSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  
  /// Total taxable amount across all categories
  double get totalTaxableAmount =>
      b2bTaxableAmount + b2clTaxableAmount + b2csTaxableAmount + exportTaxableAmount;
  
  /// Total tax amount
  double get totalTaxAmount =>
      b2bTaxAmount + b2clTaxAmount + b2csTaxAmount;
  
  /// Net taxable after credit/debit notes
  double get netTaxableAmount =>
      totalTaxableAmount - creditNoteTaxableAmount + debitNoteTaxableAmount;
  
  /// Net tax
  double get netTaxAmount =>
      totalTaxAmount - creditNoteTaxAmount + debitNoteTaxAmount;
}
