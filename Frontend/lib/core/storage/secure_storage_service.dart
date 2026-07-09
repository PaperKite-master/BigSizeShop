import 'secure_storage_impl.dart'
    if (dart.library.html) 'secure_storage_web_impl.dart';

import '../constants/app_constants.dart';

class SecureStorageService {
  const SecureStorageService();

  static const SecureStorageImpl _impl = SecureStorageImpl();

  Future<void> saveToken(String token) {
    return _impl.write(AppConstants.tokenKey, token);
  }

  Future<String?> readToken() {
    return _impl.read(AppConstants.tokenKey);
  }

  Future<void> deleteToken() {
    return _impl.delete(AppConstants.tokenKey);
  }
}
