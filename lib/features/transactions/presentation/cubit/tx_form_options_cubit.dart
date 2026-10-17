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

  bool get isLoading =>
      options == null &&
      (status == TxFormOptionsStatus.initial ||
          status == TxFormOptionsStatus.loading);

  @override
  List<Object?> get props => [status, options, error];
}

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
    } catch (e, st) {
      if (isClosed) return;
      emit(
        TxFormOptionsState(
          status: TxFormOptionsStatus.error,
          options: state.options,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  Future<void> loadIfNeeded() async {
    if (state.status == TxFormOptionsStatus.loaded ||
        state.status == TxFormOptionsStatus.loading) {
      return;
    }
    return load();
  }
}

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
