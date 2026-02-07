import 'dart:io';

import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../services/storage_service.dart';
import '../services/receipt_scanner_service.dart';

/// Result wrapper for expense operations
class ExpenseResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ExpenseResult._({this.data, this.error, required this.isSuccess});

  factory ExpenseResult.success(T data) =>
      ExpenseResult._(data: data, isSuccess: true);

  factory ExpenseResult.failure(String error) =>
      ExpenseResult._(error: error, isSuccess: false);
}

/// Repository for expense operations with clean API
class ExpenseRepository {
  ExpenseRepository._();
  static final ExpenseRepository _instance = ExpenseRepository._();
  static ExpenseRepository get instance => _instance;

  final _expenseService = ExpenseService.instance;
  final _storageService = StorageService.instance;
  final _scannerService = ReceiptScannerService.instance;

  /// Get all expenses with optional filters
  Future<ExpenseResult<List<ExpenseModel>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    ExpenseCategory? category,
    String? orderBy,
    bool ascending = false,
  }) async {
    try {
      final expenses = await _expenseService.getExpenses(
        startDate: startDate,
        endDate: endDate,
        category: category,
        orderBy: orderBy,
        ascending: ascending,
      );
      return ExpenseResult.success(expenses);
    } catch (e) {
      return ExpenseResult.failure(_parseError(e));
    }
  }

  /// Get expense by ID
  Future<ExpenseResult<ExpenseModel>> getExpenseById(String id) async {
    try {
      final expense = await _expenseService.getExpenseById(id);
      if (expense == null) {
        return ExpenseResult.failure('Expense not found');
      }
      return ExpenseResult.success(expense);
    } catch (e) {
      return ExpenseResult.failure(_parseError(e));
    }
  }

  /// Create expense with optional receipt image
  Future<ExpenseResult<ExpenseModel>> createExpense({
    required double amount,
    required ExpenseCategory category,
    required DateTime expenseDate,
    required String userId,
    String? description,
    String? vendor,
    File? receiptImage,
  }) async {
    try {
      String? receiptUrl;

      // Upload receipt image if provided
      if (receiptImage != null) {
        receiptUrl = await _storageService.uploadReceipt(receiptImage);
      }

      final expense = ExpenseModel(
        id: '', // Will be set by Supabase
        userId: userId,
        amount: amount,
        category: category,
        description: description,
        vendor: vendor,
        expenseDate: expenseDate,
        receiptUrl: receiptUrl,
      );

      final created = await _expenseService.createExpense(expense);
      return ExpenseResult.success(created);
    } catch (e) {
      return ExpenseResult.failure(_parseError(e));
    }
  }

  /// Update existing expense
  Future<ExpenseResult<ExpenseModel>> updateExpense(
    ExpenseModel expense, {
    File? newReceiptImage,
  }) async {
    try {
      String? receiptUrl = expense.receiptUrl;

      // Upload new receipt image if provided
      if (newReceiptImage != null) {
        // Delete old receipt if exists
        if (receiptUrl != null) {
          await _storageService.deleteReceipt(receiptUrl);
        }
        receiptUrl = await _storageService.uploadReceipt(newReceiptImage);
      }

      final updated = await _expenseService.updateExpense(
        expense.copyWith(receiptUrl: receiptUrl),
      );
      return ExpenseResult.success(updated);
    } catch (e) {
      return ExpenseResult.failure(_parseError(e));
    }
  }

  /// Delete expense
  Future<ExpenseResult<void>> deleteExpense(ExpenseModel expense) async {
    try {
      // Delete receipt image if exists
      if (expense.receiptUrl != null) {
        await _storageService.deleteReceipt(expense.receiptUrl!);
      }

      await _expenseService.deleteExpense(expense.id);
      return ExpenseResult.success(null);
    } catch (e) {
      return ExpenseResult.failure(_parseError(e));
    }
  }

  /// Scan receipt from camera
  Future<ReceiptScanResult> scanReceiptFromCamera() async {
    final file = await _scannerService.pickFromCamera();
    if (file == null) {
      return ReceiptScanResult(
        rawText: '',
        imageFile: File(''),
        error: 'Camera cancelled',
      );
    }
    return _scannerService.scanReceipt(file);
  }

  /// Scan receipt from gallery
  Future<ReceiptScanResult> scanReceiptFromGallery() async {
    final file = await _scannerService.pickFromGallery();
    if (file == null) {
      return ReceiptScanResult(
        rawText: '',
        imageFile: File(''),
        error: 'Gallery cancelled',
      );
    }
    return _scannerService.scanReceipt(file);
  }

  /// Get expense summary
  Future<ExpenseResult<Map<String, dynamic>>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final summary = await _expenseService.getExpenseSummary(
        startDate: startDate,
        endDate: endDate,
      );
      return ExpenseResult.success(summary);
    } catch (e) {
      return ExpenseResult.failure(_parseError(e));
    }
  }

  /// Get today's total expenses
  Future<ExpenseResult<double>> getTodayTotal() async {
    try {
      final total = await _expenseService.getTodayTotal();
      return ExpenseResult.success(total);
    } catch (e) {
      return ExpenseResult.failure(_parseError(e));
    }
  }

  /// Parse error to user-friendly message
  String _parseError(dynamic error) {
    final message = error.toString().toLowerCase();

    if (message.contains('permission') || message.contains('denied')) {
      return 'Permission denied. Please grant the required permissions.';
    }
    if (message.contains('network') || message.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    if (message.contains('not found')) {
      return 'Expense not found.';
    }

    return 'An error occurred. Please try again.';
  }
}
