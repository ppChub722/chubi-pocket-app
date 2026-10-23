import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/data/data_changes.dart';
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
    this.statusFilter = 'current',
    this.page = 0,
    this.totalPages = 0,
    this.loadingMore = false,
    this.query = '',
    this.tagIds = const [],
    this.sort = ProjectSort.updatedDesc,
    this.summary,
  });

  final List<Project> projects;

  final ProjectListSummary? summary;
  final ProjectsStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;

  /// The BE `status`: current (all but archived) | active | unsettled |
  /// receivable | payable | ended.
  final String statusFilter;

  final int page;
  final int totalPages;

  final bool loadingMore;

  final String query;
  final List<String> tagIds;
  final ProjectSort sort;

  bool get filtered =>
      statusFilter != 'current' || query.trim().isNotEmpty || tagIds.isNotEmpty;

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
    ProjectListSummary? summary,
    bool clearError = false,
  }) {
    return ProjectsState(
      summary: summary ?? this.summary,
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
    summary,
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

class ProjectsCubit extends Cubit<ProjectsState>
    with Clearable, RefreshOnDataChange<ProjectsState> {
  ProjectsCubit({required ProjectsRepository repository})
    : _repo = repository,
      super(const ProjectsState()) {
    refreshOn({DataTable.projects}, () async {
      if (state.status != ProjectsStatus.initial) await load(silent: true);
    });
  }

  final ProjectsRepository _repo;

  @override
  void clear() => emit(const ProjectsState());

  /// Loads only when there is nothing usable cached: never loaded, failed, or
  /// narrowed to another status (the event picker lists the ACTIVE ones).
  Future<void> loadIfNeeded() async {
    final usable =
        state.status == ProjectsStatus.loaded && state.statusFilter == 'active';
    if (usable || state.status == ProjectsStatus.loading) return;
    await load();
  }

  Future<void> load({
    String? statusFilter,
    String? query,
    List<String>? tagIds,
    ProjectSort? sort,
    bool silent = false,
  }) async {
    emit(
      state.copyWith(
        status: silent && state.status == ProjectsStatus.loaded
            ? null
            : ProjectsStatus.loading,
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
      if (!_same(state, asked)) return;
      emit(
        state.copyWith(
          projects: p.projects,
          summary: p.summary,
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

  Future<EventPatch> archive(String id) async {
    final p = await _repo.archive(id);
    patch(p.project);
    return p;
  }

  Future<EventPatch> restore(String id) async {
    final p = await _repo.restore(id);
    patch(p.project);
    return p;
  }

  Future<Map<String, double>> delete(
    String id, {
    bool deleteLinkedTxs = false,
  }) async {
    final balances = await _repo.delete(id, deleteLinkedTxs: deleteLinkedTxs);
    remove(id);
    return balances;
  }

  void patch(Project p) {
    if (!state.projects.any((x) => x.id == p.id)) return;
    final f = state.statusFilter;
    const stored = {'active', 'completed', 'cancelled', 'archived'};
    if (stored.contains(f) && p.status.wire != f) return remove(p.id);
    if (f == 'current' && p.status == ProjectStatus.archived) {
      return remove(p.id);
    }
    emit(
      state.copyWith(
        projects: [
          for (final existing in state.projects)
            if (existing.id == p.id) p else existing,
        ],
      ),
    );
  }

  void remove(String id) => emit(
    state.copyWith(projects: state.projects.where((p) => p.id != id).toList()),
  );
}
