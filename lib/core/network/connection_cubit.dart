import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'api_client.dart';
import 'http_logger_interceptor.dart';

/// online → (a call fails) reconnecting ("connecting… n/N") → online via
/// backOnline, or offline ("can't connect" + retry) once the last retry
/// fails.
enum ConnectionStatus { online, offline, reconnecting, backOnline }

class ServerConnectionState extends Equatable {
  const ServerConnectionState({
    this.status = ConnectionStatus.online,
    this.reconnects = 0,
    this.attempt = 0,
    this.attempts = 0,
  });

  final ConnectionStatus status;

  final int reconnects;

  /// While reconnecting: the retry running or last run (1…[attempts]); 0 =
  /// before the first retry.
  final int attempt;

  /// How many retries a cycle has (the policy's); 0 = not shown.
  final int attempts;

  bool get isOffline =>
      status == ConnectionStatus.offline ||
      status == ConnectionStatus.reconnecting;

  @override
  List<Object?> get props => [status, reconnects, attempt, attempts];
}

/// The one owner of "can the app reach the server". A network-level failure
/// starts a cycle: wait [retryPolicy] gap AFTER the last result, ping
/// /health, repeat up to its retries; one request at a time. The state is
/// reconnecting (n/N) for the whole cycle and offline only when the last
/// retry fails; then nothing is sent until the user's retry ([retryNow]),
/// the app returning to the foreground ([resumed]) or a device network
/// change ([deviceOnline]) starts a fresh cycle. Any answer resets it. On
/// the dev hub ([devHub]) it never pings.
class ConnectionCubit extends Cubit<ServerConnectionState> {
  ConnectionCubit({
    required ApiClient client,
    Stream<bool>? deviceOnline,
    Stream<void>? resumed,
    ValueListenable<bool>? devHub,
    ({Duration gap, int retries}) policy = retryPolicy,
    Duration backOnlineFor = const Duration(seconds: 3),
  }) : _client = client,
       _policy = policy,
       _backOnlineFor = backOnlineFor,
       _devHub = devHub,
       super(const ServerConnectionState()) {
    _subs.add(client.onUnreachable.listen((_) => _goOffline()));
    _subs.add(client.onReachable.listen((_) => _goOnline()));
    if (deviceOnline != null) {
      _subs.add(
        deviceOnline.listen((up) {
          if (!up) {
            _goOffline();
          } else if (_stopped) {
            retryNow();
          }
        }),
      );
    }
    if (resumed != null) {
      _subs.add(
        resumed.listen((_) {
          if (_stopped) retryNow();
        }),
      );
    }
    devHub?.addListener(_devHubChanged);
  }

  /// The retry rhythm (owner 2026-10-28): 10 s after each failed result, 6
  /// retries, then stop. Change it here only.
  static const retryPolicy = (gap: Duration(seconds: 10), retries: 6);

  final ApiClient _client;
  final ({Duration gap, int retries}) _policy;
  final Duration _backOnlineFor;
  final ValueListenable<bool>? _devHub;
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _wait;
  Timer? _settle;
  int _attempt = 0;
  bool _inFlight = false;

  bool get _stopped => state.status == ConnectionStatus.offline;

  bool get _onDevHub => _devHub?.value ?? false;

  void _devHubChanged() {
    if (_onDevHub) {
      _wait?.cancel();
    } else if (state.isOffline && !_inFlight) {
      retryNow();
    }
  }

  void _emitConnecting() => emit(
    ServerConnectionState(
      status: ConnectionStatus.reconnecting,
      reconnects: state.reconnects,
      attempt: _attempt,
      attempts: _policy.retries,
    ),
  );

  void _goOffline() {
    if (isClosed || state.isOffline) return;
    _settle?.cancel();
    _attempt = 0;
    _emitConnecting();
    _waitThenRetry();
  }

  void _goOnline() {
    _wait?.cancel();
    _attempt = 0;
    if (isClosed || !state.isOffline) return;
    emit(
      ServerConnectionState(
        status: ConnectionStatus.backOnline,
        reconnects: state.reconnects + 1,
      ),
    );
    _settle?.cancel();
    _settle = Timer(_backOnlineFor, () {
      if (!isClosed && state.status == ConnectionStatus.backOnline) {
        emit(ServerConnectionState(reconnects: state.reconnects));
      }
    });
  }

  void _waitThenRetry() {
    _wait?.cancel();
    if (isClosed || _onDevHub) return;
    _wait = Timer(_policy.gap, () {
      _attempt++;
      _ping();
    });
  }

  /// A fresh cycle now (the user's retry, or a restart trigger): one ping,
  /// then the retries if it fails.
  Future<void> retryNow() async {
    if (!state.isOffline || _inFlight || _onDevHub) return;
    _wait?.cancel();
    _attempt = 0;
    await _ping();
  }

  Future<void> _ping() async {
    if (isClosed || !state.isOffline || _inFlight || _onDevHub) return;
    _inFlight = true;
    _emitConnecting();
    var answered = false;
    try {
      await _client.dio.get<dynamic>(
        '/health',
        options: Options(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          extra: {
            if (_attempt > 0)
              HttpLoggerInterceptor.attemptExtra:
                  '$_attempt/${_policy.retries}',
          },
        ),
      );
      answered = true;
    } on DioException catch (e) {
      answered = e.response != null;
    } catch (_) {}
    _inFlight = false;
    if (answered) {
      _goOnline();
      return;
    }
    if (isClosed || !state.isOffline) return;
    if (_attempt >= _policy.retries) {
      emit(
        ServerConnectionState(
          status: ConnectionStatus.offline,
          reconnects: state.reconnects,
          attempt: _attempt,
          attempts: _policy.retries,
        ),
      );
      return;
    }
    _waitThenRetry();
  }

  @override
  Future<void> close() async {
    _wait?.cancel();
    _settle?.cancel();
    _devHub?.removeListener(_devHubChanged);
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
