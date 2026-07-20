import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/payment_providers.dart';
import 'routes/app_router.dart';

class BigSizeShopApp extends ConsumerWidget {
  const BigSizeShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    ref.listen(paymentControllerProvider, (previous, next) {
      if (!next.fromDeepLink ||
          previous?.linkEvent == next.linkEvent ||
          next.linkEvent == 0) {
        return;
      }
      final location = Uri(
        path: '/payment',
        queryParameters: next.orderId == null
            ? null
            : <String, String>{'orderId': next.orderId!},
      ).toString();
      WidgetsBinding.instance.addPostFrameCallback((_) => router.go(location));
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}