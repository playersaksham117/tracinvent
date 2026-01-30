/// Branch Model for Multi-Store Support
class Branch {
  final int? id;
  final String? serverId;
  final String tenantId;
  final String branchCode;
  final String branchName;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? phone;
  final String? email;
  final String? gstin;
  final String? managerName;
  final bool isActive;
  final bool isHeadOffice;
  final int syncStatus;
  final String? createdAt;
  final String? updatedAt;

  Branch({
    this.id,
    this.serverId,
    required this.tenantId,
    required this.branchCode,
    required this.branchName,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.phone,
    this.email,
    this.gstin,
    this.managerName,
    this.isActive = true,
    this.isHeadOffice = false,
    this.syncStatus = 0,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'tenant_id': tenantId,
      'branch_code': branchCode,
      'branch_name': branchName,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'phone': phone,
      'email': email,
      'gstin': gstin,
      'manager_name': managerName,
      'is_active': isActive ? 1 : 0,
      'is_head_office': isHeadOffice ? 1 : 0,
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'] as int?,
      serverId: map['server_id'] as String?,
      tenantId: map['tenant_id'] as String,
      branchCode: map['branch_code'] as String,
      branchName: map['branch_name'] as String,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      postalCode: map['postal_code'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      gstin: map['gstin'] as String?,
      managerName: map['manager_name'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      isHeadOffice: (map['is_head_office'] as int?) == 1,
      syncStatus: map['sync_status'] as int? ?? 0,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Branch copyWith({
    int? id,
    String? serverId,
    String? tenantId,
    String? branchCode,
    String? branchName,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? phone,
    String? email,
    String? gstin,
    String? managerName,
    bool? isActive,
    bool? isHeadOffice,
    int? syncStatus,
    String? createdAt,
    String? updatedAt,
  }) {
    return Branch(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      tenantId: tenantId ?? this.tenantId,
      branchCode: branchCode ?? this.branchCode,
      branchName: branchName ?? this.branchName,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      managerName: managerName ?? this.managerName,
      isActive: isActive ?? this.isActive,
      isHeadOffice: isHeadOffice ?? this.isHeadOffice,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
