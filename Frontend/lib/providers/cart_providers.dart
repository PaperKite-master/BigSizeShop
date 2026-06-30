import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item_model.dart';
import '../services/cart_service.dart';
import 'app_providers.dart';

final cartServiceProvider = Provider<CartService>((ref) {
  return CartService(ref.watch(apiClientProvider));
});

final cartControllerProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<CartItemModel>>>((ref) {
  return CartNotifier(ref);
});

final cartBadgeCountProvider = Provider<int>((ref) {
  final cartAsync = ref.watch(cartControllerProvider);
  return cartAsync.maybeWhen(
    data: (items) => items.fold<int>(0, (sum, item) => sum + item.quantity),
    orElse: () => 0,
  );
});

class CartNotifier extends StateNotifier<AsyncValue<List<CartItemModel>>> {
  CartNotifier(this._ref) : super(const AsyncValue.loading()) {
    // Automatically load cart on start if user is logged in
    _ref.listen(authControllerProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          fetchCart();
        } else {
          state = const AsyncValue.data([]);
        }
      });
    });

    // Initial load check
    final user = _ref.read(authControllerProvider).value;
    if (user != null) {
      fetchCart();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  final Ref _ref;
  final Map<String, Timer> _debounceTimers = {};

  CartService get _cartService => _ref.read(cartServiceProvider);

  @override
  void dispose() {
    for (var timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> fetchCart() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _cartService.getCart();
    });
  }

  Future<void> addToCart({
    required String productId,
    required int quantity,
    String? variantId,
  }) async {
    // Show loading while performing operations
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _cartService.addToCart(
        productId: productId,
        quantity: quantity,
        variantId: variantId,
      );
      return await _cartService.getCart();
    });
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    final currentItems = state.value;
    if (currentItems == null) return;

    // 1. Instantly update UI locally
    final updatedItems = currentItems.map((item) {
      if (item.id == cartItemId) {
        return CartItemModel(
          id: item.id,
          userId: item.userId,
          productId: item.productId,
          quantity: quantity,
          variantId: item.variantId,
          product: item.product,
          variant: item.variant,
        );
      }
      return item;
    }).toList();

    state = AsyncValue.data(updatedItems);

    // 2. Debounced API Update call
    _debounceTimers[cartItemId]?.cancel();
    _debounceTimers[cartItemId] = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _cartService.updateQuantity(cartItemId: cartItemId, quantity: quantity);
      } catch (e) {
        // Revert to server state on error
        fetchCart();
      }
    });
  }

  Future<void> removeFromCart({required String cartItemId}) async {
    final currentItems = state.value;
    if (currentItems == null) return;

    // 1. Instantly update UI locally
    state = AsyncValue.data(
      currentItems.where((item) => item.id != cartItemId).toList(),
    );

    // 2. Cancel any pending debounce timers for this item
    _debounceTimers[cartItemId]?.cancel();

    // 3. Make API request
    try {
      await _cartService.removeFromCart(cartItemId);
    } catch (_) {
      // Revert to server state on error
      fetchCart();
    }
  }

  void clearCartLocal() {
    state = const AsyncValue.data([]);
  }
}
