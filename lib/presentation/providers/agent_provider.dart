import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/agent_recommendation_model.dart';
import '../../data/models/cash_flow_prediction_model.dart';
import '../../data/services/agent_service.dart';
import '../../data/services/agents/cash_flow_agent.dart';
import '../../data/services/agents/revenue_optimizer_agent.dart';

// ============================================================
// SERVICE PROVIDERS
// ============================================================

/// Agent Service provider
final agentServiceProvider = Provider<AgentService>((ref) {
  return AgentService.instance;
});

/// Cash Flow Agent provider
final cashFlowAgentProvider = Provider<CashFlowAgent>((ref) {
  return CashFlowAgent.instance;
});

/// Revenue Optimizer Agent provider
final revenueOptimizerAgentProvider = Provider<RevenueOptimizerAgent>((ref) {
  return RevenueOptimizerAgent.instance;
});

// ============================================================
// RECOMMENDATIONS PROVIDERS
// ============================================================

/// All pending recommendations
final pendingRecommendationsProvider =
    FutureProvider<List<AgentRecommendationModel>>((ref) async {
      final service = ref.watch(agentServiceProvider);
      return service.getPendingRecommendations();
    });

/// Recommendations by agent type
final recommendationsByTypeProvider =
    FutureProvider.family<List<AgentRecommendationModel>, AgentType>((
      ref,
      type,
    ) async {
      final service = ref.watch(agentServiceProvider);
      return service.getRecommendationsByType(type);
    });

/// Critical and high priority recommendations
final urgentRecommendationsProvider =
    FutureProvider<List<AgentRecommendationModel>>((ref) async {
      final service = ref.watch(agentServiceProvider);
      final pending = await service.getPendingRecommendations();
      return pending
          .where(
            (r) =>
                r.priority == RecommendationPriority.critical ||
                r.priority == RecommendationPriority.high,
          )
          .toList();
    });

/// Pending counts by priority
final pendingCountsProvider = FutureProvider<Map<RecommendationPriority, int>>((
  ref,
) async {
  final service = ref.watch(agentServiceProvider);
  return service.getPendingCounts();
});

/// Agent statistics
final agentStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(agentServiceProvider);
  return service.getAgentStats();
});

// ============================================================
// CASH FLOW PROVIDERS
// ============================================================

/// Cash flow forecast
final cashFlowForecastProvider = FutureProvider<CashFlowForecast>((ref) async {
  final agent = ref.watch(cashFlowAgentProvider);
  return agent.generateForecast();
});

/// Cash flow recommendations
final cashFlowRecommendationsProvider =
    FutureProvider<List<AgentRecommendationModel>>((ref) async {
      final agent = ref.watch(cashFlowAgentProvider);
      return agent.analyze();
    });

// ============================================================
// REVENUE PROVIDERS
// ============================================================

/// Revenue opportunities
final revenueOpportunitiesProvider = FutureProvider<List<RevenueOpportunity>>((
  ref,
) async {
  final agent = ref.watch(revenueOptimizerAgentProvider);
  return agent.getOpportunities(status: OpportunityStatus.open);
});

/// Revenue recommendations
final revenueRecommendationsProvider =
    FutureProvider<List<AgentRecommendationModel>>((ref) async {
      final agent = ref.watch(revenueOptimizerAgentProvider);
      return agent.analyze();
    });

// ============================================================
// AGENT ACTIONS NOTIFIER
// ============================================================

/// State for managing agent actions
class AgentActionsNotifier extends StateNotifier<AgentActionsState> {
  final AgentService _agentService;
  final Ref _ref;

  AgentActionsNotifier(this._agentService, this._ref)
    : super(const AgentActionsState());

  /// Run all agents
  Future<void> runAllAgents() async {
    state = state.copyWith(isRunning: true, error: null);
    try {
      final recommendations = await _agentService.runAllAgents();
      state = state.copyWith(
        isRunning: false,
        lastRunCount: recommendations.length,
        lastRunAt: DateTime.now(),
      );
      // Invalidate related providers to refresh UI
      _ref.invalidate(pendingRecommendationsProvider);
      _ref.invalidate(pendingCountsProvider);
      _ref.invalidate(agentStatsProvider);
    } catch (e) {
      state = state.copyWith(isRunning: false, error: e.toString());
    }
  }

  /// Accept a recommendation
  Future<void> acceptRecommendation(String id) async {
    await _agentService.acceptRecommendation(id);
    _ref.invalidate(pendingRecommendationsProvider);
    _ref.invalidate(pendingCountsProvider);
  }

  /// Dismiss a recommendation
  Future<void> dismissRecommendation(String id) async {
    await _agentService.dismissRecommendation(id);
    _ref.invalidate(pendingRecommendationsProvider);
    _ref.invalidate(pendingCountsProvider);
  }

  /// Snooze a recommendation
  Future<void> snoozeRecommendation(String id, Duration duration) async {
    await _agentService.snoozeRecommendation(id, duration);
    _ref.invalidate(pendingRecommendationsProvider);
    _ref.invalidate(pendingCountsProvider);
  }
}

/// State for agent actions
class AgentActionsState {
  final bool isRunning;
  final int lastRunCount;
  final DateTime? lastRunAt;
  final String? error;

  const AgentActionsState({
    this.isRunning = false,
    this.lastRunCount = 0,
    this.lastRunAt,
    this.error,
  });

  AgentActionsState copyWith({
    bool? isRunning,
    int? lastRunCount,
    DateTime? lastRunAt,
    String? error,
  }) {
    return AgentActionsState(
      isRunning: isRunning ?? this.isRunning,
      lastRunCount: lastRunCount ?? this.lastRunCount,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      error: error,
    );
  }
}

/// Agent actions provider
final agentActionsProvider =
    StateNotifierProvider<AgentActionsNotifier, AgentActionsState>((ref) {
      final service = ref.watch(agentServiceProvider);
      return AgentActionsNotifier(service, ref);
    });

// ============================================================
// HELPER PROVIDERS
// ============================================================

/// Total pending recommendations count
final totalPendingCountProvider = FutureProvider<int>((ref) async {
  final counts = await ref.watch(pendingCountsProvider.future);
  return counts.values.fold<int>(0, (sum, count) => sum + count);
});

/// Has critical recommendations
final hasCriticalRecommendationsProvider = FutureProvider<bool>((ref) async {
  final counts = await ref.watch(pendingCountsProvider.future);
  return (counts[RecommendationPriority.critical] ?? 0) > 0;
});
