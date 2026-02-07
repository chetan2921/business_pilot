import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'analytics_service.dart';
import 'ai_analytics_service.dart';

/// Service for generating PDF reports
class ReportGeneratorService {
  ReportGeneratorService._();
  static final ReportGeneratorService _instance = ReportGeneratorService._();
  static ReportGeneratorService get instance => _instance;

  final _analyticsService = AnalyticsService.instance;
  final _aiAnalyticsService = AiAnalyticsService.instance;

  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final _dateFormat = DateFormat('dd MMM yyyy');

  // ============================================================
  // COMPREHENSIVE BUSINESS REPORT
  // ============================================================

  /// Generate comprehensive business report PDF
  Future<Uint8List> generateBusinessReport() async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Fetch all data
    final dashboard = await _analyticsService.getDashboardData();
    final healthScore = await _aiAnalyticsService.calculateBusinessHealth();
    final trendPrediction = await _aiAnalyticsService.predictRevenueTrend();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('Business Report', now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Business Health Score
          _buildSectionTitle('Business Health Score'),
          _buildHealthScoreSection(healthScore),
          pw.SizedBox(height: 20),

          // Revenue Overview
          _buildSectionTitle('Revenue Overview'),
          _buildRevenueSection(dashboard.revenueTrend, trendPrediction),
          pw.SizedBox(height: 20),

          // Inventory Value
          _buildSectionTitle('Inventory Value'),
          _buildInventorySection(dashboard.inventoryValue),
          pw.SizedBox(height: 20),

          // Top Products
          _buildSectionTitle('Top Performing Products'),
          _buildTopProductsSection(dashboard.topProducts),
          pw.SizedBox(height: 20),

          // Category Profit
          _buildSectionTitle('Profit by Category'),
          _buildCategoryProfitSection(dashboard.categoryProfit),
          pw.SizedBox(height: 20),

          // Recommendations
          _buildSectionTitle('AI Recommendations'),
          _buildRecommendationsSection(healthScore.recommendations),
        ],
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // REVENUE REPORT
  // ============================================================

  /// Generate revenue-focused report PDF
  Future<Uint8List> generateRevenueReport() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final revenueTrend = await _analyticsService.getRevenueTrend();
    final revenueData = await _analyticsService.getRevenueData(
      startDate: thirtyDaysAgo,
      endDate: now,
    );
    final trendPrediction = await _aiAnalyticsService.predictRevenueTrend();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('Revenue Report', now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary
          _buildSectionTitle('Revenue Summary (Last 30 Days)'),
          _buildKeyValueRow(
            'Current Period',
            _currencyFormat.format(revenueTrend.currentPeriodRevenue),
          ),
          _buildKeyValueRow(
            'Previous Period',
            _currencyFormat.format(revenueTrend.previousPeriodRevenue),
          ),
          _buildKeyValueRow(
            'Growth',
            '${revenueTrend.changePercent.toStringAsFixed(1)}%',
          ),
          pw.SizedBox(height: 20),

          // Prediction
          _buildSectionTitle('AI Revenue Forecast'),
          _buildKeyValueRow('Trend Direction', trendPrediction.directionLabel),
          _buildKeyValueRow(
            'Projected Revenue (30 days)',
            _currencyFormat.format(trendPrediction.projectedRevenue),
          ),
          _buildKeyValueRow(
            'Confidence',
            '${(trendPrediction.confidence * 100).toInt()}%',
          ),
          pw.SizedBox(height: 20),

          // Daily breakdown
          _buildSectionTitle('Daily Revenue Breakdown'),
          _buildRevenueTable(revenueData),
        ],
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // INVENTORY REPORT
  // ============================================================

  /// Generate inventory value report PDF
  Future<Uint8List> generateInventoryReport() async {
    final pdf = pw.Document();
    final now = DateTime.now();

    final inventoryValue = await _analyticsService.getInventoryValueReport();
    final categoryProfit = await _analyticsService.getProfitByCategory();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('Inventory Value Report', now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary
          _buildSectionTitle('Inventory Value Summary'),
          _buildKeyValueRow(
            'Total Cost Value',
            _currencyFormat.format(inventoryValue.totalCostValue),
          ),
          _buildKeyValueRow(
            'Total Retail Value',
            _currencyFormat.format(inventoryValue.totalRetailValue),
          ),
          _buildKeyValueRow(
            'Potential Profit',
            _currencyFormat.format(inventoryValue.totalPotentialProfit),
          ),
          _buildKeyValueRow(
            'Average Margin',
            '${inventoryValue.avgProfitMargin.toStringAsFixed(1)}%',
          ),
          _buildKeyValueRow('Total Units', '${inventoryValue.totalUnits}'),
          pw.SizedBox(height: 20),

          // By Category
          _buildSectionTitle('Value by Category'),
          ...inventoryValue.valueByCategory.entries.map(
            (e) => _buildKeyValueRow(
              e.key.toUpperCase(),
              _currencyFormat.format(e.value),
            ),
          ),
          pw.SizedBox(height: 20),

          // Profit by category
          _buildSectionTitle('Profit Analysis by Category'),
          _buildCategoryProfitTable(categoryProfit),
        ],
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // EXPENSE REPORT
  // ============================================================

  /// Generate expense breakdown report PDF
  Future<Uint8List> generateExpenseReport() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final expenses = await _analyticsService.getExpenseBreakdown(
      startDate: thirtyDaysAgo,
      endDate: now,
    );

    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('Expense Report', now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary
          _buildSectionTitle('Expense Summary (Last 30 Days)'),
          _buildKeyValueRow('Total Expenses', _currencyFormat.format(total)),
          _buildKeyValueRow('Number of Categories', '${expenses.length}'),
          pw.SizedBox(height: 20),

          // Breakdown
          _buildSectionTitle('Expense Breakdown by Category'),
          _buildExpenseTable(expenses),
        ],
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // HELPER WIDGETS
  // ============================================================

  pw.Widget _buildHeader(String title, DateTime date) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated on ${_dateFormat.format(date)}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Text(
            'Business Pilot',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Business Pilot Report',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
    );
  }

  pw.Widget _buildKeyValueRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHealthScoreSection(BusinessHealthScore health) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Overall Score',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${health.overallScore}/100 - ${health.statusLabel}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          _buildKeyValueRow('Revenue Score', '${health.revenueScore}/100'),
          _buildKeyValueRow('Profit Score', '${health.profitScore}/100'),
          _buildKeyValueRow('Inventory Score', '${health.inventoryScore}/100'),
          _buildKeyValueRow('Cash Flow Score', '${health.cashFlowScore}/100'),
        ],
      ),
    );
  }

  pw.Widget _buildRevenueSection(
    RevenueTrend trend,
    TrendPrediction prediction,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _buildKeyValueRow(
            'Current Period Revenue',
            _currencyFormat.format(trend.currentPeriodRevenue),
          ),
          _buildKeyValueRow(
            'Previous Period Revenue',
            _currencyFormat.format(trend.previousPeriodRevenue),
          ),
          _buildKeyValueRow(
            'Change',
            '${trend.changePercent >= 0 ? '+' : ''}${trend.changePercent.toStringAsFixed(1)}%',
          ),
          pw.Divider(height: 15),
          _buildKeyValueRow('Forecast Trend', prediction.directionLabel),
          _buildKeyValueRow(
            '30-Day Projection',
            _currencyFormat.format(prediction.projectedRevenue),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInventorySection(InventoryValueReport inventory) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _buildKeyValueRow(
            'Cost Value',
            _currencyFormat.format(inventory.totalCostValue),
          ),
          _buildKeyValueRow(
            'Retail Value',
            _currencyFormat.format(inventory.totalRetailValue),
          ),
          _buildKeyValueRow(
            'Potential Profit',
            _currencyFormat.format(inventory.totalPotentialProfit),
          ),
          _buildKeyValueRow(
            'Average Margin',
            '${inventory.avgProfitMargin.toStringAsFixed(1)}%',
          ),
          _buildKeyValueRow('Total Units', '${inventory.totalUnits}'),
        ],
      ),
    );
  }

  pw.Widget _buildTopProductsSection(List<TopProduct> products) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeader('#'),
            _tableHeader('Product'),
            _tableHeader('Units Sold'),
            _tableHeader('Profit'),
          ],
        ),
        ...products.asMap().entries.map(
          (e) => pw.TableRow(
            children: [
              _tableCell('${e.key + 1}'),
              _tableCell(e.value.productName),
              _tableCell('${e.value.unitsSold}'),
              _tableCell(_currencyFormat.format(e.value.profit)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCategoryProfitSection(List<CategoryProfit> categories) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeader('Category'),
            _tableHeader('Cost'),
            _tableHeader('Profit'),
            _tableHeader('Margin'),
          ],
        ),
        ...categories.map(
          (c) => pw.TableRow(
            children: [
              _tableCell(c.category.toUpperCase()),
              _tableCell(_currencyFormat.format(c.totalCost)),
              _tableCell(_currencyFormat.format(c.totalProfit)),
              _tableCell('${c.profitMargin.toStringAsFixed(0)}%'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildRecommendationsSection(List<String> recommendations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: recommendations
          .map(
            (r) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Expanded(
                    child: pw.Text(r, style: const pw.TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildRevenueTable(List<RevenueDataPoint> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [_tableHeader('Date'), _tableHeader('Revenue')],
        ),
        ...data.map(
          (d) => pw.TableRow(
            children: [
              _tableCell(d.period),
              _tableCell(_currencyFormat.format(d.amount)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCategoryProfitTable(List<CategoryProfit> categories) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeader('Category'),
            _tableHeader('Cost'),
            _tableHeader('Profit'),
            _tableHeader('Margin'),
          ],
        ),
        ...categories.map(
          (c) => pw.TableRow(
            children: [
              _tableCell(c.category.toUpperCase()),
              _tableCell(_currencyFormat.format(c.totalCost)),
              _tableCell(_currencyFormat.format(c.totalProfit)),
              _tableCell('${c.profitMargin.toStringAsFixed(0)}%'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildExpenseTable(List<ExpenseBreakdown> expenses) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeader('Category'),
            _tableHeader('Amount'),
            _tableHeader('%'),
          ],
        ),
        ...expenses.map(
          (e) => pw.TableRow(
            children: [
              _tableCell(e.category),
              _tableCell(_currencyFormat.format(e.amount)),
              _tableCell('${e.percentage.toStringAsFixed(0)}%'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  // ============================================================
  // PRINT / SHARE METHODS
  // ============================================================

  /// Print business report
  Future<void> printBusinessReport() async {
    final pdfBytes = await generateBusinessReport();
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'business_report_${_dateFormat.format(DateTime.now())}',
    );
  }

  /// Print revenue report
  Future<void> printRevenueReport() async {
    final pdfBytes = await generateRevenueReport();
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'revenue_report_${_dateFormat.format(DateTime.now())}',
    );
  }

  /// Print inventory report
  Future<void> printInventoryReport() async {
    final pdfBytes = await generateInventoryReport();
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'inventory_report_${_dateFormat.format(DateTime.now())}',
    );
  }

  /// Print expense report
  Future<void> printExpenseReport() async {
    final pdfBytes = await generateExpenseReport();
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'expense_report_${_dateFormat.format(DateTime.now())}',
    );
  }
}
