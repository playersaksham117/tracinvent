import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

class ReceiptService {
  static Future<void> printReceipt({
    required BuildContext context,
    required Sale sale,
    required List<SaleItem> items,
    Customer? customer,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'BILLEASE POS',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Premium Point of Sale',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Thank You for Your Purchase!',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),

            pw.Divider(height: 20, thickness: 2),

            // Sale Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Invoice No:', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  sale.saleNumber,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date:', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  _formatDateTime(sale.createdAt),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),

            if (customer != null) ...[
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Customer:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    customer.name,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              if (customer.phone != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Phone:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      customer.phone!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
            ],

            pw.Divider(height: 16),

            // Items Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'Item',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'Qty',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'Price',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'Total',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            pw.Divider(height: 8),

            // Items List
            ...items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          item.productName,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          item.quantity.toString(),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          '₹${item.unitPrice.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          '₹${item.totalAmount.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),

            pw.Divider(height: 16, thickness: 2),

            // Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  '₹${sale.subtotal.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),

            if (sale.taxAmount > 0) ...[
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tax:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    '₹${sale.taxAmount.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],

            if (sale.discountAmount > 0) ...[
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Discount:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    '-₹${sale.discountAmount.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],

            pw.Divider(height: 12),

            // Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '₹${sale.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),

            pw.Divider(height: 12),

            // Payment Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Payment Method:', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  sale.paymentMethod,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Paid:', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  '₹${sale.paidAmount.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),

            if (sale.changeAmount > 0) ...[
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Change:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    '₹${sale.changeAmount.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],

            pw.Divider(height: 20, thickness: 2),

            // Footer
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Thank you for shopping with us!',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Visit again soon',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Powered by BillEase POS',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Show print dialog
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Receipt_${sale.saleNumber}.pdf',
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
