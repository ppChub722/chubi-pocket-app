import 'package:flutter/foundation.dart';

@immutable
class OutlineItem {
  const OutlineItem(this.id, this.level, {this.section});

  final String id;

  final int level;
  final Object? section;

  OutlineItem withLevel(int level) => OutlineItem(id, level, section: section);

  @override
  bool operator ==(Object other) =>
      other is OutlineItem &&
      other.id == id &&
      other.level == level &&
      other.section == section;

  @override
  int get hashCode => Object.hash(id, level, section);

  @override
  String toString() => '$id@$level';
}

abstract final class ReorderOutline {
  static int blockEnd(List<OutlineItem> items, int i) {
    var e = i + 1;
    while (e < items.length &&
        items[e].section == items[i].section &&
        items[e].level > items[i].level) {
      e++;
    }
    return e;
  }

  static int heightOf(List<OutlineItem> items, int i) {
    var deepest = items[i].level;
    for (var j = i + 1; j < blockEnd(items, i); j++) {
      if (items[j].level > deepest) deepest = items[j].level;
    }
    return deepest - items[i].level + 1;
  }

  static int? parentIndex(List<OutlineItem> items, int i) {
    for (var j = i - 1; j >= 0; j--) {
      if (items[j].section != items[i].section) return null;
      if (items[j].level < items[i].level) return j;
    }
    return null;
  }

  static bool hasChildren(List<OutlineItem> items, int i) =>
      blockEnd(items, i) > i + 1;

  static bool isVisible(List<OutlineItem> items, int i, Set<String> collapsed) {
    for (var p = parentIndex(items, i); p != null; p = parentIndex(items, p)) {
      if (collapsed.contains(items[p].id)) return false;
    }
    return true;
  }

  static List<OutlineItem> visible(
    List<OutlineItem> items,
    Set<String> collapsed, {
    Object? section,
  }) {
    final out = <OutlineItem>[];
    var i = 0;
    while (i < items.length) {
      final item = items[i];
      if (item.section != section) {
        i++;
        continue;
      }
      out.add(item);
      i = collapsed.contains(item.id) ? blockEnd(items, i) : i + 1;
    }
    return out;
  }

  static (int, int) sectionRange(List<OutlineItem> items, Object? section) {
    var start = items.indexWhere((r) => r.section == section);
    if (start < 0) {
      start = items.length;
      return (start, start);
    }
    var end = start;
    while (end < items.length && items[end].section == section) {
      end++;
    }
    return (start, end);
  }

  static (int, int)? validLevels(
    List<OutlineItem> rest,
    int k, {
    required Object? section,
    required int height,
    required int maxDepth,
    required Set<String> collapsed,
  }) {
    final (start, end) = sectionRange(rest, section);
    if (k < start || k > end) return null;
    final above = k > start ? rest[k - 1] : null;
    final below = k < end ? rest[k] : null;
    var max = above == null ? 1 : above.level + 1;
    final depthCap = maxDepth - height + 1;
    if (depthCap < max) max = depthCap;
    final min = below?.level ?? 1;
    var visibleMax = min - 1;
    for (var level = min; level <= max; level++) {
      if (!_chainExpanded(rest, k, level, start, collapsed)) break;
      visibleMax = level;
    }
    if (visibleMax < min) return null;
    return (min, visibleMax);
  }

  /// The parent a block at index [k] of [rest] on [level] would get, or null
  /// for top level.
  static String? parentAt(
    List<OutlineItem> rest,
    int k,
    int level, {
    required Object? section,
  }) {
    final (start, _) = sectionRange(rest, section);
    for (var j = k - 1; j >= start; j--) {
      if (rest[j].level < level) return rest[j].id;
    }
    return null;
  }

  static bool _chainExpanded(
    List<OutlineItem> rest,
    int k,
    int level,
    int sectionStart,
    Set<String> collapsed,
  ) {
    var need = level;
    for (var j = k - 1; j >= sectionStart && need > 1; j--) {
      if (rest[j].level < need) {
        if (collapsed.contains(rest[j].id)) return false;
        need = rest[j].level;
      }
    }
    return true;
  }

  static (List<OutlineItem>, List<OutlineItem>) cut(
    List<OutlineItem> items,
    int i,
  ) {
    final end = blockEnd(items, i);
    return (
      items.sublist(i, end),
      [...items.sublist(0, i), ...items.sublist(end)],
    );
  }

  static List<OutlineItem> insert(
    List<OutlineItem> rest,
    List<OutlineItem> block,
    int k,
    int level,
  ) {
    final shift = level - block.first.level;
    return [
      ...rest.sublist(0, k),
      for (final r in block) r.withLevel(r.level + shift),
      ...rest.sublist(k),
    ];
  }

  /// Drag-and-drop: the block at [i] to index [k] of the outline without it, on
  /// [level].
  static List<OutlineItem>? moveTo(
    List<OutlineItem> items,
    int i,
    int k,
    int level, {
    required int maxDepth,
    Set<String> collapsed = const {},
  }) {
    final (block, rest) = cut(items, i);
    final range = validLevels(
      rest,
      k,
      section: items[i].section,
      height: heightOf(items, i),
      maxDepth: maxDepth,
      collapsed: collapsed,
    );
    if (range == null || level < range.$1 || level > range.$2) return null;
    return insert(rest, block, k, level);
  }

  static List<OutlineItem>? moveUp(
    List<OutlineItem> items,
    int i, {
    required int maxDepth,
    Set<String> collapsed = const {},
  }) => _step(items, i, -1, maxDepth: maxDepth, collapsed: collapsed);

  static List<OutlineItem>? moveDown(
    List<OutlineItem> items,
    int i, {
    required int maxDepth,
    Set<String> collapsed = const {},
  }) => _step(items, i, 1, maxDepth: maxDepth, collapsed: collapsed);

  static List<OutlineItem>? _step(
    List<OutlineItem> items,
    int i,
    int dir, {
    required int maxDepth,
    required Set<String> collapsed,
  }) {
    final section = items[i].section;
    final height = heightOf(items, i);
    final (block, rest) = cut(items, i);
    final (start, end) = sectionRange(rest, section);
    for (var k = i + dir; k >= start && k <= end; k += dir) {
      final range = validLevels(
        rest,
        k,
        section: section,
        height: height,
        maxDepth: maxDepth,
        collapsed: collapsed,
      );
      if (range == null) continue;
      final own = block.first.level;
      final level = own < range.$2 ? own : range.$2;
      if (level < range.$1) continue;
      return insert(rest, block, k, level);
    }
    return null;
  }

  static List<OutlineItem>? outdent(List<OutlineItem> items, int i) {
    final p = parentIndex(items, i);
    if (p == null) return null;
    final (block, rest) = cut(items, i);
    final k = blockEnd(rest, p);
    return insert(rest, block, k, items[i].level - 1);
  }

  static List<OutlineItem>? indent(
    List<OutlineItem> items,
    int i, {
    required int maxDepth,
  }) {
    final level = items[i].level;
    if (level + heightOf(items, i) > maxDepth) return null;
    int? sibling;
    for (var j = i - 1; j >= 0; j--) {
      if (items[j].section != items[i].section) break;
      if (items[j].level <= level) {
        if (items[j].level == level) sibling = j;
        break;
      }
    }
    if (sibling == null) return null;
    final end = blockEnd(items, i);
    return [
      ...items.sublist(0, i),
      for (final r in items.sublist(i, end)) r.withLevel(r.level + 1),
      ...items.sublist(end),
    ];
  }
}
