import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_model.freezed.dart';
part 'expense_model.g.dart';

/// Expense categories
enum ExpenseCategory {
  food('Food & Dining', '🍔'),
  transport('Transport', '🚗'),
  utilities('Utilities', '💡'),
  rent('Rent & Housing', '🏠'),
  supplies('Office Supplies', '📎'),
  marketing('Marketing', '📢'),
  salary('Salary & Wages', '💰'),
  equipment('Equipment', '🖥️'),
  travel('Business Travel', '✈️'),
  insurance('Insurance', '🛡️'),
  taxes('Taxes', '📋'),
  entertainment('Entertainment', '🎬'),
  healthcare('Healthcare', '🏥'),
  subscriptions('Subscriptions', '📱'),
  other('Other', '📦');

  final String displayName;
  final String emoji;

  const ExpenseCategory(this.displayName, this.emoji);

  String get label => '$emoji $displayName';
}

/// Expense model
@freezed
abstract class ExpenseModel with _$ExpenseModel {
  const ExpenseModel._();

  const factory ExpenseModel({
    required String id,
    required String userId,
    required double amount,
    required ExpenseCategory category,
    String? description,
    String? vendor,
    required DateTime expenseDate,
    String? receiptUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ExpenseModel;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);

  /// Create ExpenseModel from Supabase row
  factory ExpenseModel.fromSupabase(Map<String, dynamic> row) {
    return ExpenseModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (c) => c.name == row['category'],
        orElse: () => ExpenseCategory.other,
      ),
      description: row['description'] as String?,
      vendor: row['vendor'] as String?,
      expenseDate: DateTime.parse(row['expense_date'] as String),
      receiptUrl: row['receipt_url'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  /// Convert to Supabase insert format
  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'amount': amount,
      'category': category.name,
      'description': description,
      'vendor': vendor,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'receipt_url': receiptUrl,
    };
  }

  /// Format amount as currency (INR)
  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
}
