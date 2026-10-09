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

  /// Optimistic: the switch flips at once; a failed save flips it back and
  /// sets [SettingsState.error] (the page shows "เปลี่ยนกลับแล้ว").
  Future<void> update({
    Set<String>? mutedTypes,
    Set<String>? autoTypes,
    String? defaultAccountId,
    bool clearDefaultAccount = false,
    bool? autoResolveOwnInProjects,
  }) async {
    final before = state.settings;
    if (before == null) return;
    emit(
      state.copyWith(
        settings: before.copyWith(
          mutedTypes: mutedTypes,
          autoTypes: autoTypes,
          defaultAccountId: defaultAccountId,
          clearDefaultAccount: clearDefaultAccount,
          autoResolveOwnInProjects: autoResolveOwnInProjects,
        ),
        status: SettingsStatus.saving,
        clearError: true,
      ),
    );
    try {
      final updated = await _repo.updateSettings(
        mutedTypes: mutedTypes,
        autoTypes: autoTypes,
        defaultAccountId: defaultAccountId,
        clearDefaultAccount: clearDefaultAccount,
        autoResolveOwnInProjects: autoResolveOwnInProjects,
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
