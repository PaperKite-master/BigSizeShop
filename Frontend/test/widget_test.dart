import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:big_size_shop/app.dart';

void main() {
  testWidgets('renders the home architecture scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BigSizeShopApp()));
    await tester.pump();

    expect(find.text('BigSize Shop'), findsOneWidget);
    expect(find.text('E-commerce architecture scaffold'), findsOneWidget);
  });
}
