import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  const AuthService(this._client);

  final ApiClient _client;

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    return UserModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data!['data'] as Map<String, dynamic>;

    return AuthSession(
      token: data['token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<UserModel> me() async {
    final response = await _client.get<Map<String, dynamic>>('/auth/me');
    return UserModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _client.post<Map<String, dynamic>>('/auth/logout');
  }
}
