import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../data/notifications_repository.dart';

/// App-wide unread-count cubit. Powers the bell badge in the top app bar.
/// Polls every 30s while authenticated; spec §13.4.8 (in-app polling in 1b).
class UnreadBadgeCubit extends Cubit<int> with Clearable {
  UnreadBadgeCubit({
    required NotificationsRepository repository,
    Duration interval = const Duration(seconds: 30),
  })  : _repo = repository,
        _interval = interval,
        super(0);

  /// On logout: stop polling AND wipe the cached count so the bell
  /// doesn't briefly show the previous user's number after re-login.
  @override
  void clear() => stop();

  final NotificationsRepository _repo;
  final Duration _interval;
  Timer? _timer;
  bool _running = false;

  /// Begin polling. Idempotent — safe to call after auth resolves.
  void start() {
    if (_running) return;
    _running = true;
    _tick();
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  /// Stop polling — called on logout.
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    if (state != 0) emit(0);
  }

  /// One-shot refresh (e.g. after the user opens the inbox).
  Future<void> refresh() => _tick();

  /// Surgical decrement after the user marks one as read locally.
  void decrementBy(int n) {
    final next = (state - n).clamp(0, 1 << 31);
    if (next != state) emit(next);
  }

  Future<void> _tick() async {
    try {
      final n = await _repo.unreadCount();
      if (!isClosed && n != state) emit(n);
    } catch (_) {
      // Silent — badge stays at last value. Failures here are background
      // polling; surfacing a snackbar would be noise.
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
