// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'communication_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommunicationLogModelImpl _$$CommunicationLogModelImplFromJson(
  Map<String, dynamic> json,
) => _$CommunicationLogModelImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  customerId: json['customerId'] as String,
  type: $enumDecode(_$CommunicationTypeEnumMap, json['type']),
  subject: json['subject'] as String?,
  content: json['content'] as String,
  direction:
      $enumDecodeNullable(_$CommunicationDirectionEnumMap, json['direction']) ??
      CommunicationDirection.outbound,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$CommunicationLogModelImplToJson(
  _$CommunicationLogModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'customerId': instance.customerId,
  'type': _$CommunicationTypeEnumMap[instance.type]!,
  'subject': instance.subject,
  'content': instance.content,
  'direction': _$CommunicationDirectionEnumMap[instance.direction]!,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$CommunicationTypeEnumMap = {
  CommunicationType.call: 'call',
  CommunicationType.email: 'email',
  CommunicationType.sms: 'sms',
  CommunicationType.meeting: 'meeting',
  CommunicationType.note: 'note',
};

const _$CommunicationDirectionEnumMap = {
  CommunicationDirection.inbound: 'inbound',
  CommunicationDirection.outbound: 'outbound',
};
