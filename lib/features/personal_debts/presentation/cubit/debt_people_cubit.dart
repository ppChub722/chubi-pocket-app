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
    this.overdue30 = false,
    this.counts = const {},
    this.loadingMore = false,
    this.error,
    this.moreError,
  });

  /// Only people whose oldest open debt is more than 30 days old.
  final bool overdue30;

  /// Each filter chip's count.
  final Map<DebtListFilter, int> counts;

  /// The chip picked (mock DebtsList: ทั้งหมด / รอรับ / รอจ่าย / ค้างเกิน 30
  /// วัน).
  DebtListFilter get filter => overdue30
      ? DebtListFilter.overdue30
      : switch (side) {
          NetSide.owedToMe => DebtListFilter.receivable,
          NetSide.iOwe => DebtListFilter.payable,
          _ => DebtListFilter.all,
        };

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
  bool get isFiltered => q.trim().isNotEmpty || side != null || overdue30;

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
    bool? overdue30,
    Map<DebtListFilter, int>? counts,
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
    overdue30: overdue30 ?? this.overdue30,
    counts: counts ?? this.counts,
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
    overdue30,
    counts,
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
    bool? overdue30,
  }) {
    if (isClosed) return;
    final d = _directory.state;
    final next = state.copyWith(
      q: q,
      all: all,
      sort: sort,
      side: side,
      clearSide: clearSide,
      overdue30: overdue30,
    );
    final items = filterPeople(
      d.people,
      q: next.q,
      all: next.all,
      side: next.side,
      overdue30: next.overdue30,
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
        counts: countPeople(d.people),
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

  /// One chip at a time (mock DebtsList).
  void setFilter(DebtListFilter f) => switch (f) {
    DebtListFilter.all => _derive(clearSide: true, overdue30: false),
    DebtListFilter.receivable => _derive(
      side: NetSide.owedToMe,
      overdue30: false,
    ),
    DebtListFilter.payable => _derive(side: NetSide.iOwe, overdue30: false),
    DebtListFilter.overdue30 => _derive(clearSide: true, overdue30: true),
  };

  Future<void> loadMore() async {}

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
