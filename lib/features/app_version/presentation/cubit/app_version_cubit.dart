import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/logger/app_logger.dart';
import '../../data/app_version_repository.dart';
import '../../domain/app_version_info.dart';

enum AppVersionStatus {
  checking,

  /// Good to go (also: the check failed — never lock anyone out on that).
  ok,

  updateAvailable,

  updateRequired,
}

class AppVersionState {
  const AppVersionState({
    this.status = AppVersionStatus.checking,
    this.info = const AppVersionInfo(),
    this.build,
    this.bannerDismissed = false,
  });

  final AppVersionStatus status;
  final AppVersionInfo info;

  final int? build;

  final bool bannerDismissed;

  bool get blocked => status == AppVersionStatus.updateRequired;
  bool get showBanner =>
      status == AppVersionStatus.updateAvailable && !bannerDismissed;

  AppVersionState copyWith({
    AppVersionStatus? status,
    AppVersionInfo? info,
    int? build,
    bool? bannerDismissed,
  }) => AppVersionState(
    status: status ?? this.status,
    info: info ?? this.info,
    build: build ?? this.build,
    bannerDismissed: bannerDismissed ?? this.bannerDismissed,
  );
}

class AppVersionCubit extends Cubit<AppVersionState> {
  AppVersionCubit({
    required AppVersionRepository repository,
    required Future<int?> Function() currentBuild,
    Stream<Map<String, dynamic>?>? outdated,
    SharedPreferences? prefs,
    DateTime Function()? now,
    this.timeout = const Duration(seconds: 5),
  }) : _repository = repository,
       _currentBuild = currentBuild,
       _prefs = prefs,
       _now = now ?? DateTime.now,
       super(const AppVersionState()) {
    _outdatedSub = outdated?.listen(_onOutdated);
  }

  final AppVersionRepository _repository;
  final Future<int?> Function() _currentBuild;
  final SharedPreferences? _prefs;
  final DateTime Function() _now;
  StreamSubscription<Map<String, dynamic>?>? _outdatedSub;

  final Duration timeout;

  static const _dismissedKey = 'app_update_banner_dismissed_at';
  static const _bannerQuiet = Duration(days: 1);

  bool _checking = false;

  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    try {
      final build = await _currentBuild();
      final info = await _repository.fetch().timeout(timeout);
      if (isClosed) return;
      final status = build == null
          ? AppVersionStatus.ok
          : info.blocks(build)
          ? AppVersionStatus.updateRequired
          : info.hasUpdateFor(build)
          ? AppVersionStatus.updateAvailable
          : AppVersionStatus.ok;
      emit(
        AppVersionState(
          status: status,
          info: info,
          build: build,
          bannerDismissed: _dismissedRecently(),
        ),
      );
    } catch (e) {
      AppLogger.instance.warn(
        'app_version.check_failed',
        fields: {'error': '$e'},
      );
      if (!isClosed && state.status == AppVersionStatus.checking) {
        emit(state.copyWith(status: AppVersionStatus.ok));
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> dismissBanner() async {
    emit(state.copyWith(bannerDismissed: true));
    await _prefs?.setInt(_dismissedKey, _now().millisecondsSinceEpoch);
  }

  void _onOutdated(Map<String, dynamic>? details) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: AppVersionStatus.updateRequired,
        info: details == null ? null : AppVersionInfo.fromJson(details),
      ),
    );
  }

  bool _dismissedRecently() {
    final at = _prefs?.getInt(_dismissedKey);
    if (at == null) return false;
    final since = _now().difference(DateTime.fromMillisecondsSinceEpoch(at));
    return since < _bannerQuiet;
  }

  @override
  Future<void> close() async {
    await _outdatedSub?.cancel();
    return super.close();
  }
}
