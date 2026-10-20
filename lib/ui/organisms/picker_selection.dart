/// How a ticked parent treats the items under it, in a multi picker with a
/// tree.
enum PickerChildren {
  /// Every item is ticked on its own.
  separate,

  /// A ticked parent shows a box to take in all its sub-items.
  toggle,

  /// A ticked parent always takes in all its sub-items.
  always,
}

/// The parent / children links of a picker's items.
class PickerTree {
  PickerTree(Iterable<({String id, String? parentId})> items) {
    final ids = {for (final i in items) i.id};
    for (final i in items) {
      final p = i.parentId;
      if (p == null || !ids.contains(p)) continue;
      _parent[i.id] = p;
      (_children[p] ??= []).add(i.id);
    }
  }

  final _parent = <String, String>{};
  final _children = <String, List<String>>{};

  String? parentOf(String id) => _parent[id];

  List<String> childrenOf(String id) => _children[id] ?? const [];

  bool hasChildren(String id) => _children.containsKey(id);

  int depthOf(String id) {
    var d = 0;
    for (var p = _parent[id]; p != null; p = _parent[p]) {
      d++;
    }
    return d;
  }

  Iterable<String> ancestorsOf(String id) sync* {
    for (var p = _parent[id]; p != null; p = _parent[p]) {
      yield p;
    }
  }

  Iterable<String> descendantsOf(String id) sync* {
    for (final c in childrenOf(id)) {
      yield c;
      yield* descendantsOf(c);
    }
  }
}

/// What is ticked in a multi picker: each pick is an id and whether it takes
/// in its sub-items. A sub-item a pick takes in is never stored on its own.
class PickerSelection {
  PickerSelection({
    required this.mode,
    Iterable<String> ids = const [],
    Iterable<String> withChildren = const [],
    this.none = false,
  }) {
    final all = withChildren.toSet();
    for (final id in ids) {
      _picks[id] = mode != PickerChildren.separate && all.contains(id);
    }
    for (final id in all) {
      _picks.putIfAbsent(id, () => mode != PickerChildren.separate);
    }
  }

  final PickerChildren mode;
  final Map<String, bool> _picks = {};
  bool none;

  Iterable<String> get ids => _picks.keys;

  Set<String> get withChildren => {
    for (final e in _picks.entries)
      if (e.value) e.key,
  };

  bool isPicked(String id) => _picks.containsKey(id);

  bool takesChildren(String id) => _picks[id] ?? false;

  /// Drops the stored sub-items a pick already takes in; in [PickerChildren.toggle]
  /// a parent whose sub-items are all ticked takes them in.
  void normalize(PickerTree tree) {
    for (final e in [..._picks.entries]) {
      if (e.value) tree.descendantsOf(e.key).forEach(_picks.remove);
    }
    _collapse(tree);
  }

  /// The ticked ancestor that takes [id] in, if any.
  String? coveringAncestor(String id, PickerTree tree) {
    for (final a in tree.ancestorsOf(id)) {
      if (_picks[a] == true) return a;
    }
    return null;
  }

  bool shownTicked(String id, PickerTree tree) =>
      _picks.containsKey(id) || coveringAncestor(id, tree) != null;

  /// Every row that shows ticked (sub-items a pick takes in count too).
  int shownCount(PickerTree tree) =>
      _picks.length +
      _picks.entries
          .where((e) => e.value)
          .fold(0, (n, e) => n + tree.descendantsOf(e.key).length);

  void toggle(String id, PickerTree tree) {
    final cover = coveringAncestor(id, tree);
    if (cover != null) {
      _untickCovered(cover, id, tree);
      return;
    }
    if (_picks.remove(id) != null) return;
    if (mode == PickerChildren.always && tree.hasChildren(id)) {
      _picks[id] = true;
      tree.descendantsOf(id).forEach(_picks.remove);
      return;
    }
    _picks[id] = false;
    _collapse(tree);
  }

  /// The "take in sub-items" box of a ticked parent ([PickerChildren.toggle]).
  void setTakesChildren(String id, bool on, PickerTree tree) {
    _picks[id] = on;
    tree.descendantsOf(id).forEach(_picks.remove);
  }

  /// Unticking one sub-item of a parent that takes them all in. [toggle]: the
  /// parent stays, the other sub-items get ticked one by one. [always]: a
  /// parent can't be ticked without its sub-items, so it goes and its other
  /// branches stay ticked.
  void _untickCovered(String cover, String id, PickerTree tree) {
    if (mode == PickerChildren.toggle) {
      final out = {id, ...tree.descendantsOf(id)};
      _picks[cover] = false;
      for (final d in tree.descendantsOf(cover)) {
        if (!out.contains(d)) _picks[d] = false;
      }
      return;
    }
    _picks.remove(cover);
    for (final c in tree.childrenOf(cover)) {
      if (c == id) continue;
      if (tree.ancestorsOf(id).contains(c)) {
        _untickCovered(c, id, tree);
      } else {
        _picks[c] = tree.hasChildren(c);
      }
    }
  }

  void _collapse(PickerTree tree) {
    if (mode != PickerChildren.toggle) return;
    var changed = true;
    while (changed) {
      changed = false;
      for (final e in [..._picks.entries]) {
        if (e.value) continue;
        final subs = tree.descendantsOf(e.key).toList();
        if (subs.isEmpty || !subs.every((d) => shownTicked(d, tree))) continue;
        _picks[e.key] = true;
        subs.forEach(_picks.remove);
        changed = true;
      }
    }
  }
}
