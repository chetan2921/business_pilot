import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/ai_analytics_service.dart';

/// Provider for business health score
final businessHealthProvider = FutureProvider<BusinessHealthScore>((ref) async {
  return AiAnalyticsService.instance.calculateBusinessHealth();
});

/// Provider for revenue trend prediction
final trendPredictionProvider = FutureProvider<TrendPrediction>((ref) async {
  return AiAnalyticsService.instance.predictRevenueTrend();
});

/// Provider for anomaly detection
final anomalyDetectionProvider = FutureProvider<List<Anomaly>>((ref) async {
  return AiAnalyticsService.instance.detectAnomalies();
});

/// Provider for customer payment analysis
final customerPaymentProvider = FutureProvider<CustomerPaymentAnalysis>((
  ref,
) async {
  return AiAnalyticsService.instance.analyzeCustomerPayments();
});

/// Refresh all AI analytics
void refreshAiAnalytics(WidgetRef ref) {
  ref.invalidate(businessHealthProvider);
  ref.invalidate(trendPredictionProvider);
  ref.invalidate(anomalyDetectionProvider);
  ref.invalidate(customerPaymentProvider);
}
