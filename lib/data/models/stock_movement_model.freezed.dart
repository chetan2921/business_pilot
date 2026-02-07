// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_movement_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StockMovementModel _$StockMovementModelFromJson(Map<String, dynamic> json) {
  return _StockMovementModel.fromJson(json);
}

/// @nodoc
mixin _$StockMovementModel {
  String get id => throw _privateConstructorUsedError;
  String get productId => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  MovementType get movementType => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get referenceId =>
      throw _privateConstructorUsedError; // e.g., invoice ID for sales
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this StockMovementModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StockMovementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StockMovementModelCopyWith<StockMovementModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockMovementModelCopyWith<$Res> {
  factory $StockMovementModelCopyWith(
    StockMovementModel value,
    $Res Function(StockMovementModel) then,
  ) = _$StockMovementModelCopyWithImpl<$Res, StockMovementModel>;
  @useResult
  $Res call({
    String id,
    String productId,
    int quantity,
    MovementType movementType,
    String? notes,
    String? referenceId,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$StockMovementModelCopyWithImpl<$Res, $Val extends StockMovementModel>
    implements $StockMovementModelCopyWith<$Res> {
  _$StockMovementModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StockMovementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = null,
    Object? quantity = null,
    Object? movementType = null,
    Object? notes = freezed,
    Object? referenceId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            productId: null == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as String,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            movementType: null == movementType
                ? _value.movementType
                : movementType // ignore: cast_nullable_to_non_nullable
                      as MovementType,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            referenceId: freezed == referenceId
                ? _value.referenceId
                : referenceId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StockMovementModelImplCopyWith<$Res>
    implements $StockMovementModelCopyWith<$Res> {
  factory _$$StockMovementModelImplCopyWith(
    _$StockMovementModelImpl value,
    $Res Function(_$StockMovementModelImpl) then,
  ) = __$$StockMovementModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String productId,
    int quantity,
    MovementType movementType,
    String? notes,
    String? referenceId,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$StockMovementModelImplCopyWithImpl<$Res>
    extends _$StockMovementModelCopyWithImpl<$Res, _$StockMovementModelImpl>
    implements _$$StockMovementModelImplCopyWith<$Res> {
  __$$StockMovementModelImplCopyWithImpl(
    _$StockMovementModelImpl _value,
    $Res Function(_$StockMovementModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StockMovementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = null,
    Object? quantity = null,
    Object? movementType = null,
    Object? notes = freezed,
    Object? referenceId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$StockMovementModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        productId: null == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as String,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        movementType: null == movementType
            ? _value.movementType
            : movementType // ignore: cast_nullable_to_non_nullable
                  as MovementType,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        referenceId: freezed == referenceId
            ? _value.referenceId
            : referenceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StockMovementModelImpl extends _StockMovementModel {
  const _$StockMovementModelImpl({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.movementType,
    this.notes,
    this.referenceId,
    this.createdAt,
  }) : super._();

  factory _$StockMovementModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockMovementModelImplFromJson(json);

  @override
  final String id;
  @override
  final String productId;
  @override
  final int quantity;
  @override
  final MovementType movementType;
  @override
  final String? notes;
  @override
  final String? referenceId;
  // e.g., invoice ID for sales
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'StockMovementModel(id: $id, productId: $productId, quantity: $quantity, movementType: $movementType, notes: $notes, referenceId: $referenceId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockMovementModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.movementType, movementType) ||
                other.movementType == movementType) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    productId,
    quantity,
    movementType,
    notes,
    referenceId,
    createdAt,
  );

  /// Create a copy of StockMovementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StockMovementModelImplCopyWith<_$StockMovementModelImpl> get copyWith =>
      __$$StockMovementModelImplCopyWithImpl<_$StockMovementModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StockMovementModelImplToJson(this);
  }
}

abstract class _StockMovementModel extends StockMovementModel {
  const factory _StockMovementModel({
    required final String id,
    required final String productId,
    required final int quantity,
    required final MovementType movementType,
    final String? notes,
    final String? referenceId,
    final DateTime? createdAt,
  }) = _$StockMovementModelImpl;
  const _StockMovementModel._() : super._();

  factory _StockMovementModel.fromJson(Map<String, dynamic> json) =
      _$StockMovementModelImpl.fromJson;

  @override
  String get id;
  @override
  String get productId;
  @override
  int get quantity;
  @override
  MovementType get movementType;
  @override
  String? get notes;
  @override
  String? get referenceId; // e.g., invoice ID for sales
  @override
  DateTime? get createdAt;

  /// Create a copy of StockMovementModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StockMovementModelImplCopyWith<_$StockMovementModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
