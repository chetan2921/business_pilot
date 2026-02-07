import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/invoice_model.dart';

/// Service for generating and sharing invoice PDFs
class PdfService {
  PdfService._();
  static final PdfService _instance = PdfService._();
  static PdfService get instance => _instance;

  /// Generate invoice PDF and return file path
  Future<String> generateInvoicePdf(InvoiceModel invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      invoice.invoiceNumber,
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'BusinessPilot',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('Your Business Partner'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // Customer & Dates
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill To:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      invoice.customerName ?? 'N/A',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Issue Date: ${_formatDate(invoice.issueDate)}'),
                    if (invoice.dueDate != null)
                      pw.Text('Due Date: ${_formatDate(invoice.dueDate!)}'),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _getStatusColor(invoice.status),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        invoice.status.displayName.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Items Table
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellPadding: const pw.EdgeInsets.all(8),
              headers: ['Description', 'Qty', 'Unit Price', 'Amount'],
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
              data: invoice.items
                  .map(
                    (item) => [
                      item.description,
                      item.quantity.toString(),
                      '₹${item.unitPrice.toStringAsFixed(2)}',
                      '₹${item.amount.toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 20),

            // Totals
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 200,
                child: pw.Column(
                  children: [
                    _buildTotalRow('Subtotal', invoice.subtotal),
                    if (invoice.taxRate > 0)
                      _buildTotalRow(
                        'Tax (${invoice.taxRate}%)',
                        invoice.taxAmount,
                      ),
                    pw.Divider(),
                    _buildTotalRow('Total', invoice.total, isBold: true),
                  ],
                ),
              ),
            ),
            pw.Spacer(),

            // Notes
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Text(
                'Notes:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(invoice.notes!),
            ],

            // Footer
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  /// Share invoice PDF
  Future<void> shareInvoicePdf(InvoiceModel invoice) async {
    final path = await generateInvoicePdf(invoice);
    final file = XFile(path);

    // Share with position origin for iOS/iPad compatibility
    await Share.shareXFiles(
      [file],
      subject: 'Invoice ${invoice.invoiceNumber}',
      text: 'Please find attached invoice ${invoice.invoiceNumber}',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  PdfColor _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return PdfColors.green;
      case InvoiceStatus.overdue:
        return PdfColors.red;
      case InvoiceStatus.sent:
      case InvoiceStatus.viewed:
        return PdfColors.blue;
      default:
        return PdfColors.grey;
    }
  }

  pw.Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
          ),
          pw.Text(
            '₹${amount.toStringAsFixed(2)}',
            style: isBold
                ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)
                : null,
          ),
        ],
      ),
    );
  }
}
