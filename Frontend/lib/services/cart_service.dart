import '../core/network/api_client.dart';
import '../models/cart_item_model.dart';

class CartService {
  const CartService(this._client);

  final ApiClient _client;

  Future<List<CartItemModel>> getCart() async {
    final response = await _client.get<Map<String, dynamic>>('/cart');
    final list = response.data!['data'] as List<dynamic>;
    return list.map((item) => CartItemModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<CartItemModel> addToCart({
    required String productId,
    required int quantity,
    String? variantId,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/cart',
      data: {
        'productId': productId,
        'quantity': quantity,
        if (variantId != null) 'variantId': variantId,
      },
    );
    return CartItemModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<CartItemModel> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/cart/$cartItemId',
      data: {
        'quantity': quantity,
      },
    );
    return CartItemModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> removeFromCart(String cartItemId) async {
    await _client.delete<Map<String, dynamic>>('/cart/$cartItemId');
  }
}
