// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StockMovementModelImpl _$$StockMovementModelImplFromJson(
  Map<String, dynamic> json,
) => _$StockMovementModelImpl(
  id: json['id'] as String,
  productId: json['productId'] as String,
  quantity: (json['quantity'] as num).toInt(),
  movementType: $enumDecode(_$MovementTypeEnumMap, json['movementType']),
  notes: json['notes'] as String?,
  referenceId: json['referenceId'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$StockMovementModelImplToJson(
  _$StockMovementModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'productId': instance.productId,
  'quantity': instance.quantity,
  'movementType': _$MovementTypeEnumMap[instance.movementType]!,
  'notes': instance.notes,
  'referenceId': instance.referenceId,
  'createdAt': instance.createdAt?.toIso8601String(),
};

const _$MovementTypeEnumMap = {
  MovementType.purchase: 'purchase',
  MovementType.sale: 'sale',
  MovementType.adjustment: 'adjustment',
  MovementType.return_in: 'return_in',
  MovementType.return_out: 'return_out',
  MovementType.damaged: 'damaged',
};
