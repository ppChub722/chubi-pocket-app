import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification.dart';

enum SettingsStatus { initial, loading, loaded, saving, error }

class SettingsState extends Equatable {
  const SettingsState({
    this.settings,
    this.status = SettingsStatus.initial,
    this.error,
  });

  final NotificationSettings? settings;
  final SettingsStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;

  SettingsState copyWith({
    NotificationSettings? settings,
    SettingsStatus? status,
    ApiException? error,
    bool clearError = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [settings, status, error];
}

class NotificationSettingsCubit extends Cubit<SettingsState> {
  NotificationSettingsCubit({required NotificationsRepository repository})
    : _repo = repository,
      super(const SettingsState());

  final NotificationsRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: SettingsStatus.loading, clearError: true));
    try {
      final s = await _repo.getSettings();
      emit(state.copyWith(settings: s, status: SettingsStatus.loaded));
    } catch (e, st) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  /// One type to [mode] — ONE call carrying only the list(s) that change
  /// (off = muted, auto cleared; notify = neither; auto = auto, not muted).
  Future<void> setMode(NotificationType t, NotifyMode mode) {
    final s = state.settings;
    if (s == null || s.modeOf(t) == mode) return Future.value();
    Set<String> with_(Set<String> set, bool on) =>
        on ? {...set, t.wire} : (set.toSet()..remove(t.wire));
    final muted = with_(s.mutedTypes, mode == NotifyMode.off);
    final auto = with_(s.autoTypes, mode == NotifyMode.auto);
    return update(
      mutedTypes: s.isMuted(t) == (mode == NotifyMode.off) ? null : muted,
      autoTypes: s.isAuto(t) == (mode == NotifyMode.auto) ? null : auto,
    );
  }

  /// Optimistic: the switch flips at once; a failed save flips it back and
  /// sets [SettingsState.error] (the page shows "เปลี่ยนกลับแล้ว"; muting a
  /// non-mutable type comes back as `TYPE_NOT_MUTABLE`).
  Future<void> update({
    Set<String>? mutedTypes,
    Set<String>? autoTypes,
    DefaultAccountRef? defaultAccount,
    bool clearDefaultAccount = false,
  }) async {
    final before = state.settings;
    if (before == null) return;
    emit(
      state.copyWith(
        settings: before.copyWith(
          mutedTypes: mutedTypes,
          autoTypes: autoTypes,
          defaultAccount: defaultAccount,
          clearDefaultAccount: clearDefaultAccount,
        ),
        status: SettingsStatus.saving,
        clearError: true,
      ),
    );
    try {
      final updated = await _repo.updateSettings(
        mutedTypes: mutedTypes,
        autoTypes: autoTypes,
        defaultAccountId: defaultAccount?.id,
        clearDefaultAccount: clearDefaultAccount,
      );
      emit(state.copyWith(settings: updated, status: SettingsStatus.loaded));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          settings: before,
          status: SettingsStatus.error,
          error: e,
        ),
      );
    }
  }
}
