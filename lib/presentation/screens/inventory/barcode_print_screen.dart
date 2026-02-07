import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';

/// Barcode print preview screen with organized layout
class BarcodePrintScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const BarcodePrintScreen({super.key, required this.product});

  @override
  ConsumerState<BarcodePrintScreen> createState() => _BarcodePrintScreenState();
}

class _BarcodePrintScreenState extends ConsumerState<BarcodePrintScreen> {
  int _copies = 1;
  bool _isPrinting = false;
  String? _barcodeData;

  @override
  void initState() {
    super.initState();
    _barcodeData = widget.product.barcode ?? _generateBarcode();
  }

  String _generateBarcode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = widget.product.id.hashCode.abs().toString().padLeft(6, '0');
    final code =
        '${timestamp.substring(timestamp.length - 6)}${hash.substring(0, 6)}';
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(code[i]);
      sum += digit * (i.isEven ? 1 : 3);
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return '$code$checkDigit';
  }

  void _incrementCopies() {
    setState(() {
      _copies = (_copies + 1).clamp(1, 100);
    });
  }

  void _decrementCopies() {
    setState(() {
      _copies = (_copies - 1).clamp(1, 100);
    });
  }

  Future<void> _printLabels() async {
    if (_barcodeData == null) return;

    setState(() => _isPrinting = true);

    try {
      final pdf = pw.Document();

      // Create pages with multiple labels
      final labelsPerRow = 3;
      final rowsPerPage = 8;
      final labelsPerPage = labelsPerRow * rowsPerPage;
      final pageCount = (_copies / labelsPerPage).ceil();

      for (int page = 0; page < pageCount; page++) {
        final labelsOnThisPage = (_copies - page * labelsPerPage).clamp(
          0,
          labelsPerPage,
        );

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(10),
            build: (context) {
              final rows = <pw.TableRow>[];

              for (int r = 0; r < rowsPerPage; r++) {
                final rowStart = r * labelsPerRow;
                if (rowStart >= labelsOnThisPage) break;

                final cells = <pw.Widget>[];
                for (int c = 0; c < labelsPerRow; c++) {
                  final index = rowStart + c;
                  if (index < labelsOnThisPage) {
                    cells.add(_buildPdfLabel());
                  } else {
                    cells.add(pw.SizedBox());
                  }
                }
                rows.add(pw.TableRow(children: cells));
              }

              return pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: rows,
              );
            },
          ),
        );
      }

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'barcode_${widget.product.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  pw.Widget _buildPdfLabel() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      height: 3 * PdfPageFormat.cm,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            widget.product.name,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
          pw.SizedBox(height: 2),
          pw.BarcodeWidget(
            barcode: Barcode.code128(),
            data: _barcodeData!,
            width: 5.5 * PdfPageFormat.cm,
            height: 1 * PdfPageFormat.cm,
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                widget.product.formattedPrice,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(_barcodeData!, style: const pw.TextStyle(fontSize: 6)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy barcode',
            onPressed: () {
              if (_barcodeData != null) {
                Clipboard.setData(ClipboardData(text: _barcodeData!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Barcode copied to clipboard')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMd),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          product.category.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.formattedPrice,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (product.sku != null)
                            Text(
                              'SKU: ${product.sku}',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Barcode Preview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLg),
                child: Column(
                  children: [
                    Text(
                      'Barcode Preview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Visual Barcode
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (_barcodeData != null)
                            bw.BarcodeWidget(
                              barcode: bw.Barcode.code128(),
                              data: _barcodeData!,
                              width: 200,
                              height: 60,
                              drawText: false,
                              color: Colors.black,
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.formattedPrice,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                _barcodeData ?? '',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Barcode number
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.numbers,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _barcodeData ?? 'No barcode',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Number of Copies Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Print Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Number of copies',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Decrement button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(12),
                                  ),
                                  onTap: _copies > 1 ? _decrementCopies : null,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.remove,
                                      color: _copies > 1
                                          ? colorScheme.primary
                                          : colorScheme.outline,
                                    ),
                                  ),
                                ),
                              ),
                              // Counter display
                              Container(
                                width: 60,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  border: Border.symmetric(
                                    vertical: BorderSide(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '$_copies',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                ),
                              ),
                              // Increment button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(12),
                                  ),
                                  onTap: _copies < 100
                                      ? _incrementCopies
                                      : null,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.add,
                                      color: _copies < 100
                                          ? colorScheme.primary
                                          : colorScheme.outline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Labels will be printed on A4 sheet (24 labels per page)',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Print Button
            FilledButton.icon(
              onPressed: _isPrinting ? null : _printLabels,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _isPrinting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.print),
              label: Text(
                _isPrinting
                    ? 'Preparing...'
                    : 'Print $_copies ${_copies == 1 ? 'Label' : 'Labels'}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
