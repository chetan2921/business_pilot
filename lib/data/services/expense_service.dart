import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/expense_model.dart';

/// Service for expense CRUD operations with Supabase
class ExpenseService {
  ExpenseService._();
  static final ExpenseService _instance = ExpenseService._();
  static ExpenseService get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;
  static const String _tableName = 'expenses';

  /// Get all expenses for current user
  Future<List<ExpenseModel>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    ExpenseCategory? category,
    String? orderBy,
    bool ascending = false,
  }) async {
    var query = _client.from(_tableName).select();

    // Apply filters
    if (startDate != null) {
      query = query.gte(
        'expense_date',
        startDate.toIso8601String().split('T')[0],
      );
    }
    if (endDate != null) {
      query = query.lte(
        'expense_date',
        endDate.toIso8601String().split('T')[0],
      );
    }
    if (category != null) {
      query = query.eq('category', category.name);
    }

    // Apply ordering
    final orderColumn = orderBy ?? 'expense_date';
    final response = await query.order(orderColumn, ascending: ascending);

    return (response as List)
        .map((row) => ExpenseModel.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  /// Get single expense by ID
  Future<ExpenseModel?> getExpenseById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ExpenseModel.fromSupabase(response);
  }

  /// Create new expense
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final response = await _client
        .from(_tableName)
        .insert(expense.toSupabase())
        .select()
        .single();

    return ExpenseModel.fromSupabase(response);
  }

  /// Update existing expense
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final response = await _client
        .from(_tableName)
        .update(expense.toSupabase())
        .eq('id', expense.id)
        .select()
        .single();

    return ExpenseModel.fromSupabase(response);
  }

  /// Delete expense
  Future<void> deleteExpense(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  /// Get expense summary for date range
  Future<Map<String, dynamic>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final expenses = await getExpenses(startDate: startDate, endDate: endDate);

    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final byCategory = <ExpenseCategory, double>{};

    for (final expense in expenses) {
      byCategory[expense.category] =
          (byCategory[expense.category] ?? 0) + expense.amount;
    }

    return {'total': total, 'count': expenses.length, 'byCategory': byCategory};
  }

  /// Get today's expenses total
  Future<double> getTodayTotal() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final expenses = await getExpenses(
      startDate: startOfDay,
      endDate: endOfDay,
    );

    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }
}
