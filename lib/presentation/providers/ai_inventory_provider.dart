import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/ai_inventory_service.dart';

/// Provider for AI inventory reorder predictions
final reorderPredictionsProvider = FutureProvider<List<ReorderPrediction>>((
  ref,
) async {
  return AiInventoryService.instance.getReorderPredictions();
});

/// Provider for stock optimization suggestions
final stockOptimizationsProvider = FutureProvider<List<StockOptimization>>((
  ref,
) async {
  return AiInventoryService.instance.getStockOptimizations();
});

/// Provider for slow-moving inventory
final slowMovingInventoryProvider = FutureProvider<List<SlowMovingProduct>>((
  ref,
) async {
  return AiInventoryService.instance.getSlowMovingInventory();
});

/// Provider for AI insights summary
final aiInsightsSummaryProvider = FutureProvider<AiInsightsSummary>((
  ref,
) async {
  return AiInventoryService.instance.getInsightsSummary();
});

/// Combined refresh function
void refreshAiInventory(WidgetRef ref) {
  ref.invalidate(reorderPredictionsProvider);
  ref.invalidate(stockOptimizationsProvider);
  ref.invalidate(slowMovingInventoryProvider);
  ref.invalidate(aiInsightsSummaryProvider);
}
