import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/domain/user.dart';

/// `PUT /v1/users/me` — partial update of profile fields.
///
/// `GET /v1/users/me` is owned by [AuthRepository] (used at cold-start to
/// validate the stored token); putting the writer here keeps user-profile
/// edits separate from auth identity flow.
class UsersRepository {
  UsersRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// Updates only the fields that are non-null. Returns the refreshed [User].
  ///
  /// `email` follows the same partial-update pattern: pass null to leave the
  /// stored email unchanged. Clearing back to NULL isn't supported through
  /// this endpoint (BE COALESCEs nil → existing value). The BE returns 409
  /// EMAIL_EXISTS if another user already owns the address.
  Future<User> updateMe({
    String? displayName,
    String? currency,
    String? avatarUrl,
    String? email,
    bool clearAvatar = false,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (currency != null) body['currency'] = currency;
    if (email != null) body['email'] = email;
    if (clearAvatar) {
      body['avatar_url'] = null;
    } else if (avatarUrl != null) {
      body['avatar_url'] = avatarUrl;
    }

    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/users/me',
        data: body,
      );
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
