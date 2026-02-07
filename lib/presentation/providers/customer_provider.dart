import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer_model.dart';
import '../../data/services/customer_service.dart';
import 'auth_provider.dart';

/// Customers list provider
final customersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];
  return CustomerService.instance.getCustomers();
});

/// Customer loading state
final customerLoadingProvider = StateProvider<bool>((ref) => false);

/// Customer notifier for CRUD operations
class CustomerNotifier extends StateNotifier<AsyncValue<List<CustomerModel>>> {
  final Ref _ref;

  CustomerNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    try {
      final customers = await CustomerService.instance.getCustomers();
      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
  }) async {
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    _ref.read(customerLoadingProvider.notifier).state = true;
    try {
      final customer = CustomerModel(
        id: '',
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        address: address,
      );
      await CustomerService.instance.createCustomer(customer);
      await loadCustomers();
      return true;
    } catch (e) {
      return false;
    } finally {
      _ref.read(customerLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    _ref.read(customerLoadingProvider.notifier).state = true;
    try {
      await CustomerService.instance.updateCustomer(customer);
      await loadCustomers();
      return true;
    } catch (e) {
      return false;
    } finally {
      _ref.read(customerLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    try {
      await CustomerService.instance.deleteCustomer(customerId);
      await loadCustomers();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Customer notifier provider
final customerNotifierProvider =
    StateNotifierProvider<CustomerNotifier, AsyncValue<List<CustomerModel>>>(
      (ref) => CustomerNotifier(ref),
    );

/// Provider for getting a single customer's purchase history
final customerPurchaseHistoryProvider =
    FutureProvider.family<List<CustomerPurchase>, String>((
      ref,
      customerId,
    ) async {
      final data = await CustomerService.instance.getCustomerPurchaseHistory(
        customerId,
      );
      return data.map((row) => CustomerPurchase.fromSupabase(row)).toList();
    });

/// Customer purchase summary model
class CustomerPurchase {
  final String invoiceId;
  final String invoiceNumber;
  final DateTime date;
  final double total;
  final String status;

  CustomerPurchase({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.date,
    required this.total,
    required this.status,
  });

  factory CustomerPurchase.fromSupabase(Map<String, dynamic> row) {
    return CustomerPurchase(
      invoiceId: row['id'] as String,
      invoiceNumber: row['invoice_number'] as String,
      date: DateTime.parse(row['issue_date'] as String),
      total: (row['total'] as num).toDouble(),
      status: row['status'] as String,
    );
  }
}
