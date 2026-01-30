import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class CartItem {
  final Product product;
  int quantity;
  double discount;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0,
  });

  double get subtotal => product.price * quantity;
  double get taxAmount => (subtotal - discount) * product.taxRate / 100;
  double get total => subtotal - discount + taxAmount;
}

class _POSScreenState extends State<POSScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Customer> _customers = [];
  final List<CartItem> _cart = [];
  
  Customer? _selectedCustomer;
  double _globalDiscount = 0;
  String _selectedReceiptTemplate = 'standard';
  bool _isLoading = true;
  String _paymentMethod = 'Cash';
  String _currencySymbol = '₹';
  pw.Font? _unicodeFont;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load currency symbol from preferences
      final prefs = await SharedPreferences.getInstance();
      _currencySymbol = prefs.getString('currency_symbol') ?? '₹';
      
      // Load Unicode font for PDF
      _unicodeFont = await PdfGoogleFonts.notoSansRegular();
      
      final db = await _db.database;
      
      // Get products
      final productsData = await db.query('products', where: 'is_active = ?', whereArgs: [1]);
      final products = productsData.map((map) => Product.fromMap(map)).toList();
      
      // Get customers
      final customersData = await db.query('customers');
      final customers = customersData.map((map) => Customer.fromMap(map)).toList();
      
      setState(() {
        _products = products;
        _filteredProducts = products;
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase()) ||
                 product.sku.toLowerCase().contains(query.toLowerCase()) ||
                 (product.barcode?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
      if (existingIndex != -1) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _updateQuantity(int index, int quantity) {
    if (quantity > 0) {
      setState(() {
        _cart[index].quantity = quantity;
      });
    }
  }

  double get _subtotal {
    return _cart.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get _totalDiscount {
    final itemDiscounts = _cart.fold(0.0, (sum, item) => sum + item.discount);
    return itemDiscounts + _globalDiscount;
  }

  double get _totalTax {
    return _cart.fold(0, (sum, item) => sum + item.taxAmount);
  }

  double get _grandTotal {
    return _subtotal - _totalDiscount + _totalTax;
  }

  void _showCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Customer'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search Customer',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    return ListTile(
                      title: Text(customer.name),
                      subtitle: Text(customer.phone ?? 'No phone'),
                      trailing: Text(customer.customerCode),
                      selected: _selectedCustomer?.id == customer.id,
                      onTap: () {
                        setState(() {
                          _selectedCustomer = customer;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog() {
    _discountController.text = _globalDiscount.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Discount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Discount Amount',
                prefixIcon: Icon(Icons.discount),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _globalDiscount = double.tryParse(_discountController.text) ?? 0;
              });
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _testPrintReceipt() async {
    final pdf = pw.Document();
    final testSaleNumber = 'TEST-${DateTime.now().millisecondsSinceEpoch}';
    
    // Add sample items if cart is empty
    if (_cart.isEmpty) {
      _cart.add(CartItem(
        product: Product(
          id: 1,
          tenantId: 'test',
          name: 'Sample Product',
          sku: 'TEST-001',
          price: 100.0,
          cost: 50.0,
          taxRate: 18.0,
          stockQuantity: 10,
          unit: 'piece',
          isActive: true,
          syncStatus: 0,
        ),
        quantity: 2,
      ));
    }

    switch (_selectedReceiptTemplate) {
      case 'thermal':
        pdf.addPage(_buildThermalReceipt(testSaleNumber, _grandTotal, 0));
        break;
      case 'a4':
        pdf.addPage(_buildA4Receipt(testSaleNumber, _grandTotal, 0));
        break;
      case 'minimal':
        pdf.addPage(_buildMinimalReceipt(testSaleNumber, _grandTotal, 0));
        break;
      default:
        pdf.addPage(_buildStandardReceipt(testSaleNumber, _grandTotal, 0));
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  void _showCheckoutDialog() {
    final TextEditingController paidController = TextEditingController(text: _grandTotal.toStringAsFixed(2));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Checkout'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Total Amount'),
                  trailing: Text(
                    '$_currencySymbol${_grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Cash', 'Card', 'UPI', 'Wallet']
                      .map((method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _paymentMethod = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: paidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid',
                    prefixIcon: Icon(Icons.payment),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedReceiptTemplate,
                  decoration: const InputDecoration(
                    labelText: 'Receipt Template',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'standard', child: Text('Standard')),
                    DropdownMenuItem(value: 'thermal', child: Text('Thermal (58mm)')),
                    DropdownMenuItem(value: 'a4', child: Text('A4 Invoice')),
                    DropdownMenuItem(value: 'minimal', child: Text('Minimal')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedReceiptTemplate = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _testPrintReceipt();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print),
                  SizedBox(width: 4),
                  Text('Test Print'),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final paidAmount = double.tryParse(paidController.text) ?? 0;
                if (paidAmount < _grandTotal) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Insufficient payment amount')),
                  );
                  return;
                }
                
                if (!context.mounted) return;
                Navigator.pop(context);
                await _completeSale(paidAmount);
              },
              icon: const Icon(Icons.check),
              label: const Text('Complete Sale'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeSale(double paidAmount) async {
    try {
      // Save to database
      final saleNumber = 'SALE${DateTime.now().millisecondsSinceEpoch}';
      final changeAmount = paidAmount - _grandTotal;
      
      final db = await _db.database;
      
      // Create sale
      final saleId = await db.insert('sales', {
        'tenant_id': 'tenant_001',
        'sale_number': saleNumber,
        'customer_id': _selectedCustomer?.id,
        'customer_name': _selectedCustomer?.name ?? 'Walk-in Customer',
        'customer_phone': _selectedCustomer?.phone,
        'subtotal': _subtotal,
        'tax_amount': _totalTax,
        'discount_amount': _totalDiscount,
        'total_amount': _grandTotal,
        'paid_amount': paidAmount,
        'change_amount': changeAmount,
        'payment_method': _paymentMethod,
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Save sale items
      for (var item in _cart) {
        await db.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'sku': item.product.sku,
          'quantity': item.quantity,
          'unit_price': item.product.price,
          'discount_amount': item.discount,
          'tax_rate': item.product.taxRate,
          'tax_amount': item.taxAmount,
          'total_amount': item.total,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Update stock
        final newStock = item.product.stockQuantity - item.quantity;
        await db.rawUpdate(
          'UPDATE products SET stock_quantity = ? WHERE id = ?',
          [newStock, item.product.id],
        );
      }

      // Generate and print receipt
      await _printReceipt(saleNumber, paidAmount, changeAmount);

      // Clear cart
      setState(() {
        _cart.clear();
        _selectedCustomer = null;
        _globalDiscount = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale completed successfully!')),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing sale: $e')),
        );
      }
    }
  }

  Future<void> _printReceipt(String saleNumber, double paidAmount, double changeAmount) async {
    final pdf = pw.Document();
    
    switch (_selectedReceiptTemplate) {
      case 'thermal':
        pdf.addPage(_buildThermalReceipt(saleNumber, paidAmount, changeAmount));
        break;
      case 'a4':
        pdf.addPage(_buildA4Receipt(saleNumber, paidAmount, changeAmount));
        break;
      case 'minimal':
        pdf.addPage(_buildMinimalReceipt(saleNumber, paidAmount, changeAmount));
        break;
      default:
        pdf.addPage(_buildStandardReceipt(saleNumber, paidAmount, changeAmount));
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  pw.Page _buildStandardReceipt(String saleNumber, double paidAmount, double changeAmount) {
    return pw.Page(
      pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 0),
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BillEase POS',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Standard Receipt',
                style: pw.TextStyle(fontSize: 12, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Text(
                'Sale #: $saleNumber',
                style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
              pw.Text(
                'Date: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
              if (_selectedCustomer != null) ...[
                pw.Text(
                  'Customer: ${_selectedCustomer!.name}',
                  style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
                  textAlign: pw.TextAlign.left,
                ),
                if (_selectedCustomer!.phone != null)
                  pw.Text(
                    'Phone: ${_selectedCustomer!.phone}',
                    style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
                    textAlign: pw.TextAlign.left,
                  ),
              ],
              pw.Divider(),
              ..._cart.map((item) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.product.name,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
                      textAlign: pw.TextAlign.left,
                    ),
                    pw.Text(
                      '${item.quantity} x $_currencySymbol${item.product.price.toStringAsFixed(2)} = $_currencySymbol${item.subtotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
                      textAlign: pw.TextAlign.left,
                    ),
                    if (item.discount > 0)
                      pw.Text(
                        'Discount: -$_currencySymbol${item.discount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 9, font: _unicodeFont),
                        textAlign: pw.TextAlign.left,
                      ),
                    if (item.product.taxRate > 0)
                      pw.Text(
                        'Tax (${item.product.taxRate}%): $_currencySymbol${item.taxAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 9, font: _unicodeFont),
                        textAlign: pw.TextAlign.left,
                      ),
                  ],
                ),
              )),
              pw.Divider(),
              pw.Text(
                'Subtotal: $_currencySymbol${_subtotal.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
              if (_totalDiscount > 0)
                pw.Text(
                  'Total Discount: -$_currencySymbol${_totalDiscount.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
                  textAlign: pw.TextAlign.left,
                ),
              pw.Text(
                'Total Tax: $_currencySymbol${_totalTax.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
              pw.Divider(),
              pw.Text(
                'TOTAL: $_currencySymbol${_grandTotal.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
              pw.Text(
                'Paid: $_currencySymbol${paidAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
              pw.Text(
                'Change: $_currencySymbol${changeAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
              pw.Text(
                'Payment: $_paymentMethod',
                style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Text(
                'Thank You for Your Business!',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Visit Again',
                style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
            ],
          ),
        ),
      );
  }

  pw.Page _buildThermalReceipt(String saleNumber, double paidAmount, double changeAmount) {
    return pw.Page(
      pageFormat: const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 0),
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BillEase',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Thermal Receipt',
              style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Divider(),
            pw.Text(
              'Sale: $saleNumber',
              style: pw.TextStyle(fontSize: 9, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Text(
              DateFormat('dd/MM/yy hh:mm a').format(DateTime.now()),
              style: pw.TextStyle(fontSize: 9, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            if (_selectedCustomer != null)
              pw.Text(
                _selectedCustomer!.name,
                style: pw.TextStyle(fontSize: 9, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
            pw.Divider(),
            ..._cart.map((item) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    item.product.name,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
                    textAlign: pw.TextAlign.left,
                  ),
                  pw.Text(
                    '${item.quantity} x $_currencySymbol${item.product.price.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 9, font: _unicodeFont),
                    textAlign: pw.TextAlign.left,
                  ),
                  pw.Text(
                    '$_currencySymbol${item.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 9, font: _unicodeFont),
                    textAlign: pw.TextAlign.left,
                  ),
                ],
              ),
            )),
            pw.Divider(),
            pw.Text(
              'Total: $_currencySymbol${_grandTotal.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Text(
              'Paid: $_currencySymbol${paidAmount.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Text(
              'Change: $_currencySymbol${changeAmount.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Thank You!',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  pw.Page _buildA4Receipt(String saleNumber, double paidAmount, double changeAmount) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4.copyWith(marginLeft: 0, marginRight: 0, marginTop: 0, marginBottom: 0),
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BillEase Point of Sale',
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 15),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
            pw.Text(
              'Invoice Number: $saleNumber',
              style: pw.TextStyle(fontSize: 12, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Text(
              'Date: ${DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 12, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 10),
            if (_selectedCustomer != null) ...[
              pw.Text(
                'BILL TO',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
              pw.Text(
                _selectedCustomer!.name,
                style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
              if (_selectedCustomer!.phone != null)
                pw.Text(
                  'Phone: ${_selectedCustomer!.phone}',
                  style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
                  textAlign: pw.TextAlign.left,
                ),
              if (_selectedCustomer!.email != null)
                pw.Text(
                  'Email: ${_selectedCustomer!.email}',
                  style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
                  textAlign: pw.TextAlign.left,
                ),
              pw.SizedBox(height: 10),
            ],
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'ITEMS',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 5),
            ..._cart.map((item) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    item.product.name,
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
                    textAlign: pw.TextAlign.left,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'SKU: ${item.product.sku}',
                    style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
                    textAlign: pw.TextAlign.left,
                  ),
                  pw.Text(
                    'Quantity: ${item.quantity} x $_currencySymbol${item.product.price.toStringAsFixed(2)} = $_currencySymbol${item.subtotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
                    textAlign: pw.TextAlign.left,
                  ),
                  if (item.discount > 0)
                    pw.Text(
                      'Item Discount: -$_currencySymbol${item.discount.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
                      textAlign: pw.TextAlign.left,
                    ),
                  if (item.product.taxRate > 0)
                    pw.Text(
                      'Tax (${item.product.taxRate}%): $_currencySymbol${item.taxAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
                      textAlign: pw.TextAlign.left,
                    ),
                  pw.Text(
                    'Item Total: $_currencySymbol${item.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
                    textAlign: pw.TextAlign.left,
                  ),
                ],
              ),
            )),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
            pw.Text(
              'SUMMARY',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Subtotal: $_currencySymbol${_subtotal.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            if (_totalDiscount > 0)
              pw.Text(
                'Total Discount: -$_currencySymbol${_totalDiscount.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
                textAlign: pw.TextAlign.left,
              ),
            pw.Text(
              'Total Tax: $_currencySymbol${_totalTax.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 5),
            pw.Divider(),
            pw.Text(
              'GRAND TOTAL: $_currencySymbol${_grandTotal.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Amount Paid: $_currencySymbol${paidAmount.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 12, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Text(
              'Change Due: $_currencySymbol${changeAmount.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 12, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Text(
              'Payment Method: $_paymentMethod',
              style: pw.TextStyle(fontSize: 12, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Thank You for Your Business!',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Text(
              'We appreciate your patronage',
              style: pw.TextStyle(fontSize: 11, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  pw.Page _buildMinimalReceipt(String saleNumber, double paidAmount, double changeAmount) {
    return pw.Page(
      pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 0),
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BillEase',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Divider(),
            pw.Text(
              saleNumber,
              style: pw.TextStyle(fontSize: 9, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Text(
              DateFormat('dd/MM/yy hh:mm').format(DateTime.now()),
              style: pw.TextStyle(fontSize: 9, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Divider(),
            ..._cart.map((item) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    item.product.name,
                    style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
                    textAlign: pw.TextAlign.left,
                  ),
                  pw.Text(
                    '${item.quantity} x $_currencySymbol${item.product.price.toStringAsFixed(2)} = $_currencySymbol${item.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 9, font: _unicodeFont),
                    textAlign: pw.TextAlign.left,
                  ),
                ],
              ),
            )),
            pw.Divider(),
            pw.Text(
              'Total: $_currencySymbol${_grandTotal.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Text(
              'Paid: $_currencySymbol${paidAmount.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.Text(
              'Change: $_currencySymbol${changeAmount.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Thank You',
              style: pw.TextStyle(fontSize: 10, font: _unicodeFont),
              textAlign: pw.TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _selectedCustomer = null;
      _globalDiscount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Products Section
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search Products',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterProducts('');
                                    },
                                  )
                                : null,
                          ),
                          onChanged: _filterProducts,
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return Card(
                              elevation: 2,
                              child: InkWell(
                                onTap: () => _addToCart(product),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: Icon(
                                            Icons.inventory_2,
                                            size: 40,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Text(
                                        '$_currencySymbol${product.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      Text(
                                        'Stock: ${product.stockQuantity}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: product.isLowStock
                                              ? Colors.red
                                              : Colors.grey[600],
                                        ),
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
                  ),
                ),
                // Cart Section
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Shopping Cart',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_cart.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear_all),
                                  onPressed: _clearCart,
                                  tooltip: 'Clear Cart',
                                ),
                            ],
                          ),
                        ),
                        // Customer Selection
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(_selectedCustomer?.name ?? 'Walk-in Customer'),
                          trailing: const Icon(Icons.arrow_drop_down),
                          onTap: _showCustomerDialog,
                        ),
                        const Divider(height: 1),
                        // Cart Items
                        Expanded(
                          child: _cart.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Cart is empty',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _cart.length,
                                  itemBuilder: (context, index) {
                                    final item = _cart[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.product.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, size: 20),
                                                  onPressed: () => _removeFromCart(index),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove),
                                                  onPressed: () => _updateQuantity(
                                                    index,
                                                    item.quantity - 1,
                                                  ),
                                                ),
                                                Text(
                                                  '${item.quantity}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add),
                                                  onPressed: () => _updateQuantity(
                                                    index,
                                                    item.quantity + 1,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '$_currencySymbol${item.product.price.toStringAsFixed(2)}',
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'Total: $_currencySymbol${item.total.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        // Totals Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border(
                              top: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal:'),
                                  Text('$_currencySymbol${_subtotal.toStringAsFixed(2)}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tax:'),
                                  Text('$_currencySymbol${_totalTax.toStringAsFixed(2)}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount:'),
                                  Text('-$_currencySymbol${_totalDiscount.toStringAsFixed(2)}'),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$_currencySymbol${_grandTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _cart.isEmpty ? null : _showDiscountDialog,
                                      icon: const Icon(Icons.discount),
                                      label: const Text('Discount'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _cart.isEmpty ? null : _showCheckoutDialog,
                                  icon: const Icon(Icons.payment),
                                  label: const Text('Checkout'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
