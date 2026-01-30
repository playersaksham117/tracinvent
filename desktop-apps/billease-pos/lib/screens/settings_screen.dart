import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/receipt_generator.dart';
import '../database/database_helper.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCategory = 'business';
  
  // Shop Settings
  String shopName = 'SACHIN ELECTRICALS';
  String gstin = '03ABCDE1234F1Z5';
  String phone = '+91-98765-43210';
  String address = '';
  String currencySymbol = '₹';
  
  // Branch Settings
  int? selectedBranchId;
  String selectedBranchName = 'Head Office';
  List<Map<String, dynamic>> branches = [];
  
  // Receipt Settings
  String selectedTemplate = 'standard';
  String paperSize = '80mm';
  bool printSkuOnReceipt = false;
  bool printBarcodeOnReceipt = false;
  bool printSkuOnly = false;
  
  // Barcode Label Printing Settings
  double labelPaperWidth = 40.0;  // in mm
  double labelPaperHeight = 25.0; // in mm
  String labelAlignment = 'Center + Middle';
  String labelContentType = 'full'; // full, name_price, name_barcode, barcode_only
  bool labelShowSku = true;
  bool labelShowBarcode = true;
  bool labelShowPrice = true;
  bool labelShowName = true;
  bool labelShowMrp = false;
  bool labelShowShopName = false;
  
  // Payment & Sales Settings
  bool enableSplitPayments = true;
  bool enableReturns = true;
  bool enableCreditSales = true;
  
  // Loyalty Settings
  bool enableLoyaltyPoints = false;
  int loyaltyPointsRate = 1;
  double loyaltyRedemptionValue = 1.0;
  
  // Inventory Settings
  bool trackBatchNumbers = false;
  bool trackExpiryDates = false;
  
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBranches();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedTemplate = prefs.getString('receipt_template') ?? 'standard';
      paperSize = prefs.getString('paper_size') ?? '80mm';
      shopName = prefs.getString('shop_name') ?? 'SACHIN ELECTRICALS';
      gstin = prefs.getString('gstin') ?? '03ABCDE1234F1Z5';
      phone = prefs.getString('phone') ?? '+91-98765-43210';
      address = prefs.getString('address') ?? '';
      currencySymbol = prefs.getString('currency_symbol') ?? '₹';
      selectedBranchId = prefs.getInt('selected_branch_id');
      selectedBranchName = prefs.getString('selected_branch_name') ?? 'Head Office';
      
      // Advanced settings
      printSkuOnReceipt = prefs.getBool('print_sku_on_receipt') ?? false;
      printBarcodeOnReceipt = prefs.getBool('print_barcode_on_receipt') ?? false;
      printSkuOnly = prefs.getBool('print_sku_only') ?? false;
      enableSplitPayments = prefs.getBool('enable_split_payments') ?? true;
      enableReturns = prefs.getBool('enable_returns') ?? true;
      enableCreditSales = prefs.getBool('enable_credit_sales') ?? true;
      enableLoyaltyPoints = prefs.getBool('enable_loyalty_points') ?? false;
      trackBatchNumbers = prefs.getBool('track_batch_numbers') ?? false;
      trackExpiryDates = prefs.getBool('track_expiry_dates') ?? false;
      loyaltyPointsRate = prefs.getInt('loyalty_points_rate') ?? 1;
      loyaltyRedemptionValue = prefs.getDouble('loyalty_redemption_value') ?? 1.0;
      
      // Barcode Label Settings
      labelPaperWidth = prefs.getDouble('label_paper_width') ?? 40.0;
      labelPaperHeight = prefs.getDouble('label_paper_height') ?? 25.0;
      labelAlignment = prefs.getString('label_alignment') ?? 'Center';
      labelContentType = prefs.getString('label_content_type') ?? 'full';
      labelShowSku = prefs.getBool('label_show_sku') ?? true;
      labelShowBarcode = prefs.getBool('label_show_barcode') ?? true;
      labelShowPrice = prefs.getBool('label_show_price') ?? true;
      labelShowName = prefs.getBool('label_show_name') ?? true;
      labelShowMrp = prefs.getBool('label_show_mrp') ?? false;
      labelShowShopName = prefs.getBool('label_show_shop_name') ?? false;
    });
  }

  Future<void> _loadBranches() async {
    final db = DatabaseHelper.instance;
    final branchList = await db.getActiveBranches();
    setState(() {
      branches = branchList;
      if (branches.isNotEmpty && selectedBranchId == null) {
        selectedBranchId = branches.first['id'] as int;
        selectedBranchName = branches.first['branch_name'] as String;
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paper_size', paperSize);
    await prefs.setString('shop_name', shopName);
    await prefs.setString('gstin', gstin);
    await prefs.setString('phone', phone);
    await prefs.setString('currency_symbol', currencySymbol);
    await prefs.setString('address', address);
    await prefs.setString('receipt_template', selectedTemplate);
    
    if (selectedBranchId != null) {
      await prefs.setInt('selected_branch_id', selectedBranchId!);
      await prefs.setString('selected_branch_name', selectedBranchName);
    }
    
    await prefs.setBool('print_sku_on_receipt', printSkuOnReceipt);
    await prefs.setBool('print_barcode_on_receipt', printBarcodeOnReceipt);
    await prefs.setBool('print_sku_only', printSkuOnly);
    await prefs.setBool('enable_split_payments', enableSplitPayments);
    await prefs.setBool('enable_returns', enableReturns);
    await prefs.setBool('enable_credit_sales', enableCreditSales);
    await prefs.setBool('enable_loyalty_points', enableLoyaltyPoints);
    await prefs.setBool('track_batch_numbers', trackBatchNumbers);
    await prefs.setBool('track_expiry_dates', trackExpiryDates);
    await prefs.setInt('loyalty_points_rate', loyaltyPointsRate);
    await prefs.setDouble('loyalty_redemption_value', loyaltyRedemptionValue);
    
    // Barcode Label Settings
    await prefs.setDouble('label_paper_width', labelPaperWidth);
    await prefs.setDouble('label_paper_height', labelPaperHeight);
    await prefs.setString('label_alignment', labelAlignment);
    await prefs.setString('label_content_type', labelContentType);
    await prefs.setBool('label_show_sku', labelShowSku);
    await prefs.setBool('label_show_barcode', labelShowBarcode);
    await prefs.setBool('label_show_price', labelShowPrice);
    await prefs.setBool('label_show_name', labelShowName);
    await prefs.setBool('label_show_mrp', labelShowMrp);
    await prefs.setBool('label_show_shop_name', labelShowShopName);
    
    setState(() => _hasUnsavedChanges = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Settings saved successfully'),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _testPrintReceipt() async {
    try {
      // Get paper size constant
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

      // Get template type
      String templateType;
      switch (selectedTemplate) {
        case 'minimal':
          templateType = ReceiptGenerator.TEMPLATE_MINIMAL;
          break;
        case 'gst_invoice':
          templateType = ReceiptGenerator.TEMPLATE_GST_INVOICE;
          break;
        case 'non_gst':
          templateType = ReceiptGenerator.TEMPLATE_NON_GST;
          break;
        case 'standard':
        default:
          templateType = ReceiptGenerator.TEMPLATE_STANDARD;
      }

      // Create test data
      final now = DateTime.now();
      final testData = {
        'shopName': shopName,
        'branchName': selectedBranchName,
        'address': address.isNotEmpty ? address : null,
        'phone': phone,
        'gstin': gstin,
        'receiptNo': 'TEST-${now.millisecondsSinceEpoch}',
        'date': _formatDate(now),
        'time': _formatTime(now),
        'cashier': 'TEST USER',
        'currencySymbol': currencySymbol,
        'items': [
          {
            'name': 'SAMPLE PRODUCT 1',
            'sku': 'SKU001',
            'barcode': '123456789012',
            'quantity': 2,
            'rate': 100.00,
            'amount': 200.00,
            'taxRate': 18.0,
            'taxAmount': 30.51,
          },
          {
            'name': 'SAMPLE PRODUCT 2',
            'sku': 'SKU002',
            'barcode': '987654321098',
            'quantity': 1,
            'rate': 250.00,
            'amount': 250.00,
            'taxRate': 12.0,
            'taxAmount': 26.79,
          },
        ],
        'subtotal': 392.70,
        'totalTax': 57.30,
        'discount': 0.0,
        'grandTotal': 450.00,
        'paymentMode': 'CASH',
        'amountPaid': 500.00,
        'changeAmount': 50.00,
        'footerText': 'This is a test receipt',
      };

      // Generate receipt
      final receiptText = ReceiptGenerator.generateReceipt(
        templateType: templateType,
        paperSize: paperWidth,
        data: testData,
        printSku: printSkuOnReceipt,
        printBarcode: printBarcodeOnReceipt,
      );

      // Show preview dialog
      _showReceiptPreviewDialog(receiptText);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating test receipt: $e')),
      );
    }
  }

  void _showReceiptPreviewDialog(String receiptText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Colors.indigo),
            const SizedBox(width: 8),
            Text('Test Receipt - $paperSize'),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 700,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      receiptText,
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: paperSize == '58mm' ? 10 : 12,
                        height: 1.3,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _printToFile(receiptText);
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printToFile(String receiptText) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}\\test_receipt_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File(filePath);
      await file.writeAsString(receiptText);

      // Try to print using Windows PRINT command
      await Process.run('notepad', ['/p', filePath]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt sent to printer')),
      );

      // Clean up after delay
      Future.delayed(const Duration(seconds: 10), () {
        try {
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print error: $e')),
      );
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}-${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  void _navigateToBranchManagement() {
    Navigator.pushNamed(context, '/branches').then((_) {
      if (mounted) {
        _loadBranches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          _buildCategorySidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildContentForCategory(),
                  ),
                ),
                if (_hasUnsavedChanges) _buildSaveBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.settings, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildCategoryItem(
                  id: 'business',
                  icon: Icons.business_rounded,
                  label: 'Business / Shop',
                ),
                _buildCategoryItem(
                  id: 'branches',
                  icon: Icons.store_rounded,
                  label: 'Branch Management',
                ),
                _buildCategoryItem(
                  id: 'receipt',
                  icon: Icons.receipt_long_rounded,
                  label: 'Receipt & Printing',
                ),
                _buildCategoryItem(
                  id: 'payment',
                  icon: Icons.payments_rounded,
                  label: 'Payment & Sales',
                ),
                _buildCategoryItem(
                  id: 'taxes',
                  icon: Icons.account_balance_rounded,
                  label: 'Taxes (GST)',
                  badge: 'Soon',
                ),
                _buildCategoryItem(
                  id: 'users',
                  icon: Icons.people_rounded,
                  label: 'Users & Roles',
                  badge: 'Soon',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildCategoryItem(
                  id: 'backup',
                  icon: Icons.cloud_upload_rounded,
                  label: 'Backup & Data',
                  badge: 'Soon',
                ),
                _buildCategoryItem(
                  id: 'advanced',
                  icon: Icons.tune_rounded,
                  label: 'Advanced',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String id,
    required IconData icon,
    required String label,
    String? badge,
  }) {
    final isSelected = _selectedCategory == id;
    final isDisabled = badge == 'Soon';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : () => setState(() => _selectedCategory = id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0F9FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: const Color(0xFFBAE6FD))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF0284C7)
                      : isDisabled
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : isDisabled
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFA16207),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final categoryTitles = {
      'business': 'Business / Shop Information',
      'branches': 'Branch Management',
      'receipt': 'Receipt & Printing Settings',
      'payment': 'Payment & Sales Options',
      'taxes': 'Taxes & GST Configuration',
      'users': 'Users & Roles Management',
      'backup': 'Backup & Data Management',
      'advanced': 'Advanced Settings',
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Text(
            categoryTitles[_selectedCategory] ?? 'Settings',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          if (_hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8),
                  Text(
                    'Unsaved changes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA16207),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentForCategory() {
    switch (_selectedCategory) {
      case 'business':
        return _buildBusinessSettings();
      case 'branches':
        return _buildBranchSettings();
      case 'receipt':
        return _buildReceiptSettings();
      case 'payment':
        return _buildPaymentSettings();
      case 'advanced':
        return _buildAdvancedSettings();
      default:
        return _buildComingSoon();
    }
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You have unsaved changes',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _hasUnsavedChanges = false);
              _loadSettings();
            },
            child: const Text('Discard'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildComingSoon() {
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
              Icons.construction_rounded,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This feature is under development',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTemplateOption(String value, String title, String description) {
    return RadioListTile<String>(
      value: value,
      groupValue: selectedTemplate,
      onChanged: (val) {
        setState(() {
          selectedTemplate = val!;
        });
      },
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(description, style: const TextStyle(fontSize: 11)),
      activeColor: Colors.indigo,
      dense: true,
    );
  }

  Widget _buildBusinessSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingsCard(
          title: 'Shop Information',
          icon: Icons.store_rounded,
          children: [
            _buildTextField(
              label: 'Shop / Business Name',
              value: shopName,
              onChanged: (v) {
                shopName = v;
                _markChanged();
              },
              hint: 'Enter your business name',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'GSTIN',
                    value: gstin,
                    onChanged: (v) {
                      gstin = v;
                      _markChanged();
                    },
                    hint: '03ABCDE1234F1Z5',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Phone Number',
                    value: phone,
                    onChanged: (v) {
                      phone = v;
                      _markChanged();
                    },
                    hint: '+91-98765-43210',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Address',
              value: address,
              onChanged: (v) {
                address = v;
                _markChanged();
              },
              hint: 'Shop address (optional)',
              maxLines: 2,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSettingsCard(
          title: 'Currency',
          icon: Icons.currency_rupee_rounded,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Currency Symbol',
                border: OutlineInputBorder(),
              ),
              initialValue: currencySymbol,
              items: const [
                DropdownMenuItem(value: '₹', child: Text('₹ - Indian Rupee')),
                DropdownMenuItem(value: '\$', child: Text('\$ - US Dollar')),
                DropdownMenuItem(value: '€', child: Text('€ - Euro')),
                DropdownMenuItem(value: '£', child: Text('£ - British Pound')),
                DropdownMenuItem(value: '¥', child: Text('¥ - Japanese Yen')),
              ],
              onChanged: (value) {
                setState(() {
                  currencySymbol = value!;
                  _markChanged();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBranchSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingsCard(
          title: 'Active Branch',
          icon: Icons.storefront_rounded,
          children: [
            if (branches.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.store_outlined, size: 40, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    const Text(
                      'No branches configured',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create branches to manage multiple store locations',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _navigateToBranchManagement,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create First Branch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Select Active Branch',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_rounded),
                ),
                initialValue: selectedBranchId,
                items: branches.map((branch) {
                  return DropdownMenuItem<int>(
                    value: branch['id'] as int,
                    child: Text(
                      '${branch['branch_name']}${(branch['is_head_office'] as int) == 1 ? ' (HQ)' : ''}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBranchId = value;
                    final branch = branches.firstWhere(
                      (b) => b['id'] == value,
                      orElse: () => {},
                    );
                    selectedBranchName = branch['branch_name'] as String? ?? 'Head Office';
                    _markChanged();
                  });
                },
              ),
            if (branches.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _navigateToBranchManagement,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Manage Branches'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildReceiptSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingsCard(
          title: 'Paper Size',
          icon: Icons.print_rounded,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Printer Paper Size',
                border: OutlineInputBorder(),
              ),
              initialValue: paperSize,
              items: const [
                DropdownMenuItem(value: '58mm', child: Text('58mm Thermal (32 chars)')),
                DropdownMenuItem(value: '80mm', child: Text('80mm Thermal (48 chars)')),
                DropdownMenuItem(value: 'A4', child: Text('A4 Paper (80 chars)')),
              ],
              onChanged: (value) {
                setState(() {
                  paperSize = value!;
                  _markChanged();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSettingsCard(
          title: 'Receipt Template',
          icon: Icons.receipt_long_rounded,
          children: [
            _buildRadioOption(
              value: 'standard',
              groupValue: selectedTemplate,
              title: 'Standard Receipt',
              subtitle: 'Complete retail invoice with items, taxes, and totals',
              onChanged: (v) {
                setState(() {
                  selectedTemplate = v!;
                  _markChanged();
                });
              },
            ),
            _buildRadioOption(
              value: 'minimal',
              groupValue: selectedTemplate,
              title: 'Minimal / Fast Billing',
              subtitle: 'Quick receipt format for fast checkout',
              onChanged: (v) {
                setState(() {
                  selectedTemplate = v!;
                  _markChanged();
                });
              },
            ),
            _buildRadioOption(
              value: 'gst_invoice',
              groupValue: selectedTemplate,
              title: 'GST Tax Invoice',
              subtitle: 'Full GST invoice with CGST/SGST/IGST breakdown',
              onChanged: (v) {
                setState(() {
                  selectedTemplate = v!;
                  _markChanged();
                });
              },
            ),
            _buildRadioOption(
              value: 'non_gst',
              groupValue: selectedTemplate,
              title: 'Non-GST Cash Receipt',
              subtitle: 'Simple cash receipt without tax details',
              onChanged: (v) {
                setState(() {
                  selectedTemplate = v!;
                  _markChanged();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSettingsCard(
          title: 'Display Options',
          icon: Icons.visibility_rounded,
          children: [
            _buildToggleRow(
              label: 'Print SKU on Receipt',
              subtitle: 'Display product SKU/Code',
              value: printSkuOnReceipt,
              onChanged: (v) {
                setState(() {
                  printSkuOnReceipt = v;
                  _markChanged();
                });
              },
            ),
            const Divider(height: 24),
            _buildToggleRow(
              label: 'Print Barcode',
              subtitle: 'Display barcode below product',
              value: printBarcodeOnReceipt,
              onChanged: (v) {
                setState(() {
                  printBarcodeOnReceipt = v;
                  _markChanged();
                });
              },
            ),
            const Divider(height: 24),
            _buildToggleRow(
              label: 'Print SKU Only',
              subtitle: 'Show only SKU (hide barcode)',
              value: printSkuOnly,
              onChanged: (v) {
                setState(() {
                  printSkuOnly = v;
                  _markChanged();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _testPrintReceipt,
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Test Print Receipt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Test your printer setup before billing',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSettingsCard(
          title: 'Barcode Label Printing',
          icon: Icons.qr_code_2_rounded,
          children: [
            const Text(
              'Configure paper size and alignment for product barcode labels',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Label Width (mm)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.width_normal),
                      helperText: 'Width in millimeters',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    initialValue: labelPaperWidth.toString(),
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          labelPaperWidth = parsed;
                          _markChanged();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Label Height (mm)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                      helperText: 'Height in millimeters',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    initialValue: labelPaperHeight.toString(),
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          labelPaperHeight = parsed;
                          _markChanged();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Label Alignment',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.align_horizontal_center),
              ),
              value: labelAlignment,
              items: const [
                DropdownMenuItem(value: 'Center + Middle', child: Text('Center + Middle (Recommended)')),
                DropdownMenuItem(value: 'Top Left', child: Text('Top Left')),
                DropdownMenuItem(value: 'Top Center', child: Text('Top Center')),
                DropdownMenuItem(value: 'Top Right', child: Text('Top Right')),
                DropdownMenuItem(value: 'Center Left', child: Text('Center Left')),
                DropdownMenuItem(value: 'Center', child: Text('Center')),
                DropdownMenuItem(value: 'Center Right', child: Text('Center Right')),
                DropdownMenuItem(value: 'Bottom Left', child: Text('Bottom Left')),
                DropdownMenuItem(value: 'Bottom Center', child: Text('Bottom Center')),
                DropdownMenuItem(value: 'Bottom Right', child: Text('Bottom Right')),
              ],
              onChanged: (value) {
                setState(() {
                  labelAlignment = value!;
                  _markChanged();
                });
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Color(0xFF0284C7)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Current: ${labelPaperWidth}mm × ${labelPaperHeight}mm • $labelAlignment',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSettingsCard(
          title: 'Label Content Options',
          icon: Icons.label_outline_rounded,
          children: [
            const Text(
              'Choose what information to display on product labels',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Label Template',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.style),
              ),
              value: labelContentType,
              items: const [
                DropdownMenuItem(value: 'full', child: Text('Full Label (Name, SKU, Price, Barcode)')),
                DropdownMenuItem(value: 'name_price', child: Text('Name & Price Only')),
                DropdownMenuItem(value: 'name_barcode', child: Text('Name & Barcode')),
                DropdownMenuItem(value: 'barcode_only', child: Text('Barcode Only')),
              ],
              onChanged: (value) {
                setState(() {
                  labelContentType = value!;
                  _markChanged();
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Content Toggles',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            _buildToggleRow(
              label: 'Show Product Name',
              subtitle: 'Display product name on label',
              value: labelShowName,
              onChanged: (v) {
                setState(() {
                  labelShowName = v;
                  _markChanged();
                });
              },
            ),
            const Divider(height: 20),
            _buildToggleRow(
              label: 'Show SKU',
              subtitle: 'Display SKU/Product code',
              value: labelShowSku,
              onChanged: (v) {
                setState(() {
                  labelShowSku = v;
                  _markChanged();
                });
              },
            ),
            const Divider(height: 20),
            _buildToggleRow(
              label: 'Show Price',
              subtitle: 'Display selling price on label',
              value: labelShowPrice,
              onChanged: (v) {
                setState(() {
                  labelShowPrice = v;
                  _markChanged();
                });
              },
            ),
            const Divider(height: 20),
            _buildToggleRow(
              label: 'Show MRP Prefix',
              subtitle: 'Add "MRP:" prefix before price',
              value: labelShowMrp,
              onChanged: (v) {
                setState(() {
                  labelShowMrp = v;
                  _markChanged();
                });
              },
            ),
            const Divider(height: 20),
            _buildToggleRow(
              label: 'Show Barcode',
              subtitle: 'Display barcode graphic on label',
              value: labelShowBarcode,
              onChanged: (v) {
                setState(() {
                  labelShowBarcode = v;
                  _markChanged();
                });
              },
            ),
            const Divider(height: 20),
            _buildToggleRow(
              label: 'Show Shop Name',
              subtitle: 'Include shop name on each label',
              value: labelShowShopName,
              onChanged: (v) {
                setState(() {
                  labelShowShopName = v;
                  _markChanged();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 24, color: Color(0xFFA16207)),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Print Labels from Inventory',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFA16207),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Go to Product Management to print labels for individual or multiple products using the Print Label button.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCA8A04),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingsCard(
          title: 'Payment Options',
          icon: Icons.payment_rounded,
          children: [
            _buildToggleRow(
              label: 'Enable Split Payments',
              subtitle: 'Allow multiple payment methods per sale',
              value: enableSplitPayments,
              onChanged: (v) {
                setState(() {
                  enableSplitPayments = v;
                  _markChanged();
                });
              },
            ),
            const Divider(height: 24),
            _buildToggleRow(
              label: 'Enable Credit Sales',
              subtitle: 'Allow sales on credit with due tracking',
              value: enableCreditSales,
              onChanged: (v) {
                setState(() {
                  enableCreditSales = v;
                  _markChanged();
                });
              },
            ),
            const Divider(height: 24),
            _buildToggleRow(
              label: 'Enable Returns',
              subtitle: 'Process product returns and exchanges',
              value: enableReturns,
              onChanged: (v) {
                setState(() {
                  enableReturns = v;
                  _markChanged();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSettingsCard(
          title: 'Loyalty Program',
          icon: Icons.star_rounded,
          children: [
            _buildToggleRow(
              label: 'Enable Loyalty Points',
              subtitle: 'Reward customers with points',
              value: enableLoyaltyPoints,
              onChanged: (v) {
                setState(() {
                  enableLoyaltyPoints = v;
                  _markChanged();
                });
              },
            ),
            if (enableLoyaltyPoints) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Points per $currencySymbol',
                        border: const OutlineInputBorder(),
                        helperText: 'Points earned per currency unit',
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: loyaltyPointsRate.toString(),
                      onChanged: (v) {
                        loyaltyPointsRate = int.tryParse(v) ?? 1;
                        _markChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: '$currencySymbol per Point',
                        border: const OutlineInputBorder(),
                        helperText: 'Redemption value',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      initialValue: loyaltyRedemptionValue.toString(),
                      onChanged: (v) {
                        loyaltyRedemptionValue = double.tryParse(v) ?? 1.0;
                        _markChanged();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingsCard(
          title: 'Inventory Tracking',
          icon: Icons.inventory_2_rounded,
          children: [
            _buildToggleRow(
              label: 'Track Batch Numbers',
              subtitle: 'Track products by batch/lot numbers',
              value: trackBatchNumbers,
              onChanged: (v) {
                setState(() {
                  trackBatchNumbers = v;
                  _markChanged();
                });
              },
            ),
            const Divider(height: 24),
            _buildToggleRow(
              label: 'Track Expiry Dates',
              subtitle: 'Monitor product expiration dates',
              value: trackExpiryDates,
              onChanged: (v) {
                setState(() {
                  trackExpiryDates = v;
                  _markChanged();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      initialValue: value,
      onChanged: onChanged,
      maxLines: maxLines,
    );
  }

  Widget _buildToggleRow({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String groupValue,
    required String title,
    required String subtitle,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
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

  // ignore: unused_element
  Widget _buildPreview() {
    // Get character width based on paper size
    double fontSize;
    switch (paperSize) {
      case '58mm':
        fontSize = 10;
        break;
      case 'A4':
        fontSize = 11;
        break;
      case '80mm':
      default:
        fontSize = 11;
    }

    // Generate preview receipt
    String previewText;
    try {
      final testData = {
        'shopName': shopName,
        'phone': phone,
        'gstin': gstin,
        'receiptNo': 'PREVIEW-001',
        'date': '06-JAN-2026',
        'time': '02:45 PM',
        'currencySymbol': currencySymbol,
        'items': [
          {
            'name': 'SAMPLE ITEM 1',
            'quantity': 2,
            'rate': 100.00,
            'amount': 200.00,
          },
          {
            'name': 'SAMPLE ITEM 2',
            'quantity': 1,
            'rate': 150.00,
            'amount': 150.00,
          },
        ],
        'grandTotal': 350.00,
        'paymentMode': 'CASH',
      };

      String templateType;
      switch (selectedTemplate) {
        case 'minimal':
          templateType = ReceiptGenerator.TEMPLATE_MINIMAL;
          break;
        case 'gst_invoice':
          templateType = ReceiptGenerator.TEMPLATE_GST_INVOICE;
          break;
        case 'non_gst':
          templateType = ReceiptGenerator.TEMPLATE_NON_GST;
          break;
        case 'standard':
        default:
          templateType = ReceiptGenerator.TEMPLATE_STANDARD;
      }

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

      previewText = ReceiptGenerator.generateReceipt(
        templateType: templateType,
        paperSize: paperWidth,
        data: testData,
        printSku: printSkuOnReceipt,
        printBarcode: printBarcodeOnReceipt,
      );
    } catch (e) {
      previewText = 'Error generating preview: $e';
    }

    return SingleChildScrollView(
      child: Text(
        previewText,
        style: TextStyle(
          fontFamily: 'Courier New',
          fontSize: fontSize,
          height: 1.3,
          color: Colors.black87,
        ),
      ),
    );
  }
}
