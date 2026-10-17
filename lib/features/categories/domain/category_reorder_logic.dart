import 'category.dart';
import 'category_type.dart';
import '../../../ui/ui.dart';

abstract final class CategoryReorderLogic {
  static List<String> subtreeIds(String rootId, List<Category> all) {
    final result = <String>[rootId];
    for (final c in _children(rootId, all)) {
      result.addAll(subtreeIds(c.id, all));
    }
    return result;
  }

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
