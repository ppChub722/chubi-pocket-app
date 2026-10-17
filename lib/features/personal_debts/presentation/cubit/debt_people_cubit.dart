import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/debt_ledger.dart';
import 'debt_book.dart';

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

class DebtPeopleCubit extends Cubit<DebtPeopleState> with DebtBookListener {
  DebtPeopleCubit({
    required PersonalDebtsRepository repository,
    this.perPage = 30,
    this.debounce = const Duration(milliseconds: 300),
  }) : _repo = repository,
       super(const DebtPeopleState()) {
    DebtBook.attach(this);
  }

  final PersonalDebtsRepository _repo;
  final int perPage;
  final Duration debounce;

  Timer? _searchTimer;

  /// Bumped per page-1 request: an older response never overwrites a newer
  /// search / filter.
  int _generation = 0;

  Future<void> load() async {
    _searchTimer?.cancel();
    final gen = ++_generation;
    emit(
      state.copyWith(
        status: DebtLoadStatus.loading,
        loadingMore: false,
        clearError: true,
        clearMoreError: true,
      ),
    );
    try {
      final page = await _repo.listPeople(
        perPage: perPage,
        q: state.q,
        all: state.all,
        sort: state.sort,
        side: state.side,
      );
      if (gen != _generation || isClosed) return;
      emit(
        state.copyWith(
          status: DebtLoadStatus.loaded,
          items: page.items,
          totals: page.totals,
          paging: page.paging,
        ),
      );
    } catch (e, st) {
      if (gen != _generation || isClosed) return;
      emit(
        state.copyWith(
          status: DebtLoadStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  void search(String q) {
    if (q == state.q) return;
    emit(state.copyWith(q: q));
    _searchTimer?.cancel();
    _searchTimer = Timer(debounce, load);
  }

  void showAll(bool all) {
    if (all == state.all) return;
    emit(state.copyWith(all: all));
    load();
  }

  void setSort(DebtPeopleSort sort) {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort));
    load();
  }

  void toggleSide(NetSide side) {
    if (state.side == side) {
      emit(state.copyWith(clearSide: true));
    } else {
      emit(state.copyWith(side: side));
    }
    load();
  }

  Future<void> loadMore() async {
    final s = state;
    if (!s.hasMore || s.loadingMore || s.status != DebtLoadStatus.loaded) {
      return;
    }
    final gen = _generation;
    emit(s.copyWith(loadingMore: true, clearMoreError: true));
    try {
      final page = await _repo.listPeople(
        page: s.paging.page + 1,
        perPage: perPage,
        q: s.q,
        all: s.all,
        sort: s.sort,
        side: s.side,
      );
      if (gen != _generation || isClosed) return;
      final seen = {for (final p in state.items) p.key};
      emit(
        state.copyWith(
          loadingMore: false,
          items: [
            ...state.items,
            for (final p in page.items)
              if (!seen.contains(p.key)) p,
          ],
          totals: page.totals,
          paging: page.paging,
        ),
      );
    } catch (e, st) {
      if (gen != _generation || isClosed) return;
      emit(
        state.copyWith(loadingMore: false, moreError: ApiException.from(e, st)),
      );
    }
  }

  void applyBalance(PersonBalance b) {
    final i = state.items.indexWhere((p) => p.key == b.key);
    if (i < 0) return;
    final next = [...state.items]..[i] = b;
    emit(state.copyWith(items: next));
  }

  @override
  void onEntrySaved(DebtEntryWriteResult r) {
    if (isClosed || state.status == DebtLoadStatus.initial) return;
    applyBalance(r.balance);
    load();
  }

  @override
  Future<void> close() {
    DebtBook.detach(this);
    _searchTimer?.cancel();
    return super.close();
  }
}
