import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/auth_token.dart';
import '../domain/user.dart';

/// All HTTP traffic for `/auth/*` and `/users/me` lives here.
///
/// This is the **template Phase 1+ modules copy.** Convention:
/// - Methods accept primitive params or typed input objects, return typed
///   domain models, and throw [ApiException] on any failure.
/// - The repository never imports widgets, never reads from storage directly;
///   token storage is owned by the auth feature's cubit.
/// - Catches [DioException] and rethrows via [ApiException.fromDioException]
///   so callers (cubits) only ever handle one error type.
class AuthRepository {
  AuthRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `POST /v1/auth/register` — returns the new user + first access token.
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

  /// `POST /v1/auth/login` — returns the user + access token.
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

  /// `POST /v1/auth/logout` — best-effort server invalidation.
  /// Phase 0/1 only discards the token client-side; this call is fire-and-forget.
  Future<void> logout() async {
    try {
      await _client.dio.post<void>('/auth/logout');
    } on DioException catch (_) {
      // Server logout is best-effort. Swallow — caller still clears local state.
    }
  }

  /// `PUT /v1/auth/password` — change own password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.dio.put<void>(
        '/auth/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /v1/users/me` — fetch the authenticated user.
  /// Used by splash on cold-start to validate a stored token.
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
