import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/services/receipt_scanner_service.dart';
import 'auth_provider.dart';

/// Expense repository provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository.instance;
});

/// Expenses list provider with filters
final expensesProvider =
    FutureProvider.family<List<ExpenseModel>, ExpenseFilter>((
      ref,
      filter,
    ) async {
      final result = await ref
          .watch(expenseRepositoryProvider)
          .getExpenses(
            startDate: filter.startDate,
            endDate: filter.endDate,
            category: filter.category,
            orderBy: filter.orderBy,
            ascending: filter.ascending,
          );
      if (result.isSuccess) {
        return result.data!;
      }
      throw Exception(result.error);
    });

/// Today's expense total provider
final todayExpenseTotalProvider = FutureProvider<double>((ref) async {
  final result = await ref.watch(expenseRepositoryProvider).getTodayTotal();
  if (result.isSuccess) {
    return result.data!;
  }
  return 0.0;
});

/// Expense filter model
class ExpenseFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final ExpenseCategory? category;
  final String? orderBy;
  final bool ascending;

  const ExpenseFilter({
    this.startDate,
    this.endDate,
    this.category,
    this.orderBy,
    this.ascending = false,
  });

  ExpenseFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    ExpenseCategory? category,
    String? orderBy,
    bool? ascending,
  }) {
    return ExpenseFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      orderBy: orderBy ?? this.orderBy,
      ascending: ascending ?? this.ascending,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseFilter &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          category == other.category &&
          orderBy == other.orderBy &&
          ascending == other.ascending;

  @override
  int get hashCode =>
      startDate.hashCode ^
      endDate.hashCode ^
      category.hashCode ^
      orderBy.hashCode ^
      ascending.hashCode;
}

/// Current filter state provider
final expenseFilterProvider = StateProvider<ExpenseFilter>((ref) {
  return const ExpenseFilter();
});

/// Expense loading state
final expenseLoadingProvider = StateProvider<bool>((ref) => false);

/// Expense error state
final expenseErrorProvider = StateProvider<String?>((ref) => null);

/// Expense notifier for managing expense operations
class ExpenseNotifier extends StateNotifier<AsyncValue<List<ExpenseModel>>> {
  final ExpenseRepository _repository;
  final Ref _ref;

  ExpenseNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  /// Load expenses with current filter
  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    final filter = _ref.read(expenseFilterProvider);

    final result = await _repository.getExpenses(
      startDate: filter.startDate,
      endDate: filter.endDate,
      category: filter.category,
      orderBy: filter.orderBy,
      ascending: filter.ascending,
    );

    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
    } else {
      state = AsyncValue.error(result.error!, StackTrace.current);
    }
  }

  /// Add new expense
  Future<bool> addExpense({
    required double amount,
    required ExpenseCategory category,
    required DateTime expenseDate,
    String? description,
    String? vendor,
    File? receiptImage,
  }) async {
    _ref.read(expenseLoadingProvider.notifier).state = true;
    _ref.read(expenseErrorProvider.notifier).state = null;

    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) {
      _ref.read(expenseErrorProvider.notifier).state = 'User not authenticated';
      _ref.read(expenseLoadingProvider.notifier).state = false;
      return false;
    }

    final result = await _repository.createExpense(
      amount: amount,
      category: category,
      expenseDate: expenseDate,
      userId: userId,
      description: description,
      vendor: vendor,
      receiptImage: receiptImage,
    );

    _ref.read(expenseLoadingProvider.notifier).state = false;

    if (result.isSuccess) {
      await loadExpenses(); // Refresh list
      return true;
    } else {
      _ref.read(expenseErrorProvider.notifier).state = result.error;
      return false;
    }
  }

  /// Update expense
  Future<bool> updateExpense(
    ExpenseModel expense, {
    File? newReceiptImage,
  }) async {
    _ref.read(expenseLoadingProvider.notifier).state = true;
    _ref.read(expenseErrorProvider.notifier).state = null;

    final result = await _repository.updateExpense(
      expense,
      newReceiptImage: newReceiptImage,
    );

    _ref.read(expenseLoadingProvider.notifier).state = false;

    if (result.isSuccess) {
      await loadExpenses(); // Refresh list
      return true;
    } else {
      _ref.read(expenseErrorProvider.notifier).state = result.error;
      return false;
    }
  }

  /// Delete expense
  Future<bool> deleteExpense(ExpenseModel expense) async {
    _ref.read(expenseLoadingProvider.notifier).state = true;

    final result = await _repository.deleteExpense(expense);

    _ref.read(expenseLoadingProvider.notifier).state = false;

    if (result.isSuccess) {
      await loadExpenses(); // Refresh list
      return true;
    } else {
      _ref.read(expenseErrorProvider.notifier).state = result.error;
      return false;
    }
  }

  /// Scan receipt from camera
  Future<ReceiptScanResult?> scanFromCamera() async {
    return _repository.scanReceiptFromCamera();
  }

  /// Scan receipt from gallery
  Future<ReceiptScanResult?> scanFromGallery() async {
    return _repository.scanReceiptFromGallery();
  }

  /// Clear error
  void clearError() {
    _ref.read(expenseErrorProvider.notifier).state = null;
  }
}

/// Expense notifier provider
final expenseNotifierProvider =
    StateNotifierProvider<ExpenseNotifier, AsyncValue<List<ExpenseModel>>>(
      (ref) => ExpenseNotifier(ref.watch(expenseRepositoryProvider), ref),
    );
