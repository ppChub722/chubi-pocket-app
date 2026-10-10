import '../../../shared/icon_maker/icon_code.dart';
import 'category.dart';

/// Helpers for navigating the category tree built from a flat list of
/// [Category] rows linked by `parent_id`.
///
/// Pure functions — no state, no Bloc dependency. The cubit and forms
/// pass their `state` (or filtered subset) and ask questions about
/// depth, the L1 root, sibling names and breadcrumb paths.
class CategoryTree {
  CategoryTree._();

  /// Maximum nesting depth — root is depth 1, root's child is depth 2,
  /// grandchild is depth 3. Spec §4.4 caps at 3.
  static const int maxDepth = 3;

  /// Returns the depth of [category] within [all]. Walks up `parent_id`
  /// links; returns 1 for a root, 2 for a child, 3 for a grandchild.
  /// Returns [maxDepth] + 1 if the chain is somehow longer (corrupt data).
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

  /// Returns the L1 ancestor of [category] — i.e. the root of [category]'s
  /// branch. For an L1 category this is itself; for L2/L3 it walks up the
  /// `parent_id` chain until it finds a node with no parent.
  ///
  /// Used by the color-inheritance rule: every row's display color comes
  /// from its L1 ancestor, so editing a leaf's color is meaningless —
  /// only the root carries the visual identity for its branch.
  static Category rootOf(Category category, List<Category> all) {
    var current = category;
    while (current.parentId != null) {
      final parent = _byId(current.parentId!, all);
      if (parent == null) break; // dangling — treat current as root
      current = parent;
    }
    return current;
  }

  /// IconCode to display, derived from [rootOf]. L1 rows return their own
  /// iconCode; L2/L3 rows inherit from their L1 ancestor.
  static IconCode? resolveIconCode(Category category, List<Category> all) {
    return rootOf(category, all).iconCode;
  }

  /// Renders an ancestor-path breadcrumb for a category, e.g.
  /// `"Food & Drinks › Groceries"`. Returns empty string for top-level.
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
  /// Excludes [excludeId] from the comparison so editing without renaming
  /// doesn't trigger the collision check.
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
