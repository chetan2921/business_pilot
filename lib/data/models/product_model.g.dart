// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductModelImpl _$$ProductModelImplFromJson(Map<String, dynamic> json) =>
    _$ProductModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 10,
      category:
          $enumDecodeNullable(_$ProductCategoryEnumMap, json['category']) ??
          ProductCategory.other,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ProductModelImplToJson(_$ProductModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'description': instance.description,
      'sku': instance.sku,
      'barcode': instance.barcode,
      'costPrice': instance.costPrice,
      'sellingPrice': instance.sellingPrice,
      'stockQuantity': instance.stockQuantity,
      'lowStockThreshold': instance.lowStockThreshold,
      'category': _$ProductCategoryEnumMap[instance.category]!,
      'imageUrl': instance.imageUrl,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$ProductCategoryEnumMap = {
  ProductCategory.electronics: 'electronics',
  ProductCategory.clothing: 'clothing',
  ProductCategory.food: 'food',
  ProductCategory.beauty: 'beauty',
  ProductCategory.home: 'home',
  ProductCategory.sports: 'sports',
  ProductCategory.books: 'books',
  ProductCategory.toys: 'toys',
  ProductCategory.automotive: 'automotive',
  ProductCategory.other: 'other',
};
