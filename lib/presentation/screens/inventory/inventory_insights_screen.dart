import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/services/ai_inventory_service.dart';
import '../../providers/ai_inventory_provider.dart';

/// AI-powered inventory insights screen
class InventoryInsightsScreen extends ConsumerStatefulWidget {
  const InventoryInsightsScreen({super.key});

  @override
  ConsumerState<InventoryInsightsScreen> createState() =>
      _InventoryInsightsScreenState();
}

class _InventoryInsightsScreenState
    extends ConsumerState<InventoryInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(aiInsightsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshAiInventory(ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.warning_amber), text: 'Reorder'),
            Tab(icon: Icon(Icons.tune), text: 'Optimize'),
            Tab(icon: Icon(Icons.slow_motion_video), text: 'Slow Movers'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary Card
          summaryAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) => _buildSummaryCard(context, summary),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_ReorderTab(), _OptimizeTab(), _SlowMoversTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, AiInsightsSummary summary) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    if (!summary.hasAlerts) {
      return Card(
        margin: const EdgeInsets.all(AppConstants.paddingMd),
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All inventory levels look healthy!',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(AppConstants.paddingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'AI Insights Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (summary.criticalReorders > 0)
                  _SummaryChip(
                    label: '${summary.criticalReorders} Critical',
                    color: Colors.red,
                    icon: Icons.error,
                  ),
                if (summary.highPriorityReorders > 0)
                  _SummaryChip(
                    label: '${summary.highPriorityReorders} High Priority',
                    color: Colors.orange,
                    icon: Icons.warning,
                  ),
                if (summary.slowMovingCount > 0)
                  _SummaryChip(
                    label: '${summary.slowMovingCount} Slow Movers',
                    color: Colors.blue,
                    icon: Icons.slow_motion_video,
                  ),
                if (summary.capitalInSlowMovers > 0)
                  _SummaryChip(
                    label:
                        '${currencyFormat.format(summary.capitalInSlowMovers)} tied up',
                    color: Colors.purple,
                    icon: Icons.account_balance_wallet,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REORDER TAB
// ============================================================

class _ReorderTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync = ref.watch(reorderPredictionsProvider);

    return predictionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (predictions) {
        if (predictions.isEmpty) {
          return _EmptyState(
            icon: Icons.inventory_2,
            title: 'No Reorder Alerts',
            subtitle: 'All products have healthy stock levels',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingSm),
          itemCount: predictions.length,
          itemBuilder: (context, index) {
            final prediction = predictions[index];
            return _ReorderCard(prediction: prediction);
          },
        );
      },
    );
  }
}

class _ReorderCard extends StatelessWidget {
  final ReorderPrediction prediction;

  const _ReorderCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d');

    Color urgencyColor;
    switch (prediction.urgency) {
      case UrgencyLevel.critical:
        urgencyColor = Colors.red;
        break;
      case UrgencyLevel.high:
        urgencyColor = Colors.orange;
        break;
      case UrgencyLevel.medium:
        urgencyColor = Colors.amber;
        break;
      case UrgencyLevel.low:
        urgencyColor = Colors.green;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      prediction.product.category.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${prediction.product.stockQuantity} units left',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${prediction.urgency.emoji} ${prediction.urgency.label}',
                    style: TextStyle(
                      color: urgencyColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _InfoColumn(
                    label: 'Stockout',
                    value: prediction.stockoutText,
                    icon: Icons.timer,
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: 'Daily Sales',
                    value:
                        '${prediction.dailySalesVelocity.toStringAsFixed(1)}/day',
                    icon: Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: 'Order Qty',
                    value: '${prediction.suggestedOrderQuantity}',
                    icon: Icons.shopping_cart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 Reorder by ${dateFormat.format(prediction.suggestedReorderDate)} for ${prediction.suggestedOrderQuantity} units',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// OPTIMIZE TAB
// ============================================================

class _OptimizeTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optimizationsAsync = ref.watch(stockOptimizationsProvider);

    return optimizationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (optimizations) {
        // Filter to only show non-optimal items
        final needsAction = optimizations
            .where((o) => o.recommendation != StockRecommendation.optimal)
            .toList();

        if (needsAction.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle,
            title: 'All Stock Levels Optimal',
            subtitle: 'Your inventory is well balanced',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingSm),
          itemCount: needsAction.length,
          itemBuilder: (context, index) {
            final opt = needsAction[index];
            return _OptimizeCard(optimization: opt);
          },
        );
      },
    );
  }
}

class _OptimizeCard extends StatelessWidget {
  final StockOptimization optimization;

  const _OptimizeCard({required this.optimization});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncrease = optimization.adjustmentNeeded > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      optimization.product.category.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        optimization.product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        optimization.recommendation.label,
                        style: TextStyle(
                          color: isIncrease ? Colors.orange : Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  optimization.recommendation.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StockBar(
                    label: 'Current',
                    value: optimization.currentStock,
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward, size: 16, color: colorScheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: _StockBar(
                    label: 'Optimal',
                    value: optimization.optimalStock,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Adjustment: ${isIncrease ? '+' : ''}${optimization.adjustmentNeeded} units',
              style: TextStyle(
                color: isIncrease ? Colors.orange : Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StockBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SLOW MOVERS TAB
// ============================================================

class _SlowMoversTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slowMoversAsync = ref.watch(slowMovingInventoryProvider);

    return slowMoversAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (slowMovers) {
        if (slowMovers.isEmpty) {
          return _EmptyState(
            icon: Icons.speed,
            title: 'No Slow Moving Items',
            subtitle: 'All products are selling at a healthy rate',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingSm),
          itemCount: slowMovers.length,
          itemBuilder: (context, index) {
            final item = slowMovers[index];
            return _SlowMoverCard(item: item);
          },
        );
      },
    );
  }
}

class _SlowMoverCard extends StatelessWidget {
  final SlowMovingProduct item;

  const _SlowMoverCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      item.product.category.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${item.product.stockQuantity} units in stock',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.daysSinceLastSale}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'days idle',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _InfoColumn(
                    label: 'Last Sale',
                    value: item.lastSaleDate != null
                        ? dateFormat.format(item.lastSaleDate!)
                        : 'Never',
                    icon: Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: 'Capital Tied',
                    value: currencyFormat.format(item.capitalTiedUp),
                    icon: Icons.account_balance_wallet,
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: 'Turnover',
                    value: '${(item.turnoverRate * 100).toStringAsFixed(0)}%',
                    icon: Icons.sync,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 ${item.recommendation}',
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SHARED WIDGETS
// ============================================================

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoColumn({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
