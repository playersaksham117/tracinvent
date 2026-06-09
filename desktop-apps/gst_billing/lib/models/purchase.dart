/// Purchase Models - BillEase Accounts+
/// Purchase entry, returns, supplier credit, due tracking
library;

import 'package:flutter/material.dart';

/// Purchase Invoice Model
class Purchase {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String supplierId;
  final String supplierName;
  final String? supplierGstin;
  final List<PurchaseItem> items;
  final double subtotal;
  final double discountAmount;
  final double discountPercent;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double totalTax;
  final double roundOff;
  final double grandTotal;
  final double paidAmount;
  final double dueAmount;
  final PurchaseStatus status;
  final PaymentStatus paymentStatus;
  final PurchaseType type;
  final String? notes;
  final List<ExpenseTag> expenseTags;
  final List<PurchasePayment> payments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Purchase({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.supplierId,
    required this.supplierName,
    this.supplierGstin,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0,
    this.discountPercent = 0,
    required this.taxableAmount,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.cessAmount = 0,
    required this.totalTax,
    this.roundOff = 0,
    required this.grandTotal,
    this.paidAmount = 0,
    required this.dueAmount,
    this.status = PurchaseStatus.draft,
    this.paymentStatus = PaymentStatus.unpaid,
    this.type = PurchaseType.purchase,
    this.notes,
    this.expenseTags = const [],
    this.payments = const [],
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOverdue => dueDate != null && 
      DateTime.now().isAfter(dueDate!) && 
      paymentStatus != PaymentStatus.paid;

  int get daysOverdue {
    if (!isOverdue || dueDate == null) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  Purchase copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? supplierId,
    String? supplierName,
    String? supplierGstin,
    List<PurchaseItem>? items,
    double? subtotal,
    double? discountAmount,
    double? discountPercent,
    double? taxableAmount,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? cessAmount,
    double? totalTax,
    double? roundOff,
    double? grandTotal,
    double? paidAmount,
    double? dueAmount,
    PurchaseStatus? status,
    PaymentStatus? paymentStatus,
    PurchaseType? type,
    String? notes,
    List<ExpenseTag>? expenseTags,
    List<PurchasePayment>? payments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Purchase(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierGstin: supplierGstin ?? this.supplierGstin,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      cessAmount: cessAmount ?? this.cessAmount,
      totalTax: totalTax ?? this.totalTax,
      roundOff: roundOff ?? this.roundOff,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      expenseTags: expenseTags ?? this.expenseTags,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'invoiceDate': invoiceDate.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'supplierId': supplierId,
    'supplierName': supplierName,
    'supplierGstin': supplierGstin,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'discountAmount': discountAmount,
    'discountPercent': discountPercent,
    'taxableAmount': taxableAmount,
    'cgstAmount': cgstAmount,
    'sgstAmount': sgstAmount,
    'igstAmount': igstAmount,
    'cessAmount': cessAmount,
    'totalTax': totalTax,
    'roundOff': roundOff,
    'grandTotal': grandTotal,
    'paidAmount': paidAmount,
    'dueAmount': dueAmount,
    'status': status.name,
    'paymentStatus': paymentStatus.name,
    'type': type.name,
    'notes': notes,
    'expenseTags': expenseTags.map((t) => t.toJson()).toList(),
    'payments': payments.map((p) => p.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
    id: json['id'],
    invoiceNumber: json['invoiceNumber'],
    invoiceDate: DateTime.parse(json['invoiceDate']),
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    supplierId: json['supplierId'],
    supplierName: json['supplierName'],
    supplierGstin: json['supplierGstin'],
    items: (json['items'] as List).map((i) => PurchaseItem.fromJson(i)).toList(),
    subtotal: (json['subtotal'] as num).toDouble(),
    discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
    discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
    taxableAmount: (json['taxableAmount'] as num).toDouble(),
    cgstAmount: (json['cgstAmount'] as num?)?.toDouble() ?? 0,
    sgstAmount: (json['sgstAmount'] as num?)?.toDouble() ?? 0,
    igstAmount: (json['igstAmount'] as num?)?.toDouble() ?? 0,
    cessAmount: (json['cessAmount'] as num?)?.toDouble() ?? 0,
    totalTax: (json['totalTax'] as num).toDouble(),
    roundOff: (json['roundOff'] as num?)?.toDouble() ?? 0,
    grandTotal: (json['grandTotal'] as num).toDouble(),
    paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
    dueAmount: (json['dueAmount'] as num).toDouble(),
    status: PurchaseStatus.values.firstWhere((e) => e.name == json['status']),
    paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == json['paymentStatus']),
    type: PurchaseType.values.firstWhere((e) => e.name == json['type']),
    notes: json['notes'],
    expenseTags: (json['expenseTags'] as List?)?.map((t) => ExpenseTag.fromJson(t)).toList() ?? [],
    payments: (json['payments'] as List?)?.map((p) => PurchasePayment.fromJson(p)).toList() ?? [],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );
}

/// Purchase Item
class PurchaseItem {
  final String id;
  final String itemId;
  final String itemName;
  final String? hsnCode;
  final String? batchNumber;
  final DateTime? expiryDate;
  final double quantity;
  final String unit;
  final double purchasePrice;
  final double mrp;
  final double sellingPrice;
  final double discountPercent;
  final double discountAmount;
  final double taxableAmount;
  final double gstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessRate;
  final double cessAmount;
  final double totalAmount;

  PurchaseItem({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.hsnCode,
    this.batchNumber,
    this.expiryDate,
    required this.quantity,
    this.unit = 'pcs',
    required this.purchasePrice,
    required this.mrp,
    required this.sellingPrice,
    this.discountPercent = 0,
    this.discountAmount = 0,
    required this.taxableAmount,
    required this.gstRate,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.cessRate = 0,
    this.cessAmount = 0,
    required this.totalAmount,
  });

  double get profitMargin => sellingPrice > 0 
      ? ((sellingPrice - purchasePrice) / sellingPrice) * 100 
      : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'itemName': itemName,
    'hsnCode': hsnCode,
    'batchNumber': batchNumber,
    'expiryDate': expiryDate?.toIso8601String(),
    'quantity': quantity,
    'unit': unit,
    'purchasePrice': purchasePrice,
    'mrp': mrp,
    'sellingPrice': sellingPrice,
    'discountPercent': discountPercent,
    'discountAmount': discountAmount,
    'taxableAmount': taxableAmount,
    'gstRate': gstRate,
    'cgstAmount': cgstAmount,
    'sgstAmount': sgstAmount,
    'igstAmount': igstAmount,
    'cessRate': cessRate,
    'cessAmount': cessAmount,
    'totalAmount': totalAmount,
  };

  factory PurchaseItem.fromJson(Map<String, dynamic> json) => PurchaseItem(
    id: json['id'],
    itemId: json['itemId'],
    itemName: json['itemName'],
    hsnCode: json['hsnCode'],
    batchNumber: json['batchNumber'],
    expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] ?? 'pcs',
    purchasePrice: (json['purchasePrice'] as num).toDouble(),
    mrp: (json['mrp'] as num).toDouble(),
    sellingPrice: (json['sellingPrice'] as num).toDouble(),
    discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
    discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
    taxableAmount: (json['taxableAmount'] as num).toDouble(),
    gstRate: (json['gstRate'] as num).toDouble(),
    cgstAmount: (json['cgstAmount'] as num?)?.toDouble() ?? 0,
    sgstAmount: (json['sgstAmount'] as num?)?.toDouble() ?? 0,
    igstAmount: (json['igstAmount'] as num?)?.toDouble() ?? 0,
    cessRate: (json['cessRate'] as num?)?.toDouble() ?? 0,
    cessAmount: (json['cessAmount'] as num?)?.toDouble() ?? 0,
    totalAmount: (json['totalAmount'] as num).toDouble(),
  );
}

/// Purchase Return (Debit Note to Supplier)
class PurchaseReturn {
  final String id;
  final String returnNumber;
  final DateTime returnDate;
  final String purchaseId;
  final String purchaseInvoiceNumber;
  final String supplierId;
  final String supplierName;
  final List<PurchaseReturnItem> items;
  final double totalAmount;
  final String reason;
  final PurchaseReturnStatus status;
  final DateTime createdAt;

  PurchaseReturn({
    required this.id,
    required this.returnNumber,
    required this.returnDate,
    required this.purchaseId,
    required this.purchaseInvoiceNumber,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.totalAmount,
    required this.reason,
    this.status = PurchaseReturnStatus.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'returnNumber': returnNumber,
    'returnDate': returnDate.toIso8601String(),
    'purchaseId': purchaseId,
    'purchaseInvoiceNumber': purchaseInvoiceNumber,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'items': items.map((i) => i.toJson()).toList(),
    'totalAmount': totalAmount,
    'reason': reason,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PurchaseReturn.fromJson(Map<String, dynamic> json) => PurchaseReturn(
    id: json['id'],
    returnNumber: json['returnNumber'],
    returnDate: DateTime.parse(json['returnDate']),
    purchaseId: json['purchaseId'],
    purchaseInvoiceNumber: json['purchaseInvoiceNumber'],
    supplierId: json['supplierId'],
    supplierName: json['supplierName'],
    items: (json['items'] as List).map((i) => PurchaseReturnItem.fromJson(i)).toList(),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    reason: json['reason'],
    status: PurchaseReturnStatus.values.firstWhere((e) => e.name == json['status']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class PurchaseReturnItem {
  final String itemId;
  final String itemName;
  final double quantity;
  final String unit;
  final double rate;
  final double amount;

  PurchaseReturnItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'itemName': itemName,
    'quantity': quantity,
    'unit': unit,
    'rate': rate,
    'amount': amount,
  };

  factory PurchaseReturnItem.fromJson(Map<String, dynamic> json) => PurchaseReturnItem(
    itemId: json['itemId'],
    itemName: json['itemName'],
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'],
    rate: (json['rate'] as num).toDouble(),
    amount: (json['amount'] as num).toDouble(),
  );
}

/// Supplier Credit
class SupplierCredit {
  final String id;
  final String supplierId;
  final String supplierName;
  final double creditLimit;
  final double usedCredit;
  final double availableCredit;
  final int creditDays;
  final DateTime? lastPurchaseDate;
  final double totalOutstanding;

  SupplierCredit({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.creditLimit,
    required this.usedCredit,
    required this.availableCredit,
    this.creditDays = 30,
    this.lastPurchaseDate,
    this.totalOutstanding = 0,
  });

  bool get isOverLimit => usedCredit > creditLimit;
  double get utilizationPercent => creditLimit > 0 ? (usedCredit / creditLimit) * 100 : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'creditLimit': creditLimit,
    'usedCredit': usedCredit,
    'availableCredit': availableCredit,
    'creditDays': creditDays,
    'lastPurchaseDate': lastPurchaseDate?.toIso8601String(),
    'totalOutstanding': totalOutstanding,
  };

  factory SupplierCredit.fromJson(Map<String, dynamic> json) => SupplierCredit(
    id: json['id'],
    supplierId: json['supplierId'],
    supplierName: json['supplierName'],
    creditLimit: (json['creditLimit'] as num).toDouble(),
    usedCredit: (json['usedCredit'] as num).toDouble(),
    availableCredit: (json['availableCredit'] as num).toDouble(),
    creditDays: json['creditDays'] ?? 30,
    lastPurchaseDate: json['lastPurchaseDate'] != null ? DateTime.parse(json['lastPurchaseDate']) : null,
    totalOutstanding: (json['totalOutstanding'] as num?)?.toDouble() ?? 0,
  );
}

/// Purchase Payment
class PurchasePayment {
  final String id;
  final String purchaseId;
  final DateTime paymentDate;
  final double amount;
  final PaymentMode paymentMode;
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;

  PurchasePayment({
    required this.id,
    required this.purchaseId,
    required this.paymentDate,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'purchaseId': purchaseId,
    'paymentDate': paymentDate.toIso8601String(),
    'amount': amount,
    'paymentMode': paymentMode.name,
    'referenceNumber': referenceNumber,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PurchasePayment.fromJson(Map<String, dynamic> json) => PurchasePayment(
    id: json['id'],
    purchaseId: json['purchaseId'],
    paymentDate: DateTime.parse(json['paymentDate']),
    amount: (json['amount'] as num).toDouble(),
    paymentMode: PaymentMode.values.firstWhere((e) => e.name == json['paymentMode']),
    referenceNumber: json['referenceNumber'],
    notes: json['notes'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// Expense Tag for categorizing purchase expenses
class ExpenseTag {
  final String id;
  final String name;
  final Color color;
  final String? description;
  final ExpenseCategory category;

  ExpenseTag({
    required this.id,
    required this.name,
    required this.color,
    this.description,
    this.category = ExpenseCategory.general,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value,
    'description': description,
    'category': category.name,
  };

  factory ExpenseTag.fromJson(Map<String, dynamic> json) => ExpenseTag(
    id: json['id'],
    name: json['name'],
    color: Color(json['color']),
    description: json['description'],
    category: ExpenseCategory.values.firstWhere((e) => e.name == json['category']),
  );
}

/// Due Tracking
class DueTracking {
  final String supplierId;
  final String supplierName;
  final double totalDue;
  final double overdueDue;
  final int overdueCount;
  final List<DueInvoice> dueInvoices;
  final DateTime? oldestDueDate;

  DueTracking({
    required this.supplierId,
    required this.supplierName,
    required this.totalDue,
    required this.overdueDue,
    required this.overdueCount,
    required this.dueInvoices,
    this.oldestDueDate,
  });

  int get maxDaysOverdue {
    if (oldestDueDate == null) return 0;
    return DateTime.now().difference(oldestDueDate!).inDays;
  }
}

class DueInvoice {
  final String purchaseId;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double totalAmount;
  final double dueAmount;
  final int daysOverdue;

  DueInvoice({
    required this.purchaseId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.totalAmount,
    required this.dueAmount,
    required this.daysOverdue,
  });
}

/// Enums
enum PurchaseStatus { draft, confirmed, received, cancelled }

enum PurchaseReturnStatus { pending, approved, rejected, completed }

enum PurchaseType { purchase, purchaseReturn }

enum PaymentStatus { unpaid, partiallyPaid, paid, overdue }

enum PaymentMode { cash, bank, upi, cheque, card, credit, other }

enum ExpenseCategory {
  inventory,
  operating,
  administrative,
  marketing,
  utilities,
  salary,
  rent,
  maintenance,
  general,
}

extension ExpenseCategoryExt on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.inventory: return 'Inventory';
      case ExpenseCategory.operating: return 'Operating';
      case ExpenseCategory.administrative: return 'Administrative';
      case ExpenseCategory.marketing: return 'Marketing';
      case ExpenseCategory.utilities: return 'Utilities';
      case ExpenseCategory.salary: return 'Salary';
      case ExpenseCategory.rent: return 'Rent';
      case ExpenseCategory.maintenance: return 'Maintenance';
      case ExpenseCategory.general: return 'General';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.inventory: return Icons.inventory;
      case ExpenseCategory.operating: return Icons.settings;
      case ExpenseCategory.administrative: return Icons.admin_panel_settings;
      case ExpenseCategory.marketing: return Icons.campaign;
      case ExpenseCategory.utilities: return Icons.electrical_services;
      case ExpenseCategory.salary: return Icons.people;
      case ExpenseCategory.rent: return Icons.home;
      case ExpenseCategory.maintenance: return Icons.build;
      case ExpenseCategory.general: return Icons.category;
    }
  }
}

extension PaymentStatusExt on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.unpaid: return 'Unpaid';
      case PaymentStatus.partiallyPaid: return 'Partial';
      case PaymentStatus.paid: return 'Paid';
      case PaymentStatus.overdue: return 'Overdue';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.unpaid: return Colors.orange;
      case PaymentStatus.partiallyPaid: return Colors.blue;
      case PaymentStatus.paid: return Colors.green;
      case PaymentStatus.overdue: return Colors.red;
    }
  }
}

extension PaymentModeExt on PaymentMode {
  String get displayName {
    switch (this) {
      case PaymentMode.cash: return 'Cash';
      case PaymentMode.bank: return 'Bank Transfer';
      case PaymentMode.upi: return 'UPI';
      case PaymentMode.cheque: return 'Cheque';
      case PaymentMode.card: return 'Card';
      case PaymentMode.credit: return 'Credit';
      case PaymentMode.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMode.cash: return Icons.payments;
      case PaymentMode.bank: return Icons.account_balance;
      case PaymentMode.upi: return Icons.phone_android;
      case PaymentMode.cheque: return Icons.receipt_long;
      case PaymentMode.card: return Icons.credit_card;
      case PaymentMode.credit: return Icons.account_balance_wallet;
      case PaymentMode.other: return Icons.more_horiz;
    }
  }
}
