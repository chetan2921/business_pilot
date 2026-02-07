import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Service for scanning receipts and extracting text using ML Kit OCR
class ReceiptScannerService {
  ReceiptScannerService._();
  static final ReceiptScannerService _instance = ReceiptScannerService._();
  static ReceiptScannerService get instance => _instance;

  final _textRecognizer = TextRecognizer();
  final _imagePicker = ImagePicker();

  /// Pick image from camera
  Future<File?> pickFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (image == null) return null;
    return File(image.path);
  }

  /// Pick image from gallery
  Future<File?> pickFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (image == null) return null;
    return File(image.path);
  }

  /// Extract text from image file
  Future<ReceiptScanResult> scanReceipt(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract structured data from recognized text
      final fullText = recognizedText.text;
      final amount = _extractAmount(fullText);
      final date = _extractDate(fullText);
      final vendor = _extractVendor(recognizedText.blocks);

      return ReceiptScanResult(
        rawText: fullText,
        extractedAmount: amount,
        extractedDate: date,
        extractedVendor: vendor,
        imageFile: imageFile,
      );
    } catch (e) {
      // ignore: avoid_print
      print('OCR Error: $e');
      return ReceiptScanResult(
        rawText: '',
        imageFile: imageFile,
        error: e.toString(),
      );
    }
  }

  /// Extract amount from text using regex patterns
  double? _extractAmount(String text) {
    // Common currency patterns for INR
    final patterns = [
      RegExp(
        r'(?:Total|Grand Total|Amount|Net|Subtotal)[:\s]*₹?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(r'₹\s*([\d,]+\.?\d*)'),
      RegExp(r'Rs\.?\s*([\d,]+\.?\d*)'),
      RegExp(r'INR\s*([\d,]+\.?\d*)'),
      RegExp(r'([\d,]+\.?\d*)\s*(?:Total|Grand Total)', caseSensitive: false),
    ];

    double? largestAmount;
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        if (amountStr != null) {
          final amount = double.tryParse(amountStr);
          if (amount != null &&
              (largestAmount == null || amount > largestAmount)) {
            largestAmount = amount;
          }
        }
      }
    }

    return largestAmount;
  }

  /// Extract date from text
  DateTime? _extractDate(String text) {
    // Common date patterns
    final patterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
      RegExp(
        r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+(\d{2,4})',
        caseSensitive: false,
      ),
      RegExp(
        r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+(\d{1,2}),?\s+(\d{2,4})',
        caseSensitive: false,
      ),
    ];

    final monthMap = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (match.groupCount >= 3) {
            final g1 = match.group(1)!;
            final g2 = match.group(2)!;
            final g3 = match.group(3)!;

            int day, month, year;

            // Check if it's a month name pattern
            if (monthMap.containsKey(g1.toLowerCase().substring(0, 3))) {
              month = monthMap[g1.toLowerCase().substring(0, 3)]!;
              day = int.parse(g2);
              year = int.parse(g3);
            } else if (monthMap.containsKey(g2.toLowerCase().substring(0, 3))) {
              day = int.parse(g1);
              month = monthMap[g2.toLowerCase().substring(0, 3)]!;
              year = int.parse(g3);
            } else {
              // Numeric date pattern (DD/MM/YYYY or MM/DD/YYYY)
              day = int.parse(g1);
              month = int.parse(g2);
              year = int.parse(g3);
            }

            // Handle 2-digit years
            if (year < 100) {
              year += year > 50 ? 1900 : 2000;
            }

            return DateTime(year, month, day);
          }
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  /// Extract vendor name (usually at the top of receipt)
  String? _extractVendor(List<TextBlock> blocks) {
    if (blocks.isEmpty) return null;

    // Get the top-most text block as potential vendor name
    final sortedBlocks = [...blocks]
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    for (final block in sortedBlocks.take(3)) {
      final text = block.text.trim();
      // Skip if it looks like a date or number
      if (text.length > 3 &&
          !RegExp(r'^\d+[/-]').hasMatch(text) &&
          !RegExp(r'^[\d\s.,]+$').hasMatch(text)) {
        return text.split('\n').first;
      }
    }

    return null;
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}

/// Result of receipt scanning
class ReceiptScanResult {
  final String rawText;
  final double? extractedAmount;
  final DateTime? extractedDate;
  final String? extractedVendor;
  final File imageFile;
  final String? error;

  ReceiptScanResult({
    required this.rawText,
    this.extractedAmount,
    this.extractedDate,
    this.extractedVendor,
    required this.imageFile,
    this.error,
  });

  bool get hasError => error != null;
  bool get hasData =>
      extractedAmount != null ||
      extractedDate != null ||
      extractedVendor != null;
}
