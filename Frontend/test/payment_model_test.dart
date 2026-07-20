import 'package:big_size_shop/models/order_model.dart';
import 'package:big_size_shop/models/payment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentResultLink', () {
    test('parses the expected VNPay return link', () {
      final result = PaymentResultLink.tryParse(
        Uri.parse(
          'bigsize-shop://payment-result?orderId=order-123&success=true&responseCode=00',
        ),
      );

      expect(result, isNotNull);
      expect(result!.orderId, 'order-123');
      expect(result.success, isTrue);
      expect(result.responseCode, '00');
    });

    test('rejects malformed and unrelated links', () {
      expect(
        PaymentResultLink.tryParse(
          Uri.parse('bigsize-shop://payment-result?success=true'),
        ),
        isNull,
      );
      expect(
        PaymentResultLink.tryParse(
          Uri.parse(
            'bigsize-shop://payment-result?orderId=order-123&success=maybe',
          ),
        ),
        isNull,
      );
      expect(
        PaymentResultLink.tryParse(
          Uri.parse(
            'https://example.com/payment-result?orderId=order-123&success=true',
          ),
        ),
        isNull,
      );
    });
  });

  test('parses payment status and payment fields on an order', () {
    final status = PaymentStatusModel.fromJson({
      'orderId': 'order-123',
      'paymentStatus': 'PAID',
      'paymentTransactionId': 'txn-456',
      'paidAt': '2026-07-20T01:02:03.000Z',
    });
    final order = OrderModel.fromJson({
      'id': 'order-123',
      'userId': 'user-1',
      'totalPrice': '150000',
      'status': 'PENDING',
      'address': 'Test address',
      'paymentMethod': 'BANK',
      'paymentStatus': 'PAID',
      'paymentTransactionId': 'txn-456',
      'paidAt': '2026-07-20T01:02:03.000Z',
      'createdAt': '2026-07-20T01:00:00.000Z',
      'order_items': <dynamic>[],
    });

    expect(status.isPaid, isTrue);
    expect(status.paymentTransactionId, 'txn-456');
    expect(status.paidAt, DateTime.utc(2026, 7, 20, 1, 2, 3));
    expect(order.paymentStatus, 'PAID');
    expect(order.paymentTransactionId, 'txn-456');
    expect(order.paidAt, DateTime.utc(2026, 7, 20, 1, 2, 3));
  });
}
