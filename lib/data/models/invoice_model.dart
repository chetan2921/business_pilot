import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice_model.freezed.dart';
part 'invoice_model.g.dart';

/// Invoice status
enum InvoiceStatus {
  draft('Draft', '📝'),
  sent('Sent', '📤'),
  viewed('Viewed', '👁️'),
  paid('Paid', '✅'),
  overdue('Overdue', '⚠️'),
  cancelled('Cancelled', '❌');

  final String displayName;
  final String emoji;

  const InvoiceStatus(this.displayName, this.emoji);

  String get label => '$emoji $displayName';
}

/// Invoice line item
@freezed
abstract class InvoiceItem with _$InvoiceItem {
  const InvoiceItem._();

  const factory InvoiceItem({
    String? id,
    String? invoiceId,
    required String description,
    @Default(1) double quantity,
    required double unitPrice,
    required double amount,
  }) = _InvoiceItem;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemFromJson(json);

  factory InvoiceItem.fromSupabase(Map<String, dynamic> row) {
    return InvoiceItem(
      id: row['id'] as String?,
      invoiceId: row['invoice_id'] as String?,
      description: row['description'] as String,
      quantity: (row['quantity'] as num?)?.toDouble() ?? 1,
      unitPrice: (row['unit_price'] as num).toDouble(),
      amount: (row['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toSupabase(String invoiceId) {
    return {
      'invoice_id': invoiceId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'amount': amount,
    };
  }
}

/// Invoice model
@freezed
abstract class InvoiceModel with _$InvoiceModel {
  const InvoiceModel._();

  const factory InvoiceModel({
    required String id,
    required String userId,
    String? customerId,
    String? customerName,
    required String invoiceNumber,
    @Default(InvoiceStatus.draft) InvoiceStatus status,
    @Default(0) double subtotal,
    @Default(0) double taxRate,
    @Default(0) double taxAmount,
    @Default(0) double total,
    String? notes,
    required DateTime issueDate,
    DateTime? dueDate,
    DateTime? createdAt,
    @Default([]) List<InvoiceItem> items,
  }) = _InvoiceModel;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceModelFromJson(json);

  factory InvoiceModel.fromSupabase(
    Map<String, dynamic> row, [
    List<InvoiceItem>? items,
  ]) {
    return InvoiceModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      customerId: row['customer_id'] as String?,
      customerName: row['customer']?['name'] as String?,
      invoiceNumber: row['invoice_number'] as String,
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      subtotal: (row['subtotal'] as num?)?.toDouble() ?? 0,
      taxRate: (row['tax_rate'] as num?)?.toDouble() ?? 0,
      taxAmount: (row['tax_amount'] as num?)?.toDouble() ?? 0,
      total: (row['total'] as num?)?.toDouble() ?? 0,
      notes: row['notes'] as String?,
      issueDate: DateTime.parse(row['issue_date'] as String),
      dueDate: row['due_date'] != null
          ? DateTime.parse(row['due_date'] as String)
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      items: items ?? [],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'customer_id': customerId,
      'invoice_number': invoiceNumber,
      'status': status.name,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total': total,
      'notes': notes,
      'issue_date': issueDate.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
    };
  }

  /// Formatted total
  String get formattedTotal => '₹${total.toStringAsFixed(2)}';

  /// Is overdue
  bool get isOverdue =>
      status != InvoiceStatus.paid &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());
}
