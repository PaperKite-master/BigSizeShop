import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../providers/cart_providers.dart';
import '../../../providers/order_providers.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.paymentMethod,
  });

  final String paymentMethod;

  @override
  ConsumerState<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends ConsumerState<OrderConfirmationScreen> {
  final Color vgMidnight = const Color(0xFF0F1E36);
  final Color vgCyanSky = const Color(0xFF1C528B);
  final Color vgStarGold = const Color(0xFFF3C63F);
  final Color vgCypressGreen = const Color(0xFF233B2B);

  bool _isSubmitting = false;

  void _confirmAndPlaceOrder(double subtotal) async {
    setState(() => _isSubmitting = true);

    try {
      // Place the order on the backend with 'string' as the address
      await ref.read(ordersProvider.notifier).placeOrder(
            addressText: 'string',
            paymentMethod: widget.paymentMethod,
          );

      // Show Success Dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFFFDFCF7),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: vgCypressGreen, size: 30),
                const SizedBox(width: 8),
                Text(
                  'Order Placed!',
                  style: TextStyle(
                    fontFamily: 'serif',
                    color: vgMidnight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Thank you! Your order has been successfully created.\nTotal Amount: ${formatCurrency(subtotal + 30000)}',
              style: TextStyle(color: vgMidnight),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.go('/orders'); // Route to orders screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: vgStarGold,
                  foregroundColor: vgMidnight,
                ),
                child: const Text('View My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient matching checkout screen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [vgMidnight, vgCyanSky, vgMidnight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text(
                'Confirm Order',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  color: Color(0xFF0F1E36),
                ),
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      vgStarGold.withOpacity(0.95),
                      const Color(0xFFF1C40F).withOpacity(0.80),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: vgMidnight),
                onPressed: () => context.go('/checkout'),
              ),
            ),
            body: cartAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(message: error.toString()),
              data: (cartItems) {
                if (cartItems.isEmpty) {
                  return const EmptyView(message: 'Your cart is empty.');
                }

                double subtotal = cartItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
                double shippingFee = 30000;
                double total = subtotal + shippingFee;

                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // 1. Order Confirmation Header Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: vgStarGold, size: 24),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Order Summary Details',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'serif',
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white24, height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Address:', style: TextStyle(color: Colors.white70)),
                                    Text(
                                      'string',
                                      style: TextStyle(
                                        color: vgStarGold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Payment Method:', style: TextStyle(color: Colors.white70)),
                                    Text(
                                      widget.paymentMethod,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. Items List Section Title
                          const Text(
                            'Items to Buy',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'serif',
                              shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 3. Items list
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: cartItems.map((item) {
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Thumbnail Image
                                          if (item.product.displayImage.isNotEmpty)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                item.product.displayImage,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(Icons.image_not_supported, size: 24),
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.image, size: 24),
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.product.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: vgMidnight,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                if (item.variant != null)
                                                  Text(
                                                    'Variant: ${item.variant!.variantName}',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${formatCurrency(item.unitPrice)} x ${item.quantity}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            formatCurrency(item.totalPrice),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: vgMidnight,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item != cartItems.last)
                                      Divider(height: 1, color: Colors.grey.shade300),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),

                    // Cost Summary & Confirmation Actions
                    _buildConfirmationPanel(subtotal, shippingFee, total),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationPanel(double subtotal, double shippingFee, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items total', style: TextStyle(color: Colors.grey.shade600)),
                Text(formatCurrency(subtotal), style: TextStyle(fontWeight: FontWeight.bold, color: vgMidnight)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Shipping fee', style: TextStyle(color: Colors.grey.shade600)),
                Text(formatCurrency(shippingFee), style: TextStyle(fontWeight: FontWeight.bold, color: vgMidnight)),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order total',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatCurrency(total),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: vgMidnight,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Cancel/Back Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => context.go('/checkout'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: vgMidnight, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: vgMidnight,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm & Place Order Button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [vgCyanSky, vgMidnight],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: vgCyanSky.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _confirmAndPlaceOrder(subtotal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Confirm Order',
                              style: TextStyle(
                                color: vgStarGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'serif',
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
