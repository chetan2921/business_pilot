/// Types of agents that generate recommendations
enum AgentType {
  cashFlow,
  revenue,
  inventory,
  customer;

  String get displayName {
    switch (this) {
      case AgentType.cashFlow:
        return 'Cash Flow';
      case AgentType.revenue:
        return 'Revenue';
      case AgentType.inventory:
        return 'Inventory';
      case AgentType.customer:
        return 'Customer';
    }
  }

  String get icon {
    switch (this) {
      case AgentType.cashFlow:
        return '💰';
      case AgentType.revenue:
        return '📈';
      case AgentType.inventory:
        return '📦';
      case AgentType.customer:
        return '👥';
    }
  }
}

/// Priority levels for recommendations
enum RecommendationPriority {
  critical,
  high,
  medium,
  low;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  int get sortOrder {
    switch (this) {
      case RecommendationPriority.critical:
        return 0;
      case RecommendationPriority.high:
        return 1;
      case RecommendationPriority.medium:
        return 2;
      case RecommendationPriority.low:
        return 3;
    }
  }
}

/// Status of a recommendation
enum RecommendationStatus {
  pending,
  accepted,
  dismissed,
  snoozed,
  expired,
  autoResolved;

  String get displayName {
    switch (this) {
      case RecommendationStatus.pending:
        return 'Pending';
      case RecommendationStatus.accepted:
        return 'Accepted';
      case RecommendationStatus.dismissed:
        return 'Dismissed';
      case RecommendationStatus.snoozed:
        return 'Snoozed';
      case RecommendationStatus.expired:
        return 'Expired';
      case RecommendationStatus.autoResolved:
        return 'Auto-Resolved';
    }
  }
}

/// Type of action the user can take
enum ActionType {
  navigate, // Navigate to a screen
  approve, // Approve an action
  dismiss, // Dismiss the recommendation
  external, // Open external link/app
}

/// Agent recommendation model
class AgentRecommendationModel {
  final String id;
  final String userId;
  final AgentType agentType;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final String? suggestedAction;
  final ActionType? actionType;
  final Map<String, dynamic> actionData;
  final Map<String, dynamic> data;
  final RecommendationStatus status;
  final DateTime? snoozedUntil;
  final DateTime? expiresAt;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AgentRecommendationModel({
    required this.id,
    required this.userId,
    required this.agentType,
    required this.priority,
    required this.title,
    required this.description,
    this.suggestedAction,
    this.actionType,
    this.actionData = const {},
    this.data = const {},
    this.status = RecommendationStatus.pending,
    this.snoozedUntil,
    this.expiresAt,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Supabase row
  factory AgentRecommendationModel.fromSupabase(Map<String, dynamic> row) {
    return AgentRecommendationModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      agentType: _parseAgentType(row['agent_type'] as String),
      priority: _parsePriority(row['priority'] as String),
      title: row['title'] as String,
      description: row['description'] as String,
      suggestedAction: row['suggested_action'] as String?,
      actionType: row['action_type'] != null
          ? _parseActionType(row['action_type'] as String)
          : null,
      actionData: (row['action_data'] as Map<String, dynamic>?) ?? {},
      data: (row['data'] as Map<String, dynamic>?) ?? {},
      status: _parseStatus(row['status'] as String),
      snoozedUntil: row['snoozed_until'] != null
          ? DateTime.parse(row['snoozed_until'] as String)
          : null,
      expiresAt: row['expires_at'] != null
          ? DateTime.parse(row['expires_at'] as String)
          : null,
      resolvedAt: row['resolved_at'] != null
          ? DateTime.parse(row['resolved_at'] as String)
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  /// Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'agent_type': _agentTypeToDb(agentType),
      'priority': priority.name,
      'title': title,
      'description': description,
      'suggested_action': suggestedAction,
      'action_type': actionType?.name,
      'action_data': actionData,
      'data': data,
      'status': status == RecommendationStatus.autoResolved
          ? 'auto_resolved'
          : status.name,
      'snoozed_until': snoozedUntil?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  /// Check if recommendation is actionable
  bool get isActionable =>
      status == RecommendationStatus.pending ||
      status == RecommendationStatus.snoozed;

  /// Get time since creation
  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  /// Create a copy with updated fields
  AgentRecommendationModel copyWith({
    String? id,
    String? userId,
    AgentType? agentType,
    RecommendationPriority? priority,
    String? title,
    String? description,
    String? suggestedAction,
    ActionType? actionType,
    Map<String, dynamic>? actionData,
    Map<String, dynamic>? data,
    RecommendationStatus? status,
    DateTime? snoozedUntil,
    DateTime? expiresAt,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentRecommendationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      agentType: agentType ?? this.agentType,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      actionType: actionType ?? this.actionType,
      actionData: actionData ?? this.actionData,
      data: data ?? this.data,
      status: status ?? this.status,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      expiresAt: expiresAt ?? this.expiresAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

AgentType _parseAgentType(String value) {
  switch (value) {
    case 'cash_flow':
      return AgentType.cashFlow;
    case 'revenue':
      return AgentType.revenue;
    case 'inventory':
      return AgentType.inventory;
    case 'customer':
      return AgentType.customer;
    default:
      return AgentType.cashFlow;
  }
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

RecommendationPriority _parsePriority(String value) {
  return RecommendationPriority.values.firstWhere(
    (e) => e.name == value,
    orElse: () => RecommendationPriority.medium,
  );
}

RecommendationStatus _parseStatus(String value) {
  if (value == 'auto_resolved') return RecommendationStatus.autoResolved;
  return RecommendationStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => RecommendationStatus.pending,
  );
}

ActionType _parseActionType(String value) {
  return ActionType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ActionType.navigate,
  );
}

/// Model for agent run logs
class AgentRunLog {
  final String id;
  final String userId;
  final AgentType agentType;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? durationMs;
  final int recommendationsGenerated;
  final String status;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  AgentRunLog({
    required this.id,
    required this.userId,
    required this.agentType,
    required this.startedAt,
    this.completedAt,
    this.durationMs,
    this.recommendationsGenerated = 0,
    this.status = 'running',
    this.errorMessage,
    this.metadata = const {},
  });

  factory AgentRunLog.fromSupabase(Map<String, dynamic> row) {
    return AgentRunLog(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      agentType: _parseAgentType(row['agent_type'] as String),
      startedAt: DateTime.parse(row['started_at'] as String),
      completedAt: row['completed_at'] != null
          ? DateTime.parse(row['completed_at'] as String)
          : null,
      durationMs: row['duration_ms'] as int?,
      recommendationsGenerated: row['recommendations_generated'] as int? ?? 0,
      status: row['status'] as String,
      errorMessage: row['error_message'] as String?,
      metadata: (row['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }
}
