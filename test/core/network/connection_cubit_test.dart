import 'dart:async';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/connection_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi extends Fake implements ApiClient {
  _FakeApi(this.dio);

  @override
  final Dio dio;
  final unreachable = StreamController<void>.broadcast();
  final reachable = StreamController<void>.broadcast();

  @override
  Stream<void> get onUnreachable => unreachable.stream;
  @override
  Stream<void> get onReachable => reachable.stream;
}

/// Answers /health: down until [up] is true.
class _Health implements HttpClientAdapter {
  bool up = false;
  int pings = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    pings++;
    if (!up) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

/// A network-level failure → offline; polling /health with backoff until the
/// server answers → back online (+1 reconnect), then settles to online.
void main() {
  late _Health health;
  late _FakeApi api;
  late ConnectionCubit cubit;

  setUp(() {
    health = _Health();
    api = _FakeApi(Dio()..httpClientAdapter = health);
    cubit = ConnectionCubit(
      client: api,
      backoff: const [Duration(milliseconds: 30), Duration(milliseconds: 60)],
      backOnlineFor: const Duration(milliseconds: 300),
    );
  });

  tearDown(() => cubit.close());

  test(
    'network failure → offline; polls until it answers; then back',
    () async {
      expect(cubit.state.status, ConnectionStatus.online);
      api.unreachable.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state.isOffline, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(health.pings, greaterThanOrEqualTo(2)); // it keeps polling
      expect(cubit.state.isOffline, isTrue);

      health.up = true;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(cubit.state.status, ConnectionStatus.backOnline);
      expect(cubit.state.reconnects, 1);

      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(cubit.state.status, ConnectionStatus.online);
      expect(cubit.state.reconnects, 1);
    },
  );

  test('any answered call while offline brings it back at once', () async {
    api.unreachable.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    api.reachable.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(cubit.state.status, ConnectionStatus.backOnline);
    expect(cubit.state.reconnects, 1);
  });

  test('retryNow polls immediately', () async {
    api.unreachable.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    health.up = true;
    await cubit.retryNow();
    expect(cubit.state.status, ConnectionStatus.backOnline);
  });
}
