/// Invoice PDF Service
/// Generates GST-compliant PDF invoices for printing, sharing via WhatsApp, etc.
library;

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

class InvoicePdfService {
  /// Generate PDF for a GST Invoice
  static Future<Uint8List> generateInvoicePdf({
    required GSTInvoice invoice,
    required CompanyProfile company,
    bool isDuplicate = false,
    bool isOriginal = true,
  }) async {
    final pdf = pw.Document();
    
    // Load fonts
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    
    final textStyle = pw.TextStyle(font: regularFont, fontSize: 9);
    final boldStyle = pw.TextStyle(font: boldFont, fontSize: 9);
    final headerStyle = pw.TextStyle(font: boldFont, fontSize: 11);
    final titleStyle = pw.TextStyle(font: boldFont, fontSize: 14);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          company: company,
          invoice: invoice,
          titleStyle: titleStyle,
          headerStyle: headerStyle,
          textStyle: textStyle,
          boldStyle: boldStyle,
          isDuplicate: isDuplicate,
          isOriginal: isOriginal,
        ),
        footer: (context) => _buildFooter(
          company: company,
          textStyle: textStyle,
          boldStyle: boldStyle,
          pageNumber: context.pageNumber,
          totalPages: context.pagesCount,
        ),
        build: (context) => [
          // Party Details
          _buildPartySection(invoice, textStyle, boldStyle),
          pw.SizedBox(height: 15),
          
          // Items Table
          _buildItemsTable(invoice, textStyle, boldStyle, headerStyle),
          pw.SizedBox(height: 15),
          
          // Tax Summary & Totals
          _buildTotalsSection(invoice, textStyle, boldStyle, headerStyle),
          pw.SizedBox(height: 15),
          
          // Amount in Words
          _buildAmountInWords(invoice, textStyle, boldStyle),
          pw.SizedBox(height: 20),
          
          // Bank Details & Signature
          _buildBankAndSignature(company, textStyle, boldStyle),
          pw.SizedBox(height: 15),
          
          // Terms & Conditions
          if (invoice.termsConditions != null || company.termsAndConditions != null)
            _buildTerms(invoice, company, textStyle),
        ],
      ),
    );
    
    return pdf.save();
  }
  
  static pw.Widget _buildHeader({
    required CompanyProfile company,
    required GSTInvoice invoice,
    required pw.TextStyle titleStyle,
    required pw.TextStyle headerStyle,
    required pw.TextStyle textStyle,
    required pw.TextStyle boldStyle,
    bool isDuplicate = false,
    bool isOriginal = true,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Copy Type Badge
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TAX INVOICE', style: titleStyle),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                isDuplicate ? 'DUPLICATE' : (isOriginal ? 'ORIGINAL FOR RECIPIENT' : 'DUPLICATE FOR SUPPLIER'),
                style: textStyle.copyWith(fontSize: 8),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        
        // Company Details
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(company.companyName, style: headerStyle),
                  pw.SizedBox(height: 2),
                  pw.Text(company.addressLine1, style: textStyle),
                  if (company.addressLine2 != null && company.addressLine2!.isNotEmpty)
                    pw.Text(company.addressLine2!, style: textStyle),
                  pw.Text(
                    '${company.city}, ${company.stateName} - ${company.pincode}',
                    style: textStyle,
                  ),
                  pw.SizedBox(height: 4),
                  // Always show GSTIN/PAN lines in header (display '-' when not set)
                  pw.Text('GSTIN: ${company.gstin ?? '-'}', style: boldStyle),
                  pw.Text('PAN: ${company.pan ?? '-'}', style: boldStyle),
                  if (company.phone != null)
                    pw.Text('Phone: ${company.phone}', style: textStyle),
                  if (company.email != null)
                    pw.Text('Email: ${company.email}', style: textStyle),
                ],
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _invoiceDetailRow('Invoice No:', invoice.invoiceNumber ?? 'DRAFT', boldStyle, textStyle),
                  _invoiceDetailRow('Date:', _formatDate(invoice.invoiceDate), boldStyle, textStyle),
                  if (invoice.dueDate != null)
                    _invoiceDetailRow('Due Date:', _formatDate(invoice.dueDate!), boldStyle, textStyle),
                  pw.SizedBox(height: 4),
                  _invoiceDetailRow('Place of Supply:', invoice.placeOfSupply ?? '-', boldStyle, textStyle),
                  if (invoice.isReverseCharge)
                    pw.Text('Reverse Charge: Yes', style: textStyle),
                ],
              ),
            ),
          ],
        ),
        pw.Divider(thickness: 0.5),
      ],
    );
  }
  
  static pw.Widget _buildPartySection(
    GSTInvoice invoice,
    pw.TextStyle textStyle,
    pw.TextStyle boldStyle,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill To:', style: boldStyle),
              pw.SizedBox(height: 4),
              pw.Text(invoice.billingName ?? invoice.partyName, style: boldStyle),
              if (invoice.billingAddress != null)
                pw.Text(invoice.billingAddress!, style: textStyle),
              if (invoice.billingCity != null || invoice.billingPincode != null)
                pw.Text(
                  '${invoice.billingCity ?? ''}, ${invoice.billingStateCode ?? ''} - ${invoice.billingPincode ?? ''}'.trim(),
                  style: textStyle,
                ),
              if (invoice.partyGstin != null)
                pw.Text('GSTIN: ${invoice.partyGstin}', style: boldStyle),
            ],
          ),
        ),
        if (invoice.shippingAddress != null)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Ship To:', style: boldStyle),
                pw.SizedBox(height: 4),
                pw.Text(invoice.shippingName ?? invoice.partyName, style: boldStyle),
                pw.Text(invoice.shippingAddress!, style: textStyle),
                if (invoice.shippingCity != null || invoice.shippingPincode != null)
                  pw.Text(
                    '${invoice.shippingCity ?? ''}, ${invoice.shippingStateCode ?? ''} - ${invoice.shippingPincode ?? ''}'.trim(),
                    style: textStyle,
                  ),
              ],
            ),
          ),
      ],
    );
  }
  
  static pw.Widget _buildItemsTable(
    GSTInvoice invoice,
    pw.TextStyle textStyle,
    pw.TextStyle boldStyle,
    pw.TextStyle headerStyle,
  ) {
    final isInterState = invoice.igstAmount > 0;
    
    final headers = [
      '#',
      'Item Description',
      'HSN/SAC',
      'Qty',
      'Unit',
      'Rate',
      'Disc',
      'Taxable',
      if (!isInterState) 'CGST',
      if (!isInterState) 'SGST',
      if (isInterState) 'IGST',
      'Amount',
    ];
    
    final rows = invoice.items.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      
      return [
        '${idx + 1}',
        item.itemName,
        item.hsnCode ?? '-',
        item.quantity.toStringAsFixed(2),
        item.unitCode ?? 'NOS',
        _formatCurrency(item.rate),
        item.discountAmount > 0 ? _formatCurrency(item.discountAmount) : '-',
        _formatCurrency(item.taxableAmount),
        if (!isInterState) '${item.cgstRate}%\n${_formatCurrency(item.cgstAmount)}',
        if (!isInterState) '${item.sgstRate}%\n${_formatCurrency(item.sgstAmount)}',
        if (isInterState) '${item.igstRate}%\n${_formatCurrency(item.igstAmount)}',
        _formatCurrency(item.totalAmount),
      ];
    }).toList();
    
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      cellStyle: textStyle,
      headerStyle: boldStyle.copyWith(color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
        7: pw.Alignment.centerRight,
        8: pw.Alignment.centerRight,
        9: pw.Alignment.centerRight,
        10: pw.Alignment.centerRight,
        11: pw.Alignment.centerRight,
      },
      border: pw.TableBorder.all(color: PdfColors.grey400),
    );
  }
  
  static pw.Widget _buildTotalsSection(
    GSTInvoice invoice,
    pw.TextStyle textStyle,
    pw.TextStyle boldStyle,
    pw.TextStyle headerStyle,
  ) {
    final isInterState = invoice.igstAmount > 0;
    
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // HSN Summary (GSTR-1 ready)
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('HSN/SAC Summary', style: boldStyle),
              pw.SizedBox(height: 5),
              pw.TableHelper.fromTextArray(
                headers: ['HSN/SAC', 'Taxable', 'Tax Rate', isInterState ? 'IGST' : 'CGST', if (!isInterState) 'SGST', 'Total Tax'],
                data: _getHSNSummary(invoice).map((s) => [
                  s.hsnCode,
                  _formatCurrency(s.taxableAmount),
                  '${s.gstRate}%',
                  _formatCurrency(isInterState ? s.igstAmount : s.cgstAmount),
                  if (!isInterState) _formatCurrency(s.sgstAmount),
                  _formatCurrency(s.totalTax),
                ]).toList(),
                cellStyle: textStyle.copyWith(fontSize: 8),
                headerStyle: boldStyle.copyWith(fontSize: 8),
                border: pw.TableBorder.all(color: PdfColors.grey400),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        
        // Totals
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              children: [
                _totalRow('Subtotal', invoice.subtotal, textStyle),
                if (invoice.discountAmount > 0)
                  _totalRow('Discount', -invoice.discountAmount, textStyle),
                _totalRow('Taxable Amount', invoice.taxableAmount, textStyle),
                if (!isInterState) ...[
                  _totalRow('CGST', invoice.cgstAmount, textStyle),
                  _totalRow('SGST', invoice.sgstAmount, textStyle),
                ] else
                  _totalRow('IGST', invoice.igstAmount, textStyle),
                if (invoice.cessAmount > 0)
                  _totalRow('Cess', invoice.cessAmount, textStyle),
                if (invoice.transportCharges > 0)
                  _totalRow('Transport', invoice.transportCharges, textStyle),
                if (invoice.packingCharges > 0)
                  _totalRow('Packing', invoice.packingCharges, textStyle),
                if (invoice.otherCharges > 0)
                  _totalRow('Other Charges', invoice.otherCharges, textStyle),
                _totalRow('Round Off', invoice.roundOffAmount, textStyle),
                pw.Divider(thickness: 0.5),
                _totalRow('Grand Total', invoice.grandTotal, headerStyle),
                pw.Divider(thickness: 0.5),
                if (invoice.paidAmount > 0)
                  _totalRow('Paid Amount', invoice.paidAmount, textStyle),
                if (invoice.balanceAmount > 0)
                  _totalRow('Balance Due', invoice.balanceAmount, boldStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  static pw.Widget _buildAmountInWords(
    GSTInvoice invoice,
    pw.TextStyle textStyle,
    pw.TextStyle boldStyle,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Amount in Words:', style: textStyle),
          pw.SizedBox(height: 2),
          pw.Text(invoice.amountInWords ?? '', style: boldStyle),
        ],
      ),
    );
  }
  
  static pw.Widget _buildBankAndSignature(
    CompanyProfile company,
    pw.TextStyle textStyle,
    pw.TextStyle boldStyle,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Bank Details
        if (company.bankName != null)
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Bank Details:', style: boldStyle),
                  pw.SizedBox(height: 5),
                  pw.Text('Bank: ${company.bankName}', style: textStyle),
                  if (company.bankAccountNumber != null)
                    pw.Text('A/C No: ${company.bankAccountNumber}', style: textStyle),
                  if (company.bankIfsc != null)
                    pw.Text('IFSC: ${company.bankIfsc}', style: textStyle),
                  if (company.bankBranch != null)
                    pw.Text('Branch: ${company.bankBranch}', style: textStyle),
                ],
              ),
            ),
          ),
        pw.SizedBox(width: 20),
        
        // Signature
        pw.Expanded(
          child: pw.Container(
            height: 80,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('For ${company.companyName}', style: boldStyle),
                pw.Text('Authorised Signatory', style: textStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  static pw.Widget _buildTerms(
    GSTInvoice invoice,
    CompanyProfile company,
    pw.TextStyle textStyle,
  ) {
    final terms = invoice.termsConditions ?? company.termsAndConditions ?? '';
    
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Terms & Conditions:', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(terms, style: textStyle.copyWith(fontSize: 7)),
        ],
      ),
    );
  }
  
  static pw.Widget _buildFooter({
    required CompanyProfile company,
    required pw.TextStyle textStyle,
    required pw.TextStyle boldStyle,
    required int pageNumber,
    required int totalPages,
  }) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'This is a computer generated invoice',
            style: textStyle.copyWith(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page $pageNumber of $totalPages',
            style: textStyle.copyWith(fontSize: 8),
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  static pw.Widget _invoiceDetailRow(String label, String value, pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(label, style: labelStyle),
          pw.SizedBox(width: 8),
          pw.Text(value, style: valueStyle),
        ],
      ),
    );
  }
  
  static pw.Widget _totalRow(String label, double amount, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(_formatCurrency(amount), style: style),
        ],
      ),
    );
  }
  
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  static String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    
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
    
    return '${isNegative ? '-' : ''}₹$formatted.$decPart';
  }
  
  static List<TaxSummary> _getHSNSummary(GSTInvoice invoice) {
    final hsnMap = <String, TaxSummary>{};
    
    for (final item in invoice.items) {
      final hsn = item.hsnCode ?? '0000';
      
      if (!hsnMap.containsKey(hsn)) {
        hsnMap[hsn] = TaxSummary(hsnCode: hsn, gstRate: item.gstRate);
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
  
  /// Print the invoice directly
  static Future<void> printInvoice({
    required GSTInvoice invoice,
    required CompanyProfile company,
    bool isDuplicate = false,
  }) async {
    final pdfData = await generateInvoicePdf(
      invoice: invoice,
      company: company,
      isDuplicate: isDuplicate,
    );
    
    await Printing.layoutPdf(
      onLayout: (_) => pdfData,
      name: 'Invoice_${invoice.invoiceNumber ?? 'DRAFT'}',
    );
  }
  
  /// Share invoice via system share dialog (WhatsApp, Email, etc.)
  static Future<void> shareInvoice({
    required GSTInvoice invoice,
    required CompanyProfile company,
  }) async {
    final pdfData = await generateInvoicePdf(
      invoice: invoice,
      company: company,
    );
    
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'Invoice_${invoice.invoiceNumber ?? 'DRAFT'}.pdf',
    );
  }
}
