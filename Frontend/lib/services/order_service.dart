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
        'address': addressText ?? 'string',
        'paymentMethod': paymentMethod,
      },
    );
    return OrderModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<OrderModel> cancelOrder(String orderId) async {
    final response = await _client.dio.patch<Map<String, dynamic>>('/orders/$orderId/cancel');
    return OrderModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<OrderModel> updateOrderStatus(String orderId, String status) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/orders/$orderId/status',
      data: {'status': status},
    );
    return OrderModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
