import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/stock_movement_model.dart';
import '../../data/services/invoice_service.dart';
import '../../data/services/product_service.dart';
import 'auth_provider.dart';

/// Cart item model
class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.sellingPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}

/// POS state model
class PosState {
  final List<CartItem> items;
  final CustomerModel? selectedCustomer;
  final bool isProcessing;
  final String? error;

  const PosState({
    this.items = const [],
    this.selectedCustomer,
    this.isProcessing = false,
    this.error,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get taxRate => 18.0; // GST 18%
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  PosState copyWith({
    List<CartItem>? items,
    CustomerModel? selectedCustomer,
    bool? isProcessing,
    String? error,
    bool clearCustomer = false,
  }) {
    return PosState(
      items: items ?? this.items,
      selectedCustomer: clearCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

/// POS Notifier for cart operations
class PosNotifier extends StateNotifier<PosState> {
  final Ref _ref;
  final ProductService _productService;
  final InvoiceService _invoiceService;

  PosNotifier(this._ref, this._productService, this._invoiceService)
    : super(const PosState());

  /// Add product to cart by barcode
  Future<bool> addProductByBarcode(String barcode) async {
    state = state.copyWith(error: null);

    try {
      final product = await _productService.getProductByBarcode(barcode);
      if (product == null) {
        state = state.copyWith(
          error: 'Product not found for barcode: $barcode',
        );
        return false;
      }

      if (product.isOutOfStock) {
        state = state.copyWith(error: '${product.name} is out of stock');
        return false;
      }

      addProduct(product);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Add product to cart
  void addProduct(ProductModel product, {int quantity = 1}) {
    final items = List<CartItem>.from(state.items);
    final existingIndex = items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      final existing = items[existingIndex];
      final newQuantity = existing.quantity + quantity;

      // Check stock
      if (newQuantity > product.stockQuantity) {
        state = state.copyWith(
          error: 'Only ${product.stockQuantity} ${product.name} available',
        );
        return;
      }

      items[existingIndex] = existing.copyWith(quantity: newQuantity);
    } else {
      if (quantity > product.stockQuantity) {
        state = state.copyWith(
          error: 'Only ${product.stockQuantity} ${product.name} available',
        );
        return;
      }
      items.add(CartItem(product: product, quantity: quantity));
    }

    state = state.copyWith(items: items, error: null);
  }

  /// Update quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }

    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      final item = items[index];
      if (quantity > item.product.stockQuantity) {
        state = state.copyWith(
          error: 'Only ${item.product.stockQuantity} available',
        );
        return;
      }
      items[index] = item.copyWith(quantity: quantity);
      state = state.copyWith(items: items, error: null);
    }
  }

  /// Remove product from cart
  void removeProduct(String productId) {
    final items = state.items
        .where((item) => item.product.id != productId)
        .toList();
    state = state.copyWith(items: items, error: null);
  }

  /// Set customer
  void setCustomer(CustomerModel? customer) {
    state = state.copyWith(
      selectedCustomer: customer,
      clearCustomer: customer == null,
    );
  }

  /// Clear cart
  void clearCart() {
    state = const PosState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Checkout - create invoice and deduct stock
  Future<InvoiceModel?> checkout() async {
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Cart is empty');
      return null;
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) {
        state = state.copyWith(isProcessing: false, error: 'Not authenticated');
        return null;
      }

      // Create invoice items from cart
      final invoiceItems = state.items.map((cartItem) {
        return InvoiceItem(
          description: cartItem.product.name,
          quantity: cartItem.quantity.toDouble(),
          unitPrice: cartItem.product.sellingPrice,
          amount: cartItem.total,
        );
      }).toList();

      // Create invoice
      final invoice = InvoiceModel(
        id: '',
        userId: userId,
        customerId: state.selectedCustomer?.id,
        customerName: state.selectedCustomer?.name,
        invoiceNumber: _generateInvoiceNumber(),
        status: InvoiceStatus.paid, // Mark as paid immediately for POS
        subtotal: state.subtotal,
        taxRate: state.taxRate,
        taxAmount: state.taxAmount,
        total: state.total,
        issueDate: DateTime.now(),
        items: invoiceItems,
      );

      // Save invoice
      final savedInvoice = await _invoiceService.createInvoice(
        invoice,
        invoiceItems,
      );

      // Deduct stock for each item
      for (final cartItem in state.items) {
        await _productService.adjustStock(
          productId: cartItem.product.id,
          quantity: cartItem.quantity,
          movementType: MovementType.sale,
          notes: 'Sale - Invoice ${savedInvoice.invoiceNumber}',
          referenceId: savedInvoice.id,
        );
      }

      // Clear cart
      state = const PosState();

      return savedInvoice;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return null;
    }
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(5);
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}$timestamp';
  }
}

/// POS provider
final posProvider = StateNotifierProvider<PosNotifier, PosState>((ref) {
  return PosNotifier(ref, ProductService.instance, InvoiceService.instance);
});

/// Cart items count provider
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(posProvider).totalItems;
});

/// Cart total provider
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(posProvider).total;
});
