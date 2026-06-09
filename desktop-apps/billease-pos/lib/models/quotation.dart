class Quotation {
  final int? id;
  final String? serverId;
  final String tenantId;
  final String quotationNumber;
  final String quotationType; // 'sale' or 'purchase'
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final int? supplierId;
  final String? supplierName;
  final String? supplierPhone;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String? notes;
  final String status; // draft, sent, accepted, rejected, expired, converted
  final DateTime? validUntil;
  final int syncStatus;
  final String createdAt;
  final String updatedAt;

  Quotation({
    this.id,
    this.serverId,
    required this.tenantId,
    required this.quotationNumber,
    required this.quotationType,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.supplierId,
    this.supplierName,
    this.supplierPhone,
    required this.subtotal,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    this.notes,
    this.status = 'draft',
    this.validUntil,
    this.syncStatus = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'tenant_id': tenantId,
      'quotation_number': quotationNumber,
      'quotation_type': quotationType,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'supplier_phone': supplierPhone,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'notes': notes,
      'status': status,
      'valid_until': validUntil?.toIso8601String(),
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Quotation.fromMap(Map<String, dynamic> map) {
    return Quotation(
      id: map['id'] as int?,
      serverId: map['server_id'] as String?,
      tenantId: map['tenant_id'] as String,
      quotationNumber: map['quotation_number'] as String,
      quotationType: map['quotation_type'] as String,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      supplierId: map['supplier_id'] as int?,
      supplierName: map['supplier_name'] as String?,
      supplierPhone: map['supplier_phone'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'draft',
      validUntil: map['valid_until'] != null 
          ? DateTime.tryParse(map['valid_until'] as String) 
          : null,
      syncStatus: map['sync_status'] as int? ?? 0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Quotation copyWith({
    int? id,
    String? serverId,
    String? tenantId,
    String? quotationNumber,
    String? quotationType,
    int? customerId,
    String? customerName,
    String? customerPhone,
    int? supplierId,
    String? supplierName,
    String? supplierPhone,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    String? notes,
    String? status,
    DateTime? validUntil,
    int? syncStatus,
    String? createdAt,
    String? updatedAt,
  }) {
    return Quotation(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      tenantId: tenantId ?? this.tenantId,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      quotationType: quotationType ?? this.quotationType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      validUntil: validUntil ?? this.validUntil,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class QuotationItem {
  final int? id;
  final String? serverId;
  final int quotationId;
  final int productId;
  final String productName;
  final String sku;
  final String? barcode;
  final int quantity;
  final double unitPrice;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final int syncStatus;
  final String createdAt;

  QuotationItem({
    this.id,
    this.serverId,
    required this.quotationId,
    required this.productId,
    required this.productName,
    required this.sku,
    this.barcode,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    required this.totalAmount,
    this.syncStatus = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'quotation_id': quotationId,
      'product_id': productId,
      'product_name': productName,
      'sku': sku,
      'barcode': barcode,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_amount': discountAmount,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'sync_status': syncStatus,
      'created_at': createdAt,
    };
  }

  factory QuotationItem.fromMap(Map<String, dynamic> map) {
    return QuotationItem(
      id: map['id'] as int?,
      serverId: map['server_id'] as String?,
      quotationId: map['quotation_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      sku: map['sku'] as String,
      barcode: map['barcode'] as String?,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      syncStatus: map['sync_status'] as int? ?? 0,
      createdAt: map['created_at'] as String,
    );
  }
}
