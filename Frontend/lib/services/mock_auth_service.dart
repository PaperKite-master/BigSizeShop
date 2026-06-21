import 'package:dio/dio.dart';
import '../models/user_model.dart';

class MockAuthService {
  MockAuthService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const String _baseUrl = 'https://6a3762adc105017aa638eb0a.mockapi.io';

  /// Login từ Mock API - lấy user data từ users table
  /// Tìm user theo email và kiểm tra password
  Future<AuthSession> loginMock({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '$_baseUrl/users',
      );

      if (response.statusCode == 200 && response.data != null) {
        // Tìm user theo email
        final users = response.data as List<dynamic>;
        final userJson = users.firstWhere(
          (user) => user['email'] == email,
          orElse: () => null,
        );

        if (userJson == null) {
          throw DioException(
            requestOptions: response.requestOptions,
            message: 'Email or password is incorrect',
            type: DioExceptionType.badResponse,
            response: response,
          );
        }

        // Kiểm tra password
        final userPassword = userJson['pass'] as String?;
        if (userPassword != password) {
          throw DioException(
            requestOptions: response.requestOptions,
            message: 'Email or password is incorrect',
            type: DioExceptionType.badResponse,
            response: response,
          );
        }

        // Parse user data
        final user = UserModel.fromJson(userJson as Map<String, dynamic>);

        // Mock token
        final mockToken = 'mock_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

        return AuthSession(
          token: mockToken,
          user: user,
        );
      }

      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Failed to login',
        type: DioExceptionType.badResponse,
        response: response,
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '$_baseUrl/users'),
        message: 'Login failed: ${e.toString()}',
        type: DioExceptionType.unknown,
      );
    }
  }

  /// Lấy danh sách tất cả users từ Mock API
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '$_baseUrl/users',
      );

      if (response.statusCode == 200 && response.data != null) {
        final users = response.data as List<dynamic>;
        return users
            .map((user) => UserModel.fromJson(user as Map<String, dynamic>))
            .toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Failed to fetch users',
        type: DioExceptionType.badResponse,
        response: response,
      );
    } on DioException {
      rethrow;
    }
  }
}
