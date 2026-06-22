import 'package:flutter/foundation.dart';
import '../core/storage/sqlite_service.dart';
import '../core/storage/sqlite_mock_data.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  const AuthService(this._sqliteService, this._secureStorage);

  final SqliteService _sqliteService;
  final SecureStorageService _secureStorage;

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final newUser = {
      'id': 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      'fullName': fullName,
      'email': email,
      'password': password,
      'phone': phone,
      'avatar': 'https://picsum.photos/150/150?random=${DateTime.now().second}',
      'role': 'USER',
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      final db = await _sqliteService.database;
      await db.insert('users', newUser);
    } catch (e) {
      debugPrint('SQLite: Đăng ký lỗi: $e');
    }

    return UserModel.fromJson(newUser);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final localUser = await _loginOffline(email, password);
    if (localUser != null) {
      return AuthSession(
        token: 'mock-jwt-token-for-${localUser.id}',
        user: localUser,
      );
    }
    throw Exception('Email hoặc mật khẩu không chính xác');
  }

  Future<UserModel> me() async {
    final token = await _secureStorage.readToken();
    if (token != null && token.startsWith('mock-jwt-token-for-')) {
      final userId = token.replaceFirst('mock-jwt-token-for-', '');

      try {
        final db = await _sqliteService.database;
        final List<Map<String, dynamic>> maps = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
        );
        if (maps.isNotEmpty) {
          return UserModel.fromJson(maps.first);
        }
      } catch (dbError) {
        debugPrint('SQLite: Lấy chi tiết phiên làm việc lỗi: $dbError');
      }

      // Dữ liệu mẫu tĩnh dự phòng
      for (final user in SqliteMockData.mockUsers) {
        if (user['id'] == userId) {
          return UserModel.fromJson(user);
        }
      }
    }
    throw Exception('Không có phiên hoạt động cục bộ');
  }

  Future<void> logout() async {
    // Không cần gọi API ngoại tuyến
  }

  Future<UserModel?> _loginOffline(String email, String password) async {
    try {
      final db = await _sqliteService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      if (maps.isNotEmpty) {
        return UserModel.fromJson(maps.first);
      }
    } catch (e) {
      debugPrint('SQLite: Lỗi đăng nhập: $e');
    }

    for (final user in SqliteMockData.mockUsers) {
      if (user['email'] == email && user['password'] == password) {
        return UserModel.fromJson(user);
      }
    }

    return null;
  }
}
