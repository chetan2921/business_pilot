import 'package:freezed_annotation/freezed_annotation.dart';

part 'communication_log_model.freezed.dart';
part 'communication_log_model.g.dart';

/// Communication log type
enum CommunicationType {
  call('Call', '📞'),
  email('Email', '📧'),
  sms('SMS', '💬'),
  meeting('Meeting', '🤝'),
  note('Note', '📝');

  final String displayName;
  final String emoji;

  const CommunicationType(this.displayName, this.emoji);

  String get label => '$emoji $displayName';
}

/// Communication direction
enum CommunicationDirection {
  inbound('Inbound'),
  outbound('Outbound');

  final String displayName;
  const CommunicationDirection(this.displayName);
}

/// Communication log model for tracking customer interactions
@freezed
abstract class CommunicationLogModel with _$CommunicationLogModel {
  const CommunicationLogModel._();

  const factory CommunicationLogModel({
    required String id,
    required String userId,
    required String customerId,
    required CommunicationType type,
    String? subject,
    required String content,
    @Default(CommunicationDirection.outbound) CommunicationDirection direction,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CommunicationLogModel;

  factory CommunicationLogModel.fromJson(Map<String, dynamic> json) =>
      _$CommunicationLogModelFromJson(json);

  /// Create from Supabase row
  factory CommunicationLogModel.fromSupabase(Map<String, dynamic> row) {
    return CommunicationLogModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      customerId: row['customer_id'] as String,
      type: CommunicationType.values.firstWhere(
        (t) => t.name == row['type'],
        orElse: () => CommunicationType.note,
      ),
      subject: row['subject'] as String?,
      content: row['content'] as String,
      direction: CommunicationDirection.values.firstWhere(
        (d) => d.name == row['direction'],
        orElse: () => CommunicationDirection.outbound,
      ),
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
      'customer_id': customerId,
      'type': type.name,
      'subject': subject,
      'content': content,
      'direction': direction.name,
    };
  }

  /// Format for display
  String get typeLabel => type.label;
}
