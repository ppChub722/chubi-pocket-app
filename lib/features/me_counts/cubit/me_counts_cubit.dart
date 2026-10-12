import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/me_counts_repository.dart';
import '../domain/me_counts.dart';

class MeCountsState extends Equatable {
  const MeCountsState({this.counts, this.loading = false, this.error});

  /// Last good payload — kept while reloading / on a failed refresh.
  final MeCounts? counts;
  final bool loading;
  final ApiException? error;

  @override
  List<Object?> get props => [counts, loading, error];
}

/// Owns one `GET /me/counts` per [load] (open / pull-to-refresh).
class MeCountsCubit extends Cubit<MeCountsState> {
  MeCountsCubit({required MeCountsRepository repository})
    : _repo = repository,
      super(const MeCountsState());

  final MeCountsRepository _repo;

  Future<void> load() async {
    emit(MeCountsState(counts: state.counts, loading: true));
    try {
      final c = await _repo.fetch();
      if (!isClosed) emit(MeCountsState(counts: c));
    } on ApiException catch (e) {
      if (!isClosed) emit(MeCountsState(counts: state.counts, error: e));
    }
  }
}
