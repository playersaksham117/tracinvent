/// Receipt Generator - Usage Examples & Test Cases
/// 
/// This file demonstrates how to use the ReceiptGenerator class
/// with real-world examples for all receipt templates and paper sizes.
library;

import 'package:flutter/foundation.dart';
import 'receipt_generator.dart';

class ReceiptGeneratorExamples {
  
  /// Example 1: Standard Retail Receipt on 80mm thermal printer
  static void example1Standard80mm() {
    final receiptData = {
      'shopName': 'SACHIN ELECTRICALS',
      'address': '123 Market Street, Mumbai',
      'phone': '+91-98765-43210',
      'gstin': '27AABCU9603R1ZM',
      'receiptNo': 'RCP-2024-001234',
      'date': '06-JAN-2026',
      'time': '02:45 PM',
      'cashier': 'RAJESH KUMAR',
      'customerName': 'AMIT SHARMA',
      'currencySymbol': '₹',
      'items': [
        {
          'name': 'LED BULB 9W PHILIPS',
          'quantity': 2,
          'rate': 120.00,
          'amount': 240.00,
          'taxRate': 18.0,
          'taxAmount': 36.61,
        },
        {
          'name': 'ELECTRIC WIRE 10M FINOLEX',
          'quantity': 1,
          'rate': 350.00,
          'amount': 350.00,
          'taxRate': 18.0,
          'taxAmount': 53.39,
        },
        {
          'name': 'SWITCH BOARD 4 WAY',
          'quantity': 3,
          'rate': 40.00,
          'amount': 120.00,
          'taxRate': 12.0,
          'taxAmount': 12.86,
        },
      ],
      'subtotal': 607.14,
      'totalTax': 102.86,
      'discount': 0.0,
      'grandTotal': 710.00,
      'paymentMode': 'CASH',
      'amountPaid': 1000.00,
      'changeAmount': 290.00,
      'footerText': 'Exchange within 7 days with bill',
    };

    final receipt = ReceiptGenerator.generateReceipt(
      templateType: ReceiptGenerator.TEMPLATE_STANDARD,
      paperSize: ReceiptGenerator.PAPER_80MM,
      data: receiptData,
    );

    debugPrint('═' * 50);
    debugPrint('EXAMPLE 1: Standard Receipt - 80mm Thermal');
    debugPrint('═' * 50);
    debugPrint(receipt);
    debugPrint('═' * 50);
    debugPrint('\n');
  }

  /// Example 2: Standard Receipt on 58mm thermal printer (compact)
  static void example2Standard58mm() {
    final receiptData = {
      'shopName': 'QUICK MART',
      'phone': '+91-99999-12345',
      'gstin': '29AABCU9603R1ZM',
      'receiptNo': 'QM-58-001',
      'date': '06-JAN-2026',
      'time': '03:15 PM',
      'currencySymbol': '₹',
      'items': [
        {
          'name': 'COCA COLA 500ML',
          'quantity': 2,
          'rate': 40.00,
          'amount': 80.00,
        },
        {
          'name': 'LAYS CHIPS',
          'quantity': 3,
          'rate': 20.00,
          'amount': 60.00,
        },
      ],
      'subtotal': 140.00,
      'totalTax': 0.0,
      'discount': 5.00,
      'grandTotal': 135.00,
      'paymentMode': 'UPI',
    };

    final receipt = ReceiptGenerator.generateReceipt(
      templateType: ReceiptGenerator.TEMPLATE_STANDARD,
      paperSize: ReceiptGenerator.PAPER_58MM,
      data: receiptData,
    );

    debugPrint('═' * 35);
    debugPrint('EXAMPLE 2: Standard - 58mm Thermal');
    debugPrint('═' * 35);
    debugPrint(receipt);
    debugPrint('═' * 35);
    debugPrint('\n');
  }

  /// Example 3: Minimal Receipt for fast billing
  static void example3MinimalFastBilling() {
    final receiptData = {
      'shopName': 'QUICK STORE',
      'phone': '9876543210',
      'receiptNo': 'MIN-001',
      'date': '06/01/26',
      'currencySymbol': '₹',
      'items': [
        {
          'name': 'BREAD',
          'quantity': 2,
          'amount': 60.00,
        },
        {
          'name': 'MILK 1L',
          'quantity': 1,
          'amount': 56.00,
        },
        {
          'name': 'EGGS DOZEN',
          'quantity': 1,
          'amount': 84.00,
        },
      ],
      'grandTotal': 200.00,
      'paymentMode': 'CASH',
    };

    final receipt = ReceiptGenerator.generateReceipt(
      templateType: ReceiptGenerator.TEMPLATE_MINIMAL,
      paperSize: ReceiptGenerator.PAPER_58MM,
      data: receiptData,
    );

    debugPrint('═' * 35);
    debugPrint('EXAMPLE 3: Minimal Fast Billing');
    debugPrint('═' * 35);
    debugPrint(receipt);
    debugPrint('═' * 35);
    debugPrint('\n');
  }

  /// Example 4: GST Invoice (India) with CGST+SGST breakdown
  static void example4GstInvoice() {
    final receiptData = {
      'shopName': 'TECH SOLUTIONS PVT LTD',
      'address': 'Plot 45, IT Park, Bangalore',
      'phone': '080-12345678',
      'gstin': '29AABCT1234F1Z5',
      'receiptNo': 'INV/2024/00789',
      'date': '06-JAN-2026',
      'time': '11:30 AM',
      'customerName': 'INFOSYS TECHNOLOGIES',
      'customerGSTIN': '29AABCI9603R1ZM',
      'customerPhone': '080-87654321',
      'currencySymbol': 'Rs.',
      'isInterState': false, // Intra-state: CGST + SGST
      'items': [
        {
          'name': 'LAPTOP DELL INSPIRON',
          'quantity': 2,
          'rate': 45000.00,
          'amount': 106200.00,
          'taxRate': 18.0,
        },
        {
          'name': 'WIRELESS MOUSE LOGITECH',
          'quantity': 5,
          'rate': 800.00,
          'amount': 4720.00,
          'taxRate': 18.0,
        },
      ],
      'discount': 500.00,
      'grandTotal': 110420.00,
      'paymentMode': 'BANK TRANSFER',
      'amountPaid': 110420.00,
      'footerText': 'Subject to Bangalore jurisdiction',
    };

    final receipt = ReceiptGenerator.generateReceipt(
      templateType: ReceiptGenerator.TEMPLATE_GST_INVOICE,
      paperSize: ReceiptGenerator.PAPER_80MM,
      data: receiptData,
    );

    debugPrint('═' * 50);
    debugPrint('EXAMPLE 4: GST Invoice (CGST+SGST)');
    debugPrint('═' * 50);
    debugPrint(receipt);
    debugPrint('═' * 50);
    debugPrint('\n');
  }

  /// Example 5: GST Invoice with IGST (Inter-state)
  static void example5GstInvoiceIgst() {
    final receiptData = {
      'shopName': 'ELECTRONICS BAZAAR',
      'address': 'Sector 18, Noida, UP',
      'phone': '0120-4567890',
      'gstin': '09AABCE2345F1Z6',
      'receiptNo': 'IGST/2024/00123',
      'date': '06-JAN-2026',
      'time': '04:20 PM',
      'customerName': 'TECH WORLD PUNE',
      'customerGSTIN': '27AABCT9876R1ZM',
      'currencySymbol': '₹',
      'isInterState': true, // Inter-state: IGST
      'items': [
        {
          'name': 'SAMSUNG TV 43 INCH',
          'quantity': 1,
          'rate': 35000.00,
          'amount': 41300.00,
          'taxRate': 18.0,
        },
      ],
      'grandTotal': 41300.00,
      'paymentMode': 'CREDIT',
      'footerText': 'Goods once sold will not be taken back',
    };

    final receipt = ReceiptGenerator.generateReceipt(
      templateType: ReceiptGenerator.TEMPLATE_GST_INVOICE,
      paperSize: ReceiptGenerator.PAPER_A4,
      data: receiptData,
    );

    debugPrint('═' * 80);
    debugPrint('EXAMPLE 5: GST Invoice (IGST) - A4 Format');
    debugPrint('═' * 80);
    debugPrint(receipt);
    debugPrint('═' * 80);
    debugPrint('\n');
  }

  /// Example 6: Non-GST Cash Receipt
  static void example6NonGstCashReceipt() {
    final receiptData = {
      'shopName': 'GARDEN FRESH VEGETABLES',
      'address': 'Vegetable Market, Delhi',
      'phone': '011-9876543210',
      'receiptNo': 'CASH-2024-5678',
      'date': '06-JAN-2026',
      'time': '07:30 AM',
      'customerName': 'HOTEL PARADISE',
      'currencySymbol': 'Rs.',
      'items': [
        {
          'name': 'FRESH TOMATOES',
          'amount': 450.00,
          'description': '15 KG @ Rs.30/KG',
        },
        {
          'name': 'ONIONS',
          'amount': 600.00,
          'description': '20 KG @ Rs.30/KG',
        },
        {
          'name': 'POTATOES',
          'amount': 750.00,
          'description': '25 KG @ Rs.30/KG',
        },
      ],
      'grandTotal': 1800.00,
      'paymentMode': 'CASH',
      'footerText': 'Fresh produce daily',
    };

    final receipt = ReceiptGenerator.generateReceipt(
      templateType: ReceiptGenerator.TEMPLATE_NON_GST,
      paperSize: ReceiptGenerator.PAPER_80MM,
      data: receiptData,
    );

    debugPrint('═' * 50);
    debugPrint('EXAMPLE 6: Non-GST Cash Receipt');
    debugPrint('═' * 50);
    debugPrint(receipt);
    debugPrint('═' * 50);
    debugPrint('\n');
  }

  /// Example 7: Test with USD currency
  static void example7UsdCurrency() {
    final receiptData = {
      'shopName': 'INTERNATIONAL STORE',
      'address': 'Downtown Mall, NYC',
      'phone': '+1-555-123-4567',
      'receiptNo': 'US-001-2024',
      'date': 'JAN-06-2026',
      'time': '02:45 PM',
      'currencySymbol': '\$',
      'items': [
        {
          'name': 'COFFEE BEANS 500G',
          'quantity': 2,
          'rate': 15.99,
          'amount': 31.98,
        },
        {
          'name': 'ORGANIC TEA BOX',
          'quantity': 1,
          'rate': 12.50,
          'amount': 12.50,
        },
      ],
      'subtotal': 44.48,
      'totalTax': 3.56,
      'grandTotal': 48.04,
      'paymentMode': 'CARD',
    };

    final receipt = ReceiptGenerator.generateReceipt(
      templateType: ReceiptGenerator.TEMPLATE_STANDARD,
      paperSize: ReceiptGenerator.PAPER_80MM,
      data: receiptData,
    );

    debugPrint('═' * 50);
    debugPrint('EXAMPLE 7: USD Currency Receipt');
    debugPrint('═' * 50);
    debugPrint(receipt);
    debugPrint('═' * 50);
    debugPrint('\n');
  }

  /// Example 8: Very long item names on 58mm (truncation test)
  static void example8LongItemNames58mm() {
    final receiptData = {
      'shopName': 'MEGA STORE',
      'phone': '9999999999',
      'receiptNo': 'TEST-58-001',
      'date': '06-JAN-26',
      'currencySymbol': '₹',
      'items': [
        {
          'name': 'SUPER EXTRA LONG PRODUCT NAME THAT WILL BE TRUNCATED',
          'quantity': 1,
          'amount': 100.00,
        },
        {
          'name': 'ANOTHER EXTREMELY LONG NAME FOR TESTING TRUNCATION',
          'quantity': 2,
          'amount': 200.00,
        },
      ],
      'grandTotal': 300.00,
      'paymentMode': 'CASH',
    };

    final receipt = ReceiptGenerator.generateReceipt(
      templateType: ReceiptGenerator.TEMPLATE_STANDARD,
      paperSize: ReceiptGenerator.PAPER_58MM,
      data: receiptData,
    );

    debugPrint('═' * 35);
    debugPrint('EXAMPLE 8: Long Names - 58mm Test');
    debugPrint('═' * 35);
    debugPrint(receipt);
    debugPrint('═' * 35);
    debugPrint('\n');
  }

  /// Example 9: ESC/POS with commands
  static void example9EscPos() {
    final receiptData = {
      'shopName': 'THERMAL PRINTER DEMO',
      'phone': '9876543210',
      'receiptNo': 'ESC-001',
      'date': '06-JAN-2026',
      'currencySymbol': '₹',
      'items': [
        {
          'name': 'TEST ITEM 1',
          'quantity': 1,
          'amount': 100.00,
        },
      ],
      'grandTotal': 100.00,
      'paymentMode': 'CASH',
    };

    final receipt = ReceiptGenerator.generateReceiptWithESCPOS(
      templateType: ReceiptGenerator.TEMPLATE_MINIMAL,
      paperSize: ReceiptGenerator.PAPER_58MM,
      data: receiptData,
    );

    debugPrint('═' * 35);
    debugPrint('EXAMPLE 9: ESC/POS Commands');
    debugPrint('═' * 35);
    debugPrint(receipt);
    debugPrint('(Receipt includes ESC/POS control codes)');
    debugPrint('Use raw printer to see formatted output');
    debugPrint('═' * 35);
    debugPrint('\n');
  }

  /// Run all examples
  static void runAllExamples() {
    debugPrint('\n');
    debugPrint('╔══════════════════════════════════════════════════════════════════════════════╗');
    debugPrint('║         PROFESSIONAL RECEIPT GENERATOR - USAGE EXAMPLES                     ║');
    debugPrint('║         Author: Senior POS/ERP Engineer                                     ║');
    debugPrint('║         Support: 58mm, 80mm Thermal & A4 Printers                          ║');
    debugPrint('╚══════════════════════════════════════════════════════════════════════════════╝');
    debugPrint('\n');

    example1Standard80mm();
    example2Standard58mm();
    example3MinimalFastBilling();
    example4GstInvoice();
    example5GstInvoiceIgst();
    example6NonGstCashReceipt();
    example7UsdCurrency();
    example8LongItemNames58mm();
    example9EscPos();

    debugPrint('═' * 80);
    debugPrint('ALL EXAMPLES COMPLETED SUCCESSFULLY');
    debugPrint('═' * 80);
    debugPrint('\n');
    debugPrint('USAGE INSTRUCTIONS:');
    debugPrint('1. Copy receipt_generator.dart to your lib/utils/ folder');
    debugPrint('2. Import: import \'package:your_app/utils/receipt_generator.dart\';');
    debugPrint('3. Call: ReceiptGenerator.generateReceipt(...)');
    debugPrint('4. Print the returned string using your printer library');
    debugPrint('\n');
    debugPrint('PRINTING METHODS:');
    debugPrint('- Save to .txt file and print via Notepad');
    debugPrint('- Send directly to thermal printer using raw printer library');
    debugPrint('- Use ESC/POS commands for advanced formatting');
    debugPrint('\n');
  }

  /// Integration example for Flutter POS app
  static String integrateWithFlutterPOS({
    required String customerName,
    required List<Map<String, dynamic>> cartItems,
    required double grandTotal,
    required String paymentMode,
    required String shopName,
    required String phone,
    String? gstin,
  }) {
    // Build receipt data from cart
    final receiptData = {
      'shopName': shopName,
      'phone': phone,
      'gstin': gstin,
      'receiptNo': 'POS-${DateTime.now().millisecondsSinceEpoch}',
      'date': _formatDate(DateTime.now()),
      'time': _formatTime(DateTime.now()),
      'customerName': customerName,
      'currencySymbol': '₹',
      'items': cartItems.map((item) => {
        'name': item['productName'],
        'quantity': item['quantity'],
        'rate': item['rate'],
        'amount': item['amount'],
        'taxRate': item['taxRate'] ?? 0.0,
        'taxAmount': item['taxAmount'] ?? 0.0,
      }).toList(),
      'subtotal': cartItems.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0)),
      'totalTax': cartItems.fold(0.0, (sum, item) => sum + (item['taxAmount'] ?? 0.0)),
      'discount': 0.0,
      'grandTotal': grandTotal,
      'paymentMode': paymentMode,
    };

    // Generate receipt (auto-detect paper size from settings)
    return ReceiptGenerator.generateReceipt(
      templateType: ReceiptGenerator.TEMPLATE_STANDARD,
      paperSize: ReceiptGenerator.PAPER_80MM,
      data: receiptData,
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}-${_monthName(dt.month)}-${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  static String _monthName(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}

/// Main function to test the receipt generator
void main() {
  ReceiptGeneratorExamples.runAllExamples();
}
