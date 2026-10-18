import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/data/sync_backed.dart';
import '../../../../core/data/sync_coordinator.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/project.dart';

enum ProjectDirectoryStatus { initial, loading, loaded, error }

class ProjectDirectoryState extends Equatable {
  const ProjectDirectoryState({
    this.projects = const [],
    this.status = ProjectDirectoryStatus.initial,
    this.error,
  });

  /// Every event the caller belongs to, whatever its status.
  final List<Project> projects;
  final ProjectDirectoryStatus status;
  final ApiException? error;

  /// Events a bill can go to: active, and the caller is a member who is not a viewer.
  List<Project> get formEvents => [
    for (final p in projects)
      if (p.isActive && p.myRole != null && p.myRole != MemberRole.viewer) p,
  ];

  @override
  List<Object?> get props => [projects, status, error];
}

/// The events the pickers choose from. The events page keeps its own filtered,
/// paged list (`ProjectsCubit`).
class ProjectDirectoryCubit extends Cubit<ProjectDirectoryState>
    with Clearable, SyncBacked<ProjectDirectoryState> {
  ProjectDirectoryCubit({required SyncCoordinator coordinator})
    : syncCoordinator = coordinator,
      super(const ProjectDirectoryState()) {
    bindSync();
  }

  @override
  final SyncCoordinator syncCoordinator;

  @override
  SyncSet get syncSet => SyncSet.projects;

  @override
  bool get syncLoading => state.status == ProjectDirectoryStatus.loading;

  @override
  void markSyncLoading() => emit(
    ProjectDirectoryState(
      projects: state.projects,
      status: ProjectDirectoryStatus.loading,
    ),
  );

  @override
  void syncFailed(ApiException error) => emit(
    ProjectDirectoryState(
      projects: state.projects,
      status: ProjectDirectoryStatus.error,
      error: error,
    ),
  );

  @override
  void applySync(Map<String, dynamic> body) {
    emit(
      ProjectDirectoryState(
        projects: [
          for (final p in (body['data'] as List? ?? const []))
            Project.fromJson(p as Map<String, dynamic>),
        ],
        status: ProjectDirectoryStatus.loaded,
      ),
    );
  }

  @override
  void clear() => emit(const ProjectDirectoryState());

  Future<void> loadIfNeeded() async {
    if (state.status == ProjectDirectoryStatus.loaded ||
        state.status == ProjectDirectoryStatus.loading) {
      return;
    }
    return load();
  }

  Future<void> load() => loadSynced();

  Project? byId(String id) {
    for (final p in state.projects) {
      if (p.id == id) return p;
    }
    return null;
  }
}
