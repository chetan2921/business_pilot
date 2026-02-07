import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/services/receipt_scanner_service.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/primary_button.dart';

/// Add expense screen with manual entry and receipt scanning
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _vendorController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();
  File? _receiptImage;
  ReceiptScanResult? _scanResult;
  bool _isScanning = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt(bool fromCamera) async {
    setState(() => _isScanning = true);

    final notifier = ref.read(expenseNotifierProvider.notifier);
    final result = fromCamera
        ? await notifier.scanFromCamera()
        : await notifier.scanFromGallery();

    setState(() => _isScanning = false);

    if (result == null || result.hasError) {
      if (result?.error != 'Camera cancelled' &&
          result?.error != 'Gallery cancelled') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result?.error ?? 'Scan failed')),
          );
        }
      }
      return;
    }

    setState(() {
      _scanResult = result;
      _receiptImage = result.imageFile;

      // Auto-fill extracted data
      if (result.extractedAmount != null) {
        _amountController.text = result.extractedAmount!.toStringAsFixed(2);
      }
      if (result.extractedVendor != null) {
        _vendorController.text = result.extractedVendor!;
      }
      if (result.extractedDate != null) {
        _selectedDate = result.extractedDate!;
      }
    });

    // Show extraction summary
    if (mounted && result.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Extracted: ${result.extractedAmount != null ? "₹${result.extractedAmount}" : ""} '
                    '${result.extractedVendor ?? ""}'
                .trim(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.tryParse(
        _amountController.text.replaceAll(',', ''),
      );
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }

      final success = await ref
          .read(expenseNotifierProvider.notifier)
          .addExpense(
            amount: amount,
            category: _selectedCategory,
            expenseDate: _selectedDate,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            vendor: _vendorController.text.trim().isNotEmpty
                ? _vendorController.text.trim()
                : null,
            receiptImage: _receiptImage,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully!')),
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(expenseErrorProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to add expense')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(expenseLoadingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('EEE, dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Receipt Scanner Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.document_scanner,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scan Receipt',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_receiptImage != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _receiptImage!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton.filled(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _receiptImage = null;
                                    _scanResult = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isScanning
                                    ? null
                                    : () => _scanReceipt(true),
                                icon: _isScanning
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.camera_alt),
                                label: const Text('Camera'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isScanning
                                    ? null
                                    : () => _scanReceipt(false),
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Gallery'),
                              ),
                            ),
                          ],
                        ),
                      if (_scanResult != null &&
                          _scanResult!.rawText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ExpansionTile(
                            title: const Text('Extracted Text'),
                            tilePadding: EdgeInsets.zero,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _scanResult!.rawText,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                style: Theme.of(context).textTheme.headlineSmall,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: ExpenseCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Vendor Field
              TextFormField(
                controller: _vendorController,
                decoration: const InputDecoration(
                  labelText: 'Vendor / Store (Optional)',
                  prefixIcon: Icon(Icons.store),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Save Button
              PrimaryButton(
                text: 'Save Expense',
                onPressed: _saveExpense,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
