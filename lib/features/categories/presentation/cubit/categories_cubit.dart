import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/categories_repository.dart';
import '../../domain/category.dart';

/// State for [CategoriesCubit].
///
/// Single class (not a sealed hierarchy) because every consumer wants
/// the same shape: the list, the freshness, and an optional error
/// string. Sealed variants would force pattern-matching at every read
/// site for no real benefit.
class CategoriesState extends Equatable {
  const CategoriesState({
    this.categories = const [],
    this.status = CategoriesStatus.initial,
    this.error,
  });

  /// Full list — system + user, all types. Consumers filter via the
  /// cubit's [CategoriesCubit.userCategories].
  final List<Category> categories;

  /// Cold-start lifecycle: `initial → loading → (loaded | error)`. Mutators
  /// don't transition out of `loaded` even when they fail; they re-throw
  /// so the page can surface a snackbar without resetting the list view.
  final CategoriesStatus status;

  /// Last failure from `load()`. Cleared on next
  /// successful load. Mutator failures don't set this.
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

/// Categories store backed by [CategoriesRepository].
///
/// **Lifecycle:** [loadIfNeeded] is the standard entry point — pages
/// call it from `initState` and the cubit no-ops if already loaded.
/// First call hits the API; subsequent screens reuse the cache.
///
/// **Mutators:** all re-throw [ApiException] on failure. The success path
/// emits the new list; the failure path leaves state untouched. This keeps
/// the form-page UX simple — the page wraps `await cubit.add(...)` in
/// try/catch and shows a snackbar.
class CategoriesCubit extends Cubit<CategoriesState> with Clearable {
  CategoriesCubit({required CategoriesRepository repository})
    : _repo = repository,
      super(const CategoriesState());

  final CategoriesRepository _repo;

  @override
  void clear() => emit(const CategoriesState());

  /// Hard cap on user-editable categories per spec discussion (not yet in
  /// canonical spec — flag for P1a doc bump). System categories don't
  /// count toward this limit.
  static const int userLimit = 100;

  // ── Loading ────────────────────────────────────────────────────────

  /// Hits `GET /v1/categories` if state hasn't been loaded yet. Idempotent
  /// — opening the management page twice doesn't refetch.
  Future<void> loadIfNeeded() async {
    if (state.status == CategoriesStatus.loaded ||
        state.status == CategoriesStatus.loading) {
      return;
    }
    return load();
  }

  /// Force-reload from the API. Used by an explicit refresh action.
  /// On failure preserves the previously loaded list (if any) and
  /// surfaces an `error` while flipping status to `error`.
  Future<void> load() async {
    emit(state.copyWith(status: CategoriesStatus.loading, clearError: true));
    try {
      // Include system rows so other features (transactions) can
      // resolve Transfer/Adjustment/Opening when the list is shared.
      // The management page filters via [userCategories].
      final list = await _repo.list(includeSystem: true);
      emit(
        state.copyWith(
          categories: list,
          status: CategoriesStatus.loaded,
          clearError: true,
        ),
      );
    } catch (e, st) {
      emit(
        state.copyWith(
          status: CategoriesStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  // ── Read helpers ───────────────────────────────────────────────────

  /// All non-system categories. The categories management page binds
  /// to this; system rows live in [state.categories] but shouldn't
  /// surface in the management UI.
  List<Category> get userCategories =>
      state.categories.where((c) => !c.isSystem).toList();

  Category? byId(String id) {
    for (final c in state.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Returns `true` if the user can add another category. Used by the
  /// add-CTA to disable itself + show a "limit reached" snackbar.
  bool get canAddMore => userCategories.length < userLimit;

  // ── Mutators (round-trip through the repo) ─────────────────────────

  /// Adds [draft]. Throws [CategoryLimitExceeded] when the user has
  /// already hit [userLimit] non-system categories. Caller should
  /// pre-check via [canAddMore] for a clean UX path. Re-throws
  /// [ApiException] on server validation failures.
  Future<Category> add(Category draft) async {
    if (!canAddMore) throw const CategoryLimitExceeded();
    final created = await _repo.create(draft);
    emit(state.copyWith(categories: [...state.categories, created]));
    return created;
  }

  Future<void> update(Category category) async {
    final updated = await _repo.update(category);
    emit(
      state.copyWith(
        categories: [
          for (final c in state.categories)
            if (c.id == updated.id) updated else c,
        ],
      ),
    );
  }

  /// Real delete (see [CategoriesRepository.delete]). Reloads afterwards
  /// because the server also re-parents the row's children.
  Future<void> remove(String id) async {
    await _repo.delete(id);
    await load();
  }

  /// Transactions / budgets a delete of [id] would affect.
  Future<({int transactions, int budgets})> usage(String id) => _repo.usage(id);

  /// Saves the user's drag-and-drop reorder by sending the staged tree
  /// to `PATCH /v1/categories/reorder`. Server returns the user's full
  /// updated active list, which we replace into state. System rows
  /// (excluded from the reorder payload because they always stay roots)
  /// are re-attached from the prior local state.
  Future<void> saveReorder(List<Category> staged) async {
    final userOnly = staged.where((c) => !c.isSystem).toList();
    final result = await _repo.reorder(userOnly);
    final systemRows = state.categories.where((c) => c.isSystem).toList();
    emit(state.copyWith(categories: [...systemRows, ...result]));
  }
}

/// Thrown by [CategoriesCubit.add] when the user has reached the per-user
/// category limit. The page-level handler catches this and surfaces a
/// localized snackbar.
class CategoryLimitExceeded implements Exception {
  const CategoryLimitExceeded();

  @override
  String toString() => 'CategoryLimitExceeded';
}
