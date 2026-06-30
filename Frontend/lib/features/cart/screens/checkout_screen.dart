import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../providers/address_providers.dart';
import '../../../providers/cart_providers.dart';
import '../../../providers/order_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final Color vgMidnight = const Color(0xFF0F1E36);
  final Color vgCyanSky = const Color(0xFF1C528B);
  final Color vgStarGold = const Color(0xFFF3C63F);
  final Color vgCypressGreen = const Color(0xFF233B2B);

  String? _selectedAddressId;
  String _selectedPaymentMethod = 'COD';
  bool _isSubmitting = false;

  // Controllers for new address form
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _streetController = TextEditingController();
  bool _isDefaultAddress = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _openAddAddressDialog() {
    // Clear fields
    _nameController.clear();
    _phoneController.clear();
    _provinceController.clear();
    _districtController.clear();
    _wardController.clear();
    _streetController.clear();
    _isDefaultAddress = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFF8F9FA),
          title: Text(
            'Add New Address',
            style: TextStyle(fontFamily: 'serif', color: vgMidnight, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Receiver Name *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Receiver Phone *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _provinceController,
                  decoration: const InputDecoration(labelText: 'Province / City'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _districtController,
                  decoration: const InputDecoration(labelText: 'District'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _wardController,
                  decoration: const InputDecoration(labelText: 'Ward'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _streetController,
                  decoration: const InputDecoration(labelText: 'Street Address *'),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text('Set as default address'),
                  value: _isDefaultAddress,
                  activeColor: vgCyanSky,
                  onChanged: (val) {
                    setDialogState(() {
                      _isDefaultAddress = val ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty ||
                    _phoneController.text.trim().isEmpty ||
                    _streetController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields (*)')),
                  );
                  return;
                }

                ref.read(addressesProvider.notifier).addAddress(
                      receiverName: _nameController.text.trim(),
                      receiverPhone: _phoneController.text.trim(),
                      province: _provinceController.text.trim().isEmpty ? null : _provinceController.text.trim(),
                      district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
                      ward: _wardController.text.trim().isEmpty ? null : _wardController.text.trim(),
                      streetAddress: _streetController.text.trim(),
                      isDefault: _isDefaultAddress,
                    );

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: vgCyanSky, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitOrder(double totalPrice) async {
    if (_selectedAddressId == null) {
      AppSnackBar.showError(context, 'Please select a delivery address');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(ordersProvider.notifier).placeOrder(
            addressId: _selectedAddressId,
            paymentMethod: _selectedPaymentMethod,
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
                  style: TextStyle(fontFamily: 'serif', color: vgMidnight, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Thank you! Your order was successfully created.\nTotal Amount: ${formatCurrency(totalPrice + 30000)}',
              style: TextStyle(color: vgMidnight),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.go('/orders'); // Route to orders screen
                },
                style: ElevatedButton.styleFrom(backgroundColor: vgStarGold, foregroundColor: vgMidnight),
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
    final addressesAsync = ref.watch(addressesProvider);

    // Set default selected address ID when addresses list is resolved
    addressesAsync.whenData((addresses) {
      if (_selectedAddressId == null && addresses.isNotEmpty) {
        final def = addresses.where((a) => a.isDefault).toList();
        final defaultId = def.isNotEmpty ? def.first.id : addresses.first.id;
        Future.microtask(() {
          if (mounted && _selectedAddressId == null) {
            setState(() {
              _selectedAddressId = defaultId;
            });
          }
        });
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
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
                'Checkout',
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
                onPressed: () => context.go('/cart'),
              ),
            ),
            body: cartAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(message: error.toString()),
              data: (cartItems) {
                if (cartItems.isEmpty) {
                  return const EmptyView(message: 'Your cart is empty. Nothing to checkout!');
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
                          // 1. Delivery Address Section
                          _buildSectionTitle('1. Delivery Address'),
                          const SizedBox(height: 8),
                          addressesAsync.when(
                            loading: () => const LoadingView(),
                            error: (err, _) => Text('Error loading addresses: $err', style: const TextStyle(color: Colors.white70)),
                            data: (addresses) {
                              if (addresses.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'No saved addresses.',
                                        style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: _openAddAddressDialog,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Address'),
                                        style: ElevatedButton.styleFrom(backgroundColor: vgStarGold, foregroundColor: vgMidnight),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                children: [
                                  ...addresses.map((address) {
                                    final isSelected = _selectedAddressId == address.id;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedAddressId = address.id;
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFFFFDF2) : Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected ? vgStarGold : Colors.transparent,
                                            width: isSelected ? 2.5 : 0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Radio<String>(
                                              value: address.id,
                                              groupValue: _selectedAddressId,
                                              activeColor: vgCyanSky,
                                              onChanged: (val) {
                                                setState(() {
                                                  _selectedAddressId = val;
                                                });
                                              },
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        address.receiverName,
                                                        style: TextStyle(fontWeight: FontWeight.bold, color: vgMidnight, fontSize: 15),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        address.receiverPhone,
                                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                                      ),
                                                      if (address.isDefault) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: vgCypressGreen.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            'Default',
                                                            style: TextStyle(color: vgCypressGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    address.fullAddressText,
                                                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: _openAddAddressDialog,
                                      icon: Icon(Icons.add, color: vgStarGold),
                                      label: Text('Add New Address', style: TextStyle(color: vgStarGold, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // 2. Payment Method Section
                          _buildSectionTitle('2. Payment Method'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                RadioListTile<String>(
                                  title: const Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  value: 'COD',
                                  groupValue: _selectedPaymentMethod,
                                  activeColor: vgCyanSky,
                                  secondary: const Icon(Icons.delivery_dining, color: Colors.amber),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedPaymentMethod = val!;
                                    });
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey.shade300),
                                RadioListTile<String>(
                                  title: const Text('Bank Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
                                  value: 'BANK',
                                  groupValue: _selectedPaymentMethod,
                                  activeColor: vgCyanSky,
                                  secondary: const Icon(Icons.account_balance, color: Colors.blue),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedPaymentMethod = val!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 3. Items Summary
                          _buildSectionTitle('3. Order Items'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: cartItems.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.product.name,
                                              style: TextStyle(fontWeight: FontWeight.bold, color: vgMidnight),
                                            ),
                                            if (item.variant != null)
                                              Text(
                                                'Variant: ${item.variant!.variantName}',
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'x${item.quantity}',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: vgMidnight),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        formatCurrency(item.totalPrice),
                                        style: TextStyle(fontWeight: FontWeight.bold, color: vgMidnight),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    // Cost Summary & Place Order Button
                    _buildCostSummaryPanel(subtotal, shippingFee, total),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'serif',
        shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
      ),
    );
  }

  Widget _buildCostSummaryPanel(double subtotal, double shippingFee, double total) {
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
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
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
                onPressed: _isSubmitting ? null : () => _submitOrder(subtotal),
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
                        'Place Order',
                        style: TextStyle(
                          color: vgStarGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'serif',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
