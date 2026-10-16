import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/debt_ledger.dart';
import 'debt_book.dart';

enum DebtLoadStatus { initial, loading, loaded, error }

/// The people list (`/personal-debts`), page-scoped: open = 1 call, search /
/// filter / next page = 1 call each, all on the server. Writes elsewhere
/// patch a row with [applyBalance] (no re-fetch).
class DebtPeopleState extends Equatable {
  const DebtPeopleState({
    this.status = DebtLoadStatus.initial,
    this.items = const [],
    this.totals = const DebtTotals(),
    this.paging = const DebtPaging(),
    this.q = '',
    this.all = false,
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

  /// "ทั้งหมด": settled people too.
  final bool all;

  /// The summary-box filter (ติดคุณ / คุณติด); null = both.
  final NetSide? side;
  final bool loadingMore;
  final ApiException? error;

  /// The last load-more failed (the list stays; the footer offers a retry).
  final ApiException? moreError;

  bool get hasMore => paging.hasMore;
  bool get isFiltered => q.trim().isNotEmpty || side != null;

  /// First load only: later reloads keep the rows on screen.
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

  /// Page 1 with the current search / filters (open, pull-to-refresh, retry).
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

  /// Typing in the search: one call once the typing pauses.
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

  /// Tap a summary box: filter to that side; tap it again: both.
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

  /// A write's `person_balance`: patch that person's row in place. A new
  /// person, or one who no longer matches the filter, waits for the next
  /// load (the list is the server's view).
  void applyBalance(PersonBalance b) {
    final i = state.items.indexWhere((p) => p.key == b.key);
    if (i < 0) return;
    final next = [...state.items]..[i] = b;
    emit(state.copyWith(items: next));
  }

  /// An entry was saved elsewhere (the shell's +): the person's row follows
  /// its balance at once; the list reloads for the totals and for a new
  /// person (the list is the server's view). Only once the list has loaded.
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
