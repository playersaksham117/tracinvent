import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/receipt_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _searchController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _paidAmountFocusNode = FocusNode();
  final _completeSaleFocusNode = FocusNode();

  Timer? _debounce;

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  final List<CartItem> _cartItems = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  int? _selectedCustomerId;
  bool _showCustomerDropdown = false;

  // Billing mode variables
  String _billingMode = 'sale'; // 'sale' or 'quotation'
  String _quotationType = 'sale'; // Fixed to sales quotation

  String _invoiceNumber = '';
  final DateTime _invoiceDate = DateTime.now();
  String _paymentMethod = 'Cash';
  String _paymentStatus = 'paid'; // paid, partial, credit
  bool _isLoading = false;
  bool _allowNegativeStockSales = false;

  double _subtotal = 0.0;
  double _totalTax = 0.0;
  double _discount = 0.0;
  double _grandTotal = 0.0;
  double _paidAmount = 0.0;
  double _dueAmount = 0.0;
  double _changeAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-focus search on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  // Keyboard shortcut handler
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // F1-F4: Quick payment methods
    if (event.logicalKey == LogicalKeyboardKey.f1) {
      setState(() => _paymentMethod = 'Cash');
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.f2) {
      setState(() => _paymentMethod = 'Card');
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.f3) {
      setState(() => _paymentMethod = 'UPI');
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.f4) {
      setState(() => _paymentMethod = 'Wallet');
      return KeyEventResult.handled;
    }

    // Ctrl+Enter: Complete sale
    if (event.logicalKey == LogicalKeyboardKey.enter &&
        HardwareKeyboard.instance.isControlPressed) {
      if (_cartItems.isNotEmpty) {
        _completeSale();
      }
      return KeyEventResult.handled;
    }

    // Ctrl+N: New bill
    if (event.logicalKey == LogicalKeyboardKey.keyN &&
        HardwareKeyboard.instance.isControlPressed) {
      _resetBilling();
      return KeyEventResult.handled;
    }

    // Ctrl+F: Focus search
    if (event.logicalKey == LogicalKeyboardKey.keyF &&
        HardwareKeyboard.instance.isControlPressed) {
      _searchFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // Ctrl+P: Focus payment amount
    if (event.logicalKey == LogicalKeyboardKey.keyP &&
        HardwareKeyboard.instance.isControlPressed) {
      if (_paymentStatus != 'credit') {
        _paidAmountFocusNode.requestFocus();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    // Generate new invoice/quotation number based on mode
    if (_billingMode == 'quotation') {
      _invoiceNumber = await _dbHelper.generateQuotationNumber(quotationType: _quotationType);
    } else {
      _invoiceNumber = await _dbHelper.generateInvoiceNumber();
    }

    // Load products
    final products = await _dbHelper
        .query('products', where: 'is_active = ?', whereArgs: [1]);

    // Load customers
    final customers = await _dbHelper.getAllCustomers();

    setState(() {
      _allowNegativeStockSales =
          prefs.getBool('allow_negative_stock_sales') ?? false;
      _allProducts = products;
      _filteredProducts = products;
      _customers = customers;
      _filteredCustomers = customers;
      _isLoading = false;
    });
  }

  void _filterProducts(String query) {
    // Debounce search input
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        if (query.isEmpty) {
          _filteredProducts = _allProducts;
        } else {
          _filteredProducts = _allProducts.where((product) {
            final name = product['name'].toString().toLowerCase();
            final sku = product['sku'].toString().toLowerCase();
            final barcode = product['barcode']?.toString().toLowerCase() ?? '';
            final searchLower = query.toLowerCase();

            return name.contains(searchLower) ||
                sku.contains(searchLower) ||
                barcode.contains(searchLower);
          }).toList();
        }
      });
    });
  }

  bool _isServiceItem(Map<String, dynamic> product) {
    final type = (product['product_type']?.toString().toLowerCase() ?? '');
    if (type == 'service') return true;
    final category = (product['category']?.toString().toLowerCase() ?? '');
    return category.contains('service');
  }

  int _availableProductStock(Map<String, dynamic> product) {
    final stock = (product['stock_quantity'] as int?) ?? 0;
    if (_isServiceItem(product)) return 1 << 30;

    final cartQty = _cartItems
        .where((item) => item.productId == product['id'])
        .fold<int>(0, (sum, item) => sum + item.quantity);
    return stock - cartQty;
  }

  void _addToCart(Map<String, dynamic> product) {
    if (!_allowNegativeStockSales &&
        !_isServiceItem(product) &&
        _availableProductStock(product) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No remaining stock for this product'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      final existingIndex =
          _cartItems.indexWhere((item) => item.productId == product['id']);

      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(
          productId: product['id'],
          productName: product['name'],
          sku: product['sku'],
          barcode: product['barcode'],
          unitPrice: (product['price'] as num).toDouble(),
          quantity: 1,
          taxRate: (product['tax_rate'] as num?)?.toDouble() ?? 0,
          isService: _isServiceItem(product),
        ));
      }

      _calculateTotals();
      _searchController.clear();
      _filteredProducts = _allProducts;
      
      // Keep focus on search for rapid entry
      _searchFocusNode.requestFocus();
    });
  }

  void _updateCartItemQuantity(int index, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        if (!_allowNegativeStockSales && !_cartItems[index].isService) {
          final product = _allProducts.firstWhere(
            (p) => p['id'] == _cartItems[index].productId,
            orElse: () => {'stock_quantity': 0},
          );
          final stock = (product['stock_quantity'] as int?) ?? 0;
          if (quantity > stock) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Requested quantity exceeds available stock'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }
        _cartItems[index].quantity = quantity;
      }
      _calculateTotals();
    });
  }

  void _updateCartItemPrice(int index, double price) {
    setState(() {
      if (price >= 0) {
        _cartItems[index].unitPrice = price;
        _calculateTotals();
      }
    });
  }

  double? _parseEditedUnitPrice({
    required String input,
    required double taxRate,
  }) {
    final parsed = double.tryParse(input.trim());
    if (parsed == null) return null;

    // If user enters negative value (e.g. -50), treat magnitude as
    // tax-inclusive final amount and convert to pre-tax unit rate.
    if (parsed < 0) {
      final inclusiveAmount = parsed.abs();
      final divisor = 1 + (taxRate / 100);
      if (divisor <= 0) return inclusiveAmount;
      return inclusiveAmount / divisor;
    }

    return parsed;
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    _subtotal = 0.0;
    _totalTax = 0.0;

    for (var item in _cartItems) {
      final itemSubtotal = item.unitPrice * item.quantity;
      final itemTax = itemSubtotal * (item.taxRate / 100);

      _subtotal += itemSubtotal;
      _totalTax += itemTax;
    }

    _grandTotal = _subtotal + _totalTax - _discount;

    // Calculate due amount and change
    if (_paidAmountController.text.isNotEmpty) {
      _paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
    }

    if (_paymentStatus == 'paid') {
      _dueAmount = 0.0;
      _changeAmount = _paidAmount - _grandTotal;
      
      // Auto-populate paid amount for full payment
      if (_paidAmountController.text.isEmpty || 
          double.tryParse(_paidAmountController.text) != _grandTotal) {
        _paidAmountController.text = _grandTotal.toStringAsFixed(2);
      }
    } else if (_paymentStatus == 'partial') {
      _dueAmount = _grandTotal - _paidAmount;
      _changeAmount = 0.0;
    } else {
      // credit
      _dueAmount = _grandTotal;
      _paidAmount = 0.0;
      _changeAmount = 0.0;
    }
  }

  Future<void> _completeSale() async {
    if (_cartItems.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add items to cart'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // Skip payment validation for quotations
    if (_billingMode != 'quotation') {
      // Validate payment
      if (_paymentStatus == 'paid' && _paidAmount < _grandTotal) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Paid amount must be >= total amount'),
              backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      if (_billingMode == 'quotation') {
        // Insert quotation (NO STOCK CHANGES)
        final quotationData = {
          'tenant_id': 'default',
          'quotation_number': _invoiceNumber,
          'quotation_type': 'sale',
          'customer_id': _selectedCustomerId,
          'customer_name': _customerNameController.text.isNotEmpty
              ? _customerNameController.text
              : null,
          'customer_phone': _customerPhoneController.text.isNotEmpty
              ? _customerPhoneController.text
              : null,
          'subtotal': _subtotal,
          'tax_amount': _totalTax,
          'discount_amount': _discount,
          'total_amount': _grandTotal,
          'notes': _notesController.text.isEmpty ? null : _notesController.text,
          'status': 'draft',
          'valid_until': now.add(const Duration(days: 30)).toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final quotationId = await _dbHelper.insertQuotation(quotationData);

        // Insert quotation items (NO STOCK CHANGES)
        for (var item in _cartItems) {
          final itemData = {
            'quotation_id': quotationId,
            'product_id': item.productId,
            'product_name': item.productName,
            'sku': item.sku,
            'barcode': item.barcode,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'tax_rate': item.taxRate,
            'tax_amount': item.unitPrice * item.quantity * (item.taxRate / 100),
            'total_amount':
                item.unitPrice * item.quantity * (1 + item.taxRate / 100),
            'created_at': now.toIso8601String(),
          };
          await _dbHelper.insertQuotationItem(itemData);
        }

        // Show success
        if (mounted) {
          _showQuotationSuccessDialog(quotationId);
        }
      } else {
        // Insert sale
        final saleData = {
          'tenant_id': 'default',
          'sale_number': _invoiceNumber,
          'customer_id': _selectedCustomerId,
          'customer_name': _customerNameController.text.isEmpty
              ? null
              : _customerNameController.text,
          'customer_phone': _customerPhoneController.text.isEmpty
              ? null
              : _customerPhoneController.text,
          'subtotal': _subtotal,
          'tax_amount': _totalTax,
          'discount_amount': _discount,
          'total_amount': _grandTotal,
          'paid_amount': _paidAmount,
          'due_amount': _dueAmount,
          'change_amount': _changeAmount,
          'payment_method': _paymentMethod,
          'payment_status': _paymentStatus,
          'notes': _notesController.text.isEmpty ? null : _notesController.text,
          'status': 'completed',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final saleId = await _dbHelper.insertSale(saleData);

        // Insert sale items and DECREASE stock
        for (var item in _cartItems) {
          final itemData = {
            'sale_id': saleId,
            'product_id': item.productId,
            'product_name': item.productName,
            'sku': item.sku,
            'barcode': item.barcode,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'tax_rate': item.taxRate,
            'tax_amount': item.unitPrice * item.quantity * (item.taxRate / 100),
            'total_amount':
                item.unitPrice * item.quantity * (1 + item.taxRate / 100),
            'created_at': now.toIso8601String(),
          };
          await _dbHelper.insertSaleItem(itemData);

          // Update quantity:
          // - product: decrease remaining stock
          // - service: increase sold counter
          final product = await _dbHelper
              .query('products', where: 'id = ?', whereArgs: [item.productId]);
          if (product.isNotEmpty) {
            final currentStock = product.first['stock_quantity'] as int;
            final productType =
                (product.first['product_type'] as String?)?.toLowerCase() ??
                    'product';
            final isService = productType == 'service';
            await _dbHelper.update(
                'products',
                {
                  'stock_quantity': isService
                      ? currentStock + item.quantity
                      : currentStock - item.quantity,
                  'updated_at': now.toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [item.productId]);
          }
        }

        // Show success and print receipt
        if (mounted) {
          _showSuccessDialog(saleId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showQuotationSuccessDialog(int quotationId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.purple.shade600, size: 32),
            const SizedBox(width: 12),
            Text('Quotation Created!', style: TextStyle(color: Colors.purple.shade600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quotation #: $_invoiceNumber',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total: ₹${_grandTotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            const Text('Type: Sales Quotation', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Valid for 30 days',
                style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('No stock changes applied.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              await _generateQuotationPdf(quotationId);
            },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _resetBilling();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Quotation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateQuotationPdf(int quotationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopName = prefs.getString('shop_name') ?? 'My Shop';
      final address = prefs.getString('address') ?? '';
      final phone = prefs.getString('phone') ?? '';
      final gstin = prefs.getString('gstin') ?? '';
      final branchName = prefs.getString('selected_branch_name') ?? '';
      final currencySymbol = prefs.getString('currency_symbol') ?? '₹';

      // Load Unicode font for rupee symbol support
      final fontData = await PdfGoogleFonts.notoSansRegular();
      final fontBoldData = await PdfGoogleFonts.notoSansBold();
      final fontItalicData = await PdfGoogleFonts.notoSansItalic();
      
      final pdf = pw.Document();
      final baseStyle = pw.TextStyle(font: fontData);
      final boldStyle = pw.TextStyle(font: fontBoldData, fontWeight: pw.FontWeight.bold);
      final italicStyle = pw.TextStyle(font: fontItalicData, fontStyle: pw.FontStyle.italic);

      // Build PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        shopName,
                        style: pw.TextStyle(
                          font: fontBoldData,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (branchName.isNotEmpty)
                        pw.Text(branchName, style: pw.TextStyle(font: fontData, fontSize: 12)),
                      if (address.isNotEmpty)
                        pw.Text(address, style: pw.TextStyle(font: fontData, fontSize: 10)),
                      if (phone.isNotEmpty)
                        pw.Text('Phone: $phone', style: pw.TextStyle(font: fontData, fontSize: 10)),
                      if (gstin.isNotEmpty)
                        pw.Text('GSTIN: $gstin', style: pw.TextStyle(font: fontData, fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // Quotation details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SALES QUOTATION',
                          style: pw.TextStyle(font: fontBoldData, fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Quotation #: $_invoiceNumber', style: baseStyle),
                        pw.Text('Date: ${DateFormat('dd-MMM-yyyy').format(_invoiceDate)}', style: baseStyle),
                        pw.Text('Valid Until: ${DateFormat('dd-MMM-yyyy').format(_invoiceDate.add(const Duration(days: 30)))}', style: baseStyle),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (_customerNameController.text.isNotEmpty) ...[
                          pw.Text('Customer:', style: boldStyle),
                          pw.Text(_customerNameController.text, style: baseStyle),
                          if (_customerPhoneController.text.isNotEmpty)
                            pw.Text(_customerPhoneController.text, style: baseStyle),
                        ],
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Items table
                pw.TableHelper.fromTextArray(
                  headerStyle: boldStyle,
                  cellStyle: baseStyle,
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellPadding: const pw.EdgeInsets.all(6),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                  headers: ['Item', 'Qty', 'Rate', 'Tax %', 'Amount'],
                  data: _cartItems.map((item) {
                    final amount = item.unitPrice * item.quantity * (1 + item.taxRate / 100);
                    return [
                      item.productName,
                      item.quantity.toString(),
                      '$currencySymbol${item.unitPrice.toStringAsFixed(2)}',
                      '${item.taxRate.toStringAsFixed(1)}%',
                      '$currencySymbol${amount.toStringAsFixed(2)}',
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 20),

                // Totals
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildQuotationTotalRow('Subtotal:', '$currencySymbol${_subtotal.toStringAsFixed(2)}', fontData, fontBoldData),
                      _buildQuotationTotalRow('Tax:', '$currencySymbol${_totalTax.toStringAsFixed(2)}', fontData, fontBoldData),
                      if (_discount > 0)
                        _buildQuotationTotalRow('Discount:', '-$currencySymbol${_discount.toStringAsFixed(2)}', fontData, fontBoldData),
                      pw.Divider(),
                      _buildQuotationTotalRow(
                        'Grand Total:',
                        '$currencySymbol${_grandTotal.toStringAsFixed(2)}',
                        fontData,
                        fontBoldData,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Notes
                if (_notesController.text.isNotEmpty) ...[
                  pw.Text('Notes:', style: boldStyle),
                  pw.Text(_notesController.text, style: baseStyle),
                  pw.SizedBox(height: 20),
                ],

                // Terms
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Terms & Conditions:', style: boldStyle),
                      pw.SizedBox(height: 5),
                      pw.Text('1. This quotation is valid for 30 days from the date of issue.', style: baseStyle),
                      pw.Text('2. Prices are subject to change without prior notice.', style: baseStyle),
                      pw.Text('3. This is a computer-generated quotation.', style: baseStyle),
                    ],
                  ),
                ),

                // Footer
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your interest!',
                    style: italicStyle,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF directly to file
      final pdfBytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final quotationsDir = Directory(p.join(directory.path, 'BillEase', 'Quotations'));
      if (!await quotationsDir.exists()) {
        await quotationsDir.create(recursive: true);
      }
      
      final fileName = 'Quotation_${_invoiceNumber.replaceAll('/', '-')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = p.join(quotationsDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      
      // Open the PDF file
      if (Platform.isWindows) {
        await Process.run('explorer', [filePath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved: $fileName'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Open Folder',
            textColor: Colors.white,
            onPressed: () async {
              if (Platform.isWindows) {
                await Process.run('explorer', [quotationsDir.path]);
              }
            },
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(int saleId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Sale Completed!', style: TextStyle(color: Colors.green)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: $_invoiceNumber',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total: ₹${_grandTotal.toStringAsFixed(2)}'),
            if (_paymentStatus != 'paid') ...[
              const SizedBox(height: 4),
              Text('Due Amount: ₹${_dueAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ],
            if (_changeAmount > 0) ...[
              const SizedBox(height: 4),
              Text('Change: ₹${_changeAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green)),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              await _printReceipt(saleId);
            },
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await _generatePdfReceipt(saleId, isPurchase: false);
            },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _resetBilling();
            },
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('New Bill'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(int saleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paperSize = prefs.getString('paperSize') ?? '80mm';
      final templateType = prefs.getString('receiptTemplate') ?? 'standard';
      final shopName = prefs.getString('shopName') ?? 'BillEase POS';
      final address = prefs.getString('address') ?? '';
      final phone = prefs.getString('phone') ?? '';
      final gstin = prefs.getString('gstin') ?? '';
      final branchName = prefs.getString('selectedBranchName') ?? '';
      final currencySymbol = prefs.getString('currencySymbol') ?? '₹';
      final printSku = prefs.getBool('printSkuOnReceipt') ?? false;
      final printBarcode = prefs.getBool('printBarcodeOnReceipt') ?? false;

      int paperWidth;
      switch (paperSize) {
        case '58mm':
          paperWidth = ReceiptGenerator.PAPER_58MM;
          break;
        case 'A4':
          paperWidth = ReceiptGenerator.PAPER_A4;
          break;
        case '80mm':
        default:
          paperWidth = ReceiptGenerator.PAPER_80MM;
      }

      final receiptData = {
        'shopName': shopName,
        'branchName': branchName,
        'address': address,
        'phone': phone,
        'gstin': gstin,
        'receiptNo': _invoiceNumber,
        'date': DateFormat('dd-MMM-yyyy').format(_invoiceDate),
        'time': DateFormat('hh:mm a').format(_invoiceDate),
        'customerName': _customerNameController.text,
        'customerPhone': _customerPhoneController.text,
        'currencySymbol': currencySymbol,
        'items': _cartItems
            .map((item) => {
                  'name': item.productName,
                  'sku': item.sku,
                  'barcode': item.barcode,
                  'quantity': item.quantity,
                  'rate': item.unitPrice,
                  'taxRate': item.taxRate,
                  'taxAmount':
                      item.unitPrice * item.quantity * (item.taxRate / 100),
                  'amount':
                      item.unitPrice * item.quantity * (1 + item.taxRate / 100),
                })
            .toList(),
        'subtotal': _subtotal,
        'totalTax': _totalTax,
        'discount': _discount,
        'grandTotal': _grandTotal,
        'paymentMode': _paymentMethod,
        'amountPaid': _paidAmount,
        'changeAmount': _changeAmount > 0 ? _changeAmount : null,
        'dueAmount': _dueAmount > 0 ? _dueAmount : null,
        'paymentStatus': _paymentStatus,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      final receiptText = ReceiptGenerator.generateReceipt(
        templateType: templateType,
        paperSize: paperWidth,
        data: receiptData,
        printSku: printSku,
        printBarcode: printBarcode,
      );

      // Save to file in executable directory
      // Sanitize invoice number for safe filename (replace / with _)
      final safeInvoiceNumber = _invoiceNumber.replaceAll('/', '_');

      String receiptPath;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // For desktop, use executable directory
        final exePath = Platform.resolvedExecutable;
        final exeDir = File(exePath).parent.path;
        final receiptsDir = Directory(p.join(exeDir, 'receipts'));

        // Create receipts directory if it doesn't exist
        if (!await receiptsDir.exists()) {
          await receiptsDir.create(recursive: true);
        }

        receiptPath =
            p.join(receiptsDir.path, 'receipt_$safeInvoiceNumber.txt');
      } else {
        // For mobile, use application documents directory
        final directory = await getApplicationDocumentsDirectory();
        receiptPath =
            p.join(directory.path, 'receipt_$safeInvoiceNumber.txt');
      }

      final file = File(receiptPath);
      await file.writeAsString(receiptText);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt saved: ${file.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: () async {
              if (Platform.isWindows) {
                await Process.run('notepad.exe', [file.path]);
              } else if (Platform.isMacOS) {
                await Process.run('open', ['-a', 'TextEdit', file.path]);
              } else if (Platform.isLinux) {
                await Process.run('xdg-open', [file.path]);
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error printing: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _generatePdfReceipt(int transactionId, {required bool isPurchase}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopName = prefs.getString('shopName') ?? 'BillEase POS';
      final address = prefs.getString('address') ?? '';
      final phone = prefs.getString('phone') ?? '';
      final gstin = prefs.getString('gstin') ?? '';
      final branchName = prefs.getString('selectedBranchName') ?? '';
      final currencySymbol = prefs.getString('currencySymbol') ?? '₹';

      final pdf = pw.Document();

      // Build PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        shopName,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (branchName.isNotEmpty)
                        pw.Text(branchName, style: const pw.TextStyle(fontSize: 12)),
                      if (address.isNotEmpty)
                        pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
                      if (phone.isNotEmpty)
                        pw.Text('Phone: $phone', style: const pw.TextStyle(fontSize: 10)),
                      if (gstin.isNotEmpty)
                        pw.Text('GSTIN: $gstin', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // Invoice details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isPurchase ? 'PURCHASE INVOICE' : 'SALES INVOICE',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Invoice #: $_invoiceNumber'),
                        pw.Text('Date: ${DateFormat('dd-MMM-yyyy').format(_invoiceDate)}'),
                        pw.Text('Time: ${DateFormat('hh:mm a').format(_invoiceDate)}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (!isPurchase && _customerNameController.text.isNotEmpty) ...[
                          pw.Text('Customer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(_customerNameController.text),
                          if (_customerPhoneController.text.isNotEmpty)
                            pw.Text(_customerPhoneController.text),
                        ],
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Items table
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellPadding: const pw.EdgeInsets.all(6),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                  headers: ['Item', 'Qty', 'Rate', 'Tax %', 'Amount'],
                  data: _cartItems.map((item) {
                    final amount = item.unitPrice * item.quantity * (1 + item.taxRate / 100);
                    return [
                      item.productName,
                      item.quantity.toString(),
                      '$currencySymbol${item.unitPrice.toStringAsFixed(2)}',
                      '${item.taxRate.toStringAsFixed(1)}%',
                      '$currencySymbol${amount.toStringAsFixed(2)}',
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 20),

                // Totals
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildPdfTotalRow('Subtotal:', '$currencySymbol${_subtotal.toStringAsFixed(2)}'),
                      _buildPdfTotalRow('Tax:', '$currencySymbol${_totalTax.toStringAsFixed(2)}'),
                      if (_discount > 0)
                        _buildPdfTotalRow('Discount:', '-$currencySymbol${_discount.toStringAsFixed(2)}'),
                      pw.Divider(),
                      _buildPdfTotalRow(
                        'Grand Total:',
                        '$currencySymbol${_grandTotal.toStringAsFixed(2)}',
                        isBold: true,
                      ),
                      pw.SizedBox(height: 10),
                      _buildPdfTotalRow('Payment Method:', _paymentMethod),
                      _buildPdfTotalRow('Amount Paid:', '$currencySymbol${_paidAmount.toStringAsFixed(2)}'),
                      if (_changeAmount > 0)
                        _buildPdfTotalRow('Change:', '$currencySymbol${_changeAmount.toStringAsFixed(2)}'),
                      if (_dueAmount > 0)
                        _buildPdfTotalRow('Due Amount:', '$currencySymbol${_dueAmount.toStringAsFixed(2)}', isRed: true),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Notes
                if (_notesController.text.isNotEmpty) ...[
                  pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(_notesController.text),
                  pw.SizedBox(height: 20),
                ],

                // Footer
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Show print/share dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${isPurchase ? 'Purchase' : 'Invoice'}_$_invoiceNumber',
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Widget _buildPdfTotalRow(String label, String value, {bool isBold = false, bool isRed = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isRed ? PdfColors.red : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildQuotationTotalRow(String label, String value, pw.Font font, pw.Font boldFont, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: isBold ? boldFont : font,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: isBold ? boldFont : font,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _resetBilling() {
    setState(() {
      _cartItems.clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _paidAmountController.clear();
      _notesController.clear();
      _paymentStatus = 'paid';
      _paymentMethod = 'Cash';
      _discount = 0.0;
      _selectedCustomerId = null;
      _showCustomerDropdown = false;
      _calculateTotals();
    });
    _loadData(); // Generate new invoice number
    
    // Return focus to search for next transaction
    Future.delayed(const Duration(milliseconds: 100), () {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      // Left Panel - Product Search & Filters (25%)
                      SizedBox(
                        width: constraints.maxWidth * 0.25,
                        child: _buildSearchPanel(),
                      ),

                      // Center Panel - Products Grid (45%)
                      Expanded(
                        child: _buildProductsPanel(constraints),
                      ),

                      // Right Panel - Cart & Billing (30%)
                      SizedBox(
                        width: constraints.maxWidth * 0.30,
                        child: _buildBillingPanel(),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.point_of_sale, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Point of Sale',
              style:
                  TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ],
      ),
      backgroundColor: const Color(0xFF1E293B),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Keyboard shortcuts hint
        PopupMenuButton<String>(
          icon: const Icon(Icons.keyboard, color: Colors.white70, size: 20),
          tooltip: 'Keyboard Shortcuts',
          itemBuilder: (context) => [
            const PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Keyboard Shortcuts',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Divider(),
                  Text('Enter - Add first product', style: TextStyle(fontSize: 12)),
                  Text('F1-F4 - Payment methods', style: TextStyle(fontSize: 12)),
                  Text('Ctrl+Enter - Complete sale', style: TextStyle(fontSize: 12)),
                  Text('Ctrl+N - New bill', style: TextStyle(fontSize: 12)),
                  Text('Ctrl+F - Focus search', style: TextStyle(fontSize: 12)),
                  Text('Ctrl+P - Focus payment', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        TextButton.icon(
          icon: const Icon(Icons.history, color: Colors.white70, size: 20),
          label: const Text('History', style: TextStyle(color: Colors.white70)),
          onPressed: () {
            // TODO: Navigate to sales history
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // NEW: Left Panel - Search & Filters
  Widget _buildSearchPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Search',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _filterProducts,
                    onSubmitted: (value) {
                      // Enter key: Add first filtered product to cart
                      if (_filteredProducts.isNotEmpty) {
                        _addToCart(_filteredProducts[0]);
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Type & press Enter to add...',
                      hintStyle:
                          TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.search,
                          color: Color(0xFF64748B), size: 20),
                      suffixIcon: Icon(Icons.keyboard_return,
                          color: Color(0xFF94A3B8), size: 16),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: _buildProductList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No products found',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try a different search',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductListItem(product);
      },
    );
  }

  Widget _buildProductListItem(Map<String, dynamic> product) {
    final stock = product['stock_quantity'] as int;
    final isService = _isServiceItem(product);
    final lowStock = !isService && stock <= (product['low_stock_threshold'] as int);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _addToCart(product),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
          ),
          child: Row(
            children: [
              // Product Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '₹${(product['price'] as num).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: lowStock
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isService ? 'Sold: $stock' : 'Stock: $stock',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: lowStock
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline,
                  size: 20, color: Color(0xFF3B82F6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsPanel(BoxConstraints constraints) {
    final isSmallScreen = constraints.maxWidth < 1200;
    final crossAxisCount = isSmallScreen ? 2 : 3;

    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Products',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '${_filteredProducts.length} items',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Products Grid
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 56,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No products available',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Search or scan a product to get started',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final stock = product['stock_quantity'] as int;
    final isService = _isServiceItem(product);
    final lowStock = !isService && stock <= (product['low_stock_threshold'] as int);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 0,
      child: InkWell(
        onTap: () => _addToCart(product),
        borderRadius: BorderRadius.circular(10),
        hoverColor: const Color(0xFFF0F9FF),
        splashColor: const Color(0xFFDCEDFE),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product['sku'],
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: lowStock
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isService ? 'S:$stock' : '$stock',
                      style: TextStyle(
                        color: lowStock
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${(product['price'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillingPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sale/Quotation Toggle
          _buildSalePurchaseToggle(),
          
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Invoice Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _billingMode == 'quotation'
                                ? [Colors.purple.shade600, Colors.purple.shade400]
                                : [const Color(0xFF1E293B), const Color(0xFF334155)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _billingMode == 'quotation'
                                          ? 'QUOTATION'
                                          : 'INVOICE',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _invoiceNumber,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('dd MMM yyyy').format(_invoiceDate),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  DateFormat('hh:mm a').format(_invoiceDate),
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

          // Customer Section - Collapsible
                  _buildCustomerSection(),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Cart Items Summary
                  Container(
                    constraints: const BoxConstraints(minHeight: 200, maxHeight: 300),
                    child: _cartItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 56,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Cart is empty',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Add products to start billing',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _cartItems.length,
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              return _buildCartItem(item, index);
                            },
                          ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Totals Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: const Color(0xFFF8FAFC),
                    child: Column(
                      children: [
                        _buildTotalRow('Subtotal', _subtotal, false),
                        const SizedBox(height: 8),
                        _buildTotalRow('Tax', _totalTax, false),
                        if (_discount > 0) ...[
                          const SizedBox(height: 8),
                          _buildTotalRow('Discount', -_discount, false),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                '₹${_grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Payment Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Method - Segmented Buttons
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPaymentMethodSelector(),
                        const SizedBox(height: 16),

                        // Payment Status - Segmented Buttons
                        const Text(
                          'Payment Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPaymentStatusSelector(),

                        if (_paymentStatus != 'credit') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _paidAmountController,
                            focusNode: _paidAmountFocusNode,
                            decoration: InputDecoration(
                              labelText: _paymentStatus == 'paid'
                                  ? 'Amount Paid'
                                  : 'Partial Amount',
                              labelStyle: const TextStyle(fontSize: 13),
                              prefixIcon: const Icon(Icons.currency_rupee,
                                  color: Color(0xFF64748B), size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Color(0xFF3B82F6), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (value) {
                              setState(() => _calculateTotals());
                            },
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],

                        if (_dueAmount > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Due Amount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                Text(
                                  '₹${_dueAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_changeAmount > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Change to Return',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                Text(
                                  '₹${_changeAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 80), // Space for fixed footer
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed Footer - Complete Action Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                focusNode: _completeSaleFocusNode,
                onPressed: _cartItems.isEmpty ? null : _completeSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _billingMode == 'quotation'
                          ? Colors.purple.shade600
                          : const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _billingMode == 'quotation'
                              ? 'Create Quotation'
                              : 'Complete Sale',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Ctrl+↵',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return ExpansionTile(
      title: const Text(
        'Customer Details',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
      subtitle: _customerNameController.text.isNotEmpty
          ? Text(
              _customerNameController.text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            )
          : null,
      leading:
          const Icon(Icons.person_outline, size: 20, color: Color(0xFF64748B)),
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            TextField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: 'Customer Name (Optional)',
                labelStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.person_outline,
                    color: Color(0xFF64748B), size: 18),
                suffixIcon: _selectedCustomerId != null
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Color(0xFF94A3B8), size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedCustomerId = null;
                            _customerNameController.clear();
                            _customerPhoneController.clear();
                            _showCustomerDropdown = false;
                          });
                        },
                      )
                    : const Icon(Icons.arrow_drop_down, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (value) {
                setState(() {
                  _showCustomerDropdown = value.isNotEmpty;
                  _filteredCustomers = _customers.where((customer) {
                    final name =
                        customer['name']?.toString().toLowerCase() ?? '';
                    final phone =
                        customer['phone']?.toString().toLowerCase() ?? '';
                    final query = value.toLowerCase();
                    return name.contains(query) || phone.contains(query);
                  }).toList();
                });
              },
              onTap: () {
                setState(() {
                  _showCustomerDropdown = true;
                  _filteredCustomers = _customers;
                });
              },
            ),
            if (_showCustomerDropdown && _filteredCustomers.isNotEmpty)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return InkWell(
                          onTap: () {
                            final customerId = customer['id'];
                            final customerName = customer['name'] ?? '';
                            final customerPhone = customer['phone'] ?? '';
                            setState(() {
                              _selectedCustomerId = customerId;
                              _customerNameController.text = customerName;
                              _customerPhoneController.text = customerPhone;
                              _showCustomerDropdown = false;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFDCEDFE),
                                  child: Text(
                                    (customer['name'] ?? 'C')[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        customer['name'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      if (customer['phone'] != null && customer['phone'].toString().isNotEmpty)
                                        Text(
                                          customer['phone'].toString(),
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                    ],
                                  ),
                                ),
                                if (customer['loyalty_points'] != null &&
                                    customer['loyalty_points'] > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star,
                                            size: 12, color: Color(0xFFF59E0B)),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${customer['loyalty_points']}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Add extra spacing when dropdown is visible to prevent overlap
        SizedBox(height: _showCustomerDropdown && _filteredCustomers.isNotEmpty ? 212 : 12),
        TextField(
          controller: _customerPhoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number (Optional)',
            labelStyle: const TextStyle(fontSize: 12),
            prefixIcon: const Icon(Icons.phone_outlined,
                color: Color(0xFF64748B), size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
          keyboardType: TextInputType.phone,
          enabled: _selectedCustomerId == null,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSalePurchaseToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          const Text(
            'Mode:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_billingMode != 'sale' && _cartItems.isEmpty) {
                          setState(() => _billingMode = 'sale');
                          _loadData();
                        } else if (_billingMode != 'sale' && _cartItems.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Clear cart before switching mode'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _billingMode == 'sale'
                              ? const Color(0xFF3B82F6)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(7),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sell_rounded,
                              size: 14,
                              color: _billingMode == 'sale'
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sale',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _billingMode == 'sale'
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_billingMode != 'quotation' && _cartItems.isEmpty) {
                          setState(() => _billingMode = 'quotation');
                          _loadData();
                        } else if (_billingMode != 'quotation' && _cartItems.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Clear cart before switching mode'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _billingMode == 'quotation'
                              ? Colors.purple.shade600
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(7),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.request_quote_rounded,
                              size: 14,
                              color: _billingMode == 'quotation'
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Quotation',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _billingMode == 'quotation'
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildPaymentMethodSelector() {
    final methods = [
      {'label': 'Cash', 'icon': Icons.payments_outlined},
      {'label': 'Card', 'icon': Icons.credit_card},
      {'label': 'UPI', 'icon': Icons.qr_code_2},
      {'label': 'Wallet', 'icon': Icons.account_balance_wallet_outlined},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: methods.map((method) {
          final isSelected = _paymentMethod == method['label'];
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    setState(() => _paymentMethod = method['label'] as String),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        method['icon'] as IconData,
                        size: 20,
                        color:
                            isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentStatusSelector() {
    final statuses = [
      {'label': 'Full', 'value': 'paid', 'color': Color(0xFF16A34A)},
      {'label': 'Partial', 'value': 'partial', 'color': Color(0xFFF59E0B)},
      {'label': 'Credit', 'value': 'credit', 'color': Color(0xFFDC2626)},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: statuses.map((status) {
          final isSelected = _paymentStatus == status['value'];
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _paymentStatus = status['value'] as String;
                    if (_paymentStatus == 'paid') {
                      _paidAmountController.text =
                          _grandTotal.toStringAsFixed(2);
                    } else if (_paymentStatus == 'credit') {
                      _paidAmountController.text = '0';
                    } else {
                      _paidAmountController.clear();
                    }
                    _calculateTotals();
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? status['color'] as Color
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    final itemTotal = item.unitPrice * item.quantity * (1 + item.taxRate / 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.sku.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'SKU: ${item.sku}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon:
                    const Icon(Icons.close, color: Color(0xFFEF4444), size: 18),
                onPressed: () => _removeFromCart(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Price and Quantity Row - Editable
          Row(
            children: [
              // Price Field
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _showEditPriceDialog(index, item.unitPrice),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '\u20b9',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.unitPrice.toStringAsFixed(2),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const Icon(Icons.edit, size: 12, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Quantity Controls
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _updateCartItemQuantity(index, item.quantity - 1),
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(6)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: const Icon(Icons.remove,
                                size: 14, color: Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showEditQuantityDialog(index, item.quantity),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(color: Color(0xFFE2E8F0)),
                                right: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _updateCartItemQuantity(index, item.quantity + 1),
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(6)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: const Icon(Icons.add,
                                size: 14, color: Color(0xFF3B82F6)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\u20b9${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}' +
                    (item.taxRate > 0 ? ' + ${item.taxRate.toStringAsFixed(1)}% tax' : ''),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
              Text(
                '\u20b9${itemTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditPriceDialog(int index, double currentPrice) {
    final controller = TextEditingController(text: currentPrice.toStringAsFixed(2));
    final taxRate = _cartItems[index].taxRate;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Price'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Unit Price',
            prefixText: '\u20b9 ',
            helperText: 'Enter -amount to treat it as tax-inclusive final amount',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final newPrice = _parseEditedUnitPrice(
              input: value,
              taxRate: taxRate,
            );
            if (newPrice != null && newPrice >= 0) {
              _updateCartItemPrice(index, newPrice);
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = _parseEditedUnitPrice(
                input: controller.text,
                taxRate: taxRate,
              );
              if (newPrice != null && newPrice >= 0) {
                _updateCartItemPrice(index, newPrice);
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEditQuantityDialog(int index, int currentQty) {
    final controller = TextEditingController(text: currentQty.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final newQty = int.tryParse(value);
            if (newQty != null) {
              _updateCartItemQuantity(index, newQty);
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text);
              if (newQty != null) {
                _updateCartItemQuantity(index, newQty);
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isGrandTotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isGrandTotal ? 14 : 13,
              fontWeight: isGrandTotal ? FontWeight.w600 : FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            '₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isGrandTotal ? 16 : 14,
              fontWeight: isGrandTotal ? FontWeight.w700 : FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    _searchFocusNode.dispose();
    _paidAmountFocusNode.dispose();
    _completeSaleFocusNode.dispose();
    super.dispose();
  }
}

class CartItem {
  final int productId;
  final String productName;
  final String sku;
  final String? barcode;
  double unitPrice;
  int quantity;
  final double taxRate;
  final bool isService;

  CartItem({
    required this.productId,
    required this.productName,
    required this.sku,
    this.barcode,
    required this.unitPrice,
    required this.quantity,
    required this.taxRate,
    this.isService = false,
  });
}
