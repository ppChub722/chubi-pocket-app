import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/data/sync_backed.dart';
import '../../../../core/data/sync_coordinator.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../core/network/api_exception.dart';

enum FormDefaultsStatus { initial, loading, loaded, error }

class FormDefaultsState extends Equatable {
  const FormDefaultsState({
    this.defaultAccountId,
    this.feeCategoryId,
    this.status = FormDefaultsStatus.initial,
    this.error,
  });

  /// The wallet a new transaction starts on.
  final String? defaultAccountId;

  /// The category fees go to, when the user chose one.
  final String? feeCategoryId;
  final FormDefaultsStatus status;
  final ApiException? error;

  @override
  List<Object?> get props => [defaultAccountId, feeCategoryId, status, error];
}

class FormDefaultsCubit extends Cubit<FormDefaultsState>
    with Clearable, SyncBacked<FormDefaultsState> {
  FormDefaultsCubit({required SyncCoordinator coordinator})
    : syncCoordinator = coordinator,
      super(const FormDefaultsState()) {
    bindSync();
  }

  @override
  final SyncCoordinator syncCoordinator;

  @override
  SyncSet get syncSet => SyncSet.formDefaults;

  @override
  bool get syncLoading => state.status == FormDefaultsStatus.loading;

  @override
  void markSyncLoading() => emit(
    FormDefaultsState(
      defaultAccountId: state.defaultAccountId,
      feeCategoryId: state.feeCategoryId,
      status: FormDefaultsStatus.loading,
    ),
  );

  @override
  void syncFailed(ApiException error) => emit(
    FormDefaultsState(
      defaultAccountId: state.defaultAccountId,
      feeCategoryId: state.feeCategoryId,
      status: FormDefaultsStatus.error,
      error: error,
    ),
  );

  @override
  void applySync(Map<String, dynamic> body) {
    emit(
      FormDefaultsState(
        defaultAccountId: body['default_account_id'] as String?,
        feeCategoryId: body['fee_category_id'] as String?,
        status: FormDefaultsStatus.loaded,
      ),
    );
  }

  @override
  void clear() => emit(const FormDefaultsState());

  Future<void> loadIfNeeded() async {
    if (state.status == FormDefaultsStatus.loaded ||
        state.status == FormDefaultsStatus.loading) {
      return;
    }
    return loadSynced();
  }
}
