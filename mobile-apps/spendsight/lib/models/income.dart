import 'package:uuid/uuid.dart';

/// Income source types
enum IncomeSource {
  cash,
  pos,
  bankTransfer,
  upi,
  cheque,
  online,
  other;

  String get displayName {
    switch (this) {
      case IncomeSource.cash:
        return 'Cash';
      case IncomeSource.pos:
        return 'POS';
      case IncomeSource.bankTransfer:
        return 'Bank Transfer';
      case IncomeSource.upi:
        return 'UPI';
      case IncomeSource.cheque:
        return 'Cheque';
      case IncomeSource.online:
        return 'Online';
      case IncomeSource.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case IncomeSource.cash:
        return '💵';
      case IncomeSource.pos:
        return '🖥️';
      case IncomeSource.bankTransfer:
        return '🏦';
      case IncomeSource.upi:
        return '📱';
      case IncomeSource.cheque:
        return '📄';
      case IncomeSource.online:
        return '🌐';
      case IncomeSource.other:
        return '💰';
    }
  }
}

/// Income categories
enum IncomeCategory {
  sales,
  services,
  salary,
  freelance,
  investment,
  rental,
  refund,
  gift,
  other;

  String get displayName {
    switch (this) {
      case IncomeCategory.sales:
        return 'Sales';
      case IncomeCategory.services:
        return 'Services';
      case IncomeCategory.salary:
        return 'Salary';
      case IncomeCategory.freelance:
        return 'Freelance';
      case IncomeCategory.investment:
        return 'Investment';
      case IncomeCategory.rental:
        return 'Rental';
      case IncomeCategory.refund:
        return 'Refund';
      case IncomeCategory.gift:
        return 'Gift';
      case IncomeCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case IncomeCategory.sales:
        return '🛒';
      case IncomeCategory.services:
        return '🔧';
      case IncomeCategory.salary:
        return '💼';
      case IncomeCategory.freelance:
        return '💻';
      case IncomeCategory.investment:
        return '📈';
      case IncomeCategory.rental:
        return '🏠';
      case IncomeCategory.refund:
        return '↩️';
      case IncomeCategory.gift:
        return '🎁';
      case IncomeCategory.other:
        return '💵';
    }
  }
}

/// Sync status for offline-first functionality
enum IncomeSyncStatus {
  pending,
  synced,
  failed,
}

/// Income model with all required fields
class Income {
  final String id;
  final double amount;
  final IncomeCategory category;
  final IncomeSource source;
  final DateTime date;
  final String? description;
  
  // Optional customer info
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  
  // Reference/Invoice
  final String? invoiceNumber;
  final String? referenceId;
  
  // Business fields
  final double? taxAmount;
  final double? taxPercentage;
  
  // Sync status
  final IncomeSyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Income({
    String? id,
    required this.amount,
    required this.category,
    required this.source,
    required this.date,
    this.description,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.invoiceNumber,
    this.referenceId,
    this.taxAmount,
    this.taxPercentage,
    this.syncStatus = IncomeSyncStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calculate total amount including tax
  double get totalWithTax => amount + (taxAmount ?? 0);

  /// Check if has customer info
  bool get hasCustomer => customerName != null && customerName!.isNotEmpty;

  /// Copy with method for immutability
  Income copyWith({
    String? id,
    double? amount,
    IncomeCategory? category,
    IncomeSource? source,
    DateTime? date,
    String? description,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? invoiceNumber,
    String? referenceId,
    double? taxAmount,
    double? taxPercentage,
    IncomeSyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      source: source ?? this.source,
      date: date ?? this.date,
      description: description ?? this.description,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      referenceId: referenceId ?? this.referenceId,
      taxAmount: taxAmount ?? this.taxAmount,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category.name,
      'source': source.name,
      'date': date.toIso8601String(),
      'description': description,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'invoiceNumber': invoiceNumber,
      'referenceId': referenceId,
      'taxAmount': taxAmount,
      'taxPercentage': taxPercentage,
      'syncStatus': syncStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from Map (database)
  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      category: IncomeCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => IncomeCategory.other,
      ),
      source: IncomeSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => IncomeSource.cash,
      ),
      date: DateTime.parse(map['date']),
      description: map['description'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      customerEmail: map['customerEmail'],
      invoiceNumber: map['invoiceNumber'],
      referenceId: map['referenceId'],
      taxAmount: map['taxAmount'] != null
          ? (map['taxAmount'] as num).toDouble()
          : null,
      taxPercentage: map['taxPercentage'] != null
          ? (map['taxPercentage'] as num).toDouble()
          : null,
      syncStatus: IncomeSyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => IncomeSyncStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
