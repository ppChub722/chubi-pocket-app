import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/tags_repository.dart';
import '../../domain/tag.dart';

class TagsState extends Equatable {
  const TagsState({
    this.tags = const [],
    this.status = TagsStatus.initial,
    this.error,
  });

  final List<Tag> tags;
  final TagsStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;

  TagsState copyWith({
    List<Tag>? tags,
    TagsStatus? status,
    ApiException? error,
    bool clearError = false,
  }) {
    return TagsState(
      tags: tags ?? this.tags,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [tags, status, error];
}

enum TagsStatus { initial, loading, loaded, error }

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
      emit(
        state.copyWith(tags: list, status: TagsStatus.loaded, clearError: true),
      );
    } catch (e, st) {
      emit(
        state.copyWith(
          status: TagsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  Future<Tag> add(Tag draft) async {
    final created = await _repo.create(draft);
    emit(state.copyWith(tags: [...state.tags, created]));
    return created;
  }

  Future<List<Tag>> saveBatch({
    List<Tag> create = const [],
    List<Tag> update = const [],
    List<String> delete = const [],
  }) async {
    final res = await _repo.batch(
      create: create,
      update: update,
      delete: delete,
    );
    emit(state.copyWith(tags: res.data, status: TagsStatus.loaded));
    return res.created;
  }

  Future<void> update(Tag tag) async {
    final updated = await _repo.update(tag);
    emit(
      state.copyWith(
        tags: [
          for (final t in state.tags)
            if (t.id == updated.id) updated else t,
        ],
      ),
    );
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    emit(state.copyWith(tags: state.tags.where((t) => t.id != id).toList()));
  }

  Tag? byId(String id) {
    for (final t in state.tags) {
      if (t.id == id) return t;
    }
    return null;
  }
}
