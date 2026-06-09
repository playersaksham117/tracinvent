/// Unified Products & Inventory Management Screen
/// Complete product lifecycle with stock management, import/export, and analytics
library;

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/product_csv_service.dart';
import '../theme/app_theme.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _api;
  final _searchController = TextEditingController();
  final _csvContent = TextEditingController();
  
  // Products & Inventory data
  List<Item> _products = [];
  List<StockMovement> _movements = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  // CSV Import/Export
  ParsedProductCSV? _parsedData;
  ProductImportResult? _importResult;
  bool _isImporting = false;
  bool _dryRunMode = true;

  // Product detail view
  List<StockMovement> _productMovements = [];
  Map<String, dynamic>? _productAging;
  bool _loadingProductDetails = false;

  // Column visibility toggles
  late Map<String, bool> _columnVisibility;
  
  final Map<String, String> _columnLabels = {
    'name': 'Product Name',
    'sku': 'SKU',
    'barcode': 'Barcode',
    'unit': 'Unit',
    'costPrice': 'Cost Price',
    'sellingPrice': 'Selling Price',
    'mrp': 'MRP',
    'gstRate': 'GST %',
    'currentStock': 'Current Stock',
    'minStockLevel': 'Min Stock',
    'hsnCode': 'HSN Code',
    'description': 'Description',
  };

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _tabController = TabController(length: 5, vsync: this);
    
    // Initialize column visibility
    _columnVisibility = {
      'name': true,
      'sku': true,
      'barcode': false,
      'unit': true,
      'costPrice': true,
      'sellingPrice': true,
      'mrp': false,
      'gstRate': true,
      'currentStock': true,
      'minStockLevel': true,
      'hsnCode': false,
      'description': false,
    };
    
    _loadAllData();
  }

  @override
  void dispose() {
    // Tab controller
    _tabController.dispose();
    // Search and CSV controllers
    _searchController.dispose();
    _csvContent.dispose();
    // Product form controllers
    _productNameController.dispose();
    _productSkuController.dispose();
    _productBarcodeController.dispose();
    _productCostPriceController.dispose();
    _productSellingPriceController.dispose();
    _productMrpController.dispose();
    _productGstRateController.dispose();
    _productHsnCodeController.dispose();
    _productMinStockController.dispose();
    super.dispose();
  }

  void _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final productsData = await _api.getItems();
      final movementsDataJson = await _api.getInventoryMovements(limit: 50);
      final movementsData = movementsDataJson
          .map((json) => StockMovement.fromJson(json))
          .toList();
      
      setState(() {
        _products = productsData;
        _movements = movementsData;
      });
    } catch (e) {
      _showSnackBar('Error loading data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Item> _getFilteredProducts() {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (p.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
        .toList();
  }

  Future<void> _showProductDetails(Item product) async {
    setState(() {
      _loadingProductDetails = true;
    });

    try {
      // Fetch product-specific movements
      final movementsJson = await _api.getInventoryMovements(
        itemId: product.id,
        limit: 20,
      );
      _productMovements = movementsJson.map((json) => StockMovement.fromJson(json)).toList();
      
      // Try to fetch aging data
      try {
        final agingData = await _api.getInventoryAging();
        if (agingData.isNotEmpty) {
          _productAging = agingData.first;
        }
      } catch (_) {
        _productAging = null;
      }

      setState(() => _loadingProductDetails = false);
      
      if (mounted) {
        _showProductDetailDialog(product);
      }
    } catch (e) {
      _showSnackBar('Error loading product details: $e', isError: true);
      setState(() => _loadingProductDetails = false);
    }
  }

  void _showProductDetailDialog(Item product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SizedBox(
          width: 800,
          height: 600,
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Product info tabs
                TabBar(
                  indicatorColor: AppTheme.primaryColor,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Movements'),
                    Tab(text: 'Aging'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Details Tab
                      _buildProductDetailsTab(product),
                      // Movements Tab
                      _buildProductMovementsTab(),
                      // Aging Tab
                      _buildProductAgingTab(product),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsTab(Item product) {
    final isLowStock = product.currentStock < product.minStockLevel;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock status card
          Card(
            color: isLowStock ? Colors.red.shade50 : Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Stock',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        '${product.currentStock.toStringAsFixed(0)} ${product.unitCode ?? 'PCS'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Min Stock Level',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        '${product.minStockLevel.toStringAsFixed(0)} ${product.unitCode ?? 'PCS'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Product details grid
          _buildDetailRow('SKU', product.sku ?? '—'),
          _buildDetailRow('Barcode', product.barcode ?? '—'),
          _buildDetailRow('Unit', product.unitCode ?? 'PCS'),
          _buildDetailRow('Cost Price', '₹${product.costPrice.toStringAsFixed(2)}'),
          _buildDetailRow('Selling Price', '₹${product.sellingPrice.toStringAsFixed(2)}'),
          _buildDetailRow('MRP', '₹${product.mrp.toStringAsFixed(2)}'),
          _buildDetailRow('GST Rate', '${product.gstRate.toStringAsFixed(1)}%'),
          _buildDetailRow('HSN Code', product.hsnCode ?? '—'),
          if (product.description != null) _buildDetailRow('Description', product.description!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildProductMovementsTab() {
    return _loadingProductDetails
        ? const Center(child: CircularProgressIndicator())
        : _productMovements.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'No movements recorded',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _productMovements.length,
                itemBuilder: (context, index) {
                  final movement = _productMovements[index];
                  final isInward = movement.isInward;
                  final color = isInward ? Colors.green : Colors.red;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        isInward ? Icons.arrow_downward : Icons.arrow_upward,
                        color: color,
                      ),
                      title: Text(movement.type.name.toUpperCase()),
                      subtitle: Text(
                        movement.movementDate.toString().split(' ')[0],
                      ),
                      trailing: Text(
                        '${isInward ? '+' : '-'}${movement.quantity.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
  }

  Widget _buildProductAgingTab(Item product) {
    return _loadingProductDetails
        ? const Center(child: CircularProgressIndicator())
        : _productAging == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'No aging data available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Aging Analysis',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildAgingBracket(
                            '0-30 Days',
                            Colors.green,
                            'Fresh stock',
                          ),
                          const SizedBox(height: 12),
                          _buildAgingBracket(
                            '31-90 Days',
                            Colors.orange,
                            'Medium age',
                          ),
                          const SizedBox(height: 12),
                          _buildAgingBracket(
                            '90+ Days',
                            Colors.red,
                            'Old stock - consider promotion',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
  }

  Widget _buildAgingBracket(String label, Color color, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Add Product Dialog
  final _addProductFormKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _productSkuController = TextEditingController();
  final _productBarcodeController = TextEditingController();
  final _productCostPriceController = TextEditingController();
  final _productSellingPriceController = TextEditingController();
  final _productMrpController = TextEditingController();
  final _productGstRateController = TextEditingController(text: '18');
  final _productHsnCodeController = TextEditingController();
  final _productMinStockController = TextEditingController();
  String _selectedUnit = 'PCS';

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: SizedBox(
          width: 600,
          height: 650,
          child: SingleChildScrollView(
            child: Form(
              key: _addProductFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _productNameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.inventory_2),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _productSkuController,
                          decoration: InputDecoration(
                            labelText: 'SKU',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _productBarcodeController,
                          decoration: InputDecoration(
                            labelText: 'Barcode',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const ['PCS', 'KG', 'LTR', 'MTR', 'BOX']
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedUnit = value ?? 'PCS'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _productMinStockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Min Stock Level',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _productCostPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Cost Price *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixText: '₹ ',
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _productSellingPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Selling Price *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixText: '₹ ',
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _productMrpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'MRP *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixText: '₹ ',
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _productGstRateController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'GST Rate %',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _productHsnCodeController,
                    decoration: InputDecoration(
                      labelText: 'HSN Code',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '* Required fields',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAddProductForm();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: _submitAddProduct,
            icon: const Icon(Icons.check),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAddProduct() async {
    if (!_addProductFormKey.currentState!.validate()) return;

    if (_productCostPriceController.text.isEmpty ||
        _productSellingPriceController.text.isEmpty ||
        _productMrpController.text.isEmpty) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    final costPrice = double.tryParse(_productCostPriceController.text) ?? 0;
    final sellingPrice = double.tryParse(_productSellingPriceController.text) ?? 0;
    final mrp = double.tryParse(_productMrpController.text) ?? 0;
    final gstRate = double.tryParse(_productGstRateController.text) ?? 18;
    final minStock = double.tryParse(_productMinStockController.text) ?? 10;

    final newProduct = Item(
      name: _productNameController.text.trim(),
      sku: _productSkuController.text.trim().isEmpty ? null : _productSkuController.text.trim(),
      barcode: _productBarcodeController.text.trim().isEmpty ? null : _productBarcodeController.text.trim(),
      unitCode: _selectedUnit,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      mrp: mrp,
      gstRate: gstRate,
      hsnCode: _productHsnCodeController.text.trim().isEmpty ? null : _productHsnCodeController.text.trim(),
      minStockLevel: minStock,
      currentStock: 0,
      isActive: true,
    );

    try {
      await _api.createItem(newProduct);
      if (mounted) {
        _showSnackBar('Product added successfully!', isError: false);
        Navigator.pop(context);
        _clearAddProductForm();
        _loadAllData();
      }
    } catch (e) {
      _showSnackBar('Error adding product: $e', isError: true);
    }
  }

  void _clearAddProductForm() {
    _productNameController.clear();
    _productSkuController.clear();
    _productBarcodeController.clear();
    _productCostPriceController.clear();
    _productSellingPriceController.clear();
    _productMrpController.clear();
    _productGstRateController.text = '18';
    _productHsnCodeController.clear();
    _productMinStockController.clear();
    _selectedUnit = 'PCS';
  }

  void _handleCSVParse() {
    final content = _csvContent.text.trim();
    if (content.isEmpty) {
      _showSnackBar('Please paste CSV content', isError: true);
      return;
    }
    setState(() => _parsedData = ProductCSVService.parseProductCSV(content));
  }

  Future<void> _handleImport() async {
    if (_parsedData?.rows.isEmpty ?? true) {
      _showSnackBar('No valid rows to import', isError: true);
      return;
    }

    setState(() => _isImporting = true);
    try {
      final result = await ProductCSVService.importProductsFromCSV(
        _parsedData!.rows,
        dryRun: _dryRunMode,
      );
      setState(() => _importResult = result);
      _showSnackBar(result.message, isError: !result.success);
      
      if (result.success && !_dryRunMode) {
        _loadAllData();
        _csvContent.clear();
        setState(() => _parsedData = null);
      }
    } catch (e) {
      _showSnackBar('Import failed: $e', isError: true);
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _handleExport() async {
    try {
      final csvContent = await ProductCSVService.exportProductsFromDatabase();
      _showExportDialog(csvContent);
    } catch (e) {
      _showSnackBar('Export failed: $e', isError: true);
    }
  }

  void _showExportDialog(String csvContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Products Exported Successfully'),
        content: SizedBox(
          width: 700,
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Products: ${csvContent.split('\n').length - 2}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          'Ready to download',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      csvContent,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('CSV copied to clipboard');
            },
            icon: const Icon(Icons.file_download),
            label: const Text('Copy & Download'),
          ),
        ],
      ),
    );
  }

  void _showColumnVisibilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Column Visibility'),
        content: SizedBox(
          width: 350,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _columnVisibility.entries
                  .map((entry) => CheckboxListTile(
                        title: Text(_columnLabels[entry.key] ?? entry.key),
                        value: entry.value,
                        onChanged: (value) {
                          setState(() =>
                              _columnVisibility[entry.key] = value ?? false);
                          Navigator.pop(context);
                          _showColumnVisibilityDialog();
                        },
                      ))
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: AppBar(
        title: const Text('Products & Inventory'),
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Products'),
            Tab(icon: Icon(Icons.trending_down), text: 'Low Stock'),
            Tab(icon: Icon(Icons.history), text: 'Movements'),
            Tab(icon: Icon(Icons.upload), text: 'Import'),
            Tab(icon: Icon(Icons.download), text: 'Export'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildLowStockTab(),
          _buildMovementsTab(),
          _buildImportTab(),
          _buildExportTab(),
        ],
      ),
    );
  }

  // ========== PRODUCTS TAB ==========
  Widget _buildProductsTab() {
    final filteredProducts = _getFilteredProducts();

    return Column(
      children: [
        // Search bar & controls
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search products by name, SKU, or barcode...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showColumnVisibilityDialog,
                    icon: const Icon(Icons.view_column),
                    label: const Text('Columns'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _loadAllData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddProductDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${_products.length} | Showing: ${filteredProducts.length}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Chip(
                    label: Text(
                      'Low Stock: ${_products.where((p) => p.currentStock < p.minStockLevel).length}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    backgroundColor: Colors.red.shade50,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Products table
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            _products.isEmpty
                                ? 'No products found'
                                : 'No products match search',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: DataTable(
                          columnSpacing: 12,
                          horizontalMargin: 16,
                          columns: _buildDataColumns(),
                          rows: _buildDataRows(filteredProducts),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  // ========== LOW STOCK TAB ==========
  Widget _buildLowStockTab() {
    final lowStockProducts = _products
        .where((p) => p.currentStock < p.minStockLevel)
        .toList()
      ..sort((a, b) =>
          (a.currentStock / a.minStockLevel)
              .compareTo(b.currentStock / b.minStockLevel));

    return lowStockProducts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.green[300]),
                const SizedBox(height: 16),
                Text(
                  'No low stock items',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lowStockProducts.length,
            itemBuilder: (context, index) {
              final product = lowStockProducts[index];
              final stockPercent =
                  product.currentStock / product.minStockLevel * 100;
              final color = stockPercent < 25
                  ? Colors.red
                  : stockPercent < 50
                      ? Colors.orange
                      : Colors.yellow;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'SKU: ${product.sku ?? "N/A"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              border: Border.all(color: color),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${stockPercent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stockPercent / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stock: ${product.currentStock.toStringAsFixed(0)} / Min: ${product.minStockLevel.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            '₹${product.sellingPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  // ========== MOVEMENTS TAB ==========
  Widget _buildMovementsTab() {
    return _movements.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No stock movements recorded',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _movements.length,
            itemBuilder: (context, index) {
              final movement = _movements[index];
              final isInward = movement.isInward;
              final color = isInward ? Colors.green : Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isInward ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                    ),
                  ),
                  title: Text(movement.itemName),
                  subtitle: Text(
                    '${movement.type.name.toUpperCase()} • ${movement.movementDate.toString().split(' ')[0]}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    '${isInward ? '+' : '-'}${movement.quantity.toStringAsFixed(0)} units',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              );
            },
          );
  }

  // ========== IMPORT TAB ==========
  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            icon: Icons.upload_file,
            title: 'Import Products from CSV',
            description:
                'Paste CSV data to bulk import products into inventory',
          ),
          const SizedBox(height: 24),
          Text('Paste CSV Data',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _csvContent,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: 'Paste CSV content here (with headers)...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _handleCSVParse,
            icon: const Icon(Icons.upload),
            label: const Text('Parse CSV'),
          ),
          const SizedBox(height: 24),
          if (_parsedData != null) ...[
            _buildParsedDataPreview(),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _dryRunMode,
                  onChanged: (v) => setState(() => _dryRunMode = v ?? true),
                ),
                const Expanded(
                  child: Text('Dry Run Mode (Preview without saving)'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _handleImport,
                icon: _isImporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_dryRunMode ? 'Preview Import' : 'Import Products'),
              ),
            ),
            if (_importResult != null) ...[
              const SizedBox(height: 16),
              _buildImportResultCard(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildParsedDataPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Parsed Data',
                    style: Theme.of(context).textTheme.titleMedium),
                Chip(
                  label: Text('${_parsedData!.rows.length} rows'),
                  backgroundColor: Colors.blue.shade50,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_parsedData!.errors.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text('${_parsedData!.errors.length} errors found',
                            style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._parsedData!.errors
                        .take(3)
                        .map((e) => Text('• $e', style: const TextStyle(fontSize: 12)))
                        .toList(),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text('All rows validated successfully',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportResultCard() {
    return Card(
      color: _importResult!.success ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _importResult!.success ? Icons.check_circle : Icons.error,
                  color: _importResult!.success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _importResult!.message,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _importResult!.success
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatChip('Imported', _importResult!.importedCount.toString(), Colors.green),
                const SizedBox(width: 8),
                _buildStatChip('Skipped', _importResult!.skippedCount.toString(), Colors.orange),
                const SizedBox(width: 8),
                _buildStatChip('Failed', _importResult!.failedCount.toString(), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  // ========== EXPORT TAB ==========
  Widget _buildExportTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_download,
                      size: 64, color: AppTheme.primaryColor),
                  const SizedBox(height: 24),
                  Text('Export All Products',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Download all products with current stock levels',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _handleExport,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Products as CSV'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Export includes all product details, pricing, GST rates, and current stock levels for backup or transfer.',
                            style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataColumn> _buildDataColumns() {
    final columns = <DataColumn>[];
    
    if (_columnVisibility['name']!)
      columns.add(DataColumn(label: _buildColumnHeader('Product Name')));
    if (_columnVisibility['sku']!)
      columns.add(DataColumn(label: _buildColumnHeader('SKU')));
    if (_columnVisibility['barcode']!)
      columns.add(DataColumn(label: _buildColumnHeader('Barcode')));
    if (_columnVisibility['unit']!)
      columns.add(DataColumn(label: _buildColumnHeader('Unit')));
    if (_columnVisibility['costPrice']!)
      columns.add(DataColumn(label: _buildColumnHeader('Cost Price')));
    if (_columnVisibility['sellingPrice']!)
      columns.add(DataColumn(label: _buildColumnHeader('Selling Price')));
    if (_columnVisibility['mrp']!)
      columns.add(DataColumn(label: _buildColumnHeader('MRP')));
    if (_columnVisibility['gstRate']!)
      columns.add(DataColumn(label: _buildColumnHeader('GST %')));
    if (_columnVisibility['currentStock']!)
      columns.add(DataColumn(label: _buildColumnHeader('Stock')));
    if (_columnVisibility['minStockLevel']!)
      columns.add(DataColumn(label: _buildColumnHeader('Min Stock')));
    if (_columnVisibility['hsnCode']!)
      columns.add(DataColumn(label: _buildColumnHeader('HSN')));
    if (_columnVisibility['description']!)
      columns.add(DataColumn(label: _buildColumnHeader('Description')));
    
    return columns;
  }

  List<DataRow> _buildDataRows(List<Item> products) {
    return products.asMap().entries.map((entry) {
      final product = entry.value;
      final index = entry.key;
      final cells = <DataCell>[];
      final isLowStock = product.currentStock < product.minStockLevel;

      if (_columnVisibility['name']!)
        cells.add(DataCell(Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isLowStock ? Colors.red : Colors.black,
          ),
        )));
      if (_columnVisibility['sku']!) {
        cells.add(DataCell(Text(product.sku ?? '—', maxLines: 1)));
      }
      if (_columnVisibility['barcode']!) {
        cells.add(DataCell(Text(product.barcode ?? '—', maxLines: 1)));
      }
      if (_columnVisibility['unit']!) {
        cells.add(DataCell(Text(product.unitCode ?? 'PCS')));
      }
      if (_columnVisibility['costPrice']!) {
        cells.add(DataCell(Text('₹${product.costPrice.toStringAsFixed(2)}')));
      }
      if (_columnVisibility['sellingPrice']!) {
        cells.add(DataCell(Text('₹${product.sellingPrice.toStringAsFixed(2)}')));
      }
      if (_columnVisibility['mrp']!) {
        cells.add(DataCell(Text('₹${product.mrp.toStringAsFixed(2)}')));
      }
      if (_columnVisibility['gstRate']!) {
        cells.add(DataCell(Text('${product.gstRate.toStringAsFixed(1)}%')));
      }
      if (_columnVisibility['currentStock']!) {
        cells.add(DataCell(Text(
          product.currentStock.toStringAsFixed(0),
          style: TextStyle(
            color: isLowStock ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        )));
      }
      if (_columnVisibility['minStockLevel']!) {
        cells.add(DataCell(Text(product.minStockLevel.toStringAsFixed(0))));
      }
      if (_columnVisibility['hsnCode']!) {
        cells.add(DataCell(Text(product.hsnCode ?? '—')));
      }
      if (_columnVisibility['description']!) {
        cells.add(DataCell(Text(
          product.description ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )));
      }

      return DataRow(
        onSelectChanged: (selected) {
          if (selected == true) {
            _showProductDetails(product);
          }
        },
        color: WidgetStatePropertyAll(
          index.isEven ? Colors.grey.shade50 : Colors.white,
        ),
        cells: cells,
      );
    }).toList();
  }

  Widget _buildColumnHeader(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
