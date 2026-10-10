import '../../../shared/widgets/reorder/reorder_outline.dart';
import 'category.dart';
import 'category_type.dart';

/// Categories ⇄ the reorder kit's outline ([ReorderOutline]).
///
/// The reorder mode stages moves as an outline — rows in display order,
/// each with a level, one section per [CategoryType]. On save the outline
/// becomes `parent_id` + `sort_order` per row (a row's parent is the
/// nearest row above it with a smaller level) for
/// `PATCH /v1/categories/reorder`.
abstract final class CategoryReorderLogic {
  /// IDs in display order rooted at [rootId] — root first, then
  /// descendants.
  static List<String> subtreeIds(String rootId, List<Category> all) {
    final result = <String>[rootId];
    for (final c in _children(rootId, all)) {
      result.addAll(subtreeIds(c.id, all));
    }
    return result;
  }

  /// Levels in the subtree rooted at [rootId]: 1 = a leaf, 2 = has
  /// children, 3 = has grandchildren.
  static int subtreeHeight(String rootId, List<Category> all) {
    var deepest = 0;
    for (final c in all) {
      if (c.parentId == rootId) {
        final h = subtreeHeight(c.id, all);
        if (h > deepest) deepest = h;
      }
    }
    return deepest + 1;
  }

  /// The user categories as an outline: [types] in order, each type its
  /// own section, rows parent-first by sort order. System categories never
  /// appear in the management UI.
  static List<OutlineItem> toOutline(
    List<Category> all, {
    List<CategoryType> types = CategoryType.values,
  }) {
    final out = <OutlineItem>[];
    void visit(String? parentId, CategoryType type, int level) {
      final children =
          all
              .where(
                (c) => c.parentId == parentId && c.type == type && !c.isSystem,
              )
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final c in children) {
        out.add(OutlineItem(c.id, level, section: type));
        visit(c.id, type, level + 1);
      }
    }

    for (final t in types) {
      visit(null, t, 1);
    }
    return out;
  }

  /// [all] with `parent_id` + `sort_order` rewritten from [outline]; rows
  /// not in it (system ones) pass through unchanged.
  static List<Category> fromOutline(
    List<OutlineItem> outline,
    List<Category> all,
  ) {
    final byId = {for (final c in all) c.id: c};
    final updated = <String, Category>{};
    final stack = <String>[]; // active ancestors, deepest last
    final counters = <String?, int>{};
    Object? section;
    for (final row in outline) {
      if (row.section != section) {
        // Each type numbers its own top level from 0.
        section = row.section;
        stack.clear();
        counters.remove(null);
      }
      while (stack.length >= row.level) {
        stack.removeLast();
      }
      final parentId = stack.isEmpty ? null : stack.last;
      final sortOrder = counters[parentId] ?? 0;
      counters[parentId] = sortOrder + 1;
      final c = byId[row.id];
      if (c != null) {
        updated[c.id] = c.copyWith(
          parentId: parentId,
          clearParent: parentId == null,
          sortOrder: sortOrder,
        );
      }
      stack.add(row.id);
    }
    return [for (final c in all) updated[c.id] ?? c];
  }

  static List<Category> _children(String parentId, List<Category> all) =>
      all.where((c) => c.parentId == parentId).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}
