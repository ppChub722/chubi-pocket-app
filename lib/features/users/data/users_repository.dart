import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/domain/user.dart';
import '../../../ui/ui.dart';

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

  Future<User> getMe() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/users/me');
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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

  /// Sets the decimals preference (`money_decimals`: always, never, auto).
  Future<User> setMoneyDecimals(String decimals) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/users/me',
        data: {
          'preferences': {'money_decimals': decimals},
        },
      );
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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
