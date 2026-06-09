/// Statements Models - Party Ledger Statements
/// View firm's credit and debit transactions, invoices, notes, and payments
library;

/// Statement Transaction types
enum StatementTransactionType {
  invoice, // Sales Invoice - Debit for customers, Credit for suppliers
  creditNote, // Credit Note - Credit
  debitNote, // Debit Note - Debit
  payment, // Payment Entry - Credit (inflow)
  receipt, // Receipt Entry - Debit (inflow)
  openingBalance, // Opening Balance
  closingBalance, // Closing Balance
}

/// Statement Transaction - Individual ledger entry
class StatementTransaction {
  final int id;
  final DateTime date;
  final String referenceNumber; // Invoice/Note/Voucher number
  final String description; // Party name, narration
  final StatementTransactionType type;
  final double debitAmount; // Increase in receivable/payable
  final double creditAmount; // Decrease in receivable/payable
  final double runningBalance; // Running balance after this transaction
  final String? narration; // Additional notes
  final String? remarks; // Additional remarks

  StatementTransaction({
    required this.id,
    required this.date,
    required this.referenceNumber,
    required this.description,
    required this.type,
    this.debitAmount = 0,
    this.creditAmount = 0,
    this.runningBalance = 0,
    this.narration,
    this.remarks,
  });

  factory StatementTransaction.fromJson(Map<String, dynamic> json) {
    return StatementTransaction(
      id: json['id'] as int? ?? 0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      referenceNumber: json['reference_number'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: _parseTransactionType(json['type']),
      debitAmount: (json['debit_amount'] as num?)?.toDouble() ?? 0,
      creditAmount: (json['credit_amount'] as num?)?.toDouble() ?? 0,
      runningBalance: (json['running_balance'] as num?)?.toDouble() ?? 0,
      narration: json['narration'] as String?,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'reference_number': referenceNumber,
    'description': description,
    'type': type.name,
    'debit_amount': debitAmount,
    'credit_amount': creditAmount,
    'running_balance': runningBalance,
    'narration': narration,
    'remarks': remarks,
  };

  static StatementTransactionType _parseTransactionType(dynamic value) {
    if (value == null) return StatementTransactionType.invoice;
    final str = value.toString();
    
    // Map from backend values to enum names
    const typeMap = {
      'invoice': StatementTransactionType.invoice,
      'creditNote': StatementTransactionType.creditNote,
      'debitNote': StatementTransactionType.debitNote,
      'payment': StatementTransactionType.payment,
      'receipt': StatementTransactionType.receipt,
      'openingBalance': StatementTransactionType.openingBalance,
      'closingBalance': StatementTransactionType.closingBalance,
    };
    
    return typeMap[str] ?? StatementTransactionType.invoice;
  }
}

/// Statement Summary - Balance and totals
class StatementSummary {
  final double openingBalance;
  final String openingBalanceType; // 'DR' or 'CR'
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;
  final String closingBalanceType; // 'DR' or 'CR'
  final double creditLimit;
  final double availableCredit;
  final int creditDays;
  final DateTime? lastTransactionDate;
  final int totalTransactions;

  StatementSummary({
    this.openingBalance = 0,
    this.openingBalanceType = 'DR',
    this.totalDebit = 0,
    this.totalCredit = 0,
    this.closingBalance = 0,
    this.closingBalanceType = 'DR',
    this.creditLimit = 0,
    this.availableCredit = 0,
    this.creditDays = 30,
    this.lastTransactionDate,
    this.totalTransactions = 0,
  });

  /// Check if party is due
  bool get isOverdue => closingBalance > 0 && closingBalanceType == 'CR';

  /// Get balance color indicator
  String get balanceIndicator {
    if (closingBalance == 0) return 'balanced';
    return closingBalanceType == 'DR' ? 'debit' : 'credit';
  }

  factory StatementSummary.fromJson(Map<String, dynamic> json) {
    return StatementSummary(
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
      openingBalanceType: json['opening_balance_type'] as String? ?? 'DR',
      totalDebit: (json['total_debit'] as num?)?.toDouble() ?? 0,
      totalCredit: (json['total_credit'] as num?)?.toDouble() ?? 0,
      closingBalance: (json['closing_balance'] as num?)?.toDouble() ?? 0,
      closingBalanceType: json['closing_balance_type'] as String? ?? 'DR',
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0,
      availableCredit: (json['available_credit'] as num?)?.toDouble() ?? 0,
      creditDays: json['credit_days'] as int? ?? 30,
      lastTransactionDate: json['last_transaction_date'] != null
          ? DateTime.tryParse(json['last_transaction_date'])
          : null,
      totalTransactions: json['total_transactions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'opening_balance': openingBalance,
    'opening_balance_type': openingBalanceType,
    'total_debit': totalDebit,
    'total_credit': totalCredit,
    'closing_balance': closingBalance,
    'closing_balance_type': closingBalanceType,
    'credit_limit': creditLimit,
    'available_credit': availableCredit,
    'credit_days': creditDays,
    'last_transaction_date': lastTransactionDate?.toIso8601String(),
    'total_transactions': totalTransactions,
  };
}

/// Complete Party Statement
class PartyStatement {
  final int partyId;
  final String partyName;
  final String? gstin;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime fromDate;
  final DateTime toDate;
  final List<StatementTransaction> transactions;
  final StatementSummary summary;

  PartyStatement({
    required this.partyId,
    required this.partyName,
    this.gstin,
    this.phone,
    this.email,
    this.address,
    required this.fromDate,
    required this.toDate,
    this.transactions = const [],
    StatementSummary? summary,
  }) : summary = summary ?? StatementSummary();

  /// Filter transactions by type
  List<StatementTransaction> getTransactionsByType(
    StatementTransactionType type,
  ) {
    return transactions.where((t) => t.type == type).toList();
  }

  /// Get invoices only
  List<StatementTransaction> get invoices {
    return getTransactionsByType(StatementTransactionType.invoice);
  }

  /// Get credit notes only
  List<StatementTransaction> get creditNotes {
    return getTransactionsByType(StatementTransactionType.creditNote);
  }

  /// Get debit notes only
  List<StatementTransaction> get debitNotes {
    return getTransactionsByType(StatementTransactionType.debitNote);
  }

  /// Get payment entries only
  List<StatementTransaction> get payments {
    return [
      ...getTransactionsByType(StatementTransactionType.payment),
      ...getTransactionsByType(StatementTransactionType.receipt),
    ];
  }

  factory PartyStatement.fromJson(Map<String, dynamic> json) {
    final transactionsList =
        (json['transactions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
    return PartyStatement(
      partyId: json['party_id'] as int? ?? 0,
      partyName: json['party_name'] as String? ?? '',
      gstin: json['gstin'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      fromDate: json['from_date'] != null
          ? DateTime.parse(json['from_date'])
          : DateTime.now(),
      toDate: json['to_date'] != null
          ? DateTime.parse(json['to_date'])
          : DateTime.now(),
      transactions: transactionsList
          .map((t) => StatementTransaction.fromJson(t))
          .toList(),
      summary: json['summary'] != null
          ? StatementSummary.fromJson(json['summary'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'party_id': partyId,
    'party_name': partyName,
    'gstin': gstin,
    'phone': phone,
    'email': email,
    'address': address,
    'from_date': fromDate.toIso8601String(),
    'to_date': toDate.toIso8601String(),
    'transactions': transactions.map((t) => t.toJson()).toList(),
    'summary': summary.toJson(),
  };
}
