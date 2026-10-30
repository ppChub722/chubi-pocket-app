import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/connections_repository.dart';
import '../../domain/connection.dart';

class ConnectionsState extends Equatable {
  const ConnectionsState({this.items, this.loading = false, this.error});

  /// Null = never loaded.
  final List<Connection>? items;
  final bool loading;

  /// The last load failure (kept beside the old rows).
  final Object? error;

  Connection? of(String provider) {
    for (final c in items ?? const <Connection>[]) {
      if (c.provider == provider) return c;
    }
    return null;
  }

  @override
  List<Object?> get props => [items, loading, error];
}

/// My outside apps (0.4.2 1b), shared by the settings card (linked logos),
/// the profile page and the connection page: a page open loads once; every
/// write's answer replaces its row (no re-fetch).
class ConnectionsCubit extends Cubit<ConnectionsState> {
  ConnectionsCubit({required ConnectionsRepository repository})
    : _repo = repository,
      super(const ConnectionsState());

  final ConnectionsRepository _repo;

  /// GET /connections. Throws nothing: a failure lands in [ConnectionsState.error].
  Future<void> load() async {
    emit(ConnectionsState(items: state.items, loading: true));
    try {
      emit(ConnectionsState(items: await _repo.list()));
    } catch (e) {
      if (!isClosed) emit(ConnectionsState(items: state.items, error: e));
    }
  }

  /// [load] only when nothing is loaded yet (the settings card).
  Future<void> ensureLoaded() async {
    if (state.items == null && !state.loading) await load();
  }

  /// One row from a write / GET /connections/{provider}.
  void put(Connection row) {
    final items = state.items;
    if (items == null) {
      emit(ConnectionsState(items: [row]));
      return;
    }
    final i = items.indexWhere((c) => c.provider == row.provider);
    emit(
      ConnectionsState(
        items: i < 0 ? [...items, row] : ([...items]..[i] = row),
        loading: state.loading,
      ),
    );
  }

  /// The stored picture of [source] is gone (DELETE /avatars/{source}).
  void photoDeleted(String source) {
    final row = state.of(source);
    if (row != null && row.photo != null) put(row.withoutPhoto());
  }

  void clear() => emit(const ConnectionsState());
}
