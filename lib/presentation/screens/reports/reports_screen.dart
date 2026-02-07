import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/expense_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/invoice_provider.dart';

/// Date range filter for reports
enum DateRange { thisMonth, last30Days, last90Days, thisYear, all }

extension DateRangeExt on DateRange {
  String get label {
    switch (this) {
      case DateRange.thisMonth:
        return 'This Month';
      case DateRange.last30Days:
        return 'Last 30 Days';
      case DateRange.last90Days:
        return 'Last 90 Days';
      case DateRange.thisYear:
        return 'This Year';
      case DateRange.all:
        return 'All Time';
    }
  }

  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case DateRange.thisMonth:
        return DateTime(now.year, now.month, 1);
      case DateRange.last30Days:
        return now.subtract(const Duration(days: 30));
      case DateRange.last90Days:
        return now.subtract(const Duration(days: 90));
      case DateRange.thisYear:
        return DateTime(now.year, 1, 1);
      case DateRange.all:
        return DateTime(2000);
    }
  }
}

final dateRangeProvider = StateProvider<DateRange>(
  (ref) => DateRange.thisMonth,
);

/// Reports screen with expense and income analytics
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(dateRangeProvider);
    final expensesAsync = ref.watch(expenseNotifierProvider);
    final invoicesAsync = ref.watch(invoiceNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Filter Chips
              _buildDateFilterChips(context, ref, dateRange, colorScheme),
              const SizedBox(height: 24),

              // Expense Summary Card
              _buildSectionTitle(
                context,
                'Expense Overview',
                Icons.trending_down,
                Colors.red,
              ),
              const SizedBox(height: 12),
              expensesAsync.when(
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard(message: 'Error: $e'),
                data: (expenses) {
                  final filtered = expenses
                      .where((e) => e.expenseDate.isAfter(dateRange.startDate))
                      .toList();
                  final total = filtered.fold<double>(
                    0,
                    (sum, e) => sum + e.amount,
                  );
                  final byCategory = _groupByCategory(filtered);

                  if (filtered.isEmpty) {
                    return _EmptyCard(
                      icon: Icons.receipt_long_outlined,
                      message: 'No expenses in this period',
                    );
                  }

                  return Column(
                    children: [
                      _StatCard(
                        title: 'Total Expenses',
                        value: currencyFormat.format(total),
                        subtitle: '${filtered.length} transactions',
                        icon: Icons.arrow_downward,
                        iconColor: Colors.red,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A5A)],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (byCategory.isNotEmpty)
                        _ExpensePieChartCard(data: byCategory, total: total),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Income Summary
              _buildSectionTitle(
                context,
                'Income Overview',
                Icons.trending_up,
                Colors.green,
              ),
              const SizedBox(height: 12),
              invoicesAsync.when(
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard(message: 'Error: $e'),
                data: (invoices) {
                  final filtered = invoices
                      .where((i) => i.issueDate.isAfter(dateRange.startDate))
                      .toList();
                  final totalInvoiced = filtered.fold<double>(
                    0,
                    (sum, i) => sum + i.total,
                  );
                  final paidInvoices = filtered.where(
                    (i) => i.status == InvoiceStatus.paid,
                  );
                  final totalPaid = paidInvoices.fold<double>(
                    0,
                    (sum, i) => sum + i.total,
                  );
                  final pending = totalInvoiced - totalPaid;

                  if (filtered.isEmpty) {
                    return _EmptyCard(
                      icon: Icons.receipt_outlined,
                      message: 'No invoices in this period',
                    );
                  }

                  return Column(
                    children: [
                      // Income Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStatCard(
                              title: 'Invoiced',
                              value: currencyFormat.format(totalInvoiced),
                              icon: Icons.receipt_long,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStatCard(
                              title: 'Received',
                              value: currencyFormat.format(totalPaid),
                              icon: Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _MiniStatCard(
                        title: 'Pending Payment',
                        value: currencyFormat.format(pending),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      if (filtered.isNotEmpty)
                        _InvoiceStatusCard(invoices: filtered),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterChips(
    BuildContext context,
    WidgetRef ref,
    DateRange selected,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DateRange.values.map((range) {
          final isSelected = range == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(range.label),
              selected: isSelected,
              onSelected: (_) =>
                  ref.read(dateRangeProvider.notifier).state = range,
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Map<ExpenseCategory, double> _groupByCategory(List<ExpenseModel> expenses) {
    final map = <ExpenseCategory, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }
}

// Premium Stat Card with gradient
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Gradient gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Mini stat card for income section
class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Improved Pie Chart Card
class _ExpensePieChartCard extends StatelessWidget {
  final Map<ExpenseCategory, double> data;
  final double total;

  const _ExpensePieChartCard({required this.data, required this.total});

  static const _colors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEF4444), // Red
    Color(0xFF14B8A6), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expenses by Category',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          // Pie Chart
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 45,
                sections: entries.asMap().entries.map((e) {
                  final idx = e.key;
                  final amount = e.value.value;
                  final percent = (amount / total * 100);
                  return PieChartSectionData(
                    value: amount,
                    title: '${percent.toStringAsFixed(0)}%',
                    color: _colors[idx % _colors.length],
                    radius: 45,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    titlePositionPercentageOffset: 0.6,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          ...entries.asMap().entries.map((e) {
            final idx = e.key;
            final category = e.value.key;
            final amount = e.value.value;
            final percent = (amount / total * 100);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _colors[idx % _colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    currencyFormat.format(amount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${percent.toStringAsFixed(0)}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Invoice Status Card with horizontal bars
class _InvoiceStatusCard extends StatelessWidget {
  final List<InvoiceModel> invoices;

  const _InvoiceStatusCard({required this.invoices});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = invoices.length;
    final paidCount = invoices
        .where((i) => i.status == InvoiceStatus.paid)
        .length;
    final pendingCount = invoices
        .where(
          (i) =>
              i.status == InvoiceStatus.sent ||
              i.status == InvoiceStatus.viewed ||
              i.status == InvoiceStatus.draft,
        )
        .length;
    final overdueCount = invoices
        .where((i) => i.status == InvoiceStatus.overdue)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice Status',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _StatusBar(
            label: 'Paid',
            count: paidCount,
            total: total,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _StatusBar(
            label: 'Pending',
            count: pendingCount,
            total: total,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _StatusBar(
            label: 'Overdue',
            count: overdueCount,
            total: total,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
            ),
            Text(
              '$count invoices',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
