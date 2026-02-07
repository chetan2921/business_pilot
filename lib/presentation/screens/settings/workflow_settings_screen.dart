import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/services/workflow_service.dart';
import '../../providers/workflow_provider.dart';

/// Workflow Settings Screen
class WorkflowSettingsScreen extends ConsumerWidget {
  const WorkflowSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowState = ref.watch(workflowProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation Settings'),
        actions: [
          if (workflowState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(workflowProvider.notifier).refresh(),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Workflows section
          Text(
            'Automated Workflows',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure automated tasks that run on schedule',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          // Invoice Follow-up Workflow
          _WorkflowCard(
            title: 'Invoice Follow-up',
            description:
                'Automatically remind customers about overdue invoices',
            icon: Icons.receipt_long,
            enabled: workflowState.settings.invoiceFollowUpEnabled,
            onToggle: (enabled) {
              ref
                  .read(workflowProvider.notifier)
                  .toggleWorkflow(WorkflowType.invoiceFollowUp, enabled);
            },
            onRunNow: () {
              ref
                  .read(workflowProvider.notifier)
                  .runWorkflow(WorkflowType.invoiceFollowUp);
            },
            settings: [
              _SettingRow(
                label: 'Days before reminder',
                value: '${workflowState.settings.invoiceFollowUpDays} days',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekly Business Review Workflow
          _WorkflowCard(
            title: 'Weekly Business Review',
            description: 'Generate weekly summary of business performance',
            icon: Icons.analytics_outlined,
            enabled: workflowState.settings.weeklyReviewEnabled,
            onToggle: (enabled) {
              ref
                  .read(workflowProvider.notifier)
                  .toggleWorkflow(WorkflowType.weeklyBusinessReview, enabled);
            },
            onRunNow: () {
              ref
                  .read(workflowProvider.notifier)
                  .runWorkflow(WorkflowType.weeklyBusinessReview);
            },
            settings: [
              _SettingRow(
                label: 'Review day',
                value: _getDayName(workflowState.settings.weeklyReviewDay),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Low Stock Alert Workflow
          _WorkflowCard(
            title: 'Low Stock Alerts',
            description: 'Get notified when inventory runs low',
            icon: Icons.inventory_2_outlined,
            enabled: workflowState.settings.lowStockAlertEnabled,
            onToggle: (enabled) {
              ref
                  .read(workflowProvider.notifier)
                  .toggleWorkflow(WorkflowType.lowStockAlert, enabled);
            },
            settings: [
              _SettingRow(
                label: 'Alert threshold',
                value: '${workflowState.settings.lowStockThreshold} units',
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Recent Runs section
          Text(
            'Recent Activity',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (workflowState.recentRuns.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: colorScheme.outline),
                  const SizedBox(height: 8),
                  Text(
                    'No workflow runs yet',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            ...workflowState.recentRuns
                .take(10)
                .map((run) => _WorkflowRunCard(run: run)),
        ],
      ),
    );
  }

  String _getDayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[day - 1];
  }
}

// ============================================================
// WORKFLOW CARD
// ============================================================

class _WorkflowCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool enabled;
  final Function(bool) onToggle;
  final VoidCallback? onRunNow;
  final List<_SettingRow> settings;

  const _WorkflowCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.enabled,
    required this.onToggle,
    this.onRunNow,
    this.settings = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: enabled
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: enabled ? colorScheme.primary : colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(value: enabled, onChanged: onToggle),
              ],
            ),
            if (settings.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              ...settings,
            ],
            if (onRunNow != null && enabled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRunNow,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Run Now'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SETTING ROW
// ============================================================

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================
// WORKFLOW RUN CARD
// ============================================================

class _WorkflowRunCard extends StatelessWidget {
  final WorkflowRun run;

  const _WorkflowRunCard({required this.run});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getStatusIcon(colorScheme),
        title: Text(_getWorkflowName(run.type)),
        subtitle: Text(
          DateFormat('MMM d, y • h:mm a').format(run.startedAt),
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        trailing: _getStatusBadge(colorScheme),
      ),
    );
  }

  Widget _getStatusIcon(ColorScheme colorScheme) {
    IconData icon;
    Color color;

    switch (run.status) {
      case WorkflowRunStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
      case WorkflowRunStatus.failed:
        icon = Icons.error;
        color = colorScheme.error;
      case WorkflowRunStatus.running:
        icon = Icons.sync;
        color = colorScheme.primary;
      case WorkflowRunStatus.skipped:
        icon = Icons.skip_next;
        color = colorScheme.outline;
      case WorkflowRunStatus.pending:
        icon = Icons.schedule;
        color = colorScheme.tertiary;
    }

    return Icon(icon, color: color);
  }

  Widget _getStatusBadge(ColorScheme colorScheme) {
    String label;
    Color bgColor;
    Color textColor;

    switch (run.status) {
      case WorkflowRunStatus.completed:
        label = 'Done';
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
      case WorkflowRunStatus.failed:
        label = 'Failed';
        bgColor = colorScheme.errorContainer;
        textColor = colorScheme.error;
      case WorkflowRunStatus.running:
        label = 'Running';
        bgColor = colorScheme.primaryContainer;
        textColor = colorScheme.primary;
      case WorkflowRunStatus.skipped:
        label = 'Skipped';
        bgColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
      case WorkflowRunStatus.pending:
        label = 'Pending';
        bgColor = colorScheme.tertiaryContainer;
        textColor = colorScheme.tertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  String _getWorkflowName(WorkflowType type) {
    switch (type) {
      case WorkflowType.invoiceFollowUp:
        return 'Invoice Follow-up';
      case WorkflowType.weeklyBusinessReview:
        return 'Weekly Business Review';
      case WorkflowType.lowStockAlert:
        return 'Low Stock Alert';
      case WorkflowType.customerFollowUp:
        return 'Customer Follow-up';
    }
  }
}
