import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_movement_model.freezed.dart';
part 'stock_movement_model.g.dart';

/// Type of stock movement
enum MovementType {
  purchase('Purchase', '📥', true),
  sale('Sale', '📤', false),
  adjustment('Adjustment', '🔧', true),
  return_in('Return (In)', '↩️', true),
  return_out('Return (Out)', '↪️', false),
  damaged('Damaged', '💔', false);

  final String displayName;
  final String emoji;
  final bool isAddition; // true = adds stock, false = removes stock

  const MovementType(this.displayName, this.emoji, this.isAddition);

  String get label => '$emoji $displayName';
}

/// Stock movement model for tracking inventory changes
@freezed
abstract class StockMovementModel with _$StockMovementModel {
  const StockMovementModel._();

  const factory StockMovementModel({
    required String id,
    required String productId,
    required int quantity,
    required MovementType movementType,
    String? notes,
    String? referenceId, // e.g., invoice ID for sales
    DateTime? createdAt,
  }) = _StockMovementModel;

  factory StockMovementModel.fromJson(Map<String, dynamic> json) =>
      _$StockMovementModelFromJson(json);

  /// Create from Supabase row
  factory StockMovementModel.fromSupabase(Map<String, dynamic> row) {
    return StockMovementModel(
      id: row['id'] as String,
      productId: row['product_id'] as String,
      quantity: (row['quantity'] as num).toInt(),
      movementType: MovementType.values.firstWhere(
        (m) => m.name == row['movement_type'],
        orElse: () => MovementType.adjustment,
      ),
      notes: row['notes'] as String?,
      referenceId: row['reference_id'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
    );
  }

  /// Convert to Supabase insert format
  Map<String, dynamic> toSupabase() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'movement_type': movementType.name,
      'notes': notes,
      'reference_id': referenceId,
    };
  }

  /// Net quantity change (positive or negative)
  int get netQuantityChange => movementType.isAddition ? quantity : -quantity;

  /// Formatted display string
  String get displayText {
    final sign = movementType.isAddition ? '+' : '-';
    return '$sign$quantity ${movementType.displayName}';
  }
}
