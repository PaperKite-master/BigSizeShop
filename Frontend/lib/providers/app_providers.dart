import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/storage/sqlite_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/local_product_repository.dart';
import '../services/product_service.dart';

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => const SecureStorageService(FlutterSecureStorage()),
);

final sqliteServiceProvider = Provider<SqliteService>((ref) {
  final service = SqliteService();
  ref.onDispose(() {
    service.close();
  });
  return service;
});

final localProductRepositoryProvider = Provider<LocalProductRepository>((ref) {
  return LocalProductRepository(ref.watch(sqliteServiceProvider));
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStorageProvider));
});

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(apiClientProvider)),
);

final categoryServiceProvider = Provider<CategoryService>(
  (ref) => CategoryService(ref.watch(apiClientProvider)),
);

final productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(
    ref.watch(apiClientProvider),
    ref.watch(localProductRepositoryProvider),
  ),
);

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>(
  (ref) => AuthController(ref),
);

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  AuthController(this._ref) : super(const AsyncValue.loading()) {
    _restoreSession();
  }

  final Ref _ref;

  AuthService get _authService => _ref.read(authServiceProvider);
  SecureStorageService get _storage => _ref.read(secureStorageProvider);

  Future<void> _restoreSession() async {
    try {
      final token = await _storage.readToken();

      if (token == null || token.isEmpty) {
        state = const AsyncValue.data(null);
        return;
      }

      final user = await _authService.me();
      state = AsyncValue.data(user);
    } catch (_) {
      await _storage.deleteToken();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final session = await _authService.login(email: email, password: password);
      await _storage.saveToken(session.token);
      return session.user;
    });
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    await _authService.register(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
    );
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // Token may already be invalid; still clear local session.
    }

    await _storage.deleteToken();
    state = const AsyncValue.data(null);
  }
}
