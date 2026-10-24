import 'dart:typed_data';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokens extends Mock implements SecureTokenStorage {}

/// Records the options of every request and answers `{}`.
class _Adapter implements HttpClientAdapter {
  final seen = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Page loads fail fast; writes keep the long defaults.
void main() {
  late _Adapter adapter;
  late ApiClient client;

  setUp(() {
    final tokens = _MockTokens();
    when(tokens.readAuthToken).thenAnswer((_) async => null);
    adapter = _Adapter();
    client = ApiClient(
      tokenStorage: tokens,
      dio: Dio()..httpClientAdapter = adapter,
      baseUrl: 'http://test',
      appBuild: () async => '1',
      timezone: () async => 'Asia/Bangkok',
    );
  });

  test(
    'timeouts: GET fails fast, POST keeps the defaults, a set one stays',
    () async {
      final cases = <(String, Future<void> Function(), Duration, Duration)>[
        (
          'GET',
          () => client.dio.get<dynamic>('/contacts/1'),
          ApiClient.pageLoadConnectTimeout,
          ApiClient.pageLoadReceiveTimeout,
        ),
        (
          'POST',
          () => client.dio.post<dynamic>('/contacts', data: {}),
          const Duration(seconds: 10),
          const Duration(seconds: 15),
        ),
        (
          'GET with its own receive timeout',
          () => client.dio.get<dynamic>(
            '/export',
            options: Options(receiveTimeout: const Duration(seconds: 60)),
          ),
          ApiClient.pageLoadConnectTimeout,
          const Duration(seconds: 60),
        ),
      ];
      for (final (name, call, connect, receive) in cases) {
        adapter.seen.clear();
        await call();
        final o = adapter.seen.single;
        expect(o.connectTimeout, connect, reason: '$name connect');
        expect(o.receiveTimeout, receive, reason: '$name receive');
      }
    },
  );

  test('every request carries X-Timezone (the device IANA name)', () async {
    await client.dio.get<dynamic>('/categories');
    expect(adapter.seen.single.headers['X-Timezone'], 'Asia/Bangkok');
  });
}
