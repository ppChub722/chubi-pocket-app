import 'category.dart';
import 'category_tree.dart';
import 'category_type.dart';

/// One row in the user-visible flat list (DFS render order). Carries the
/// row's [level] independently of the underlying tree — lets the reorder
/// flow stage moves as `(id, level)` pairs and derive parent_ids only at
/// commit time, "outliner" style.
class CategoryFlatRow {
  const CategoryFlatRow(this.category, this.level);

  final Category category;

  /// 1 = root, 2 = child, 3 = grandchild. Independent of [Category.parentId];
  /// during a staged reorder the level is the source of truth.
  final int level;
}

/// Pure functions for the simplified reorder model.
///
/// **Model**: during reorder mode, the visible list is flat. Each row
/// carries an explicit [level] (1, 2, or 3). Parent_id is *derived* from
/// list position + level on commit — the standard outliner rule:
/// "a row's parent is the nearest preceding row with a smaller level".
///
/// This replaces the old `CategoryDropResolver` (which kept parent_id as
/// the source of truth and computed cycles / depth checks during drag).
/// The model is easier to reason about, easier to extract for future
/// tree-shaped features, and easier for the backend: the API will receive
/// `[(id, level, sort_order)]` and reconstruct parent_id server-side.
class CategoryReorderLogic {
  CategoryReorderLogic._();

  /// Computes the level the dropped row should land at, given the cursor
  /// column and the row directly above the cursor.
  ///
  /// Rules (only two clamps, everything else free):
  /// - **Top of section** (anchor null) → always L1. The first row of a
  ///   section physically can't be a child — there's nothing above to
  ///   parent it.
  /// - **Col 3 with anchor at L1** → L2. Putting an L3 directly under an
  ///   L1 would skip a level.
  ///
  /// Otherwise: cursor column = level. Free drop.
  static int effectiveLevel({
    required int cursorCol,
    required Category? anchor,
    required List<Category> all,
  }) {
    if (anchor == null) return 1;
    final anchorDepth = CategoryTree.depthOf(anchor, all);
    if (cursorCol == 3 && anchorDepth == 1) return 2;
    return cursorCol;
  }

  /// IDs in DFS order rooted at [rootId] — root first, then descendants.
  /// Used to find the contiguous subtree that travels with a dragged
  /// parent.
  static List<String> subtreeIds(String rootId, List<Category> all) {
    final result = <String>[rootId];
    final children = all.where((c) => c.parentId == rootId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final c in children) {
      result.addAll(subtreeIds(c.id, all));
    }
    return result;
  }

  /// User-visible flat list of categories of [type] in DFS tree order
  /// (parent then children, sorted by sort_order). System categories are
  /// excluded — they never appear in the management UI.
  static List<CategoryFlatRow> flatten(
      List<Category> all, CategoryType type) {
    final result = <CategoryFlatRow>[];
    void visit(String? parentId, int level) {
      final children = all
          .where((c) =>
              c.parentId == parentId && c.type == type && !c.isSystem)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final c in children) {
        result.add(CategoryFlatRow(c, level));
        visit(c.id, level + 1);
      }
    }

    visit(null, 1);
    return result;
  }

  /// Applies one drag-and-drop move to [all]:
  /// 1. Cuts the moving block out of its current position. The block is
  ///    either the **whole subtree** (`dragOnlyRoot: false` — the
  ///    natural "move this branch" behavior, used when dragging a
  ///    collapsed parent) or **just the dragged row** (`dragOnlyRoot:
  ///    true` — used when dragging an expanded parent: descendants stay
  ///    where they are and get re-parented by the outliner rebuild).
  /// 2. Applies the level shift to every row in the moving block.
  ///    **Each row is clamped individually at [CategoryTree.maxDepth]**
  ///    — descendants that would land past L3 stay at L3 (becoming
  ///    siblings of whatever's at L3 in their branch). The root lands
  ///    at the requested level even if some descendants get flattened.
  /// 3. Inserts the moving block right after [anchor] in the flat list.
  ///    Pass `anchor: null` to drop at the top of the section. Pass
  ///    `anchor.id == dragged.id` for "demote in place" — the row stays
  ///    at its original flat position; only its level changes.
  /// 4. Walks the new flat list and rewrites parent_id + sort_order via
  ///    the outliner rule (nearest preceding row with smaller level).
  ///
  /// Returns a new [List<Category>] where the moved rows (and any
  /// rows whose sort_order changed because of the rewrite) carry
  /// updated parent_id and sort_order. Categories of other types are
  /// untouched.
  static List<Category> applyMove({
    required List<Category> all,
    required Category dragged,
    required Category? anchor,
    required int targetLevel,
    bool dragOnlyRoot = false,
  }) {
    final type = dragged.type;
    final flat = flatten(all, type);

    final draggedIdx = flat.indexWhere((r) => r.category.id == dragged.id);
    if (draggedIdx < 0) return all; // not in this section, no-op

    final draggedLevel = flat[draggedIdx].level;

    // Determine the moving block's extent in the flat list.
    final int endIdx;
    if (dragOnlyRoot) {
      // Expanded parent — only the row itself moves; descendants stay
      // in the flat list and get re-parented by the outliner walk.
      endIdx = draggedIdx + 1;
    } else {
      // Collapsed parent (or leaf) — grab the whole subtree by DFS
      // adjacency: the dragged row plus every consecutive descendant.
      var e = draggedIdx + 1;
      while (e < flat.length && flat[e].level > draggedLevel) {
        e++;
      }
      endIdx = e;
    }
    final subtree = flat.sublist(draggedIdx, endIdx);

    // Per-row clamp: shift each row by `levelShift`, clamping at
    // maxDepth individually. Descendants that would exceed L3 collapse
    // onto L3 (becoming siblings of whatever's at L3 in their branch).
    // The root lands where the cursor said even if some descendants
    // flatten — matches the "free drop" intent.
    final levelShift = targetLevel - draggedLevel;
    final shiftedSubtree = [
      for (final r in subtree)
        CategoryFlatRow(
          r.category,
          (r.level + levelShift) > CategoryTree.maxDepth
              ? CategoryTree.maxDepth
              : (r.level + levelShift),
        ),
    ];

    // Cut subtree out of the flat list.
    final remaining = [
      ...flat.sublist(0, draggedIdx),
      ...flat.sublist(endIdx),
    ];

    // Find insert position: right after anchor in `remaining`.
    int insertIdx;
    if (anchor == null) {
      insertIdx = 0;
    } else if (anchor.id == dragged.id) {
      // Drop on self → keep the dragged item exactly where it was in
      // the flat list. Combined with the level shift above, this is the
      // "demote in place" gesture: the row stays put while its level
      // (and thus its parent_id, after outliner rebuild) changes.
      // Items before `draggedIdx` weren't cut, so the original index
      // also points to the same slot in `remaining`.
      insertIdx = draggedIdx;
    } else {
      final anchorIdxInRemaining =
          remaining.indexWhere((r) => r.category.id == anchor.id);
      insertIdx = anchorIdxInRemaining < 0
          ? remaining.length
          : anchorIdxInRemaining + 1;
    }

    final newFlat = [
      ...remaining.sublist(0, insertIdx),
      ...shiftedSubtree,
      ...remaining.sublist(insertIdx),
    ];

    // Reconstruct parent_id + sort_order from the new flat list.
    return _reconstruct(newFlat, all, type);
  }

  /// Walks [flat] left-to-right, deriving each row's parent_id (nearest
  /// preceding row with a smaller level) and sort_order (incrementing
  /// counter per parent group). Returns the merged list — categories of
  /// other types and system categories pass through unchanged.
  static List<Category> _reconstruct(
    List<CategoryFlatRow> flat,
    List<Category> originalAll,
    CategoryType type,
  ) {
    final updated = <String, Category>{};
    final stack = <String>[]; // ids of active ancestors, deepest at end
    final sortCounters = <String?, int>{};

    for (final row in flat) {
      // Trim stack so its size matches (level - 1).
      while (stack.length >= row.level) {
        stack.removeLast();
      }
      final parentId = stack.isEmpty ? null : stack.last;
      final sortOrder = sortCounters[parentId] ?? 0;
      sortCounters[parentId] = sortOrder + 1;

      updated[row.category.id] = row.category.copyWith(
        parentId: parentId,
        clearParent: parentId == null,
        sortOrder: sortOrder,
      );
      stack.add(row.category.id);
    }

    return [
      for (final c in originalAll)
        if (updated.containsKey(c.id)) updated[c.id]! else c,
    ];
  }
}
