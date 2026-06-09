enum LicenseType { free, basic, pro, lifetime }

enum LicenseStatus { unactivated, active, expired, revoked, suspended }

class LicenseInfo {
  final String id;
  final String licenseKey;
  final String? userId;
  final LicenseType licenseType;
  final DateTime purchaseDate;
  final DateTime? expiryDate;
  final int activationLimit;
  final int activeDeviceCount;
  final LicenseStatus status;

  const LicenseInfo({
    required this.id,
    required this.licenseKey,
    this.userId,
    required this.licenseType,
    required this.purchaseDate,
    this.expiryDate,
    required this.activationLimit,
    required this.activeDeviceCount,
    required this.status,
  });

  bool get isValid =>
      status == LicenseStatus.active &&
      (expiryDate == null || expiryDate!.isAfter(DateTime.now()));

  bool get hasSlots => activeDeviceCount < activationLimit;

  String get typeLabel {
    switch (licenseType) {
      case LicenseType.free:
        return 'Free';
      case LicenseType.basic:
        return 'Basic';
      case LicenseType.pro:
        return 'Pro';
      case LicenseType.lifetime:
        return 'Lifetime';
    }
  }

  factory LicenseInfo.fromMap(Map<String, dynamic> map) {
    return LicenseInfo(
      id: map['id'] as String,
      licenseKey: map['license_key'] as String? ?? '',
      userId: map['user_id'] as String?,
      licenseType: _parseType(map['license_type'] as String? ?? 'free'),
      purchaseDate: DateTime.tryParse(map['purchase_date'] ?? '') ?? DateTime.now(),
      expiryDate: map['expiry_date'] != null ? DateTime.tryParse(map['expiry_date']) : null,
      activationLimit: (map['activation_limit'] as int?) ?? 1,
      activeDeviceCount: (map['active_device_count'] as int?) ?? 0,
      status: _parseStatus(map['status'] as String? ?? 'unactivated'),
    );
  }

  static LicenseType _parseType(String t) {
    switch (t) {
      case 'basic':    return LicenseType.basic;
      case 'pro':      return LicenseType.pro;
      case 'lifetime': return LicenseType.lifetime;
      default:         return LicenseType.free;
    }
  }

  static LicenseStatus _parseStatus(String s) {
    switch (s) {
      case 'active':      return LicenseStatus.active;
      case 'expired':     return LicenseStatus.expired;
      case 'revoked':     return LicenseStatus.revoked;
      case 'suspended':   return LicenseStatus.suspended;
      default:            return LicenseStatus.unactivated;
    }
  }
}

/// Cached locally to allow grace period offline validation
class CachedValidation {
  final DateTime validatedAt;
  final String licenseType;
  final DateTime? expiryDate;
  final String fingerprintHash;

  const CachedValidation({
    required this.validatedAt,
    required this.licenseType,
    this.expiryDate,
    required this.fingerprintHash,
  });

  /// Grace period: 7 days without internet
  bool get withinGracePeriod =>
      DateTime.now().difference(validatedAt).inDays < 7;

  bool get licenseNotExpired =>
      expiryDate == null || expiryDate!.isAfter(DateTime.now());

  bool get isValid => withinGracePeriod && licenseNotExpired;

  factory CachedValidation.fromMap(Map<String, dynamic> map) {
    return CachedValidation(
      validatedAt: DateTime.parse(map['validated_at'] as String),
      licenseType: map['license_type'] as String,
      expiryDate: map['expiry_date'] != null
          ? DateTime.tryParse(map['expiry_date'] as String)
          : null,
      fingerprintHash: map['fingerprint_hash'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'validated_at': validatedAt.toIso8601String(),
        'license_type': licenseType,
        'expiry_date': expiryDate?.toIso8601String(),
        'fingerprint_hash': fingerprintHash,
      };
}
