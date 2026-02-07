import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/customer_reminder_model.dart';

/// Service for customer reminder CRUD operations
class CustomerReminderService {
  CustomerReminderService._();
  static final CustomerReminderService _instance = CustomerReminderService._();
  static CustomerReminderService get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;
  static const String _tableName = 'customer_reminders';

  /// Get all reminders for a customer
  Future<List<CustomerReminderModel>> getRemindersForCustomer(
    String customerId,
  ) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('customer_id', customerId)
        .order('reminder_date', ascending: true);

    return (response as List)
        .map(
          (row) =>
              CustomerReminderModel.fromSupabase(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get all pending reminders (not completed, includes overdue)
  Future<List<CustomerReminderModel>> getPendingReminders() async {
    final response = await _client
        .from(_tableName)
        .select('*, customers(name)')
        .eq('is_completed', false)
        .order('reminder_date', ascending: true);

    return (response as List)
        .map(
          (row) =>
              CustomerReminderModel.fromSupabase(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get today's reminders
  Future<List<CustomerReminderModel>> getTodayReminders() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from(_tableName)
        .select('*, customers(name)')
        .eq('is_completed', false)
        .gte('reminder_date', startOfDay.toIso8601String())
        .lt('reminder_date', endOfDay.toIso8601String())
        .order('reminder_date', ascending: true);

    return (response as List)
        .map(
          (row) =>
              CustomerReminderModel.fromSupabase(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get overdue reminders
  Future<List<CustomerReminderModel>> getOverdueReminders() async {
    final now = DateTime.now();

    final response = await _client
        .from(_tableName)
        .select('*, customers(name)')
        .eq('is_completed', false)
        .lt('reminder_date', now.toIso8601String())
        .order('reminder_date', ascending: true);

    return (response as List)
        .map(
          (row) =>
              CustomerReminderModel.fromSupabase(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get upcoming reminders (next 7 days)
  Future<List<CustomerReminderModel>> getUpcomingReminders({
    int days = 7,
  }) async {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));

    final response = await _client
        .from(_tableName)
        .select('*, customers(name)')
        .eq('is_completed', false)
        .gte('reminder_date', now.toIso8601String())
        .lte('reminder_date', futureDate.toIso8601String())
        .order('reminder_date', ascending: true);

    return (response as List)
        .map(
          (row) =>
              CustomerReminderModel.fromSupabase(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// Create new reminder
  Future<CustomerReminderModel> createReminder(
    CustomerReminderModel reminder,
  ) async {
    final response = await _client
        .from(_tableName)
        .insert(reminder.toSupabase())
        .select()
        .single();

    return CustomerReminderModel.fromSupabase(response);
  }

  /// Update reminder
  Future<CustomerReminderModel> updateReminder(
    CustomerReminderModel reminder,
  ) async {
    final response = await _client
        .from(_tableName)
        .update(reminder.toSupabase())
        .eq('id', reminder.id)
        .select()
        .single();

    return CustomerReminderModel.fromSupabase(response);
  }

  /// Mark reminder as completed
  Future<void> completeReminder(String id) async {
    await _client
        .from(_tableName)
        .update({
          'is_completed': true,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Delete reminder
  Future<void> deleteReminder(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  /// Get reminder count summary
  Future<Map<String, int>> getReminderSummary() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get all pending reminders in one query
    final response = await _client
        .from(_tableName)
        .select('reminder_date')
        .eq('is_completed', false);

    final reminders = response as List;

    int overdue = 0;
    int today = 0;
    int upcoming = 0;

    for (final r in reminders) {
      final date = DateTime.parse(r['reminder_date'] as String);
      if (date.isBefore(startOfDay)) {
        overdue++;
      } else if (date.isBefore(endOfDay)) {
        today++;
      } else {
        upcoming++;
      }
    }

    return {
      'overdue': overdue,
      'today': today,
      'upcoming': upcoming,
      'total': reminders.length,
    };
  }
}
