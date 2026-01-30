/// Integration Guide: Receipt Generator with Existing POS Screen
/// 
/// This file shows how to integrate the receipt_generator.dart
/// with your existing pos_screen.dart for plain text thermal printing
library;

import 'package:flutter/material.dart';
import '../utils/receipt_generator.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ReceiptPrinterIntegration {
  
  /// Example 1: Replace existing PDF receipt with plain text receipt
  /// 
  /// In your pos_screen.dart, replace the PDF generation with this:
  static Future<void> printPlainTextReceipt({
    required BuildContext context,
    required String shopName,
    required String? address,
    required String? phone,
    required String? gstin,
    required String receiptNo,
    required String currencySymbol,
    required List<dynamic> cartItems,
    required double subtotal,
    required double totalTax,
    required double totalDiscount,
    required double grandTotal,
    required String paymentMode,
    required double? amountPaid,
    required double? changeAmount,
    String? customerName,
    String? cashier,
    String selectedTemplate = 'standard',
    int paperSize = 48, // 80mm default
  }) async {
    try {
      // Build receipt data from cart
      final receiptData = _buildReceiptData(
        shopName: shopName,
        address: address,
        phone: phone,
        gstin: gstin,
        receiptNo: receiptNo,
        currencySymbol: currencySymbol,
        cartItems: cartItems,
        subtotal: subtotal,
        totalTax: totalTax,
        totalDiscount: totalDiscount,
        grandTotal: grandTotal,
        paymentMode: paymentMode,
        amountPaid: amountPaid,
        changeAmount: changeAmount,
        customerName: customerName,
        cashier: cashier,
      );

      // Map template names to constants
      String templateType;
      switch (selectedTemplate.toLowerCase()) {
        case 'minimal':
        case 'compact':
          templateType = ReceiptGenerator.TEMPLATE_MINIMAL;
          break;
        case 'gst':
        case 'gst_detailed':
        case 'gst_invoice':
          templateType = ReceiptGenerator.TEMPLATE_GST_INVOICE;
          break;
        case 'non_gst':
        case 'cash_memo':
          templateType = ReceiptGenerator.TEMPLATE_NON_GST;
          break;
        default:
          templateType = ReceiptGenerator.TEMPLATE_STANDARD;
      }

      // Generate plain text receipt
      final receiptText = ReceiptGenerator.generateReceipt(
        templateType: templateType,
        paperSize: paperSize,
        data: receiptData,
      );

      // Option 1: Save and print via system
      await _printViaSystem(receiptText);

      // Option 2: Show in dialog for preview/copy
      if (context.mounted) {
        _showReceiptPreview(context, receiptText);
      }

    } catch (e) {
      debugPrint('Error printing receipt: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing receipt: $e')),
        );
      }
    }
  }

  /// Build receipt data map from POS cart data
  static Map<String, dynamic> _buildReceiptData({
    required String shopName,
    String? address,
    String? phone,
    String? gstin,
    required String receiptNo,
    required String currencySymbol,
    required List<dynamic> cartItems,
    required double subtotal,
    required double totalTax,
    required double totalDiscount,
    required double grandTotal,
    required String paymentMode,
    double? amountPaid,
    double? changeAmount,
    String? customerName,
    String? cashier,
  }) {
    final now = DateTime.now();
    
    return {
      // Shop info
      'shopName': shopName,
      'address': address,
      'phone': phone,
      'gstin': gstin,
      
      // Receipt info
      'receiptNo': receiptNo,
      'date': _formatDate(now),
      'time': _formatTime(now),
      'cashier': cashier,
      'customerName': customerName,
      
      // Currency
      'currencySymbol': currencySymbol,
      
      // Items
      'items': cartItems.map((item) {
        // Assuming item has: product.name, quantity, product.price, subtotal, taxRate, taxAmount
        final productName = item.product?.name ?? 'Unknown';
        final qty = item.quantity ?? 0;
        final rate = item.product?.price ?? 0.0;
        final amount = item.total ?? 0.0;
        final taxRate = item.product?.taxRate ?? 0.0;
        final taxAmount = item.taxAmount ?? 0.0;
        
        return {
          'name': productName.toUpperCase(),
          'quantity': qty,
          'rate': rate,
          'amount': amount,
          'taxRate': taxRate,
          'taxAmount': taxAmount,
        };
      }).toList(),
      
      // Totals
      'subtotal': subtotal,
      'totalTax': totalTax,
      'discount': totalDiscount,
      'grandTotal': grandTotal,
      
      // Payment
      'paymentMode': paymentMode.toUpperCase(),
      'amountPaid': amountPaid,
      'changeAmount': changeAmount,
      
      // Footer
      'footerText': 'Thank you for shopping with us!',
    };
  }

  /// Print receipt via Windows PRINT command (Notepad)
  static Future<void> _printViaSystem(String receiptText) async {
    try {
      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}\\receipt_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File(filePath);
      await file.writeAsString(receiptText);

      // Print using Windows PRINT command
      // This will send directly to default printer
      await Process.run('PRINT', [filePath]);

      // Alternative: Open in Notepad for manual print
      // await Process.run('notepad', ['/p', filePath]);

      // Clean up after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        try {
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (_) {}
      });

    } catch (e) {
      debugPrint('Error printing via system: $e');
      rethrow;
    }
  }

  /// Show receipt preview in dialog
  static void _showReceiptPreview(BuildContext context, String receiptText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Receipt Preview'),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 600,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      receiptText,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        height: 1.3,
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
                    onPressed: () {
                      Navigator.pop(context);
                      _printViaSystem(receiptText);
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _copyToClipboard(receiptText);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receipt copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
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

  /// Copy text to clipboard
  static void _copyToClipboard(String text) {
    // Use Clipboard.setData() from flutter/services.dart
    // Clipboard.setData(ClipboardData(text: text));
  }

  /// Format date
  static String _formatDate(DateTime dt) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}-${dt.year}';
  }

  /// Format time
  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  // ============================================================================
  // ADVANCED: Direct Thermal Printer Integration
  // ============================================================================

  /// Send receipt directly to thermal printer via COM port or USB
  /// 
  /// Requires: blue_thermal_printer, esc_pos_printer, or similar package
  static Future<void> printToThermalPrinter({
    required String receiptText,
    String? printerName,
  }) async {
    // Example using ESC/POS commands
    final receiptWithCommands = ReceiptGenerator.generateReceiptWithESCPOS(
      templateType: ReceiptGenerator.TEMPLATE_STANDARD,
      paperSize: ReceiptGenerator.PAPER_80MM,
      data: {}, // Your receipt data here
    );

    // Send to printer
    // Implementation depends on your thermal printer package
    // Example: bluetooth, USB, network printer
    
    debugPrint('Sending to thermal printer...');
    debugPrint('Receipt commands prepared: ${receiptWithCommands.length} bytes');
    // await yourPrinterPackage.print(receiptWithCommands);
  }

  // ============================================================================
  // SETTINGS INTEGRATION
  // ============================================================================

  /// Get paper size from settings
  static int getPaperSizeFromSettings(String? savedSize) {
    switch (savedSize?.toLowerCase()) {
      case '58mm':
        return ReceiptGenerator.PAPER_58MM;
      case 'a4':
        return ReceiptGenerator.PAPER_A4;
      case '80mm':
      default:
        return ReceiptGenerator.PAPER_80MM;
    }
  }

  /// Get template from settings
  static String getTemplateFromSettings(String? savedTemplate) {
    switch (savedTemplate?.toLowerCase()) {
      case 'detailed':
      case 'standard':
        return ReceiptGenerator.TEMPLATE_STANDARD;
      case 'compact':
      case 'minimal':
        return ReceiptGenerator.TEMPLATE_MINIMAL;
      case 'gst_detailed':
      case 'gst':
        return ReceiptGenerator.TEMPLATE_GST_INVOICE;
      case 'cash_memo':
      case 'non_gst':
        return ReceiptGenerator.TEMPLATE_NON_GST;
      default:
        return ReceiptGenerator.TEMPLATE_STANDARD;
    }
  }
}

// ============================================================================
// USAGE IN POS SCREEN
// ============================================================================

/*

// In your pos_screen.dart, replace the PDF printing method with:

Future<void> _completeSaleAndPrint() async {
  // ... your existing sale completion code ...

  // Get settings
  final prefs = await SharedPreferences.getInstance();
  final template = prefs.getString('receipt_template') ?? 'standard';
  final paperSizeStr = prefs.getString('paper_size') ?? '80mm';
  final paperSize = ReceiptPrinterIntegration.getPaperSizeFromSettings(paperSizeStr);

  // Print plain text receipt
  await ReceiptPrinterIntegration.printPlainTextReceipt(
    context: context,
    shopName: prefs.getString('shop_name') ?? 'MY SHOP',
    address: prefs.getString('address'),
    phone: prefs.getString('phone'),
    gstin: prefs.getString('gstin'),
    receiptNo: saleNumber,
    currencySymbol: _currencySymbol,
    cartItems: _cart,
    subtotal: _subtotal,
    totalTax: _totalTax,
    totalDiscount: _totalDiscount,
    grandTotal: _grandTotal,
    paymentMode: _paymentMethod,
    amountPaid: paidAmount,
    changeAmount: changeAmount,
    customerName: _selectedCustomer?.name,
    cashier: 'Current User', // Get from your auth system
    selectedTemplate: template,
    paperSize: paperSize,
  );
}

// Add to settings_screen.dart:
// Paper Size dropdown
DropdownButtonFormField<String>(
  decoration: InputDecoration(
    labelText: 'Paper Size',
    border: OutlineInputBorder(),
  ),
  value: paperSize,
  items: [
    DropdownMenuItem(value: '58mm', child: Text('58mm Thermal')),
    DropdownMenuItem(value: '80mm', child: Text('80mm Thermal')),
    DropdownMenuItem(value: 'a4', child: Text('A4 Paper')),
  ],
  onChanged: (value) {
    setState(() {
      paperSize = value!;
    });
  },
),

*/
