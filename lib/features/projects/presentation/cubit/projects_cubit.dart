import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';

enum ProjectsStatus { initial, loading, loaded, error }

class ProjectsState extends Equatable {
  const ProjectsState({
    this.projects = const [],
    this.status = ProjectsStatus.initial,
    this.errorMessage,
    this.statusFilter = 'active',
  });

  final List<Project> projects;
  final ProjectsStatus status;
  final String? errorMessage;
  final String statusFilter;

  ProjectsState copyWith({
    List<Project>? projects,
    ProjectsStatus? status,
    String? errorMessage,
    String? statusFilter,
    bool clearError = false,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  @override
  List<Object?> get props =>
      [projects, status, errorMessage, statusFilter];
}

class ProjectsCubit extends Cubit<ProjectsState> with Clearable {
  ProjectsCubit({required ProjectsRepository repository})
      : _repo = repository,
        super(const ProjectsState());

  final ProjectsRepository _repo;

  @override
  void clear() => emit(const ProjectsState());

  Future<void> load({String? statusFilter}) async {
    emit(state.copyWith(
      status: ProjectsStatus.loading,
      statusFilter: statusFilter,
      clearError: true,
    ));
    try {
      final list = await _repo.list(status: state.statusFilter);
      emit(state.copyWith(projects: list, status: ProjectsStatus.loaded));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: ProjectsStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  Future<Project> create({
    required String name,
    String? type,
    String? description,
    String? startDate,
    String? endDate,
  }) async {
    final p = await _repo.create(
      name: name,
      type: type,
      description: description,
      startDate: startDate,
      endDate: endDate,
    );
    emit(state.copyWith(projects: [p, ...state.projects]));
    return p;
  }

  Future<Project> update(String id, {
    String? name,
    String? description,
    ProjectStatus? status,
  }) async {
    final updated = await _repo.update(
      id,
      name: name,
      description: description,
      status: status,
    );
    _replace(updated);
    return updated;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    emit(state.copyWith(
      projects: state.projects.where((p) => p.id != id).toList(),
    ));
  }

  void _replace(Project p) {
    emit(state.copyWith(
      projects: [
        for (final existing in state.projects)
          if (existing.id == p.id) p else existing,
      ],
    ));
  }
}
