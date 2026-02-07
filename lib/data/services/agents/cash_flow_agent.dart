import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../models/agent_recommendation_model.dart';
import '../../models/cash_flow_prediction_model.dart';
import '../../models/invoice_model.dart';
import '../expense_service.dart';
import '../invoice_service.dart';

/// Cash Flow Agent - Monitors and predicts cash flow issues
/// Generates recommendations to prevent cash shortages
class CashFlowAgent {
  CashFlowAgent._();
  static final CashFlowAgent _instance = CashFlowAgent._();
  static CashFlowAgent get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;
  final _invoiceService = InvoiceService.instance;
  final _expenseService = ExpenseService.instance;

  /// Run the cash flow analysis and generate recommendations
  Future<List<AgentRecommendationModel>> analyze() async {
    final recommendations = <AgentRecommendationModel>[];
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return recommendations;

    try {
      // Get financial data
      final forecast = await generateForecast();
      final overdueInvoices = await _getOverdueInvoices();
      final upcomingExpenses = await _getUpcomingRecurringExpenses();

      // Check for cash shortfall
      if (forecast.hasShortfall && forecast.daysUntilShortfall != null) {
        recommendations.add(
          AgentRecommendationModel(
            id: '',
            userId: userId,
            agentType: AgentType.cashFlow,
            priority: forecast.daysUntilShortfall! <= 7
                ? RecommendationPriority.critical
                : RecommendationPriority.high,
            title: 'Cash Shortfall Predicted',
            description:
                'Your cash balance is projected to go negative in ${forecast.daysUntilShortfall} days. '
                'Expected shortfall: ₹${forecast.lowestProjectedBalance.abs().toStringAsFixed(0)}',
            suggestedAction: 'Review and prioritize receivables collection',
            actionType: ActionType.navigate,
            actionData: {'route': '/agent/cash-flow'},
            data: {
              'shortfall_date': forecast.shortfallDate?.toIso8601String(),
              'shortfall_amount': forecast.lowestProjectedBalance.abs(),
              'days_until': forecast.daysUntilShortfall,
            },
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          ),
        );
      }

      // Check for low balance warning
      if (!forecast.hasShortfall &&
          forecast.lowestProjectedBalance < forecast.currentBalance * 0.3) {
        recommendations.add(
          AgentRecommendationModel(
            id: '',
            userId: userId,
            agentType: AgentType.cashFlow,
            priority: RecommendationPriority.medium,
            title: 'Low Cash Balance Warning',
            description:
                'Your projected balance may drop to ₹${forecast.lowestProjectedBalance.toStringAsFixed(0)}, '
                'which is ${((forecast.lowestProjectedBalance / forecast.currentBalance) * 100).toStringAsFixed(0)}% of current balance.',
            suggestedAction: 'Consider delaying non-essential expenses',
            actionType: ActionType.navigate,
            actionData: {'route': '/agent/cash-flow'},
            expiresAt: DateTime.now().add(const Duration(days: 14)),
          ),
        );
      }

      // Check for overdue invoices
      if (overdueInvoices.isNotEmpty) {
        final totalOverdue = overdueInvoices.fold<double>(
          0,
          (sum, inv) => sum + inv.total,
        );
        final oldestDays = overdueInvoices
            .map((inv) => DateTime.now().difference(inv.dueDate!).inDays)
            .reduce((a, b) => a > b ? a : b);

        recommendations.add(
          AgentRecommendationModel(
            id: '',
            userId: userId,
            agentType: AgentType.cashFlow,
            priority: oldestDays > 30
                ? RecommendationPriority.high
                : RecommendationPriority.medium,
            title: '${overdueInvoices.length} Overdue Invoices',
            description:
                'You have ₹${totalOverdue.toStringAsFixed(0)} in overdue receivables. '
                'Oldest invoice is $oldestDays days overdue.',
            suggestedAction: 'Send payment reminders to customers',
            actionType: ActionType.navigate,
            actionData: {'route': '/invoices', 'filter': 'overdue'},
            data: {
              'count': overdueInvoices.length,
              'total_amount': totalOverdue,
              'oldest_days': oldestDays,
            },
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          ),
        );
      }

      // Check for large upcoming expenses
      if (upcomingExpenses.isNotEmpty) {
        final totalUpcoming = upcomingExpenses.fold<double>(
          0,
          (sum, exp) => sum + (exp['amount'] as double),
        );

        if (totalUpcoming > forecast.currentBalance * 0.5) {
          recommendations.add(
            AgentRecommendationModel(
              id: '',
              userId: userId,
              agentType: AgentType.cashFlow,
              priority: RecommendationPriority.medium,
              title: 'Large Expenses Coming Up',
              description:
                  '₹${totalUpcoming.toStringAsFixed(0)} in expenses expected in the next 2 weeks. '
                  'This is ${((totalUpcoming / forecast.currentBalance) * 100).toStringAsFixed(0)}% of your current balance.',
              suggestedAction: 'Review and prioritize upcoming expenses',
              actionType: ActionType.navigate,
              actionData: {'route': '/expenses'},
              expiresAt: DateTime.now().add(const Duration(days: 14)),
            ),
          );
        }
      }

      return recommendations;
    } catch (e) {
      // Log error but don't throw - agent should be resilient
      return recommendations;
    }
  }

  /// Generate a 3-week cash flow forecast
  Future<CashFlowForecast> generateForecast() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return CashFlowForecast(
        weeklyProjections: [],
        currentBalance: 0,
        lowestProjectedBalance: 0,
      );
    }

    // Get current balance from recent transactions
    final currentBalance = await _estimateCurrentBalance();

    // Get expected inflows (unpaid invoices - sent or draft)
    final sentInvoices = await _invoiceService.getInvoices(
      status: InvoiceStatus.sent,
    );

    // Get expected outflows (recurring expenses pattern)
    final recentExpenses = await _expenseService.getExpenses(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );

    // Calculate average weekly expense
    final avgWeeklyExpense =
        recentExpenses.fold<double>(0, (sum, exp) => sum + exp.amount) /
        4.3; // ~4.3 weeks in a month

    // Generate weekly projections
    final projections = <CashFlowProjection>[];
    double runningBalance = currentBalance;
    double lowestBalance = currentBalance;
    DateTime? shortfallDate;

    for (int week = 1; week <= 3; week++) {
      final weekStart = DateTime.now().add(Duration(days: (week - 1) * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));

      // Calculate expected inflow for this week
      final weekInflow = sentInvoices
          .where(
            (inv) =>
                inv.dueDate != null &&
                inv.dueDate!.isAfter(weekStart) &&
                inv.dueDate!.isBefore(weekEnd),
          )
          .fold<double>(0, (sum, inv) => sum + inv.total);

      // Estimate outflow based on historical average
      final weekOutflow = avgWeeklyExpense;

      runningBalance = runningBalance + weekInflow - weekOutflow;

      if (runningBalance < lowestBalance) {
        lowestBalance = runningBalance;
      }

      if (runningBalance < 0 && shortfallDate == null) {
        shortfallDate = weekStart;
      }

      projections.add(
        CashFlowProjection(
          id: 'projection_week_$week',
          userId: userId,
          projectionDate: weekStart,
          projectedInflow: weekInflow,
          projectedOutflow: weekOutflow,
          projectedBalance: runningBalance,
          confidenceScore: 0.8 - (week * 0.1), // Confidence decreases over time
        ),
      );
    }

    // Generate alerts
    final alerts = <CashFlowAlert>[];
    if (shortfallDate != null) {
      alerts.add(
        CashFlowAlert(
          title: 'Cash Shortfall Alert',
          description:
              'Projected negative balance starting ${_formatDate(shortfallDate)}',
          type: CashFlowAlertType.shortfall,
          impactAmount: lowestBalance.abs(),
          suggestedAction: 'Accelerate receivables collection',
        ),
      );
    }

    return CashFlowForecast(
      weeklyProjections: projections,
      currentBalance: currentBalance,
      lowestProjectedBalance: lowestBalance,
      shortfallDate: shortfallDate,
      alerts: alerts,
    );
  }

  /// Save projections to database
  Future<void> saveProjections(List<CashFlowProjection> projections) async {
    for (final projection in projections) {
      await _client
          .from('cash_flow_projections')
          .upsert(
            projection.toSupabase(),
            onConflict: 'user_id,projection_date',
          );
    }
  }

  Future<double> _estimateCurrentBalance() async {
    // Get last 30 days of paid invoices and expenses
    final last30Days = DateTime.now().subtract(const Duration(days: 30));

    final paidInvoices = await _invoiceService.getInvoices(
      status: InvoiceStatus.paid,
      startDate: last30Days,
    );
    final expenses = await _expenseService.getExpenses(startDate: last30Days);

    final totalIncome = paidInvoices.fold<double>(
      0,
      (sum, inv) => sum + inv.total,
    );
    final totalExpenses = expenses.fold<double>(
      0,
      (sum, exp) => sum + exp.amount,
    );

    // This is a rough estimate; ideally would connect to actual bank balance
    return totalIncome - totalExpenses;
  }

  Future<List<InvoiceModel>> _getOverdueInvoices() async {
    final invoices = await _invoiceService.getInvoices(
      status: InvoiceStatus.overdue,
    );

    return invoices;
  }

  Future<List<Map<String, dynamic>>> _getUpcomingRecurringExpenses() async {
    // Analyze expense patterns to predict upcoming expenses
    final last60Days = DateTime.now().subtract(const Duration(days: 60));
    final expenses = await _expenseService.getExpenses(startDate: last60Days);

    // Group by category and identify recurring patterns
    final categoryTotals = <String, List<double>>{};
    for (final expense in expenses) {
      final key = expense.category.name;
      categoryTotals[key] ??= [];
      categoryTotals[key]!.add(expense.amount);
    }

    // Predict upcoming based on averages
    final upcoming = <Map<String, dynamic>>[];
    for (final entry in categoryTotals.entries) {
      if (entry.value.length >= 2) {
        // At least 2 occurrences suggests recurring
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        upcoming.add({'category': entry.key, 'amount': avg, 'confidence': 0.7});
      }
    }

    return upcoming;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
