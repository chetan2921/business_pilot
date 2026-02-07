// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'communication_log_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CommunicationLogModel _$CommunicationLogModelFromJson(
  Map<String, dynamic> json,
) {
  return _CommunicationLogModel.fromJson(json);
}

/// @nodoc
mixin _$CommunicationLogModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get customerId => throw _privateConstructorUsedError;
  CommunicationType get type => throw _privateConstructorUsedError;
  String? get subject => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  CommunicationDirection get direction => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CommunicationLogModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommunicationLogModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommunicationLogModelCopyWith<CommunicationLogModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommunicationLogModelCopyWith<$Res> {
  factory $CommunicationLogModelCopyWith(
    CommunicationLogModel value,
    $Res Function(CommunicationLogModel) then,
  ) = _$CommunicationLogModelCopyWithImpl<$Res, CommunicationLogModel>;
  @useResult
  $Res call({
    String id,
    String userId,
    String customerId,
    CommunicationType type,
    String? subject,
    String content,
    CommunicationDirection direction,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$CommunicationLogModelCopyWithImpl<
  $Res,
  $Val extends CommunicationLogModel
>
    implements $CommunicationLogModelCopyWith<$Res> {
  _$CommunicationLogModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommunicationLogModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? customerId = null,
    Object? type = null,
    Object? subject = freezed,
    Object? content = null,
    Object? direction = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            customerId: null == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as CommunicationType,
            subject: freezed == subject
                ? _value.subject
                : subject // ignore: cast_nullable_to_non_nullable
                      as String?,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            direction: null == direction
                ? _value.direction
                : direction // ignore: cast_nullable_to_non_nullable
                      as CommunicationDirection,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CommunicationLogModelImplCopyWith<$Res>
    implements $CommunicationLogModelCopyWith<$Res> {
  factory _$$CommunicationLogModelImplCopyWith(
    _$CommunicationLogModelImpl value,
    $Res Function(_$CommunicationLogModelImpl) then,
  ) = __$$CommunicationLogModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String customerId,
    CommunicationType type,
    String? subject,
    String content,
    CommunicationDirection direction,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$CommunicationLogModelImplCopyWithImpl<$Res>
    extends
        _$CommunicationLogModelCopyWithImpl<$Res, _$CommunicationLogModelImpl>
    implements _$$CommunicationLogModelImplCopyWith<$Res> {
  __$$CommunicationLogModelImplCopyWithImpl(
    _$CommunicationLogModelImpl _value,
    $Res Function(_$CommunicationLogModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommunicationLogModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? customerId = null,
    Object? type = null,
    Object? subject = freezed,
    Object? content = null,
    Object? direction = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$CommunicationLogModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerId: null == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as CommunicationType,
        subject: freezed == subject
            ? _value.subject
            : subject // ignore: cast_nullable_to_non_nullable
                  as String?,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        direction: null == direction
            ? _value.direction
            : direction // ignore: cast_nullable_to_non_nullable
                  as CommunicationDirection,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CommunicationLogModelImpl extends _CommunicationLogModel {
  const _$CommunicationLogModelImpl({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.type,
    this.subject,
    required this.content,
    this.direction = CommunicationDirection.outbound,
    this.createdAt,
    this.updatedAt,
  }) : super._();

  factory _$CommunicationLogModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommunicationLogModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String customerId;
  @override
  final CommunicationType type;
  @override
  final String? subject;
  @override
  final String content;
  @override
  @JsonKey()
  final CommunicationDirection direction;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'CommunicationLogModel(id: $id, userId: $userId, customerId: $customerId, type: $type, subject: $subject, content: $content, direction: $direction, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommunicationLogModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    customerId,
    type,
    subject,
    content,
    direction,
    createdAt,
    updatedAt,
  );

  /// Create a copy of CommunicationLogModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommunicationLogModelImplCopyWith<_$CommunicationLogModelImpl>
  get copyWith =>
      __$$CommunicationLogModelImplCopyWithImpl<_$CommunicationLogModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CommunicationLogModelImplToJson(this);
  }
}

abstract class _CommunicationLogModel extends CommunicationLogModel {
  const factory _CommunicationLogModel({
    required final String id,
    required final String userId,
    required final String customerId,
    required final CommunicationType type,
    final String? subject,
    required final String content,
    final CommunicationDirection direction,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$CommunicationLogModelImpl;
  const _CommunicationLogModel._() : super._();

  factory _CommunicationLogModel.fromJson(Map<String, dynamic> json) =
      _$CommunicationLogModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get customerId;
  @override
  CommunicationType get type;
  @override
  String? get subject;
  @override
  String get content;
  @override
  CommunicationDirection get direction;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of CommunicationLogModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommunicationLogModelImplCopyWith<_$CommunicationLogModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
