/// GST Calculator Service
/// Local GST calculation without requiring backend
/// Supports CGST+SGST (intra-state), IGST (inter-state), tax-inclusive pricing
library;

import '../models/models.dart';
import '../models/gst_invoice.dart' as gst;

enum GSTType {
  intraState, // CGST + SGST
  interState, // IGST
  export_,
  sez,
}

/// GST Slab rates as per Indian GST law
class GSTSlabs {
  static const List<double> validRates = [0, 0.1, 0.25, 1, 3, 5, 12, 18, 28];
  
  static double nearestValidRate(double rate) {
    double nearest = validRates[0];
    double minDiff = (rate - nearest).abs();
    
    for (final r in validRates) {
      final diff = (rate - r).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = r;
      }
    }
    return nearest;
  }
}

class GSTCalculator {
  /// Determine GST type based on place of supply
  static GSTType determineGSTType({
    required String companyStateCode,
    required String placeOfSupply,
    bool isExport = false,
    bool isSEZ = false,
  }) {
    if (isExport) return GSTType.export_;
    if (isSEZ) return GSTType.sez;

    if (companyStateCode == placeOfSupply) {
      return GSTType.intraState;
    } else {
      return GSTType.interState;
    }
  }

  /// Calculate tax for a single invoice item
  /// Supports both tax-exclusive and tax-inclusive pricing
  static InvoiceItem calculateItemTax(
    InvoiceItem item,
    GSTType gstType, {
    bool priceIncludesTax = false,
  }) {
    // Step 1: Calculate gross amount
    double grossAmount = item.quantity * item.rate;
    double taxableAmount;
    
    // Step 2: Handle tax-inclusive pricing
    if (priceIncludesTax && item.gstRate > 0) {
      // Reverse calculate taxable amount from inclusive price
      taxableAmount = grossAmount * 100 / (100 + item.gstRate);
    } else {
      taxableAmount = grossAmount;
    }

    // Step 3: Calculate discount
    double discountAmount;
    if (item.discountType == DiscountType.percentage) {
      discountAmount = taxableAmount * item.discountValue / 100;
    } else {
      discountAmount = item.discountValue;
    }

    // Step 4: Final taxable amount after discount
    taxableAmount = taxableAmount - discountAmount;
    
    // Ensure non-negative
    if (taxableAmount < 0) taxableAmount = 0;

    // Step 5: Calculate GST based on type
    double cgstRate = 0, cgstAmount = 0;
    double sgstRate = 0, sgstAmount = 0;
    double igstRate = 0, igstAmount = 0;

    if (gstType == GSTType.intraState) {
      // Split equally between CGST and SGST
      cgstRate = item.gstRate / 2;
      sgstRate = item.gstRate / 2;
      cgstAmount = _round(taxableAmount * cgstRate / 100);
      sgstAmount = _round(taxableAmount * sgstRate / 100);
    } else if (gstType == GSTType.interState ||
        gstType == GSTType.sez ||
        gstType == GSTType.export_) {
      // Full IGST
      igstRate = item.gstRate;
      igstAmount = _round(taxableAmount * igstRate / 100);
    }

    // Step 6: Calculate Cess
    double cessAmount = 0;
    if (item.cessRate > 0) {
      cessAmount = _round(taxableAmount * item.cessRate / 100);
    }

    // Step 7: Calculate total tax
    final totalTaxAmount = cgstAmount + sgstAmount + igstAmount + cessAmount;

    // Step 8: Calculate total amount
    final totalAmount = taxableAmount + totalTaxAmount;

    return item.copyWith(
      discountAmount: _round(discountAmount),
      taxableAmount: _round(taxableAmount),
      cgstRate: cgstRate,
      cgstAmount: cgstAmount,
      sgstRate: sgstRate,
      sgstAmount: sgstAmount,
      igstRate: igstRate,
      igstAmount: igstAmount,
      cessAmount: cessAmount,
      totalTaxAmount: totalTaxAmount,
      totalAmount: _round(totalAmount),
    );
  }

  /// Calculate full invoice with all items
  static GSTInvoice calculateInvoice(
    GSTInvoice invoice,
    String companyStateCode, {
    bool priceIncludesTax = false,
  }) {
    // Determine GST type
    final gstType = determineGSTType(
      companyStateCode: companyStateCode,
      placeOfSupply: invoice.placeOfSupply ?? companyStateCode,
      isExport: invoice.isExport,
    );

    // Calculate each item
    final calculatedItems = <InvoiceItem>[];
    for (final item in invoice.items) {
      calculatedItems.add(calculateItemTax(item, gstType, priceIncludesTax: priceIncludesTax));
    }

    // Calculate totals
    double subtotal = 0;
    double totalDiscount = 0;
    double totalTaxable = 0;
    double totalCGST = 0;
    double totalSGST = 0;
    double totalIGST = 0;
    double totalCess = 0;

    for (final item in calculatedItems) {
      subtotal += item.grossAmount;
      totalDiscount += item.discountAmount;
      totalTaxable += item.taxableAmount;
      totalCGST += item.cgstAmount;
      totalSGST += item.sgstAmount;
      totalIGST += item.igstAmount;
      totalCess += item.cessAmount;
    }

    // Apply invoice-level discount
    if (invoice.discountValue > 0 && totalTaxable > 0) {
      double invoiceDiscount;
      if (invoice.discountType == DiscountType.percentage) {
        invoiceDiscount = totalTaxable * invoice.discountValue / 100;
      } else {
        invoiceDiscount = invoice.discountValue;
      }

      // Reduce taxable and recalculate tax proportionally
      final discountRatio = invoiceDiscount / totalTaxable;
      totalTaxable -= invoiceDiscount;
      totalDiscount += invoiceDiscount;
      totalCGST = _round(totalCGST * (1 - discountRatio));
      totalSGST = _round(totalSGST * (1 - discountRatio));
      totalIGST = _round(totalIGST * (1 - discountRatio));
      totalCess = _round(totalCess * (1 - discountRatio));
    }

    // Total tax
    final totalTax = totalCGST + totalSGST + totalIGST + totalCess;

    // Pre-round total
    final preRoundTotal = totalTaxable +
        totalTax +
        invoice.transportCharges +
        invoice.packingCharges +
        invoice.otherCharges;

    // Round off
    final roundedTotal = preRoundTotal.round().toDouble();
    final roundOff = roundedTotal - preRoundTotal;

    // Grand total
    final grandTotal = roundedTotal;

    // Balance
    final balanceAmount = grandTotal - invoice.paidAmount;
    final paymentStatus = balanceAmount <= 0
        ? gst.PaymentStatus.paid
        : (invoice.paidAmount > 0
            ? gst.PaymentStatus.partial
            : gst.PaymentStatus.unpaid);

    return invoice.copyWith(
      items: calculatedItems,
      subtotal: _round(subtotal),
      discountAmount: _round(totalDiscount),
      taxableAmount: _round(totalTaxable),
      cgstAmount: _round(totalCGST),
      sgstAmount: _round(totalSGST),
      igstAmount: _round(totalIGST),
      cessAmount: _round(totalCess),
      totalTaxAmount: _round(totalTax),
      roundOffAmount: _round(roundOff),
      grandTotal: grandTotal,
      balanceAmount: _round(balanceAmount),
      paymentStatus: paymentStatus,
      amountInWords: _numberToWords(grandTotal),
    );
  }

  /// Generate HSN-wise tax summary
  static List<TaxSummary> getHSNWiseSummary(List<InvoiceItem> items) {
    final hsnMap = <String, TaxSummary>{};

    for (final item in items) {
      final hsn = item.hsnCode ?? '0000';

      if (!hsnMap.containsKey(hsn)) {
        hsnMap[hsn] = TaxSummary(
          hsnCode: hsn,
          gstRate: item.gstRate,
        );
      }

      final existing = hsnMap[hsn]!;
      hsnMap[hsn] = TaxSummary(
        hsnCode: hsn,
        quantity: existing.quantity + item.quantity,
        taxableAmount: existing.taxableAmount + item.taxableAmount,
        gstRate: item.gstRate,
        cgstAmount: existing.cgstAmount + item.cgstAmount,
        sgstAmount: existing.sgstAmount + item.sgstAmount,
        igstAmount: existing.igstAmount + item.igstAmount,
        cessAmount: existing.cessAmount + item.cessAmount,
        totalTax: existing.totalTax + item.totalTaxAmount,
      );
    }

    return hsnMap.values.toList();
  }

  /// Calculate reverse tax (from inclusive price)
  static Map<String, double> calculateReverseTax(
      double amount, double gstRate) {
    final taxable = amount * 100 / (100 + gstRate);
    final tax = amount - taxable;

    return {
      'taxable_amount': _round(taxable),
      'tax_amount': _round(tax),
    };
  }

  /// Round to 2 decimal places
  static double _round(double value) {
    return (value * 100).round() / 100;
  }

  /// Convert number to words (Indian format)
  static String _numberToWords(double number) {
    final int rupees = number.truncate();
    final int paise = ((number - rupees) * 100).round();

    final rupeesWords = _convertToWords(rupees);

    if (paise > 0) {
      final paiseWords = _convertToWords(paise);
      return 'Rupees $rupeesWords and $paiseWords Paise Only';
    }

    return 'Rupees $rupeesWords Only';
  }

  static String _convertToWords(int number) {
    if (number == 0) return 'Zero';

    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen'
    ];

    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety'
    ];

    String words = '';

    // Crores
    if (number >= 10000000) {
      words += '${_convertToWords(number ~/ 10000000)} Crore ';
      number %= 10000000;
    }

    // Lakhs
    if (number >= 100000) {
      words += '${_convertToWords(number ~/ 100000)} Lakh ';
      number %= 100000;
    }

    // Thousands
    if (number >= 1000) {
      words += '${_convertToWords(number ~/ 1000)} Thousand ';
      number %= 1000;
    }

    // Hundreds
    if (number >= 100) {
      words += '${ones[number ~/ 100]} Hundred ';
      number %= 100;
    }

    // Tens and Ones
    if (number > 0) {
      if (words.isNotEmpty) words += 'and ';

      if (number < 20) {
        words += ones[number];
      } else {
        words += tens[number ~/ 10];
        if (number % 10 > 0) {
          words += ' ${ones[number % 10]}';
        }
      }
    }

    return words.trim();
  }
}

/// Extension for currency formatting
extension CurrencyFormat on double {
  String toCurrency({String symbol = '₹', int decimals = 2}) {
    final parts = toStringAsFixed(decimals).split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';

    // Indian number formatting
    String formatted = '';
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      count++;
      formatted = intPart[i] + formatted;
      if (i > 0) {
        if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
          formatted = ',$formatted';
        }
      }
    }

    return '$symbol$formatted${decPart.isNotEmpty ? '.$decPart' : ''}';
  }
}
