// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExpenseModelImpl _$$ExpenseModelImplFromJson(Map<String, dynamic> json) =>
    _$ExpenseModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: $enumDecode(_$ExpenseCategoryEnumMap, json['category']),
      description: json['description'] as String?,
      vendor: json['vendor'] as String?,
      expenseDate: DateTime.parse(json['expenseDate'] as String),
      receiptUrl: json['receiptUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ExpenseModelImplToJson(_$ExpenseModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'amount': instance.amount,
      'category': _$ExpenseCategoryEnumMap[instance.category]!,
      'description': instance.description,
      'vendor': instance.vendor,
      'expenseDate': instance.expenseDate.toIso8601String(),
      'receiptUrl': instance.receiptUrl,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$ExpenseCategoryEnumMap = {
  ExpenseCategory.food: 'food',
  ExpenseCategory.transport: 'transport',
  ExpenseCategory.utilities: 'utilities',
  ExpenseCategory.rent: 'rent',
  ExpenseCategory.supplies: 'supplies',
  ExpenseCategory.marketing: 'marketing',
  ExpenseCategory.salary: 'salary',
  ExpenseCategory.equipment: 'equipment',
  ExpenseCategory.travel: 'travel',
  ExpenseCategory.insurance: 'insurance',
  ExpenseCategory.taxes: 'taxes',
  ExpenseCategory.entertainment: 'entertainment',
  ExpenseCategory.healthcare: 'healthcare',
  ExpenseCategory.subscriptions: 'subscriptions',
  ExpenseCategory.other: 'other',
};
