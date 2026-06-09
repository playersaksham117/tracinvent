import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/warehouse_provider.dart';
import '../providers/stock_entry_provider.dart';
import '../models/warehouse.dart';
import '../models/location.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  Warehouse? _selectedWarehouse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouses & Storage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWarehouseDialog(context),
          ),
        ],
      ),
      body: Consumer<WarehouseProvider>(
        builder: (context, warehouseProvider, _) {
          if (warehouseProvider.warehouses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warehouse_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No warehouses yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddWarehouseDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Warehouse'),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              // Warehouses List
              SizedBox(
                width: 350,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: warehouseProvider.warehouses.length,
                  itemBuilder: (context, index) {
                    final warehouse = warehouseProvider.warehouses[index];
                    final isSelected = _selectedWarehouse?.id == warehouse.id;
                    
                    return Card(
                      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTypeColor(warehouse.type).withOpacity(0.2),
                          child: Icon(
                            _getTypeIcon(warehouse.type),
                            color: _getTypeColor(warehouse.type),
                          ),
                        ),
                        title: Text(
                          warehouse.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getTypeLabel(warehouse.type)),
                            Text(
                              warehouse.city ?? warehouse.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: warehouse.isActive
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.cancel, color: Colors.red),
                        onTap: () {
                          setState(() => _selectedWarehouse = warehouse);
                          warehouseProvider.loadStorageLocations(warehouse.id);
                        },
                      ),
                    );
                  },
                ),
              ),
              const VerticalDivider(width: 1),
              
              // Warehouse Details
              Expanded(
                child: _selectedWarehouse == null
                    ? Center(
                        child: Text(
                          'Select a warehouse to view details',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      )
                    : _buildWarehouseDetails(context, _selectedWarehouse!, warehouseProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWarehouseDetails(
    BuildContext context,
    Warehouse warehouse,
    WarehouseProvider provider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _getTypeColor(warehouse.type).withOpacity(0.2),
                child: Icon(
                  _getTypeIcon(warehouse.type),
                  color: _getTypeColor(warehouse.type),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warehouse.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _getTypeLabel(warehouse.type),
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditWarehouseDialog(context, warehouse),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.location_on, 'Address', warehouse.address),
                  if (warehouse.city != null)
                    _buildDetailRow(Icons.location_city, 'City', warehouse.city!),
                  if (warehouse.state != null)
                    _buildDetailRow(Icons.map, 'State', warehouse.state!),
                  if (warehouse.pincode != null)
                    _buildDetailRow(Icons.pin_drop, 'Pincode', warehouse.pincode!),
                  if (warehouse.contactPerson != null)
                    _buildDetailRow(Icons.person, 'Contact', warehouse.contactPerson!),
                  if (warehouse.contactPhone != null)
                    _buildDetailRow(Icons.phone, 'Phone', warehouse.contactPhone!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Zones Management - ONLY zones, no cells
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Zones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddZoneDialog(context, warehouse.id),
                icon: const Icon(Icons.add),
                label: const Text('Add Zone'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          FutureBuilder<List<Zone>>(
            future: _loadZonesForWarehouse(warehouse.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final zones = snapshot.data ?? [];
              
              if (zones.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.dashboard_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No zones defined',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create zones to organize storage areas in this warehouse',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddZoneDialog(context, warehouse.id),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Zone'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              return _buildZonesList(zones, warehouse.id);
            },
          ),
        ],
      ),
    );
  }

  // Build simple zones list with edit/delete buttons
  Widget _buildZonesList(List<Zone> zones, String warehouseId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: zones.map((zone) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.dashboard_outlined, color: Colors.blue.shade700),
                ),
                title: Text(
                  zone.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  zone.description ?? 'Zone',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      tooltip: 'Edit Zone',
                      onPressed: () => _showEditZoneDialog(context, zone, warehouseId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      tooltip: 'Delete Zone',
                      onPressed: () => _showDeleteZoneDialog(context, zone),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'warehouse':
        return Icons.warehouse;
      case 'branch':
        return Icons.store;
      case 'godown':
        return Icons.home_work;
      case 'rack':
        return Icons.storage;
      case 'cell':
        return Icons.grid_view;
      default:
        return Icons.location_on;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'warehouse':
        return Colors.blue;
      case 'branch':
        return Colors.green;
      case 'godown':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  String _getTypeLabel(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }

  void _showAddWarehouseDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final pincodeController = TextEditingController();
    final contactPersonController = TextEditingController();
    final contactPhoneController = TextEditingController();
    String selectedType = 'warehouse';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Warehouse'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'warehouse', child: Text('Warehouse')),
                    DropdownMenuItem(value: 'branch', child: Text('Branch')),
                    DropdownMenuItem(value: 'godown', child: Text('Godown')),
                  ],
                  onChanged: (value) => selectedType = value!,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: stateController,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pincodeController,
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone',
                    border: OutlineInputBorder(),
                  ),
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
              if (nameController.text.isEmpty || addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              final warehouse = Warehouse(
                id: const Uuid().v4(),
                name: nameController.text,
                type: selectedType,
                address: addressController.text,
                city: cityController.text.isEmpty ? null : cityController.text,
                state: stateController.text.isEmpty ? null : stateController.text,
                pincode: pincodeController.text.isEmpty ? null : pincodeController.text,
                contactPerson: contactPersonController.text.isEmpty ? null : contactPersonController.text,
                contactPhone: contactPhoneController.text.isEmpty ? null : contactPhoneController.text,
                createdAt: DateTime.now(),
              );

              await Provider.of<WarehouseProvider>(context, listen: false)
                  .addWarehouse(warehouse);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Warehouse added successfully')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditWarehouseDialog(BuildContext context, Warehouse warehouse) {
    final nameController = TextEditingController(text: warehouse.name);
    final addressController = TextEditingController(text: warehouse.address);
    final cityController = TextEditingController(text: warehouse.city ?? '');
    final stateController = TextEditingController(text: warehouse.state ?? '');
    final pincodeController = TextEditingController(text: warehouse.pincode ?? '');
    final contactPersonController = TextEditingController(text: warehouse.contactPerson ?? '');
    final contactPhoneController = TextEditingController(text: warehouse.contactPhone ?? '');
    String selectedType = warehouse.type;
    bool isActive = warehouse.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit Warehouse'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warehouse),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'warehouse', child: Text('Warehouse')),
                      DropdownMenuItem(value: 'branch', child: Text('Branch')),
                      DropdownMenuItem(value: 'godown', child: Text('Godown')),
                    ],
                    onChanged: (value) => setState(() => selectedType = value!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_city),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: stateController,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.map),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pincodeController,
                    decoration: const InputDecoration(
                      labelText: 'Pincode',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pin_drop),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contactPersonController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Person',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contactPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: Text(isActive ? 'Warehouse is active' : 'Warehouse is inactive'),
                    value: isActive,
                    onChanged: (value) => setState(() => isActive = value),
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
            ElevatedButton.icon(
              onPressed: () async {
                if (nameController.text.isEmpty || addressController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill required fields')),
                  );
                  return;
                }

                final updatedWarehouse = Warehouse(
                  id: warehouse.id,
                  name: nameController.text,
                  type: selectedType,
                  address: addressController.text,
                  city: cityController.text.isEmpty ? null : cityController.text,
                  state: stateController.text.isEmpty ? null : stateController.text,
                  pincode: pincodeController.text.isEmpty ? null : pincodeController.text,
                  contactPerson: contactPersonController.text.isEmpty ? null : contactPersonController.text,
                  contactPhone: contactPhoneController.text.isEmpty ? null : contactPhoneController.text,
                  isActive: isActive,
                  createdAt: warehouse.createdAt,
                );

                await Provider.of<WarehouseProvider>(context, listen: false)
                    .updateWarehouse(updatedWarehouse);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Warehouse "${nameController.text}" updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  this.setState(() => _selectedWarehouse = updatedWarehouse);
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Load zones for a warehouse
  Future<List<Zone>> _loadZonesForWarehouse(String warehouseId) async {
    final provider = Provider.of<StockEntryProvider>(context, listen: false);
    return await provider.loadZones(warehouseId);
  }

  // Show dialog to add a zone
  void _showAddZoneDialog(BuildContext context, String warehouseId) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dashboard_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Add New Zone'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Zone Name *',
                  hintText: 'e.g., Zone A, Cold Storage, Electronics',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dashboard_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g., Temperature controlled area',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a zone name')),
                );
                return;
              }

              try {
                final provider = Provider.of<StockEntryProvider>(context, listen: false);
                await provider.createZone(
                  warehouseId: warehouseId,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Zone "${nameController.text.trim()}" created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {}); // Refresh the UI
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Zone'),
          ),
        ],
      ),
    );
  }

  // Show dialog to edit a zone
  void _showEditZoneDialog(BuildContext context, Zone zone, String warehouseId) {
    final nameController = TextEditingController(text: zone.name);
    final descriptionController = TextEditingController(text: zone.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 8),
            Text('Edit Zone'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Zone Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dashboard_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a zone name')),
                );
                return;
              }

              try {
                final provider = Provider.of<StockEntryProvider>(context, listen: false);
                await provider.updateZone(
                  zoneId: zone.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Zone "${nameController.text.trim()}" updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {}); // Refresh the UI
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Show dialog to delete a zone
  void _showDeleteZoneDialog(BuildContext context, Zone zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Zone'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete zone "${zone.name}"?\n\nThis will also delete all cells within this zone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final provider = Provider.of<StockEntryProvider>(context, listen: false);
                await provider.deleteZone(zone.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zone deleted'), backgroundColor: Colors.orange),
                  );
                  setState(() {}); // Refresh the UI
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
