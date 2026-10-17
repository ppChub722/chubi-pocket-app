import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/domain/user.dart';
import '../../../ui/ui.dart';

/// `PUT /v1/users/me` — partial update of profile fields (the currency is
/// a relabel: no conversion, owner 2026-10-15).
///
/// `GET /v1/users/me` is owned by [AuthRepository] (used at cold-start to
/// validate the stored token); putting the writer here keeps user-profile
/// edits separate from auth identity flow.
class UsersRepository {
  UsersRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<User> updateMe({
    String? displayName,
    String? email,
    IconCode? iconCode,
    bool clearIconCode = false,
    String? currency,
    String? defaultAccountId,
    bool clearDefaultAccount = false,
  }) async {
    final body = <String, dynamic>{};
    if (clearDefaultAccount) {
      body['default_account_id'] = null;
    } else if (defaultAccountId != null) {
      body['default_account_id'] = defaultAccountId;
    }
    if (displayName != null) body['display_name'] = displayName;
    if (email != null) body['email'] = email;
    if (currency != null) body['currency'] = currency;
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

  /// `GET /v1/users/me` — the profile with its server preferences (the
  /// login answer has none).
  Future<User> getMe() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/users/me');
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Sets the money style preference (`money_style`: plus_minus,
  /// plus_minus_plain, parentheses, parentheses_plain, color_only).
  Future<User> setMoneyStyle(String style) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/users/me',
        data: {
          'preferences': {'money_style': style},
        },
      );
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Sets (or clears, [categoryId] null) the fee category preference —
  /// the BE checks it is one of the user's expense categories.
  Future<User> setFeeCategory(String? categoryId) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/users/me',
        data: {
          'preferences': {'fee_category_id': categoryId},
        },
      );
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
