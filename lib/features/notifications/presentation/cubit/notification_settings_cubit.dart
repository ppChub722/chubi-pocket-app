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
    this.errorMessage,
  });

  final NotificationSettings? settings;
  final SettingsStatus status;
  final String? errorMessage;

  SettingsState copyWith({
    NotificationSettings? settings,
    SettingsStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [settings, status, errorMessage];
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
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> update({
    bool? autoNotifyLinkedSplitContacts,
    bool? autoAddToPersonalDebtOnSplitNotification,
    bool? autoRecordReceivedPayment,
    bool? autoResolveOwnInProjects,
    String? defaultAccountId,
  }) async {
    emit(state.copyWith(status: SettingsStatus.saving, clearError: true));
    try {
      final updated = await _repo.updateSettings(
        autoNotifyLinkedSplitContacts: autoNotifyLinkedSplitContacts,
        autoAddToPersonalDebtOnSplitNotification:
            autoAddToPersonalDebtOnSplitNotification,
        autoRecordReceivedPayment: autoRecordReceivedPayment,
        autoResolveOwnInProjects: autoResolveOwnInProjects,
        defaultAccountId: defaultAccountId,
      );
      emit(state.copyWith(settings: updated, status: SettingsStatus.loaded));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: e.message,
      ));
    }
  }
}
