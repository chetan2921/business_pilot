import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product_model.dart';
import '../../data/models/stock_movement_model.dart';
import '../../data/services/product_service.dart';
import 'auth_provider.dart';

/// Product service provider
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService.instance;
});

/// Product filter class
class ProductFilter {
  final ProductCategory? category;
  final bool? isActive;
  final bool? lowStockOnly;
  final String? searchQuery;

  const ProductFilter({
    this.category,
    this.isActive,
    this.lowStockOnly,
    this.searchQuery,
  });

  ProductFilter copyWith({
    ProductCategory? category,
    bool? isActive,
    bool? lowStockOnly,
    String? searchQuery,
  }) {
    return ProductFilter(
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductFilter &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          isActive == other.isActive &&
          lowStockOnly == other.lowStockOnly &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode =>
      category.hashCode ^
      isActive.hashCode ^
      lowStockOnly.hashCode ^
      searchQuery.hashCode;
}

/// Current filter state provider
final productFilterProvider = StateProvider<ProductFilter>((ref) {
  return const ProductFilter(isActive: true);
});

/// Product loading state
final productLoadingProvider = StateProvider<bool>((ref) => false);

/// Product error state
final productErrorProvider = StateProvider<String?>((ref) => null);

/// Product notifier for managing product operations
class ProductNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final ProductService _service;
  final Ref _ref;

  ProductNotifier(this._service, this._ref)
    : super(const AsyncValue.loading()) {
    loadProducts();
  }

  /// Load products with current filter
  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    final filter = _ref.read(productFilterProvider);

    try {
      final products = await _service.getProducts(
        category: filter.category,
        isActive: filter.isActive,
        lowStockOnly: filter.lowStockOnly,
        searchQuery: filter.searchQuery,
      );
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add new product
  Future<bool> addProduct(ProductModel product) async {
    _ref.read(productLoadingProvider.notifier).state = true;
    _ref.read(productErrorProvider.notifier).state = null;

    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) {
      _ref.read(productErrorProvider.notifier).state = 'User not authenticated';
      _ref.read(productLoadingProvider.notifier).state = false;
      return false;
    }

    try {
      final productWithUser = ProductModel(
        id: '',
        userId: userId,
        name: product.name,
        description: product.description,
        sku: product.sku,
        barcode: product.barcode,
        costPrice: product.costPrice,
        sellingPrice: product.sellingPrice,
        stockQuantity: product.stockQuantity,
        lowStockThreshold: product.lowStockThreshold,
        category: product.category,
        imageUrl: product.imageUrl,
        isActive: product.isActive,
      );

      await _service.createProduct(productWithUser);
      _ref.read(productLoadingProvider.notifier).state = false;
      await loadProducts();
      return true;
    } catch (e) {
      _ref.read(productErrorProvider.notifier).state = e.toString();
      _ref.read(productLoadingProvider.notifier).state = false;
      return false;
    }
  }

  /// Update product
  Future<bool> updateProduct(ProductModel product) async {
    _ref.read(productLoadingProvider.notifier).state = true;
    _ref.read(productErrorProvider.notifier).state = null;

    try {
      await _service.updateProduct(product);
      _ref.read(productLoadingProvider.notifier).state = false;
      await loadProducts();
      return true;
    } catch (e) {
      _ref.read(productErrorProvider.notifier).state = e.toString();
      _ref.read(productLoadingProvider.notifier).state = false;
      return false;
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String id) async {
    _ref.read(productLoadingProvider.notifier).state = true;

    try {
      await _service.deleteProduct(id);
      _ref.read(productLoadingProvider.notifier).state = false;
      await loadProducts();
      return true;
    } catch (e) {
      _ref.read(productErrorProvider.notifier).state = e.toString();
      _ref.read(productLoadingProvider.notifier).state = false;
      return false;
    }
  }

  /// Adjust stock
  Future<bool> adjustStock({
    required String productId,
    required int quantity,
    required MovementType movementType,
    String? notes,
  }) async {
    _ref.read(productLoadingProvider.notifier).state = true;

    try {
      await _service.adjustStock(
        productId: productId,
        quantity: quantity,
        movementType: movementType,
        notes: notes,
      );
      _ref.read(productLoadingProvider.notifier).state = false;
      await loadProducts();
      return true;
    } catch (e) {
      _ref.read(productErrorProvider.notifier).state = e.toString();
      _ref.read(productLoadingProvider.notifier).state = false;
      return false;
    }
  }

  /// Search products
  void search(String query) {
    final currentFilter = _ref.read(productFilterProvider);
    _ref.read(productFilterProvider.notifier).state = currentFilter.copyWith(
      searchQuery: query.isEmpty ? null : query,
    );
    loadProducts();
  }

  /// Clear error
  void clearError() {
    _ref.read(productErrorProvider.notifier).state = null;
  }
}

/// Product notifier provider
final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<List<ProductModel>>>(
      (ref) => ProductNotifier(ref.watch(productServiceProvider), ref),
    );

/// Low stock products provider
final lowStockProductsProvider = FutureProvider<List<ProductModel>>((
  ref,
) async {
  final service = ref.watch(productServiceProvider);
  return service.getLowStockProducts();
});

/// Inventory stats provider
final inventoryStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.watch(productServiceProvider);
  return service.getInventoryStats();
});

/// Stock movements for a product provider
final stockMovementsProvider =
    FutureProvider.family<List<StockMovementModel>, String>((
      ref,
      productId,
    ) async {
      final service = ref.watch(productServiceProvider);
      return service.getStockMovements(productId);
    });

/// Product by barcode provider
final productByBarcodeProvider = FutureProvider.family<ProductModel?, String>((
  ref,
  barcode,
) async {
  final service = ref.watch(productServiceProvider);
  return service.getProductByBarcode(barcode);
});
