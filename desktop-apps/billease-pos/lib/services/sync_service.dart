import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _connectivity = Connectivity();
  
  StreamSubscription? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService._init();

  // Initialize sync service
  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && !_isSyncing) {
        syncAll();
      }
    });

    // Periodic sync every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      syncAll();
    });
  }

  // Check if device is online
  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Sync all pending data
  Future<Map<String, dynamic>> syncAll() async {
    if (_isSyncing) {
      return {'status': 'already_syncing'};
    }

    if (!await isOnline()) {
      return {'status': 'offline', 'message': 'No internet connection'};
    }

    _isSyncing = true;

    try {
      final results = {
        'products': await _syncProducts(),
        'customers': await _syncCustomers(),
        'sales': await _syncSales(),
        'stock_adjustments': await _syncStockAdjustments(),
      };

      return {
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
        'results': results,
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    } finally {
      _isSyncing = false;
    }
  }

  // Sync products to Supabase
  Future<Map<String, int>> _syncProducts() async {
    final supabase = Supabase.instance.client;
    final localProducts = await _db.query(
      'products',
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    int synced = 0;
    int failed = 0;

    for (var productMap in localProducts) {
      try {
        final product = Product.fromMap(productMap);
        
        // Prepare data for Supabase
        final data = {
          'tenant_id': product.tenantId,
          'name': product.name,
          'sku': product.sku,
          'barcode': product.barcode,
          'description': product.description,
          'category': product.category,
          'brand': product.brand,
          'unit': product.unit,
          'price': product.price,
          'cost': product.cost,
          'tax_rate': product.taxRate,
          'stock_quantity': product.stockQuantity,
          'low_stock_threshold': product.lowStockThreshold,
          'image_url': product.imageUrl,
          'is_active': product.isActive,
        };

        // Insert or update on Supabase
        final response = await supabase
            .from('products')
            .upsert(data, onConflict: 'sku')
            .select()
            .single();

        // Update local record with server ID and sync status
        await _db.update(
          'products',
          {
            'server_id': response['id'].toString(),
            'sync_status': 1,
          },
          where: 'id = ?',
          whereArgs: [product.id],
        );

        synced++;
      } catch (e) {
        debugPrint('Error syncing product: $e');
        failed++;
      }
    }

    return {'synced': synced, 'failed': failed};
  }

  // Sync customers to Supabase
  Future<Map<String, int>> _syncCustomers() async {
    final supabase = Supabase.instance.client;
    final localCustomers = await _db.query(
      'customers',
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    int synced = 0;
    int failed = 0;

    for (var customerMap in localCustomers) {
      try {
        final customer = Customer.fromMap(customerMap);
        
        final data = {
          'tenant_id': customer.tenantId,
          'customer_code': customer.customerCode,
          'name': customer.name,
          'email': customer.email,
          'phone': customer.phone,
          'address': customer.address,
          'city': customer.city,
          'state': customer.state,
          'postal_code': customer.postalCode,
          'country': customer.country,
          'customer_group': customer.customerGroup,
          'loyalty_points': customer.loyaltyPoints,
          'total_purchases': customer.totalPurchases,
          'total_orders': customer.totalOrders,
        };

        final response = await supabase
            .from('customers')
            .upsert(data, onConflict: 'customer_code')
            .select()
            .single();

        await _db.update(
          'customers',
          {
            'server_id': response['id'].toString(),
            'sync_status': 1,
          },
          where: 'id = ?',
          whereArgs: [customer.id],
        );

        synced++;
      } catch (e) {
        debugPrint('Error syncing customer: $e');
        failed++;
      }
    }

    return {'synced': synced, 'failed': failed};
  }

  // Sync sales to Supabase
  Future<Map<String, int>> _syncSales() async {
    final supabase = Supabase.instance.client;
    final localSales = await _db.query(
      'sales',
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    int synced = 0;
    int failed = 0;

    for (var saleMap in localSales) {
      try {
        final sale = Sale.fromMap(saleMap);
        
        // Get sale items
        final itemMaps = await _db.query(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [sale.id],
        );

        final items = itemMaps.map((item) => {
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'discount_amount': item['discount_amount'],
          'tax_rate': item['tax_rate'],
          'tax_amount': item['tax_amount'],
          'total_amount': item['total_amount'],
        }).toList();

        final data = {
          'tenant_id': sale.tenantId,
          'sale_number': sale.saleNumber,
          'customer_id': sale.customerId,
          'subtotal': sale.subtotal,
          'tax_amount': sale.taxAmount,
          'discount_amount': sale.discountAmount,
          'total_amount': sale.totalAmount,
          'paid_amount': sale.paidAmount,
          'change_amount': sale.changeAmount,
          'payment_method': sale.paymentMethod,
          'payment_reference': sale.paymentReference,
          'notes': sale.notes,
          'status': sale.status,
          'items': items,
        };

        // Use RPC function to create sale with items
        await supabase.rpc('create_sale_with_items', params: {'sale_data': data});

        await _db.update(
          'sales',
          {'sync_status': 1},
          where: 'id = ?',
          whereArgs: [sale.id],
        );

        // Update sale items sync status
        await _db.update(
          'sale_items',
          {'sync_status': 1},
          where: 'sale_id = ?',
          whereArgs: [sale.id],
        );

        synced++;
      } catch (e) {
        debugPrint('Error syncing sale: $e');
        failed++;
      }
    }

    return {'synced': synced, 'failed': failed};
  }

  // Sync stock adjustments
  Future<Map<String, int>> _syncStockAdjustments() async {
    final supabase = Supabase.instance.client;
    final localAdjustments = await _db.query(
      'stock_adjustments',
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    int synced = 0;
    int failed = 0;

    for (var adjustment in localAdjustments) {
      try {
        final data = {
          'tenant_id': adjustment['tenant_id'],
          'product_id': adjustment['product_id'],
          'adjustment_type': adjustment['adjustment_type'],
          'quantity_change': adjustment['quantity_change'],
          'reason': adjustment['reason'],
          'performed_by': adjustment['performed_by'],
        };

        await supabase.from('stock_adjustments').insert(data);

        await _db.update(
          'stock_adjustments',
          {'sync_status': 1},
          where: 'id = ?',
          whereArgs: [adjustment['id']],
        );

        synced++;
      } catch (e) {
        debugPrint('Error syncing stock adjustment: $e');
        failed++;
      }
    }

    return {'synced': synced, 'failed': failed};
  }

  // Pull data from Supabase to local database
  Future<void> pullFromServer(String tenantId) async {
    if (!await isOnline()) return;

    final supabase = Supabase.instance.client;

    try {
      // Pull products
      final products = await supabase
          .from('products')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_active', true);

      for (var product in products) {
        await _db.insert('products', {
          'server_id': product['id'].toString(),
          'tenant_id': product['tenant_id'],
          'name': product['name'],
          'sku': product['sku'],
          'barcode': product['barcode'],
          'description': product['description'],
          'category': product['category'],
          'brand': product['brand'],
          'unit': product['unit'],
          'price': product['price'],
          'cost': product['cost'],
          'tax_rate': product['tax_rate'],
          'stock_quantity': product['stock_quantity'],
          'low_stock_threshold': product['low_stock_threshold'],
          'image_url': product['image_url'],
          'is_active': 1,
          'sync_status': 1,
        });
      }

      // Pull customers
      final customers = await supabase
          .from('customers')
          .select()
          .eq('tenant_id', tenantId);

      for (var customer in customers) {
        await _db.insert('customers', {
          'server_id': customer['id'].toString(),
          'tenant_id': customer['tenant_id'],
          'customer_code': customer['customer_code'],
          'name': customer['name'],
          'email': customer['email'],
          'phone': customer['phone'],
          'address': customer['address'],
          'city': customer['city'],
          'state': customer['state'],
          'postal_code': customer['postal_code'],
          'country': customer['country'],
          'customer_group': customer['customer_group'],
          'loyalty_points': customer['loyalty_points'],
          'total_purchases': customer['total_purchases'],
          'total_orders': customer['total_orders'],
          'sync_status': 1,
        });
      }

      debugPrint('Successfully pulled data from server');
    } catch (e) {
      debugPrint('Error pulling from server: $e');
    }
  }

  // Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    final pendingProducts = await _db.query(
      'products',
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    final pendingCustomers = await _db.query(
      'customers',
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    final pendingSales = await _db.query(
      'sales',
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    return {
      'pending_products': pendingProducts.length,
      'pending_customers': pendingCustomers.length,
      'pending_sales': pendingSales.length,
      'total_pending': pendingProducts.length + pendingCustomers.length + pendingSales.length,
    };
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}
