import '../models/customer_model.dart';
import 'communication_log_service.dart';
import 'customer_reminder_service.dart';

/// AI-powered customer intelligence service
class AiCustomerService {
  AiCustomerService._();
  static final AiCustomerService _instance = AiCustomerService._();
  static AiCustomerService get instance => _instance;

  final _communicationService = CommunicationLogService.instance;
  final _reminderService = CustomerReminderService.instance;

  // ============================================================
  // CHURN RISK PREDICTION
  // ============================================================

  /// Calculate churn risk score for a customer (0-100, higher = more risk)
  Future<ChurnRiskAnalysis> analyzeChurnRisk(CustomerModel customer) async {
    // Get communication history
    final logs = await _communicationService.getLogsForCustomer(customer.id);
    final lastLog = logs.isNotEmpty ? logs.first : null;

    // Calculate risk factors
    double riskScore = 0;
    final riskFactors = <String>[];

    // Factor 1: Days since last purchase (max 40 points)
    final daysSinceLastPurchase = customer.daysSinceLastPurchase;
    if (daysSinceLastPurchase != null) {
      if (daysSinceLastPurchase > 90) {
        riskScore += 40;
        riskFactors.add('No purchase in $daysSinceLastPurchase days');
      } else if (daysSinceLastPurchase > 60) {
        riskScore += 30;
        riskFactors.add('No purchase in $daysSinceLastPurchase days');
      } else if (daysSinceLastPurchase > 30) {
        riskScore += 15;
        riskFactors.add('No purchase in $daysSinceLastPurchase days');
      }
    } else {
      riskScore += 20;
      riskFactors.add('No purchase history');
    }

    // Factor 2: Days since last communication (max 30 points)
    if (lastLog != null) {
      final daysSinceContact = DateTime.now()
          .difference(lastLog.createdAt!)
          .inDays;
      if (daysSinceContact > 60) {
        riskScore += 30;
        riskFactors.add('No contact in $daysSinceContact days');
      } else if (daysSinceContact > 30) {
        riskScore += 15;
        riskFactors.add('No contact in $daysSinceContact days');
      }
    } else {
      riskScore += 20;
      riskFactors.add('No communication history');
    }

    // Factor 3: Customer segment (max 15 points)
    if (customer.segment == CustomerSegment.newCustomer) {
      riskScore += 15;
      riskFactors.add('New customer needs nurturing');
    } else if (customer.segment == CustomerSegment.bronze) {
      riskScore += 10;
      riskFactors.add('Bronze tier - potential to upgrade');
    }

    // Factor 4: Total spent (max 15 points)
    if (customer.totalSpent < 1000) {
      riskScore += 15;
      riskFactors.add(
        'Low lifetime value (${_formatCurrency(customer.totalSpent)})',
      );
    } else if (customer.totalSpent < 5000) {
      riskScore += 8;
    }

    // Cap at 100
    riskScore = riskScore.clamp(0, 100);

    return ChurnRiskAnalysis(
      customerId: customer.id,
      riskScore: riskScore.round(),
      riskLevel: _getRiskLevel(riskScore),
      riskFactors: riskFactors,
      lastPurchaseDate: customer.lastPurchaseDate,
      lastContactDate: lastLog?.createdAt,
      daysSinceLastPurchase: daysSinceLastPurchase,
      recommendedActions: _getChurnPreventionActions(riskScore, riskFactors),
    );
  }

  ChurnRiskLevel _getRiskLevel(double score) {
    if (score >= 70) return ChurnRiskLevel.high;
    if (score >= 40) return ChurnRiskLevel.medium;
    if (score >= 20) return ChurnRiskLevel.low;
    return ChurnRiskLevel.minimal;
  }

  List<String> _getChurnPreventionActions(double score, List<String> factors) {
    final actions = <String>[];

    if (score >= 70) {
      actions.add('Urgent: Schedule a personal call immediately');
      actions.add('Consider offering a loyalty discount');
    } else if (score >= 40) {
      actions.add('Send a check-in email or message');
      actions.add('Share new products or promotions');
    } else if (score >= 20) {
      actions.add('Add to re-engagement email campaign');
    }

    if (factors.any((f) => f.contains('No purchase'))) {
      actions.add('Send a special comeback offer');
    }
    if (factors.any((f) => f.contains('New customer'))) {
      actions.add('Schedule onboarding follow-up');
    }

    return actions.isNotEmpty
        ? actions
        : ['Customer is healthy - maintain engagement'];
  }

  // ============================================================
  // NEXT BEST ACTION
  // ============================================================

  /// Get next best action suggestions for a customer
  Future<List<NextBestAction>> getNextBestActions(
    CustomerModel customer,
  ) async {
    final actions = <NextBestAction>[];
    final logs = await _communicationService.getLogsForCustomer(customer.id);
    final reminders = await _reminderService.getRemindersForCustomer(
      customer.id,
    );
    final pendingReminders = reminders.where((r) => !r.isCompleted).toList();

    // Check for overdue reminders
    for (final reminder in pendingReminders) {
      if (reminder.isOverdue) {
        actions.add(
          NextBestAction(
            type: ActionType.urgentFollowUp,
            title: 'Overdue: ${reminder.title}',
            description:
                'This reminder was due ${_formatDate(reminder.reminderDate)}',
            priority: ActionPriority.high,
            icon: '⚠️',
          ),
        );
      }
    }

    // Check days since last purchase
    final daysSince = customer.daysSinceLastPurchase;
    if (daysSince != null && daysSince > 30) {
      actions.add(
        NextBestAction(
          type: ActionType.reEngagement,
          title: 'Re-engagement opportunity',
          description: 'No purchase in $daysSince days - consider reaching out',
          priority: daysSince > 60
              ? ActionPriority.high
              : ActionPriority.medium,
          icon: '🔄',
        ),
      );
    }

    // Check communication gap
    if (logs.isEmpty) {
      actions.add(
        NextBestAction(
          type: ActionType.introduction,
          title: 'Initiate first contact',
          description: 'No communication history - introduce yourself',
          priority: ActionPriority.medium,
          icon: '👋',
        ),
      );
    } else {
      final lastContact = logs.first.createdAt!;
      final daysSinceContact = DateTime.now().difference(lastContact).inDays;
      if (daysSinceContact > 14) {
        actions.add(
          NextBestAction(
            type: ActionType.followUp,
            title: 'Check-in call or message',
            description: 'Last contact was $daysSinceContact days ago',
            priority: daysSinceContact > 30
                ? ActionPriority.high
                : ActionPriority.low,
            icon: '📞',
          ),
        );
      }
    }

    // Segment-based actions
    if (customer.segment == CustomerSegment.newCustomer) {
      actions.add(
        NextBestAction(
          type: ActionType.onboarding,
          title: 'Welcome onboarding',
          description: 'New customer - ensure great first experience',
          priority: ActionPriority.medium,
          icon: '🎯',
        ),
      );
    } else if (customer.segment == CustomerSegment.gold) {
      actions.add(
        NextBestAction(
          type: ActionType.appreciation,
          title: 'VIP appreciation',
          description: 'Gold customer - maintain premium relationship',
          priority: ActionPriority.low,
          icon: '🌟',
        ),
      );
    }

    // Sort by priority
    actions.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return actions;
  }

  // ============================================================
  // PERSONALIZED COMMUNICATION TEMPLATES
  // ============================================================

  /// Generate personalized communication templates for a customer
  Future<List<CommunicationTemplate>> getPersonalizedTemplates(
    CustomerModel customer,
  ) async {
    final templates = <CommunicationTemplate>[];
    final churnRisk = await analyzeChurnRisk(customer);

    // Re-engagement template
    if (customer.daysSinceLastPurchase != null &&
        customer.daysSinceLastPurchase! > 30) {
      templates.add(
        CommunicationTemplate(
          type: TemplateType.reEngagement,
          subject: 'We miss you, ${customer.name.split(' ').first}!',
          body: '''Hi ${customer.name.split(' ').first},

It's been a while since your last visit! We've got some exciting new products that we think you'll love.

As a valued customer, here's a special 10% discount on your next order. Use code: COMEBACK10

Looking forward to seeing you soon!

Best regards''',
          tone: 'Friendly & Inviting',
        ),
      );
    }

    // Follow-up template
    templates.add(
      CommunicationTemplate(
        type: TemplateType.followUp,
        subject: 'Following up - ${customer.name}',
        body:
            '''Hi ${customer.name.split(' ').first},

I wanted to check in and see how everything is going. 

${customer.lastPurchaseDate != null ? 'Hope you\'re enjoying your recent purchase!' : 'Is there anything I can help you with?'}

Please don't hesitate to reach out if you have any questions.

Best regards''',
        tone: 'Professional & Caring',
      ),
    );

    // High churn risk template
    if (churnRisk.riskLevel == ChurnRiskLevel.high) {
      templates.add(
        CommunicationTemplate(
          type: TemplateType.winBack,
          subject:
              'A special offer just for you, ${customer.name.split(' ').first}',
          body: '''Dear ${customer.name.split(' ').first},

We value your business and noticed it's been a while since we connected.

We'd love to welcome you back with an exclusive offer: 15% off your next purchase!

Is there anything we could be doing better? Your feedback means a lot to us.

Warm regards''',
          tone: 'Appreciative & Urgent',
        ),
      );
    }

    // Birthday/Anniversary template
    templates.add(
      CommunicationTemplate(
        type: TemplateType.celebration,
        subject: 'A special gift for you! 🎉',
        body: '''Dear ${customer.name.split(' ').first},

On behalf of our team, we'd like to wish you a wonderful day!

As a token of our appreciation, please enjoy 20% off on us.

Thank you for being part of our family!

Cheers''',
        tone: 'Celebratory & Warm',
      ),
    );

    // Thank you template
    templates.add(
      CommunicationTemplate(
        type: TemplateType.thankYou,
        subject: 'Thank you for your business!',
        body: '''Dear ${customer.name.split(' ').first},

Thank you so much for your recent purchase!

We truly appreciate your business and hope you love your new items.

If you have any questions or concerns, please don't hesitate to reach out.

With gratitude''',
        tone: 'Grateful & Professional',
      ),
    );

    return templates;
  }

  // ============================================================
  // CUSTOMER INSIGHTS SUMMARY
  // ============================================================

  /// Get comprehensive customer insights
  Future<CustomerInsightsSummary> getCustomerInsights(
    CustomerModel customer,
  ) async {
    final churnRisk = await analyzeChurnRisk(customer);
    final nextActions = await getNextBestActions(customer);
    final logs = await _communicationService.getLogsForCustomer(customer.id);
    final reminders = await _reminderService.getRemindersForCustomer(
      customer.id,
    );

    return CustomerInsightsSummary(
      customer: customer,
      churnRisk: churnRisk,
      nextBestActions: nextActions,
      totalCommunications: logs.length,
      pendingReminders: reminders.where((r) => !r.isCompleted).length,
      healthScore: 100 - churnRisk.riskScore,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================================
// DATA MODELS
// ============================================================

enum ChurnRiskLevel { minimal, low, medium, high }

class ChurnRiskAnalysis {
  final String customerId;
  final int riskScore;
  final ChurnRiskLevel riskLevel;
  final List<String> riskFactors;
  final DateTime? lastPurchaseDate;
  final DateTime? lastContactDate;
  final int? daysSinceLastPurchase;
  final List<String> recommendedActions;

  ChurnRiskAnalysis({
    required this.customerId,
    required this.riskScore,
    required this.riskLevel,
    required this.riskFactors,
    this.lastPurchaseDate,
    this.lastContactDate,
    this.daysSinceLastPurchase,
    required this.recommendedActions,
  });

  String get riskEmoji {
    switch (riskLevel) {
      case ChurnRiskLevel.high:
        return '🔴';
      case ChurnRiskLevel.medium:
        return '🟠';
      case ChurnRiskLevel.low:
        return '🟡';
      case ChurnRiskLevel.minimal:
        return '🟢';
    }
  }

  String get riskLabel {
    switch (riskLevel) {
      case ChurnRiskLevel.high:
        return 'High Risk';
      case ChurnRiskLevel.medium:
        return 'Medium Risk';
      case ChurnRiskLevel.low:
        return 'Low Risk';
      case ChurnRiskLevel.minimal:
        return 'Minimal Risk';
    }
  }
}

enum ActionType {
  urgentFollowUp,
  followUp,
  reEngagement,
  introduction,
  onboarding,
  appreciation,
  payment,
}

enum ActionPriority { high, medium, low }

class NextBestAction {
  final ActionType type;
  final String title;
  final String description;
  final ActionPriority priority;
  final String icon;

  NextBestAction({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.icon,
  });

  String get priorityLabel {
    switch (priority) {
      case ActionPriority.high:
        return 'High Priority';
      case ActionPriority.medium:
        return 'Medium Priority';
      case ActionPriority.low:
        return 'Low Priority';
    }
  }
}

enum TemplateType { reEngagement, followUp, winBack, celebration, thankYou }

class CommunicationTemplate {
  final TemplateType type;
  final String subject;
  final String body;
  final String tone;

  CommunicationTemplate({
    required this.type,
    required this.subject,
    required this.body,
    required this.tone,
  });

  String get typeLabel {
    switch (type) {
      case TemplateType.reEngagement:
        return 'Re-engagement';
      case TemplateType.followUp:
        return 'Follow-up';
      case TemplateType.winBack:
        return 'Win-back';
      case TemplateType.celebration:
        return 'Celebration';
      case TemplateType.thankYou:
        return 'Thank You';
    }
  }
}

class CustomerInsightsSummary {
  final CustomerModel customer;
  final ChurnRiskAnalysis churnRisk;
  final List<NextBestAction> nextBestActions;
  final int totalCommunications;
  final int pendingReminders;
  final int healthScore;

  CustomerInsightsSummary({
    required this.customer,
    required this.churnRisk,
    required this.nextBestActions,
    required this.totalCommunications,
    required this.pendingReminders,
    required this.healthScore,
  });
}
