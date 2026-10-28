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

/// The notification page: on / off per type (mute only; auto sync is its
/// own setting since 0.4.1-2).
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

  /// Turns [type] on / off: ONE call; the switch flips at once and comes
  /// back (with the error) when the save fails.
  Future<void> setOn(String type, bool on) async {
    final before = state.settings;
    if (before == null) return;
    final muted = before.mutedWith(type, on: on);
    if (muted.length == before.mutedTypes.length &&
        muted.containsAll(before.mutedTypes)) {
      return;
    }
    emit(
      state.copyWith(
        settings: before.copyWith(mutedTypes: muted),
        status: SettingsStatus.saving,
        clearError: true,
      ),
    );
    try {
      final updated = await _repo.updateSettings(mutedTypes: muted);
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
