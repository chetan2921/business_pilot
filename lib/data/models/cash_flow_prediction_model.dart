// Cash flow prediction models for the proactive agent system

/// Weekly cash flow projection
class CashFlowProjection {
  final String id;
  final String userId;
  final DateTime projectionDate;
  final double projectedInflow;
  final double projectedOutflow;
  final double projectedBalance;
  final double confidenceScore;
  final List<InflowSource> inflowSources;
  final List<OutflowSource> outflowSources;
  final DateTime createdAt;

  CashFlowProjection({
    required this.id,
    required this.userId,
    required this.projectionDate,
    required this.projectedInflow,
    required this.projectedOutflow,
    required this.projectedBalance,
    this.confidenceScore = 0.8,
    this.inflowSources = const [],
    this.outflowSources = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CashFlowProjection.fromSupabase(Map<String, dynamic> row) {
    return CashFlowProjection(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      projectionDate: DateTime.parse(row['projection_date'] as String),
      projectedInflow: (row['projected_inflow'] as num).toDouble(),
      projectedOutflow: (row['projected_outflow'] as num).toDouble(),
      projectedBalance: (row['projected_balance'] as num).toDouble(),
      confidenceScore: (row['confidence_score'] as num?)?.toDouble() ?? 0.8,
      inflowSources: _parseInflowSources(row['inflow_sources']),
      outflowSources: _parseOutflowSources(row['outflow_sources']),
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'projection_date': projectionDate.toIso8601String().split('T')[0],
      'projected_inflow': projectedInflow,
      'projected_outflow': projectedOutflow,
      'projected_balance': projectedBalance,
      'confidence_score': confidenceScore,
      'inflow_sources': inflowSources.map((s) => s.toJson()).toList(),
      'outflow_sources': outflowSources.map((s) => s.toJson()).toList(),
    };
  }

  /// Net cash flow for this period
  double get netCashFlow => projectedInflow - projectedOutflow;

  /// Is this projection showing a deficit?
  bool get isDeficit => projectedBalance < 0;

  /// Confidence level as percentage
  String get confidencePercentage => '${(confidenceScore * 100).toInt()}%';
}

/// Source of expected inflow
class InflowSource {
  final String name;
  final double amount;
  final String type; // 'receivable', 'expected_sale', 'recurring'
  final double probability;

  InflowSource({
    required this.name,
    required this.amount,
    required this.type,
    this.probability = 1.0,
  });

  factory InflowSource.fromJson(Map<String, dynamic> json) {
    return InflowSource(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      probability: (json['probability'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'type': type,
    'probability': probability,
  };

  /// Expected contribution considering probability
  double get expectedAmount => amount * probability;
}

/// Source of expected outflow
class OutflowSource {
  final String name;
  final double amount;
  final String type; // 'payable', 'recurring', 'scheduled'
  final bool isFixed;
  final DateTime? dueDate;

  OutflowSource({
    required this.name,
    required this.amount,
    required this.type,
    this.isFixed = true,
    this.dueDate,
  });

  factory OutflowSource.fromJson(Map<String, dynamic> json) {
    return OutflowSource(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      isFixed: json['is_fixed'] as bool? ?? true,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'type': type,
    'is_fixed': isFixed,
    'due_date': dueDate?.toIso8601String(),
  };
}

List<InflowSource> _parseInflowSources(dynamic sources) {
  if (sources == null) return [];
  if (sources is! List) return [];
  return sources
      .map((s) => InflowSource.fromJson(s as Map<String, dynamic>))
      .toList();
}

List<OutflowSource> _parseOutflowSources(dynamic sources) {
  if (sources == null) return [];
  if (sources is! List) return [];
  return sources
      .map((s) => OutflowSource.fromJson(s as Map<String, dynamic>))
      .toList();
}

/// Cash flow forecast summary
class CashFlowForecast {
  final List<CashFlowProjection> weeklyProjections;
  final double currentBalance;
  final double lowestProjectedBalance;
  final DateTime? shortfallDate;
  final List<CashFlowAlert> alerts;

  CashFlowForecast({
    required this.weeklyProjections,
    required this.currentBalance,
    required this.lowestProjectedBalance,
    this.shortfallDate,
    this.alerts = const [],
  });

  /// Check if there's a projected shortfall
  bool get hasShortfall => lowestProjectedBalance < 0;

  /// Days until shortfall (null if no shortfall)
  int? get daysUntilShortfall {
    if (shortfallDate == null) return null;
    return shortfallDate!.difference(DateTime.now()).inDays;
  }

  /// Overall health rating
  String get healthRating {
    if (hasShortfall) return 'Critical';
    if (lowestProjectedBalance < currentBalance * 0.2) return 'Warning';
    if (lowestProjectedBalance < currentBalance * 0.5) return 'Fair';
    return 'Healthy';
  }
}

/// Cash flow alert
class CashFlowAlert {
  final String title;
  final String description;
  final CashFlowAlertType type;
  final double impactAmount;
  final String? suggestedAction;

  CashFlowAlert({
    required this.title,
    required this.description,
    required this.type,
    required this.impactAmount,
    this.suggestedAction,
  });
}

enum CashFlowAlertType {
  shortfall,
  lowBalance,
  overdueReceivable,
  upcomingPayment,
  opportunity;

  String get icon {
    switch (this) {
      case CashFlowAlertType.shortfall:
        return '🚨';
      case CashFlowAlertType.lowBalance:
        return '⚠️';
      case CashFlowAlertType.overdueReceivable:
        return '📥';
      case CashFlowAlertType.upcomingPayment:
        return '📤';
      case CashFlowAlertType.opportunity:
        return '💡';
    }
  }
}

/// Revenue opportunity model
class RevenueOpportunity {
  final String id;
  final String userId;
  final OpportunityType type;
  final String? customerId;
  final String? productId;
  final String title;
  final String description;
  final double? estimatedRevenue;
  final double confidenceScore;
  final Map<String, dynamic> data;
  final OpportunityStatus status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? actionedAt;

  RevenueOpportunity({
    required this.id,
    required this.userId,
    required this.type,
    this.customerId,
    this.productId,
    required this.title,
    required this.description,
    this.estimatedRevenue,
    this.confidenceScore = 0.7,
    this.data = const {},
    this.status = OpportunityStatus.open,
    this.expiresAt,
    DateTime? createdAt,
    this.actionedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RevenueOpportunity.fromSupabase(Map<String, dynamic> row) {
    return RevenueOpportunity(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      type: _parseOpportunityType(row['opportunity_type'] as String),
      customerId: row['customer_id'] as String?,
      productId: row['product_id'] as String?,
      title: row['title'] as String,
      description: row['description'] as String,
      estimatedRevenue: (row['estimated_revenue'] as num?)?.toDouble(),
      confidenceScore: (row['confidence_score'] as num?)?.toDouble() ?? 0.7,
      data: (row['data'] as Map<String, dynamic>?) ?? {},
      status: _parseOpportunityStatus(row['status'] as String),
      expiresAt: row['expires_at'] != null
          ? DateTime.parse(row['expires_at'] as String)
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
      actionedAt: row['actioned_at'] != null
          ? DateTime.parse(row['actioned_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'opportunity_type': type.name,
      'customer_id': customerId,
      'product_id': productId,
      'title': title,
      'description': description,
      'estimated_revenue': estimatedRevenue,
      'confidence_score': confidenceScore,
      'data': data,
      'status': status.name,
      'expires_at': expiresAt?.toIso8601String(),
      'actioned_at': actionedAt?.toIso8601String(),
    };
  }

  bool get isOpen => status == OpportunityStatus.open;
}

enum OpportunityType {
  upsell,
  crossSell,
  priceOptimization,
  promotion,
  bundle;

  String get displayName {
    switch (this) {
      case OpportunityType.upsell:
        return 'Upsell';
      case OpportunityType.crossSell:
        return 'Cross-Sell';
      case OpportunityType.priceOptimization:
        return 'Price Optimization';
      case OpportunityType.promotion:
        return 'Promotion';
      case OpportunityType.bundle:
        return 'Bundle';
    }
  }

  String get icon {
    switch (this) {
      case OpportunityType.upsell:
        return '⬆️';
      case OpportunityType.crossSell:
        return '↔️';
      case OpportunityType.priceOptimization:
        return '💰';
      case OpportunityType.promotion:
        return '🎯';
      case OpportunityType.bundle:
        return '📦';
    }
  }
}

enum OpportunityStatus { open, actioned, dismissed, expired }

OpportunityType _parseOpportunityType(String value) {
  switch (value) {
    case 'cross_sell':
      return OpportunityType.crossSell;
    case 'price_optimization':
      return OpportunityType.priceOptimization;
    default:
      return OpportunityType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => OpportunityType.upsell,
      );
  }
}

OpportunityStatus _parseOpportunityStatus(String value) {
  return OpportunityStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => OpportunityStatus.open,
  );
}
