import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'api_client.dart';

enum ConnectionStatus {
  online,

  offline,

  reconnecting,

  backOnline,
}

class ServerConnectionState extends Equatable {
  const ServerConnectionState({
    this.status = ConnectionStatus.online,
    this.reconnects = 0,
  });

  final ConnectionStatus status;

  final int reconnects;

  bool get isOffline =>
      status == ConnectionStatus.offline ||
      status == ConnectionStatus.reconnecting;

  @override
  List<Object?> get props => [status, reconnects];
}

class ConnectionCubit extends Cubit<ServerConnectionState> {
  ConnectionCubit({
    required ApiClient client,
    Stream<bool>? deviceOnline,
    List<Duration> backoff = defaultBackoff,
    Duration backOnlineFor = const Duration(seconds: 3),
  }) : _client = client,
       _backoff = backoff,
       _backOnlineFor = backOnlineFor,
       super(const ServerConnectionState()) {
    _subs.add(client.onUnreachable.listen((_) => _goOffline()));
    _subs.add(client.onReachable.listen((_) => _goOnline()));
    if (deviceOnline != null) {
      _subs.add(
        deviceOnline.listen((up) {
          if (!up) {
            _goOffline();
          } else if (state.isOffline) {
            retryNow();
          }
        }),
      );
    }
  }

  static const defaultBackoff = [
    Duration(seconds: 3),
    Duration(seconds: 3),
    Duration(seconds: 5),
    Duration(seconds: 8),
    Duration(seconds: 10),
  ];

  final ApiClient _client;
  final List<Duration> _backoff;
  final Duration _backOnlineFor;
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _poll;
  Timer? _settle;
  int _attempt = 0;

  void _goOffline() {
    if (isClosed || state.isOffline) return;
    _settle?.cancel();
    emit(
      ServerConnectionState(
        status: ConnectionStatus.offline,
        reconnects: state.reconnects,
      ),
    );
    _attempt = 0;
    _schedule();
  }

  void _goOnline() {
    if (isClosed || !state.isOffline) return;
    _poll?.cancel();
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

  void _schedule() {
    _poll?.cancel();
    final delay = _backoff[_attempt.clamp(0, _backoff.length - 1)];
    _poll = Timer(delay, _ping);
  }

  Future<void> retryNow() async {
    if (!state.isOffline) return;
    _poll?.cancel();
    await _ping();
  }

  Future<void> _ping() async {
    if (isClosed || !state.isOffline) return;
    emit(
      ServerConnectionState(
        status: ConnectionStatus.reconnecting,
        reconnects: state.reconnects,
      ),
    );
    try {
      await _client.dio.get<dynamic>(
        '/health',
        options: Options(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      _goOnline();
      return;
    } on DioException catch (e) {
      if (e.response != null) {
        _goOnline();
        return;
      }
    } catch (_) {
    }
    if (isClosed || !state.isOffline) return;
    emit(
      ServerConnectionState(
        status: ConnectionStatus.offline,
        reconnects: state.reconnects,
      ),
    );
    _attempt++;
    _schedule();
  }

  @override
  Future<void> close() async {
    _poll?.cancel();
    _settle?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
