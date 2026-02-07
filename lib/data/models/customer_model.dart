import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_model.freezed.dart';
part 'customer_model.g.dart';

/// Customer segment for categorization
enum CustomerSegment {
  gold('Gold', '🥇', 'Top-tier customer'),
  silver('Silver', '🥈', 'High-value customer'),
  bronze('Bronze', '🥉', 'Regular customer'),
  newCustomer('New', '🆕', 'New customer');

  final String displayName;
  final String emoji;
  final String description;

  const CustomerSegment(this.displayName, this.emoji, this.description);

  String get label => '$emoji $displayName';

  static CustomerSegment fromString(String? value) {
    switch (value) {
      case 'gold':
        return CustomerSegment.gold;
      case 'silver':
        return CustomerSegment.silver;
      case 'bronze':
        return CustomerSegment.bronze;
      default:
        return CustomerSegment.newCustomer;
    }
  }
}

/// Customer model
@freezed
abstract class CustomerModel with _$CustomerModel {
  const CustomerModel._();

  const factory CustomerModel({
    required String id,
    required String userId,
    required String name,
    String? email,
    String? phone,
    String? address,
    String? companyName,
    String? notes,
    @Default(CustomerSegment.newCustomer) CustomerSegment segment,
    @Default([]) List<String> tags,
    @Default(0) double totalSpent,
    DateTime? lastPurchaseDate,
    DateTime? createdAt,
  }) = _CustomerModel;

  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);

  /// Create from Supabase row
  factory CustomerModel.fromSupabase(Map<String, dynamic> row) {
    return CustomerModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      email: row['email'] as String?,
      phone: row['phone'] as String?,
      address: row['address'] as String?,
      companyName: row['company_name'] as String?,
      notes: row['notes'] as String?,
      segment: CustomerSegment.fromString(row['segment'] as String?),
      tags: row['tags'] != null ? (row['tags'] as List).cast<String>() : [],
      totalSpent: (row['total_spent'] as num?)?.toDouble() ?? 0,
      lastPurchaseDate: row['last_purchase_date'] != null
          ? DateTime.parse(row['last_purchase_date'] as String)
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
    );
  }

  /// Convert to Supabase insert format
  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'company_name': companyName,
      'notes': notes,
      'segment': segment == CustomerSegment.newCustomer ? 'new' : segment.name,
      'tags': tags,
    };
  }

  /// Display name with email
  String get displayWithEmail => email != null ? '$name ($email)' : name;

  /// Get initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Days since last purchase
  int? get daysSinceLastPurchase {
    if (lastPurchaseDate == null) return null;
    return DateTime.now().difference(lastPurchaseDate!).inDays;
  }
}
