import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:big_size_shop/features/cart/screens/order_confirmation_screen.dart';

void main() {
  testWidgets('confirmation without checkout state offers recovery',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OrderConfirmationScreen()),
      ),
    );

    expect(
      find.text(
        'Checkout details are missing. Please return to checkout and select a delivery address.',
      ),
      findsOneWidget,
    );
    expect(find.text('Back to checkout'), findsOneWidget);
  });
}
