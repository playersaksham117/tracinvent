/// Payment & Ledger Models - BillEase Accounts+
/// Customer/Supplier ledger, receipts/payments, auto balance, reminders, aging
library;

import 'package:flutter/material.dart';

/// Party Ledger - Customer or Supplier account
class PartyLedger {
  final String id;
  final String partyId;
  final String partyName;
  final PartyType partyType;
  final String? phone;
  final String? email;
  final String? gstin;
  final double openingBalance;
  final BalanceType openingBalanceType;
  final double currentBalance;
  final BalanceType currentBalanceType;
  final double creditLimit;
  final int creditDays;
  final double totalDebit;
  final double totalCredit;
  final DateTime? lastTransactionDate;
  final List<LedgerEntry> entries;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PartyLedger({
    required this.id,
    required this.partyId,
    required this.partyName,
    required this.partyType,
    this.phone,
    this.email,
    this.gstin,
    this.openingBalance = 0,
    this.openingBalanceType = BalanceType.debit,
    this.currentBalance = 0,
    this.currentBalanceType = BalanceType.debit,
    this.creditLimit = 0,
    this.creditDays = 30,
    this.totalDebit = 0,
    this.totalCredit = 0,
    this.lastTransactionDate,
    this.entries = const [],
    required this.createdAt,
    this.updatedAt,
  });

  // For customers: Debit = They owe us (receivable)
  // For suppliers: Credit = We owe them (payable)
  double get receivable => partyType == PartyType.customer && currentBalanceType == BalanceType.debit
      ? currentBalance
      : 0;

  double get payable => partyType == PartyType.supplier && currentBalanceType == BalanceType.credit
      ? currentBalance
      : 0;

  bool get hasOutstanding => currentBalance > 0;

  bool get isOverCreditLimit => creditLimit > 0 && currentBalance > creditLimit;

  Map<String, dynamic> toJson() => {
    'id': id,
    'partyId': partyId,
    'partyName': partyName,
    'partyType': partyType.name,
    'phone': phone,
    'email': email,
    'gstin': gstin,
    'openingBalance': openingBalance,
    'openingBalanceType': openingBalanceType.name,
    'currentBalance': currentBalance,
    'currentBalanceType': currentBalanceType.name,
    'creditLimit': creditLimit,
    'creditDays': creditDays,
    'totalDebit': totalDebit,
    'totalCredit': totalCredit,
    'lastTransactionDate': lastTransactionDate?.toIso8601String(),
    'entries': entries.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory PartyLedger.fromJson(Map<String, dynamic> json) => PartyLedger(
    id: json['id'],
    partyId: json['partyId'],
    partyName: json['partyName'],
    partyType: PartyType.values.firstWhere((e) => e.name == json['partyType']),
    phone: json['phone'],
    email: json['email'],
    gstin: json['gstin'],
    openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
    openingBalanceType: BalanceType.values.firstWhere(
      (e) => e.name == json['openingBalanceType'], 
      orElse: () => BalanceType.debit
    ),
    currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
    currentBalanceType: BalanceType.values.firstWhere(
      (e) => e.name == json['currentBalanceType'], 
      orElse: () => BalanceType.debit
    ),
    creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
    creditDays: json['creditDays'] ?? 30,
    totalDebit: (json['totalDebit'] as num?)?.toDouble() ?? 0,
    totalCredit: (json['totalCredit'] as num?)?.toDouble() ?? 0,
    lastTransactionDate: json['lastTransactionDate'] != null 
        ? DateTime.parse(json['lastTransactionDate']) : null,
    entries: (json['entries'] as List?)?.map((e) => LedgerEntry.fromJson(e)).toList() ?? [],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );
}

/// Ledger Entry - Individual transaction in ledger
class LedgerEntry {
  final String id;
  final String ledgerId;
  final DateTime entryDate;
  final EntryType entryType;
  final String? referenceId;
  final String? referenceNumber;
  final String particulars;
  final double debitAmount;
  final double creditAmount;
  final double runningBalance;
  final BalanceType runningBalanceType;
  final String? notes;
  final DateTime createdAt;

  LedgerEntry({
    required this.id,
    required this.ledgerId,
    required this.entryDate,
    required this.entryType,
    this.referenceId,
    this.referenceNumber,
    required this.particulars,
    this.debitAmount = 0,
    this.creditAmount = 0,
    required this.runningBalance,
    required this.runningBalanceType,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ledgerId': ledgerId,
    'entryDate': entryDate.toIso8601String(),
    'entryType': entryType.name,
    'referenceId': referenceId,
    'referenceNumber': referenceNumber,
    'particulars': particulars,
    'debitAmount': debitAmount,
    'creditAmount': creditAmount,
    'runningBalance': runningBalance,
    'runningBalanceType': runningBalanceType.name,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
    id: json['id'],
    ledgerId: json['ledgerId'],
    entryDate: DateTime.parse(json['entryDate']),
    entryType: EntryType.values.firstWhere((e) => e.name == json['entryType']),
    referenceId: json['referenceId'],
    referenceNumber: json['referenceNumber'],
    particulars: json['particulars'],
    debitAmount: (json['debitAmount'] as num?)?.toDouble() ?? 0,
    creditAmount: (json['creditAmount'] as num?)?.toDouble() ?? 0,
    runningBalance: (json['runningBalance'] as num).toDouble(),
    runningBalanceType: BalanceType.values.firstWhere((e) => e.name == json['runningBalanceType']),
    notes: json['notes'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// Payment Receipt - Money received from customer
class PaymentReceipt {
  final String id;
  final String receiptNumber;
  final DateTime receiptDate;
  final String customerId;
  final String customerName;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? bankName;
  final String? chequeNumber;
  final DateTime? chequeDate;
  final String? upiId;
  final String? transactionId;
  final List<ReceiptAllocation> allocations;
  final String? notes;
  final ReceiptStatus status;
  final DateTime createdAt;

  PaymentReceipt({
    required this.id,
    required this.receiptNumber,
    required this.receiptDate,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.paymentMethod,
    this.bankName,
    this.chequeNumber,
    this.chequeDate,
    this.upiId,
    this.transactionId,
    this.allocations = const [],
    this.notes,
    this.status = ReceiptStatus.received,
    required this.createdAt,
  });

  double get allocatedAmount => allocations.fold(0, (sum, a) => sum + a.amount);
  double get unallocatedAmount => amount - allocatedAmount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'receiptNumber': receiptNumber,
    'receiptDate': receiptDate.toIso8601String(),
    'customerId': customerId,
    'customerName': customerName,
    'amount': amount,
    'paymentMethod': paymentMethod.name,
    'bankName': bankName,
    'chequeNumber': chequeNumber,
    'chequeDate': chequeDate?.toIso8601String(),
    'upiId': upiId,
    'transactionId': transactionId,
    'allocations': allocations.map((a) => a.toJson()).toList(),
    'notes': notes,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) => PaymentReceipt(
    id: json['id'],
    receiptNumber: json['receiptNumber'],
    receiptDate: DateTime.parse(json['receiptDate']),
    customerId: json['customerId'],
    customerName: json['customerName'],
    amount: (json['amount'] as num).toDouble(),
    paymentMethod: PaymentMethod.values.firstWhere((e) => e.name == json['paymentMethod']),
    bankName: json['bankName'],
    chequeNumber: json['chequeNumber'],
    chequeDate: json['chequeDate'] != null ? DateTime.parse(json['chequeDate']) : null,
    upiId: json['upiId'],
    transactionId: json['transactionId'],
    allocations: (json['allocations'] as List?)?.map((a) => ReceiptAllocation.fromJson(a)).toList() ?? [],
    notes: json['notes'],
    status: ReceiptStatus.values.firstWhere((e) => e.name == json['status']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// Payment Made - Money paid to supplier
class PaymentMade {
  final String id;
  final String paymentNumber;
  final DateTime paymentDate;
  final String supplierId;
  final String supplierName;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? bankName;
  final String? chequeNumber;
  final DateTime? chequeDate;
  final String? upiId;
  final String? transactionId;
  final List<PaymentAllocation> allocations;
  final String? notes;
  final PaymentMadeStatus status;
  final DateTime createdAt;

  PaymentMade({
    required this.id,
    required this.paymentNumber,
    required this.paymentDate,
    required this.supplierId,
    required this.supplierName,
    required this.amount,
    required this.paymentMethod,
    this.bankName,
    this.chequeNumber,
    this.chequeDate,
    this.upiId,
    this.transactionId,
    this.allocations = const [],
    this.notes,
    this.status = PaymentMadeStatus.paid,
    required this.createdAt,
  });

  double get allocatedAmount => allocations.fold(0, (sum, a) => sum + a.amount);
  double get unallocatedAmount => amount - allocatedAmount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'paymentNumber': paymentNumber,
    'paymentDate': paymentDate.toIso8601String(),
    'supplierId': supplierId,
    'supplierName': supplierName,
    'amount': amount,
    'paymentMethod': paymentMethod.name,
    'bankName': bankName,
    'chequeNumber': chequeNumber,
    'chequeDate': chequeDate?.toIso8601String(),
    'upiId': upiId,
    'transactionId': transactionId,
    'allocations': allocations.map((a) => a.toJson()).toList(),
    'notes': notes,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PaymentMade.fromJson(Map<String, dynamic> json) => PaymentMade(
    id: json['id'],
    paymentNumber: json['paymentNumber'],
    paymentDate: DateTime.parse(json['paymentDate']),
    supplierId: json['supplierId'],
    supplierName: json['supplierName'],
    amount: (json['amount'] as num).toDouble(),
    paymentMethod: PaymentMethod.values.firstWhere((e) => e.name == json['paymentMethod']),
    bankName: json['bankName'],
    chequeNumber: json['chequeNumber'],
    chequeDate: json['chequeDate'] != null ? DateTime.parse(json['chequeDate']) : null,
    upiId: json['upiId'],
    transactionId: json['transactionId'],
    allocations: (json['allocations'] as List?)?.map((a) => PaymentAllocation.fromJson(a)).toList() ?? [],
    notes: json['notes'],
    status: PaymentMadeStatus.values.firstWhere((e) => e.name == json['status']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// Receipt Allocation - Link receipt to specific invoices
class ReceiptAllocation {
  final String invoiceId;
  final String invoiceNumber;
  final double invoiceAmount;
  final double amount;
  final DateTime allocationDate;

  ReceiptAllocation({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceAmount,
    required this.amount,
    required this.allocationDate,
  });

  Map<String, dynamic> toJson() => {
    'invoiceId': invoiceId,
    'invoiceNumber': invoiceNumber,
    'invoiceAmount': invoiceAmount,
    'amount': amount,
    'allocationDate': allocationDate.toIso8601String(),
  };

  factory ReceiptAllocation.fromJson(Map<String, dynamic> json) => ReceiptAllocation(
    invoiceId: json['invoiceId'],
    invoiceNumber: json['invoiceNumber'],
    invoiceAmount: (json['invoiceAmount'] as num).toDouble(),
    amount: (json['amount'] as num).toDouble(),
    allocationDate: DateTime.parse(json['allocationDate']),
  );
}

/// Payment Allocation - Link payment to specific purchase bills
class PaymentAllocation {
  final String purchaseId;
  final String invoiceNumber;
  final double invoiceAmount;
  final double amount;
  final DateTime allocationDate;

  PaymentAllocation({
    required this.purchaseId,
    required this.invoiceNumber,
    required this.invoiceAmount,
    required this.amount,
    required this.allocationDate,
  });

  Map<String, dynamic> toJson() => {
    'purchaseId': purchaseId,
    'invoiceNumber': invoiceNumber,
    'invoiceAmount': invoiceAmount,
    'amount': amount,
    'allocationDate': allocationDate.toIso8601String(),
  };

  factory PaymentAllocation.fromJson(Map<String, dynamic> json) => PaymentAllocation(
    purchaseId: json['purchaseId'],
    invoiceNumber: json['invoiceNumber'],
    invoiceAmount: (json['invoiceAmount'] as num).toDouble(),
    amount: (json['amount'] as num).toDouble(),
    allocationDate: DateTime.parse(json['allocationDate']),
  );
}

/// Payment Reminder
class PaymentReminder {
  final String id;
  final String partyId;
  final String partyName;
  final PartyType partyType;
  final String? phone;
  final String? email;
  final double outstandingAmount;
  final DateTime dueDate;
  final int daysOverdue;
  final ReminderStatus status;
  final ReminderType reminderType;
  final DateTime? lastReminderSent;
  final int reminderCount;
  final DateTime? nextReminderDate;
  final String? notes;
  final DateTime createdAt;

  PaymentReminder({
    required this.id,
    required this.partyId,
    required this.partyName,
    required this.partyType,
    this.phone,
    this.email,
    required this.outstandingAmount,
    required this.dueDate,
    required this.daysOverdue,
    this.status = ReminderStatus.pending,
    this.reminderType = ReminderType.manual,
    this.lastReminderSent,
    this.reminderCount = 0,
    this.nextReminderDate,
    this.notes,
    required this.createdAt,
  });

  bool get isOverdue => daysOverdue > 0;

  ReminderPriority get priority {
    if (daysOverdue > 90) return ReminderPriority.critical;
    if (daysOverdue > 60) return ReminderPriority.high;
    if (daysOverdue > 30) return ReminderPriority.medium;
    return ReminderPriority.low;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'partyId': partyId,
    'partyName': partyName,
    'partyType': partyType.name,
    'phone': phone,
    'email': email,
    'outstandingAmount': outstandingAmount,
    'dueDate': dueDate.toIso8601String(),
    'daysOverdue': daysOverdue,
    'status': status.name,
    'reminderType': reminderType.name,
    'lastReminderSent': lastReminderSent?.toIso8601String(),
    'reminderCount': reminderCount,
    'nextReminderDate': nextReminderDate?.toIso8601String(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PaymentReminder.fromJson(Map<String, dynamic> json) => PaymentReminder(
    id: json['id'],
    partyId: json['partyId'],
    partyName: json['partyName'],
    partyType: PartyType.values.firstWhere((e) => e.name == json['partyType']),
    phone: json['phone'],
    email: json['email'],
    outstandingAmount: (json['outstandingAmount'] as num).toDouble(),
    dueDate: DateTime.parse(json['dueDate']),
    daysOverdue: json['daysOverdue'],
    status: ReminderStatus.values.firstWhere((e) => e.name == json['status']),
    reminderType: ReminderType.values.firstWhere((e) => e.name == json['reminderType']),
    lastReminderSent: json['lastReminderSent'] != null ? DateTime.parse(json['lastReminderSent']) : null,
    reminderCount: json['reminderCount'] ?? 0,
    nextReminderDate: json['nextReminderDate'] != null ? DateTime.parse(json['nextReminderDate']) : null,
    notes: json['notes'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// Aging Report
class AgingReport {
  final PartyType partyType;
  final DateTime asOfDate;
  final double total;
  final double current;          // Not yet due
  final double days1To30;        // 1-30 days overdue
  final double days31To60;       // 31-60 days overdue
  final double days61To90;       // 61-90 days overdue
  final double daysOver90;       // 90+ days overdue
  final List<AgingDetail> details;

  AgingReport({
    required this.partyType,
    required this.asOfDate,
    required this.total,
    required this.current,
    required this.days1To30,
    required this.days31To60,
    required this.days61To90,
    required this.daysOver90,
    required this.details,
  });

  Map<String, double> get buckets => {
    'Current': current,
    '1-30 Days': days1To30,
    '31-60 Days': days31To60,
    '61-90 Days': days61To90,
    '90+ Days': daysOver90,
  };
}

class AgingDetail {
  final String partyId;
  final String partyName;
  final String? phone;
  final double total;
  final double current;
  final double days1To30;
  final double days31To60;
  final double days61To90;
  final double daysOver90;
  final List<AgingInvoice> invoices;

  AgingDetail({
    required this.partyId,
    required this.partyName,
    this.phone,
    required this.total,
    required this.current,
    required this.days1To30,
    required this.days31To60,
    required this.days61To90,
    required this.daysOver90,
    required this.invoices,
  });
}

class AgingInvoice {
  final String invoiceId;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double totalAmount;
  final double dueAmount;
  final int daysOverdue;
  final String agingBucket;

  AgingInvoice({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.totalAmount,
    required this.dueAmount,
    required this.daysOverdue,
    required this.agingBucket,
  });
}

/// Ledger Summary
class LedgerSummary {
  final PartyType partyType;
  final int totalParties;
  final double totalReceivable;
  final double totalPayable;
  final double totalOverdue;
  final int overdueCount;
  final DateTime asOfDate;

  LedgerSummary({
    required this.partyType,
    required this.totalParties,
    required this.totalReceivable,
    required this.totalPayable,
    required this.totalOverdue,
    required this.overdueCount,
    required this.asOfDate,
  });
}

/// Enums
enum PartyType { customer, supplier }

enum BalanceType { debit, credit }

enum EntryType {
  openingBalance,
  invoice,
  payment,
  receipt,
  creditNote,
  debitNote,
  adjustment,
}

enum PaymentMethod { cash, bank, upi, cheque, card, other }

enum ReceiptStatus { received, deposited, bounced, cancelled }

enum PaymentMadeStatus { paid, cleared, bounced, cancelled }

enum ReminderStatus { pending, sent, acknowledged, ignored, cancelled }

enum ReminderType { manual, automatic, scheduled }

enum ReminderPriority { low, medium, high, critical }

/// Extensions
extension PartyTypeExt on PartyType {
  String get displayName {
    switch (this) {
      case PartyType.customer: return 'Customer';
      case PartyType.supplier: return 'Supplier';
    }
  }

  IconData get icon {
    switch (this) {
      case PartyType.customer: return Icons.person;
      case PartyType.supplier: return Icons.store;
    }
  }

  Color get color {
    switch (this) {
      case PartyType.customer: return Colors.blue;
      case PartyType.supplier: return Colors.orange;
    }
  }
}

extension EntryTypeExt on EntryType {
  String get displayName {
    switch (this) {
      case EntryType.openingBalance: return 'Opening Balance';
      case EntryType.invoice: return 'Invoice';
      case EntryType.payment: return 'Payment';
      case EntryType.receipt: return 'Receipt';
      case EntryType.creditNote: return 'Credit Note';
      case EntryType.debitNote: return 'Debit Note';
      case EntryType.adjustment: return 'Adjustment';
    }
  }

  IconData get icon {
    switch (this) {
      case EntryType.openingBalance: return Icons.account_balance;
      case EntryType.invoice: return Icons.receipt;
      case EntryType.payment: return Icons.payment;
      case EntryType.receipt: return Icons.receipt_long;
      case EntryType.creditNote: return Icons.note_add;
      case EntryType.debitNote: return Icons.note;
      case EntryType.adjustment: return Icons.tune;
    }
  }
}

extension PaymentMethodExt on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash: return 'Cash';
      case PaymentMethod.bank: return 'Bank Transfer';
      case PaymentMethod.upi: return 'UPI';
      case PaymentMethod.cheque: return 'Cheque';
      case PaymentMethod.card: return 'Card';
      case PaymentMethod.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash: return Icons.payments;
      case PaymentMethod.bank: return Icons.account_balance;
      case PaymentMethod.upi: return Icons.phone_android;
      case PaymentMethod.cheque: return Icons.receipt_long;
      case PaymentMethod.card: return Icons.credit_card;
      case PaymentMethod.other: return Icons.more_horiz;
    }
  }
}

extension ReminderPriorityExt on ReminderPriority {
  Color get color {
    switch (this) {
      case ReminderPriority.low: return Colors.green;
      case ReminderPriority.medium: return Colors.orange;
      case ReminderPriority.high: return Colors.deepOrange;
      case ReminderPriority.critical: return Colors.red;
    }
  }

  String get displayName {
    switch (this) {
      case ReminderPriority.low: return 'Low';
      case ReminderPriority.medium: return 'Medium';
      case ReminderPriority.high: return 'High';
      case ReminderPriority.critical: return 'Critical';
    }
  }
}
