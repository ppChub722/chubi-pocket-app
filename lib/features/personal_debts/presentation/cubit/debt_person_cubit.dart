import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/debt_ledger.dart';
import 'debt_book.dart';
import 'debt_people_cubit.dart';

/// One tab's list of entries (the timeline, or the money history).
class DebtEntryList extends Equatable {
  const DebtEntryList({
    this.status = DebtLoadStatus.initial,
    this.items = const [],
    this.paging = const DebtPaging(),
    this.query = const DebtEntryQuery(),
    this.loadingMore = false,
    this.error,
    this.moreError,
  });

  final DebtLoadStatus status;
  final List<DebtEntry> items;
  final DebtPaging paging;
  final DebtEntryQuery query;
  final bool loadingMore;
  final ApiException? error;
  final ApiException? moreError;

  bool get hasMore => paging.hasMore;
  bool get firstLoad =>
      items.isEmpty &&
      (status == DebtLoadStatus.initial || status == DebtLoadStatus.loading);

  DebtEntryList copyWith({
    DebtLoadStatus? status,
    List<DebtEntry>? items,
    DebtPaging? paging,
    DebtEntryQuery? query,
    bool? loadingMore,
    ApiException? error,
    bool clearError = false,
    ApiException? moreError,
    bool clearMoreError = false,
  }) => DebtEntryList(
    status: status ?? this.status,
    items: items ?? this.items,
    paging: paging ?? this.paging,
    query: query ?? this.query,
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearError ? null : (error ?? this.error),
    moreError: clearMoreError ? null : (moreError ?? this.moreError),
  );

  @override
  List<Object?> get props => [
    status,
    items,
    paging,
    query,
    loadingMore,
    error,
    moreError,
  ];
}

/// The two tabs of the person page.
enum DebtPersonTab { entries, money }

/// The person page (`/personal-debts/people/:key`), page-scoped.
/// Open = 1 call (person + net + the first timeline page); the money tab
/// = 1 call on its first open; search / filter / sort / next page = 1 call
/// each. Writes patch from their response ([applyBalance], [setPaid]).
class DebtPersonState extends Equatable {
  const DebtPersonState({
    required this.personKey,
    this.status = DebtLoadStatus.initial,
    this.balance,
    this.entryCount = 0,
    this.moneyCount = 0,
    this.entries = const DebtEntryList(),
    this.money = const DebtEntryList(query: DebtEntryQuery(moneyOnly: true)),
    this.error,
  });

  final String personKey;
  final DebtLoadStatus status;

  /// The person + net (null until the first load lands).
  final PersonBalance? balance;
  final int entryCount;
  final int moneyCount;
  final DebtEntryList entries;
  final DebtEntryList money;
  final ApiException? error;

  bool get firstLoad =>
      balance == null &&
      (status == DebtLoadStatus.initial || status == DebtLoadStatus.loading);

  DebtEntryList tab(DebtPersonTab t) =>
      t == DebtPersonTab.entries ? entries : money;

  DebtPersonState copyWith({
    DebtLoadStatus? status,
    PersonBalance? balance,
    int? entryCount,
    int? moneyCount,
    DebtEntryList? entries,
    DebtEntryList? money,
    ApiException? error,
    bool clearError = false,
  }) => DebtPersonState(
    personKey: personKey,
    status: status ?? this.status,
    balance: balance ?? this.balance,
    entryCount: entryCount ?? this.entryCount,
    moneyCount: moneyCount ?? this.moneyCount,
    entries: entries ?? this.entries,
    money: money ?? this.money,
    error: clearError ? null : (error ?? this.error),
  );

  DebtPersonState withTab(DebtPersonTab t, DebtEntryList list) =>
      t == DebtPersonTab.entries
      ? copyWith(entries: list)
      : copyWith(money: list);

  @override
  List<Object?> get props => [
    personKey,
    status,
    balance,
    entryCount,
    moneyCount,
    entries,
    money,
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

  /// An entry was saved elsewhere (the shell's +): patch from the response.
  @override
  void onEntrySaved(DebtEntryWriteResult r) => addEntry(r);

  final PersonalDebtsRepository _repo;
  final int perPage;
  final Duration debounce;

  final _gen = <DebtPersonTab, int>{
    DebtPersonTab.entries: 0,
    DebtPersonTab.money: 0,
  };
  final _timers = <DebtPersonTab, Timer>{};

  String get _key => state.personKey;

  int _bump(DebtPersonTab t) => _gen[t] = _gen[t]! + 1;

  /// Open / pull-to-refresh / retry: the page in ONE call. The timeline
  /// comes embedded when it shows its default view; with a search / filter
  /// active the timeline re-runs its own query after. The money tab reloads
  /// only once it has been opened.
  Future<void> load() async {
    final gen = _bump(DebtPersonTab.entries);
    emit(
      state.copyWith(
        status: DebtLoadStatus.loading,
        clearError: true,
        entries: state.entries.copyWith(
          status: DebtLoadStatus.loading,
          clearError: true,
          clearMoreError: true,
        ),
      ),
    );
    try {
      final d = await _repo.person(_key, perPage: perPage);
      if (isClosed) return;
      final filtered = state.entries.query.isFiltered;
      emit(
        state.copyWith(
          status: DebtLoadStatus.loaded,
          balance: d.balance,
          entryCount: d.entryCount,
          moneyCount: d.moneyCount,
          entries: filtered || gen != _gen[DebtPersonTab.entries]
              ? null
              : state.entries.copyWith(
                  status: DebtLoadStatus.loaded,
                  items: d.entries.items,
                  paging: d.entries.paging,
                  loadingMore: false,
                ),
        ),
      );
      if (filtered && gen == _gen[DebtPersonTab.entries]) {
        await _loadTab(DebtPersonTab.entries);
      }
      if (state.money.status != DebtLoadStatus.initial) {
        await _loadTab(DebtPersonTab.money);
      }
    } catch (e, st) {
      if (isClosed) return;
      final err = ApiException.from(e, st);
      emit(
        state.copyWith(
          status: DebtLoadStatus.error,
          error: err,
          entries: gen == _gen[DebtPersonTab.entries]
              ? state.entries.copyWith(status: DebtLoadStatus.error, error: err)
              : null,
        ),
      );
    }
  }

  /// The money tab's first open loads it (once).
  Future<void> openTab(DebtPersonTab t) async {
    if (state.tab(t).status == DebtLoadStatus.initial) await _loadTab(t);
  }

  /// A tab's retry (its own error view).
  Future<void> retryTab(DebtPersonTab t) => _loadTab(t);

  void search(DebtPersonTab t, String q) {
    final list = state.tab(t);
    if (q == list.query.q) return;
    emit(state.withTab(t, list.copyWith(query: list.query.copyWith(q: q))));
    _timers[t]?.cancel();
    _timers[t] = Timer(debounce, () => _loadTab(t));
  }

  /// Sort / filter chips: one call with the new query.
  void setQuery(DebtPersonTab t, DebtEntryQuery query) {
    final list = state.tab(t);
    if (query == list.query) return;
    emit(state.withTab(t, list.copyWith(query: query)));
    _timers[t]?.cancel();
    _loadTab(t);
  }

  Future<void> _loadTab(DebtPersonTab t) async {
    _timers[t]?.cancel();
    final gen = _bump(t);
    emit(
      state.withTab(
        t,
        state
            .tab(t)
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
        query: state.tab(t).query,
        perPage: perPage,
      );
      if (gen != _gen[t] || isClosed) return;
      emit(
        state.withTab(
          t,
          state
              .tab(t)
              .copyWith(
                status: DebtLoadStatus.loaded,
                items: page.items,
                paging: page.paging,
              ),
        ),
      );
    } catch (e, st) {
      if (gen != _gen[t] || isClosed) return;
      emit(
        state.withTab(
          t,
          state
              .tab(t)
              .copyWith(
                status: DebtLoadStatus.error,
                error: ApiException.from(e, st),
              ),
        ),
      );
    }
  }

  Future<void> loadMore(DebtPersonTab t) async {
    final list = state.tab(t);
    if (!list.hasMore ||
        list.loadingMore ||
        list.status != DebtLoadStatus.loaded) {
      return;
    }
    final gen = _gen[t]!;
    emit(
      state.withTab(t, list.copyWith(loadingMore: true, clearMoreError: true)),
    );
    try {
      final page = await _repo.entries(
        _key,
        query: list.query,
        page: list.paging.page + 1,
        perPage: perPage,
      );
      if (gen != _gen[t] || isClosed) return;
      final cur = state.tab(t);
      final seen = {for (final e in cur.items) e.id};
      emit(
        state.withTab(
          t,
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
      if (gen != _gen[t] || isClosed) return;
      emit(
        state.withTab(
          t,
          state
              .tab(t)
              .copyWith(
                loadingMore: false,
                moreError: ApiException.from(e, st),
              ),
        ),
      );
    }
  }

  /// The "จ่ายแล้ว" label (1 call); both tabs patch from the response.
  /// Throws the [ApiException] so the page can show it.
  Future<void> setPaid(String entryId, bool paid) async {
    final res = await _repo.setPaid(entryId, paid);
    if (isClosed) return;
    var next = state;
    for (final t in DebtPersonTab.values) {
      final list = next.tab(t);
      if (!list.items.any((e) => e.id == entryId)) continue;
      next = next.withTab(
        t,
        list.copyWith(
          items: [for (final e in list.items) e.id == entryId ? res.entry : e],
        ),
      );
    }
    if (res.balance.key == _key) {
      next = next.copyWith(balance: res.balance);
    }
    emit(next);
  }

  /// Quick create (debt mode) saved an entry for this person: the hero and
  /// counts follow `person_balance`, and the entry joins each loaded tab
  /// that shows the default view (newest first), in date order. A filtered
  /// tab, or a save that also labelled other entries paid (the open count
  /// says so), re-runs that list.
  void addEntry(DebtEntryWriteResult r) {
    if (r.balance.key != _key || isClosed) return;
    final e = r.entry;
    final before = state.balance?.openCount ?? 0;
    final labelled = r.balance.openCount != before + (e.paid ? 0 : 1);
    var next = state.copyWith(
      balance: r.balance,
      entryCount: state.entryCount + 1,
      moneyCount: state.moneyCount + (e.movedMoney ? 1 : 0),
    );
    final stale = <DebtPersonTab>[];
    for (final t in DebtPersonTab.values) {
      final list = next.tab(t);
      if (list.status != DebtLoadStatus.loaded) continue;
      if (t == DebtPersonTab.money && !e.movedMoney && !labelled) continue;
      if (labelled || list.query.isFiltered) {
        stale.add(t);
        continue;
      }
      final items = _insertByDate(list.items, e, hasMore: list.hasMore);
      next = next.withTab(t, list.copyWith(items: items));
    }
    emit(next);
    for (final t in stale) {
      _loadTab(t);
    }
  }

  /// Newest first: [e] goes before the first entry that is older. Older
  /// than every loaded row with more pages to come: a later page brings it.
  static List<DebtEntry> _insertByDate(
    List<DebtEntry> items,
    DebtEntry e, {
    required bool hasMore,
  }) {
    final d = e.date;
    final at = d == null
        ? 0
        : items.indexWhere((x) => x.date == null || !x.date!.isAfter(d));
    if (at < 0 && hasMore) return items;
    return [...items]..insert(at < 0 ? items.length : at, e);
  }

  /// A write elsewhere (quick create in debt mode, tx detail) returned this
  /// person's balance: the hero follows it at once. The lists reload on the
  /// next open / pull (the new entry's place depends on the server's sort).
  void applyBalance(PersonBalance b) {
    if (b.key != _key) return;
    emit(state.copyWith(balance: b));
  }

  @override
  Future<void> close() {
    DebtBook.detach(this);
    for (final t in _timers.values) {
      t.cancel();
    }
    return super.close();
  }
}
