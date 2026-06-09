import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../utils/label_generator.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  String selectedCategory = 'All';
  List<String> categories = ['All'];
  Product? _hoveredProduct;
  bool showLowStockOnly = false;  // Low stock filter
  bool _allowNegativeStockSales = false;

  int _displayStock(Product product) {
    if (_allowNegativeStockSales || product.isService) return product.stockQuantity;
    return product.stockQuantity < 0 ? 0 : product.stockQuantity;
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Get count of low stock products
  int get lowStockCount => products
      .where((p) => !p.isService && _displayStock(p) <= p.lowStockThreshold)
      .length;

  Future<void> _loadProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('products', orderBy: 'name ASC');
      
      setState(() {
        _allowNegativeStockSales =
            prefs.getBool('allow_negative_stock_sales') ?? false;
        products = result.map((map) => Product.fromMap(map)).toList();
        filteredProducts = products;
        
        // Extract unique categories using Set to avoid duplicates
        final categorySet = <String>{'All'};
        for (var product in products) {
          if (product.category != null && product.category!.trim().isNotEmpty) {
            categorySet.add(product.category!.trim());
          }
        }
        categories = categorySet.toList()..sort((a, b) => a == 'All' ? -1 : a.compareTo(b));
        
        // Validate selectedCategory exists
        if (!categories.contains(selectedCategory)) {
          selectedCategory = 'All';
        }
        
        isLoading = false;
      });
      
      // Show low stock alert if there are items below threshold
      _checkLowStockAlert();
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Check and show low stock alert
  void _checkLowStockAlert() {
    final lowStockProducts = products
        .where((p) => !p.isService && _displayStock(p) <= p.lowStockThreshold)
        .toList();
    if (lowStockProducts.isNotEmpty && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠️ ${lowStockProducts.length} product${lowStockProducts.length > 1 ? 's' : ''} below stock threshold!',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    setState(() {
                      showLowStockOnly = true;
                      _filterProducts();
                    });
                  },
                  child: const Text('VIEW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      });
    }
  }

  void _filterProducts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((product) {
        final matchesSearch = product.name.toLowerCase().contains(query) ||
               product.sku.toLowerCase().contains(query) ||
               (product.barcode?.toLowerCase().contains(query) ?? false);
        
        final matchesCategory = selectedCategory == 'All' ||
               product.category == selectedCategory;
        
        final matchesLowStock = !showLowStockOnly ||
               (!product.isService && _displayStock(product) <= product.lowStockThreshold);
        
        return matchesSearch && matchesCategory && matchesLowStock;
      }).toList();
    });
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('products', where: 'id = ?', whereArgs: [product.id]);
        _loadProducts();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  Future<void> _exportCSV() async {
    try {
      List<List<dynamic>> rows = [
        ['Name', 'SKU', 'Type', 'Barcode', 'Category', 'Brand', 'Price', 'Cost', 'Tax Rate', 'Stock', 'Description']
      ];

      for (var product in products) {
        rows.add([
          product.name,
          product.sku,
          product.productType,
          product.barcode ?? '',
          product.category ?? '',
          product.brand ?? '',
          product.price,
          product.cost,
          product.taxRate,
          product.stockQuantity,
          product.description ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/products_export.csv');
      await file.writeAsString(csv);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Products exported to ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting: $e')),
      );
    }
  }

  Future<void> _importCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final csvString = await file.readAsString();
        List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

        if (rows.length <= 1) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV file is empty or invalid')),
          );
          return;
        }

        final db = await DatabaseHelper.instance.database;
        int imported = 0;

        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length >= 10) {
            try {
              await db.insert('products', {
                'tenant_id': 'default',
                'name': row[0].toString(),
                'sku': row[1].toString(),
                'product_type': row[2].toString().toLowerCase() == 'service' ? 'service' : 'product',
                'barcode': row[3].toString(),
                'category': row[4].toString(),
                'brand': row[5].toString(),
                'price': double.tryParse(row[6].toString()) ?? 0.0,
                'cost': double.tryParse(row[7].toString()) ?? 0.0,
                'tax_rate': double.tryParse(row[8].toString()) ?? 0.0,
                'stock_quantity': int.tryParse(row[9].toString()) ?? 0,
                'description': row.length > 10 ? row[10].toString() : '',
                'unit': 'piece',
                'is_active': 1,
                'sync_status': 0,
              });
              imported++;
            } catch (e) {
              debugPrint('Error importing row $i: $e');
            }
          }
        }

        _loadProducts();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $imported products successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildTopToolbar(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTableHeader(),
                  const Divider(height: 1),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredProducts.isEmpty
                            ? _buildEmptyState()
                            : _buildProductTable(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button + Title
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back to Dashboard',
          ),
          const SizedBox(width: 8),
          const Text(
            'Product / Service Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 24),
          
          // Search bar (center)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, SKU, barcode...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Low Stock Alert Badge/Button
          if (lowStockCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: showLowStockOnly ? 'Show all products' : 'Show low stock items only',
                child: InkWell(
                  onTap: () {
                    setState(() {
                      showLowStockOnly = !showLowStockOnly;
                      _filterProducts();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: showLowStockOnly ? const Color(0xFFEF4444) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: showLowStockOnly ? const Color(0xFFEF4444) : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: showLowStockOnly ? Colors.white : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Low Stock: $lowStockCount',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: showLowStockOnly ? Colors.white : const Color(0xFFDC2626),
                          ),
                        ),
                        if (showLowStockOnly) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Category filter + Actions (right)
          Container(
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF8FAFC),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF64748B)),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                items: categories.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                    _filterProducts();
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Export/Import buttons
          IconButton(
            icon: const Icon(Icons.file_download_outlined, size: 20),
            onPressed: _exportCSV,
            tooltip: 'Export CSV',
            color: const Color(0xFF64748B),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, size: 20),
            onPressed: _importCSV,
            tooltip: 'Import CSV',
            color: const Color(0xFF64748B),
          ),
          
          const SizedBox(width: 12),
          
          // Print Labels button
          ElevatedButton.icon(
            onPressed: _showPrintLabelsDialog,
            icon: const Icon(Icons.label_outline, size: 18),
            label: const Text('Print Labels'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Add Product button
          ElevatedButton.icon(
            onPressed: () => _showProductDialog(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            flex: 3,
            child: Text(
              'NAME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'SKU',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'CATEGORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'PRICE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'STOCK / SOLD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'TAX',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            width: 130,
            child: Text(
              'ACTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTable() {
    return ListView.builder(
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final isHovered = _hoveredProduct?.id == product.id;
        
        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredProduct = product),
          onExit: (_) => setState(() => _hoveredProduct = null),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isHovered ? const Color(0xFFF8FAFC) : Colors.white,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    product.sku,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: product.category != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.category!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : const Text(
                          'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Tooltip(
                    message: product.isService
                        ? 'Total sold services: ${_displayStock(product)}'
                        : _displayStock(product) <= product.lowStockThreshold
                        ? 'Low stock! Threshold: ${product.lowStockThreshold}'
                        : 'Stock OK (Threshold: ${product.lowStockThreshold})',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.isService
                            ? const Color(0xFFEDE9FE)
                            : _displayStock(product) <= product.lowStockThreshold
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!product.isService && _displayStock(product) <= product.lowStockThreshold)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFDC2626)),
                            ),
                          Text(
                            product.isService
                                ? 'S:${_displayStock(product)}'
                                : _displayStock(product).toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: product.isService
                                  ? const Color(0xFF6D28D9)
                                  : _displayStock(product) <= product.lowStockThreshold
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${(product.taxRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.label_outline, size: 18),
                        onPressed: () => _showSingleProductLabelDialog(product),
                        tooltip: 'Print Label',
                        color: const Color(0xFF8B5CF6),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showProductDialog(product),
                        tooltip: 'Edit',
                        color: const Color(0xFF3B82F6),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _deleteProduct(product),
                        tooltip: 'Delete',
                        color: const Color(0xFFEF4444),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No items yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get started by adding your first product or service',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showProductDialog(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Your First Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(Product? product) {
    final isEdit = product != null;
    
    // Controllers
    final nameController = TextEditingController(text: product?.name ?? '');
    final skuController = TextEditingController(text: product?.sku ?? '');
    final barcodeController = TextEditingController(text: product?.barcode ?? '');
    final categoryController = TextEditingController(text: product?.category ?? '');
    final brandController = TextEditingController(text: product?.brand ?? '');
    final hsnSacController = TextEditingController(text: product?.hsnSac ?? '');
    final modelVariantController = TextEditingController(text: product?.modelVariant ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final costController = TextEditingController(text: product?.cost.toString() ?? '');
    final taxController = TextEditingController(
      text: product != null ? product.taxRate.toString() : '18'
    );
    final stockController = TextEditingController(text: product?.stockQuantity.toString() ?? '0');
    String productType = product?.productType ?? 'product';
    
    final formKey = GlobalKey<FormState>();
    
    // Auto-focus first field
    final nameFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameFocusNode.requestFocus();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 680,
          constraints: const BoxConstraints(maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isEdit ? 'Edit Item' : 'Add New Item',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
              
              // Scrollable Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION 1: Basic Info
                        _buildSectionHeader('Basic Information', Icons.info_outline),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: nameController,
                          focusNode: nameFocusNode,
                          decoration: _inputDecoration(
                            label: 'Name',
                            hint: 'Enter product or service name',
                            isRequired: true,
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: skuController,
                                decoration: _inputDecoration(
                                  label: 'SKU',
                                  hint: 'Stock Keeping Unit',
                                  isRequired: true,
                                ),
                                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: barcodeController,
                                decoration: _inputDecoration(
                                  label: 'Barcode',
                                  hint: 'Optional',
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // SECTION 2: Classification
                        _buildSectionHeader('Classification', Icons.category_outlined),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: categoryController,
                                decoration: _inputDecoration(
                                  label: 'Category',
                                  hint: 'e.g., Electronics',
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: brandController,
                                decoration: _inputDecoration(
                                  label: 'Brand',
                                  hint: 'Optional',
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: hsnSacController,
                                decoration: _inputDecoration(
                                  label: 'HSN/SAC Code',
                                  hint: 'e.g., 8471',
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: modelVariantController,
                                decoration: _inputDecoration(
                                  label: 'Model/Variant',
                                  hint: 'e.g., Pro Max 256GB',
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // SECTION 3: Pricing
                        _buildSectionHeader('Pricing', Icons.payments_outlined),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: priceController,
                                decoration: _inputDecoration(
                                  label: 'Selling Price',
                                  hint: '0.00',
                                  prefix: '₹',
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: costController,
                                decoration: _inputDecoration(
                                  label: 'Cost Price',
                                  hint: '0.00',
                                  prefix: '₹',
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // SECTION 4: Tax & Stock
                        _buildSectionHeader('Tax & Stock', Icons.inventory_outlined),
                        const SizedBox(height: 16),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: taxController,
                                    decoration: _inputDecoration(
                                      label: 'Tax Rate',
                                      hint: '18',
                                      suffix: '%',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      _buildTaxPresetChip('0', taxController),
                                      _buildTaxPresetChip('5', taxController),
                                      _buildTaxPresetChip('12', taxController),
                                      _buildTaxPresetChip('18', taxController),
                                      _buildTaxPresetChip('28', taxController),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: productType,
                                decoration: _inputDecoration(
                                  label: 'Type',
                                  hint: 'Select type',
                                  isRequired: true,
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'product', child: Text('Product')),
                                  DropdownMenuItem(value: 'service', child: Text('Service')),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  productType = value;
                                  if (productType == 'service') {
                                    stockController.text = '0';
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: stockController,
                                decoration: _inputDecoration(
                                  label: productType == 'service' ? 'Sold Count' : 'Stock Quantity',
                                  hint: '0',
                                  isRequired: productType == 'product',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (productType == 'product' && (v?.isEmpty ?? true)) return 'Required';
                                  if (int.tryParse(v!) == null) return 'Invalid number';
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // SECTION 5: Description
                        _buildSectionHeader('Additional Details', Icons.description_outlined),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: descriptionController,
                          decoration: _inputDecoration(
                            label: 'Description',
                            hint: 'Product description (optional)',
                          ),
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _saveProduct(
                            context,
                            formKey,
                            isEdit,
                            product,
                            nameController,
                            skuController,
                            barcodeController,
                            categoryController,
                            brandController,
                            hsnSacController,
                            modelVariantController,
                            descriptionController,
                            priceController,
                            costController,
                            taxController,
                            stockController,
                            productType,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _saveProduct(
                        context,
                        formKey,
                        isEdit,
                        product,
                        nameController,
                        skuController,
                        barcodeController,
                        categoryController,
                        brandController,
                        hsnSacController,
                        modelVariantController,
                        descriptionController,
                        priceController,
                        costController,
                        taxController,
                        stockController,
                        productType,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, size: 18),
                          const SizedBox(width: 8),
                          Text(isEdit ? 'Update Item' : 'Save Item'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    String? prefix,
    String? suffix,
    bool isRequired = false,
  }) {
    return InputDecoration(
      labelText: label + (isRequired ? ' *' : ''),
      hintText: hint,
      prefixText: prefix,
      suffixText: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTaxPresetChip(String rate, TextEditingController controller) {
    return InkWell(
      onTap: () => controller.text = rate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          '$rate%',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct(
    BuildContext context,
    GlobalKey<FormState> formKey,
    bool isEdit,
    Product? product,
    TextEditingController nameController,
    TextEditingController skuController,
    TextEditingController barcodeController,
    TextEditingController categoryController,
    TextEditingController brandController,
    TextEditingController hsnSacController,
    TextEditingController modelVariantController,
    TextEditingController descriptionController,
    TextEditingController priceController,
    TextEditingController costController,
    TextEditingController taxController,
    TextEditingController stockController,
    String productType,
  ) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final parsedStock = int.tryParse(stockController.text) ?? 0;
      final data = {
        'tenant_id': 'default',
        'name': nameController.text,
        'sku': skuController.text,
        'barcode': barcodeController.text.isEmpty ? null : barcodeController.text,
        'category': categoryController.text.isEmpty ? null : categoryController.text,
        'brand': brandController.text.isEmpty ? null : brandController.text,
        'hsn_sac': hsnSacController.text.isEmpty ? null : hsnSacController.text,
        'model_variant': modelVariantController.text.isEmpty ? null : modelVariantController.text,
        'description': descriptionController.text.isEmpty ? null : descriptionController.text,
        'price': double.tryParse(priceController.text) ?? 0.0,
        'cost': double.tryParse(costController.text) ?? 0.0,
        'tax_rate': double.tryParse(taxController.text) ?? 0.0,
        'product_type': productType,
        'stock_quantity': productType == 'service' ? parsedStock.clamp(0, 2147483647) : parsedStock,
        'unit': 'piece',
        'is_active': 1,
        'sync_status': 0,
      };

      if (isEdit) {
        await db.update('products', data, where: 'id = ?', whereArgs: [product!.id]);
      } else {
        await db.insert('products', data);
      }

      if (!context.mounted) return;
      Navigator.pop(context);
      _loadProducts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('Item ${isEdit ? "updated" : "added"} successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // ============ LABEL PRINTING METHODS ============

  /// Show dialog to print label for a single product
  void _showSingleProductLabelDialog(Product product) {
    int labelQuantity = 1;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.label_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Print Product Label',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabelInfoRow('SKU', product.sku),
                      if (product.barcode != null && product.barcode!.isNotEmpty)
                        _buildLabelInfoRow('Barcode', product.barcode!),
                      _buildLabelInfoRow('Price', '₹${product.price.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Quantity selector
                const Text(
                  'Number of Labels',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (labelQuantity > 1) {
                          setDialogState(() => labelQuantity--);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      color: const Color(0xFF64748B),
                    ),
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$labelQuantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setDialogState(() => labelQuantity++);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 12),
                    // Quick quantity buttons
                    _buildQuickQtyButton(5, () => setDialogState(() => labelQuantity = 5)),
                    const SizedBox(width: 8),
                    _buildQuickQtyButton(10, () => setDialogState(() => labelQuantity = 10)),
                    const SizedBox(width: 8),
                    _buildQuickQtyButton(20, () => setDialogState(() => labelQuantity = 20)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _printProductLabels([product], {product.id!: labelQuantity});
              },
              icon: const Icon(Icons.print, size: 18),
              label: Text('Print $labelQuantity Label${labelQuantity > 1 ? 's' : ''}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQtyButton(int qty, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          '$qty',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  /// Show dialog to print labels for multiple products
  void _showPrintLabelsDialog() {
    if (filteredProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products available to print labels'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final Map<int, int> selectedQuantities = {};
    final Set<int> selectedProductIds = {};
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 700,
            height: 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.label_outline, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Print Product Labels',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Select products and set label quantities',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Select All / Clear All
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          for (var p in filteredProducts) {
                            selectedProductIds.add(p.id!);
                            selectedQuantities[p.id!] = selectedQuantities[p.id!] ?? 1;
                          }
                        });
                      },
                      icon: const Icon(Icons.select_all, size: 18),
                      label: const Text('Select All'),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          selectedProductIds.clear();
                          selectedQuantities.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${selectedProductIds.length} selected • ${selectedQuantities.values.fold(0, (a, b) => a + b)} labels',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Product list
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final isSelected = selectedProductIds.contains(product.id);
                        final qty = selectedQuantities[product.id] ?? 1;
                        
                        return Container(
                          color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
                          child: ListTile(
                            dense: true,
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    selectedProductIds.add(product.id!);
                                    selectedQuantities[product.id!] = 1;
                                  } else {
                                    selectedProductIds.remove(product.id);
                                    selectedQuantities.remove(product.id);
                                  }
                                });
                              },
                              activeColor: const Color(0xFF8B5CF6),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'SKU: ${product.sku} • ₹${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            trailing: isSelected
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 18),
                                        onPressed: qty > 1
                                            ? () => setDialogState(() => selectedQuantities[product.id!] = qty - 1)
                                            : null,
                                        color: const Color(0xFF64748B),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      Container(
                                        width: 40,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$qty',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18),
                                        onPressed: () => setDialogState(() => selectedQuantities[product.id!] = qty + 1),
                                        color: const Color(0xFF8B5CF6),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Footer actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        if (selectedProductIds.isEmpty) return;
                        final selectedProducts = filteredProducts
                            .where((p) => selectedProductIds.contains(p.id))
                            .toList();
                        Navigator.pop(context);
                        await _previewLabels(selectedProducts, selectedQuantities);
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Preview'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: selectedProductIds.isEmpty
                          ? null
                          : () async {
                              final selectedProducts = filteredProducts
                                  .where((p) => selectedProductIds.contains(p.id))
                                  .toList();
                              Navigator.pop(context);
                              await _printProductLabels(selectedProducts, selectedQuantities);
                            },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print Labels'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Preview labels before printing (shows PDF preview with actual barcodes)
  Future<void> _previewLabels(List<Product> products, Map<int, int> quantities) async {
    try {
      // Use preview mode to show PDF preview dialog
      await LabelGenerator.printLabels(
        products: products,
        quantities: quantities,
        context: context,
        showPreview: true,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Preview error: $e')),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  /// Print labels for products (PDF with actual barcode graphics)
  Future<void> _printProductLabels(List<Product> products, Map<int, int> quantities) async {
    try {
      // Use direct print mode (no preview)
      await LabelGenerator.printLabels(
        products: products,
        quantities: quantities,
        context: context,
        showPreview: false,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('${quantities.values.fold(0, (a, b) => a + b)} labels sent to printer'),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Print error: $e')),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
