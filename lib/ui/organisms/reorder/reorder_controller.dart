import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'reorder_outline.dart';

class ReorderController extends ChangeNotifier {
  ReorderController({
    required List<OutlineItem> items,
    this.maxDepth = 3,
    Set<String>? collapsed,
    this.undoLimit = 5,
  }) : _items = List.unmodifiable(items),
       _original = List.unmodifiable(items),
       collapsed = collapsed ?? <String>{};

  final int maxDepth;
  final int undoLimit;
  final Set<String> collapsed;

  List<OutlineItem> _items;
  final List<OutlineItem> _original;
  final List<List<OutlineItem>> _undo = [];
  String? _selectedId;

  int _moves = 0;

  List<OutlineItem> get items => _items;
  String? get selectedId => _selectedId;
  int get moves => _moves;
  bool get isTree => maxDepth > 1;
  bool get canUndo => _undo.isNotEmpty;

  bool get dirty => !listEquals(_items, _original);

  int indexOf(String id) => _items.indexWhere((r) => r.id == id);

  OutlineItem? itemOf(String id) {
    final i = indexOf(id);
    return i < 0 ? null : _items[i];
  }

  bool hasChildren(String id) {
    final i = indexOf(id);
    return i >= 0 && ReorderOutline.hasChildren(_items, i);
  }

  bool isCollapsed(String id) => collapsed.contains(id);

  List<OutlineItem> visible({Object? section}) =>
      ReorderOutline.visible(_items, collapsed, section: section);

  void tapRow(String id) => select(_selectedId == id ? null : id);

  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  void toggleCollapsed(String id) {
    if (!collapsed.remove(id)) collapsed.add(id);
    final sel = _selectedId == null ? -1 : indexOf(_selectedId!);
    if (sel >= 0 && !ReorderOutline.isVisible(_items, sel, collapsed)) {
      _selectedId = null;
    }
    notifyListeners();
  }

  void expand(String id) {
    if (collapsed.remove(id)) notifyListeners();
  }

  int get _sel => _selectedId == null ? -1 : indexOf(_selectedId!);

  List<OutlineItem>? _upResult() => _sel < 0
      ? null
      : ReorderOutline.moveUp(
          _items,
          _sel,
          maxDepth: maxDepth,
          collapsed: collapsed,
        );

  List<OutlineItem>? _downResult() => _sel < 0
      ? null
      : ReorderOutline.moveDown(
          _items,
          _sel,
          maxDepth: maxDepth,
          collapsed: collapsed,
        );

  List<OutlineItem>? _outdentResult() =>
      _sel < 0 || !isTree ? null : ReorderOutline.outdent(_items, _sel);

  List<OutlineItem>? _indentResult() => _sel < 0 || !isTree
      ? null
      : ReorderOutline.indent(_items, _sel, maxDepth: maxDepth);

  bool get canMoveUp => _upResult() != null;
  bool get canMoveDown => _downResult() != null;
  bool get canOutdent => _outdentResult() != null;
  bool get canIndent => _indentResult() != null;

  void moveUp() => _apply(_upResult());
  void moveDown() => _apply(_downResult());
  void outdent() => _apply(_outdentResult());
  void indent() => _apply(_indentResult());

  /// Drops the block of [id] at index [k] of the outline without it, on
  /// [level].
  bool drop(String id, int k, int level) {
    final i = indexOf(id);
    if (i < 0) return false;
    return _apply(
      ReorderOutline.moveTo(
        _items,
        i,
        k,
        level,
        maxDepth: maxDepth,
        collapsed: collapsed,
      ),
      haptic: false,
    );
  }

  void undo() {
    if (_undo.isEmpty) return;
    HapticFeedback.selectionClick();
    _items = _undo.removeLast();
    _moves++;
    notifyListeners();
  }

  bool _apply(List<OutlineItem>? next, {bool haptic = true}) {
    if (next == null || listEquals(next, _items)) return false;
    _undo.add(_items);
    if (_undo.length > undoLimit) _undo.removeAt(0);
    _items = List.unmodifiable(next);
    _moves++;
    _revealSelected();
    if (haptic) HapticFeedback.selectionClick();
    notifyListeners();
    return true;
  }

  void _revealSelected() {
    final i = _sel;
    if (i < 0) return;
    for (
      var p = ReorderOutline.parentIndex(_items, i);
      p != null;
      p = ReorderOutline.parentIndex(_items, p)
    ) {
      collapsed.remove(_items[p].id);
    }
  }
}
