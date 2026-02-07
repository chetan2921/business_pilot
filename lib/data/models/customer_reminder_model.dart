import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_reminder_model.freezed.dart';
part 'customer_reminder_model.g.dart';

/// Reminder type
enum ReminderType {
  followUp('Follow Up', '📞'),
  payment('Payment Due', '💰'),
  birthday('Birthday', '🎂'),
  anniversary('Anniversary', '🎉'),
  custom('Custom', '📌');

  final String displayName;
  final String emoji;

  const ReminderType(this.displayName, this.emoji);

  String get label => '$emoji $displayName';
}

/// Customer reminder model
@freezed
abstract class CustomerReminderModel with _$CustomerReminderModel {
  const CustomerReminderModel._();

  const factory CustomerReminderModel({
    required String id,
    required String userId,
    required String customerId,
    required String title,
    String? description,
    required DateTime reminderDate,
    @Default(ReminderType.followUp) ReminderType reminderType,
    @Default(false) bool isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Joined customer name for display
    String? customerName,
  }) = _CustomerReminderModel;

  factory CustomerReminderModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerReminderModelFromJson(json);

  /// Create from Supabase row
  factory CustomerReminderModel.fromSupabase(Map<String, dynamic> row) {
    return CustomerReminderModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      customerId: row['customer_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      reminderDate: DateTime.parse(row['reminder_date'] as String),
      reminderType: ReminderType.values.firstWhere(
        (t) =>
            t.name == row['reminder_type'] ||
            t.name == (row['reminder_type'] as String?)?.replaceAll('_', ''),
        orElse: () => ReminderType.custom,
      ),
      isCompleted: row['is_completed'] as bool? ?? false,
      completedAt: row['completed_at'] != null
          ? DateTime.parse(row['completed_at'] as String)
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
      customerName: row['customers'] != null
          ? (row['customers'] as Map<String, dynamic>)['name'] as String?
          : null,
    );
  }

  /// Convert to Supabase insert format
  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'customer_id': customerId,
      'title': title,
      'description': description,
      'reminder_date': reminderDate.toIso8601String(),
      'reminder_type': reminderType.name == 'followUp'
          ? 'follow_up'
          : reminderType.name,
      'is_completed': isCompleted,
    };
  }

  /// Check if reminder is overdue
  bool get isOverdue => !isCompleted && reminderDate.isBefore(DateTime.now());

  /// Check if reminder is due today
  bool get isDueToday {
    final now = DateTime.now();
    return !isCompleted &&
        reminderDate.year == now.year &&
        reminderDate.month == now.month &&
        reminderDate.day == now.day;
  }

  /// Format for display
  String get typeLabel => reminderType.label;
}
