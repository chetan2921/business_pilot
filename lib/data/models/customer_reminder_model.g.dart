// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_reminder_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomerReminderModelImpl _$$CustomerReminderModelImplFromJson(
  Map<String, dynamic> json,
) => _$CustomerReminderModelImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  customerId: json['customerId'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  reminderDate: DateTime.parse(json['reminderDate'] as String),
  reminderType:
      $enumDecodeNullable(_$ReminderTypeEnumMap, json['reminderType']) ??
      ReminderType.followUp,
  isCompleted: json['isCompleted'] as bool? ?? false,
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  customerName: json['customerName'] as String?,
);

Map<String, dynamic> _$$CustomerReminderModelImplToJson(
  _$CustomerReminderModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'customerId': instance.customerId,
  'title': instance.title,
  'description': instance.description,
  'reminderDate': instance.reminderDate.toIso8601String(),
  'reminderType': _$ReminderTypeEnumMap[instance.reminderType]!,
  'isCompleted': instance.isCompleted,
  'completedAt': instance.completedAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'customerName': instance.customerName,
};

const _$ReminderTypeEnumMap = {
  ReminderType.followUp: 'followUp',
  ReminderType.payment: 'payment',
  ReminderType.birthday: 'birthday',
  ReminderType.anniversary: 'anniversary',
  ReminderType.custom: 'custom',
};
