import '../core/network/api_client.dart';
import '../models/payment_model.dart';

class PaymentService {
  const PaymentService(this._client);

  final ApiClient _client;

  Future<Uri> createVnPayUrl(String orderId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/payments/vnpay/create',
      data: {'orderId': orderId},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final paymentUrl = Uri.tryParse(data['paymentUrl'] as String? ?? '');
    if (paymentUrl == null || !paymentUrl.hasScheme) {
      throw const FormatException(
        'The payment gateway returned an invalid URL.',
      );
    }
    return paymentUrl;
  }

  Future<PaymentStatusModel> getOrderPaymentStatus(String orderId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/payments/orders/$orderId/status',
    );
    return PaymentStatusModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }
}
