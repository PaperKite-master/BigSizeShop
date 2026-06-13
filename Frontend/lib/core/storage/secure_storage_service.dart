import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) {
    return _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> readToken() {
    return _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() {
    return _storage.delete(key: AppConstants.tokenKey);
  }
}
