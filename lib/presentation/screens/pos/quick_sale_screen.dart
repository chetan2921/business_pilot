import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/pos_provider.dart';

/// Quick Sale POS screen with barcode scanning
class QuickSaleScreen extends ConsumerStatefulWidget {
  const QuickSaleScreen({super.key});

  @override
  ConsumerState<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends ConsumerState<QuickSaleScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isScannerActive = true;
  String? _lastScannedCode;
  bool _isScanning = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isScanning || !_isScannerActive) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final code = barcode.rawValue!;
    if (code == _lastScannedCode) return;

    setState(() {
      _isScanning = true;
      _lastScannedCode = code;
    });

    // Add product to cart
    final success = await ref
        .read(posProvider.notifier)
        .addProductByBarcode(code);

    if (success && mounted) {
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Product added!'),
          duration: const Duration(milliseconds: 500),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Reset scan state after delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isScanning = false;
        _lastScannedCode = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    // Show error snackbar
    ref.listen<PosState>(posProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () => ref.read(posProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Sale'),
        centerTitle: true,
        actions: [
          if (posState.items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClearCart(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Scanner Section
          Container(
            height: 200,
            margin: const EdgeInsets.all(AppConstants.paddingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(color: colorScheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (_isScannerActive)
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onBarcodeDetected,
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 48,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        const Text('Scanner paused'),
                      ],
                    ),
                  ),
                // Scanner controls
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton.filled(
                        onPressed: () => _scannerController.toggleTorch(),
                        icon: const Icon(Icons.flash_on, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () => setState(
                          () => _isScannerActive = !_isScannerActive,
                        ),
                        icon: Icon(
                          _isScannerActive ? Icons.pause : Icons.play_arrow,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isScanning)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          // Customer Selection
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMd,
            ),
            child: _CustomerSelector(
              selectedCustomer: posState.selectedCustomer,
              onSelect: (customer) =>
                  ref.read(posProvider.notifier).setCustomer(customer),
            ),
          ),
          const SizedBox(height: 8),

          // Cart Items
          Expanded(
            child: posState.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Scan products to add',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMd,
                    ),
                    itemCount: posState.items.length,
                    itemBuilder: (context, index) {
                      final item = posState.items[index];
                      return _CartItemTile(
                        item: item,
                        currencyFormat: currencyFormat,
                        onQuantityChanged: (qty) => ref
                            .read(posProvider.notifier)
                            .updateQuantity(item.product.id, qty),
                        onRemove: () => ref
                            .read(posProvider.notifier)
                            .removeProduct(item.product.id),
                      );
                    },
                  ),
          ),

          // Checkout Section
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMd),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      Text(currencyFormat.format(posState.subtotal)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GST (${posState.taxRate.toStringAsFixed(0)}%)',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      Text(currencyFormat.format(posState.taxAmount)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormat.format(posState.total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: posState.items.isEmpty || posState.isProcessing
                        ? null
                        : () => _checkout(context),
                    icon: posState.isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payment),
                    label: Text(
                      posState.isProcessing ? 'Processing...' : 'Checkout',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkout(BuildContext context) async {
    final invoice = await ref.read(posProvider.notifier).checkout();

    if (invoice != null && mounted) {
      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Sale Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Invoice: ${invoice.invoiceNumber}'),
              const SizedBox(height: 8),
              Text(
                invoice.formattedTotal,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('New Sale'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('${AppRoutes.invoices}/${invoice.id}');
              },
              child: const Text('View Invoice'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirmClearCart(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('This will remove all items from the cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(posProvider.notifier).clearCart();
    }
  }
}

class _CustomerSelector extends ConsumerWidget {
  final CustomerModel? selectedCustomer;
  final ValueChanged<CustomerModel?> onSelect;

  const _CustomerSelector({
    required this.selectedCustomer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            selectedCustomer != null ? Icons.person : Icons.person_add,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: selectedCustomer != null
            ? Text(selectedCustomer!.name)
            : const Text('Walk-in Customer'),
        subtitle: selectedCustomer?.phone != null
            ? Text(selectedCustomer!.phone!)
            : const Text('Tap to select customer'),
        trailing: selectedCustomer != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => onSelect(null),
              )
            : const Icon(Icons.chevron_right),
        onTap: () => _showCustomerPicker(context, ref),
      ),
    );
  }

  Future<void> _showCustomerPicker(BuildContext context, WidgetRef ref) async {
    final customersAsync = ref.read(customersProvider);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Select Customer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onSelect(null);
                    },
                    child: const Text('Walk-in'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: customersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (customers) {
                  if (customers.isEmpty) {
                    return const Center(child: Text('No customers yet'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(customer.name[0].toUpperCase()),
                        ),
                        title: Text(customer.name),
                        subtitle: customer.phone != null
                            ? Text(customer.phone!)
                            : null,
                        trailing: selectedCustomer?.id == customer.id
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(customer);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final NumberFormat currencyFormat;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.currencyFormat,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  item.product.category.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currencyFormat.format(item.product.sellingPrice),
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            // Quantity controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => onQuantityChanged(item.quantity - 1),
                  visualDensity: VisualDensity.compact,
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => onQuantityChanged(item.quantity + 1),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            // Item total
            SizedBox(
              width: 70,
              child: Text(
                currencyFormat.format(item.total),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
