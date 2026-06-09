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
  final String createdAt;
  final String updatedAt;

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
    required this.createdAt,
    required this.updatedAt,
  });

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
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      serverId: map['server_id'] as String?,
      tenantId: map['tenant_id'] as String,
      name: map['name'] as String,
      sku: map['sku'] as String,
      barcode: map['barcode'] as String?,
      description: map['description'] as String?,
      category: map['category'] as String?,
      brand: map['brand'] as String?,
      hsnSac: map['hsn_sac'] as String?,
      modelVariant: map['model_variant'] as String?,
      unit: map['unit'] as String? ?? 'piece',
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
      productType: map['product_type'] as String? ?? 'product',
      stockQuantity: map['stock_quantity'] as int? ?? 0,
      lowStockThreshold: map['low_stock_threshold'] as int? ?? 10,
      imageUrl: map['image_url'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      syncStatus: map['sync_status'] as int? ?? 0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  bool get isService => productType.toLowerCase() == 'service';
}
