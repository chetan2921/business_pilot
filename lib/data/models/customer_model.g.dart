// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomerModelImpl _$$CustomerModelImplFromJson(Map<String, dynamic> json) =>
    _$CustomerModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      companyName: json['companyName'] as String?,
      notes: json['notes'] as String?,
      segment:
          $enumDecodeNullable(_$CustomerSegmentEnumMap, json['segment']) ??
          CustomerSegment.newCustomer,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      lastPurchaseDate: json['lastPurchaseDate'] == null
          ? null
          : DateTime.parse(json['lastPurchaseDate'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CustomerModelImplToJson(_$CustomerModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'address': instance.address,
      'companyName': instance.companyName,
      'notes': instance.notes,
      'segment': _$CustomerSegmentEnumMap[instance.segment]!,
      'tags': instance.tags,
      'totalSpent': instance.totalSpent,
      'lastPurchaseDate': instance.lastPurchaseDate?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$CustomerSegmentEnumMap = {
  CustomerSegment.gold: 'gold',
  CustomerSegment.silver: 'silver',
  CustomerSegment.bronze: 'bronze',
  CustomerSegment.newCustomer: 'newCustomer',
};
