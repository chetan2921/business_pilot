import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/services/customer_service.dart';
import '../../data/services/invoice_service.dart';
import 'auth_provider.dart';

// ============ Customer Providers ============

final customerServiceProvider = Provider<CustomerService>((ref) {
  return CustomerService.instance;
});

final customersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  return ref.watch(customerServiceProvider).getCustomers();
});

final customerLoadingProvider = StateProvider<bool>((ref) => false);
final customerErrorProvider = StateProvider<String?>((ref) => null);

class CustomerNotifier extends StateNotifier<AsyncValue<List<CustomerModel>>> {
  final CustomerService _service;
  final Ref _ref;

  CustomerNotifier(this._service, this._ref)
    : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  Future<void> loadCustomers({String? search}) async {
    state = const AsyncValue.loading();
    try {
      final customers = await _service.getCustomers(search: search);
      state = AsyncValue.data(customers);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> addCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
  }) async {
    _ref.read(customerLoadingProvider.notifier).state = true;
    _ref.read(customerErrorProvider.notifier).state = null;

    try {
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) throw Exception('Not authenticated');

      final customer = CustomerModel(
        id: '',
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        address: address,
      );

      await _service.createCustomer(customer);
      await loadCustomers();
      _ref.read(customerLoadingProvider.notifier).state = false;
      return true;
    } catch (e) {
      _ref.read(customerErrorProvider.notifier).state = e.toString();
      _ref.read(customerLoadingProvider.notifier).state = false;
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      await _service.deleteCustomer(id);
      await loadCustomers();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final customerNotifierProvider =
    StateNotifierProvider<CustomerNotifier, AsyncValue<List<CustomerModel>>>(
      (ref) => CustomerNotifier(ref.watch(customerServiceProvider), ref),
    );

// ============ Invoice Providers ============

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService.instance;
});

final invoiceFilterProvider = StateProvider<InvoiceStatus?>((ref) => null);

final invoicesProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  final status = ref.watch(invoiceFilterProvider);
  return ref.watch(invoiceServiceProvider).getInvoices(status: status);
});

final invoiceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(invoiceServiceProvider).getInvoiceStats();
});

final invoiceLoadingProvider = StateProvider<bool>((ref) => false);
final invoiceErrorProvider = StateProvider<String?>((ref) => null);

class InvoiceNotifier extends StateNotifier<AsyncValue<List<InvoiceModel>>> {
  final InvoiceService _service;
  final Ref _ref;

  InvoiceNotifier(this._service, this._ref)
    : super(const AsyncValue.loading()) {
    // Listen to filter changes and reload
    _ref.listen<InvoiceStatus?>(invoiceFilterProvider, (_, __) {
      loadInvoices();
    });
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    state = const AsyncValue.loading();
    try {
      final status = _ref.read(invoiceFilterProvider);
      final invoices = await _service.getInvoices(status: status);
      state = AsyncValue.data(invoices);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> createInvoice({
    String? customerId,
    required List<InvoiceItem> items,
    double taxRate = 0,
    String? notes,
    DateTime? dueDate,
  }) async {
    _ref.read(invoiceLoadingProvider.notifier).state = true;
    _ref.read(invoiceErrorProvider.notifier).state = null;

    try {
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) throw Exception('Not authenticated');

      final invoiceNumber = await _service.generateInvoiceNumber();

      double subtotal = 0;
      for (final item in items) {
        subtotal += item.amount;
      }
      final taxAmount = subtotal * (taxRate / 100);
      final total = subtotal + taxAmount;

      final invoice = InvoiceModel(
        id: '',
        userId: userId,
        customerId: customerId,
        invoiceNumber: invoiceNumber,
        status: InvoiceStatus.draft,
        subtotal: subtotal,
        taxRate: taxRate,
        taxAmount: taxAmount,
        total: total,
        notes: notes,
        issueDate: DateTime.now(),
        dueDate: dueDate,
      );

      final created = await _service.createInvoice(invoice, items);
      await loadInvoices();
      _ref.read(invoiceLoadingProvider.notifier).state = false;
      return created.id;
    } catch (e) {
      _ref.read(invoiceErrorProvider.notifier).state = e.toString();
      _ref.read(invoiceLoadingProvider.notifier).state = false;
      return null;
    }
  }

  Future<bool> updateStatus(String id, InvoiceStatus status) async {
    try {
      await _service.updateStatus(id, status);
      await loadInvoices();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteInvoice(String id) async {
    try {
      await _service.deleteInvoice(id);
      await loadInvoices();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final invoiceNotifierProvider =
    StateNotifierProvider<InvoiceNotifier, AsyncValue<List<InvoiceModel>>>(
      (ref) => InvoiceNotifier(ref.watch(invoiceServiceProvider), ref),
    );

/// Get single invoice by ID
final invoiceByIdProvider = FutureProvider.family<InvoiceModel?, String>(
  (ref, id) => ref.watch(invoiceServiceProvider).getInvoiceById(id),
);
