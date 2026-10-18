import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/data/sync_backed.dart';
import '../../../../core/data/sync_coordinator.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/payment_provider.dart';

enum ProvidersStatus { initial, loading, loaded, error }

class ProvidersState extends Equatable {
  const ProvidersState({
    this.providers = const [],
    this.status = ProvidersStatus.initial,
    this.error,
  });

  final List<PaymentProvider> providers;
  final ProvidersStatus status;
  final ApiException? error;

  @override
  List<Object?> get props => [providers, status, error];
}

/// Banks and e-wallets the identifier editor and the bank picker name.
class ProvidersCubit extends Cubit<ProvidersState>
    with Clearable, SyncBacked<ProvidersState> {
  ProvidersCubit({required SyncCoordinator coordinator})
    : syncCoordinator = coordinator,
      super(const ProvidersState()) {
    bindSync();
  }

  @override
  final SyncCoordinator syncCoordinator;

  @override
  SyncSet get syncSet => SyncSet.providers;

  @override
  bool get syncLoading => state.status == ProvidersStatus.loading;

  @override
  void markSyncLoading() =>
      emit(const ProvidersState(status: ProvidersStatus.loading));

  @override
  void syncFailed(ApiException error) =>
      emit(ProvidersState(status: ProvidersStatus.error, error: error));

  @override
  void applySync(Map<String, dynamic> body) {
    emit(
      ProvidersState(
        providers: [
          for (final p in (body['data'] as List? ?? const []))
            PaymentProvider.fromJson(p as Map<String, dynamic>),
        ],
        status: ProvidersStatus.loaded,
      ),
    );
  }

  @override
  void clear() => emit(const ProvidersState());

  Future<void> loadIfNeeded() async {
    if (state.status == ProvidersStatus.loaded ||
        state.status == ProvidersStatus.loading) {
      return;
    }
    return loadSynced();
  }
}
