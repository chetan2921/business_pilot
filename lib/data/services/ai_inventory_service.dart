import '../models/product_model.dart';
import '../models/stock_movement_model.dart';
import 'product_service.dart';

/// AI-powered inventory prediction service
class AiInventoryService {
  AiInventoryService._();
  static final AiInventoryService _instance = AiInventoryService._();
  static AiInventoryService get instance => _instance;

  final ProductService _productService = ProductService.instance;

  // ============================================================
  // REORDER PREDICTION
  // ============================================================

  /// Predict when a product will need reordering based on sales velocity
  Future<List<ReorderPrediction>> getReorderPredictions() async {
    final products = await _productService.getProducts(isActive: true);
    final predictions = <ReorderPrediction>[];

    for (final product in products) {
      final movements = await _productService.getStockMovements(product.id);
      final prediction = _calculateReorderPrediction(product, movements);
      if (prediction != null) {
        predictions.add(prediction);
      }
    }

    // Sort by urgency (days until stockout)
    predictions.sort(
      (a, b) => a.daysUntilStockout.compareTo(b.daysUntilStockout),
    );
    return predictions;
  }

  ReorderPrediction? _calculateReorderPrediction(
    ProductModel product,
    List<StockMovementModel> movements,
  ) {
    // Get sales from last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentSales = movements.where((m) {
      return m.movementType == MovementType.sale &&
          m.createdAt != null &&
          m.createdAt!.isAfter(thirtyDaysAgo);
    }).toList();

    if (recentSales.isEmpty) {
      // No recent sales - might be slow-moving
      return null;
    }

    // Calculate daily sales velocity
    final totalSold = recentSales.fold<int>(0, (sum, m) => sum + m.quantity);
    final daysCovered = DateTime.now().difference(thirtyDaysAgo).inDays;
    final dailySalesVelocity = totalSold / daysCovered;

    if (dailySalesVelocity <= 0) return null;

    // Calculate days until stockout
    final daysUntilStockout = (product.stockQuantity / dailySalesVelocity)
        .floor();

    // Calculate suggested reorder date (reorder 7 days before stockout)
    final leadTimeDays = 7;
    final reorderDate = DateTime.now().add(
      Duration(days: (daysUntilStockout - leadTimeDays).clamp(0, 365)),
    );

    // Calculate suggested order quantity (cover 30 days + safety stock)
    final suggestedOrderQty = (dailySalesVelocity * 30 * 1.2)
        .ceil(); // 20% safety margin

    // Determine urgency
    UrgencyLevel urgency;
    if (daysUntilStockout <= 3) {
      urgency = UrgencyLevel.critical;
    } else if (daysUntilStockout <= 7) {
      urgency = UrgencyLevel.high;
    } else if (daysUntilStockout <= 14) {
      urgency = UrgencyLevel.medium;
    } else {
      urgency = UrgencyLevel.low;
    }

    return ReorderPrediction(
      product: product,
      daysUntilStockout: daysUntilStockout,
      dailySalesVelocity: dailySalesVelocity,
      suggestedReorderDate: reorderDate,
      suggestedOrderQuantity: suggestedOrderQty,
      urgency: urgency,
    );
  }

  // ============================================================
  // OPTIMAL STOCK LEVELS
  // ============================================================

  /// Suggest optimal stock levels based on demand patterns
  Future<List<StockOptimization>> getStockOptimizations() async {
    final products = await _productService.getProducts(isActive: true);
    final optimizations = <StockOptimization>[];

    for (final product in products) {
      final movements = await _productService.getStockMovements(product.id);
      final optimization = _calculateOptimalStock(product, movements);
      optimizations.add(optimization);
    }

    // Sort by adjustment needed (descending)
    optimizations.sort(
      (a, b) => b.adjustmentNeeded.abs().compareTo(a.adjustmentNeeded.abs()),
    );
    return optimizations;
  }

  StockOptimization _calculateOptimalStock(
    ProductModel product,
    List<StockMovementModel> movements,
  ) {
    // Analyze last 60 days of sales
    final sixtyDaysAgo = DateTime.now().subtract(const Duration(days: 60));
    final recentSales = movements.where((m) {
      return m.movementType == MovementType.sale &&
          m.createdAt != null &&
          m.createdAt!.isAfter(sixtyDaysAgo);
    }).toList();

    double avgDailySales = 0;
    double maxDailySales = 0;

    if (recentSales.isNotEmpty) {
      // Group by day and calculate averages
      final salesByDay = <String, int>{};
      for (final sale in recentSales) {
        final dateKey = sale.createdAt!.toIso8601String().substring(0, 10);
        salesByDay[dateKey] = (salesByDay[dateKey] ?? 0) + sale.quantity;
      }

      if (salesByDay.isNotEmpty) {
        final values = salesByDay.values.toList();
        avgDailySales =
            values.fold<int>(0, (sum, v) => sum + v) / values.length;
        maxDailySales = values.reduce((a, b) => a > b ? a : b).toDouble();
      }
    }

    // Optimal stock formula:
    // Base demand (30 days avg) + Safety stock (peak demand variance) + Lead time buffer
    final baseDemand = avgDailySales * 30;
    final safetyStock = (maxDailySales - avgDailySales) * 7; // 7 days safety
    final leadTimeBuffer = avgDailySales * 7; // 7 days lead time

    final optimalStock = (baseDemand + safetyStock + leadTimeBuffer).ceil();
    final adjustmentNeeded = optimalStock - product.stockQuantity;

    // Determine recommendation
    StockRecommendation recommendation;
    if (adjustmentNeeded > product.stockQuantity * 0.5) {
      recommendation = StockRecommendation.increaseSignificantly;
    } else if (adjustmentNeeded > 0) {
      recommendation = StockRecommendation.increaseSlightly;
    } else if (adjustmentNeeded < -product.stockQuantity * 0.5) {
      recommendation = StockRecommendation.decreaseSignificantly;
    } else if (adjustmentNeeded < 0) {
      recommendation = StockRecommendation.decreaseSlightly;
    } else {
      recommendation = StockRecommendation.optimal;
    }

    return StockOptimization(
      product: product,
      currentStock: product.stockQuantity,
      optimalStock: optimalStock.clamp(product.lowStockThreshold, 999999),
      adjustmentNeeded: adjustmentNeeded,
      avgDailySales: avgDailySales,
      recommendation: recommendation,
    );
  }

  // ============================================================
  // SLOW-MOVING INVENTORY
  // ============================================================

  /// Identify slow-moving inventory
  Future<List<SlowMovingProduct>> getSlowMovingInventory() async {
    final products = await _productService.getProducts(isActive: true);
    final slowMovers = <SlowMovingProduct>[];

    for (final product in products) {
      if (product.stockQuantity == 0) continue; // Skip out of stock

      final movements = await _productService.getStockMovements(product.id);
      final analysis = _analyzeSlowMover(product, movements);
      if (analysis != null) {
        slowMovers.add(analysis);
      }
    }

    // Sort by days since last sale (descending)
    slowMovers.sort(
      (a, b) => b.daysSinceLastSale.compareTo(a.daysSinceLastSale),
    );
    return slowMovers;
  }

  SlowMovingProduct? _analyzeSlowMover(
    ProductModel product,
    List<StockMovementModel> movements,
  ) {
    // Find last sale
    final sales = movements
        .where(
          (m) => m.movementType == MovementType.sale && m.createdAt != null,
        )
        .toList();

    DateTime? lastSaleDate;
    int daysSinceLastSale = 999;

    if (sales.isNotEmpty) {
      lastSaleDate = sales
          .map((s) => s.createdAt!)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      daysSinceLastSale = DateTime.now().difference(lastSaleDate).inDays;
    }

    // Calculate turnover rate (last 90 days)
    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
    final recentSales = sales.where((m) => m.createdAt!.isAfter(ninetyDaysAgo));
    final totalSold = recentSales.fold<int>(0, (sum, m) => sum + m.quantity);

    // Turnover = units sold / average inventory
    final avgInventory = (product.stockQuantity + totalSold / 2).clamp(
      1,
      double.infinity,
    );
    final turnoverRate = totalSold / avgInventory;

    // A product is "slow-moving" if:
    // - No sale in 30+ days OR
    // - Turnover rate < 0.5 (less than half inventory sold in 90 days)
    final isSlowMoving = daysSinceLastSale > 30 || turnoverRate < 0.5;

    if (!isSlowMoving) return null;

    // Calculate capital tied up
    final capitalTiedUp = product.stockQuantity * product.costPrice;

    // Recommendation
    String recommendation;
    if (daysSinceLastSale > 90) {
      recommendation = 'Consider clearance sale or discontinue';
    } else if (daysSinceLastSale > 60) {
      recommendation = 'Run promotional discount';
    } else if (turnoverRate < 0.3) {
      recommendation = 'Bundle with popular items';
    } else {
      recommendation = 'Monitor and reduce reorder quantity';
    }

    return SlowMovingProduct(
      product: product,
      lastSaleDate: lastSaleDate,
      daysSinceLastSale: daysSinceLastSale,
      turnoverRate: turnoverRate,
      capitalTiedUp: capitalTiedUp,
      recommendation: recommendation,
    );
  }

  // ============================================================
  // QUICK INSIGHTS SUMMARY
  // ============================================================

  /// Get a quick summary of AI insights
  Future<AiInsightsSummary> getInsightsSummary() async {
    final reorderPredictions = await getReorderPredictions();
    final slowMovers = await getSlowMovingInventory();

    final criticalReorders = reorderPredictions
        .where((p) => p.urgency == UrgencyLevel.critical)
        .length;
    final highReorders = reorderPredictions
        .where((p) => p.urgency == UrgencyLevel.high)
        .length;

    final totalSlowMoversValue = slowMovers.fold<double>(
      0,
      (sum, s) => sum + s.capitalTiedUp,
    );

    return AiInsightsSummary(
      totalReorderAlerts: reorderPredictions.length,
      criticalReorders: criticalReorders,
      highPriorityReorders: highReorders,
      slowMovingCount: slowMovers.length,
      capitalInSlowMovers: totalSlowMoversValue,
    );
  }
}

// ============================================================
// DATA MODELS
// ============================================================

enum UrgencyLevel {
  critical('Critical', '🔴'),
  high('High', '🟠'),
  medium('Medium', '🟡'),
  low('Low', '🟢');

  final String label;
  final String emoji;
  const UrgencyLevel(this.label, this.emoji);
}

enum StockRecommendation {
  increaseSignificantly('Increase significantly', '📈📈'),
  increaseSlightly('Increase slightly', '📈'),
  optimal('Optimal', '✅'),
  decreaseSlightly('Decrease slightly', '📉'),
  decreaseSignificantly('Decrease significantly', '📉📉');

  final String label;
  final String emoji;
  const StockRecommendation(this.label, this.emoji);
}

class ReorderPrediction {
  final ProductModel product;
  final int daysUntilStockout;
  final double dailySalesVelocity;
  final DateTime suggestedReorderDate;
  final int suggestedOrderQuantity;
  final UrgencyLevel urgency;

  ReorderPrediction({
    required this.product,
    required this.daysUntilStockout,
    required this.dailySalesVelocity,
    required this.suggestedReorderDate,
    required this.suggestedOrderQuantity,
    required this.urgency,
  });

  String get stockoutText {
    if (daysUntilStockout <= 0) return 'Out of stock!';
    if (daysUntilStockout == 1) return 'Tomorrow';
    return 'In $daysUntilStockout days';
  }
}

class StockOptimization {
  final ProductModel product;
  final int currentStock;
  final int optimalStock;
  final int adjustmentNeeded;
  final double avgDailySales;
  final StockRecommendation recommendation;

  StockOptimization({
    required this.product,
    required this.currentStock,
    required this.optimalStock,
    required this.adjustmentNeeded,
    required this.avgDailySales,
    required this.recommendation,
  });
}

class SlowMovingProduct {
  final ProductModel product;
  final DateTime? lastSaleDate;
  final int daysSinceLastSale;
  final double turnoverRate;
  final double capitalTiedUp;
  final String recommendation;

  SlowMovingProduct({
    required this.product,
    required this.lastSaleDate,
    required this.daysSinceLastSale,
    required this.turnoverRate,
    required this.capitalTiedUp,
    required this.recommendation,
  });
}

class AiInsightsSummary {
  final int totalReorderAlerts;
  final int criticalReorders;
  final int highPriorityReorders;
  final int slowMovingCount;
  final double capitalInSlowMovers;

  AiInsightsSummary({
    required this.totalReorderAlerts,
    required this.criticalReorders,
    required this.highPriorityReorders,
    required this.slowMovingCount,
    required this.capitalInSlowMovers,
  });

  bool get hasAlerts =>
      criticalReorders > 0 || highPriorityReorders > 0 || slowMovingCount > 0;
}
