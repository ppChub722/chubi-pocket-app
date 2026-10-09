import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';

enum ProjectsStatus { initial, loading, loaded, error }

class ProjectsState extends Equatable {
  const ProjectsState({
    this.projects = const [],
    this.status = ProjectsStatus.initial,
    this.error,
    this.statusFilter = 'active',
  });

  final List<Project> projects;
  final ProjectsStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;
  final String statusFilter;

  ProjectsState copyWith({
    List<Project>? projects,
    ProjectsStatus? status,
    ApiException? error,
    String? statusFilter,
    bool clearError = false,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  @override
  List<Object?> get props => [projects, status, error, statusFilter];
}

/// Projects store backed by [ProjectsRepository].
class ProjectsCubit extends Cubit<ProjectsState> with Clearable {
  ProjectsCubit({required ProjectsRepository repository})
    : _repo = repository,
      super(const ProjectsState());

  final ProjectsRepository _repo;

  @override
  void clear() => emit(const ProjectsState());

  Future<void> load({String? statusFilter}) async {
    emit(
      state.copyWith(
        status: ProjectsStatus.loading,
        statusFilter: statusFilter,
        clearError: true,
      ),
    );
    try {
      final list = await _repo.list(status: state.statusFilter);
      emit(state.copyWith(projects: list, status: ProjectsStatus.loaded));
    } catch (e, st) {
      emit(
        state.copyWith(
          status: ProjectsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  Future<Project> create({
    required String name,
    String? type,
    String? description,
    String? startDate,
    String? endDate,
    IconCode? iconCode,
  }) async {
    final p = await _repo.create(
      name: name,
      type: type,
      description: description,
      startDate: startDate,
      endDate: endDate,
      iconCode: iconCode,
    );
    emit(state.copyWith(projects: [p, ...state.projects]));
    return p;
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
  /// plan display, explicit null to hide it).
  Future<Project> update(
    String id, {
    String? name,
    String? description,
    ProjectStatus? status,
    IconCode? iconCode,
    double? plannedAmount,
    bool clearPlannedAmount = false,
  }) async {
    final updated = await _repo.update(
      id,
      name: name,
      description: description,
      status: status,
      iconCode: iconCode,
      plannedAmount: plannedAmount,
      clearPlannedAmount: clearPlannedAmount,
    );
    _replace(updated);
    return updated;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    emit(
      state.copyWith(
        projects: state.projects.where((p) => p.id != id).toList(),
      ),
    );
  }

  void _replace(Project p) {
    emit(
      state.copyWith(
        projects: [
          for (final existing in state.projects)
            if (existing.id == p.id) p else existing,
        ],
      ),
    );
  }
}
