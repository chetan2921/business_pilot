import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/expenses/expense_card.dart';

/// Expenses list screen with filtering
class ExpensesListScreen extends ConsumerStatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  ConsumerState<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends ConsumerState<ExpensesListScreen> {
  ExpenseCategory? _selectedCategory;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters
          if (_selectedCategory != null || _dateRange != null)
            _buildActiveFilters(context),

          // Expenses list
          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text('Error loading expenses'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(expenseNotifierProvider.notifier)
                          .loadExpenses(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return ExpenseEmptyState(
                    onAddExpense: () => context.push('/add-expense'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(expenseNotifierProvider.notifier)
                        .loadExpenses();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingMd),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ExpenseCard(
                          expense: expense,
                          onTap: () {
                            // TODO: Navigate to expense detail
                          },
                          onDelete: () => _confirmDelete(expense),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-expense'),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildActiveFilters(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd MMM');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMd,
        vertical: AppConstants.paddingSm,
      ),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (_selectedCategory != null)
                  Chip(
                    label: Text(_selectedCategory!.displayName),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _selectedCategory = null);
                      _applyFilters();
                    },
                  ),
                if (_dateRange != null)
                  Chip(
                    label: Text(
                      '${dateFormat.format(_dateRange!.start)} - ${dateFormat.format(_dateRange!.end)}',
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _dateRange = null);
                      _applyFilters();
                    },
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _dateRange = null;
              });
              _applyFilters();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _FilterSheet(
          selectedCategory: _selectedCategory,
          dateRange: _dateRange,
          onApply: (category, dateRange) {
            setState(() {
              _selectedCategory = category;
              _dateRange = dateRange;
            });
            _applyFilters();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _applyFilters() {
    ref.read(expenseFilterProvider.notifier).state = ExpenseFilter(
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
      category: _selectedCategory,
    );
    ref.read(expenseNotifierProvider.notifier).loadExpenses();
  }

  void _confirmDelete(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete this ${expense.formattedAmount} expense?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(expenseNotifierProvider.notifier).deleteExpense(expense);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final ExpenseCategory? selectedCategory;
  final DateTimeRange? dateRange;
  final Function(ExpenseCategory?, DateTimeRange?) onApply;

  const _FilterSheet({
    this.selectedCategory,
    this.dateRange,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  ExpenseCategory? _category;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _dateRange = widget.dateRange;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Filter Expenses',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Category filter
          Text('Category', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategory.values.map((category) {
              final isSelected = _category == category;
              return FilterChip(
                label: Text(category.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _category = selected ? category : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Date range filter
          Text('Date Range', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (picked != null) {
                setState(() => _dateRange = picked);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _dateRange != null
                  ? '${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM').format(_dateRange!.end)}'
                  : 'Select date range',
            ),
          ),
          const Spacer(),

          // Apply button
          ElevatedButton(
            onPressed: () => widget.onApply(_category, _dateRange),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
