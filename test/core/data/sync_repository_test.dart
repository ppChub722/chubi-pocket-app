import 'dart:convert';
import 'dart:typed_data';

import 'package:chubi_pocket/core/data/sync_repository.dart';
import 'package:chubi_pocket/core/data/sync_set.dart';
import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokens extends Mock implements SecureTokenStorage {}

typedef _Handler =
    (int, Object?, Map<String, List<String>>) Function(RequestOptions options);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final _Handler handler;
  final seen = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    final (status, body, extra) = handler(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...extra,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _client(_Adapter adapter) {
  final tokens = _MockTokens();
  when(tokens.readAuthToken).thenAnswer((_) async => null);
  return ApiClient(
    tokenStorage: tokens,
    dio: Dio()..httpClientAdapter = adapter,
    baseUrl: 'http://test',
    appBuild: () async => '1',
    timezone: () async => 'Asia/Bangkok',
  );
}

void main() {
  test(
    'posts want and have, and reads data / unchanged / errors / versions',
    () async {
      final adapter = _Adapter(
        (o) => (
          200,
          {
            'synced_at': '2026-10-18T14:02:11Z',
            'versions': {'tags': 't2', 'transactions': 'x1'},
            'data': {
              'tags': {
                'v': 't2',
                'body': {'data': []},
              },
            },
            'unchanged': ['contacts'],
            'errors': {
              'recurring': {'code': 'INTERNAL_ERROR', 'message': 'boom'},
            },
          },
          const {},
        ),
      );
      final repo = SyncRepository(client: _client(adapter));

      final result = await repo.sync(
        want: {SyncSet.tags, SyncSet.contacts, SyncSet.recurring},
        have: {SyncSet.contacts: 'c1'},
      );

      final sent = adapter.seen.single.data as Map;
      expect(adapter.seen.single.path, '/sync');
      expect(sent['want'], containsAll(['tags', 'contacts', 'recurring']));
      expect(sent['have'], {'contacts': 'c1'});
      expect(result.data[SyncSet.tags]?.v, 't2');
      expect(result.unchanged, {SyncSet.contacts});
      expect(result.errors[SyncSet.recurring]?.code, 'INTERNAL_ERROR');
      expect(result.versions['transactions'], 'x1');
      expect(result.fromFallback, isFalse);
    },
  );

  test('omits want when asking for everything', () async {
    final adapter = _Adapter(
      (o) => (
        200,
        {
          'synced_at': '2026-10-18T00:00:00Z',
          'versions': {},
          'data': {},
          'unchanged': [],
          'errors': {},
        },
        const {},
      ),
    );
    await SyncRepository(client: _client(adapter)).sync();
    expect((adapter.seen.single.data as Map).containsKey('want'), isFalse);
  });

  test(
    'a backend without /sync (404): each dataset from its own endpoint, once per session',
    () async {
      final adapter = _Adapter((o) {
        switch (o.path) {
          case '/sync':
            return (404, {'error': 'not found'}, const {});
          case '/personal-debts/people':
            final page = o.queryParameters['page'] as int;
            return (
              200,
              {
                'data': [
                  {'key': 'c:$page'},
                ],
                'totals': {'net': 1},
                'pagination': {
                  'page': page,
                  'per_page': 100,
                  'total': 2,
                  'total_pages': 2,
                },
              },
              const {},
            );
          case '/transactions/form-options':
            return (
              200,
              {
                'default_account_id': 'a1',
                'fee_category_id': null,
                'accounts': [],
              },
              const {},
            );
          case '/tags':
            return (
              500,
              {
                'success': false,
                'error': {'code': 'INTERNAL', 'message': 'x'},
              },
              const {},
            );
          default:
            return (200, {'data': []}, const {});
        }
      });
      final repo = SyncRepository(client: _client(adapter));

      final first = await repo.sync(
        want: {
          SyncSet.debtPeople,
          SyncSet.formDefaults,
          SyncSet.tags,
          SyncSet.accounts,
        },
      );
      expect(first.fromFallback, isTrue);
      expect(first.data[SyncSet.debtPeople]!.body['data'], hasLength(2));
      expect(first.data[SyncSet.debtPeople]!.body['totals'], {'net': 1});
      expect(first.data[SyncSet.formDefaults]!.body, {
        'default_account_id': 'a1',
        'fee_category_id': null,
      });
      expect(first.data[SyncSet.accounts]!.v, '');
      expect(first.errors[SyncSet.tags]?.code, 'INTERNAL');
      expect(first.versions, isEmpty);

      adapter.seen.clear();
      await repo.sync(want: {SyncSet.providers});
      expect(adapter.seen.map((o) => o.path), ['/payment-providers']);
    },
  );

  test(
    'a failing /sync that is not a 404 is an error, not a fallback',
    () async {
      final adapter = _Adapter(
        (o) => (
          500,
          {
            'success': false,
            'error': {'code': 'INTERNAL_SERVER_ERROR', 'message': 'x'},
          },
          const {},
        ),
      );
      expect(
        SyncRepository(client: _client(adapter)).sync(),
        throwsA(anything),
      );
    },
  );

  test(
    'the client hands X-Sync-Versions of a response to onSyncVersions',
    () async {
      final adapter = _Adapter(
        (o) => (
          201,
          {},
          {
            'x-sync-versions': ['accounts=1-2.20261018;tags=3-4'],
          },
        ),
      );
      final client = _client(adapter);
      Map<String, String>? got;
      client.onSyncVersions = (v) => got = v;

      await client.dio.post<dynamic>('/tags', data: {});
      expect(got, {'accounts': '1-2.20261018', 'tags': '3-4'});

      got = null;
      await client.dio.get<dynamic>('/tags');
      expect(got, isNull);
    },
  );
}
