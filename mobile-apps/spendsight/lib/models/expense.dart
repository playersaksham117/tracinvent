import 'package:uuid/uuid.dart';

/// Payment modes available for expenses
enum PaymentMode {
  cash,
  card,
  upi,
  bankTransfer,
  wallet,
  cheque,
  other;

  String get displayName {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.card:
        return 'Card';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.wallet:
        return 'Wallet';
      case PaymentMode.cheque:
        return 'Cheque';
      case PaymentMode.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMode.cash:
        return '💵';
      case PaymentMode.card:
        return '💳';
      case PaymentMode.upi:
        return '📱';
      case PaymentMode.bankTransfer:
        return '🏦';
      case PaymentMode.wallet:
        return '👛';
      case PaymentMode.cheque:
        return '📄';
      case PaymentMode.other:
        return '💰';
    }
  }
}

/// Sync status for offline-first functionality
enum SyncStatus {
  pending,
  synced,
  failed,
}

/// Expense model with all required fields
class Expense {
  final String id;
  final double amount;
  final String category;
  final PaymentMode paymentMode;
  final DateTime date;
  final String? note;
  final String? attachmentPath; // Local file path
  final String? attachmentUrl; // Remote URL after sync
  
  // Business-only fields
  final double? gstAmount;
  final double? gstPercentage;
  final String? gstNumber;
  
  // Member/Department for Family & Business
  final String? member;
  final String? department;
  
  // OCR data
  final String? ocrRawText;
  final Map<String, dynamic>? ocrExtractedData;
  
  // Sync status
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    String? id,
    required this.amount,
    required this.category,
    required this.paymentMode,
    required this.date,
    this.note,
    this.attachmentPath,
    this.attachmentUrl,
    this.gstAmount,
    this.gstPercentage,
    this.gstNumber,
    this.member,
    this.department,
    this.ocrRawText,
    this.ocrExtractedData,
    this.syncStatus = SyncStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calculate total amount including GST
  double get totalWithGst => amount + (gstAmount ?? 0);

  /// Check if expense has attachment
  bool get hasAttachment =>
      attachmentPath != null || attachmentUrl != null;

  /// Copy with method for immutability
  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    PaymentMode? paymentMode,
    DateTime? date,
    String? note,
    String? attachmentPath,
    String? attachmentUrl,
    double? gstAmount,
    double? gstPercentage,
    String? gstNumber,
    String? member,
    String? department,
    String? ocrRawText,
    Map<String, dynamic>? ocrExtractedData,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMode: paymentMode ?? this.paymentMode,
      date: date ?? this.date,
      note: note ?? this.note,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      gstAmount: gstAmount ?? this.gstAmount,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      gstNumber: gstNumber ?? this.gstNumber,
      member: member ?? this.member,
      department: department ?? this.department,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      ocrExtractedData: ocrExtractedData ?? this.ocrExtractedData,
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
      'category': category,
      'paymentMode': paymentMode.name,
      'date': date.toIso8601String(),
      'note': note,
      'attachmentPath': attachmentPath,
      'attachmentUrl': attachmentUrl,
      'gstAmount': gstAmount,
      'gstPercentage': gstPercentage,
      'gstNumber': gstNumber,
      'member': member,
      'department': department,
      'ocrRawText': ocrRawText,
      'ocrExtractedData': ocrExtractedData?.toString(),
      'syncStatus': syncStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from Map (database)
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      category: map['category'],
      paymentMode: PaymentMode.values.firstWhere(
        (e) => e.name == map['paymentMode'],
        orElse: () => PaymentMode.cash,
      ),
      date: DateTime.parse(map['date']),
      note: map['note'],
      attachmentPath: map['attachmentPath'],
      attachmentUrl: map['attachmentUrl'],
      gstAmount: map['gstAmount'] != null 
          ? (map['gstAmount'] as num).toDouble() 
          : null,
      gstPercentage: map['gstPercentage'] != null 
          ? (map['gstPercentage'] as num).toDouble() 
          : null,
      gstNumber: map['gstNumber'],
      member: map['member'],
      department: map['department'],
      ocrRawText: map['ocrRawText'],
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.pending,
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
