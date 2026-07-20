class PaymentStatusModel {
  const PaymentStatusModel({
    required this.orderId,
    required this.paymentStatus,
    this.paymentTransactionId,
    this.paidAt,
  });

  final String orderId;
  final String paymentStatus;
  final String? paymentTransactionId;
  final DateTime? paidAt;

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';

  factory PaymentStatusModel.fromJson(Map<String, dynamic> json) {
    final paidAtValue = json['paidAt'] ?? json['paid_at'];
    return PaymentStatusModel(
      orderId: (json['orderId'] ?? json['order_id']) as String,
      paymentStatus:
          (json['paymentStatus'] ?? json['payment_status']) as String? ??
          'PENDING',
      paymentTransactionId:
          (json['paymentTransactionId'] ?? json['payment_transaction_id'])
              as String?,
      paidAt: paidAtValue is String ? DateTime.tryParse(paidAtValue) : null,
    );
  }
}

class PaymentResultLink {
  const PaymentResultLink({
    required this.orderId,
    required this.success,
    this.responseCode,
  });

  final String orderId;
  final bool success;
  final String? responseCode;

  static PaymentResultLink? tryParse(Uri uri) {
    if (uri.scheme != 'bigsize-shop' || uri.host != 'payment-result') {
      return null;
    }

    final orderId = uri.queryParameters['orderId']?.trim();
    final successValue = uri.queryParameters['success'];
    if (orderId == null ||
        orderId.isEmpty ||
        (successValue != 'true' && successValue != 'false')) {
      return null;
    }

    return PaymentResultLink(
      orderId: orderId,
      success: successValue == 'true',
      responseCode: uri.queryParameters['responseCode'],
    );
  }
}
