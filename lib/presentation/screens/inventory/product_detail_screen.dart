import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/stock_movement_model.dart';
import '../../../data/services/barcode_generator_service.dart';
import '../../../data/services/product_service.dart';
import '../../providers/product_provider.dart';
import 'barcode_print_screen.dart';

/// Product detail screen with stock management
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductModel? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    final product = await ProductService.instance.getProductById(
      widget.productId,
    );
    setState(() {
      _product = product;
      _isLoading = false;
    });
  }

  void _openBarcodePrintScreen(ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodePrintScreen(product: product),
      ),
    );
  }

  Future<void> _generateAndSaveBarcode(ProductModel product) async {
    final barcode = BarcodeGeneratorService.instance.generateBarcodeData(
      product.id,
    );

    // Update product with generated barcode
    await ProductService.instance.updateProduct(
      product.copyWith(barcode: barcode),
    );

    // Refresh product
    await _loadProduct();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barcode generated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              const Text('Product not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await context.push(
                '${AppRoutes.addProduct}?edit=${widget.productId}',
              );
              _loadProduct();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProduct,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMd),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image/Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            product.category.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(product.category.label),
                                if (product.sku != null) ...[
                                  const Text(' • '),
                                  Text(
                                    product.sku!,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: product.isActive
                                    ? Colors.green.shade100
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                product.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: product.isActive
                                      ? Colors.green.shade800
                                      : Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pricing & Profit Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pricing',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: 'Cost Price',
                              value: currencyFormat.format(product.costPrice),
                              icon: Icons.money_off,
                              color: Colors.grey,
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              label: 'Selling Price',
                              value: currencyFormat.format(
                                product.sellingPrice,
                              ),
                              icon: Icons.attach_money,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: 'Profit/Unit',
                              value: currencyFormat.format(
                                product.profitPerUnit,
                              ),
                              icon: Icons.trending_up,
                              color: product.profitPerUnit >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              label: 'Margin',
                              value:
                                  '${product.profitMargin.toStringAsFixed(1)}%',
                              icon: Icons.percent,
                              color: product.profitMargin >= 20
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stock Management Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Inventory',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          _stockStatusBadge(product),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: 'In Stock',
                              value: '${product.stockQuantity} units',
                              icon: Icons.inventory,
                              color: _getStockColor(product.stockStatus),
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              label: 'Stock Value',
                              value: currencyFormat.format(product.stockValue),
                              icon: Icons.account_balance_wallet,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Low stock alert at ${product.lowStockThreshold} units',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showStockAdjustDialog(
                                context,
                                product,
                                MovementType.sale,
                              ),
                              icon: const Icon(Icons.remove),
                              label: const Text('Remove Stock'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _showStockAdjustDialog(
                                context,
                                product,
                                MovementType.purchase,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Stock'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stock Movement History
              Text(
                'Stock History',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, _) {
                  final movementsAsync = ref.watch(
                    stockMovementsProvider(widget.productId),
                  );
                  return movementsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Error loading history: $e')),
                    data: (movements) {
                      if (movements.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 48,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No stock movements yet',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: movements.length > 10
                              ? 10
                              : movements.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final movement = movements[index];
                            return _MovementTile(movement: movement);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Additional Info
              if (product.description != null &&
                  product.description!.isNotEmpty) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMd),
                    child: Text(product.description!),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (product.barcode != null) ...[
                Text(
                  'Barcode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMd),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.barcode_reader),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                product.barcode!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy barcode',
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: product.barcode!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Barcode copied'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _openBarcodePrintScreen(product),
                                icon: const Icon(Icons.print),
                                label: const Text('Print Label'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Barcode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMd),
                    child: Column(
                      children: [
                        Icon(
                          Icons.barcode_reader,
                          size: 48,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        const Text('No barcode assigned'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _generateAndSaveBarcode(product),
                          icon: const Icon(Icons.add),
                          label: const Text('Generate Barcode'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stockStatusBadge(ProductModel product) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (product.stockStatus) {
      case StockStatus.inStock:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        text = 'In Stock';
        break;
      case StockStatus.lowStock:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        text = 'Low Stock';
        break;
      case StockStatus.outOfStock:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        text = 'Out of Stock';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getStockColor(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return Colors.green;
      case StockStatus.lowStock:
        return Colors.orange;
      case StockStatus.outOfStock:
        return Colors.red;
    }
  }

  Future<void> _showStockAdjustDialog(
    BuildContext context,
    ProductModel product,
    MovementType defaultType,
  ) async {
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    MovementType selectedType = defaultType;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(defaultType.isAddition ? 'Add Stock' : 'Remove Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MovementType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Movement Type'),
                items: MovementType.values
                    .where((t) => t.isAddition == defaultType.isAddition)
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Enter quantity',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Reason for adjustment',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final quantity = int.tryParse(quantityController.text) ?? 0;
      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid quantity'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await ref
          .read(productNotifierProvider.notifier)
          .adjustStock(
            productId: product.id,
            quantity: quantity,
            movementType: selectedType,
            notes: notesController.text.isEmpty ? null : notesController.text,
          );

      if (success) {
        _loadProduct();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  final StockMovementModel movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAddition = movement.movementType.isAddition;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isAddition
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            movement.movementType.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(movement.movementType.displayName),
      subtitle: movement.createdAt != null
          ? Text(
              dateFormat.format(movement.createdAt!),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          : null,
      trailing: Text(
        '${isAddition ? '+' : '-'}${movement.quantity}',
        style: TextStyle(
          color: isAddition ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
