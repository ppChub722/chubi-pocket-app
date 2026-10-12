import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../../../../ui/ui.dart';

enum ProjectsStatus { initial, loading, loaded, error }

class ProjectsState extends Equatable {
  const ProjectsState({
    this.projects = const [],
    this.status = ProjectsStatus.initial,
    this.error,
    this.statusFilter = 'active',
    this.page = 0,
    this.totalPages = 0,
    this.loadingMore = false,
    this.query = '',
    this.tagIds = const [],
    this.sort = ProjectSort.updatedDesc,
  });

  final List<Project> projects;
  final ProjectsStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;
  final String statusFilter;

  /// The last page loaded (0 = none yet) and the server's page count.
  final int page;
  final int totalPages;

  /// The next page is in flight.
  final bool loadingMore;

  /// Server-side filters: name search, MY tags (any), sort.
  final String query;
  final List<String> tagIds;
  final ProjectSort sort;

  /// The filters narrow the list (an empty result is "no match").
  bool get filtered =>
      statusFilter != 'active' || query.trim().isNotEmpty || tagIds.isNotEmpty;

  bool get hasMore => page > 0 && page < totalPages;

  ProjectsState copyWith({
    List<Project>? projects,
    ProjectsStatus? status,
    ApiException? error,
    String? statusFilter,
    int? page,
    int? totalPages,
    bool? loadingMore,
    String? query,
    List<String>? tagIds,
    ProjectSort? sort,
    bool clearError = false,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      statusFilter: statusFilter ?? this.statusFilter,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      loadingMore: loadingMore ?? this.loadingMore,
      query: query ?? this.query,
      tagIds: tagIds ?? this.tagIds,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [
    projects,
    status,
    error,
    statusFilter,
    page,
    totalPages,
    loadingMore,
    query,
    tagIds,
    sort,
  ];
}

/// Projects store backed by [ProjectsRepository]: the events list (paged)
/// and the event picker's source.
class ProjectsCubit extends Cubit<ProjectsState> with Clearable {
  ProjectsCubit({required ProjectsRepository repository})
    : _repo = repository,
      super(const ProjectsState());

  final ProjectsRepository _repo;

  @override
  void clear() => emit(const ProjectsState());

  /// Loads only when there is nothing usable cached: never loaded, failed, or
  /// narrowed to another status (the event picker lists the ACTIVE ones). The
  /// picker calls this on every open — it must not cost a GET /projects each
  /// time; creating an event refreshes the list itself.
  Future<void> loadIfNeeded() async {
    final usable =
        state.status == ProjectsStatus.loaded && state.statusFilter == 'active';
    if (usable || state.status == ProjectsStatus.loading) return;
    await load();
  }

  /// The first page (again), optionally with other filters (null = keep).
  Future<void> load({
    String? statusFilter,
    String? query,
    List<String>? tagIds,
    ProjectSort? sort,
  }) async {
    emit(
      state.copyWith(
        status: ProjectsStatus.loading,
        statusFilter: statusFilter,
        query: query,
        tagIds: tagIds,
        sort: sort,
        loadingMore: false,
        clearError: true,
      ),
    );
    final asked = state;
    try {
      final p = await _list(asked);
      // A newer load (other filters) owns the state now.
      if (!_same(state, asked)) return;
      emit(
        state.copyWith(
          projects: p.projects,
          status: ProjectsStatus.loaded,
          page: p.page,
          totalPages: p.totalPages,
        ),
      );
    } catch (e, st) {
      emit(
        state.copyWith(
          status: ProjectsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  /// The next page, appended. A failure keeps the rows and rethrows (the
  /// page shows a message).
  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.loadingMore ||
        state.status != ProjectsStatus.loaded) {
      return;
    }
    final asked = state;
    emit(state.copyWith(loadingMore: true));
    try {
      final p = await _list(asked, page: asked.page + 1);
      if (!_same(state, asked)) return;
      final seen = {for (final x in state.projects) x.id};
      emit(
        state.copyWith(
          projects: [
            ...state.projects,
            ...p.projects.where((x) => !seen.contains(x.id)),
          ],
          page: p.page,
          totalPages: p.totalPages,
          loadingMore: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(loadingMore: false));
      rethrow;
    }
  }

  Future<ProjectPage> _list(ProjectsState s, {int page = 1}) => _repo.list(
    status: s.statusFilter,
    q: s.query,
    tagIds: s.tagIds,
    sort: s.sort,
    page: page,
  );

  static bool _same(ProjectsState a, ProjectsState b) =>
      a.statusFilter == b.statusFilter &&
      a.query == b.query &&
      a.sort == b.sort &&
      _sameIds(a.tagIds, b.tagIds);

  static bool _sameIds(List<String> a, List<String> b) =>
      a.length == b.length && a.every(b.contains);

  /// One call (plan, dates, my tags) → the new event (first in the list).
  /// [startDate] / [endDate] are `YYYY-MM-DD`.
  Future<Project> create({
    required String name,
    String? description,
    String? note,
    String? startDate,
    String? endDate,
    double? plannedAmount,
    List<String> tagIds = const [],
    IconCode? iconCode,
  }) async {
    final d = await _repo.create(
      name: name,
      description: description,
      note: note,
      startDate: startDate,
      endDate: endDate,
      plannedAmount: plannedAmount,
      tagIds: tagIds,
      iconCode: iconCode,
    );
    emit(state.copyWith(projects: [d.project, ...state.projects]));
    return d.project;
  }

  /// Quick create from bills (spec §10/4.24, API §10 "Quick create"):
  /// one atomic call — project + auto-added members + auto-claimed board
  /// rows for the new bill and every ticked past bill. Re-throws
  /// [ApiException] so the page can map `TX_NOT_FOUND` /
  /// `TX_ALREADY_IN_PROJECT` / `VALIDATION_ERROR` to friendly copy.
  Future<QuickCreateResult> quickCreate({
    required String name,
    required Map<String, dynamic> newTransaction,
    List<String> transactionIds = const [],
  }) async {
    final result = await _repo.quickCreate(
      name: name,
      newTransaction: newTransaction,
      transactionIds: transactionIds,
    );
    emit(state.copyWith(projects: [result.project, ...state.projects]));
    return result;
  }

  /// `plannedAmount` / `clearPlannedAmount` follow the repository's
  /// presence semantics (spec §10/4.23 — set a number to enable the
  /// plan display, explicit null to hide it); dates the same way
  /// (`YYYY-MM-DD`). [tagIds] = MY tags. Returns the event page's patch.
  Future<EventPatch> update(
    String id, {
    String? name,
    String? description,
    String? note,
    String? startDate,
    String? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
    ProjectStatus? status,
    IconCode? iconCode,
    double? plannedAmount,
    bool clearPlannedAmount = false,
    List<String>? tagIds,
  }) async {
    final p = await _repo.update(
      id,
      name: name,
      description: description,
      note: note,
      startDate: startDate,
      endDate: endDate,
      clearStartDate: clearStartDate,
      clearEndDate: clearEndDate,
      status: status,
      iconCode: iconCode,
      plannedAmount: plannedAmount,
      clearPlannedAmount: clearPlannedAmount,
      tagIds: tagIds,
    );
    patch(p.project);
    return p;
  }

  /// Returns the wallets the deleted transactions moved.
  Future<Map<String, double>> delete(
    String id, {
    bool deleteLinkedTxs = false,
  }) async {
    final balances = await _repo.delete(id, deleteLinkedTxs: deleteLinkedTxs);
    remove(id);
    return balances;
  }

  /// Puts the server's copy of [p] in the list (a write on the event page),
  /// so going back needs no reload. Unknown ids are left out (another
  /// filter / page); a status change out of the current filter drops it.
  void patch(Project p) {
    if (!state.projects.any((x) => x.id == p.id)) return;
    final filter = state.statusFilter;
    if (filter != 'all' && p.status.wire != filter) return remove(p.id);
    emit(
      state.copyWith(
        projects: [
          for (final existing in state.projects)
            if (existing.id == p.id) p else existing,
        ],
      ),
    );
  }

  /// Drops [id] from the list (deleted / left).
  void remove(String id) => emit(
    state.copyWith(projects: state.projects.where((p) => p.id != id).toList()),
  );
}
