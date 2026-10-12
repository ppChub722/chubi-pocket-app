import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/transactions_repository.dart';
import '../../domain/form_options.dart';

enum TxFormOptionsStatus { initial, loading, loaded, error }

class TxFormOptionsState extends Equatable {
  const TxFormOptionsState({
    this.status = TxFormOptionsStatus.initial,
    this.options,
    this.error,
  });

  final TxFormOptionsStatus status;
  final TxFormOptions? options;
  final ApiException? error;

  /// A first load is pending (or hasn't started): nothing to show yet.
  bool get isLoading =>
      options == null &&
      (status == TxFormOptionsStatus.initial ||
          status == TxFormOptionsStatus.loading);

  @override
  List<Object?> get props => [status, options, error];
}

/// `GET /transactions/form-options`: wallets (with balances), categories,
/// tags and events for one form, in ONE call. Created locally by whoever
/// opens a form (the quick create sheet makes one per open, so the balances
/// are fresh) — not an app-wide cubit. The pick rows / [DraftForm] use it
/// when one is in the tree ([maybeTxFormOptions]) and fall back to the
/// app-wide cubits otherwise.
class TxFormOptionsCubit extends Cubit<TxFormOptionsState> {
  TxFormOptionsCubit(this._repo) : super(const TxFormOptionsState());

  final TransactionsRepository _repo;

  Future<void> load() async {
    emit(
      TxFormOptionsState(
        status: TxFormOptionsStatus.loading,
        options: state.options,
      ),
    );
    try {
      final options = await _repo.formOptions();
      if (isClosed) return;
      emit(
        TxFormOptionsState(
          status: TxFormOptionsStatus.loaded,
          options: options,
        ),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        TxFormOptionsState(
          status: TxFormOptionsStatus.error,
          options: state.options,
          error: e,
        ),
      );
    }
  }

  /// Loads once: a no-op while loading or after a successful load.
  Future<void> loadIfNeeded() async {
    if (state.status == TxFormOptionsStatus.loaded ||
        state.status == TxFormOptionsStatus.loading) {
      return;
    }
    return load();
  }
}

/// The nearest [TxFormOptionsCubit], or null when no form provides one (the
/// pending page, the scheduled form, the detail page's edit mode). [watch]
/// subscribes the caller to its state (use it from `build`).
TxFormOptionsCubit? maybeTxFormOptions(
  BuildContext context, {
  bool watch = true,
}) {
  try {
    return watch
        ? context.watch<TxFormOptionsCubit>()
        : context.read<TxFormOptionsCubit>();
  } catch (_) {
    // Not provided (flutter_bloc / provider throw when the type is absent).
    return null;
  }
}
