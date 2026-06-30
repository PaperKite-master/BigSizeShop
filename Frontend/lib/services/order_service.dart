import '../core/network/api_client.dart';
import '../models/order_model.dart';

class OrderService {
  const OrderService(this._client);

  final ApiClient _client;

  Future<List<OrderModel>> getOrders() async {
    final response = await _client.get<Map<String, dynamic>>('/orders');
    final list = response.data!['data'] as List<dynamic>;
    return list.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<OrderModel> placeOrder({
    String? addressId,
    String? addressText,
    required String paymentMethod,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/orders',
      data: {
        if (addressId != null) 'addressId': addressId,
        if (addressText != null) 'addressText': addressText,
        'paymentMethod': paymentMethod,
      },
    );
    return OrderModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
