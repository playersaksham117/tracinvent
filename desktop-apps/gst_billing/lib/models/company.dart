/// Company Profile Model
library;

class CompanyProfile {
  final int? id;
  final String companyName;
  final String legalName;
  final String? gstin;
  final String? pan;
  final String? cin;
  final String? tan;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String stateCode;
  final String stateName;
  final String pincode;
  final String country;
  final String? phone;
  final String? email;
  final String? website;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankBranch;
  final String? logoPath;
  final String? signaturePath;
  final String financialYearStart;
  final String invoicePrefix;
  final int invoiceStartNumber;
  final String? termsAndConditions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CompanyProfile({
    this.id,
    required this.companyName,
    required this.legalName,
    this.gstin,
    this.pan,
    this.cin,
    this.tan,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.stateCode,
    required this.stateName,
    required this.pincode,
    this.country = 'India',
    this.phone,
    this.email,
    this.website,
    this.bankName,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankBranch,
    this.logoPath,
    this.signaturePath,
    this.financialYearStart = '04-01',
    this.invoicePrefix = 'INV',
    this.invoiceStartNumber = 1,
    this.termsAndConditions,
    this.createdAt,
    this.updatedAt,
  });

  /// Get full address as string
  String get fullAddress {
    final parts = <String>[];
    parts.add(addressLine1);
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.add('$city - $pincode');
    parts.add(stateName);
    return parts.join('\n');
  }

  /// Get GST formatted string
  String get gstinDisplay => gstin ?? 'Unregistered';

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      id: json['id'] as int?,
      companyName: json['company_name'] as String? ?? '',
      legalName: json['legal_name'] as String? ?? '',
      gstin: json['gstin'] as String?,
      pan: json['pan'] as String?,
      cin: json['cin'] as String?,
      tan: json['tan'] as String?,
      addressLine1: json['address_line1'] as String? ?? '',
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String? ?? '',
      stateCode: json['state_code'] as String? ?? '',
      stateName: json['state_name'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankIfsc: json['bank_ifsc'] as String?,
      bankBranch: json['bank_branch'] as String?,
      logoPath: json['logo_path'] as String?,
      signaturePath: json['signature_path'] as String?,
      financialYearStart: json['financial_year_start'] as String? ?? '04-01',
      invoicePrefix: json['invoice_prefix'] as String? ?? 'INV',
      invoiceStartNumber: json['invoice_start_number'] as int? ?? 1,
      termsAndConditions: json['terms_and_conditions'] as String?,
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
      'company_name': companyName,
      'legal_name': legalName,
      'gstin': gstin,
      'pan': pan,
      'cin': cin,
      'tan': tan,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state_code': stateCode,
      'state_name': stateName,
      'pincode': pincode,
      'country': country,
      'phone': phone,
      'email': email,
      'website': website,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_ifsc': bankIfsc,
      'bank_branch': bankBranch,
      'logo_path': logoPath,
      'signature_path': signaturePath,
      'financial_year_start': financialYearStart,
      'invoice_prefix': invoicePrefix,
      'invoice_start_number': invoiceStartNumber,
      'terms_and_conditions': termsAndConditions,
    };
  }

  CompanyProfile copyWith({
    int? id,
    String? companyName,
    String? legalName,
    String? gstin,
    String? pan,
    String? cin,
    String? tan,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? stateCode,
    String? stateName,
    String? pincode,
    String? country,
    String? phone,
    String? email,
    String? website,
    String? bankName,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankBranch,
    String? logoPath,
    String? signaturePath,
    String? financialYearStart,
    String? invoicePrefix,
    int? invoiceStartNumber,
    String? termsAndConditions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      legalName: legalName ?? this.legalName,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      cin: cin ?? this.cin,
      tan: tan ?? this.tan,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      stateCode: stateCode ?? this.stateCode,
      stateName: stateName ?? this.stateName,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankBranch: bankBranch ?? this.bankBranch,
      logoPath: logoPath ?? this.logoPath,
      signaturePath: signaturePath ?? this.signaturePath,
      financialYearStart: financialYearStart ?? this.financialYearStart,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      invoiceStartNumber: invoiceStartNumber ?? this.invoiceStartNumber,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Indian State with GST Code
class IndianState {
  final String code;
  final String name;
  final String type;

  IndianState({
    required this.code,
    required this.name,
    required this.type,
  });

  factory IndianState.fromJson(Map<String, dynamic> json) {
    return IndianState(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'STATE',
    );
  }

  @override
  String toString() => '$code - $name';
}

/// Financial Year
class FinancialYear {
  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isClosed;
  final DateTime? createdAt;

  FinancialYear({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
    this.isClosed = false,
    this.createdAt,
  });

  factory FinancialYear.fromJson(Map<String, dynamic> json) {
    return FinancialYear(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: (json['is_active'] as int?) == 1,
      isClosed: (json['is_closed'] as int?) == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

/// HSN/SAC Code
class HSNCode {
  final int? id;
  final String code;
  final String description;
  final String type;
  final double gstRate;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final double cessRate;
  final String cessType;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;
  final DateTime? createdAt;

  HSNCode({
    this.id,
    required this.code,
    required this.description,
    this.type = 'HSN',
    this.gstRate = 0,
    this.cgstRate = 0,
    this.sgstRate = 0,
    this.igstRate = 0,
    this.cessRate = 0,
    this.cessType = 'PERCENTAGE',
    this.effectiveFrom,
    this.effectiveTo,
    this.isActive = true,
    this.createdAt,
  });

  factory HSNCode.fromJson(Map<String, dynamic> json) {
    return HSNCode(
      id: json['id'] as int?,
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'HSN',
      gstRate: (json['gst_rate'] as num?)?.toDouble() ?? 0,
      cgstRate: (json['cgst_rate'] as num?)?.toDouble() ?? 0,
      sgstRate: (json['sgst_rate'] as num?)?.toDouble() ?? 0,
      igstRate: (json['igst_rate'] as num?)?.toDouble() ?? 0,
      cessRate: (json['cess_rate'] as num?)?.toDouble() ?? 0,
      cessType: json['cess_type'] as String? ?? 'PERCENTAGE',
      effectiveFrom: json['effective_from'] != null
          ? DateTime.parse(json['effective_from'] as String)
          : null,
      effectiveTo: json['effective_to'] != null
          ? DateTime.parse(json['effective_to'] as String)
          : null,
      isActive: (json['is_active'] as int?) == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'description': description,
      'type': type,
      'gst_rate': gstRate,
      'cgst_rate': cgstRate,
      'sgst_rate': sgstRate,
      'igst_rate': igstRate,
      'cess_rate': cessRate,
    };
  }

  @override
  String toString() => '$code - $description ($gstRate%)';
}

/// Voucher Type (Invoice types)
class VoucherType {
  final int? id;
  final String name;
  final String code;
  final String type;
  final String? prefix;
  final int startingNumber;
  final bool autoNumbering;
  final bool affectsInventory;
  final bool isSystemType;
  final bool isActive;
  final DateTime? createdAt;

  VoucherType({
    this.id,
    required this.name,
    required this.code,
    required this.type,
    this.prefix,
    this.startingNumber = 1,
    this.autoNumbering = true,
    this.affectsInventory = false,
    this.isSystemType = false,
    this.isActive = true,
    this.createdAt,
  });

  factory VoucherType.fromJson(Map<String, dynamic> json) {
    return VoucherType(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? '',
      prefix: json['prefix'] as String?,
      startingNumber: json['starting_number'] as int? ?? 1,
      autoNumbering: (json['auto_numbering'] as int?) == 1,
      affectsInventory: (json['affects_inventory'] as int?) == 1,
      isSystemType: (json['is_system_type'] as int?) == 1,
      isActive: (json['is_active'] as int?) == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
