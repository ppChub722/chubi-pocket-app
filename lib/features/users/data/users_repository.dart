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
    AvatarSettings? avatarSettings,
  }) async {
    final body = <String, dynamic>{};
    if (avatarSettings != null) {
      body['avatar_settings'] = avatarSettings.toJson();
    }
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
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<User> getMe() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/users/me');
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<User> _put(Map<String, dynamic> body) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/users/me',
        data: body,
      );
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  /// The profile picture I picked (0.4.2 1b): a photo source needs that
  /// photo (409 AVATAR_SOURCE_UNAVAILABLE).
  Future<User> setAvatarSettings(AvatarSettings settings) =>
      _put({'avatar_settings': settings.toJson()});

  /// Partial merge into `preferences` (only the keys sent change).
  Future<User> updatePreferences(Map<String, Object?> prefs) =>
      _put({'preferences': prefs});

  Future<User> setMoneyStyle(String style) =>
      updatePreferences({'money_style': style});

  /// Sets the decimals preference (`money_decimals`: always, never, auto).
  Future<User> setMoneyDecimals(String decimals) =>
      updatePreferences({'money_decimals': decimals});

  Future<User> setFeeCategory(String? categoryId) =>
      updatePreferences({'fee_category_id': categoryId});

  /// Remembers [page]'s list choices; null resets that page.
  Future<User> setPagePref(String page, Map<String, dynamic>? value) =>
      updatePreferences({
        'page_prefs': {page: value},
      });

  /// Every page back to its defaults.
  Future<User> resetPagePrefs() => updatePreferences({'page_prefs': null});

  /// The two auto-sync switches; only the one(s) passed change.
  Future<User> setAutoSync({bool? events, bool? debts}) =>
      _put({'auto_sync_events': ?events, 'auto_sync_debts': ?debts});

  /// The two รับบิลใหม่อัตโนมัติ switches; only the one(s) passed change.
  Future<User> setAutoAccept({bool? events, bool? debts}) =>
      _put({'auto_accept_events': ?events, 'auto_accept_debts': ?debts});

  /// The three requests' auto-accept switches (F2); only the one(s) passed
  /// change.
  Future<User> setAutoAcceptRequests({
    bool? eventInvites,
    bool? contactLinks,
    bool? walletInvites,
  }) => _put({
    'auto_accept_event_invites': ?eventInvites,
    'auto_accept_contact_links': ?contactLinks,
    'auto_accept_wallet_invites': ?walletInvites,
  });
}
