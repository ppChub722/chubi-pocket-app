import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/archived_repository.dart';
import '../domain/archived_hub.dart';

class ArchivedState extends Equatable {
  const ArchivedState({
    this.hub,
    this.loading = false,
    this.error,
    this.busy = const {},
  });

  /// Last good payload — kept while reloading / on a failed refresh.
  final ArchivedHub? hub;
  final bool loading;
  final ApiException? error;

  /// Ids whose restore is in flight.
  final Set<String> busy;

  @override
  List<Object?> get props => [hub, loading, error, busy];
}

/// One `GET /me/archived` per [load]; one call per restore.
class ArchivedCubit extends Cubit<ArchivedState> {
  ArchivedCubit({required ArchivedRepository repository})
    : _repo = repository,
      super(const ArchivedState());

  final ArchivedRepository _repo;

  Future<void> load() async {
    emit(ArchivedState(hub: state.hub, loading: true, busy: state.busy));
    try {
      final hub = await _repo.fetch();
      if (!isClosed) emit(ArchivedState(hub: hub, busy: state.busy));
    } catch (e, st) {
      if (!isClosed) {
        emit(
          ArchivedState(
            hub: state.hub,
            error: ApiException.from(e, st),
            busy: state.busy,
          ),
        );
      }
    }
  }

  /// Restores one row; it leaves the list from the write's success (no
  /// re-fetch). Returns the failure, or null.
  Future<ApiException?> restore(ArchivedKind kind, String id) async {
    if (state.busy.contains(id)) return null;
    emit(
      ArchivedState(
        hub: state.hub,
        loading: state.loading,
        busy: {...state.busy, id},
      ),
    );
    try {
      await _repo.restore(kind, id);
      if (!isClosed) {
        emit(
          ArchivedState(
            hub: state.hub?.without(kind, id),
            loading: state.loading,
            busy: {...state.busy}..remove(id),
          ),
        );
      }
      return null;
    } catch (e, st) {
      final err = ApiException.from(e, st);
      if (!isClosed) {
        emit(
          ArchivedState(
            hub: state.hub,
            loading: state.loading,
            busy: {...state.busy}..remove(id),
          ),
        );
      }
      return err;
    }
  }
}
