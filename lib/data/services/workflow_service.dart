import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/invoice_model.dart';
import 'invoice_service.dart';
import 'analytics_service.dart';

/// Workflow types supported by the system
enum WorkflowType {
  invoiceFollowUp,
  weeklyBusinessReview,
  lowStockAlert,
  customerFollowUp,
}

/// Status of a workflow run
enum WorkflowRunStatus { pending, running, completed, failed, skipped }

/// Workflow run model
class WorkflowRun {
  final String id;
  final WorkflowType type;
  final WorkflowRunStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic> results;
  final String? error;

  WorkflowRun({
    required this.id,
    required this.type,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.results = const {},
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'workflow_type': type.name,
    'status': status.name,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'results': results,
    'error': error,
  };

  factory WorkflowRun.fromJson(Map<String, dynamic> json) {
    return WorkflowRun(
      id: json['id'] as String,
      type: WorkflowType.values.firstWhere(
        (e) => e.name == json['workflow_type'],
        orElse: () => WorkflowType.invoiceFollowUp,
      ),
      status: WorkflowRunStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WorkflowRunStatus.pending,
      ),
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      results: json['results'] as Map<String, dynamic>? ?? {},
      error: json['error'] as String?,
    );
  }
}

/// Workflow settings
class WorkflowSettings {
  final bool invoiceFollowUpEnabled;
  final int invoiceFollowUpDays;
  final bool weeklyReviewEnabled;
  final int weeklyReviewDay; // 1-7 for Monday-Sunday
  final bool lowStockAlertEnabled;
  final int lowStockThreshold;

  const WorkflowSettings({
    this.invoiceFollowUpEnabled = true,
    this.invoiceFollowUpDays = 7,
    this.weeklyReviewEnabled = true,
    this.weeklyReviewDay = 1, // Monday
    this.lowStockAlertEnabled = true,
    this.lowStockThreshold = 10,
  });

  Map<String, dynamic> toJson() => {
    'invoice_follow_up_enabled': invoiceFollowUpEnabled,
    'invoice_follow_up_days': invoiceFollowUpDays,
    'weekly_review_enabled': weeklyReviewEnabled,
    'weekly_review_day': weeklyReviewDay,
    'low_stock_alert_enabled': lowStockAlertEnabled,
    'low_stock_threshold': lowStockThreshold,
  };

  factory WorkflowSettings.fromJson(Map<String, dynamic> json) {
    return WorkflowSettings(
      invoiceFollowUpEnabled:
          json['invoice_follow_up_enabled'] as bool? ?? true,
      invoiceFollowUpDays: json['invoice_follow_up_days'] as int? ?? 7,
      weeklyReviewEnabled: json['weekly_review_enabled'] as bool? ?? true,
      weeklyReviewDay: json['weekly_review_day'] as int? ?? 1,
      lowStockAlertEnabled: json['low_stock_alert_enabled'] as bool? ?? true,
      lowStockThreshold: json['low_stock_threshold'] as int? ?? 10,
    );
  }
}

/// Service for managing automated workflows
class WorkflowService {
  WorkflowService._();
  static final WorkflowService _instance = WorkflowService._();
  static WorkflowService get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;
  final _invoiceService = InvoiceService.instance;
  final _analyticsService = AnalyticsService.instance;

  Timer? _schedulerTimer;
  WorkflowSettings _settings = const WorkflowSettings();

  /// Initialize the workflow scheduler
  void initialize() {
    // Check workflows every hour
    _schedulerTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkScheduledWorkflows(),
    );
    // Also run immediately on init
    _checkScheduledWorkflows();
  }

  /// Stop the workflow scheduler
  void dispose() {
    _schedulerTimer?.cancel();
  }

  /// Load workflow settings
  Future<WorkflowSettings> loadSettings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _settings;

    final response = await _client
        .from('workflow_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      _settings = WorkflowSettings.fromJson(response);
    }
    return _settings;
  }

  /// Save workflow settings
  Future<void> saveSettings(WorkflowSettings settings) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _settings = settings;
    await _client.from('workflow_settings').upsert({
      'user_id': userId,
      ...settings.toJson(),
    });
  }

  /// Get workflow run history
  Future<List<WorkflowRun>> getWorkflowHistory({int limit = 20}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('workflow_runs')
        .select()
        .eq('user_id', userId)
        .order('started_at', ascending: false)
        .limit(limit);

    return (response as List).map((row) => WorkflowRun.fromJson(row)).toList();
  }

  /// Check for scheduled workflows
  Future<void> _checkScheduledWorkflows() async {
    await loadSettings();
    final now = DateTime.now();

    // Check invoice follow-up workflow
    if (_settings.invoiceFollowUpEnabled) {
      await runInvoiceFollowUpWorkflow();
    }

    // Check weekly business review (run on the configured day)
    if (_settings.weeklyReviewEnabled &&
        now.weekday == _settings.weeklyReviewDay) {
      // Only run once per day
      final lastRun = await _getLastWorkflowRun(
        WorkflowType.weeklyBusinessReview,
      );
      if (lastRun == null ||
          lastRun.startedAt.difference(now).inHours.abs() > 20) {
        await runWeeklyBusinessReviewWorkflow();
      }
    }
  }

  /// Get last workflow run of a specific type
  Future<WorkflowRun?> _getLastWorkflowRun(WorkflowType type) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('workflow_runs')
        .select()
        .eq('user_id', userId)
        .eq('workflow_type', type.name)
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return WorkflowRun.fromJson(response);
  }

  /// Save a workflow run
  Future<void> _saveWorkflowRun(WorkflowRun run) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('workflow_runs').insert({
      'user_id': userId,
      ...run.toJson(),
    });
  }

  // ============================================================
  // INVOICE FOLLOW-UP WORKFLOW
  // ============================================================

  /// Run invoice follow-up workflow
  Future<WorkflowRun> runInvoiceFollowUpWorkflow() async {
    final runId = DateTime.now().millisecondsSinceEpoch.toString();
    final run = WorkflowRun(
      id: runId,
      type: WorkflowType.invoiceFollowUp,
      status: WorkflowRunStatus.running,
      startedAt: DateTime.now(),
    );

    try {
      // Get overdue invoices
      final overdueInvoices = await _getOverdueInvoices();

      if (overdueInvoices.isEmpty) {
        final completedRun = WorkflowRun(
          id: runId,
          type: WorkflowType.invoiceFollowUp,
          status: WorkflowRunStatus.skipped,
          startedAt: run.startedAt,
          completedAt: DateTime.now(),
          results: {'message': 'No overdue invoices found'},
        );
        await _saveWorkflowRun(completedRun);
        return completedRun;
      }

      // Generate follow-up actions for each overdue invoice
      final actions = <Map<String, dynamic>>[];
      for (final invoice in overdueInvoices) {
        final daysOverdue = DateTime.now().difference(invoice.dueDate!).inDays;
        actions.add({
          'invoice_id': invoice.id,
          'invoice_number': invoice.invoiceNumber,
          'customer_name': invoice.customerName,
          'amount': invoice.total,
          'days_overdue': daysOverdue,
          'action': _determineFollowUpAction(daysOverdue),
        });
      }

      final completedRun = WorkflowRun(
        id: runId,
        type: WorkflowType.invoiceFollowUp,
        status: WorkflowRunStatus.completed,
        startedAt: run.startedAt,
        completedAt: DateTime.now(),
        results: {
          'overdue_count': overdueInvoices.length,
          'total_outstanding': overdueInvoices.fold<double>(
            0,
            (sum, inv) => sum + inv.total,
          ),
          'actions': actions,
        },
      );

      await _saveWorkflowRun(completedRun);
      return completedRun;
    } catch (e) {
      final failedRun = WorkflowRun(
        id: runId,
        type: WorkflowType.invoiceFollowUp,
        status: WorkflowRunStatus.failed,
        startedAt: run.startedAt,
        completedAt: DateTime.now(),
        error: e.toString(),
      );
      await _saveWorkflowRun(failedRun);
      return failedRun;
    }
  }

  Future<List<InvoiceModel>> _getOverdueInvoices() async {
    final invoices = await _invoiceService.getInvoices();
    final now = DateTime.now();
    return invoices.where((invoice) {
      if (invoice.status == InvoiceStatus.paid) return false;
      if (invoice.dueDate == null) return false;
      return invoice.dueDate!.isBefore(now);
    }).toList();
  }

  String _determineFollowUpAction(int daysOverdue) {
    if (daysOverdue <= 3) {
      return 'Send friendly reminder';
    } else if (daysOverdue <= 7) {
      return 'Send follow-up email';
    } else if (daysOverdue <= 14) {
      return 'Make phone call';
    } else {
      return 'Escalate to collections';
    }
  }

  // ============================================================
  // WEEKLY BUSINESS REVIEW WORKFLOW
  // ============================================================

  /// Run weekly business review workflow
  Future<WorkflowRun> runWeeklyBusinessReviewWorkflow() async {
    final runId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // Gather analytics data
      final revenueTrend = await _analyticsService.getRevenueTrend();
      final topProducts = await _analyticsService.getTopProducts(limit: 5);

      // Calculate week-over-week metrics
      final summary = <String, dynamic>{
        'revenue': {
          'current': revenueTrend.currentPeriodRevenue,
          'previous': revenueTrend.previousPeriodRevenue,
          'change_percent': revenueTrend.changePercent,
          'is_positive': revenueTrend.isPositive,
        },
        'top_products': topProducts
            .map(
              (p) => {
                'name': p.productName,
                'revenue': p.revenue,
                'quantity': p.unitsSold,
              },
            )
            .toList(),
        'insights': _generateWeeklyInsights(revenueTrend),
      };

      final completedRun = WorkflowRun(
        id: runId,
        type: WorkflowType.weeklyBusinessReview,
        status: WorkflowRunStatus.completed,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        results: summary,
      );

      await _saveWorkflowRun(completedRun);
      return completedRun;
    } catch (e) {
      final failedRun = WorkflowRun(
        id: runId,
        type: WorkflowType.weeklyBusinessReview,
        status: WorkflowRunStatus.failed,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        error: e.toString(),
      );
      await _saveWorkflowRun(failedRun);
      return failedRun;
    }
  }

  List<String> _generateWeeklyInsights(RevenueTrend trend) {
    final insights = <String>[];

    if (trend.isPositive) {
      if (trend.changePercent > 20) {
        insights.add(
          '🚀 Excellent week! Revenue up ${trend.changePercent.toStringAsFixed(1)}%',
        );
      } else if (trend.changePercent > 10) {
        insights.add(
          '📈 Great progress! Revenue increased by ${trend.changePercent.toStringAsFixed(1)}%',
        );
      } else {
        insights.add(
          '✅ Steady growth of ${trend.changePercent.toStringAsFixed(1)}%',
        );
      }
    } else {
      if (trend.changePercent.abs() > 20) {
        insights.add(
          '⚠️ Revenue dropped ${trend.changePercent.abs().toStringAsFixed(1)}% - review strategy',
        );
      } else if (trend.changePercent.abs() > 10) {
        insights.add(
          '📉 Revenue down ${trend.changePercent.abs().toStringAsFixed(1)}% - consider promotions',
        );
      } else {
        insights.add(
          '📊 Slight dip of ${trend.changePercent.abs().toStringAsFixed(1)}% - monitor closely',
        );
      }
    }

    return insights;
  }

  // ============================================================
  // MANUAL WORKFLOW TRIGGERS
  // ============================================================

  /// Manually trigger a workflow
  Future<WorkflowRun> triggerWorkflow(WorkflowType type) async {
    switch (type) {
      case WorkflowType.invoiceFollowUp:
        return runInvoiceFollowUpWorkflow();
      case WorkflowType.weeklyBusinessReview:
        return runWeeklyBusinessReviewWorkflow();
      case WorkflowType.lowStockAlert:
        throw UnimplementedError(
          'Low stock alert workflow not yet implemented',
        );
      case WorkflowType.customerFollowUp:
        throw UnimplementedError(
          'Customer follow-up workflow not yet implemented',
        );
    }
  }
}
