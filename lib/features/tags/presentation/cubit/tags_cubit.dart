import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/tags_repository.dart';
import '../../domain/tag.dart';

/// State for [TagsCubit]. See [CategoriesState] for rationale on the
/// single-class-with-enum-status shape.
class TagsState extends Equatable {
  const TagsState({
    this.tags = const [],
    this.status = TagsStatus.initial,
    this.errorMessage,
  });

  final List<Tag> tags;
  final TagsStatus status;
  final String? errorMessage;

  TagsState copyWith({
    List<Tag>? tags,
    TagsStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TagsState(
      tags: tags ?? this.tags,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [tags, status, errorMessage];
}

enum TagsStatus { initial, loading, loaded, error }

/// Tags store backed by [TagsRepository].
///
/// Tags are flat (no parent/child) and hard-deleted (junction rows
/// cascade per spec §4.11). New users start empty — the `+` action
/// is the discoverability path.
///
/// Mutators round-trip through the API and re-throw [ApiException]
/// on failure so the form page can show a snackbar.
class TagsCubit extends Cubit<TagsState> with Clearable {
  TagsCubit({required TagsRepository repository})
      : _repo = repository,
        super(const TagsState());

  final TagsRepository _repo;

  @override
  void clear() => emit(const TagsState());

  Future<void> loadIfNeeded() async {
    if (state.status == TagsStatus.loaded ||
        state.status == TagsStatus.loading) {
      return;
    }
    return load();
  }

  Future<void> load() async {
    emit(state.copyWith(status: TagsStatus.loading, clearError: true));
    try {
      final list = await _repo.list();
      emit(state.copyWith(
        tags: list,
        status: TagsStatus.loaded,
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: TagsStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> add(Tag draft) async {
    final created = await _repo.create(draft);
    emit(state.copyWith(tags: [...state.tags, created]));
  }

  Future<void> update(Tag tag) async {
    final updated = await _repo.update(tag);
    emit(state.copyWith(
      tags: [
        for (final t in state.tags)
          if (t.id == updated.id) updated else t,
      ],
    ));
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    emit(state.copyWith(
      tags: state.tags.where((t) => t.id != id).toList(),
    ));
  }

  Tag? byId(String id) {
    for (final t in state.tags) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Server already sorts by `usage_count DESC, name ASC` (spec §3.9),
  /// so this is a passthrough — kept as a getter so the page doesn't
  /// re-sort on every build and for parity with how the cubit was
  /// shaped in mock mode.
  List<Tag> get sorted => state.tags;

  /// Case-insensitive uniqueness check for the form's name validator.
  /// Excludes [excludeId] so editing without renaming doesn't trigger
  /// the collision.
  bool nameExists(String name, {String? excludeId}) {
    final lower = name.trim().toLowerCase();
    if (lower.isEmpty) return false;
    return state.tags.any(
      (t) => t.id != excludeId && t.name.trim().toLowerCase() == lower,
    );
  }
}
