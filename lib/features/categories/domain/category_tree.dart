import 'category.dart';
import '../../../ui/ui.dart';

class CategoryTree {
  CategoryTree._();

  static const int maxDepth = 3;

  static int depthOf(Category category, List<Category> all) {
    var current = category;
    var depth = 1;
    while (current.parentId != null) {
      final parent = _byId(current.parentId!, all);
      if (parent == null) break; // dangling parent ref — treat as root
      current = parent;
      depth++;
      if (depth > maxDepth + 1) break;
    }
    return depth;
  }

  static Category rootOf(Category category, List<Category> all) {
    var current = category;
    while (current.parentId != null) {
      final parent = _byId(current.parentId!, all);
      if (parent == null) break; // dangling — treat current as root
      current = parent;
    }
    return current;
  }

  static IconCode? resolveIconCode(Category category, List<Category> all) {
    return category.iconCode ?? rootOf(category, all).iconCode;
  }

  static String breadcrumb(Category category, List<Category> all) {
    final names = <String>[];
    var current = category;
    while (current.parentId != null) {
      final parent = _byId(current.parentId!, all);
      if (parent == null) break;
      names.add(parent.name);
      current = parent;
    }
    return names.reversed.join(' › ');
  }

  /// True when adding a sibling with [name] under [parentId] / [type] would
  /// collide with an existing active category (case-insensitive).
  static bool hasSiblingWithName({
    required String name,
    required String? parentId,
    required type,
    required List<Category> all,
    String? excludeId,
  }) {
    final lower = name.trim().toLowerCase();
    if (lower.isEmpty) return false;
    return all.any(
      (c) =>
          c.id != excludeId &&
          c.parentId == parentId &&
          c.type == type &&
          c.name.trim().toLowerCase() == lower,
    );
  }

  static Category? _byId(String id, List<Category> all) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
