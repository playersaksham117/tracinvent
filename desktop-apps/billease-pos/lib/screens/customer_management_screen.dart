import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  _CustomerManagementScreenState createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> filteredCustomers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => isLoading = true);
    try {
      final db = DatabaseHelper.instance;
      customers = await db.getAllCustomers();
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading customers: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredCustomers = customers.where((customer) {
        final name = customer['name']?.toString().toLowerCase() ?? '';
        final phone = customer['phone']?.toString().toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();

      // Sort by name
      filteredCustomers.sort((a, b) => 
        (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? ''));
    });
  }

  Future<void> _showCustomerDialog({Map<String, dynamic>? customer}) async {
    final isEdit = customer != null;
    final nameController = TextEditingController(text: customer?['name']);
    final phoneController = TextEditingController(text: customer?['phone']);
    final emailController = TextEditingController(text: customer?['email']);
    final addressController = TextEditingController(text: customer?['address']);
    final cityController = TextEditingController(text: customer?['city']);
    final stateController = TextEditingController(text: customer?['state']);
    final postalController = TextEditingController(text: customer?['postal_code']);
    final gstinController = TextEditingController(text: customer?['gstin']);

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Customer' : 'Add New Customer'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: stateController,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: postalController,
                    decoration: const InputDecoration(
                      labelText: 'Postal Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pin_drop),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: gstinController,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                ],
              ),
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
              if (formKey.currentState!.validate()) {
                try {
                  final customerData = {
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'email': emailController.text.isEmpty ? null : emailController.text,
                    'address': addressController.text.isEmpty ? null : addressController.text,
                    'city': cityController.text.isEmpty ? null : cityController.text,
                    'state': stateController.text.isEmpty ? null : stateController.text,
                    'postal_code': postalController.text.isEmpty ? null : postalController.text,
                    'gstin': gstinController.text.isEmpty ? null : gstinController.text,
                    'loyalty_points': customer?['loyalty_points'] ?? 0,
                    'is_active': 1,
                  };

                  if (isEdit) {
                    customerData['id'] = customer['id'];
                    await DatabaseHelper.instance.updateCustomer(customerData);
                  } else {
                    await DatabaseHelper.instance.insertCustomer(customerData);
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadCustomers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Customer ${isEdit ? 'updated' : 'added'} successfully')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirm Delete'),
          ],
        ),
        content: const Text('Are you sure you want to delete this customer?'),
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
        await DatabaseHelper.instance.deleteCustomer(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted successfully')),
        );
        _loadCustomers();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting customer: $e')),
        );
      }
    }
  }

  Future<void> _viewCustomerDetails(Map<String, dynamic> customer) async {
    // Get customer's transaction history
    final sales = await DatabaseHelper.instance.getCustomerSales(customer['id']);
    final totalSpent = sales.fold<double>(0.0, (sum, sale) => sum + (sale['total'] as num? ?? 0.0));
    final totalDue = sales.fold<double>(0.0, (sum, sale) => 
      sale['payment_status'] != 'paid' ? sum + (sale['due_amount'] as num? ?? 0.0) : sum);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer['name']?.toString() ?? 'Customer Details'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Phone', customer['phone']?.toString() ?? 'N/A'),
                _buildDetailRow('Email', customer['email']?.toString() ?? 'N/A'),
                _buildDetailRow('Address', customer['address']?.toString() ?? 'N/A'),
                _buildDetailRow('City', customer['city']?.toString() ?? 'N/A'),
                _buildDetailRow('State', customer['state']?.toString() ?? 'N/A'),
                _buildDetailRow('Postal Code', customer['postal_code']?.toString() ?? 'N/A'),
                _buildDetailRow('GSTIN', customer['gstin']?.toString() ?? 'N/A'),
                const Divider(height: 24),
                _buildDetailRow('Loyalty Points', '${customer['loyalty_points'] ?? 0} pts', 
                  valueColor: Colors.amber[700]),
                _buildDetailRow('Total Spent', '₹${totalSpent.toStringAsFixed(2)}',
                  valueColor: Colors.green[700]),
                _buildDetailRow('Total Due', '₹${totalDue.toStringAsFixed(2)}',
                  valueColor: totalDue > 0 ? Colors.red[700] : Colors.green[700]),
                _buildDetailRow('Total Transactions', '${sales.length}'),
                const Divider(height: 24),
                const Text('Recent Transactions:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...sales.take(5).map((sale) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${sale['invoice_number']} - ₹${(sale['total'] as num? ?? 0.0).toStringAsFixed(2)} (${sale['payment_status']})',
                    style: const TextStyle(fontSize: 12),
                  ),
                )),
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
              _showCustomerDialog(customer: customer);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                searchQuery = value;
                _applyFilters();
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No customers found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showCustomerDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Customer'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          return _buildCustomerCard(customer);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final loyaltyPoints = customer['loyalty_points'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewCustomerDetails(customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    (customer['name']?.toString() ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer['name']?.toString() ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          customer['phone']?.toString() ?? 'N/A',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (customer['email'] != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            customer['email'].toString(),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          '$loyaltyPoints',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                        onPressed: () => _showCustomerDialog(customer: customer),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _deleteCustomer(customer['id']),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
