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
    this.errorMessage,
  });

  /// Full list — system + user, all types. Consumers filter via the
  /// cubit's [CategoriesCubit.userCategories] / [CategoriesCubit.childrenOf].
  final List<Category> categories;

  /// Cold-start lifecycle: `initial → loading → (loaded | error)`. Mutators
  /// don't transition out of `loaded` even when they fail; they re-throw
  /// so the page can surface a snackbar without resetting the list view.
  final CategoriesStatus status;

  /// Last known error message from a failed `load()`. Cleared on next
  /// successful load. Mutator failures don't set this.
  final String? errorMessage;

  CategoriesState copyWith({
    List<Category>? categories,
    CategoriesStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [categories, status, errorMessage];
}

enum CategoriesStatus { initial, loading, loaded, error }

/// Categories store backed by [CategoriesRepository].
///
/// **Lifecycle:** [loadIfNeeded] is the standard entry point — pages
/// call it from `initState` and the cubit no-ops if already loaded.
/// First call hits the API; subsequent screens reuse the cache.
///
/// **Mutators:** all return `Future<void>` and re-throw [ApiException]
/// on failure. The success path emits the new list; the failure path
/// leaves state untouched. This keeps the form-page UX simple — the
/// page wraps `await cubit.add(...)` in try/catch and shows a snackbar.
///
/// **Undo:** [undo] is intentionally local-only. Each successful
/// mutator pushes the prior list onto the in-memory stack; [undo] pops
/// it and emits — no server round-trip. The next mutation will re-sync
/// state with the server. Phase 1a accepts this trade — the alternative
/// (round-trip undo via inverse API calls) is much more complex.
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

  /// How many prior states the undo button can roll back through.
  static const int undoLimit = 5;

  final List<List<Category>> _undoStack = [];

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
  /// surfaces an `errorMessage` while flipping status to `error`.
  Future<void> load() async {
    emit(state.copyWith(
      status: CategoriesStatus.loading,
      clearError: true,
    ));
    try {
      // Include system rows so other features (transactions) can
      // resolve Transfer/Adjustment/Opening when the list is shared.
      // The management page filters via [userCategories].
      final list = await _repo.list(includeSystem: true);
      emit(state.copyWith(
        categories: list,
        status: CategoriesStatus.loaded,
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: CategoriesStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  // ── Read helpers ───────────────────────────────────────────────────

  bool get canUndo => _undoStack.isNotEmpty;

  /// All non-system categories. The categories management page binds
  /// to this; system rows live in [state.categories] but shouldn't
  /// surface in the management UI.
  List<Category> get userCategories =>
      state.categories.where((c) => !c.isSystem).toList();

  /// Children of [parentId] (null = top-level), excluding system rows,
  /// sorted by `sort_order`.
  List<Category> childrenOf(String? parentId) {
    return userCategories
        .where((c) => c.parentId == parentId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

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
  Future<void> add(Category draft) async {
    if (!canAddMore) throw const CategoryLimitExceeded();
    final created = await _repo.create(draft);
    _pushUndo();
    emit(state.copyWith(
      categories: [...state.categories, created],
    ));
  }

  Future<void> update(Category category) async {
    final updated = await _repo.update(category);
    _pushUndo();
    emit(state.copyWith(
      categories: [
        for (final c in state.categories)
          if (c.id == updated.id) updated else c,
      ],
    ));
  }

  /// Hard-delete or archive (server picks based on transaction count).
  /// Either way the local list drops the row — archived rows are
  /// hidden from the default list filter, and the management page
  /// doesn't show them either.
  Future<void> remove(String id) async {
    await _repo.delete(id);
    _pushUndo();
    emit(state.copyWith(
      categories: state.categories.where((c) => c.id != id).toList(),
    ));
  }

  /// Saves the user's drag-and-drop reorder by sending the staged tree
  /// to `PATCH /v1/categories/reorder`. Server returns the user's full
  /// updated active list, which we replace into state. System rows
  /// (excluded from the reorder payload because they always stay roots)
  /// are re-attached from the prior local state.
  Future<void> saveReorder(List<Category> staged) async {
    final userOnly = staged.where((c) => !c.isSystem).toList();
    final result = await _repo.reorder(userOnly);
    _pushUndo();
    final systemRows =
        state.categories.where((c) => c.isSystem).toList();
    emit(state.copyWith(
      categories: [...systemRows, ...result],
    ));
  }

  // ── Undo ───────────────────────────────────────────────────────────

  /// Restores the most recent pre-mutation snapshot — local-only;
  /// does not call the server. The next mutator call re-syncs.
  void undo() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    emit(state.copyWith(categories: previous));
  }

  void _pushUndo() {
    _undoStack.add(List<Category>.unmodifiable(state.categories));
    if (_undoStack.length > undoLimit) {
      _undoStack.removeAt(0);
    }
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
