import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/product_model.dart';

/// Service for generating and printing barcodes
class BarcodeGeneratorService {
  BarcodeGeneratorService._();
  static final BarcodeGeneratorService _instance = BarcodeGeneratorService._();
  static BarcodeGeneratorService get instance => _instance;

  /// Generate a unique barcode for a product
  String generateBarcodeData(String productId) {
    // Generate EAN-13 compatible code (12 digits + check digit)
    // Use timestamp and product ID hash to ensure uniqueness
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = productId.hashCode.abs().toString().padLeft(6, '0');
    final code =
        '${timestamp.substring(timestamp.length - 6)}${hash.substring(0, 6)}';

    // Calculate EAN-13 check digit
    final checkDigit = _calculateEAN13CheckDigit(code);
    return '$code$checkDigit';
  }

  /// Calculate EAN-13 check digit
  int _calculateEAN13CheckDigit(String code) {
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(code[i]);
      sum += digit * (i.isEven ? 1 : 3);
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit;
  }

  /// Generate barcode SVG string
  String generateBarcodeSvg(
    String data, {
    double width = 200,
    double height = 80,
  }) {
    final barcode = Barcode.code128();
    return barcode.toSvg(data, width: width, height: height);
  }

  /// Generate barcode as image bytes (PNG)
  Uint8List generateBarcodeImage(
    String data, {
    int width = 200,
    int height = 80,
  }) {
    final barcode = Barcode.code128();
    final svg = barcode.toSvg(
      data,
      width: width.toDouble(),
      height: height.toDouble(),
    );
    // Note: For actual image, we'd need to use a SVG renderer
    // For PDF printing, we use the barcode widget directly
    return Uint8List.fromList(svg.codeUnits);
  }

  /// Print barcode label for a product
  Future<void> printBarcodeLabel(ProductModel product) async {
    final pdf = pw.Document();

    // Use product barcode or generate one
    final barcodeData = product.barcode ?? generateBarcodeData(product.id);

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          5 * PdfPageFormat.cm,
          3 * PdfPageFormat.cm,
          marginAll: 0.2 * PdfPageFormat.cm,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // Product name
              pw.Text(
                product.name,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
              ),
              pw.SizedBox(height: 4),
              // Barcode
              pw.BarcodeWidget(
                barcode: Barcode.code128(),
                data: barcodeData,
                width: 4 * PdfPageFormat.cm,
                height: 1.2 * PdfPageFormat.cm,
              ),
              pw.SizedBox(height: 2),
              // Price
              pw.Text(
                product.formattedPrice,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              // Barcode number
              pw.Text(barcodeData, style: const pw.TextStyle(fontSize: 8)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'barcode_${product.name}',
    );
  }

  /// Generate PDF with multiple barcode labels (sheet printing)
  Future<Uint8List> generateBarcodeSheet(
    List<ProductModel> products, {
    int labelsPerRow = 3,
    int rowsPerPage = 8,
  }) async {
    final pdf = pw.Document();
    final labelsPerPage = labelsPerRow * rowsPerPage;
    final pageCount = (products.length / labelsPerPage).ceil();

    for (int page = 0; page < pageCount; page++) {
      final startIndex = page * labelsPerPage;
      final endIndex = (startIndex + labelsPerPage).clamp(0, products.length);
      final pageProducts = products.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10),
          build: (context) {
            final rows = <pw.TableRow>[];

            for (int r = 0; r < rowsPerPage; r++) {
              final rowStart = r * labelsPerRow;
              if (rowStart >= pageProducts.length) break;

              final cells = <pw.Widget>[];
              for (int c = 0; c < labelsPerRow; c++) {
                final index = rowStart + c;
                if (index < pageProducts.length) {
                  cells.add(_buildLabelCell(pageProducts[index]));
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

    return pdf.save();
  }

  pw.Widget _buildLabelCell(ProductModel product) {
    final barcodeData = product.barcode ?? generateBarcodeData(product.id);

    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      height: 3 * PdfPageFormat.cm,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            product.name,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
          pw.SizedBox(height: 2),
          pw.BarcodeWidget(
            barcode: Barcode.code128(),
            data: barcodeData,
            width: 5.5 * PdfPageFormat.cm,
            height: 1 * PdfPageFormat.cm,
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                product.formattedPrice,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(barcodeData, style: const pw.TextStyle(fontSize: 6)),
            ],
          ),
        ],
      ),
    );
  }

  /// Print sheet of barcode labels
  Future<void> printBarcodeSheet(List<ProductModel> products) async {
    final pdfBytes = await generateBarcodeSheet(products);

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'barcode_labels',
    );
  }
}
