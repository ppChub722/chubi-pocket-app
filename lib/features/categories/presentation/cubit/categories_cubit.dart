import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/data/sync_backed.dart';
import '../../../../core/data/sync_coordinator.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/categories_repository.dart';
import '../../domain/category.dart';

class CategoriesState extends Equatable {
  const CategoriesState({
    this.categories = const [],
    this.status = CategoriesStatus.initial,
    this.error,
  });

  final List<Category> categories;

  final CategoriesStatus status;

  final ApiException? error;
  String? get errorMessage => error?.message;

  CategoriesState copyWith({
    List<Category>? categories,
    CategoriesStatus? status,
    ApiException? error,
    bool clearError = false,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [categories, status, error];
}

enum CategoriesStatus { initial, loading, loaded, error }

class CategoriesCubit extends Cubit<CategoriesState>
    with Clearable, SyncBacked<CategoriesState> {
  CategoriesCubit({
    required CategoriesRepository repository,
    required SyncCoordinator coordinator,
  }) : _repo = repository,
       syncCoordinator = coordinator,
       super(const CategoriesState()) {
    bindSync();
  }

  final CategoriesRepository _repo;

  @override
  final SyncCoordinator syncCoordinator;

  @override
  SyncSet get syncSet => SyncSet.categories;

  @override
  bool get syncLoading => state.status == CategoriesStatus.loading;

  @override
  void markSyncLoading() =>
      emit(state.copyWith(status: CategoriesStatus.loading, clearError: true));

  @override
  void syncFailed(ApiException error) =>
      emit(state.copyWith(status: CategoriesStatus.error, error: error));

  @override
  void applySync(Map<String, dynamic> body) {
    emit(
      state.copyWith(
        categories: [
          for (final c in (body['data'] as List? ?? const []))
            Category.fromJson(c as Map<String, dynamic>),
        ],
        status: CategoriesStatus.loaded,
        clearError: true,
      ),
    );
  }

  @override
  void clear() => emit(const CategoriesState());

  static const int userLimit = 100;

  Future<void> loadIfNeeded() async {
    if (state.status == CategoriesStatus.loaded ||
        state.status == CategoriesStatus.loading) {
      return;
    }
    return load();
  }

  Future<void> load() => loadSynced();

  List<Category> get userCategories =>
      state.categories.where((c) => !c.isSystem).toList();

  Category? byId(String id) {
    for (final c in state.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  bool get canAddMore => userCategories.length < userLimit;

  Future<Category> add(Category draft) async {
    if (!canAddMore) throw const CategoryLimitExceeded();
    final created = await _repo.create(draft);
    emit(state.copyWith(categories: [...state.categories, created]));
    return created;
  }

  Future<CategoryDetail> fetchDetail(String id) async {
    final detail = await _repo.get(id);
    _patch(detail);
    return detail;
  }

  Future<CategoryDetail> update(Category category) async {
    final updated = await _repo.update(category);
    _patch(updated);
    return updated;
  }

  void _patch(Category updated) {
    if (!state.categories.any((c) => c.id == updated.id)) return;
    emit(
      state.copyWith(
        categories: [
          for (final c in state.categories)
            if (c.id == updated.id) updated else c,
        ],
      ),
    );
  }

  Future<void> remove(String id) async {
    final reparented = await _repo.delete(id);
    final byId = {for (final r in reparented) r.id: r};
    emit(
      state.copyWith(
        categories: [
          for (final c in state.categories)
            if (c.id != id) byId[c.id] ?? c,
        ],
      ),
    );
  }

  Future<void> saveReorder(List<Category> staged) async {
    final userOnly = staged.where((c) => !c.isSystem).toList();
    final result = await _repo.reorder(userOnly);
    final systemRows = state.categories.where((c) => c.isSystem).toList();
    emit(state.copyWith(categories: [...systemRows, ...result]));
  }
}

class CategoryLimitExceeded implements Exception {
  const CategoryLimitExceeded();

  @override
  String toString() => 'CategoryLimitExceeded';
}
