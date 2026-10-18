import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/debt_directory.dart';
import '../../domain/debt_ledger.dart';
import 'debt_directory_cubit.dart';

enum DebtLoadStatus { initial, loading, loaded, error }

class DebtPeopleState extends Equatable {
  const DebtPeopleState({
    this.status = DebtLoadStatus.initial,
    this.items = const [],
    this.totals = const DebtTotals(),
    this.paging = const DebtPaging(),
    this.q = '',
    this.all = false,
    this.sort = DebtPeopleSort.oldest,
    this.side,
    this.loadingMore = false,
    this.error,
    this.moreError,
  });

  final DebtLoadStatus status;
  final List<PersonBalance> items;
  final DebtTotals totals;
  final DebtPaging paging;
  final String q;

  final bool all;

  final DebtPeopleSort sort;

  final NetSide? side;
  final bool loadingMore;
  final ApiException? error;

  final ApiException? moreError;

  bool get hasMore => paging.hasMore;
  bool get isFiltered => q.trim().isNotEmpty || side != null;

  bool get firstLoad =>
      items.isEmpty &&
      (status == DebtLoadStatus.initial || status == DebtLoadStatus.loading);

  DebtPeopleState copyWith({
    DebtLoadStatus? status,
    List<PersonBalance>? items,
    DebtTotals? totals,
    DebtPaging? paging,
    String? q,
    bool? all,
    DebtPeopleSort? sort,
    NetSide? side,
    bool clearSide = false,
    bool? loadingMore,
    ApiException? error,
    bool clearError = false,
    ApiException? moreError,
    bool clearMoreError = false,
  }) => DebtPeopleState(
    status: status ?? this.status,
    items: items ?? this.items,
    totals: totals ?? this.totals,
    paging: paging ?? this.paging,
    q: q ?? this.q,
    all: all ?? this.all,
    sort: sort ?? this.sort,
    side: clearSide ? null : (side ?? this.side),
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearError ? null : (error ?? this.error),
    moreError: clearMoreError ? null : (moreError ?? this.moreError),
  );

  @override
  List<Object?> get props => [
    status,
    items,
    totals,
    paging,
    q,
    all,
    sort,
    side,
    loadingMore,
    error,
    moreError,
  ];
}

/// The debts list page: the directory the app already holds, filtered, sorted
/// and totalled on the device with the backend's own rules. No request of its own.
class DebtPeopleCubit extends Cubit<DebtPeopleState> {
  DebtPeopleCubit({required DebtDirectoryCubit directory})
    : _directory = directory,
      super(const DebtPeopleState()) {
    _sub = directory.stream.listen((_) => _derive());
    _derive();
  }

  final DebtDirectoryCubit _directory;
  late final StreamSubscription<DebtDirectoryState> _sub;

  void _derive({
    String? q,
    bool? all,
    DebtPeopleSort? sort,
    NetSide? side,
    bool clearSide = false,
  }) {
    if (isClosed) return;
    final d = _directory.state;
    final next = state.copyWith(
      q: q,
      all: all,
      sort: sort,
      side: side,
      clearSide: clearSide,
    );
    final items = filterPeople(
      d.people,
      q: next.q,
      all: next.all,
      side: next.side,
      sort: next.sort,
    );
    emit(
      next.copyWith(
        status: switch (d.status) {
          DebtDirectoryStatus.initial => DebtLoadStatus.initial,
          DebtDirectoryStatus.loading => DebtLoadStatus.loading,
          DebtDirectoryStatus.loaded => DebtLoadStatus.loaded,
          DebtDirectoryStatus.error => DebtLoadStatus.error,
        },
        items: items,
        totals: d.totals,
        paging: DebtPaging(
          perPage: items.isEmpty ? 1 : items.length,
          total: items.length,
        ),
        error: d.error,
        clearError: d.error == null,
      ),
    );
  }

  /// Opens the page: syncs only if the app holds no debts yet.
  Future<void> start() => _directory.loadIfNeeded();

  /// Retry / pull-to-refresh.
  Future<void> load() => _directory.load();

  void search(String q) {
    if (q != state.q) _derive(q: q);
  }

  void showAll(bool all) {
    if (all != state.all) _derive(all: all);
  }

  void setSort(DebtPeopleSort sort) {
    if (sort != state.sort) _derive(sort: sort);
  }

  void toggleSide(NetSide side) =>
      state.side == side ? _derive(clearSide: true) : _derive(side: side);

  Future<void> loadMore() async {}

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
