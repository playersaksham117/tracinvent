/// Professional Receipt Generator for Thermal and A-Series Printers
/// 
/// Supports 58mm, 80mm thermal printers and A4/A-series paper
/// ESC/POS compatible, plain text only (Notepad safe)
/// 
/// Author: Senior POS/ERP Engineer
/// License: MIT
library;

class ReceiptGenerator {
  // Paper size configurations
  static const int PAPER_58MM = 32;  // 58mm thermal: max 32 chars per line
  static const int PAPER_80MM = 48;  // 80mm thermal: max 48 chars per line
  static const int PAPER_A4 = 80;    // A4 paper: max 80 chars per line

  // Template types
  static const String TEMPLATE_STANDARD = 'standard';
  static const String TEMPLATE_MINIMAL = 'minimal';
  static const String TEMPLATE_GST_INVOICE = 'gst_invoice';
  static const String TEMPLATE_NON_GST = 'non_gst';

  /// Main entry point: Generate receipt based on template and paper size
  /// 
  /// Parameters:
  /// - templateType: TEMPLATE_STANDARD | TEMPLATE_MINIMAL | TEMPLATE_GST_INVOICE | TEMPLATE_NON_GST
  /// - paperSize: PAPER_58MM | PAPER_80MM | PAPER_A4
  /// - data: Map containing all receipt data (shop info, items, totals, etc.)
  /// - printSku: Whether to print SKU/product code (default: false)
  /// - printBarcode: Whether to print barcode (default: false)
  /// 
  /// Returns: Plain text receipt as String
  static String generateReceipt({
    required String templateType,
    required int paperSize,
    required Map<String, dynamic> data,
    bool printSku = false,
    bool printBarcode = false,
  }) {
    data['printSku'] = printSku;
    data['printBarcode'] = printBarcode;
    switch (templateType) {
      case TEMPLATE_STANDARD:
        return _buildStandardReceipt(paperSize, data);
      case TEMPLATE_MINIMAL:
        return _buildMinimalReceipt(paperSize, data);
      case TEMPLATE_GST_INVOICE:
        return _buildGSTInvoice(paperSize, data);
      case TEMPLATE_NON_GST:
        return _buildNonGSTReceipt(paperSize, data);
      default:
        return _buildStandardReceipt(paperSize, data);
    }
  }

  // ============================================================================
  // TEMPLATE BUILDERS
  // ============================================================================

  /// Standard Retail Receipt Template
  static String _buildStandardReceipt(int width, Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln(centerText(data['shopName']?.toString().toUpperCase() ?? '', width));
    if (data['branchName'] != null && data['branchName'].toString().isNotEmpty) {
      buffer.writeln(centerText(data['branchName'].toString(), width));
    }
    if (data['address'] != null && data['address'].toString().isNotEmpty) {
      buffer.writeln(centerText(data['address'].toString(), width));
    }
    if (data['phone'] != null) {
      buffer.writeln(centerText('PH: ${data['phone']}', width));
    }
    if (data['gstin'] != null) {
      buffer.writeln(centerText('GSTIN: ${data['gstin']}', width));
    }
    buffer.writeln(separator(width));

    // Receipt Info
    buffer.writeln('RECEIPT NO : ${data['receiptNo'] ?? 'N/A'}');
    buffer.writeln('DATE       : ${data['date'] ?? ''}');
    buffer.writeln('TIME       : ${data['time'] ?? ''}');
    if (data['cashier'] != null) {
      buffer.writeln('CASHIER    : ${data['cashier']}');
    }
    if (data['customerName'] != null) {
      buffer.writeln('CUSTOMER   : ${data['customerName']}');
    }
    buffer.writeln(separator(width));

    // Column Headers
    if (width >= PAPER_80MM) {
      buffer.writeln('ITEM                    QTY  RATE    AMOUNT');
    } else {
      buffer.writeln('ITEM            QTY  AMT');
    }
    buffer.writeln(separator(width));

    // Items
    final items = data['items'] as List<Map<String, dynamic>>? ?? [];
    for (var item in items) {
      final name = item['name']?.toString().toUpperCase() ?? '';
      final sku = item['sku']?.toString() ?? '';
      final barcode = item['barcode']?.toString() ?? '';
      final qty = item['quantity'] ?? 0;
      final rate = item['rate'] ?? 0.0;
      final amount = item['amount'] ?? 0.0;
      final printSku = data['printSku'] ?? false;
      final printBarcode = data['printBarcode'] ?? false;

      if (width >= PAPER_80MM) {
        // 80mm format: NAME (24) QTY (4) RATE (7) AMOUNT (9)
        final truncName = truncateText(name, 24);
        final qtyStr = qty.toString().padLeft(3);
        final rateStr = formatAmount(rate).padLeft(7);
        final amtStr = formatAmount(amount).padLeft(9);
        buffer.writeln('$truncName $qtyStr $rateStr $amtStr');
        
        // Print SKU if enabled
        if (printSku && sku.isNotEmpty) {
          buffer.writeln('  SKU: $sku');
        }
        // Print Barcode if enabled
        if (printBarcode && barcode.isNotEmpty) {
          buffer.writeln('  Code: $barcode');
        }
      } else {
        // 58mm format: NAME (16) QTY (3) AMOUNT (8)
        final truncName = truncateText(name, 16);
        final qtyStr = qty.toString().padLeft(3);
        final amtStr = formatAmount(amount).padLeft(8);
        buffer.writeln('$truncName $qtyStr $amtStr');
        
        // Print SKU if enabled (compact format for 58mm)
        if (printSku && sku.isNotEmpty) {
          buffer.writeln('  SKU:$sku');
        }
        // Print Barcode if enabled
        if (printBarcode && barcode.isNotEmpty) {
          buffer.writeln('  Code:$barcode');
        }
      }

      // Show tax if present
      if (item['taxRate'] != null && item['taxRate'] > 0) {
        final taxAmt = item['taxAmount'] ?? 0.0;
        buffer.writeln('  TAX (${item['taxRate']}%) : ${formatAmount(taxAmt)}');
      }
    }

    buffer.writeln(separator(width));

    // Totals
    final subtotal = data['subtotal'] ?? 0.0;
    final totalTax = data['totalTax'] ?? 0.0;
    final discount = data['discount'] ?? 0.0;
    final grandTotal = data['grandTotal'] ?? 0.0;

    buffer.writeln(rightAlign('SUBTOTAL: ${formatAmount(subtotal)}', width));
    if (totalTax > 0) {
      buffer.writeln(rightAlign('TOTAL TAX: ${formatAmount(totalTax)}', width));
    }
    if (discount > 0) {
      buffer.writeln(rightAlign('DISCOUNT: -${formatAmount(discount)}', width));
    }
    buffer.writeln(separator(width));
    buffer.writeln(rightAlign('GRAND TOTAL: ${data['currencySymbol'] ?? ''}${formatAmount(grandTotal)}', width));
    buffer.writeln(separator(width));

    // Payment Info
    final paymentMode = data['paymentMode']?.toString().toUpperCase() ?? 'CASH';
    buffer.writeln('PAYMENT MODE : $paymentMode');
    
    if (data['amountPaid'] != null) {
      buffer.writeln(rightAlign('PAID: ${formatAmount(data['amountPaid'])}', width));
    }
    if (data['changeAmount'] != null && data['changeAmount'] > 0) {
      buffer.writeln(rightAlign('CHANGE: ${formatAmount(data['changeAmount'])}', width));
    }

    buffer.writeln(separator(width));
    
    // Footer
    buffer.writeln(centerText('THANK YOU FOR YOUR BUSINESS!', width));
    buffer.writeln(centerText('VISIT AGAIN', width));
    buffer.writeln(separator(width));
    
    if (data['footerText'] != null) {
      buffer.writeln(centerText(data['footerText'].toString(), width));
    }

    return buffer.toString();
  }

  /// Minimal / Fast Billing Receipt Template
  static String _buildMinimalReceipt(int width, Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // Compact Header
    buffer.writeln(centerText(data['shopName']?.toString().toUpperCase() ?? '', width));
    if (data['branchName'] != null && data['branchName'].toString().isNotEmpty) {
      buffer.writeln(centerText(data['branchName'].toString(), width));
    }
    buffer.writeln(centerText(data['phone']?.toString() ?? '', width));
    buffer.writeln(separator(width, '-'));

    // Quick Info
    buffer.writeln('NO: ${data['receiptNo']}  DATE: ${data['date']}');
    buffer.writeln(separator(width, '-'));

    // Items - Compact Format
    final items = data['items'] as List<Map<String, dynamic>>? ?? [];
    final printSku = data['printSku'] ?? false;
    final printBarcode = data['printBarcode'] ?? false;
    
    for (var item in items) {
      final name = truncateText(item['name']?.toString().toUpperCase() ?? '', width - 12);
      final sku = item['sku']?.toString() ?? '';
      final barcode = item['barcode']?.toString() ?? '';
      final qty = item['quantity'] ?? 0;
      final amount = formatAmount(item['amount'] ?? 0.0);
      buffer.writeln('$name x$qty');
      buffer.writeln(rightAlign(amount, width));
      
      // Print SKU/Barcode if enabled (compact format)
      if (printSku && sku.isNotEmpty) {
        buffer.writeln('  SKU:$sku');
      }
      if (printBarcode && barcode.isNotEmpty) {
        buffer.writeln('  Code:$barcode');
      }
    }

    buffer.writeln(separator(width, '-'));
    
    // Totals - Compact
    final grandTotal = data['grandTotal'] ?? 0.0;
    buffer.writeln(rightAlign('TOTAL: ${data['currencySymbol'] ?? ''}${formatAmount(grandTotal)}', width));
    buffer.writeln('PAID: ${data['paymentMode']?.toString().toUpperCase() ?? 'CASH'}');
    
    buffer.writeln(separator(width, '-'));
    buffer.writeln(centerText('THANK YOU!', width));

    return buffer.toString();
  }

  /// GST Invoice Template (India)
  static String _buildGSTInvoice(int width, Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // Header - Tax Invoice
    buffer.writeln(centerText('TAX INVOICE', width));
    buffer.writeln(separator(width, '='));
    buffer.writeln(centerText(data['shopName']?.toString().toUpperCase() ?? '', width));
    if (data['branchName'] != null && data['branchName'].toString().isNotEmpty) {
      buffer.writeln(centerText(data['branchName'].toString(), width));
    }
    
    if (data['address'] != null) {
      buffer.writeln(centerText(data['address'].toString(), width));
    }
    buffer.writeln(centerText('GSTIN: ${data['gstin'] ?? 'N/A'}', width));
    if (data['phone'] != null) {
      buffer.writeln(centerText('PH: ${data['phone']}', width));
    }
    buffer.writeln(separator(width, '='));

    // Invoice Details
    buffer.writeln('INVOICE NO : ${data['receiptNo'] ?? 'N/A'}');
    buffer.writeln('DATE       : ${data['date'] ?? ''}');
    buffer.writeln('TIME       : ${data['time'] ?? ''}');
    
    // Customer Details
    if (data['customerName'] != null) {
      buffer.writeln(separator(width, '-'));
      buffer.writeln('BILL TO:');
      buffer.writeln(data['customerName'].toString().toUpperCase());
      if (data['customerGSTIN'] != null) {
        buffer.writeln('GSTIN: ${data['customerGSTIN']}');
      }
      if (data['customerPhone'] != null) {
        buffer.writeln('PH: ${data['customerPhone']}');
      }
    }
    
    buffer.writeln(separator(width, '='));

    // Items with GST breakdown
    if (width >= PAPER_80MM) {
      buffer.writeln('ITEM                QTY  RATE    TAXABLE');
    } else {
      buffer.writeln('ITEM          QTY  TAXABLE');
    }
    buffer.writeln(separator(width, '-'));

    final items = data['items'] as List<Map<String, dynamic>>? ?? [];
    final printSku = data['printSku'] ?? false;
    final printBarcode = data['printBarcode'] ?? false;
    double totalTaxableAmount = 0.0;
    double totalCGST = 0.0;
    double totalSGST = 0.0;
    double totalIGST = 0.0;

    for (var item in items) {
      final name = item['name']?.toString().toUpperCase() ?? '';
      final sku = item['sku']?.toString() ?? '';
      final barcode = item['barcode']?.toString() ?? '';
      final qty = item['quantity'] ?? 0;
      final rate = item['rate'] ?? 0.0;
      final taxRate = item['taxRate'] ?? 0.0;
      final amount = item['amount'] ?? 0.0;
      
      // Calculate taxable amount (amount before tax)
      final taxableAmount = amount / (1 + (taxRate / 100));
      final taxAmount = amount - taxableAmount;
      
      totalTaxableAmount += taxableAmount;

      if (width >= PAPER_80MM) {
        final truncName = truncateText(name, 20);
        final qtyStr = qty.toString().padLeft(3);
        final rateStr = formatAmount(rate).padLeft(7);
        final taxableStr = formatAmount(taxableAmount).padLeft(8);
        buffer.writeln('$truncName $qtyStr $rateStr $taxableStr');
      } else {
        final truncName = truncateText(name, 14);
        final qtyStr = qty.toString().padLeft(3);
        final taxableStr = formatAmount(taxableAmount).padLeft(8);
        buffer.writeln('$truncName $qtyStr $taxableStr');
      }
      
      // Print SKU/Barcode if enabled
      if (printSku && sku.isNotEmpty) {
        buffer.writeln('  SKU: $sku');
      }
      if (printBarcode && barcode.isNotEmpty) {
        buffer.writeln('  Code: $barcode');
      }

      // GST Breakdown
      if (taxRate > 0) {
        if (data['isInterState'] == true) {
          // Inter-state: IGST
          totalIGST += taxAmount;
          buffer.writeln('  IGST @ ${taxRate.toStringAsFixed(2)}%: ${formatAmount(taxAmount)}');
        } else {
          // Intra-state: CGST + SGST
          final cgst = taxAmount / 2;
          final sgst = taxAmount / 2;
          totalCGST += cgst;
          totalSGST += sgst;
          final halfRate = (taxRate / 2).toStringAsFixed(2);
          buffer.writeln('  CGST @ $halfRate%: ${formatAmount(cgst)}');
          buffer.writeln('  SGST @ $halfRate%: ${formatAmount(sgst)}');
        }
      }
    }

    buffer.writeln(separator(width, '='));

    // GST Summary
    buffer.writeln('TAXABLE AMOUNT : ${formatAmount(totalTaxableAmount)}');
    
    if (data['isInterState'] == true) {
      buffer.writeln('IGST           : ${formatAmount(totalIGST)}');
    } else {
      buffer.writeln('CGST           : ${formatAmount(totalCGST)}');
      buffer.writeln('SGST           : ${formatAmount(totalSGST)}');
    }

    final discount = data['discount'] ?? 0.0;
    if (discount > 0) {
      buffer.writeln('DISCOUNT       : -${formatAmount(discount)}');
    }

    buffer.writeln(separator(width, '='));
    
    final grandTotal = data['grandTotal'] ?? 0.0;
    buffer.writeln(rightAlign('INVOICE TOTAL: ${data['currencySymbol'] ?? 'Rs.'}${formatAmount(grandTotal)}', width));
    buffer.writeln(separator(width, '='));

    // Payment Info
    buffer.writeln('PAYMENT MODE   : ${data['paymentMode']?.toString().toUpperCase() ?? 'CASH'}');
    
    if (data['amountPaid'] != null) {
      buffer.writeln('AMOUNT PAID    : ${formatAmount(data['amountPaid'])}');
    }
    if (data['changeAmount'] != null && data['changeAmount'] > 0) {
      buffer.writeln('CHANGE         : ${formatAmount(data['changeAmount'])}');
    }

    buffer.writeln(separator(width, '='));
    
    // Footer
    buffer.writeln(centerText('THIS IS A COMPUTER GENERATED INVOICE', width));
    buffer.writeln(centerText('THANK YOU FOR YOUR BUSINESS', width));
    
    if (data['footerText'] != null) {
      buffer.writeln(centerText(data['footerText'].toString(), width));
    }

    return buffer.toString();
  }

  /// Non-GST Cash Receipt Template
  static String _buildNonGSTReceipt(int width, Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln(centerText('CASH RECEIPT', width));
    buffer.writeln(separator(width));
    buffer.writeln(centerText(data['shopName']?.toString().toUpperCase() ?? '', width));
    if (data['branchName'] != null && data['branchName'].toString().isNotEmpty) {
      buffer.writeln(centerText(data['branchName'].toString(), width));
    }
    
    if (data['address'] != null) {
      buffer.writeln(centerText(data['address'].toString(), width));
    }
    if (data['phone'] != null) {
      buffer.writeln(centerText('PH: ${data['phone']}', width));
    }
    buffer.writeln(separator(width));

    // Receipt Details
    buffer.writeln('RECEIPT NO : ${data['receiptNo'] ?? 'N/A'}');
    buffer.writeln('DATE       : ${data['date'] ?? ''}');
    buffer.writeln('TIME       : ${data['time'] ?? ''}');
    
    if (data['customerName'] != null) {
      buffer.writeln('RECEIVED FROM: ${data['customerName']}');
    }
    
    buffer.writeln(separator(width));

    // Items - Simple Format
    buffer.writeln('PARTICULARS                    AMOUNT');
    buffer.writeln(separator(width, '-'));

    final items = data['items'] as List<Map<String, dynamic>>? ?? [];
    final printSku = data['printSku'] ?? false;
    final printBarcode = data['printBarcode'] ?? false;
    
    for (var item in items) {
      final name = truncateText(item['name']?.toString().toUpperCase() ?? '', width - 12);
      final sku = item['sku']?.toString() ?? '';
      final barcode = item['barcode']?.toString() ?? '';
      final amount = formatAmount(item['amount'] ?? 0.0);
      buffer.writeln(leftPadRight(name, amount, width));
      
      // Print SKU/Barcode if enabled
      if (printSku && sku.isNotEmpty) {
        buffer.writeln('  SKU: $sku');
      }
      if (printBarcode && barcode.isNotEmpty) {
        buffer.writeln('  Code: $barcode');
      }
      
      if (item['description'] != null && width >= PAPER_80MM) {
        buffer.writeln('  ${item['description']}');
      }
    }

    buffer.writeln(separator(width, '-'));

    // Total
    final grandTotal = data['grandTotal'] ?? 0.0;
    buffer.writeln(leftPadRight('TOTAL AMOUNT:', formatAmount(grandTotal), width));
    
    final discount = data['discount'] ?? 0.0;
    if (discount > 0) {
      buffer.writeln(leftPadRight('DISCOUNT:', '-${formatAmount(discount)}', width));
    }

    buffer.writeln(separator(width));
    buffer.writeln(leftPadRight('NET AMOUNT:', 
      '${data['currencySymbol'] ?? 'Rs.'}${formatAmount(data['grandTotal'] ?? 0.0)}', width));
    buffer.writeln(separator(width));

    // Payment Info
    buffer.writeln('PAYMENT MODE: ${data['paymentMode']?.toString().toUpperCase() ?? 'CASH'}');
    buffer.writeln('RECEIVED IN FULL PAYMENT');

    buffer.writeln(separator(width));
    
    // Footer
    buffer.writeln(centerText('THANK YOU', width));
    
    if (data['footerText'] != null) {
      buffer.writeln(centerText(data['footerText'].toString(), width));
    }

    return buffer.toString();
  }

  // ============================================================================
  // HELPER UTILITIES
  // ============================================================================

  /// Center text within given width
  static String centerText(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    
    final padding = (width - text.length) ~/ 2;
    return '${' ' * padding}$text';
  }

  /// Right align text
  static String rightAlign(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    
    return text.padLeft(width);
  }

  /// Left align text
  static String leftAlign(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    
    return text.padRight(width);
  }

  /// Left text, right text with padding in between
  static String leftPadRight(String left, String right, int width) {
    final totalTextLength = left.length + right.length;
    if (totalTextLength >= width) {
      return '${truncateText(left, width - right.length - 1)} $right';
    }
    
    final padding = width - totalTextLength;
    return '$left${' ' * padding}$right';
  }

  /// Generate separator line
  static String separator(int width, [String char = '-']) {
    return char * width;
  }

  /// Truncate text to fit width
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 2)}..';
  }

  /// Format amount with 2 decimal places
  static String formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    
    final double value = amount is double ? amount : double.tryParse(amount.toString()) ?? 0.0;
    return value.toStringAsFixed(2);
  }

  /// Convert amount to words (for invoice)
  static String amountInWords(double amount) {
    // Basic implementation - can be extended
    final ones = ['', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE'];
    final tens = ['', '', 'TWENTY', 'THIRTY', 'FORTY', 'FIFTY', 'SIXTY', 'SEVENTY', 'EIGHTY', 'NINETY'];
    final teens = ['TEN', 'ELEVEN', 'TWELVE', 'THIRTEEN', 'FOURTEEN', 'FIFTEEN', 'SIXTEEN', 'SEVENTEEN', 'EIGHTEEN', 'NINETEEN'];
    
    if (amount == 0) return 'ZERO ONLY';
    
    int rupees = amount.toInt();
    int paise = ((amount - rupees) * 100).round();
    
    String result = '';
    
    // Simplified conversion (extend for full implementation)
    if (rupees < 10) {
      result = ones[rupees];
    } else if (rupees < 20) {
      result = teens[rupees - 10];
    } else if (rupees < 100) {
      result = tens[rupees ~/ 10] + (rupees % 10 > 0 ? ' ${ones[rupees % 10]}' : '');
    } else {
      result = 'RUPEES $rupees';
    }
    
    if (paise > 0) {
      result += ' AND $paise PAISE';
    }
    
    return '$result ONLY';
  }

  /// Validate receipt data
  static bool validateReceiptData(Map<String, dynamic> data) {
    // Check required fields
    if (data['shopName'] == null || data['shopName'].toString().isEmpty) {
      return false;
    }
    
    if (data['items'] == null || (data['items'] as List).isEmpty) {
      return false;
    }
    
    if (data['grandTotal'] == null) {
      return false;
    }
    
    return true;
  }

  // ============================================================================
  // ESC/POS COMMANDS (Optional - for advanced thermal printer control)
  // ============================================================================

  /// ESC/POS: Initialize printer
  static String escInit() => '\x1B\x40';

  /// ESC/POS: Bold ON
  static String escBoldOn() => '\x1B\x45\x01';

  /// ESC/POS: Bold OFF
  static String escBoldOff() => '\x1B\x45\x00';

  /// ESC/POS: Center alignment
  static String escAlignCenter() => '\x1B\x61\x01';

  /// ESC/POS: Left alignment
  static String escAlignLeft() => '\x1B\x61\x00';

  /// ESC/POS: Right alignment
  static String escAlignRight() => '\x1B\x61\x02';

  /// ESC/POS: Cut paper
  static String escCutPaper() => '\x1D\x56\x00';

  /// ESC/POS: Feed paper (n lines)
  static String escFeed(int lines) {
    return '\x1B\x64${String.fromCharCode(lines)}';
  }

  /// Generate receipt with ESC/POS commands
  static String generateReceiptWithESCPOS({
    required String templateType,
    required int paperSize,
    required Map<String, dynamic> data,
  }) {
    final buffer = StringBuffer();
    
    // Initialize printer
    buffer.write(escInit());
    buffer.write(escAlignCenter());
    
    // Generate plain text receipt
    final receipt = generateReceipt(
      templateType: templateType,
      paperSize: paperSize,
      data: data,
    );
    
    buffer.write(receipt);
    
    // Feed and cut
    buffer.write(escFeed(3));
    buffer.write(escCutPaper());
    
    return buffer.toString();
  }
}
