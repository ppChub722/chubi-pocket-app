import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/auth_token.dart';
import '../domain/user.dart';

class AuthRepository {
  AuthRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<({User user, AuthToken token})> register({
    required String username,
    required String password,
    required String displayName,
    String? email,
    String currency = 'THB',
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'display_name': displayName,
          if (email != null && email.isNotEmpty) 'email': email,
          'currency': currency,
        },
      );
      return _parseAuthResponse(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<({User user, AuthToken token})> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'identifier': identifier, 'password': password},
      );
      return _parseAuthResponse(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post<void>('/auth/logout');
    } on DioException catch (_) {}
  }

  /// PUT /auth/password. [currentPassword] null = ตั้งรหัสผ่าน (0.4.2 1b-2):
  /// an account with no password yet sets one with the new password only.
  Future<void> changePassword({
    required String? currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.dio.put<void>(
        '/auth/password',
        data: {
          'current_password': ?currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/users/me');
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  ({User user, AuthToken token}) _parseAuthResponse(Map<String, dynamic> data) {
    return (
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      token: AuthToken.fromJson(data['token'] as Map<String, dynamic>),
    );
  }
}
