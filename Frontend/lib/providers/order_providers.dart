import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import 'app_providers.dart';
import 'cart_providers.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref.watch(apiClientProvider));
});

final ordersProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<List<OrderModel>>>((ref) {
  return OrderNotifier(ref);
});

class OrderNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  OrderNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen(authControllerProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          fetchOrders();
        } else {
          state = const AsyncValue.data([]);
        }
      });
    });

    final user = _ref.read(authControllerProvider).value;
    if (user != null) {
      fetchOrders();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  final Ref _ref;

  OrderService get _orderService => _ref.read(orderServiceProvider);

  Future<void> fetchOrders() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _orderService.getOrders();
    });
  }

  Future<OrderModel> placeOrder({
    String? addressId,
    String? addressText,
    required String paymentMethod,
  }) async {
    // We don't want to change the whole list state to loading before order placement
    // to keep the checkout screen details active. So we just run the request directly.
    try {
      final order = await _orderService.placeOrder(
        addressId: addressId,
        addressText: addressText,
        paymentMethod: paymentMethod,
      );

      // Clear the local cart
      _ref.read(cartControllerProvider.notifier).clearCartLocal();

      // Refresh the orders history list
      fetchOrders();

      return order;
    } catch (e) {
      rethrow;
    }
  }
}
