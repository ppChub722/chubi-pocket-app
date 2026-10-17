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

  test('GET: 5 s connect / 10 s receive', () async {
    await client.dio.get<dynamic>('/contacts/1');
    final o = adapter.seen.single;
    expect(o.connectTimeout, ApiClient.pageLoadConnectTimeout);
    expect(o.receiveTimeout, ApiClient.pageLoadReceiveTimeout);
  });

  test('every request carries X-Timezone (the device IANA name)', () async {
    await client.dio.get<dynamic>('/categories');
    expect(adapter.seen.single.headers['X-Timezone'], 'Asia/Bangkok');
  });

  test('POST keeps the 10 s connect / 15 s receive defaults', () async {
    await client.dio.post<dynamic>('/contacts', data: {});
    final o = adapter.seen.single;
    expect(o.connectTimeout, const Duration(seconds: 10));
    expect(o.receiveTimeout, const Duration(seconds: 15));
  });

  test('a GET that sets its own receive timeout keeps it', () async {
    await client.dio.get<dynamic>(
      '/export',
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    final o = adapter.seen.single;
    expect(o.receiveTimeout, const Duration(seconds: 60));
    expect(o.connectTimeout, ApiClient.pageLoadConnectTimeout);
  });
}
