import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../models/order_model.dart';
import '../../../providers/order_providers.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final Color vgMidnight = const Color(0xFF0F1E36);
  final Color vgCyanSky = const Color(0xFF1C528B);
  final Color vgStarGold = const Color(0xFFF3C63F);
  final Color vgCypressGreen = const Color(0xFF233B2B);

  String _statusFilter = 'ALL'; // ALL, PENDING, CONFIRMED, SHIPPING, DELIVERED, CANCELLED
  bool _sortNewest = true; // true = Newest first, false = Oldest first

  final List<String> _filterOptions = [
    'ALL',
    'PENDING',
    'CONFIRMED',
    'SHIPPING',
    'DELIVERED',
    'CANCELLED'
  ];

  bool _matchesStatus(String orderStatus, String filter) {
    if (filter == 'ALL') return true;
    final statusUpper = orderStatus.toUpperCase();
    final filterUpper = filter.toUpperCase();

    if (filterUpper == 'CANCELLED' || filterUpper == 'CANCELED') {
      return statusUpper == 'CANCELLED' || statusUpper == 'CANCELED';
    }
    if (filterUpper == 'CONFIRMED') {
      return statusUpper == 'CONFIRMED' || statusUpper == 'PROCESSING';
    }
    if (filterUpper == 'SHIPPING') {
      return statusUpper == 'SHIPPING' || statusUpper == 'SHIPPED';
    }
    return statusUpper == filterUpper;
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient matching app theme
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
                'System Orders',
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
                onPressed: () => context.go('/'),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: vgMidnight),
                  onPressed: () => ref.invalidate(ordersProvider),
                ),
              ],
            ),
            body: Column(
              children: [
                // Filters and Sorting Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: Colors.black.withOpacity(0.2),
                  child: Column(
                    children: [
                      // Filter Chips List
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: _filterOptions.map((filter) {
                            final isSelected = _statusFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  filter,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? vgMidnight : Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: vgStarGold,
                                backgroundColor: const Color(0xFFFFF9E6),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _statusFilter = filter;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Sorting Toggle Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sort by Date:',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _sortNewest = !_sortNewest;
                                });
                              },
                              icon: Icon(
                                _sortNewest ? Icons.arrow_downward : Icons.arrow_upward,
                                color: vgStarGold,
                                size: 16,
                              ),
                              label: Text(
                                _sortNewest ? 'Newest First' : 'Oldest First',
                                style: TextStyle(
                                  color: vgStarGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Orders List
                Expanded(
                  child: ordersAsync.when(
                    loading: () => const LoadingView(),
                    error: (error, _) => ErrorView(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(ordersProvider),
                    ),
                    data: (orders) {
                      // 1. Filter orders
                      var filtered = orders
                          .where((o) => _matchesStatus(o.status, _statusFilter))
                          .toList();

                      // 2. Sort orders
                      filtered.sort((a, b) {
                        return _sortNewest
                            ? b.createdAt.compareTo(a.createdAt)
                            : a.createdAt.compareTo(b.createdAt);
                      });

                      if (filtered.isEmpty) {
                        return const EmptyView(
                          message: 'No system orders found matching filters.',
                          icon: Icons.receipt_long,
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final order = filtered[index];
                          return _buildOrderCard(order);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    final formattedDate =
        '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header with ID, User info and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID: #${order.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: vgMidnight, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'User ID: ${order.userId.substring(0, 8).toUpperCase()}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _mapToUiStatus(order.status),
                    icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 16),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    items: <String>['PENDING', 'CONFIRMED', 'SHIPPING', 'DELIVERED', 'CANCELLED']
                        .map((statusOption) {
                      return DropdownMenuItem<String>(
                        value: statusOption,
                        child: Text(statusOption),
                      );
                    }).toList(),
                    onChanged: (newStatus) async {
                      if (newStatus != null) {
                        try {
                          final apiStatus = _mapToApiStatus(newStatus);
                          await ref.read(ordersProvider.notifier).updateOrderStatus(order.id, apiStatus);
                          if (context.mounted) {
                            AppSnackBar.showSuccess(context, 'Order status updated to $newStatus');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppSnackBar.showError(context, e.toString());
                          }
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Items inside the order
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.orderItems.length,
            itemBuilder: (context, idx) {
              final item = order.orderItems[idx];
              final imageUrl = item.product.displayImage;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: TextStyle(fontWeight: FontWeight.bold, color: vgMidnight, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (item.variant != null) 'Variant: ${item.variant!.variantName}',
                              'Qty: ${item.quantity}',
                            ].join(' • '),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatCurrency(item.price * item.quantity),
                      style: TextStyle(fontWeight: FontWeight.bold, color: vgMidnight, fontSize: 13),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 16),

          // Footer info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment: ${order.paymentMethod}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: Text(
                      'To: ${order.address}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency(order.totalPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: vgMidnight,
                      fontSize: 15,
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported_outlined, size: 16),
    );
  }

  String _mapToUiStatus(String apiStatus) {
    final upper = apiStatus.toUpperCase();
    if (upper == 'PROCESSING') return 'CONFIRMED';
    if (upper == 'SHIPPED') return 'SHIPPING';
    if (upper == 'CANCELED') return 'CANCELLED';
    return upper;
  }

  String _mapToApiStatus(String uiStatus) {
    final upper = uiStatus.toUpperCase();
    if (upper == 'CONFIRMED') return 'PROCESSING';
    if (upper == 'SHIPPING') return 'SHIPPED';
    return upper;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange.shade700;
      case 'DELIVERED':
        return vgCypressGreen;
      case 'CANCELLED':
      case 'CANCELED':
        return Colors.red.shade700;
      case 'SHIPPED':
      case 'SHIPPING':
        return Colors.blue.shade700;
      case 'PROCESSING':
      case 'CONFIRMED':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
