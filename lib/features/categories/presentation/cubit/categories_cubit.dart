import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/category.dart';
import '../../domain/category_seed.dart';

/// In-memory categories store for Phase 0 / early P1a UI work.
///
/// State is the full category list — system + user, all types — in
/// `sort_order` order. Consumers filter via the helpers below
/// ([userCategories], [childrenOf]) so the management page can hide
/// system rows while transaction screens still see them.
///
/// Maintains an undo stack of up to [undoLimit] previous states. Each
/// public mutator (add / update / remove / replaceAll) snapshots the
/// current state before applying, so [undo] restores the previous one.
/// FIFO eviction once the stack hits the limit.
///
/// Phase 1a backend integration: replace seed with `GET /v1/categories`
/// and surface async (loading / error). Public API stays stable so the
/// UI layer doesn't churn.
class CategoriesCubit extends Cubit<List<Category>> {
  CategoriesCubit() : super(seedCategories());

  /// Hard cap on user-editable categories per spec discussion (not yet in
  /// canonical spec — flag for P1a doc bump). System categories don't
  /// count toward this limit.
  static const int userLimit = 100;

  /// How many prior states the undo button can roll back through.
  static const int undoLimit = 5;

  final List<List<Category>> _undoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;

  /// All non-system categories in display order. The categories
  /// management page binds to this; system rows live in [state] but
  /// shouldn't surface in the management UI.
  List<Category> get userCategories =>
      state.where((c) => !c.isSystem).toList();

  /// Children of [parentId] (null = top-level), excluding system rows,
  /// sorted by `sort_order`.
  List<Category> childrenOf(String? parentId) {
    return userCategories
        .where((c) => c.parentId == parentId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Category? byId(String id) {
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Returns `true` if the user can add another category. Used by the
  /// add-CTA to disable itself + show a "limit reached" snackbar.
  bool get canAddMore => userCategories.length < userLimit;

  /// Adds [category]. Throws [CategoryLimitExceeded] when the user has
  /// already hit [userLimit] non-system categories. Caller should pre-check
  /// via [canAddMore] for a clean UX path.
  void add(Category category) {
    if (!canAddMore) throw const CategoryLimitExceeded();
    _pushUndo();
    emit([...state, category]);
  }

  void update(Category category) {
    _pushUndo();
    emit([
      for (final c in state)
        if (c.id == category.id) category else c,
    ]);
  }

  void remove(String id) {
    _pushUndo();
    emit(state.where((c) => c.id != id).toList());
  }

  /// Replaces the entire state — used by the drag-and-drop save flow
  /// (commits a staged tree atomically).
  void replaceAll(List<Category> next) {
    _pushUndo();
    emit(next);
  }

  /// Restores the most recent pre-mutation snapshot. No-op when the stack
  /// is empty. Does NOT push the current state onto the stack — so undo
  /// is one-shot and can't itself be undone (matches typical undo-only
  /// UX; redo would be a separate stack).
  void undo() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    emit(previous);
  }

  void _pushUndo() {
    _undoStack.add(List<Category>.unmodifiable(state));
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
