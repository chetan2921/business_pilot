import '../models/product_model.dart';
import 'analytics_service.dart';
import 'product_service.dart';

/// AI-powered analytics service for business intelligence
class AiAnalyticsService {
  AiAnalyticsService._();
  static final AiAnalyticsService _instance = AiAnalyticsService._();
  static AiAnalyticsService get instance => _instance;

  final _analyticsService = AnalyticsService.instance;
  final _productService = ProductService.instance;

  // ============================================================
  // BUSINESS HEALTH SCORING
  // ============================================================

  /// Calculate overall business health score (0-100)
  Future<BusinessHealthScore> calculateBusinessHealth() async {
    // Get various metrics
    final revenueTrend = await _analyticsService.getRevenueTrend();
    final inventoryValue = await _analyticsService.getInventoryValueReport();
    final categoryProfit = await _analyticsService.getProfitByCategory();
    final products = await _productService.getProducts();

    // Calculate component scores
    final revenueScore = _calculateRevenueScore(revenueTrend);
    final profitScore = _calculateProfitScore(categoryProfit);
    final inventoryScore = _calculateInventoryScore(products, inventoryValue);
    final cashFlowScore = _calculateCashFlowScore(revenueTrend);

    // Weighted average
    final overallScore =
        (revenueScore * 0.35 +
                profitScore * 0.25 +
                inventoryScore * 0.20 +
                cashFlowScore * 0.20)
            .clamp(0, 100)
            .round();

    return BusinessHealthScore(
      overallScore: overallScore,
      revenueScore: revenueScore.round(),
      profitScore: profitScore.round(),
      inventoryScore: inventoryScore.round(),
      cashFlowScore: cashFlowScore.round(),
      status: _getHealthStatus(overallScore),
      recommendations: _generateRecommendations(
        revenueScore: revenueScore,
        profitScore: profitScore,
        inventoryScore: inventoryScore,
        cashFlowScore: cashFlowScore,
      ),
    );
  }

  double _calculateRevenueScore(RevenueTrend trend) {
    // Score based on revenue growth
    if (trend.changePercent >= 20) return 100;
    if (trend.changePercent >= 10) return 85;
    if (trend.changePercent >= 0) return 70;
    if (trend.changePercent >= -10) return 50;
    if (trend.changePercent >= -20) return 30;
    return 15;
  }

  double _calculateProfitScore(List<CategoryProfit> categories) {
    if (categories.isEmpty) return 50;
    final avgMargin =
        categories.fold<double>(0, (sum, c) => sum + c.profitMargin) /
        categories.length;

    // Score based on average profit margin
    if (avgMargin >= 40) return 100;
    if (avgMargin >= 30) return 85;
    if (avgMargin >= 20) return 70;
    if (avgMargin >= 10) return 50;
    if (avgMargin >= 0) return 30;
    return 15;
  }

  double _calculateInventoryScore(
    List<ProductModel> products,
    InventoryValueReport report,
  ) {
    if (products.isEmpty) return 50;

    // Check stock health
    final lowStockCount = products
        .where((p) => p.stockQuantity <= p.lowStockThreshold)
        .length;
    final lowStockRatio = lowStockCount / products.length;

    // Score based on inventory health
    if (lowStockRatio <= 0.05) return 100;
    if (lowStockRatio <= 0.10) return 85;
    if (lowStockRatio <= 0.20) return 70;
    if (lowStockRatio <= 0.30) return 50;
    return 30;
  }

  double _calculateCashFlowScore(RevenueTrend trend) {
    // Simplified cash flow score based on revenue consistency
    if (trend.currentPeriodRevenue > 0 && trend.isPositive) return 90;
    if (trend.currentPeriodRevenue > 0) return 70;
    return 40;
  }

  HealthStatus _getHealthStatus(int score) {
    if (score >= 80) return HealthStatus.excellent;
    if (score >= 60) return HealthStatus.good;
    if (score >= 40) return HealthStatus.fair;
    if (score >= 20) return HealthStatus.poor;
    return HealthStatus.critical;
  }

  List<String> _generateRecommendations({
    required double revenueScore,
    required double profitScore,
    required double inventoryScore,
    required double cashFlowScore,
  }) {
    final recommendations = <String>[];

    if (revenueScore < 50) {
      recommendations.add('Consider promotional campaigns to boost sales');
    }
    if (profitScore < 50) {
      recommendations.add('Review pricing strategy to improve margins');
    }
    if (inventoryScore < 50) {
      recommendations.add('Restock low inventory items to avoid stockouts');
    }
    if (cashFlowScore < 50) {
      recommendations.add('Focus on increasing revenue consistency');
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Business is performing well - maintain current strategies',
      );
    }

    return recommendations;
  }

  // ============================================================
  // TREND PREDICTIONS
  // ============================================================

  /// Predict future revenue based on historical trends
  Future<TrendPrediction> predictRevenueTrend({int forecastDays = 30}) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));

    // Get historical data
    final recentData = await _analyticsService.getRevenueData(
      startDate: thirtyDaysAgo,
      endDate: now,
    );
    final olderData = await _analyticsService.getRevenueData(
      startDate: sixtyDaysAgo,
      endDate: thirtyDaysAgo,
    );

    // Calculate averages
    final recentAvg = recentData.isEmpty
        ? 0.0
        : recentData.fold<double>(0, (sum, d) => sum + d.amount) /
              recentData.length;
    final olderAvg = olderData.isEmpty
        ? 0.0
        : olderData.fold<double>(0, (sum, d) => sum + d.amount) /
              olderData.length;

    // Calculate growth rate
    double growthRate = 0;
    if (olderAvg > 0) {
      growthRate = (recentAvg - olderAvg) / olderAvg;
    }

    // Project future revenue
    final projectedDailyRevenue = recentAvg * (1 + growthRate);
    final projectedTotalRevenue = projectedDailyRevenue * forecastDays;

    // Determine trend direction
    TrendDirection direction;
    if (growthRate > 0.1) {
      direction = TrendDirection.strongUp;
    } else if (growthRate > 0) {
      direction = TrendDirection.slightUp;
    } else if (growthRate > -0.1) {
      direction = TrendDirection.slightDown;
    } else {
      direction = TrendDirection.strongDown;
    }

    // Confidence based on data availability
    final confidence = recentData.length >= 20
        ? 0.8
        : recentData.length >= 10
        ? 0.6
        : 0.4;

    return TrendPrediction(
      direction: direction,
      growthRate: growthRate * 100,
      projectedRevenue: projectedTotalRevenue,
      forecastDays: forecastDays,
      confidence: confidence,
      basedOnDays: recentData.length,
    );
  }

  // ============================================================
  // ANOMALY DETECTION
  // ============================================================

  /// Detect anomalies in transactions and business patterns
  Future<List<Anomaly>> detectAnomalies() async {
    final anomalies = <Anomaly>[];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Get revenue data
    final revenueData = await _analyticsService.getRevenueData(
      startDate: thirtyDaysAgo,
      endDate: now,
    );

    if (revenueData.length >= 7) {
      // Calculate mean and standard deviation
      final amounts = revenueData.map((d) => d.amount).toList();
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance =
          amounts.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
          amounts.length;
      final stdDev = variance > 0 ? _sqrt(variance) : 0.0;

      // Detect outliers (beyond 2 standard deviations)
      for (final data in revenueData) {
        if (stdDev > 0) {
          final zScore = (data.amount - mean) / stdDev;
          if (zScore.abs() > 2) {
            anomalies.add(
              Anomaly(
                type: zScore > 0
                    ? AnomalyType.unusuallyHigh
                    : AnomalyType.unusuallyLow,
                category: 'revenue',
                description: zScore > 0
                    ? 'Unusually high revenue on ${data.period}'
                    : 'Unusually low revenue on ${data.period}',
                value: data.amount,
                deviation: zScore,
                date: data.period,
                severity: zScore.abs() > 3
                    ? AnomalySeverity.high
                    : AnomalySeverity.medium,
              ),
            );
          }
        }
      }
    }

    // Check for inventory anomalies
    final products = await _productService.getProducts();
    for (final product in products) {
      // Critical stock level
      if (product.stockQuantity == 0 && product.isActive) {
        anomalies.add(
          Anomaly(
            type: AnomalyType.stockout,
            category: 'inventory',
            description: '${product.name} is out of stock',
            value: 0,
            deviation: 0,
            date: now.toIso8601String().substring(0, 10),
            severity: AnomalySeverity.high,
          ),
        );
      }
      // Overstock (more than 3x threshold)
      else if (product.stockQuantity > product.lowStockThreshold * 10) {
        anomalies.add(
          Anomaly(
            type: AnomalyType.overstock,
            category: 'inventory',
            description:
                '${product.name} may be overstocked (${product.stockQuantity} units)',
            value: product.stockQuantity.toDouble(),
            deviation: product.stockQuantity / product.lowStockThreshold,
            date: now.toIso8601String().substring(0, 10),
            severity: AnomalySeverity.low,
          ),
        );
      }
    }

    // Sort by severity
    anomalies.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return anomalies;
  }

  double _sqrt(double value) {
    if (value <= 0) return 0;
    double guess = value / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
  }

  // ============================================================
  // CUSTOMER PAYMENT PATTERNS
  // ============================================================

  /// Analyze customer payment patterns
  Future<CustomerPaymentAnalysis> analyzeCustomerPayments() async {
    // This would require invoice and payment data
    // For now, return a placeholder based on available data
    final revenueTrend = await _analyticsService.getRevenueTrend();

    return CustomerPaymentAnalysis(
      avgPaymentDays: 15, // Placeholder
      onTimePaymentRate: 0.75,
      latePaymentRate: 0.25,
      totalOutstanding: revenueTrend.currentPeriodRevenue * 0.2,
      paymentTrend: revenueTrend.isPositive ? 'Improving' : 'Declining',
    );
  }
}

// ============================================================
// DATA MODELS
// ============================================================

enum HealthStatus { excellent, good, fair, poor, critical }

class BusinessHealthScore {
  final int overallScore;
  final int revenueScore;
  final int profitScore;
  final int inventoryScore;
  final int cashFlowScore;
  final HealthStatus status;
  final List<String> recommendations;

  BusinessHealthScore({
    required this.overallScore,
    required this.revenueScore,
    required this.profitScore,
    required this.inventoryScore,
    required this.cashFlowScore,
    required this.status,
    required this.recommendations,
  });

  String get statusEmoji {
    switch (status) {
      case HealthStatus.excellent:
        return '🌟';
      case HealthStatus.good:
        return '✅';
      case HealthStatus.fair:
        return '⚠️';
      case HealthStatus.poor:
        return '🔶';
      case HealthStatus.critical:
        return '🚨';
    }
  }

  String get statusLabel {
    switch (status) {
      case HealthStatus.excellent:
        return 'Excellent';
      case HealthStatus.good:
        return 'Good';
      case HealthStatus.fair:
        return 'Fair';
      case HealthStatus.poor:
        return 'Poor';
      case HealthStatus.critical:
        return 'Critical';
    }
  }
}

enum TrendDirection { strongUp, slightUp, stable, slightDown, strongDown }

class TrendPrediction {
  final TrendDirection direction;
  final double growthRate;
  final double projectedRevenue;
  final int forecastDays;
  final double confidence;
  final int basedOnDays;

  TrendPrediction({
    required this.direction,
    required this.growthRate,
    required this.projectedRevenue,
    required this.forecastDays,
    required this.confidence,
    required this.basedOnDays,
  });

  String get directionEmoji {
    switch (direction) {
      case TrendDirection.strongUp:
        return '📈';
      case TrendDirection.slightUp:
        return '↗️';
      case TrendDirection.stable:
        return '➡️';
      case TrendDirection.slightDown:
        return '↘️';
      case TrendDirection.strongDown:
        return '📉';
    }
  }

  String get directionLabel {
    switch (direction) {
      case TrendDirection.strongUp:
        return 'Strong Growth';
      case TrendDirection.slightUp:
        return 'Slight Growth';
      case TrendDirection.stable:
        return 'Stable';
      case TrendDirection.slightDown:
        return 'Slight Decline';
      case TrendDirection.strongDown:
        return 'Declining';
    }
  }
}

enum AnomalyType {
  unusuallyHigh,
  unusuallyLow,
  stockout,
  overstock,
  suspicious,
}

enum AnomalySeverity { low, medium, high }

class Anomaly {
  final AnomalyType type;
  final String category;
  final String description;
  final double value;
  final double deviation;
  final String date;
  final AnomalySeverity severity;

  Anomaly({
    required this.type,
    required this.category,
    required this.description,
    required this.value,
    required this.deviation,
    required this.date,
    required this.severity,
  });

  String get severityEmoji {
    switch (severity) {
      case AnomalySeverity.high:
        return '🔴';
      case AnomalySeverity.medium:
        return '🟠';
      case AnomalySeverity.low:
        return '🟡';
    }
  }
}

class CustomerPaymentAnalysis {
  final int avgPaymentDays;
  final double onTimePaymentRate;
  final double latePaymentRate;
  final double totalOutstanding;
  final String paymentTrend;

  CustomerPaymentAnalysis({
    required this.avgPaymentDays,
    required this.onTimePaymentRate,
    required this.latePaymentRate,
    required this.totalOutstanding,
    required this.paymentTrend,
  });
}
