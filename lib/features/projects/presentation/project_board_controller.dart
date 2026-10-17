import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';
import 'widgets/project_common.dart';

/// The bills' sort (BE `sort` of `GET /projects/:id/transactions`).
enum BoardSort { newest, oldest, amount }

extension BoardSortWire on BoardSort {
  String get wire => switch (this) {
    BoardSort.newest => 'date_desc',
    BoardSort.oldest => 'date_asc',
    BoardSort.amount => 'amount_desc',
  };
}

/// Logic only (no widgets): the event page's bills filter — search, event
/// tag, "mine", sort — and the server rows it brings.
///
/// Unfiltered, the page shows the board its one open call brought (more
/// pages through the page); any filter runs ONE call on
/// `GET /projects/:id/transactions` and its rows replace the list. The payer
/// filter has no BE parameter yet: it narrows the rows already on screen by
/// the payer the BE sent on each (a presentation filter, nothing computed).
/// A failed call keeps the rows on screen and sets [error].
class ProjectBoardController extends ChangeNotifier {
  ProjectBoardController({required this.repository, required this.projectId});

  final ProjectsRepository repository;
  final String projectId;

  static const perPage = 30;

  String query = '';
  String? tagId;
  bool mine = false;

  /// A project member id; narrows the visible bills client-side.
  String? payerId;
  BoardSort sort = BoardSort.newest;

  /// The server's filtered rows (flat) while a server filter is on; null =
  /// the page's own board.
  List<ProjectTransaction>? rows;
  bool hasMore = false;
  bool loading = false;
  bool loadingMore = false;
  ApiException? error;

  int _page = 0;

  /// Bumped on every new query: a late answer for an older one is dropped.
  int _seq = 0;
  bool _disposed = false;

  bool get serverFiltered =>
      query.isNotEmpty || tagId != null || mine || sort != BoardSort.newest;

  /// Anything narrows or reorders the bills (the 🔍's red dot).
  bool get filtered => serverFiltered || payerId != null;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Runs the filter as it is now: one call, or back to the page's board.
  Future<void> reload() async {
    final seq = ++_seq;
    if (!serverFiltered) {
      rows = null;
      error = null;
      loading = false;
      hasMore = false;
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final got = await _fetch(1);
      if (seq != _seq) return;
      rows = got;
      _page = 1;
    } catch (e, st) {
      if (seq != _seq) return;
      error = ApiException.from(e, st);
    }
    loading = false;
    notifyListeners();
  }

  static const Object _keep = Object();

  /// A filter change, then the one call. [tagId] / [payerId]: omit = keep,
  /// null = clear.
  Future<void> change({
    String? query,
    Object? tagId = _keep,
    bool? mine,
    Object? payerId = _keep,
    BoardSort? sort,
  }) {
    if (query != null) this.query = query;
    if (!identical(tagId, _keep)) this.tagId = tagId as String?;
    if (mine != null) this.mine = mine;
    if (!identical(payerId, _keep)) this.payerId = payerId as String?;
    if (sort != null) this.sort = sort;
    return reload();
  }

  Future<List<ProjectTransaction>> _fetch(int page) async {
    final got = await repository.listTransactions(
      projectId,
      page: page,
      perPage: perPage,
      mine: mine,
      q: query,
      tagId: tagId,
      sort: sort.wire,
    );
    hasMore = got.where((t) => t.isParent).length >= perPage;
    return got;
  }

  /// The next filtered page (appended); the page's own board pages itself.
  /// Rethrows so the page can say it failed.
  Future<void> loadMore() async {
    if (rows == null || !hasMore || loadingMore) return;
    final seq = _seq;
    loadingMore = true;
    notifyListeners();
    try {
      final more = await _fetch(_page + 1);
      if (seq != _seq) return;
      final seen = {for (final t in rows!) t.id};
      rows = [...rows!, ...more.where((t) => !seen.contains(t.id))];
      _page++;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  /// A write on the page: keep the filtered rows in step — every row the
  /// write changed swapped for its new copy; rows the page had and no
  /// longer has (a removed bill / split) drop out; rows only in the
  /// filtered results stay.
  void viewChanged(ProjectView before, ProjectView after) {
    final current = rows;
    if (current == null) return;
    final now = {for (final t in after.txs) t.id: t};
    final had = {for (final t in before.txs) t.id};
    rows = [
      for (final t in current)
        if (now[t.id] case final fresh?) fresh else if (!had.contains(t.id)) t,
    ];
    notifyListeners();
  }

  /// The bills to show: the filtered rows (or the page's board) as trees,
  /// narrowed by the payer when one is picked.
  List<ProjectTxTree> trees(ProjectView view) {
    final base = rows == null ? view.trees : buildProjectTxTree(rows!);
    final payer = payerId;
    if (payer == null) return base;
    return [
      for (final t in base)
        if (view.memberOf(t.parent).id == payer) t,
    ];
  }
}
