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
  final String unit;
  final double price;
  final double cost;
  final double taxRate;
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
    this.unit = 'piece',
    required this.price,
    this.cost = 0,
    this.taxRate = 0,
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
      'unit': unit,
      'price': price,
      'cost': cost,
      'tax_rate': taxRate,
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
      unit: map['unit'] ?? 'piece',
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
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
    String? unit,
    double? price,
    double? cost,
    double? taxRate,
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
      unit: unit ?? this.unit,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      taxRate: taxRate ?? this.taxRate,
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
