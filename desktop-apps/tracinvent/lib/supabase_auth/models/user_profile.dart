class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String? mobileNumber;
  final String? companyName;
  final String country;
  final DateTime registrationDate;
  final DateTime? lastLogin;
  final String licenseStatus;
  final String licenseType;
  final int deviceCount;
  final DateTime? subscriptionExpiry;
  final bool isAdmin;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.mobileNumber,
    this.companyName,
    required this.country,
    required this.registrationDate,
    this.lastLogin,
    required this.licenseStatus,
    required this.licenseType,
    required this.deviceCount,
    this.subscriptionExpiry,
    required this.isAdmin,
  });

  bool get isLicenseActive =>
      licenseStatus == 'active' || licenseStatus == 'trial';
  bool get isLicenseExpired => licenseStatus == 'expired';
  bool get isFree => licenseType == 'free';
  bool get isPro => licenseType == 'pro' || licenseType == 'lifetime';
  bool get isLifetime => licenseType == 'lifetime';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      mobileNumber: map['mobile_number'] as String?,
      companyName: map['company_name'] as String?,
      country: map['country'] as String? ?? 'IN',
      registrationDate: DateTime.tryParse(map['registration_date'] ?? '') ?? DateTime.now(),
      lastLogin: map['last_login'] != null ? DateTime.tryParse(map['last_login']) : null,
      licenseStatus: map['license_status'] as String? ?? 'inactive',
      licenseType: map['license_type'] as String? ?? 'free',
      deviceCount: (map['device_count'] as int?) ?? 0,
      subscriptionExpiry: map['subscription_expiry'] != null
          ? DateTime.tryParse(map['subscription_expiry'])
          : null,
      isAdmin: map['is_admin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'mobile_number': mobileNumber,
        'company_name': companyName,
        'country': country,
        'last_login': lastLogin?.toIso8601String(),
        'license_status': licenseStatus,
        'license_type': licenseType,
        'device_count': deviceCount,
        'subscription_expiry': subscriptionExpiry?.toIso8601String(),
      };

  UserProfile copyWith({
    String? fullName,
    String? licenseStatus,
    String? licenseType,
    int? deviceCount,
    DateTime? subscriptionExpiry,
    DateTime? lastLogin,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      mobileNumber: mobileNumber,
      companyName: companyName,
      country: country,
      registrationDate: registrationDate,
      lastLogin: lastLogin ?? this.lastLogin,
      licenseStatus: licenseStatus ?? this.licenseStatus,
      licenseType: licenseType ?? this.licenseType,
      deviceCount: deviceCount ?? this.deviceCount,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      isAdmin: isAdmin,
    );
  }
}
