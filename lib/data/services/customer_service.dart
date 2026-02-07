import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/customer_model.dart';

/// Service for customer CRUD operations
class CustomerService {
  CustomerService._();
  static final CustomerService _instance = CustomerService._();
  static CustomerService get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;
  static const String _tableName = 'customers';

  /// Get all customers for current user
  Future<List<CustomerModel>> getCustomers({String? search}) async {
    var query = _client.from(_tableName).select();

    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,email.ilike.%$search%');
    }

    final response = await query.order('name');

    return (response as List)
        .map((row) => CustomerModel.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  /// Get customer by ID
  Future<CustomerModel?> getCustomerById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return CustomerModel.fromSupabase(response);
  }

  /// Create new customer
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final response = await _client
        .from(_tableName)
        .insert(customer.toSupabase())
        .select()
        .single();

    return CustomerModel.fromSupabase(response);
  }

  /// Update customer
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final response = await _client
        .from(_tableName)
        .update(customer.toSupabase())
        .eq('id', customer.id)
        .select()
        .single();

    return CustomerModel.fromSupabase(response);
  }

  /// Delete customer
  Future<void> deleteCustomer(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  /// Get customer count
  Future<int> getCustomerCount() async {
    final response = await _client
        .from(_tableName)
        .select()
        .count(CountOption.exact);
    return response.count;
  }

  /// Get customer purchase history from invoices
  Future<List<Map<String, dynamic>>> getCustomerPurchaseHistory(
    String customerId,
  ) async {
    final response = await _client
        .from('invoices')
        .select('id, invoice_number, issue_date, total, status')
        .eq('customer_id', customerId)
        .order('issue_date', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }
}
