/// Ledger Model
/// Represents accounts (parties, expense accounts, etc.)
library;

import 'gst_invoice.dart';

class Ledger {
  final int? id;
  final String name;
  final String? alias;
  final int ledgerGroupId;
  final double openingBalance;
  final String balanceType;
  final double currentBalance;

  // Party Details
  final bool isParty;
  final String? gstin;
  final String? pan;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? billingAddress;
  final String? billingCity;
  final String? billingStateCode;
  final String? billingPincode;
  final String? shippingAddress;
  final String? shippingCity;
  final String? shippingStateCode;
  final String? shippingPincode;
  final double creditLimit;
  final int creditDays;

  final GSTRegistrationType gstRegistrationType;

  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Ledger({
    this.id,
    required this.name,
    this.alias,
    required this.ledgerGroupId,
    this.openingBalance = 0,
    this.balanceType = 'DR',
    this.currentBalance = 0,
    this.isParty = false,
    this.gstin,
    this.pan,
    this.contactPerson,
    this.phone,
    this.email,
    this.billingAddress,
    this.billingCity,
    this.billingStateCode,
    this.billingPincode,
    this.shippingAddress,
    this.shippingCity,
    this.shippingStateCode,
    this.shippingPincode,
    this.creditLimit = 0,
    this.creditDays = 0,
    this.gstRegistrationType = GSTRegistrationType.unregistered,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Get full billing address
  String get fullBillingAddress {
    final parts = <String>[];
    if (billingAddress != null) parts.add(billingAddress!);
    if (billingCity != null) parts.add(billingCity!);
    if (billingPincode != null) parts.add(billingPincode!);
    return parts.join(', ');
  }

  /// Check if credit limit exceeded
  bool get isCreditLimitExceeded =>
      creditLimit > 0 && currentBalance > creditLimit;

  factory Ledger.fromJson(Map<String, dynamic> json) {
    // Safe parsing of ledger_group_id which might come as int, double, string, or bool from backend
    final groupIdVal = json['ledger_group_id'];
    int ledgerGroupId = 0;
    if (groupIdVal is int) {
      ledgerGroupId = groupIdVal;
    } else if (groupIdVal is double) {
      ledgerGroupId = groupIdVal.toInt();
    } else if (groupIdVal is String) {
      ledgerGroupId = int.tryParse(groupIdVal) ?? 0;
    } else if (groupIdVal is bool) {
      ledgerGroupId = groupIdVal ? 1 : 0;
    }
    
    // Safe parsing of is_party which might come as int, bool, or string from backend
    bool isPartyVal = false;
    final isPartyData = json['is_party'];
    if (isPartyData is bool) {
      isPartyVal = isPartyData;
    } else if (isPartyData is int) {
      isPartyVal = isPartyData == 1;
    } else if (isPartyData is String) {
      isPartyVal = isPartyData.toLowerCase() == 'true' || isPartyData == '1';
    }
    
    // Safe parsing of is_active which might come as int, bool, or string from backend
    bool isActiveVal = true;
    final isActiveData = json['is_active'];
    if (isActiveData is bool) {
      isActiveVal = isActiveData;
    } else if (isActiveData is int) {
      isActiveVal = isActiveData == 1;
    } else if (isActiveData is String) {
      isActiveVal = isActiveData.toLowerCase() == 'true' || isActiveData == '1';
    }
    
    return Ledger(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      alias: json['alias'] as String?,
      ledgerGroupId: ledgerGroupId,
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
      balanceType: json['balance_type'] as String? ?? 'DR',
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
      isParty: isPartyVal,
      gstin: json['gstin'] as String?,
      pan: json['pan'] as String?,
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      billingAddress: json['billing_address'] as String?,
      billingCity: json['billing_city'] as String?,
      billingStateCode: json['billing_state_code'] as String?,
      billingPincode: json['billing_pincode'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      shippingCity: json['shipping_city'] as String?,
      shippingStateCode: json['shipping_state_code'] as String?,
      shippingPincode: json['shipping_pincode'] as String?,
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0,
      creditDays: json['credit_days'] as int? ?? 0,
      gstRegistrationType:
          _parseGSTRegistrationType(json['gst_registration_type'] as String?),
      isActive: isActiveVal,
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
      'name': name,
      'alias': alias,
      'ledger_group_id': ledgerGroupId,
      'opening_balance': openingBalance,
      'balance_type': balanceType,
      'is_party': isParty,
      'gstin': gstin,
      'pan': pan,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'billing_address': billingAddress,
      'billing_city': billingCity,
      'billing_state_code': billingStateCode,
      'billing_pincode': billingPincode,
      'shipping_address': shippingAddress,
      'shipping_city': shippingCity,
      'shipping_state_code': shippingStateCode,
      'shipping_pincode': shippingPincode,
      'credit_limit': creditLimit,
      'credit_days': creditDays,
      'gst_registration_type': gstRegistrationType.name.toUpperCase(),
    };
  }

  static GSTRegistrationType _parseGSTRegistrationType(String? value) {
    switch (value?.toUpperCase()) {
      case 'REGULAR':
        return GSTRegistrationType.regular;
      case 'COMPOSITION':
        return GSTRegistrationType.composition;
      case 'CONSUMER':
        return GSTRegistrationType.consumer;
      case 'OVERSEAS':
        return GSTRegistrationType.overseas;
      case 'SEZ':
        return GSTRegistrationType.sez;
      default:
        return GSTRegistrationType.unregistered;
    }
  }

  Ledger copyWith({
    int? id,
    String? name,
    String? alias,
    int? ledgerGroupId,
    double? openingBalance,
    String? balanceType,
    double? currentBalance,
    bool? isParty,
    String? gstin,
    String? pan,
    String? contactPerson,
    String? phone,
    String? email,
    String? billingAddress,
    String? billingCity,
    String? billingStateCode,
    String? billingPincode,
    String? shippingAddress,
    String? shippingCity,
    String? shippingStateCode,
    String? shippingPincode,
    double? creditLimit,
    int? creditDays,
    GSTRegistrationType? gstRegistrationType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ledger(
      id: id ?? this.id,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      ledgerGroupId: ledgerGroupId ?? this.ledgerGroupId,
      openingBalance: openingBalance ?? this.openingBalance,
      balanceType: balanceType ?? this.balanceType,
      currentBalance: currentBalance ?? this.currentBalance,
      isParty: isParty ?? this.isParty,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      billingAddress: billingAddress ?? this.billingAddress,
      billingCity: billingCity ?? this.billingCity,
      billingStateCode: billingStateCode ?? this.billingStateCode,
      billingPincode: billingPincode ?? this.billingPincode,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingStateCode: shippingStateCode ?? this.shippingStateCode,
      shippingPincode: shippingPincode ?? this.shippingPincode,
      creditLimit: creditLimit ?? this.creditLimit,
      creditDays: creditDays ?? this.creditDays,
      gstRegistrationType: gstRegistrationType ?? this.gstRegistrationType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Ledger(id: $id, name: $name, currentBalance: $currentBalance)';
  }
}

/// Ledger Group (Chart of Accounts)
class LedgerGroup {
  final int? id;
  final String name;
  final int? parentId;
  final String nature;
  final bool isSystemGroup;
  final DateTime? createdAt;

  LedgerGroup({
    this.id,
    required this.name,
    this.parentId,
    required this.nature,
    this.isSystemGroup = false,
    this.createdAt,
  });

  factory LedgerGroup.fromJson(Map<String, dynamic> json) {
    return LedgerGroup(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      parentId: json['parent_id'] as int?,
      nature: json['nature'] as String? ?? 'ASSETS',
      isSystemGroup: (json['is_system_group'] as int?) == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

/// Ledger Transaction Entry
class LedgerTransaction {
  final int? id;
  final DateTime transactionDate;
  final int? voucherTypeId;
  final String? voucherNumber;
  final int? referenceId;
  final String? referenceType;
  final int ledgerId;
  final double debitAmount;
  final double creditAmount;
  final double balance;
  final String? narration;
  final int? financialYearId;
  final bool isOpeningBalance;
  final DateTime? createdAt;

  LedgerTransaction({
    this.id,
    required this.transactionDate,
    this.voucherTypeId,
    this.voucherNumber,
    this.referenceId,
    this.referenceType,
    required this.ledgerId,
    this.debitAmount = 0,
    this.creditAmount = 0,
    this.balance = 0,
    this.narration,
    this.financialYearId,
    this.isOpeningBalance = false,
    this.createdAt,
  });

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) {
    return LedgerTransaction(
      id: json['id'] as int?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      voucherTypeId: json['voucher_type_id'] as int?,
      voucherNumber: json['voucher_number'] as String?,
      referenceId: json['reference_id'] as int?,
      referenceType: json['reference_type'] as String?,
      ledgerId: json['ledger_id'] as int? ?? 0,
      debitAmount: (json['debit_amount'] as num?)?.toDouble() ?? 0,
      creditAmount: (json['credit_amount'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      narration: json['narration'] as String?,
      financialYearId: json['financial_year_id'] as int?,
      isOpeningBalance: (json['is_opening_balance'] as int?) == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
