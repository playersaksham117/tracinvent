import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/inventory_provider.dart';
import '../providers/settings_provider.dart';
import '../models/inventory_item.dart';
import '../widgets/barcode_print_dialog.dart';
import '../services/stock_operations_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, _) {
        final categories = ['All', ...inventoryProvider.items.map((i) => i.category).toSet()];
        
        var filteredItems = inventoryProvider.items.where((item) {
          final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.sku.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        return Column(
          children: [
            // Header with title and add button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Inventory Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showAddItemDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value!),
                    ),
                  ),
                ],
              ),
            ),

              // Items List
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_outlined, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No items found',
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showAddItemDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final totalStock = inventoryProvider.getTotalStock(item.id);
                          final isLowStock = totalStock <= item.reorderLevel;
                          final isCritical = totalStock <= item.minStockLevel;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: isCritical
                                      ? Colors.red.shade50
                                      : isLowStock
                                          ? Colors.orange.shade50
                                          : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.inventory_2,
                                  color: isCritical
                                      ? Colors.red
                                      : isLowStock
                                          ? Colors.orange
                                          : Colors.green,
                                  size: 32,
                                ),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('SKU: ${item.sku} • Category: ${item.category}'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (isCritical)
                                        Chip(
                                          label: const Text('CRITICAL', style: TextStyle(fontSize: 11)),
                                          backgroundColor: Colors.red.shade100,
                                          labelPadding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        )
                                      else if (isLowStock)
                                        Chip(
                                          label: const Text('LOW STOCK', style: TextStyle(fontSize: 11)),
                                          backgroundColor: Colors.orange.shade100,
                                          labelPadding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        )
                                      else
                                        Chip(
                                          label: const Text('IN STOCK', style: TextStyle(fontSize: 11)),
                                          backgroundColor: Colors.green.shade100,
                                          labelPadding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: SizedBox(
                                width: 200,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${totalStock.toStringAsFixed(0)} ${item.unit}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isCritical
                                                ? Colors.red
                                                : isLowStock
                                                    ? Colors.orange
                                                    : Colors.green,
                                          ),
                                        ),
                                        Text(
                                          'Min: ${item.minStockLevel.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility),
                                              SizedBox(width: 8),
                                              Text('View Details'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'print_barcode',
                                          child: Row(
                                            children: [
                                              Icon(Icons.qr_code_2, color: Color(0xFF3B82F6)),
                                              SizedBox(width: 8),
                                              Text('Print Barcode'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'view':
                                            _showItemDetails(context, item);
                                            break;
                                          case 'print_barcode':
                                            showDialog(
                                              context: context,
                                              builder: (context) => BarcodePrintDialog(item: item),
                                            );
                                            break;
                                          case 'edit':
                                            _showEditItemDialog(context, item);
                                            break;
                                          case 'delete':
                                            _deleteItem(context, item.id);
                                            break;
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
  }

  void _showAddItemDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final currencySymbol = settingsProvider.currency.symbol;
    
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final barcodeController = TextEditingController();
    final categoryController = TextEditingController();
    final unitController = TextEditingController(text: 'pcs');
    final reorderLevelController = TextEditingController(text: '10');
    final minStockController = TextEditingController(text: '5');
    final costPriceController = TextEditingController(text: '0');
    final sellingPriceController = TextEditingController(text: '0');
    final descriptionController = TextEditingController();
    bool isAdding = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Item'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit *',
                          hintText: 'pcs, kg, ltr',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: reorderLevelController,
                        decoration: const InputDecoration(
                          labelText: 'Reorder Level *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: minStockController,
                        decoration: const InputDecoration(
                          labelText: 'Min Stock *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costPriceController,
                        decoration: InputDecoration(
                          labelText: 'Cost Price *',
                          prefixText: '$currencySymbol ',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: sellingPriceController,
                        decoration: InputDecoration(
                          labelText: 'Selling Price *',
                          prefixText: '$currencySymbol ',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: isAdding ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isAdding ? null : () async {
              if (nameController.text.isEmpty ||
                  skuController.text.isEmpty ||
                  categoryController.text.isEmpty ||
                  unitController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              setState(() {
                isAdding = true;
              });

              try {
                print('Creating inventory item...');
                final item = InventoryItem(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  sku: skuController.text,
                  barcode: barcodeController.text.isEmpty ? null : barcodeController.text,
                  category: categoryController.text,
                  unit: unitController.text,
                  reorderLevel: double.tryParse(reorderLevelController.text) ?? 10,
                  minStockLevel: double.tryParse(minStockController.text) ?? 5,
                  costPrice: double.tryParse(costPriceController.text) ?? 0,
                  sellingPrice: double.tryParse(sellingPriceController.text) ?? 0,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                print('Item created: ${item.name}');

                print('Calling addInventoryItem...');
                await Provider.of<InventoryProvider>(context, listen: false).addInventoryItem(item);
                print('Item added successfully');

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item added successfully')),
                  );
                }
              } catch (e) {
                print('Error in add item dialog: $e');
                setState(() {
                  isAdding = false;
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding item: $e')),
                  );
                }
              }
            },
            child: isAdding 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Item'),
          ),
        ],
      ),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, InventoryItem item) {
    final nameController = TextEditingController(text: item.name);
    final skuController = TextEditingController(text: item.sku);
    final barcodeController = TextEditingController(text: item.barcode ?? '');
    final categoryController = TextEditingController(text: item.category);
    final unitController = TextEditingController(text: item.unit);
    final reorderLevelController = TextEditingController(text: item.reorderLevel.toString());
    final minStockController = TextEditingController(text: item.minStockLevel.toString());
    final costPriceController = TextEditingController(text: item.costPrice.toString());
    final sellingPriceController = TextEditingController(text: item.sellingPrice.toString());
    final descriptionController = TextEditingController(text: item.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit (pcs, kg, etc.) *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: reorderLevelController,
                        decoration: const InputDecoration(
                          labelText: 'Reorder Level',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: minStockController,
                        decoration: const InputDecoration(
                          labelText: 'Min Stock Level',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Cost Price',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: sellingPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  skuController.text.isEmpty ||
                  categoryController.text.isEmpty ||
                  unitController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              final updatedItem = InventoryItem(
                id: item.id,
                name: nameController.text,
                sku: skuController.text,
                barcode: barcodeController.text.isEmpty ? null : barcodeController.text,
                category: categoryController.text,
                unit: unitController.text,
                reorderLevel: double.tryParse(reorderLevelController.text) ?? item.reorderLevel,
                minStockLevel: double.tryParse(minStockController.text) ?? item.minStockLevel,
                costPrice: double.tryParse(costPriceController.text) ?? item.costPrice,
                sellingPrice: double.tryParse(sellingPriceController.text) ?? item.sellingPrice,
                description: descriptionController.text.isEmpty ? null : descriptionController.text,
                createdAt: item.createdAt,
                updatedAt: DateTime.now(),
              );

              await Provider.of<InventoryProvider>(context, listen: false).updateInventoryItem(updatedItem);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item updated successfully')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(BuildContext context, InventoryItem item) async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final totalStock = inventoryProvider.getTotalStock(item.id);

    // Get stock locations from warehouse to bin
    final stockLocations = await StockOperationsService.getItemStockLocations(item.id);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(item.name)),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                Navigator.pop(context);
                _showEditItemDialog(context, item);
              },
              tooltip: 'Edit Item',
            ),
          ],
        ),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('SKU', item.sku),
                      if (item.barcode != null) _buildDetailRow('Barcode', item.barcode!),
                      _buildDetailRow('Category', item.category),
                      _buildDetailRow('Unit', item.unit),
                      if (item.description != null) _buildDetailRow('Description', item.description!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stock Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stock Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Total Stock', '${totalStock.toStringAsFixed(0)} ${item.unit}'),
                      _buildDetailRow('Reorder Level', '${item.reorderLevel.toStringAsFixed(0)} ${item.unit}'),
                      _buildDetailRow('Min Stock', '${item.minStockLevel.toStringAsFixed(0)} ${item.unit}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Pricing
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pricing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Cost Price', '₹${item.costPrice.toStringAsFixed(2)}'),
                      _buildDetailRow('Selling Price', '₹${item.sellingPrice.toStringAsFixed(2)}'),
                      _buildDetailRow(
                        'Margin',
                        '₹${(item.sellingPrice - item.costPrice).toStringAsFixed(2)} (${item.costPrice > 0 ? ((item.sellingPrice - item.costPrice) / item.costPrice * 100).toStringAsFixed(1) : '0.0'}%)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stock Locations
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Stock Locations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (stockLocations.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No stock available in any location',
                            style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        ...stockLocations.map((location) => _buildLocationCard(location, item.unit)),
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditItemDialog(context, item);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location, String unit) {
    final quantity = location['quantity'] as double;
    final warehouseName = location['warehouseName'] as String;
    final zoneName = location['zoneName'] as String;
    final rackName = location['rackName'] as String;
    final shelfName = location['shelfName'] as String;
    final binName = location['binName'] as String;
    final batchNumber = location['batchNumber'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${quantity.toStringAsFixed(0)} $unit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (batchNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Batch: $batchNumber',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.warehouse, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                warehouseName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              '🔹 Zone: $zoneName  →  Rack: $rackName  →  Shelf: $shelfName  →  Bin: $binName',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteItem(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await Provider.of<InventoryProvider>(context, listen: false).deleteInventoryItem(itemId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
