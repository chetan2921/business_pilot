import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/invoice_model.dart';

/// Service for invoice CRUD operations
class InvoiceService {
  InvoiceService._();
  static final InvoiceService _instance = InvoiceService._();
  static InvoiceService get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;
  static const String _tableName = 'invoices';
  static const String _itemsTable = 'invoice_items';

  /// Get all invoices with optional filters
  Future<List<InvoiceModel>> getInvoices({
    InvoiceStatus? status,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from(_tableName).select('*, customer:customers(name)');

    if (status != null) {
      query = query.eq('status', status.name);
    }
    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }
    if (startDate != null) {
      query = query.gte(
        'issue_date',
        startDate.toIso8601String().split('T')[0],
      );
    }
    if (endDate != null) {
      query = query.lte('issue_date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((row) => InvoiceModel.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  /// Get invoice by ID with items
  Future<InvoiceModel?> getInvoiceById(String id) async {
    final invoiceResponse = await _client
        .from(_tableName)
        .select('*, customer:customers(name)')
        .eq('id', id)
        .maybeSingle();

    if (invoiceResponse == null) return null;

    // Get invoice items
    final itemsResponse = await _client
        .from(_itemsTable)
        .select()
        .eq('invoice_id', id)
        .order('id');

    final items = (itemsResponse as List)
        .map((row) => InvoiceItem.fromSupabase(row as Map<String, dynamic>))
        .toList();

    return InvoiceModel.fromSupabase(invoiceResponse, items);
  }

  /// Create invoice with items
  Future<InvoiceModel> createInvoice(
    InvoiceModel invoice,
    List<InvoiceItem> items,
  ) async {
    // Create invoice
    final invoiceResponse = await _client
        .from(_tableName)
        .insert(invoice.toSupabase())
        .select()
        .single();

    final invoiceId = invoiceResponse['id'] as String;

    // Create items
    if (items.isNotEmpty) {
      await _client
          .from(_itemsTable)
          .insert(items.map((item) => item.toSupabase(invoiceId)).toList());
    }

    return getInvoiceById(invoiceId).then((inv) => inv!);
  }

  /// Update invoice
  Future<InvoiceModel> updateInvoice(
    InvoiceModel invoice,
    List<InvoiceItem> items,
  ) async {
    // Update invoice
    await _client
        .from(_tableName)
        .update(invoice.toSupabase())
        .eq('id', invoice.id);

    // Delete existing items and re-create
    await _client.from(_itemsTable).delete().eq('invoice_id', invoice.id);

    if (items.isNotEmpty) {
      await _client
          .from(_itemsTable)
          .insert(items.map((item) => item.toSupabase(invoice.id)).toList());
    }

    return getInvoiceById(invoice.id).then((inv) => inv!);
  }

  /// Update invoice status
  Future<void> updateStatus(String id, InvoiceStatus status) async {
    await _client.from(_tableName).update({'status': status.name}).eq('id', id);
  }

  /// Delete invoice
  Future<void> deleteInvoice(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  /// Generate next invoice number
  Future<String> generateInvoiceNumber() async {
    final year = DateTime.now().year;
    final prefix = 'INV-$year-';

    final response = await _client
        .from(_tableName)
        .select('invoice_number')
        .like('invoice_number', '$prefix%')
        .order('invoice_number', ascending: false)
        .limit(1);

    if ((response as List).isEmpty) {
      return '${prefix}0001';
    }

    final lastNumber = response[0]['invoice_number'] as String;
    final lastSeq = int.tryParse(lastNumber.split('-').last) ?? 0;
    return '$prefix${(lastSeq + 1).toString().padLeft(4, '0')}';
  }

  /// Get invoice stats
  Future<Map<String, dynamic>> getInvoiceStats() async {
    final all = await getInvoices();

    double totalPending = 0;
    int pendingCount = 0;
    double totalPaid = 0;
    int overdueCount = 0;

    for (final invoice in all) {
      if (invoice.status == InvoiceStatus.paid) {
        totalPaid += invoice.total;
      } else if (invoice.status != InvoiceStatus.cancelled) {
        totalPending += invoice.total;
        pendingCount++;
        if (invoice.isOverdue) overdueCount++;
      }
    }

    return {
      'totalPending': totalPending,
      'pendingCount': pendingCount,
      'totalPaid': totalPaid,
      'overdueCount': overdueCount,
    };
  }
}
