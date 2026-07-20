import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/cart/models/checkout_details.dart';
import '../features/admin/screens/admin_screens.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/profile_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/products/screens/product_detail_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/cart/screens/checkout_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/cart/screens/order_confirmation_screen.dart';
import '../features/admin/screens/admin_orders_screen.dart';
import '../features/admin/screens/admin_add_product_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/payments/screens/payment_result_screen.dart';
import '../features/store/screens/store_map_screen.dart';
import '../providers/app_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      if (authState.isLoading) {
        return null;
      }

      final user = authState.value;
      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/register';
      final requiresAuthentication = path == '/profile' ||
          path == '/cart' ||
          path == '/checkout' ||
          path == '/order-confirm' ||
          path == '/payment' ||
          path == '/orders' ||
          path == '/chat' ||
          path.startsWith('/chat/') ||
          path == '/admin' ||
          path.startsWith('/admin/');

      if (user == null && requiresAuthentication) {
        final returnTo = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$returnTo';
      }

      if (user != null && isAuthRoute) {
        final returnTo = state.uri.queryParameters['from'];
        if (returnTo != null &&
            returnTo.startsWith('/') &&
            !returnTo.startsWith('/login') &&
            !returnTo.startsWith('/register')) {
          return returnTo;
        }
        return '/';
      }

      if ((path == '/admin' || path.startsWith('/admin/')) &&
          !(user?.isAdmin ?? false)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/order-confirm',
        builder: (context, state) {
          final details =
              state.extra is CheckoutDetails ? state.extra! as CheckoutDetails : null;
          return OrderConfirmationScreen(details: details);
        },
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => PaymentResultScreen(
          orderId: state.uri.queryParameters['orderId'],
          startPayment: state.uri.queryParameters['start'] == 'true',
        ),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/categories',
        builder: (context, state) => const AdminCategoriesScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/add-product',
        builder: (context, state) => const AdminAddProductScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) => ChatScreen(
          chatId: state.pathParameters['chatId']!,
        ),
      ),
      GoRoute(
        path: '/stores',
        builder: (context, state) => const StoreMapScreen(),
      ),
    ],
  );

  ref.listen(authControllerProvider, (previous, next) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
