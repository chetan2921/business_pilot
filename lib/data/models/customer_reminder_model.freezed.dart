// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_reminder_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CustomerReminderModel _$CustomerReminderModelFromJson(
  Map<String, dynamic> json,
) {
  return _CustomerReminderModel.fromJson(json);
}

/// @nodoc
mixin _$CustomerReminderModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get customerId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  DateTime get reminderDate => throw _privateConstructorUsedError;
  ReminderType get reminderType => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt =>
      throw _privateConstructorUsedError; // Joined customer name for display
  String? get customerName => throw _privateConstructorUsedError;

  /// Serializes this CustomerReminderModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerReminderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerReminderModelCopyWith<CustomerReminderModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerReminderModelCopyWith<$Res> {
  factory $CustomerReminderModelCopyWith(
    CustomerReminderModel value,
    $Res Function(CustomerReminderModel) then,
  ) = _$CustomerReminderModelCopyWithImpl<$Res, CustomerReminderModel>;
  @useResult
  $Res call({
    String id,
    String userId,
    String customerId,
    String title,
    String? description,
    DateTime reminderDate,
    ReminderType reminderType,
    bool isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
  });
}

/// @nodoc
class _$CustomerReminderModelCopyWithImpl<
  $Res,
  $Val extends CustomerReminderModel
>
    implements $CustomerReminderModelCopyWith<$Res> {
  _$CustomerReminderModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerReminderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? customerId = null,
    Object? title = null,
    Object? description = freezed,
    Object? reminderDate = null,
    Object? reminderType = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? customerName = freezed,
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
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            reminderDate: null == reminderDate
                ? _value.reminderDate
                : reminderDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            reminderType: null == reminderType
                ? _value.reminderType
                : reminderType // ignore: cast_nullable_to_non_nullable
                      as ReminderType,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            customerName: freezed == customerName
                ? _value.customerName
                : customerName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomerReminderModelImplCopyWith<$Res>
    implements $CustomerReminderModelCopyWith<$Res> {
  factory _$$CustomerReminderModelImplCopyWith(
    _$CustomerReminderModelImpl value,
    $Res Function(_$CustomerReminderModelImpl) then,
  ) = __$$CustomerReminderModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String customerId,
    String title,
    String? description,
    DateTime reminderDate,
    ReminderType reminderType,
    bool isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
  });
}

/// @nodoc
class __$$CustomerReminderModelImplCopyWithImpl<$Res>
    extends
        _$CustomerReminderModelCopyWithImpl<$Res, _$CustomerReminderModelImpl>
    implements _$$CustomerReminderModelImplCopyWith<$Res> {
  __$$CustomerReminderModelImplCopyWithImpl(
    _$CustomerReminderModelImpl _value,
    $Res Function(_$CustomerReminderModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerReminderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? customerId = null,
    Object? title = null,
    Object? description = freezed,
    Object? reminderDate = null,
    Object? reminderType = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? customerName = freezed,
  }) {
    return _then(
      _$CustomerReminderModelImpl(
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
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        reminderDate: null == reminderDate
            ? _value.reminderDate
            : reminderDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        reminderType: null == reminderType
            ? _value.reminderType
            : reminderType // ignore: cast_nullable_to_non_nullable
                  as ReminderType,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        customerName: freezed == customerName
            ? _value.customerName
            : customerName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerReminderModelImpl extends _CustomerReminderModel {
  const _$CustomerReminderModelImpl({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.title,
    this.description,
    required this.reminderDate,
    this.reminderType = ReminderType.followUp,
    this.isCompleted = false,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.customerName,
  }) : super._();

  factory _$CustomerReminderModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerReminderModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String customerId;
  @override
  final String title;
  @override
  final String? description;
  @override
  final DateTime reminderDate;
  @override
  @JsonKey()
  final ReminderType reminderType;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final DateTime? completedAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
  // Joined customer name for display
  @override
  final String? customerName;

  @override
  String toString() {
    return 'CustomerReminderModel(id: $id, userId: $userId, customerId: $customerId, title: $title, description: $description, reminderDate: $reminderDate, reminderType: $reminderType, isCompleted: $isCompleted, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt, customerName: $customerName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerReminderModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.reminderDate, reminderDate) ||
                other.reminderDate == reminderDate) &&
            (identical(other.reminderType, reminderType) ||
                other.reminderType == reminderType) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    customerId,
    title,
    description,
    reminderDate,
    reminderType,
    isCompleted,
    completedAt,
    createdAt,
    updatedAt,
    customerName,
  );

  /// Create a copy of CustomerReminderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerReminderModelImplCopyWith<_$CustomerReminderModelImpl>
  get copyWith =>
      __$$CustomerReminderModelImplCopyWithImpl<_$CustomerReminderModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerReminderModelImplToJson(this);
  }
}

abstract class _CustomerReminderModel extends CustomerReminderModel {
  const factory _CustomerReminderModel({
    required final String id,
    required final String userId,
    required final String customerId,
    required final String title,
    final String? description,
    required final DateTime reminderDate,
    final ReminderType reminderType,
    final bool isCompleted,
    final DateTime? completedAt,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final String? customerName,
  }) = _$CustomerReminderModelImpl;
  const _CustomerReminderModel._() : super._();

  factory _CustomerReminderModel.fromJson(Map<String, dynamic> json) =
      _$CustomerReminderModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get customerId;
  @override
  String get title;
  @override
  String? get description;
  @override
  DateTime get reminderDate;
  @override
  ReminderType get reminderType;
  @override
  bool get isCompleted;
  @override
  DateTime? get completedAt;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt; // Joined customer name for display
  @override
  String? get customerName;

  /// Create a copy of CustomerReminderModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerReminderModelImplCopyWith<_$CustomerReminderModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
