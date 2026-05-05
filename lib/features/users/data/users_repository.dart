import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/icon_maker/icon_code.dart';
import '../../auth/domain/user.dart';

/// `PUT /v1/users/me` — partial update of profile fields.
///
/// `GET /v1/users/me` is owned by [AuthRepository] (used at cold-start to
/// validate the stored token); putting the writer here keeps user-profile
/// edits separate from auth identity flow.
class UsersRepository {
  UsersRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<User> updateMe({
    String? displayName,
    String? currency,
    String? email,
    IconCode? iconCode,
    bool clearIconCode = false,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (currency != null) body['currency'] = currency;
    if (email != null) body['email'] = email;
    if (clearIconCode) {
      body['icon_code'] = null;
    } else if (iconCode != null) {
      body['icon_code'] = iconCode.toJson();
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
