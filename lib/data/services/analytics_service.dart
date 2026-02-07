import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Advanced analytics service for business intelligence
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;

  // ============================================================
  // REVENUE ANALYTICS
  // ============================================================

  /// Get revenue data over a time period
  Future<List<RevenueDataPoint>> getRevenueData({
    required DateTime startDate,
    required DateTime endDate,
    RevenueGrouping grouping = RevenueGrouping.daily,
  }) async {
    final invoices = await _client
        .from('invoices')
        .select('total, issue_date, status')
        .gte('issue_date', startDate.toIso8601String().substring(0, 10))
        .lte('issue_date', endDate.toIso8601String().substring(0, 10))
        .neq('status', 'cancelled');

    // Group by period
    final grouped = <String, double>{};
    for (final row in invoices) {
      final date = DateTime.parse(row['issue_date'] as String);
      final key = _getGroupKey(date, grouping);
      grouped[key] = (grouped[key] ?? 0) + (row['total'] as num).toDouble();
    }

    // Convert to data points
    final dataPoints = grouped.entries.map((e) {
      return RevenueDataPoint(period: e.key, amount: e.value);
    }).toList();

    dataPoints.sort((a, b) => a.period.compareTo(b.period));
    return dataPoints;
  }

  String _getGroupKey(DateTime date, RevenueGrouping grouping) {
    switch (grouping) {
      case RevenueGrouping.daily:
        return date.toIso8601String().substring(0, 10);
      case RevenueGrouping.weekly:
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        return 'W${weekStart.toIso8601String().substring(0, 10)}';
      case RevenueGrouping.monthly:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    }
  }

  /// Get revenue trend comparison (this period vs last period)
  Future<RevenueTrend> getRevenueTrend({int daysBack = 30}) async {
    final now = DateTime.now();
    final currentStart = now.subtract(Duration(days: daysBack));
    final previousStart = currentStart.subtract(Duration(days: daysBack));
    final previousEnd = currentStart.subtract(const Duration(days: 1));

    final currentRevenue = await _getTotalRevenue(currentStart, now);
    final previousRevenue = await _getTotalRevenue(previousStart, previousEnd);

    double changePercent = 0;
    if (previousRevenue > 0) {
      changePercent =
          ((currentRevenue - previousRevenue) / previousRevenue) * 100;
    }

    return RevenueTrend(
      currentPeriodRevenue: currentRevenue,
      previousPeriodRevenue: previousRevenue,
      changePercent: changePercent,
      isPositive: currentRevenue >= previousRevenue,
    );
  }

  Future<double> _getTotalRevenue(DateTime start, DateTime end) async {
    final invoices = await _client
        .from('invoices')
        .select('total')
        .gte('issue_date', start.toIso8601String().substring(0, 10))
        .lte('issue_date', end.toIso8601String().substring(0, 10))
        .neq('status', 'cancelled');

    return invoices.fold<double>(
      0,
      (sum, row) => sum + (row['total'] as num).toDouble(),
    );
  }

  // ============================================================
  // PROFIT MARGIN ANALYTICS
  // ============================================================

  /// Get profit margin analysis by product category
  Future<List<CategoryProfit>> getProfitByCategory() async {
    final products = await _client
        .from('products')
        .select('category, cost_price, selling_price, stock_quantity');

    final categoryData = <String, Map<String, double>>{};

    for (final row in products) {
      final category = row['category'] as String;
      final costPrice = (row['cost_price'] as num).toDouble();
      final sellingPrice = (row['selling_price'] as num).toDouble();
      final stockQty = (row['stock_quantity'] as num).toInt();

      categoryData.putIfAbsent(
        category,
        () => {
          'totalCost': 0.0,
          'totalRevenue': 0.0,
          'totalProfit': 0.0,
          'productCount': 0.0,
        },
      );

      final data = categoryData[category]!;
      data['totalCost'] = data['totalCost']! + (costPrice * stockQty);
      data['totalRevenue'] = data['totalRevenue']! + (sellingPrice * stockQty);
      data['totalProfit'] =
          data['totalProfit']! + ((sellingPrice - costPrice) * stockQty);
      data['productCount'] = data['productCount']! + 1;
    }

    return categoryData.entries.map((e) {
      final data = e.value;
      final margin = data['totalRevenue']! > 0
          ? (data['totalProfit']! / data['totalRevenue']!) * 100
          : 0;

      return CategoryProfit(
        category: e.key,
        totalCost: data['totalCost']!,
        totalPotentialRevenue: data['totalRevenue']!,
        totalProfit: data['totalProfit']!,
        profitMargin: margin.toDouble(),
        productCount: data['productCount']!.toInt(),
      );
    }).toList()..sort((a, b) => b.totalProfit.compareTo(a.totalProfit));
  }

  /// Get top performing products by profit
  Future<List<TopProduct>> getTopProducts({int limit = 10}) async {
    // Get products with their sales data
    final products = await _client
        .from('products')
        .select(
          'id, name, category, cost_price, selling_price, stock_quantity',
        );

    final movements = await _client
        .from('stock_movements')
        .select('product_id, quantity')
        .eq('movement_type', 'sale');

    // Calculate total sold per product
    final salesByProduct = <String, int>{};
    for (final m in movements) {
      final productId = m['product_id'] as String;
      salesByProduct[productId] =
          (salesByProduct[productId] ?? 0) + (m['quantity'] as num).toInt();
    }

    // Calculate profit per product
    final topProducts = <TopProduct>[];
    for (final p in products) {
      final productId = p['id'] as String;
      final unitsSold = salesByProduct[productId] ?? 0;
      final costPrice = (p['cost_price'] as num).toDouble();
      final sellingPrice = (p['selling_price'] as num).toDouble();
      final profit = (sellingPrice - costPrice) * unitsSold;

      if (unitsSold > 0) {
        topProducts.add(
          TopProduct(
            productId: productId,
            productName: p['name'] as String,
            category: p['category'] as String,
            unitsSold: unitsSold,
            revenue: sellingPrice * unitsSold,
            profit: profit,
            profitMargin: sellingPrice > 0
                ? ((sellingPrice - costPrice) / sellingPrice) * 100
                : 0,
          ),
        );
      }
    }

    topProducts.sort((a, b) => b.profit.compareTo(a.profit));
    return topProducts.take(limit).toList();
  }

  // ============================================================
  // INVENTORY VALUE ANALYTICS
  // ============================================================

  /// Get inventory value report
  Future<InventoryValueReport> getInventoryValueReport() async {
    final products = await _client
        .from('products')
        .select(
          'category, cost_price, selling_price, stock_quantity, is_active',
        );

    double totalCostValue = 0;
    double totalRetailValue = 0;
    double totalPotentialProfit = 0;
    int totalUnits = 0;
    final categoryBreakdown = <String, double>{};

    for (final p in products) {
      if (p['is_active'] != true) continue;

      final costPrice = (p['cost_price'] as num).toDouble();
      final sellingPrice = (p['selling_price'] as num).toDouble();
      final stockQty = (p['stock_quantity'] as num).toInt();
      final category = p['category'] as String;

      totalCostValue += costPrice * stockQty;
      totalRetailValue += sellingPrice * stockQty;
      totalPotentialProfit += (sellingPrice - costPrice) * stockQty;
      totalUnits += stockQty;

      categoryBreakdown[category] =
          (categoryBreakdown[category] ?? 0) + (costPrice * stockQty);
    }

    return InventoryValueReport(
      totalCostValue: totalCostValue,
      totalRetailValue: totalRetailValue,
      totalPotentialProfit: totalPotentialProfit,
      totalUnits: totalUnits,
      avgProfitMargin: totalRetailValue > 0
          ? (totalPotentialProfit / totalRetailValue) * 100
          : 0,
      valueByCategory: categoryBreakdown,
    );
  }

  // ============================================================
  // EXPENSE ANALYTICS
  // ============================================================

  /// Get expense breakdown by category
  Future<List<ExpenseBreakdown>> getExpenseBreakdown({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final expenses = await _client
        .from('expenses')
        .select('category, amount')
        .gte('expense_date', startDate.toIso8601String().substring(0, 10))
        .lte('expense_date', endDate.toIso8601String().substring(0, 10));

    final categoryTotals = <String, double>{};
    for (final e in expenses) {
      final category = e['category'] as String;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + (e['amount'] as num).toDouble();
    }

    final total = categoryTotals.values.fold<double>(0, (a, b) => a + b);

    return categoryTotals.entries.map((e) {
      return ExpenseBreakdown(
        category: e.key,
        amount: e.value,
        percentage: total > 0 ? (e.value / total) * 100 : 0,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));
  }

  // ============================================================
  // DASHBOARD SUMMARY
  // ============================================================

  /// Get complete analytics dashboard data
  Future<AnalyticsDashboard> getDashboardData() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final revenueTrend = await getRevenueTrend();
    final revenueData = await getRevenueData(
      startDate: thirtyDaysAgo,
      endDate: now,
    );
    final topProducts = await getTopProducts(limit: 5);
    final categoryProfit = await getProfitByCategory();
    final inventoryValue = await getInventoryValueReport();
    final expenseBreakdown = await getExpenseBreakdown(
      startDate: thirtyDaysAgo,
      endDate: now,
    );

    return AnalyticsDashboard(
      revenueTrend: revenueTrend,
      revenueData: revenueData,
      topProducts: topProducts,
      categoryProfit: categoryProfit,
      inventoryValue: inventoryValue,
      expenseBreakdown: expenseBreakdown,
    );
  }
}

// ============================================================
// DATA MODELS
// ============================================================

enum RevenueGrouping { daily, weekly, monthly }

class RevenueDataPoint {
  final String period;
  final double amount;

  RevenueDataPoint({required this.period, required this.amount});
}

class RevenueTrend {
  final double currentPeriodRevenue;
  final double previousPeriodRevenue;
  final double changePercent;
  final bool isPositive;

  RevenueTrend({
    required this.currentPeriodRevenue,
    required this.previousPeriodRevenue,
    required this.changePercent,
    required this.isPositive,
  });
}

class CategoryProfit {
  final String category;
  final double totalCost;
  final double totalPotentialRevenue;
  final double totalProfit;
  final double profitMargin;
  final int productCount;

  CategoryProfit({
    required this.category,
    required this.totalCost,
    required this.totalPotentialRevenue,
    required this.totalProfit,
    required this.profitMargin,
    required this.productCount,
  });
}

class TopProduct {
  final String productId;
  final String productName;
  final String category;
  final int unitsSold;
  final double revenue;
  final double profit;
  final double profitMargin;

  TopProduct({
    required this.productId,
    required this.productName,
    required this.category,
    required this.unitsSold,
    required this.revenue,
    required this.profit,
    required this.profitMargin,
  });
}

class InventoryValueReport {
  final double totalCostValue;
  final double totalRetailValue;
  final double totalPotentialProfit;
  final int totalUnits;
  final double avgProfitMargin;
  final Map<String, double> valueByCategory;

  InventoryValueReport({
    required this.totalCostValue,
    required this.totalRetailValue,
    required this.totalPotentialProfit,
    required this.totalUnits,
    required this.avgProfitMargin,
    required this.valueByCategory,
  });
}

class ExpenseBreakdown {
  final String category;
  final double amount;
  final double percentage;

  ExpenseBreakdown({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class AnalyticsDashboard {
  final RevenueTrend revenueTrend;
  final List<RevenueDataPoint> revenueData;
  final List<TopProduct> topProducts;
  final List<CategoryProfit> categoryProfit;
  final InventoryValueReport inventoryValue;
  final List<ExpenseBreakdown> expenseBreakdown;

  AnalyticsDashboard({
    required this.revenueTrend,
    required this.revenueData,
    required this.topProducts,
    required this.categoryProfit,
    required this.inventoryValue,
    required this.expenseBreakdown,
  });
}
