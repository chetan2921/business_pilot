import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/product_model.dart';
import '../models/stock_movement_model.dart';

/// Service for product and inventory CRUD operations
class ProductService {
  ProductService._();
  static final ProductService _instance = ProductService._();
  static ProductService get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;
  static const String _tableName = 'products';
  static const String _movementsTable = 'stock_movements';

  /// Get all products with optional filters
  Future<List<ProductModel>> getProducts({
    ProductCategory? category,
    bool? isActive,
    bool? lowStockOnly,
    String? searchQuery,
  }) async {
    var query = _client.from(_tableName).select();

    if (category != null) {
      query = query.eq('category', category.name);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    if (lowStockOnly == true) {
      // Get products where stock_quantity <= low_stock_threshold
      query = query.filter('stock_quantity', 'lte', 'low_stock_threshold');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
        'name.ilike.%$searchQuery%,sku.ilike.%$searchQuery%,barcode.ilike.%$searchQuery%',
      );
    }

    final response = await query.order('name');

    return (response as List)
        .map((row) => ProductModel.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  /// Get product by ID
  Future<ProductModel?> getProductById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ProductModel.fromSupabase(response);
  }

  /// Get product by barcode
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('barcode', barcode)
        .maybeSingle();

    if (response == null) return null;
    return ProductModel.fromSupabase(response);
  }

  /// Create new product
  Future<ProductModel> createProduct(ProductModel product) async {
    final response = await _client
        .from(_tableName)
        .insert(product.toSupabase())
        .select()
        .single();

    final newProduct = ProductModel.fromSupabase(response);

    // Record initial stock if any
    if (product.stockQuantity > 0) {
      await _recordMovement(
        productId: newProduct.id,
        quantity: product.stockQuantity,
        type: MovementType.purchase,
        notes: 'Initial stock',
      );
    }

    return newProduct;
  }

  /// Update product
  Future<ProductModel> updateProduct(ProductModel product) async {
    await _client
        .from(_tableName)
        .update(product.toSupabase())
        .eq('id', product.id);

    return getProductById(product.id).then((p) => p!);
  }

  /// Delete product
  Future<void> deleteProduct(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  /// Adjust stock quantity
  Future<ProductModel> adjustStock({
    required String productId,
    required int quantity,
    required MovementType movementType,
    String? notes,
    String? referenceId,
  }) async {
    // Get current product
    final product = await getProductById(productId);
    if (product == null) {
      throw Exception('Product not found');
    }

    // Calculate new quantity
    final netChange = movementType.isAddition ? quantity : -quantity;
    final newQuantity = product.stockQuantity + netChange;

    if (newQuantity < 0) {
      throw Exception('Insufficient stock');
    }

    // Update product stock
    await _client
        .from(_tableName)
        .update({'stock_quantity': newQuantity})
        .eq('id', productId);

    // Record movement
    await _recordMovement(
      productId: productId,
      quantity: quantity,
      type: movementType,
      notes: notes,
      referenceId: referenceId,
    );

    return getProductById(productId).then((p) => p!);
  }

  /// Record stock movement
  Future<void> _recordMovement({
    required String productId,
    required int quantity,
    required MovementType type,
    String? notes,
    String? referenceId,
  }) async {
    final movement = StockMovementModel(
      id: '',
      productId: productId,
      quantity: quantity,
      movementType: type,
      notes: notes,
      referenceId: referenceId,
    );

    await _client.from(_movementsTable).insert(movement.toSupabase());
  }

  /// Get stock movements for a product
  Future<List<StockMovementModel>> getStockMovements(String productId) async {
    final response = await _client
        .from(_movementsTable)
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) => StockMovementModel.fromSupabase(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get low stock products
  Future<List<ProductModel>> getLowStockProducts() async {
    final allProducts = await getProducts(isActive: true);
    return allProducts.where((p) => p.isLowStock || p.isOutOfStock).toList();
  }

  /// Get inventory stats
  Future<Map<String, dynamic>> getInventoryStats() async {
    final products = await getProducts(isActive: true);

    int totalProducts = products.length;
    int lowStockCount = 0;
    int outOfStockCount = 0;
    double totalStockValue = 0;
    double totalStockCost = 0;

    for (final product in products) {
      totalStockValue += product.stockValue;
      totalStockCost += product.stockCost;
      if (product.isOutOfStock) {
        outOfStockCount++;
      } else if (product.isLowStock) {
        lowStockCount++;
      }
    }

    return {
      'totalProducts': totalProducts,
      'lowStockCount': lowStockCount,
      'outOfStockCount': outOfStockCount,
      'totalStockValue': totalStockValue,
      'totalStockCost': totalStockCost,
      'potentialProfit': totalStockValue - totalStockCost,
    };
  }

  /// Generate SKU for a product
  String generateSku(String name, ProductCategory category) {
    final prefix = category.name.substring(0, 3).toUpperCase();
    final namePart = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final shortName = namePart.length > 4 ? namePart.substring(0, 4) : namePart;
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(8);
    return '$prefix-$shortName-$timestamp';
  }
}
