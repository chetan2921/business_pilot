import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/communication_log_model.dart';

/// Service for communication log CRUD operations
class CommunicationLogService {
  CommunicationLogService._();
  static final CommunicationLogService _instance = CommunicationLogService._();
  static CommunicationLogService get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;
  static const String _tableName = 'communication_logs';

  /// Get all communication logs for a customer
  Future<List<CommunicationLogModel>> getLogsForCustomer(
    String customerId,
  ) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) =>
              CommunicationLogModel.fromSupabase(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get recent communication logs across all customers
  Future<List<CommunicationLogModel>> getRecentLogs({int limit = 20}) async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map(
          (row) =>
              CommunicationLogModel.fromSupabase(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// Create new communication log
  Future<CommunicationLogModel> createLog(CommunicationLogModel log) async {
    final response = await _client
        .from(_tableName)
        .insert(log.toSupabase())
        .select()
        .single();

    return CommunicationLogModel.fromSupabase(response);
  }

  /// Update communication log
  Future<CommunicationLogModel> updateLog(CommunicationLogModel log) async {
    final response = await _client
        .from(_tableName)
        .update(log.toSupabase())
        .eq('id', log.id)
        .select()
        .single();

    return CommunicationLogModel.fromSupabase(response);
  }

  /// Delete communication log
  Future<void> deleteLog(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  /// Get communication count for customer
  Future<int> getLogCountForCustomer(String customerId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('customer_id', customerId)
        .count(CountOption.exact);
    return response.count;
  }

  /// Get last communication for customer
  Future<CommunicationLogModel?> getLastLogForCustomer(
    String customerId,
  ) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return CommunicationLogModel.fromSupabase(response);
  }
}
