import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Label Generator for printing product labels with actual barcodes
class LabelGenerator {
  // Label size presets (in mm)
  static const Map<String, Map<String, double>> labelPresets = {
    '40x25': {'width': 40.0, 'height': 25.0},
    '50x25': {'width': 50.0, 'height': 25.0},
    '50x30': {'width': 50.0, 'height': 30.0},
    '60x40': {'width': 60.0, 'height': 40.0},
    '70x40': {'width': 70.0, 'height': 40.0},
    '100x50': {'width': 100.0, 'height': 50.0},
    'Custom': {'width': 40.0, 'height': 25.0},
  };

  /// Label content options
  static const String CONTENT_BARCODE_ONLY = 'barcode_only';
  static const String CONTENT_NAME_PRICE = 'name_price';
  static const String CONTENT_NAME_BARCODE = 'name_barcode';
  static const String CONTENT_FULL = 'full'; // Name, Price, Barcode, SKU

  /// Barcode type options
  static const String BARCODE_CODE128 = 'code128';
  static const String BARCODE_CODE39 = 'code39';
  static const String BARCODE_EAN13 = 'ean13';
  static const String BARCODE_EAN8 = 'ean8';
  static const String BARCODE_UPC_A = 'upca';

  /// Get barcode type from string
  static Barcode getBarcodeType(String type) {
    switch (type) {
      case BARCODE_CODE39:
        return Barcode.code39();
      case BARCODE_EAN13:
        return Barcode.ean13();
      case BARCODE_EAN8:
        return Barcode.ean8();
      case BARCODE_UPC_A:
        return Barcode.upcA();
      case BARCODE_CODE128:
      default:
        return Barcode.code128();
    }
  }

  /// Generate PDF document with barcode labels
  static Future<Uint8List> generateLabelsPdf({
    required List<Product> products,
    required Map<int, int> quantities,
    required String contentType,
    required double labelWidthMm,
    required double labelHeightMm,
    String currencySymbol = '₹',
    bool showSku = true,
    bool showBarcode = true,
    bool showPrice = true,
    bool showName = true,
    bool showMrp = false,
    String? shopName,
    String barcodeType = BARCODE_CODE128,
    String alignment = 'Center + Middle',
  }) async {
    final pdf = pw.Document();
    
    // Convert mm to points (1 mm = 2.83465 points)
    final labelWidth = labelWidthMm * PdfPageFormat.mm;
    final labelHeight = labelHeightMm * PdfPageFormat.mm;

    final barcode = getBarcodeType(barcodeType);

    for (final product in products) {
      final qty = quantities[product.id] ?? 1;
      
      for (int i = 0; i < qty; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(labelWidth, labelHeight),
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              final content = _buildLabelContent(
                product: product,
                contentType: contentType,
                labelWidth: labelWidth,
                labelHeight: labelHeight,
                currencySymbol: currencySymbol,
                showSku: showSku,
                showBarcode: showBarcode,
                showPrice: showPrice,
                showName: showName,
                showMrp: showMrp,
                shopName: shopName,
                barcode: barcode,
                alignment: alignment,
              );
              
              // Full page container with center alignment
              return pw.Container(
                width: labelWidth,
                height: labelHeight,
                alignment: pw.Alignment.center,
                child: content,
              );
            },
          ),
        );
      }
    }

    return pdf.save();
  }
  
  /// Convert alignment string to pw.Alignment (kept for future use)
  // ignore: unused_element
  static pw.Alignment _getAlignmentFromString(String alignment) {
    switch (alignment) {
      case 'Top Left':
        return pw.Alignment.topLeft;
      case 'Top Center':
        return pw.Alignment.topCenter;
      case 'Top Right':
        return pw.Alignment.topRight;
      case 'Center Left':
        return pw.Alignment.centerLeft;
      case 'Center Right':
        return pw.Alignment.centerRight;
      case 'Bottom Left':
        return pw.Alignment.bottomLeft;
      case 'Bottom Center':
        return pw.Alignment.bottomCenter;
      case 'Bottom Right':
        return pw.Alignment.bottomRight;
      case 'Center + Middle':
      case 'Center':
      default:
        return pw.Alignment.center;
    }
  }

  /// Build label content widget for PDF
  static pw.Widget _buildLabelContent({
    required Product product,
    required String contentType,
    required double labelWidth,
    required double labelHeight,
    required String currencySymbol,
    required bool showSku,
    required bool showBarcode,
    required bool showPrice,
    required bool showName,
    required bool showMrp,
    String? shopName,
    required Barcode barcode,
    String alignment = 'Center + Middle',
  }) {
    // Calculate font sizes based on label size
    final nameFontSize = (labelHeight * 0.12).clamp(6.0, 12.0);
    final skuFontSize = (labelHeight * 0.08).clamp(5.0, 9.0);
    final priceFontSize = (labelHeight * 0.14).clamp(7.0, 14.0);
    final shopFontSize = (labelHeight * 0.07).clamp(4.0, 8.0);
    final barcodeHeight = (labelHeight * 0.35).clamp(15.0, 40.0);

    // Get barcode data - use barcode if available, otherwise SKU
    final barcodeData = (product.barcode != null && product.barcode!.isNotEmpty) 
        ? product.barcode! 
        : product.sku;

    // All content is centered within the column - container handles position
    const horizontalAlign = pw.CrossAxisAlignment.center;

    // Build content column based on content type
    switch (contentType) {
      case CONTENT_BARCODE_ONLY:
        return pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: horizontalAlign,
          children: [
            if (barcodeData.isNotEmpty)
              pw.BarcodeWidget(
                barcode: barcode,
                data: barcodeData,
                width: labelWidth * 0.85,
                height: barcodeHeight,
                drawText: true,
                textStyle: pw.TextStyle(fontSize: skuFontSize),
              ),
          ],
        );

      case CONTENT_NAME_PRICE:
        return pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: horizontalAlign,
          children: [
            if (shopName != null && shopName.isNotEmpty)
              pw.Text(
                shopName,
                style: pw.TextStyle(fontSize: shopFontSize, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            if (showName)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Text(
                  _truncateText(product.name, 30),
                  style: pw.TextStyle(fontSize: nameFontSize, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                ),
              ),
            if (showPrice)
              pw.Text(
                '${showMrp ? "MRP: " : ""}$currencySymbol${product.price.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: priceFontSize, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
          ],
        );

      case CONTENT_NAME_BARCODE:
        return pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: horizontalAlign,
          children: [
            if (shopName != null && shopName.isNotEmpty)
              pw.Text(
                shopName,
                style: pw.TextStyle(fontSize: shopFontSize, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            if (showName)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  _truncateText(product.name, 30),
                  style: pw.TextStyle(fontSize: nameFontSize, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                ),
              ),
            if (showBarcode && barcodeData.isNotEmpty)
              pw.BarcodeWidget(
                barcode: barcode,
                data: barcodeData,
                width: labelWidth * 0.85,
                height: barcodeHeight,
                drawText: true,
                textStyle: pw.TextStyle(fontSize: skuFontSize),
              ),
          ],
        );

      case CONTENT_FULL:
      default:
        return pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: horizontalAlign,
          children: [
            // Shop name
            if (shopName != null && shopName.isNotEmpty)
              pw.Text(
                shopName,
                style: pw.TextStyle(fontSize: shopFontSize, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            
            // Product name
            if (showName)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 1, bottom: 1),
                child: pw.Text(
                  _truncateText(product.name, 28),
                  style: pw.TextStyle(fontSize: nameFontSize, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                ),
              ),
            
            // SKU
            if (showSku)
              pw.Text(
                'SKU: ${product.sku}',
                style: pw.TextStyle(fontSize: skuFontSize),
                textAlign: pw.TextAlign.center,
              ),
            
            // Price
            if (showPrice)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 1, bottom: 1),
                child: pw.Text(
                  '${showMrp ? "MRP: " : ""}$currencySymbol${product.price.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: priceFontSize, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            
            // Barcode
            if (showBarcode && barcodeData.isNotEmpty)
              pw.BarcodeWidget(
                barcode: barcode,
                data: barcodeData,
                width: labelWidth * 0.85,
                height: barcodeHeight,
                drawText: true,
                textStyle: pw.TextStyle(fontSize: skuFontSize - 1),
              ),
          ],
        );
    }
  }

  /// Truncate text if too long
  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 2)}..';
  }

  /// Print labels directly using system print dialog
  static Future<bool> printLabels({
    required List<Product> products,
    required Map<int, int> quantities,
    required BuildContext context,
    bool showPreview = false,
  }) async {
    try {
      final settings = await loadLabelSettings();
      
      final pdfData = await generateLabelsPdf(
        products: products,
        quantities: quantities,
        contentType: settings['labelContentType'] ?? CONTENT_FULL,
        labelWidthMm: settings['labelWidth'] ?? 40.0,
        labelHeightMm: settings['labelHeight'] ?? 25.0,
        currencySymbol: settings['currencySymbol'] ?? '₹',
        showSku: settings['labelShowSku'] ?? true,
        showBarcode: settings['labelShowBarcode'] ?? true,
        showPrice: settings['labelShowPrice'] ?? true,
        showName: settings['labelShowName'] ?? true,
        showMrp: settings['labelShowMrp'] ?? false,
        shopName: (settings['labelShowShopName'] ?? false) ? settings['shopName'] : null,
        barcodeType: settings['barcodeType'] ?? BARCODE_CODE128,
        alignment: settings['labelAlignment'] ?? 'Center + Middle',
      );

      final labelWidth = (settings['labelWidth'] ?? 40.0) * PdfPageFormat.mm;
      final labelHeight = (settings['labelHeight'] ?? 25.0) * PdfPageFormat.mm;
      final labelFormat = PdfPageFormat(labelWidth, labelHeight);

      if (showPreview) {
        // Show preview dialog with PDF viewer
        if (!context.mounted) return false;
        
        await showDialog(
          context: context,
          builder: (ctx) => Dialog(
            child: Container(
              width: 700,
              height: 600,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.preview, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'Label Preview (${settings['labelWidth']}mm × ${settings['labelHeight']}mm)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  // PDF Preview - use directPrintPdf for exact output
                  Expanded(
                    child: PdfPreview(
                      build: (format) async => pdfData,
                      initialPageFormat: labelFormat,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      useActions: false,
                      pdfFileName: 'Product_Labels.pdf',
                    ),
                  ),
                  // Bottom action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Print'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            // Print with exact label format - no scaling
                            await Printing.layoutPdf(
                              onLayout: (format) async => pdfData,
                              name: 'Product Labels',
                              format: labelFormat,
                              usePrinterSettings: true,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return true;
      } else {
        // Print directly - use exact format with no scaling
        final result = await Printing.layoutPdf(
          onLayout: (format) async => pdfData,
          name: 'Product Labels',
          format: labelFormat,
          usePrinterSettings: true,
        );
        return result;
      }
    } catch (e) {
      debugPrint('Print error: $e');
      rethrow;
    }
  }

  /// Preview labels before printing (opens visual preview dialog)
  static Future<void> previewLabels({
    required List<Product> products,
    required Map<int, int> quantities,
    required BuildContext context,
  }) async {
    await printLabels(
      products: products,
      quantities: quantities,
      context: context,
      showPreview: true,
    );
  }

  /// Load label settings from SharedPreferences
  static Future<Map<String, dynamic>> loadLabelSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'labelWidth': prefs.getDouble('label_paper_width') ?? 40.0,
      'labelHeight': prefs.getDouble('label_paper_height') ?? 25.0,
      'labelAlignment': prefs.getString('label_alignment') ?? 'Center + Middle',
      'labelContentType': prefs.getString('label_content_type') ?? CONTENT_FULL,
      'labelShowSku': prefs.getBool('label_show_sku') ?? true,
      'labelShowBarcode': prefs.getBool('label_show_barcode') ?? true,
      'labelShowPrice': prefs.getBool('label_show_price') ?? true,
      'labelShowName': prefs.getBool('label_show_name') ?? true,
      'labelShowMrp': prefs.getBool('label_show_mrp') ?? false,
      'labelShowShopName': prefs.getBool('label_show_shop_name') ?? false,
      'shopName': prefs.getString('shop_name') ?? '',
      'currencySymbol': prefs.getString('currency_symbol') ?? '₹',
      'barcodeType': prefs.getString('barcode_type') ?? BARCODE_CODE128,
    };
  }

  /// Save label settings to SharedPreferences
  static Future<void> saveLabelSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    if (settings.containsKey('labelWidth')) {
      await prefs.setDouble('label_paper_width', settings['labelWidth']);
    }
    if (settings.containsKey('labelHeight')) {
      await prefs.setDouble('label_paper_height', settings['labelHeight']);
    }
    if (settings.containsKey('labelAlignment')) {
      await prefs.setString('label_alignment', settings['labelAlignment']);
    }
    if (settings.containsKey('labelContentType')) {
      await prefs.setString('label_content_type', settings['labelContentType']);
    }
    if (settings.containsKey('labelShowSku')) {
      await prefs.setBool('label_show_sku', settings['labelShowSku']);
    }
    if (settings.containsKey('labelShowBarcode')) {
      await prefs.setBool('label_show_barcode', settings['labelShowBarcode']);
    }
    if (settings.containsKey('labelShowPrice')) {
      await prefs.setBool('label_show_price', settings['labelShowPrice']);
    }
    if (settings.containsKey('labelShowName')) {
      await prefs.setBool('label_show_name', settings['labelShowName']);
    }
    if (settings.containsKey('labelShowMrp')) {
      await prefs.setBool('label_show_mrp', settings['labelShowMrp']);
    }
    if (settings.containsKey('labelShowShopName')) {
      await prefs.setBool('label_show_shop_name', settings['labelShowShopName']);
    }
    if (settings.containsKey('barcodeType')) {
      await prefs.setString('barcode_type', settings['barcodeType']);
    }
  }
}
