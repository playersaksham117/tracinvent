class Product {
  final int? id;
  final String? serverId;
  final String tenantId;
  final String name;
  final String sku;
  final String? barcode;
  final String? description;
  final String? category;
  final String? brand;
  final String? hsnSac;
  final String? modelVariant;
  final String unit;
  final double price;
  final double cost;
  final double taxRate;
  final String productType;
  final int stockQuantity;
  final int lowStockThreshold;
  final String? imageUrl;
  final bool isActive;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    this.serverId,
    required this.tenantId,
    required this.name,
    required this.sku,
    this.barcode,
    this.description,
    this.category,
    this.brand,
    this.hsnSac,
    this.modelVariant,
    this.unit = 'piece',
    required this.price,
    this.cost = 0,
    this.taxRate = 0,
    this.productType = 'product',
    this.stockQuantity = 0,
    this.lowStockThreshold = 10,
    this.imageUrl,
    this.isActive = true,
    this.syncStatus = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'tenant_id': tenantId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'description': description,
      'category': category,
      'brand': brand,
      'hsn_sac': hsnSac,
      'model_variant': modelVariant,
      'unit': unit,
      'price': price,
      'cost': cost,
      'tax_rate': taxRate,
      'product_type': productType,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      serverId: map['server_id'],
      tenantId: map['tenant_id'],
      name: map['name'],
      sku: map['sku'],
      barcode: map['barcode'],
      description: map['description'],
      category: map['category'],
      brand: map['brand'],
      hsnSac: map['hsn_sac'],
      modelVariant: map['model_variant'],
      unit: map['unit'] ?? 'piece',
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
      productType: map['product_type'] ?? 'product',
      stockQuantity: map['stock_quantity'] ?? 0,
      lowStockThreshold: map['low_stock_threshold'] ?? 10,
      imageUrl: map['image_url'],
      isActive: map['is_active'] == 1,
      syncStatus: map['sync_status'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Product copyWith({
    int? id,
    String? serverId,
    String? tenantId,
    String? name,
    String? sku,
    String? barcode,
    String? description,
    String? category,
    String? brand,
    String? hsnSac,
    String? modelVariant,
    String? unit,
    double? price,
    double? cost,
    double? taxRate,
    String? productType,
    int? stockQuantity,
    int? lowStockThreshold,
    String? imageUrl,
    bool? isActive,
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      hsnSac: hsnSac ?? this.hsnSac,
      modelVariant: modelVariant ?? this.modelVariant,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      taxRate: taxRate ?? this.taxRate,
      productType: productType ?? this.productType,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLowStock => stockQuantity <= lowStockThreshold;
  bool get isOutOfStock => stockQuantity <= 0;
  bool get isService => productType.toLowerCase() == 'service';

  double get priceWithTax => price + (price * taxRate / 100);
}

class Customer {
  final int? id;
  final String? serverId;
  final String tenantId;
  final String customerCode;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String country;
  final String customerGroup;
  final int loyaltyPoints;
  final double totalPurchases;
  final int totalOrders;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    this.id,
    this.serverId,
    required this.tenantId,
    required this.customerCode,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country = 'India',
    this.customerGroup = 'regular',
    this.loyaltyPoints = 0,
    this.totalPurchases = 0,
    this.totalOrders = 0,
    this.syncStatus = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'tenant_id': tenantId,
      'customer_code': customerCode,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'customer_group': customerGroup,
      'loyalty_points': loyaltyPoints,
      'total_purchases': totalPurchases,
      'total_orders': totalOrders,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      serverId: map['server_id'],
      tenantId: map['tenant_id'],
      customerCode: map['customer_code'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      postalCode: map['postal_code'],
      country: map['country'] ?? 'India',
      customerGroup: map['customer_group'] ?? 'regular',
      loyaltyPoints: map['loyalty_points'] ?? 0,
      totalPurchases: (map['total_purchases'] as num?)?.toDouble() ?? 0,
      totalOrders: map['total_orders'] ?? 0,
      syncStatus: map['sync_status'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

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
  final double changeAmount;
  final String paymentMethod;
  final String? paymentReference;
  final String? notes;
  final String status;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SaleItem>? items;

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
    this.changeAmount = 0,
    required this.paymentMethod,
    this.paymentReference,
    this.notes,
    this.status = 'completed',
    this.syncStatus = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.items,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

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
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'notes': notes,
      'status': status,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      serverId: map['server_id'],
      tenantId: map['tenant_id'],
      saleNumber: map['sale_number'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'],
      paymentReference: map['payment_reference'],
      notes: map['notes'],
      status: map['status'] ?? 'completed',
      syncStatus: map['sync_status'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
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
  final int quantity;
  final double unitPrice;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final int syncStatus;
  final DateTime createdAt;

  SaleItem({
    this.id,
    this.serverId,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    required this.totalAmount,
    this.syncStatus = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'sku': sku,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_amount': discountAmount,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      serverId: map['server_id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      sku: map['sku'],
      quantity: map['quantity'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      syncStatus: map['sync_status'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class Supplier {
  final int? id;
  final String? serverId;
  final String tenantId;
  final String supplierCode;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String country;
  final String? gstin;
  final String? panNumber;
  final String? bankName;
  final String? bankAccount;
  final String? ifscCode;
  final double totalPurchases;
  final double outstandingBalance;
  final bool isActive;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    this.id,
    this.serverId,
    required this.tenantId,
    required this.supplierCode,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country = 'India',
    this.gstin,
    this.panNumber,
    this.bankName,
    this.bankAccount,
    this.ifscCode,
    this.totalPurchases = 0,
    this.outstandingBalance = 0,
    this.isActive = true,
    this.syncStatus = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'tenant_id': tenantId,
      'supplier_code': supplierCode,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'gstin': gstin,
      'pan_number': panNumber,
      'bank_name': bankName,
      'bank_account': bankAccount,
      'ifsc_code': ifscCode,
      'total_purchases': totalPurchases,
      'outstanding_balance': outstandingBalance,
      'is_active': isActive ? 1 : 0,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      serverId: map['server_id'],
      tenantId: map['tenant_id'],
      supplierCode: map['supplier_code'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      postalCode: map['postal_code'],
      country: map['country'] ?? 'India',
      gstin: map['gstin'],
      panNumber: map['pan_number'],
      bankName: map['bank_name'],
      bankAccount: map['bank_account'],
      ifscCode: map['ifsc_code'],
      totalPurchases: (map['total_purchases'] as num?)?.toDouble() ?? 0,
      outstandingBalance: (map['outstanding_balance'] as num?)?.toDouble() ?? 0,
      isActive: map['is_active'] == 1,
      syncStatus: map['sync_status'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class Purchase {
  final int? id;
  final String? serverId;
  final String tenantId;
  final String purchaseNumber;
  final int? supplierId;
  final String? supplierName;
  final String? supplierPhone;
  final String? supplierInvoiceNumber;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String paymentMethod;
  final String? paymentReference;
  final String? notes;
  final String status;
  final String paymentStatus;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PurchaseItem>? items;

  Purchase({
    this.id,
    this.serverId,
    required this.tenantId,
    required this.purchaseNumber,
    this.supplierId,
    this.supplierName,
    this.supplierPhone,
    this.supplierInvoiceNumber,
    required this.subtotal,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    this.paidAmount = 0,
    this.dueAmount = 0,
    required this.paymentMethod,
    this.paymentReference,
    this.notes,
    this.status = 'completed',
    this.paymentStatus = 'paid',
    this.syncStatus = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.items,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'tenant_id': tenantId,
      'purchase_number': purchaseNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'supplier_phone': supplierPhone,
      'supplier_invoice_number': supplierInvoiceNumber,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'notes': notes,
      'status': status,
      'payment_status': paymentStatus,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      serverId: map['server_id'],
      tenantId: map['tenant_id'],
      purchaseNumber: map['purchase_number'],
      supplierId: map['supplier_id'],
      supplierName: map['supplier_name'],
      supplierPhone: map['supplier_phone'],
      supplierInvoiceNumber: map['supplier_invoice_number'],
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      dueAmount: (map['due_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'],
      paymentReference: map['payment_reference'],
      notes: map['notes'],
      status: map['status'] ?? 'completed',
      paymentStatus: map['payment_status'] ?? 'paid',
      syncStatus: map['sync_status'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class PurchaseItem {
  final int? id;
  final String? serverId;
  final int purchaseId;
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
  final DateTime createdAt;

  PurchaseItem({
    this.id,
    this.serverId,
    required this.purchaseId,
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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'purchase_id': purchaseId,
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'],
      serverId: map['server_id'],
      purchaseId: map['purchase_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      sku: map['sku'],
      barcode: map['barcode'],
      quantity: map['quantity'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      syncStatus: map['sync_status'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class PaymentMethod {
  final int? id;
  final String? serverId;
  final String tenantId;
  final String name;
  final String? icon;
  final bool isActive;
  final bool requiresReference;
  final int syncStatus;
  final DateTime createdAt;

  PaymentMethod({
    this.id,
    this.serverId,
    required this.tenantId,
    required this.name,
    this.icon,
    this.isActive = true,
    this.requiresReference = false,
    this.syncStatus = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'tenant_id': tenantId,
      'name': name,
      'icon': icon,
      'is_active': isActive ? 1 : 0,
      'requires_reference': requiresReference ? 1 : 0,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'],
      serverId: map['server_id'],
      tenantId: map['tenant_id'],
      name: map['name'],
      icon: map['icon'],
      isActive: map['is_active'] == 1,
      requiresReference: map['requires_reference'] == 1,
      syncStatus: map['sync_status'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
