import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/receipt_generator.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  _SalesHistoryScreenState createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Sales data
  List<Map<String, dynamic>> sales = [];
  List<Map<String, dynamic>> filteredSales = [];
  List<Map<String, dynamic>> customers = [];
  bool isLoading = true;
  String searchQuery = '';
  String filterStatus = 'all'; // all, paid, credit, partial
  int? selectedCustomerId;
  String? selectedCustomerName;
  DateTimeRange? dateRange;
  
  // Quotation data
  List<Map<String, dynamic>> quotations = [];
  List<Map<String, dynamic>> filteredQuotations = [];
  bool isQuotationLoading = true;
  String quotationSearchQuery = '';
  String quotationFilterType = 'all'; // all, sale
  DateTimeRange? quotationDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadDataForTab(_tabController.index);
      }
    });
    _loadCustomers();
    _loadSales();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _loadDataForTab(int index) {
    switch (index) {
      case 0:
        if (sales.isEmpty) _loadSales();
        break;
      case 1:
        if (quotations.isEmpty) _loadQuotations();
        break;
    }
  }
  
  Future<void> _loadCustomers() async {
    try {
      final db = DatabaseHelper.instance;
      customers = await db.getAllCustomers();
      setState(() {});
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadSales() async {
    setState(() => isLoading = true);
    try {
      final db = DatabaseHelper.instance;
      sales = await db.getAllSales();
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sales: $e')),
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
      filteredSales = sales.where((sale) {
        // Search filter
        final invoiceNumber = sale['invoice_number']?.toString() ?? '';
        final customerName = sale['customer_name']?.toString() ?? '';
        final matchesSearch = searchQuery.isEmpty ||
            invoiceNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
            customerName.toLowerCase().contains(searchQuery.toLowerCase());

        // Status filter
        final paymentStatus = sale['payment_status']?.toString() ?? '';
        final matchesStatus = filterStatus == 'all' || paymentStatus == filterStatus;

        // Customer filter
        final matchesCustomer = selectedCustomerId == null || sale['customer_id'] == selectedCustomerId;

        // Date range filter
        final createdAt = sale['created_at']?.toString();
        final matchesDate = dateRange == null ||
            (createdAt != null &&
                DateTime.parse(createdAt).isAfter(dateRange!.start) &&
                DateTime.parse(createdAt).isBefore(dateRange!.end.add(const Duration(days: 1))));

        return matchesSearch && matchesStatus && matchesCustomer && matchesDate;
      }).toList();

      // Sort by date descending
      filteredSales.sort((a, b) {
        final dateA = a['created_at']?.toString();
        final dateB = b['created_at']?.toString();
        if (dateA == null || dateB == null) return 0;
        return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
      });
    });
  }

  // ===== QUOTATION METHODS =====
  Future<void> _loadQuotations() async {
    setState(() => isQuotationLoading = true);
    try {
      final db = DatabaseHelper.instance;
      quotations = await db.getAllQuotations();
      _applyQuotationFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quotations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isQuotationLoading = false);
      }
    }
  }

  void _applyQuotationFilters() {
    setState(() {
      filteredQuotations = quotations.where((quotation) {
        final quotationNumber = quotation['quotation_number']?.toString() ?? '';
        final customerName = quotation['customer_name']?.toString() ?? '';
        final matchesSearch = quotationSearchQuery.isEmpty ||
            quotationNumber.toLowerCase().contains(quotationSearchQuery.toLowerCase()) ||
            customerName.toLowerCase().contains(quotationSearchQuery.toLowerCase());

        final quotationType = quotation['quotation_type']?.toString() ?? '';
        final matchesType = quotationFilterType == 'all'
            ? quotationType == 'sale'
            : quotationType == quotationFilterType;

        final createdAt = quotation['created_at']?.toString();
        final matchesDate = quotationDateRange == null ||
            (createdAt != null &&
                DateTime.parse(createdAt).isAfter(quotationDateRange!.start) &&
                DateTime.parse(createdAt).isBefore(quotationDateRange!.end.add(const Duration(days: 1))));

        return matchesSearch && matchesType && matchesDate;
      }).toList();

      filteredQuotations.sort((a, b) {
        final dateA = a['created_at']?.toString();
        final dateB = b['created_at']?.toString();
        if (dateA == null || dateB == null) return 0;
        return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
      });
    });
  }

  Future<void> _deleteQuotation(int id) async {
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
        content: const Text('Are you sure you want to delete this quotation?'),
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
        await DatabaseHelper.instance.deleteQuotation(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation deleted successfully')),
        );
        _loadQuotations();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting quotation: $e')),
        );
      }
    }
  }

  Future<void> _viewQuotationDetails(Map<String, dynamic> quotation) async {
    final items = await DatabaseHelper.instance.getQuotationItems(quotation['id']);
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quotation: ${quotation['quotation_number'] ?? 'N/A'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', 'SALE'),
              _buildDetailRow('Customer', quotation['customer_name']?.toString() ?? 'N/A'),
              _buildDetailRow('Date', quotation['created_at'] != null ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(quotation['created_at'])) : 'N/A'),
              _buildDetailRow('Valid Until', quotation['valid_until'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(quotation['valid_until'])) : 'N/A'),
              _buildDetailRow('Status', (quotation['status']?.toString() ?? 'pending').toUpperCase()),
              const Divider(),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${item['product_name'] ?? 'Unknown'} x${item['quantity'] ?? 0} = ₹${(item['total_amount'] ?? 0.0).toStringAsFixed(2)}'),
              )),
              const Divider(),
              _buildDetailRow('Subtotal', '₹${(quotation['subtotal'] ?? 0.0).toStringAsFixed(2)}'),
              _buildDetailRow('Tax', '₹${(quotation['tax_amount'] ?? 0.0).toStringAsFixed(2)}'),
              if ((quotation['discount_amount'] ?? 0.0) > 0)
                _buildDetailRow('Discount', '₹${(quotation['discount_amount'] ?? 0.0).toStringAsFixed(2)}'),
              _buildDetailRow('Total', '₹${(quotation['total_amount'] ?? 0.0).toStringAsFixed(2)}', isBold: true),
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
              _generateQuotationPdf(quotation, items);
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
          ),
          if (quotation['status'] == 'pending')
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _convertQuotation(quotation);
              },
              icon: const Icon(Icons.transform),
              label: const Text('Convert'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
        ],
      ),
    );
  }

  Future<void> _convertQuotation(Map<String, dynamic> quotation) async {
    final type = 'Sale';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Convert to $type'),
        content: Text('This will convert the quotation to an actual $type transaction. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Convert'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.convertQuotationToSale(quotation['id']);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation converted to Sale successfully!')),
        );
        _loadQuotations();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error converting quotation: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateQuotationPdf(Map<String, dynamic> quotation, List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopName = prefs.getString('shop_name') ?? 'My Shop';
      final address = prefs.getString('address') ?? '';
      final phone = prefs.getString('phone') ?? '';
      final gstin = prefs.getString('gstin') ?? '';
      final currencySymbol = prefs.getString('currency_symbol') ?? '₹';

      final fontData = await PdfGoogleFonts.notoSansRegular();
      final fontBoldData = await PdfGoogleFonts.notoSansBold();
      final fontItalicData = await PdfGoogleFonts.notoSansItalic();
      
      final pdf = pw.Document();
      final baseStyle = pw.TextStyle(font: fontData);
      final boldStyle = pw.TextStyle(font: fontBoldData, fontWeight: pw.FontWeight.bold);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(shopName, style: pw.TextStyle(font: fontBoldData, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      if (address.isNotEmpty) pw.Text(address, style: pw.TextStyle(font: fontData, fontSize: 10)),
                      if (phone.isNotEmpty) pw.Text('Phone: $phone', style: pw.TextStyle(font: fontData, fontSize: 10)),
                      if (gstin.isNotEmpty) pw.Text('GSTIN: $gstin', style: pw.TextStyle(font: fontData, fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'SALES QUOTATION',
                  style: pw.TextStyle(font: fontBoldData, fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Quotation #: ${quotation['quotation_number']}', style: baseStyle),
                pw.Text('Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(quotation['created_at']))}', style: baseStyle),
                if (quotation['valid_until'] != null)
                  pw.Text('Valid Until: ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(quotation['valid_until']))}', style: baseStyle),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headerStyle: boldStyle,
                  cellStyle: baseStyle,
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellPadding: const pw.EdgeInsets.all(6),
                  headers: ['Item', 'Qty', 'Rate', 'Amount'],
                  data: items.map((item) => [
                    item['product_name'] ?? 'Unknown',
                    item['quantity'].toString(),
                    '$currencySymbol${(item['unit_price'] ?? 0.0).toStringAsFixed(2)}',
                    '$currencySymbol${(item['total_amount'] ?? 0.0).toStringAsFixed(2)}',
                  ]).toList(),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: $currencySymbol${(quotation['subtotal'] ?? 0.0).toStringAsFixed(2)}', style: baseStyle),
                      pw.Text('Tax: $currencySymbol${(quotation['tax_amount'] ?? 0.0).toStringAsFixed(2)}', style: baseStyle),
                      pw.SizedBox(height: 5),
                      pw.Text('Grand Total: $currencySymbol${(quotation['total_amount'] ?? 0.0).toStringAsFixed(2)}', style: boldStyle),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Center(
                  child: pw.Text('Thank you for your interest!', style: pw.TextStyle(font: fontItalicData, fontStyle: pw.FontStyle.italic)),
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final quotationsDir = Directory(p.join(directory.path, 'BillEase', 'Quotations'));
      if (!await quotationsDir.exists()) {
        await quotationsDir.create(recursive: true);
      }
      
      final fileName = 'Quotation_${quotation['quotation_number'].toString().replaceAll('/', '-')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = p.join(quotationsDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      
      if (Platform.isWindows) {
        await Process.run('explorer', [filePath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved: $fileName'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteSale(int id) async {
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
        content: const Text('Are you sure you want to delete this sale? This action cannot be undone.'),
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
        await DatabaseHelper.instance.deleteSale(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale deleted successfully')),
        );
        _loadSales();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting sale: $e')),
        );
      }
    }
  }

  Future<void> _viewSaleDetails(Map<String, dynamic> sale) async {
    final items = await DatabaseHelper.instance.getSaleItems(sale['id']);
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice: ${sale['invoice_number'] ?? 'N/A'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer', sale['customer_name']?.toString() ?? 'N/A'),
              _buildDetailRow('Date', sale['created_at'] != null ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(sale['created_at'])) : 'N/A'),
              _buildDetailRow('Payment Status', (sale['payment_status']?.toString() ?? 'unknown').toUpperCase()),
              _buildDetailRow('Payment Mode', sale['payment_mode']?.toString() ?? 'N/A'),
              const Divider(),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${item['product_name'] ?? 'Unknown'} x${item['quantity'] ?? 0} = ₹${(item['total'] ?? 0.0).toStringAsFixed(2)}'),
              )),
              const Divider(),
              _buildDetailRow('Subtotal', '₹${(sale['subtotal'] ?? 0.0).toStringAsFixed(2)}'),
              _buildDetailRow('Tax', '₹${(sale['tax'] ?? 0.0).toStringAsFixed(2)}'),
              _buildDetailRow('Discount', '₹${(sale['discount'] ?? 0.0).toStringAsFixed(2)}'),
              _buildDetailRow('Total', '₹${(sale['total'] ?? 0.0).toStringAsFixed(2)}', isBold: true),
              if (sale['payment_status'] != 'paid')
                _buildDetailRow('Due Amount', '₹${(sale['due_amount'] ?? 0.0).toStringAsFixed(2)}', isRed: true),
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
              _printSale(sale, items);
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isRed ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printSale(Map<String, dynamic> sale, List<Map<String, dynamic>> items) async {
    try {
      // Show print/PDF options
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Print Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.print, color: Colors.indigo),
                title: const Text('Print Receipt'),
                subtitle: const Text('Print to thermal printer'),
                onTap: () => Navigator.pop(context, 'print'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Generate PDF'),
                subtitle: const Text('Save or print as PDF'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
            ],
          ),
        ),
      );

      if (action == 'print') {
        await _printReceipt(sale, items);
      } else if (action == 'pdf') {
        await _generatePDF(sale, items);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _printReceipt(Map<String, dynamic> sale, List<Map<String, dynamic>> items) async {
    try {
      final receiptData = {
        'shopName': 'BillEase POS',
        'branchName': sale['branch_name']?.toString() ?? '',
        'address': '',
        'phone': '',
        'gstin': '',
        'receiptNo': sale['invoice_number']?.toString() ?? '',
        'date': sale['created_at'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(sale['created_at'])) : '',
        'time': sale['created_at'] != null ? DateFormat('hh:mm a').format(DateTime.parse(sale['created_at'])) : '',
        'cashier': sale['cashier_name']?.toString() ?? 'Staff',
        'customerName': sale['customer_name']?.toString() ?? 'Walk-in Customer',
        'currencySymbol': '₹',
        'items': items.map((item) => {
          'name': item['product_name']?.toString() ?? 'Unknown',
          'sku': item['sku']?.toString() ?? '',
          'barcode': item['barcode']?.toString() ?? '',
          'quantity': item['quantity'] ?? 0,
          'rate': item['rate'] ?? 0.0,
          'amount': item['total'] ?? 0.0,
        }).toList(),
        'subtotal': sale['subtotal'] ?? 0.0,
        'totalTax': sale['tax'] ?? 0.0,
        'discount': sale['discount'] ?? 0.0,
        'grandTotal': sale['total'] ?? 0.0,
        'paymentMode': sale['payment_mode']?.toString() ?? 'CASH',
        'paymentStatus': sale['payment_status']?.toString() ?? 'paid',
        'dueAmount': sale['due_amount'] ?? 0.0,
      };

      final receipt = ReceiptGenerator.generateReceipt(
        templateType: ReceiptGenerator.TEMPLATE_STANDARD,
        paperSize: ReceiptGenerator.PAPER_80MM,
        data: receiptData,
        printSku: true,
        printBarcode: false,
      );

      // Save to file in executable directory
      // Sanitize invoice number for safe filename (replace / with _)
      final safeInvoiceNumber = (sale['invoice_number']?.toString() ?? 'unknown').replaceAll('/', '_');
      
      String receiptPath;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // For desktop, use executable directory
        final exePath = Platform.resolvedExecutable;
        final exeDir = File(exePath).parent.path;
        final receiptsDir = Directory('$exeDir/receipts');
        
        // Create receipts directory if it doesn't exist
        if (!await receiptsDir.exists()) {
          await receiptsDir.create(recursive: true);
        }
        
        receiptPath = '${receiptsDir.path}/receipt_$safeInvoiceNumber.txt';
      } else {
        // For mobile, use temp directory
        final tempDir = await getTemporaryDirectory();
        receiptPath = '${tempDir.path}/receipt_$safeInvoiceNumber.txt';
      }
      
      final file = File(receiptPath);
      await file.writeAsString(receipt);

      // Show in dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Receipt Preview'),
          content: SingleChildScrollView(
            child: Text(receipt, style: const TextStyle(fontFamily: 'Courier New', fontSize: 12)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // In a real app, send to printer
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Receipt saved to: ${file.path}')),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.print),
              label: const Text('Print'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error printing: $e')),
      );
    }
  }

  Future<void> _generatePDF(Map<String, dynamic> sale, List<Map<String, dynamic>> items) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BillEase POS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.Text(sale['branch_name']?.toString() ?? ''),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Invoice: ${sale['invoice_number']?.toString() ?? 'N/A'}'),
                        pw.Text('Date: ${sale['created_at'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(sale['created_at'])) : 'N/A'}'),
                        pw.Text('Time: ${sale['created_at'] != null ? DateFormat('hh:mm a').format(DateTime.parse(sale['created_at'])) : 'N/A'}'),
                      ],
                    ),
                  ],
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text('Bill To: ${sale['customer_name']?.toString() ?? 'Walk-in Customer'}', style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: ['Product', 'Qty', 'Rate', 'Amount'],
                  data: items.map((item) => [
                    item['product_name']?.toString() ?? 'Unknown',
                    (item['quantity'] ?? 0).toString(),
                    '₹${(item['rate'] ?? 0.0).toStringAsFixed(2)}',
                    '₹${(item['total'] ?? 0.0).toStringAsFixed(2)}',
                  ]).toList(),
                ),
                pw.SizedBox(height: 20),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: ₹${(sale['subtotal'] ?? 0.0).toStringAsFixed(2)}'),
                      pw.Text('Tax: ₹${(sale['tax'] ?? 0.0).toStringAsFixed(2)}'),
                      pw.Text('Discount: ₹${(sale['discount'] ?? 0.0).toStringAsFixed(2)}'),
                      pw.Divider(),
                      pw.Text('Total: ₹${(sale['total'] ?? 0.0).toStringAsFixed(2)}', 
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      if (sale['payment_status'] != 'paid')
                        pw.Text('Due: ₹${(sale['due_amount'] ?? 0.0).toStringAsFixed(2)}',
                          style: const pw.TextStyle(color: PdfColors.red)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF3B82F6),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF3B82F6),
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.point_of_sale),
                  text: 'Sales',
                ),
                Tab(
                  icon: Icon(Icons.description),
                  text: 'Quotations',
                ),
              ],
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Sales Tab
                _buildSalesTab(),
                // Quotations Tab
                _buildQuotationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    return Column(
      children: [
        _buildSalesFilterBar(),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredSales.isEmpty
                  ? _buildEmptyState('No sales found')
                  : _buildSalesDataTable(),
        ),
        _buildSalesSummaryBar(),
      ],
    );
  }

  Widget _buildQuotationsTab() {
    return Column(
      children: [
        _buildQuotationsFilterBar(),
        Expanded(
          child: isQuotationLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredQuotations.isEmpty
                  ? _buildEmptyState('No quotations found')
                  : _buildQuotationsDataTable(),
        ),
        _buildQuotationsSummaryBar(),
      ],
    );
  }

  Widget _buildSalesFilterBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search by Invoice Number
              SizedBox(
                width: 240,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search invoice...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Date Range Picker
              OutlinedButton.icon(
                onPressed: _showDateRangePicker,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  dateRange == null
                      ? 'Date Range'
                      : '${DateFormat('dd MMM').format(dateRange!.start)} - ${DateFormat('dd MMM').format(dateRange!.end)}',
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              if (dateRange != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() => dateRange = null);
                    _applyFilters();
                  },
                  tooltip: 'Clear date filter',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F7FA),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              
              // Customer Filter
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int?>(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    isDense: true,
                  ),
                  value: selectedCustomerId,
                  hint: const Text('All Customers', style: TextStyle(fontSize: 13)),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Customers', style: TextStyle(fontSize: 13)),
                    ),
                    ...customers.map((customer) => DropdownMenuItem<int?>(
                      value: customer['id'] as int,
                      child: Text(
                        customer['name']?.toString() ?? 'Unknown',
                        style: const TextStyle(fontSize: 13),
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCustomerId = value;
                      selectedCustomerName = value == null 
                        ? null 
                        : customers.firstWhere((c) => c['id'] == value)['name']?.toString();
                    });
                    _applyFilters();
                  },
                ),
              ),
              
              const Spacer(),
              
              // Refresh Button
              IconButton(
                onPressed: _loadSales,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F7FA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Status Filter Chips
          Row(
            children: [
              _buildStatusChip('All', filterStatus == 'all', null, () {
                setState(() => filterStatus = 'all');
                _applyFilters();
              }),
              const SizedBox(width: 8),
              _buildStatusChip('Paid', filterStatus == 'paid', const Color(0xFF10B981), () {
                setState(() => filterStatus = 'paid');
                _applyFilters();
              }),
              const SizedBox(width: 8),
              _buildStatusChip('Partial', filterStatus == 'partial', const Color(0xFFF59E0B), () {
                setState(() => filterStatus = 'partial');
                _applyFilters();
              }),
              const SizedBox(width: 8),
              _buildStatusChip('Credit', filterStatus == 'credit', const Color(0xFFEF4444), () {
                setState(() => filterStatus = 'credit');
                _applyFilters();
              }),
              const SizedBox(width: 16),
              Text(
                '${filteredSales.length} ${filteredSales.length == 1 ? 'invoice' : 'invoices'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isSelected, Color? color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (color ?? const Color(0xFF3B82F6)).withValues(alpha: 0.1)
              : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected 
                ? (color ?? const Color(0xFF3B82F6))
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected 
                ? (color ?? const Color(0xFF3B82F6))
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesDataTable() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Sticky Header
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  _buildHeaderCell('Invoice', flex: 2),
                  _buildHeaderCell('Date', flex: 2),
                  _buildHeaderCell('Customer', flex: 3),
                  _buildHeaderCell('Payment', flex: 2),
                  _buildHeaderCell('Status', flex: 2),
                  _buildHeaderCell('Amount', flex: 2, alignRight: true),
                  _buildHeaderCell('Actions', flex: 2),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            
            // Table Body
            Expanded(
              child: ListView.builder(
                itemCount: filteredSales.length,
                itemBuilder: (context, index) {
                  final sale = filteredSales[index];
                  return _buildTableRow(sale, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, {int flex = 1, bool alignRight = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
          letterSpacing: 0.3,
        ),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> sale, int index) {
    final isHovered = ValueNotifier<bool>(false);
    final statusColor = sale['payment_status'] == 'paid' 
        ? const Color(0xFF10B981)
        : sale['payment_status'] == 'partial' 
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    
    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: isHovered,
        builder: (context, hovered, _) {
          return InkWell(
            onTap: () => _viewSaleDetails(sale),
            child: Container(
              decoration: BoxDecoration(
                color: hovered ? const Color(0xFFF8FAFC) : Colors.white,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Invoice Number
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            size: 16,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            sale['invoice_number']?.toString() ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Date
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale['created_at'] != null 
                              ? DateFormat('dd MMM yyyy').format(DateTime.parse(sale['created_at']))
                              : 'N/A',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          sale['created_at'] != null 
                              ? DateFormat('hh:mm a').format(DateTime.parse(sale['created_at']))
                              : '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Customer
                  Expanded(
                    flex: 3,
                    child: Text(
                      sale['customer_name']?.toString() ?? 'Walk-in Customer',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Payment Method
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        (sale['payment_mode']?.toString() ?? 'CASH').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                  // Status
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (sale['payment_status']?.toString() ?? 'paid').toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Amount
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${(sale['total'] ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (sale['payment_status'] != 'paid' && (sale['due_amount'] ?? 0.0) > 0)
                          Text(
                            'Due: ₹${(sale['due_amount'] ?? 0.0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Actions
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () => _viewSaleDetails(sale),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          tooltip: 'View Details',
                          style: IconButton.styleFrom(
                            backgroundColor: hovered ? const Color(0xFFE0F2FE) : Colors.transparent,
                            foregroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () async {
                            final items = await DatabaseHelper.instance.getSaleItems(sale['id']);
                            _printSale(sale, items);
                          },
                          icon: const Icon(Icons.print_outlined, size: 18),
                          tooltip: 'Print',
                          style: IconButton.styleFrom(
                            backgroundColor: hovered ? const Color(0xFFDCFCE7) : Colors.transparent,
                            foregroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _deleteSale(sale['id']),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Delete',
                          style: IconButton.styleFrom(
                            backgroundColor: hovered ? const Color(0xFFFEE2E2) : Colors.transparent,
                            foregroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.all(8),
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
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Records will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesSummaryBar() {
    final totalSales = filteredSales.fold<double>(
      0.0,
      (sum, sale) => sum + (sale['total'] as double? ?? 0.0),
    );
    
    final cashSales = filteredSales
        .where((s) => s['payment_mode'] == 'cash')
        .fold<double>(0.0, (sum, s) => sum + (s['total'] as double? ?? 0.0));
    
    final cardSales = filteredSales
        .where((s) => s['payment_mode'] == 'card')
        .fold<double>(0.0, (sum, s) => sum + (s['total'] as double? ?? 0.0));
    
    final upiSales = filteredSales
        .where((s) => s['payment_mode'] == 'upi')
        .fold<double>(0.0, (sum, s) => sum + (s['total'] as double? ?? 0.0));
    
    final totalDue = filteredSales
        .where((s) => s['payment_status'] != 'paid')
        .fold<double>(0.0, (sum, s) => sum + (s['due_amount'] as double? ?? 0.0));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSummaryCard(
            label: 'Total Sales',
            value: '₹${totalSales.toStringAsFixed(2)}',
            icon: Icons.trending_up,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            label: 'Cash',
            value: '₹${cashSales.toStringAsFixed(2)}',
            icon: Icons.payments_outlined,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            label: 'Card',
            value: '₹${cardSales.toStringAsFixed(2)}',
            icon: Icons.credit_card,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            label: 'UPI',
            value: '₹${upiSales.toStringAsFixed(2)}',
            icon: Icons.qr_code,
            color: const Color(0xFF06B6D4),
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            label: 'Outstanding',
            value: '₹${totalDue.toStringAsFixed(2)}',
            icon: Icons.access_time,
            color: const Color(0xFFEF4444),
          ),
          const Spacer(),
          Text(
            '${filteredSales.length} ${filteredSales.length == 1 ? 'Transaction' : 'Transactions'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => dateRange = picked);
      _applyFilters();
    }
  }

  // ===== QUOTATIONS UI =====
  Widget _buildQuotationsFilterBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search quotation...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    quotationSearchQuery = value;
                    _applyQuotationFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: quotationDateRange,
                  );
                  if (picked != null) {
                    setState(() => quotationDateRange = picked);
                    _applyQuotationFilters();
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  quotationDateRange == null
                      ? 'Date Range'
                      : '${DateFormat('dd MMM').format(quotationDateRange!.start)} - ${DateFormat('dd MMM').format(quotationDateRange!.end)}',
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (quotationDateRange != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() => quotationDateRange = null);
                    _applyQuotationFilters();
                  },
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: _loadQuotations,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusChip('All', quotationFilterType == 'all', null, () {
                setState(() => quotationFilterType = 'all');
                _applyQuotationFilters();
              }),
              const SizedBox(width: 8),
              _buildStatusChip('Sales', quotationFilterType == 'sale', const Color(0xFF3B82F6), () {
                setState(() => quotationFilterType = 'sale');
                _applyQuotationFilters();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationsDataTable() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Quotation #', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)))),
                  Expanded(flex: 1, child: Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)))),
                  Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)))),
                  Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)))),
                  Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)))),
                  Expanded(flex: 1, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)), textAlign: TextAlign.right)),
                  SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)), textAlign: TextAlign.center)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredQuotations.length,
                itemBuilder: (context, index) {
                  final quotation = filteredQuotations[index];
                  final status = quotation['status']?.toString() ?? 'pending';
                  final partyName = quotation['customer_name']?.toString() ?? 'N/A';
                  return InkWell(
                    onTap: () => _viewQuotationDetails(quotation),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        color: index % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(quotation['quotation_number']?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                          Expanded(flex: 1, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Sale', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF3B82F6))),
                          )),
                          Expanded(flex: 2, child: Text(partyName)),
                          Expanded(flex: 2, child: Text(quotation['created_at'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(quotation['created_at'])) : 'N/A')),
                          Expanded(flex: 1, child: _buildQuotationStatusBadge(status)),
                          Expanded(flex: 1, child: Text('₹${(quotation['total_amount'] ?? 0.0).toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
                          SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(icon: const Icon(Icons.visibility, size: 18), onPressed: () => _viewQuotationDetails(quotation), tooltip: 'View'),
                                IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _deleteQuotation(quotation['id']), tooltip: 'Delete'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    
    switch (status) {
      case 'converted':
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        textColor = const Color(0xFF10B981);
        label = 'Converted';
        break;
      case 'expired':
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
        textColor = const Color(0xFFEF4444);
        label = 'Expired';
        break;
      default:
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        textColor = const Color(0xFFF59E0B);
        label = 'Pending';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textColor)),
    );
  }

  Widget _buildQuotationsSummaryBar() {
    final totalQuotations = filteredQuotations.fold<double>(0.0, (sum, q) => sum + (q['total_amount'] as double? ?? 0.0));
    final pendingCount = filteredQuotations.where((q) => q['status'] == 'pending').length;
    final convertedCount = filteredQuotations.where((q) => q['status'] == 'converted').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 2)),
      ),
      child: Row(
        children: [
          _buildSummaryCard(label: 'Total Value', value: '₹${totalQuotations.toStringAsFixed(2)}', icon: Icons.description, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 16),
          _buildSummaryCard(label: 'Pending', value: pendingCount.toString(), icon: Icons.hourglass_empty, color: const Color(0xFFF59E0B)),
          const SizedBox(width: 16),
          _buildSummaryCard(label: 'Converted', value: convertedCount.toString(), icon: Icons.check_circle, color: const Color(0xFF10B981)),
          const Spacer(),
          Text('${filteredQuotations.length} ${filteredQuotations.length == 1 ? 'Quotation' : 'Quotations'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
