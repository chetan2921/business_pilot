import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/agent_recommendation_model.dart';
import '../../providers/agent_provider.dart';

/// Agent Insights Dashboard - Main screen for AI recommendations
class AgentInsightsScreen extends ConsumerWidget {
  const AgentInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final pendingAsync = ref.watch(pendingRecommendationsProvider);
    final statsAsync = ref.watch(agentStatsProvider);
    final actionsState = ref.watch(agentActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          IconButton(
            icon: actionsState.isRunning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: actionsState.isRunning
                ? null
                : () => ref.read(agentActionsProvider.notifier).runAllAgents(),
            tooltip: 'Run Analysis',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingRecommendationsProvider);
          ref.invalidate(agentStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats summary
              statsAsync.when(
                data: (stats) => _StatsRow(stats: stats),
                loading: () => const _StatsRowSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Quick actions
              _QuickActionsCard(
                onCashFlowTap: () => context.push('/agent/cash-flow'),
                onRefreshTap: actionsState.isRunning
                    ? null
                    : () => ref
                          .read(agentActionsProvider.notifier)
                          .runAllAgents(),
              ),
              const SizedBox(height: 20),

              // Recommendations list
              Text(
                'Recommendations',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              pendingAsync.when(
                data: (recommendations) {
                  if (recommendations.isEmpty) {
                    return _EmptyRecommendations(
                      onRefresh: () => ref
                          .read(agentActionsProvider.notifier)
                          .runAllAgents(),
                    );
                  }

                  // Group by priority
                  final critical = recommendations
                      .where(
                        (r) => r.priority == RecommendationPriority.critical,
                      )
                      .toList();
                  final high = recommendations
                      .where((r) => r.priority == RecommendationPriority.high)
                      .toList();
                  final others = recommendations
                      .where(
                        (r) =>
                            r.priority != RecommendationPriority.critical &&
                            r.priority != RecommendationPriority.high,
                      )
                      .toList();

                  return Column(
                    children: [
                      if (critical.isNotEmpty) ...[
                        _PrioritySection(
                          priority: RecommendationPriority.critical,
                          recommendations: critical,
                          colorScheme: colorScheme,
                          ref: ref,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (high.isNotEmpty) ...[
                        _PrioritySection(
                          priority: RecommendationPriority.high,
                          recommendations: high,
                          colorScheme: colorScheme,
                          ref: ref,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (others.isNotEmpty)
                        _PrioritySection(
                          priority: RecommendationPriority.medium,
                          recommendations: others,
                          colorScheme: colorScheme,
                          ref: ref,
                          showPriorityLabel: false,
                        ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('Error: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final criticalCount = stats['critical_count'] as int? ?? 0;
    final highCount = stats['high_count'] as int? ?? 0;
    final totalPending = stats['total_pending'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Critical',
            value: '$criticalCount',
            icon: Icons.warning_rounded,
            colorScheme: colorScheme,
            isUrgent: criticalCount > 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'High Priority',
            value: '$highCount',
            icon: Icons.priority_high,
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: '$totalPending',
            icon: Icons.lightbulb_outline,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;
  final bool isUrgent;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isUrgent ? colorScheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: isUrgent ? colorScheme.error : colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isUrgent ? colorScheme.error : colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (_) => Expanded(
          child: Card(
            child: Container(height: 80, padding: const EdgeInsets.all(12)),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final VoidCallback onCashFlowTap;
  final VoidCallback? onRefreshTap;

  const _QuickActionsCard({required this.onCashFlowTap, this.onRefreshTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCashFlowTap,
                    icon: const Icon(Icons.account_balance_wallet, size: 18),
                    label: const Text('Cash Flow'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRefreshTap,
                    icon: const Icon(Icons.psychology, size: 18),
                    label: const Text('Run Analysis'),
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

class _PrioritySection extends StatelessWidget {
  final RecommendationPriority priority;
  final List<AgentRecommendationModel> recommendations;
  final ColorScheme colorScheme;
  final WidgetRef ref;
  final bool showPriorityLabel;

  const _PrioritySection({
    required this.priority,
    required this.recommendations,
    required this.colorScheme,
    required this.ref,
    this.showPriorityLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPriorityLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: priority == RecommendationPriority.critical
                        ? colorScheme.error
                        : colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  priority.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: priority == RecommendationPriority.critical
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ...recommendations.map(
          (rec) => _RecommendationCard(
            recommendation: rec,
            colorScheme: colorScheme,
            ref: ref,
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final AgentRecommendationModel recommendation;
  final ColorScheme colorScheme;
  final WidgetRef ref;

  const _RecommendationCard({
    required this.recommendation,
    required this.colorScheme,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical =
        recommendation.priority == RecommendationPriority.critical;

    return Card(
      color: isCritical
          ? colorScheme.errorContainer.withValues(alpha: 0.3)
          : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    recommendation.agentType.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    recommendation.timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recommendation.description,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (recommendation.suggestedAction != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '💡 ${recommendation.suggestedAction}',
                    style: TextStyle(fontSize: 12, color: colorScheme.primary),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _dismiss(context),
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _accept(context),
                    child: const Text('Take Action'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    final route = recommendation.actionData['route'] as String?;
    if (route != null) {
      context.push(route);
    }
  }

  void _accept(BuildContext context) {
    ref
        .read(agentActionsProvider.notifier)
        .acceptRecommendation(recommendation.id);

    // Navigate if there's an action route
    final route = recommendation.actionData['route'] as String?;
    if (route != null) {
      context.push(route);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Action recorded')));
  }

  void _dismiss(BuildContext context) {
    ref
        .read(agentActionsProvider.notifier)
        .dismissRecommendation(recommendation.id);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recommendation dismissed')));
  }
}

class _EmptyRecommendations extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyRecommendations({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'All Clear!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No pending recommendations.\nYour business is running smoothly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Run Analysis'),
            ),
          ],
        ),
      ),
    );
  }
}
