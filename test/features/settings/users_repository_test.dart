import 'dart:convert';
import 'dart:typed_data';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/storage/secure_token_storage.dart';
import 'package:chubi_pocket/features/users/data/users_repository.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoTokens extends Fake implements SecureTokenStorage {
  @override
  Future<String?> readAuthToken() async => null;
}

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode({'id': 'u1', 'username': 'ppond', 'display_name': 'ppOnd'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('/users/me PUT bodies', () async {
    final adapter = _Adapter();
    final repo = UsersRepository(
      client: ApiClient(
        tokenStorage: _NoTokens(),
        dio: Dio()..httpClientAdapter = adapter,
        baseUrl: 'http://test',
        appBuild: () async => null,
        timezone: () async => null,
      ),
    );
    const icon = IconCode(icon: 'star');
    final cases =
        <({String name, Future<void> Function() run, Map<String, dynamic> want})>[
          (
            name: 'currency',
            run: () => repo.updateMe(currency: 'USD'),
            want: {'currency': 'USD'},
          ),
          (
            name: 'main wallet',
            run: () =>
                repo.updateMe(defaultAccountId: 'w2', clearDefaultAccount: false),
            want: {'default_account_id': 'w2'},
          ),
          (
            name: 'no main wallet',
            run: () => repo.updateMe(clearDefaultAccount: true),
            want: {'default_account_id': null},
          ),
          (
            name: 'clearing wins over an id',
            run: () => repo.updateMe(
              defaultAccountId: 'w2',
              clearDefaultAccount: true,
            ),
            want: {'default_account_id': null},
          ),
          (
            name: 'profile: only what changed',
            run: () => repo.updateMe(displayName: 'Pond'),
            want: {'display_name': 'Pond'},
          ),
          (
            name: 'profile: name, email and icon',
            run: () => repo.updateMe(
              displayName: 'Pond',
              email: 'p@example.com',
              iconCode: icon,
            ),
            want: {
              'display_name': 'Pond',
              'email': 'p@example.com',
              'icon_code': icon.toJson(),
            },
          ),
          (
            name: 'profile: clear the icon',
            run: () => repo.updateMe(clearIconCode: true),
            want: {'icon_code': null},
          ),
          (
            name: 'money style',
            run: () => repo.setMoneyStyle('parentheses'),
            want: {
              'preferences': {'money_style': 'parentheses'},
            },
          ),
          (
            name: 'money decimals',
            run: () => repo.setMoneyDecimals('never'),
            want: {
              'preferences': {'money_decimals': 'never'},
            },
          ),
          (
            name: 'fee category off',
            run: () => repo.setFeeCategory(null),
            want: {
              'preferences': {'fee_category_id': null},
            },
          ),
        ];
    for (final c in cases) {
      await c.run();
      expect(adapter.last!.method, 'PUT', reason: c.name);
      expect(adapter.last!.path, '/users/me', reason: c.name);
      expect(adapter.last!.data, c.want, reason: c.name);
    }
  });
}
