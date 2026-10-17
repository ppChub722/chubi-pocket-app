import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/debt_ledger.dart';
import 'debt_book.dart';
import 'debt_people_cubit.dart';

/// One cycle's list of entries (the current cycle, or the earlier ones).
class DebtEntryList extends Equatable {
  const DebtEntryList({
    this.status = DebtLoadStatus.initial,
    this.items = const [],
    this.paging = const DebtPaging(),
    this.loadingMore = false,
    this.error,
    this.moreError,
  });

  final DebtLoadStatus status;
  final List<DebtEntry> items;
  final DebtPaging paging;
  final bool loadingMore;
  final ApiException? error;
  final ApiException? moreError;

  bool get hasMore => paging.hasMore;
  bool get opened => status != DebtLoadStatus.initial;

  DebtEntryList copyWith({
    DebtLoadStatus? status,
    List<DebtEntry>? items,
    DebtPaging? paging,
    bool? loadingMore,
    ApiException? error,
    bool clearError = false,
    ApiException? moreError,
    bool clearMoreError = false,
  }) => DebtEntryList(
    status: status ?? this.status,
    items: items ?? this.items,
    paging: paging ?? this.paging,
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearError ? null : (error ?? this.error),
    moreError: clearMoreError ? null : (moreError ?? this.moreError),
  );

  @override
  List<Object?> get props => [
    status,
    items,
    paging,
    loadingMore,
    error,
    moreError,
  ];
}

/// The person page (`/personal-debts/people/:key`), page-scoped: a statement
/// grouped by debt cycle. Open = 1 call (person + net + counts + the summary
/// message + the first page of the CURRENT cycle); the earlier cycles = 1
/// call on the first open of the fold; search / filter / sort / next page =
/// 1 call each. A write patches the balance from its response and re-runs
/// the page call (the summary message is BE-built).
class DebtPersonState extends Equatable {
  const DebtPersonState({
    required this.personKey,
    this.status = DebtLoadStatus.initial,
    this.balance,
    this.counts = const DebtCounts(),
    this.message = const DebtSummaryMessage(),
    this.query = const DebtEntryQuery(),
    this.current = const DebtEntryList(),
    this.earlier = const DebtEntryList(),
    this.error,
  });

  final String personKey;
  final DebtLoadStatus status;

  /// The person + net (null until the first load lands).
  final PersonBalance? balance;
  final DebtCounts counts;
  final DebtSummaryMessage message;

  /// Search / filter / sort of the statement (both cycles).
  final DebtEntryQuery query;
  final DebtEntryList current;
  final DebtEntryList earlier;
  final ApiException? error;

  bool get firstLoad =>
      balance == null &&
      (status == DebtLoadStatus.initial || status == DebtLoadStatus.loading);

  /// Anything on the statement can load more.
  bool get hasMore =>
      current.hasMore ||
      (earlier.status == DebtLoadStatus.loaded && earlier.hasMore);

  DebtEntryList list(DebtCycle c) => c == DebtCycle.current ? current : earlier;

  DebtPersonState copyWith({
    DebtLoadStatus? status,
    PersonBalance? balance,
    DebtCounts? counts,
    DebtSummaryMessage? message,
    DebtEntryQuery? query,
    DebtEntryList? current,
    DebtEntryList? earlier,
    ApiException? error,
    bool clearError = false,
  }) => DebtPersonState(
    personKey: personKey,
    status: status ?? this.status,
    balance: balance ?? this.balance,
    counts: counts ?? this.counts,
    message: message ?? this.message,
    query: query ?? this.query,
    current: current ?? this.current,
    earlier: earlier ?? this.earlier,
    error: clearError ? null : (error ?? this.error),
  );

  DebtPersonState withList(DebtCycle c, DebtEntryList list) =>
      c == DebtCycle.current
      ? copyWith(current: list)
      : copyWith(earlier: list);

  @override
  List<Object?> get props => [
    personKey,
    status,
    balance,
    counts,
    message,
    query,
    current,
    earlier,
    error,
  ];
}

class DebtPersonCubit extends Cubit<DebtPersonState> with DebtBookListener {
  DebtPersonCubit({
    required PersonalDebtsRepository repository,
    required String personKey,
    this.perPage = 30,
    this.debounce = const Duration(milliseconds: 300),
  }) : _repo = repository,
       super(DebtPersonState(personKey: personKey)) {
    DebtBook.attach(this);
  }

  final PersonalDebtsRepository _repo;
  final int perPage;
  final Duration debounce;

  Timer? _timer;
  int _loadGen = 0;
  final _gen = <DebtCycle, int>{DebtCycle.current: 0, DebtCycle.earlier: 0};

  String get _key => state.personKey;

  int _bump(DebtCycle c) => _gen[c] = _gen[c]! + 1;

  /// An entry was saved elsewhere (the shell's +): the balance follows the
  /// response at once, then the page call re-runs (the message and the cycle
  /// groups are the server's).
  @override
  void onEntrySaved(DebtEntryWriteResult r) {
    if (r.balance.key != _key || isClosed) return;
    if (state.status == DebtLoadStatus.initial) return;
    emit(state.copyWith(balance: r.balance));
    load();
  }

  /// Open / pull-to-refresh / retry / after a write: the page in ONE call.
  /// The current cycle comes embedded when the statement shows its default
  /// view; with a search / filter active that list re-runs its own query
  /// after. The earlier cycles reload only once their fold has been opened.
  /// Rows already on screen stay while it runs (and after a failure).
  Future<void> load() async {
    _timer?.cancel();
    final gen = ++_loadGen;
    final curGen = _bump(DebtCycle.current);
    emit(state.copyWith(status: DebtLoadStatus.loading, clearError: true));
    try {
      final d = await _repo.person(_key, perPage: perPage);
      if (isClosed || gen != _loadGen) return;
      final filtered = state.query.isFiltered;
      emit(
        state.copyWith(
          status: DebtLoadStatus.loaded,
          balance: d.balance,
          counts: d.counts,
          message: d.message,
          current: filtered || curGen != _gen[DebtCycle.current]
              ? null
              : state.current.copyWith(
                  status: DebtLoadStatus.loaded,
                  items: d.entries.items,
                  paging: d.entries.paging,
                  loadingMore: false,
                  clearError: true,
                  clearMoreError: true,
                ),
        ),
      );
      if (filtered) await _loadList(DebtCycle.current);
      if (isClosed || gen != _loadGen) return;
      if (state.earlier.opened) await _loadList(DebtCycle.earlier);
    } catch (e, st) {
      if (isClosed || gen != _loadGen) return;
      emit(
        state.copyWith(
          status: DebtLoadStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  /// The "รอบก่อนหน้านี้" fold's first open loads the earlier cycles (once).
  Future<void> openEarlier() async {
    if (!state.earlier.opened) await _loadList(DebtCycle.earlier);
  }

  /// The earlier cycles' own retry.
  Future<void> retryEarlier() => _loadList(DebtCycle.earlier);

  /// Typing in the search: one call per cycle shown, once the typing pauses.
  void search(String q) {
    if (q == state.query.q) return;
    emit(state.copyWith(query: state.query.copyWith(q: q)));
    _timer?.cancel();
    _timer = Timer(debounce, _reloadLists);
  }

  /// Direction / sort chips: one call with the new query.
  void setQuery(DebtEntryQuery query) {
    if (query == state.query) return;
    emit(state.copyWith(query: query));
    _timer?.cancel();
    _reloadLists();
  }

  Future<void> _reloadLists() async {
    final earlier = state.earlier.opened;
    await _loadList(DebtCycle.current);
    if (earlier && !isClosed) await _loadList(DebtCycle.earlier);
  }

  Future<void> _loadList(DebtCycle c) async {
    final gen = _bump(c);
    emit(
      state.withList(
        c,
        state
            .list(c)
            .copyWith(
              status: DebtLoadStatus.loading,
              loadingMore: false,
              clearError: true,
              clearMoreError: true,
            ),
      ),
    );
    try {
      final page = await _repo.entries(
        _key,
        query: state.query,
        perPage: perPage,
        cycle: c,
      );
      if (gen != _gen[c] || isClosed) return;
      emit(
        state.withList(
          c,
          state
              .list(c)
              .copyWith(
                status: DebtLoadStatus.loaded,
                items: page.items,
                paging: page.paging,
              ),
        ),
      );
    } catch (e, st) {
      if (gen != _gen[c] || isClosed) return;
      emit(
        state.withList(
          c,
          state
              .list(c)
              .copyWith(
                status: DebtLoadStatus.error,
                error: ApiException.from(e, st),
              ),
        ),
      );
    }
  }

  /// Scrolling near the end: the next page of the current cycle, then of the
  /// earlier ones (once opened).
  Future<void> loadMore() async {
    if (state.current.hasMore) return _loadMore(DebtCycle.current);
    if (state.earlier.status == DebtLoadStatus.loaded &&
        state.earlier.hasMore) {
      return _loadMore(DebtCycle.earlier);
    }
  }

  Future<void> _loadMore(DebtCycle c) async {
    final list = state.list(c);
    if (!list.hasMore ||
        list.loadingMore ||
        list.status != DebtLoadStatus.loaded) {
      return;
    }
    final gen = _gen[c]!;
    emit(
      state.withList(c, list.copyWith(loadingMore: true, clearMoreError: true)),
    );
    try {
      final page = await _repo.entries(
        _key,
        query: state.query,
        page: list.paging.page + 1,
        perPage: perPage,
        cycle: c,
      );
      if (gen != _gen[c] || isClosed) return;
      final cur = state.list(c);
      final seen = {for (final e in cur.items) e.id};
      emit(
        state.withList(
          c,
          cur.copyWith(
            loadingMore: false,
            items: [
              ...cur.items,
              for (final e in page.items)
                if (!seen.contains(e.id)) e,
            ],
            paging: page.paging,
          ),
        ),
      );
    } catch (e, st) {
      if (gen != _gen[c] || isClosed) return;
      emit(
        state.withList(
          c,
          state
              .list(c)
              .copyWith(
                loadingMore: false,
                moreError: ApiException.from(e, st),
              ),
        ),
      );
    }
  }

  /// The "จ่ายแล้ว" label (1 call): the row and the balance patch from the
  /// response, then the page call re-runs (the message lists open entries).
  /// Throws the [ApiException] so the page can show it.
  Future<void> setPaid(String entryId, bool paid) async {
    final res = await _repo.setPaid(entryId, paid);
    if (isClosed) return;
    var next = state;
    for (final c in DebtCycle.values) {
      final list = next.list(c);
      if (!list.items.any((e) => e.id == entryId)) continue;
      next = next.withList(
        c,
        list.copyWith(
          items: [for (final e in list.items) e.id == entryId ? res.entry : e],
        ),
      );
    }
    if (res.balance.key == _key) {
      next = next.copyWith(balance: res.balance);
    }
    emit(next);
    unawaited(load());
  }

  /// A write elsewhere (tx detail) returned this person's balance: the hero
  /// follows it at once. The statement reloads on the next open / pull.
  void applyBalance(PersonBalance b) {
    if (b.key != _key) return;
    emit(state.copyWith(balance: b));
  }

  @override
  Future<void> close() {
    DebtBook.detach(this);
    _timer?.cancel();
    return super.close();
  }
}
