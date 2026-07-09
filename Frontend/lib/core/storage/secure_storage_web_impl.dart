import 'package:web/web.dart';

/// Web: mỗi tab trình duyệt có sessionStorage riêng, tránh 2 tab dùng chung JWT.
class SecureStorageImpl {
  const SecureStorageImpl();

  Future<void> write(String key, String value) async {
    window.sessionStorage.setItem(key, value);
  }

  Future<String?> read(String key) async {
    return window.sessionStorage.getItem(key);
  }

  Future<void> delete(String key) async {
    window.sessionStorage.removeItem(key);
  }
}
