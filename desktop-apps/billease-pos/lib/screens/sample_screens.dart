import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';

/// =============================================================================
/// SAMPLE LIST SCREEN
/// Demonstrates the ModernTable, StatusChip, and other components
/// =============================================================================

// Sample data model
class Order {
  final String id;
  final String customer;
  final String date;
  final double amount;
  final String status;
  final int items;

  Order({
    required this.id,
    required this.customer,
    required this.date,
    required this.amount,
    required this.status,
    required this.items,
  });
}

class SampleListScreen extends StatefulWidget {
  const SampleListScreen({super.key});

  @override
  State<SampleListScreen> createState() => _SampleListScreenState();
}

class _SampleListScreenState extends State<SampleListScreen> {
  final List<Order> _orders = [
    Order(id: 'ORD-001', customer: 'Rajesh Kumar', date: '2024-01-15', amount: 2500.00, status: 'Completed', items: 3),
    Order(id: 'ORD-002', customer: 'Priya Sharma', date: '2024-01-15', amount: 1850.50, status: 'Pending', items: 2),
    Order(id: 'ORD-003', customer: 'Amit Patel', date: '2024-01-14', amount: 4200.00, status: 'Completed', items: 5),
    Order(id: 'ORD-004', customer: 'Sneha Reddy', date: '2024-01-14', amount: 980.00, status: 'Cancelled', items: 1),
    Order(id: 'ORD-005', customer: 'Vikram Singh', date: '2024-01-13', amount: 3600.00, status: 'Processing', items: 4),
    Order(id: 'ORD-006', customer: 'Meera Gupta', date: '2024-01-13', amount: 1250.00, status: 'Completed', items: 2),
  ];

  List<Order> _selectedOrders = [];
  String _sortColumn = 'date';
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with actions
            _buildHeader(),
            const SizedBox(height: 24),

            // Table
            Expanded(
              child: ModernTable<Order>(
                columns: const [
                  ModernTableColumn(id: 'id', label: 'Order ID', width: 120, sortable: true),
                  ModernTableColumn(id: 'customer', label: 'Customer', sortable: true),
                  ModernTableColumn(id: 'date', label: 'Date', width: 120, sortable: true),
                  ModernTableColumn(id: 'items', label: 'Items', width: 80, textAlign: TextAlign.center),
                  ModernTableColumn(id: 'amount', label: 'Amount', width: 120, textAlign: TextAlign.right, sortable: true),
                  ModernTableColumn(id: 'status', label: 'Status', width: 130),
                ],
                data: _orders,
                showCheckboxes: true,
                selectedItems: _selectedOrders,
                sortColumn: _sortColumn,
                sortAscending: _sortAscending,
                onSelectionChanged: (selected) {
                  setState(() => _selectedOrders = selected);
                },
                onSort: (column, ascending) {
                  setState(() {
                    _sortColumn = column;
                    _sortAscending = ascending;
                  });
                },
                cellBuilder: (order, column) {
                  switch (column.id) {
                    case 'id':
                      return Text(
                        order.id,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      );
                    case 'customer':
                      return Text(
                        order.customer,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate800,
                        ),
                      );
                    case 'date':
                      return Text(
                        order.date,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.slate600,
                        ),
                      );
                    case 'items':
                      return Text(
                        order.items.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.slate600,
                        ),
                      );
                    case 'amount':
                      return Text(
                        '₹${order.amount.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate800,
                        ),
                      );
                    case 'status':
                      return StatusChip(
                        label: order.status,
                        type: _getStatusType(order.status),
                      );
                    default:
                      return const SizedBox();
                  }
                },
                actionsBuilder: (order) => [
                  const PopupMenuItem<String>(value: 'view', child: Text('View Details')),
                  const PopupMenuItem<String>(value: 'edit', child: Text('Edit Order')),
                  const PopupMenuItem<String>(value: 'print', child: Text('Print Receipt')),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ],
                onAction: (order, action) {
                  debugPrint('Action: $action on ${order.id}');
                },
                onRowTap: (order) {
                  debugPrint('Tapped: ${order.id}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orders',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_orders.length} orders found',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
        // Search
        SizedBox(
          width: 260,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search orders...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Filter button
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list_rounded, size: 18),
          label: const Text('Filter'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        // Add button
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New Order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  StatusType _getStatusType(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return StatusType.success;
      case 'pending':
        return StatusType.warning;
      case 'processing':
        return StatusType.info;
      case 'cancelled':
        return StatusType.error;
      default:
        return StatusType.neutral;
    }
  }
}

/// =============================================================================
/// SAMPLE FORM SCREEN
/// Demonstrates ResponsiveFormGrid and QuantityInput
/// =============================================================================

class SampleFormScreen extends StatefulWidget {
  const SampleFormScreen({super.key});

  @override
  State<SampleFormScreen> createState() => _SampleFormScreenState();
}

class _SampleFormScreenState extends State<SampleFormScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Add New Product',
                subtitle: 'Fill in the product details below',
              ),
              const SizedBox(height: 8),

              // Responsive form grid
              ResponsiveFormGrid(
                children: [
                  _buildTextField(label: 'Product Name', hint: 'Enter product name'),
                  _buildTextField(label: 'SKU', hint: 'Enter SKU'),
                  _buildTextField(label: 'Category', hint: 'Select category'),
                  _buildTextField(label: 'Price', hint: '₹0.00', prefixIcon: Icons.currency_rupee_rounded),
                  _buildTextField(label: 'Cost Price', hint: '₹0.00', prefixIcon: Icons.currency_rupee_rounded),
                  _buildTextField(label: 'MRP', hint: '₹0.00', prefixIcon: Icons.currency_rupee_rounded),
                ],
              ),
              const SizedBox(height: 24),

              // Quantity input demo
              Row(
                children: [
                  Text(
                    'Initial Stock:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  QuantityInput(
                    value: _quantity,
                    min: 0,
                    max: 100,
                    onChanged: (value) => setState(() => _quantity = value),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Text('Save Product'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.slate700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AppColors.slate400)
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }
}
