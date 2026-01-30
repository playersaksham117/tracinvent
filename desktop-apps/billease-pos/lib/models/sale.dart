class Sale {
  final int? id;
  final String? serverId;
  final String tenantId;
  final String saleNumber;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final double changeAmount;
  final String paymentMethod;
  final String? paymentReference;
  final String? notes;
  final String status; // completed, pending, cancelled
  final String paymentStatus; // paid, partial, credit
  final int syncStatus;
  final String createdAt;
  final String updatedAt;

  Sale({
    this.id,
    this.serverId,
    required this.tenantId,
    required this.saleNumber,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.subtotal,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.changeAmount = 0,
    required this.paymentMethod,
    this.paymentReference,
    this.notes,
    this.status = 'completed',
    this.paymentStatus = 'paid',
    this.syncStatus = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'tenant_id': tenantId,
      'sale_number': saleNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'notes': notes,
      'status': status,
      'payment_status': paymentStatus,
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      serverId: map['server_id'] as String?,
      tenantId: map['tenant_id'] as String,
      saleNumber: map['sale_number'] as String,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      dueAmount: (map['due_amount'] as num?)?.toDouble() ?? 0,
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String,
      paymentReference: map['payment_reference'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'completed',
      paymentStatus: map['payment_status'] as String? ?? 'paid',
      syncStatus: map['sync_status'] as int? ?? 0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}

class SaleItem {
  final int? id;
  final String? serverId;
  final int saleId;
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

  SaleItem({
    this.id,
    this.serverId,
    required this.saleId,
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
      'sale_id': saleId,
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

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      serverId: map['server_id'] as String?,
      saleId: map['sale_id'] as int,
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
