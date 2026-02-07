import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

/// Product category enum
enum ProductCategory {
  electronics('Electronics', '📱'),
  clothing('Clothing', '👕'),
  food('Food & Beverages', '🍕'),
  beauty('Beauty & Personal Care', '💄'),
  home('Home & Garden', '🏡'),
  sports('Sports & Outdoors', '⚽'),
  books('Books & Stationery', '📚'),
  toys('Toys & Games', '🎮'),
  automotive('Automotive', '🚗'),
  other('Other', '📦');

  final String displayName;
  final String emoji;

  const ProductCategory(this.displayName, this.emoji);

  String get label => '$emoji $displayName';
}

/// Stock status for visual indicators
enum StockStatus {
  inStock('In Stock'),
  lowStock('Low Stock'),
  outOfStock('Out of Stock');

  final String displayName;
  const StockStatus(this.displayName);
}

/// Product model
@freezed
abstract class ProductModel with _$ProductModel {
  const ProductModel._();

  const factory ProductModel({
    required String id,
    required String userId,
    required String name,
    String? description,
    String? sku,
    String? barcode,
    @Default(0) double costPrice,
    required double sellingPrice,
    @Default(0) int stockQuantity,
    @Default(10) int lowStockThreshold,
    @Default(ProductCategory.other) ProductCategory category,
    String? imageUrl,
    @Default(true) bool isActive,
    DateTime? createdAt,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  /// Create from Supabase row
  factory ProductModel.fromSupabase(Map<String, dynamic> row) {
    return ProductModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      sku: row['sku'] as String?,
      barcode: row['barcode'] as String?,
      costPrice: (row['cost_price'] as num?)?.toDouble() ?? 0,
      sellingPrice: (row['selling_price'] as num).toDouble(),
      stockQuantity: (row['stock_quantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (row['low_stock_threshold'] as num?)?.toInt() ?? 10,
      category: ProductCategory.values.firstWhere(
        (c) => c.name == row['category'],
        orElse: () => ProductCategory.other,
      ),
      imageUrl: row['image_url'] as String?,
      isActive: row['is_active'] as bool? ?? true,
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
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'category': category.name,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  /// Check if stock is low
  bool get isLowStock =>
      stockQuantity > 0 && stockQuantity <= lowStockThreshold;

  /// Check if out of stock
  bool get isOutOfStock => stockQuantity <= 0;

  /// Get stock status
  StockStatus get stockStatus {
    if (isOutOfStock) return StockStatus.outOfStock;
    if (isLowStock) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  /// Calculate profit margin percentage
  double get profitMargin {
    if (costPrice <= 0) return 0;
    return ((sellingPrice - costPrice) / costPrice) * 100;
  }

  /// Calculate profit per unit
  double get profitPerUnit => sellingPrice - costPrice;

  /// Calculate total stock value (at selling price)
  double get stockValue => stockQuantity * sellingPrice;

  /// Calculate total stock cost
  double get stockCost => stockQuantity * costPrice;

  /// Formatted selling price
  String get formattedPrice => '₹${sellingPrice.toStringAsFixed(2)}';

  /// Formatted stock value
  String get formattedStockValue => '₹${stockValue.toStringAsFixed(2)}';
}
