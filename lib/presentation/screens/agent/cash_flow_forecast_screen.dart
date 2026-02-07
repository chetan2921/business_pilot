import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/cash_flow_prediction_model.dart';
import '../../providers/agent_provider.dart';

/// Cash Flow Forecast Screen - Detailed 3-week cash flow projection
class CashFlowForecastScreen extends ConsumerWidget {
  const CashFlowForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final forecastAsync = ref.watch(cashFlowForecastProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Flow Forecast'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(cashFlowForecastProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: forecastAsync.when(
        data: (forecast) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(cashFlowForecastProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.paddingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Health summary card
                _HealthSummaryCard(
                  forecast: forecast,
                  currencyFormat: currencyFormat,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),

                // Weekly projections
                Text(
                  '3-Week Forecast',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _WeeklyProjectionsChart(
                  projections: forecast.weeklyProjections,
                  currencyFormat: currencyFormat,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),

                // Projection details
                ...forecast.weeklyProjections.asMap().entries.map((entry) {
                  return _ProjectionCard(
                    weekNumber: entry.key + 1,
                    projection: entry.value,
                    currencyFormat: currencyFormat,
                    colorScheme: colorScheme,
                  );
                }),

                // Alerts section
                if (forecast.alerts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Alerts & Recommendations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...forecast.alerts.map(
                    (alert) => _AlertCard(
                      alert: alert,
                      currencyFormat: currencyFormat,
                      colorScheme: colorScheme,
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('Error loading forecast: $error'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(cashFlowForecastProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthSummaryCard extends StatelessWidget {
  final CashFlowForecast forecast;
  final NumberFormat currencyFormat;
  final ColorScheme colorScheme;

  const _HealthSummaryCard({
    required this.forecast,
    required this.currencyFormat,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isHealthy = !forecast.hasShortfall;

    return Card(
      color: isHealthy
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.warning_rounded,
                  color: isHealthy ? colorScheme.primary : colorScheme.error,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forecast.healthRating,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isHealthy
                              ? colorScheme.primary
                              : colorScheme.error,
                        ),
                      ),
                      Text(
                        isHealthy
                            ? 'Cash flow looks healthy for the next 3 weeks'
                            : 'Action needed to avoid cash shortfall',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'Current Balance',
                    value: currencyFormat.format(forecast.currentBalance),
                    colorScheme: colorScheme,
                  ),
                ),
                Expanded(
                  child: _SummaryTile(
                    label: 'Lowest Projected',
                    value: currencyFormat.format(
                      forecast.lowestProjectedBalance,
                    ),
                    colorScheme: colorScheme,
                    isNegative: forecast.lowestProjectedBalance < 0,
                  ),
                ),
              ],
            ),
            if (forecast.hasShortfall && forecast.daysUntilShortfall != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Shortfall expected in ${forecast.daysUntilShortfall} days',
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final bool isNegative;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.colorScheme,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isNegative ? colorScheme.error : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _WeeklyProjectionsChart extends StatelessWidget {
  final List<CashFlowProjection> projections;
  final NumberFormat currencyFormat;
  final ColorScheme colorScheme;

  const _WeeklyProjectionsChart({
    required this.projections,
    required this.currencyFormat,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (projections.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No projection data available',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    // Find max value for scaling
    final maxBalance = projections
        .map((p) => p.projectedBalance.abs())
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Projected Balance',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: projections.asMap().entries.map((entry) {
                  final projection = entry.value;
                  final isNegative = projection.projectedBalance < 0;
                  final barHeight = maxBalance > 0
                      ? (projection.projectedBalance.abs() / maxBalance * 80)
                            .clamp(10.0, 80.0)
                      : 10.0;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(projection.projectedBalance),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isNegative
                                ? colorScheme.error
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isNegative
                                ? colorScheme.error
                                : colorScheme.primary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Week ${entry.key + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  final int weekNumber;
  final CashFlowProjection projection;
  final NumberFormat currencyFormat;
  final ColorScheme colorScheme;

  const _ProjectionCard({
    required this.weekNumber,
    required this.projection,
    required this.currencyFormat,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$weekNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week $weekNumber',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        dateFormat.format(projection.projectionDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    projection.confidencePercentage,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _FlowTile(
                    label: 'Inflow',
                    value: currencyFormat.format(projection.projectedInflow),
                    icon: Icons.arrow_downward,
                    colorScheme: colorScheme,
                    isPositive: true,
                  ),
                ),
                Expanded(
                  child: _FlowTile(
                    label: 'Outflow',
                    value: currencyFormat.format(projection.projectedOutflow),
                    icon: Icons.arrow_upward,
                    colorScheme: colorScheme,
                    isPositive: false,
                  ),
                ),
                Expanded(
                  child: _FlowTile(
                    label: 'Balance',
                    value: currencyFormat.format(projection.projectedBalance),
                    icon: Icons.account_balance_wallet,
                    colorScheme: colorScheme,
                    isPositive: projection.projectedBalance >= 0,
                    isBold: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;
  final bool isPositive;
  final bool isBold;

  const _FlowTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
    required this.isPositive,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: isPositive ? colorScheme.primary : colorScheme.error,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold
                ? (isPositive ? colorScheme.onSurface : colorScheme.error)
                : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final CashFlowAlert alert;
  final NumberFormat currencyFormat;
  final ColorScheme colorScheme;

  const _AlertCard({
    required this.alert,
    required this.currencyFormat,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(alert.type.icon, style: const TextStyle(fontSize: 24)),
        title: Text(
          alert.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.description),
            if (alert.suggestedAction != null) ...[
              const SizedBox(height: 4),
              Text(
                '💡 ${alert.suggestedAction}',
                style: TextStyle(color: colorScheme.primary, fontSize: 12),
              ),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
