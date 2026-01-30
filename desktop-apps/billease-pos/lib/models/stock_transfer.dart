/// Stock Transfer Model for Inter-Branch Stock Movement
class StockTransfer {
  final int? id;
  final String? serverId;
  final String tenantId;
  final String transferNumber;
  final int fromBranchId;
  final String fromBranchName;
  final int toBranchId;
  final String toBranchName;
  final String status; // pending, approved, in_transit, received, rejected
  final String? notes;
  final String? approvedBy;
  final String? approvedAt;
  final String? receivedBy;
  final String? receivedAt;
  final int syncStatus;
  final String? createdAt;
  final String? updatedAt;
  final List<StockTransferItem>? items;

  StockTransfer({
    this.id,
    this.serverId,
    required this.tenantId,
    required this.transferNumber,
    required this.fromBranchId,
    required this.fromBranchName,
    required this.toBranchId,
    required this.toBranchName,
    this.status = 'pending',
    this.notes,
    this.approvedBy,
    this.approvedAt,
    this.receivedBy,
    this.receivedAt,
    this.syncStatus = 0,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'tenant_id': tenantId,
      'transfer_number': transferNumber,
      'from_branch_id': fromBranchId,
      'from_branch_name': fromBranchName,
      'to_branch_id': toBranchId,
      'to_branch_name': toBranchName,
      'status': status,
      'notes': notes,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
      'received_by': receivedBy,
      'received_at': receivedAt,
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory StockTransfer.fromMap(Map<String, dynamic> map) {
    return StockTransfer(
      id: map['id'] as int?,
      serverId: map['server_id'] as String?,
      tenantId: map['tenant_id'] as String,
      transferNumber: map['transfer_number'] as String,
      fromBranchId: map['from_branch_id'] as int,
      fromBranchName: map['from_branch_name'] as String,
      toBranchId: map['to_branch_id'] as int,
      toBranchName: map['to_branch_name'] as String,
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      approvedBy: map['approved_by'] as String?,
      approvedAt: map['approved_at'] as String?,
      receivedBy: map['received_by'] as String?,
      receivedAt: map['received_at'] as String?,
      syncStatus: map['sync_status'] as int? ?? 0,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}

/// Stock Transfer Item Model
class StockTransferItem {
  final int? id;
  final int? transferId;
  final int productId;
  final String productName;
  final String? sku;
  final int requestedQuantity;
  final int? approvedQuantity;
  final int? receivedQuantity;
  final String? notes;

  StockTransferItem({
    this.id,
    this.transferId,
    required this.productId,
    required this.productName,
    this.sku,
    required this.requestedQuantity,
    this.approvedQuantity,
    this.receivedQuantity,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transfer_id': transferId,
      'product_id': productId,
      'product_name': productName,
      'sku': sku,
      'requested_quantity': requestedQuantity,
      'approved_quantity': approvedQuantity,
      'received_quantity': receivedQuantity,
      'notes': notes,
    };
  }

  factory StockTransferItem.fromMap(Map<String, dynamic> map) {
    return StockTransferItem(
      id: map['id'] as int?,
      transferId: map['transfer_id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      sku: map['sku'] as String?,
      requestedQuantity: map['requested_quantity'] as int,
      approvedQuantity: map['approved_quantity'] as int?,
      receivedQuantity: map['received_quantity'] as int?,
      notes: map['notes'] as String?,
    );
  }
}
