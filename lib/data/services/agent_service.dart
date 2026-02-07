import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/agent_recommendation_model.dart';
import 'agents/cash_flow_agent.dart';
import 'agents/revenue_optimizer_agent.dart';

/// Main Agent Service - Orchestrates all AI agents
/// Manages recommendations, notifications, and user actions
class AgentService {
  AgentService._();
  static final AgentService _instance = AgentService._();
  static AgentService get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;

  final _cashFlowAgent = CashFlowAgent.instance;
  final _revenueAgent = RevenueOptimizerAgent.instance;

  /// Run all agents and generate recommendations
  Future<List<AgentRecommendationModel>> runAllAgents() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final allRecommendations = <AgentRecommendationModel>[];
    final runId = await _logAgentRun(userId, 'all');

    try {
      // Run Cash Flow Agent
      final cashFlowRecs = await _cashFlowAgent.analyze();
      allRecommendations.addAll(cashFlowRecs);

      // Run Revenue Optimizer Agent
      final revenueRecs = await _revenueAgent.analyze();
      allRecommendations.addAll(revenueRecs);

      // Deduplicate and prioritize
      final finalRecs = _deduplicateRecommendations(allRecommendations);

      // Save to database
      for (final rec in finalRecs) {
        await _saveRecommendation(rec);
      }

      // Update run log
      await _completeAgentRun(runId, finalRecs.length, 'success');

      return finalRecs;
    } catch (e) {
      await _completeAgentRun(runId, 0, 'failed', e.toString());
      rethrow;
    }
  }

  /// Run a specific agent
  Future<List<AgentRecommendationModel>> runAgent(AgentType type) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final runId = await _logAgentRun(userId, type.name);

    try {
      List<AgentRecommendationModel> recommendations;

      switch (type) {
        case AgentType.cashFlow:
          recommendations = await _cashFlowAgent.analyze();
          break;
        case AgentType.revenue:
          recommendations = await _revenueAgent.analyze();
          break;
        case AgentType.inventory:
          // TODO: Implement inventory agent
          recommendations = [];
          break;
        case AgentType.customer:
          // TODO: Implement customer agent
          recommendations = [];
          break;
      }

      // Save recommendations
      for (final rec in recommendations) {
        await _saveRecommendation(rec);
      }

      await _completeAgentRun(runId, recommendations.length, 'success');

      return recommendations;
    } catch (e) {
      await _completeAgentRun(runId, 0, 'failed', e.toString());
      rethrow;
    }
  }

  /// Get all pending recommendations
  Future<List<AgentRecommendationModel>> getPendingRecommendations() async {
    final response = await _client
        .from('agent_recommendations')
        .select()
        .eq('status', 'pending')
        .order('priority')
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) => AgentRecommendationModel.fromSupabase(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Get recommendations by agent type
  Future<List<AgentRecommendationModel>> getRecommendationsByType(
    AgentType type, {
    RecommendationStatus? status,
    int limit = 20,
  }) async {
    // Build query with filters before transforms
    PostgrestFilterBuilder query = _client
        .from('agent_recommendations')
        .select()
        .eq('agent_type', _agentTypeToDb(type));

    if (status != null) {
      query = query.eq('status', status.name);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map(
          (row) => AgentRecommendationModel.fromSupabase(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Get all recommendations with optional filters
  Future<List<AgentRecommendationModel>> getRecommendations({
    RecommendationStatus? status,
    RecommendationPriority? priority,
    int limit = 50,
  }) async {
    // Build query with filters before transforms
    PostgrestFilterBuilder query = _client
        .from('agent_recommendations')
        .select();

    if (status != null) {
      query = query.eq('status', status.name);
    }

    if (priority != null) {
      query = query.eq('priority', priority.name);
    }

    final response = await query
        .order('priority')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map(
          (row) => AgentRecommendationModel.fromSupabase(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Accept a recommendation
  Future<void> acceptRecommendation(String id) async {
    await _client
        .from('agent_recommendations')
        .update({
          'status': 'accepted',
          'resolved_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Dismiss a recommendation
  Future<void> dismissRecommendation(String id) async {
    await _client
        .from('agent_recommendations')
        .update({
          'status': 'dismissed',
          'resolved_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Snooze a recommendation
  Future<void> snoozeRecommendation(String id, Duration duration) async {
    await _client
        .from('agent_recommendations')
        .update({
          'status': 'snoozed',
          'snoozed_until': DateTime.now().add(duration).toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Get count of pending recommendations by priority
  Future<Map<RecommendationPriority, int>> getPendingCounts() async {
    final response = await _client
        .from('agent_recommendations')
        .select('priority')
        .eq('status', 'pending');

    final counts = <RecommendationPriority, int>{
      RecommendationPriority.critical: 0,
      RecommendationPriority.high: 0,
      RecommendationPriority.medium: 0,
      RecommendationPriority.low: 0,
    };

    for (final row in response as List) {
      final priority = RecommendationPriority.values.firstWhere(
        (p) => p.name == row['priority'],
        orElse: () => RecommendationPriority.medium,
      );
      counts[priority] = (counts[priority] ?? 0) + 1;
    }

    return counts;
  }

  /// Get agent statistics
  Future<Map<String, dynamic>> getAgentStats() async {
    final pending = await getPendingRecommendations();
    final counts = await getPendingCounts();

    // Get recent run stats
    final recentRuns = await _client
        .from('agent_run_logs')
        .select()
        .order('started_at', ascending: false)
        .limit(10);

    return {
      'total_pending': pending.length,
      'by_priority': counts,
      'critical_count': counts[RecommendationPriority.critical] ?? 0,
      'high_count': counts[RecommendationPriority.high] ?? 0,
      'recent_runs': (recentRuns as List).length,
    };
  }

  // Private helper methods

  Future<void> _saveRecommendation(AgentRecommendationModel rec) async {
    // Check for existing similar recommendation
    final existing = await _client
        .from('agent_recommendations')
        .select('id')
        .eq('agent_type', _agentTypeToDb(rec.agentType))
        .eq('title', rec.title)
        .eq('status', 'pending')
        .maybeSingle();

    if (existing != null) {
      // Update existing instead of creating duplicate
      await _client
          .from('agent_recommendations')
          .update({
            'description': rec.description,
            'data': rec.data,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);
    } else {
      await _client.from('agent_recommendations').insert(rec.toSupabase());
    }
  }

  List<AgentRecommendationModel> _deduplicateRecommendations(
    List<AgentRecommendationModel> recommendations,
  ) {
    final seen = <String>{};
    final deduplicated = <AgentRecommendationModel>[];

    // Sort by priority first
    final sorted = [...recommendations]
      ..sort((a, b) => a.priority.sortOrder.compareTo(b.priority.sortOrder));

    for (final rec in sorted) {
      final key = '${rec.agentType.name}_${rec.title}';
      if (!seen.contains(key)) {
        seen.add(key);
        deduplicated.add(rec);
      }
    }

    return deduplicated;
  }

  Future<String> _logAgentRun(String userId, String agentType) async {
    final response = await _client
        .from('agent_run_logs')
        .insert({
          'user_id': userId,
          'agent_type': agentType,
          'status': 'running',
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<void> _completeAgentRun(
    String runId,
    int recommendationsGenerated,
    String status, [
    String? errorMessage,
  ]) async {
    await _client
        .from('agent_run_logs')
        .update({
          'completed_at': DateTime.now().toIso8601String(),
          'recommendations_generated': recommendationsGenerated,
          'status': status,
          'error_message': errorMessage,
        })
        .eq('id', runId);
  }

  String _agentTypeToDb(AgentType type) {
    switch (type) {
      case AgentType.cashFlow:
        return 'cash_flow';
      case AgentType.revenue:
        return 'revenue';
      case AgentType.inventory:
        return 'inventory';
      case AgentType.customer:
        return 'customer';
    }
  }
}
