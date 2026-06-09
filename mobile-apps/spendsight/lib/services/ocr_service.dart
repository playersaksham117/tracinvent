import 'dart:async';

/// Simulated OCR service for receipt scanning
/// In production, replace with ML Kit, Google Vision API, or similar
class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  /// Process image and extract receipt data
  Future<OCRResult> processReceipt(String imagePath) async {
    // Simulate OCR processing time
    await Future.delayed(const Duration(milliseconds: 800));

    // In production, this would:
    // 1. Load the image
    // 2. Send to OCR API (Google Vision, ML Kit, etc.)
    // 3. Parse the response to extract structured data

    // Simulated extraction based on common receipt patterns
    return OCRResult(
      rawText: _generateSimulatedRawText(),
      extractedData: _simulateDataExtraction(),
      confidence: 0.85,
      processingTime: const Duration(milliseconds: 800),
    );
  }

  /// Extract amount from text using regex patterns
  static double? extractAmount(String text) {
    // Common amount patterns: ₹1,234.56, Rs. 1234, $99.99, Total: 500
    final patterns = [
      RegExp(r'(?:total|amount|grand\s*total)[:\s]*₹?\$?Rs?\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'₹\s*([\d,]+\.?\d*)'),
      RegExp(r'Rs\.?\s*([\d,]+\.?\d*)'),
      RegExp(r'\$\s*([\d,]+\.?\d*)'),
      RegExp(r'([\d,]+\.?\d*)\s*(?:INR|USD)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        if (amountStr != null) {
          return double.tryParse(amountStr);
        }
      }
    }
    return null;
  }

  /// Extract date from text
  static DateTime? extractDate(String text) {
    // Common date patterns
    final patterns = [
      // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'),
      // YYYY-MM-DD
      RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'),
      // DD Mon YYYY
      RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+(\d{4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (pattern.pattern.contains('Jan|Feb')) {
            // Month name format
            final day = int.parse(match.group(1)!);
            final monthStr = match.group(2)!.toLowerCase();
            final year = int.parse(match.group(3)!);
            final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 
                          'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
            final month = months.indexOf(monthStr.substring(0, 3)) + 1;
            return DateTime(year, month, day);
          } else if (pattern.pattern.startsWith(r'(\d{4})')) {
            // YYYY-MM-DD
            return DateTime(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
            );
          } else {
            // DD/MM/YYYY
            return DateTime(
              int.parse(match.group(3)!),
              int.parse(match.group(2)!),
              int.parse(match.group(1)!),
            );
          }
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  /// Extract GST number
  static String? extractGSTNumber(String text) {
    // Indian GST format: 22AAAAA0000A1Z5
    final gstPattern = RegExp(r'\d{2}[A-Z]{5}\d{4}[A-Z]\d[Z][A-Z\d]');
    final match = gstPattern.firstMatch(text.toUpperCase());
    return match?.group(0);
  }

  /// Extract GST amount
  static Map<String, double>? extractGSTAmounts(String text) {
    final cgst = _extractTaxAmount(text, ['cgst', 'central gst']);
    final sgst = _extractTaxAmount(text, ['sgst', 'state gst']);
    final igst = _extractTaxAmount(text, ['igst', 'integrated gst']);
    final gst = _extractTaxAmount(text, ['gst', 'tax']);

    if (cgst != null || sgst != null || igst != null || gst != null) {
      return {
        if (cgst != null) 'cgst': cgst,
        if (sgst != null) 'sgst': sgst,
        if (igst != null) 'igst': igst,
        if (gst != null && cgst == null && sgst == null && igst == null) 'gst': gst,
      };
    }
    return null;
  }

  static double? _extractTaxAmount(String text, List<String> keywords) {
    for (final keyword in keywords) {
      final pattern = RegExp(
        '$keyword[:\\s]*₹?\\s*([\\d,]+\\.?\\d*)',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(text);
      if (match != null) {
        return double.tryParse(match.group(1)?.replaceAll(',', '') ?? '');
      }
    }
    return null;
  }

  /// Detect category from merchant/items
  static String detectCategory(String text) {
    final textLower = text.toLowerCase();
    
    final categoryKeywords = {
      'Food': ['restaurant', 'cafe', 'food', 'dining', 'pizza', 'burger', 
               'coffee', 'tea', 'lunch', 'dinner', 'breakfast', 'swiggy', 
               'zomato', 'hotel'],
      'Transport': ['uber', 'ola', 'cab', 'taxi', 'fuel', 'petrol', 'diesel',
                   'parking', 'metro', 'bus', 'train', 'flight', 'airline'],
      'Shopping': ['amazon', 'flipkart', 'mall', 'store', 'shop', 'retail',
                  'fashion', 'clothing', 'electronics', 'myntra'],
      'Bills': ['electricity', 'water', 'gas', 'internet', 'broadband', 
                'mobile', 'recharge', 'bill', 'utility'],
      'Health': ['hospital', 'clinic', 'pharmacy', 'medicine', 'doctor',
                'medical', 'health', 'apollo', 'diagnostic'],
      'Entertainment': ['movie', 'cinema', 'pvr', 'inox', 'netflix', 
                       'spotify', 'game', 'concert', 'event'],
      'Groceries': ['grocery', 'supermarket', 'bigbasket', 'blinkit',
                   'vegetables', 'fruits', 'dairy', 'milk'],
    };

    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (textLower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'Other';
  }

  String _generateSimulatedRawText() {
    return '''
RETAIL STORE
123 Main Street
Date: 01/02/2026
Time: 14:30

Items:
Coffee Beans        ₹450.00
Organic Tea         ₹320.00
Snacks              ₹180.00
-----------------------
Subtotal:           ₹950.00
CGST (9%):          ₹85.50
SGST (9%):          ₹85.50
-----------------------
TOTAL:              ₹1,121.00

Payment: UPI
Thank you for shopping!
GST No: 27AABCU9603R1ZM
''';
  }

  Map<String, dynamic> _simulateDataExtraction() {
    return {
      'amount': 950.00,
      'total': 1121.00,
      'cgst': 85.50,
      'sgst': 85.50,
      'date': DateTime.now().toIso8601String(),
      'category': 'Shopping',
      'merchant': 'RETAIL STORE',
      'gstNumber': '27AABCU9603R1ZM',
      'paymentMode': 'upi',
    };
  }
}

/// Result from OCR processing
class OCRResult {
  final String rawText;
  final Map<String, dynamic> extractedData;
  final double confidence;
  final Duration processingTime;

  OCRResult({
    required this.rawText,
    required this.extractedData,
    required this.confidence,
    required this.processingTime,
  });

  double? get amount => extractedData['amount'] as double?;
  double? get total => extractedData['total'] as double?;
  String? get category => extractedData['category'] as String?;
  String? get merchant => extractedData['merchant'] as String?;
  String? get gstNumber => extractedData['gstNumber'] as String?;
  double? get cgst => extractedData['cgst'] as double?;
  double? get sgst => extractedData['sgst'] as double?;
  
  DateTime? get date {
    final dateStr = extractedData['date'] as String?;
    if (dateStr != null) {
      return DateTime.tryParse(dateStr);
    }
    return null;
  }
}
