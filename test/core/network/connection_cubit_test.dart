import 'dart:async';

import 'package:chubi_pocket/core/logger/app_logger.dart';
import 'package:chubi_pocket/core/logger/breadcrumbs.dart';
import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/connection_cubit.dart';
import 'package:chubi_pocket/core/network/http_logger_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

/// Answers /health after [latency]: down until [up] is true. Records the
/// second each request started (the test's fake clock, see [_Clock]).
class _Health implements HttpClientAdapter {
  _Health(this.clock);

  final _Clock clock;
  bool up = false;
  Duration latency = Duration.zero;
  final starts = <int>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    starts.add(clock.second);
    if (latency > Duration.zero) await Future<void>.delayed(latency);
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

/// Fake time, advanced a second at a time with the tester.
class _Clock {
  int second = 0;

  /// Lets a call started now reach the adapter (Dio hops a few events).
  Future<void> settle(WidgetTester t) =>
      t.pump(const Duration(milliseconds: 10));

  Future<void> run(WidgetTester t, int seconds) async {
    for (var i = 0; i < seconds; i++) {
      second++;
      await t.pump(const Duration(seconds: 1));
    }
  }
}

typedef _Seen = (ConnectionStatus, int);

void main() {
  late _Clock clock;
  late _Health health;
  late _FakeApi api;
  late StreamController<void> resumed;
  late StreamController<bool> network;
  late ValueNotifier<bool> devHub;
  late ConnectionCubit cubit;
  late List<_Seen> seen;

  void build() {
    clock = _Clock();
    health = _Health(clock);
    api = _FakeApi(Dio()..httpClientAdapter = health);
    resumed = StreamController<void>.broadcast();
    network = StreamController<bool>.broadcast();
    devHub = ValueNotifier(false);
    cubit = ConnectionCubit(
      client: api,
      resumed: resumed.stream,
      deviceOnline: network.stream,
      devHub: devHub,
      backOnlineFor: const Duration(seconds: 3),
    );
    seen = [];
    cubit.stream.listen((s) => seen.add((s.status, s.attempt)));
  }

  // Awaiting close() inside the fake clock never returns: start it, pump.
  Future<void> dispose(WidgetTester t) async {
    unawaited(cubit.close());
    await t.pump();
    devHub.dispose();
  }

  /// Runs a failure through all the retries (each takes [latency]).
  Future<void> failAll(WidgetTester t) async {
    api.unreachable.add(null);
    await clock.run(t, 120);
  }

  testWidgets('6 retries, each 10 s after the previous result, then stop', (
    t,
  ) async {
    build();
    health.latency = const Duration(seconds: 3); // a slow request
    expect(ConnectionCubit.retryPolicy.retries, 6);
    expect(ConnectionCubit.retryPolicy.gap, const Duration(seconds: 10));
    await failAll(t);
    // Failure at 0 → wait 10 → retry (3 s) → wait 10 → …
    expect(health.starts, [10, 23, 36, 49, 62, 75]);
    expect(seen, [
      (ConnectionStatus.reconnecting, 0),
      for (var n = 1; n <= 6; n++) (ConnectionStatus.reconnecting, n),
      (ConnectionStatus.offline, 6),
    ]);
    expect(cubit.state.attempts, 6);
    // Stopped: nothing more, ever.
    await clock.run(t, 600);
    expect(health.starts, hasLength(6));
    await dispose(t);
  });

  testWidgets('never two requests at once (a request slower than the gap)', (
    t,
  ) async {
    build();
    health.latency = const Duration(seconds: 25);
    await failAll(t);
    expect(health.starts, [10, 45, 80, 115]);
    await clock.run(t, 200);
    expect(health.starts, [10, 45, 80, 115, 150, 185]);
    expect(cubit.state.status, ConnectionStatus.offline);
    await dispose(t);
  });

  testWidgets('Retry, resume and a network change start a fresh cycle', (
    t,
  ) async {
    build();
    await failAll(t);
    expect(health.starts, hasLength(6));
    final at = clock.second;

    // While stopped: Retry pings now, then the retries run again.
    unawaited(cubit.retryNow());
    await clock.settle(t);
    expect(health.starts.last, at);
    expect(cubit.state.status, ConnectionStatus.reconnecting);
    expect(cubit.state.attempt, 0);
    await clock.run(t, 120);
    expect(health.starts, hasLength(13));
    expect(health.starts[7], at + 10);
    expect(cubit.state.status, ConnectionStatus.offline);

    resumed.add(null);
    await clock.settle(t);
    expect(health.starts, hasLength(14));
    await clock.run(t, 120);

    network.add(true);
    await clock.settle(t);
    expect(health.starts, hasLength(21));

    // During a cycle the triggers start nothing extra.
    resumed.add(null);
    network.add(true);
    await clock.settle(t);
    expect(health.starts, hasLength(21));
    await clock.run(t, 120);
    await dispose(t);
  });

  testWidgets('an answer resets everything', (t) async {
    build();
    api.unreachable.add(null);
    await clock.run(t, 25);
    expect(health.starts, [10, 20]);
    expect(cubit.state.attempt, 2);
    health.up = true;
    await clock.run(t, 6);
    expect(health.starts, [10, 20, 30]);
    expect(cubit.state.status, ConnectionStatus.backOnline);
    expect(cubit.state.reconnects, 1);
    await clock.run(t, 120);
    expect(cubit.state.status, ConnectionStatus.online);
    expect(health.starts, hasLength(3));

    // The next failure starts at retry 1 again.
    health.up = false;
    api.unreachable.add(null);
    await clock.run(t, 11);
    expect(cubit.state.attempt, 1);
    await clock.run(t, 120);
    await dispose(t);
  });

  testWidgets('any answered call while connecting brings it back', (t) async {
    build();
    api.unreachable.add(null);
    await t.pump();
    api.reachable.add(null);
    await t.pump();
    expect(cubit.state.status, ConnectionStatus.backOnline);
    expect(cubit.state.reconnects, 1);
    await clock.run(t, 60);
    expect(health.starts, isEmpty);
    await dispose(t);
  });

  testWidgets('no health checks on the dev hub', (t) async {
    build();
    devHub.value = true;
    await failAll(t);
    expect(health.starts, isEmpty);
    // Leaving it starts a cycle.
    devHub.value = false;
    await clock.settle(t);
    expect(health.starts, [clock.second]);
    await clock.run(t, 120);
    await dispose(t);
  });

  test('a failure streak logs the steps once, then one line each', () async {
    Breadcrumbs.instance.page('/auth/login');
    final dio = Dio()
      ..httpClientAdapter = _Health(_Clock())
      ..interceptors.add(HttpLoggerInterceptor(logger: AppLogger.instance));
    Future<void> call(String? attempt) => dio
        .get<dynamic>(
          '/health',
          options: Options(
            extra: {HttpLoggerInterceptor.attemptExtra: ?attempt},
          ),
        )
        .then<void>((_) {}, onError: (_) {});

    final before = AppLogger.instance.recent.length;
    await call(null);
    await call('1/6');
    await call('2/6');
    final errors = AppLogger.instance.recent
        .skip(before)
        .where((e) => e.message == 'http.error')
        .toList();
    expect(errors, hasLength(3));
    expect(errors[0].fields.containsKey('steps'), isTrue);
    for (final (i, e) in errors.skip(1).indexed) {
      expect(e.fields.containsKey('steps'), isFalse);
      expect(e.fields.keys.toSet(), {'method', 'url', 'type', 'attempt'});
      expect(e.fields['attempt'], '${i + 1}/6');
      expect(e.fields['type'], 'connectionError');
    }
  });
}
