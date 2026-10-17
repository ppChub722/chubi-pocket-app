import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';
import 'widgets/project_common.dart';

enum BoardSort { newest, oldest, amount }

extension BoardSortWire on BoardSort {
  String get wire => switch (this) {
    BoardSort.newest => 'date_desc',
    BoardSort.oldest => 'date_asc',
    BoardSort.amount => 'amount_desc',
  };
}

class ProjectBoardController extends ChangeNotifier {
  ProjectBoardController({required this.repository, required this.projectId});

  final ProjectsRepository repository;
  final String projectId;

  static const perPage = 30;

  String query = '';
  String? tagId;
  bool mine = false;

  String? payerId;
  BoardSort sort = BoardSort.newest;

  List<ProjectTransaction>? rows;
  bool hasMore = false;
  bool loading = false;
  bool loadingMore = false;
  ApiException? error;

  int _page = 0;

  int _seq = 0;
  bool _disposed = false;

  bool get serverFiltered =>
      query.isNotEmpty ||
      tagId != null ||
      mine ||
      payerId != null ||
      sort != BoardSort.newest;

  bool get filtered => serverFiltered;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

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
      payerMemberId: payerId,
      sort: sort.wire,
    );
    hasMore = got.where((t) => t.isParent).length >= perPage;
    return got;
  }

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

  List<ProjectTxTree> trees(ProjectView view) =>
      rows == null ? view.trees : buildProjectTxTree(rows!);
}
