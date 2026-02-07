import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/analytics_service.dart';

/// Provider for complete analytics dashboard
final analyticsDashboardProvider = FutureProvider<AnalyticsDashboard>((
  ref,
) async {
  return AnalyticsService.instance.getDashboardData();
});

/// Provider for revenue trend
final revenueTrendProvider = FutureProvider<RevenueTrend>((ref) async {
  return AnalyticsService.instance.getRevenueTrend();
});

/// Provider for revenue data with configurable period
final revenueDataProvider = FutureProvider.family<List<RevenueDataPoint>, int>((
  ref,
  daysBack,
) async {
  final now = DateTime.now();
  final start = now.subtract(Duration(days: daysBack));
  return AnalyticsService.instance.getRevenueData(
    startDate: start,
    endDate: now,
  );
});

/// Provider for top products
final topProductsProvider = FutureProvider<List<TopProduct>>((ref) async {
  return AnalyticsService.instance.getTopProducts();
});

/// Provider for profit by category
final categoryProfitProvider = FutureProvider<List<CategoryProfit>>((
  ref,
) async {
  return AnalyticsService.instance.getProfitByCategory();
});

/// Provider for inventory value report
final inventoryValueProvider = FutureProvider<InventoryValueReport>((
  ref,
) async {
  return AnalyticsService.instance.getInventoryValueReport();
});

/// Refresh all analytics providers
void refreshAnalytics(WidgetRef ref) {
  ref.invalidate(analyticsDashboardProvider);
  ref.invalidate(revenueTrendProvider);
  ref.invalidate(topProductsProvider);
  ref.invalidate(categoryProfitProvider);
  ref.invalidate(inventoryValueProvider);
}
