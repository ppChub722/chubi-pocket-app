import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../data/notifications_repository.dart';

/// App-wide unread-count cubit. Powers the bell badge in the top app bar.
/// Polls `GET /notifications/unread-count` every 60s while authenticated;
/// spec §13.4.8 (in-app polling in 1b).
///
/// Foreground only: the timer is cancelled when the app goes to the
/// background and one refresh + a fresh timer start on resume.
class UnreadBadgeCubit extends Cubit<int>
    with Clearable, WidgetsBindingObserver {
  UnreadBadgeCubit({
    required NotificationsRepository repository,
    Duration interval = const Duration(seconds: 60),
  }) : _repo = repository,
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
    WidgetsFlutterBinding.ensureInitialized().addObserver(this);
    _tick();
    _startTimer();
  }

  /// Stop polling — called on logout.
  void stop() {
    _running = false;
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    if (state != 0) emit(0);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  // ignore: avoid_renaming_method_parameters — `state` is the cubit's int.
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (!_running) return;
    switch (lifecycle) {
      case AppLifecycleState.resumed:
        _tick();
        _startTimer();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopTimer();
      case AppLifecycleState.inactive:
        break; // transient (dialogs, app switcher) — keep polling
    }
  }

  /// One-shot refresh (e.g. after the user opens the inbox).
  Future<void> refresh() => _tick();

  /// Patch from a count a write / list reply already carried (no poll).
  void setCount(int n) {
    if (!isClosed && n != state) emit(n);
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
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    return super.close();
  }
}
