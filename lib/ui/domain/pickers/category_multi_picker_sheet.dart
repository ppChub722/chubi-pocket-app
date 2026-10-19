import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../atoms/live_items.dart';

import '../../atoms/app_icon_button.dart';
import '../../atoms/select_check.dart';
import '../../molecules/detail_rows.dart';
import '../../molecules/empty_view.dart';
import '../../organisms/app_sheet.dart';
import '../../organisms/picker_sheet.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../icons/icon_display.dart';
import '../icons/icon_type.dart';
import 'category_picker_sheet.dart';

typedef CategoryMultiPick = ({String id, bool includeChildren});

/// The words of the multi category picker - the caller passes its localised
/// strings (the kit never reads the app's l10n).
class CategoryMultiPickerLabels {
  const CategoryMultiPickerLabels({
    required this.title,
    required this.searchHint,
    required this.includeChildren,
    required this.confirm,
    required this.empty,
    required this.noMatch,
  });

  final String title;
  final String searchHint;

  final String includeChildren;

  final String Function(int count) confirm;
  final String empty;
  final String noMatch;
}

Future<List<CategoryMultiPick>?> showCategoryMultiPicker(
  BuildContext context, {
  required List<CategoryPickerRow> rows,
  required CategoryMultiPickerLabels labels,
  List<CategoryMultiPick> initial = const [],
  int maxDepth = 2,
  bool showIncludeChildren = true,
  ValueListenable<List<CategoryPickerRow>>? live,
  Future<void> Function()? onRefresh,
}) {
  return showAppSheetCustom<List<CategoryMultiPick>>(
    context,
    builder: (_) => SheetRefreshScope(
      onRefresh: onRefresh,
      child: LiveItems<List<CategoryPickerRow>>(
        initial: rows,
        live: live,
        builder: (_, items) => CategoryMultiPickerSheet(
          rows: items,
          labels: labels,
          initial: initial,
          maxDepth: maxDepth,
          showIncludeChildren: showIncludeChildren,
        ),
      ),
    ),
  );
}

class CategoryMultiPickerSheet extends StatefulWidget {
  const CategoryMultiPickerSheet({
    required this.rows,
    required this.labels,
    this.initial = const [],
    this.maxDepth = 2,
    this.showIncludeChildren = true,
    super.key,
  });

  final List<CategoryPickerRow> rows;
  final CategoryMultiPickerLabels labels;
  final List<CategoryMultiPick> initial;
  final int maxDepth;

  final bool showIncludeChildren;

  @override
  State<CategoryMultiPickerSheet> createState() =>
      _CategoryMultiPickerSheetState();
}

class _CategoryMultiPickerSheetState extends State<CategoryMultiPickerSheet> {
  final Set<String> _expanded = <String>{};

  late final Map<String, bool> _picked = {
    for (final p in widget.initial) p.id: p.includeChildren,
  };

  @override
  void initState() {
    super.initState();
    final byId = {for (final c in widget.rows) c.id: c};
    for (final p in widget.initial) {
      var parentId = byId[p.id]?.parentId;
      while (parentId != null && _expanded.add(parentId)) {
        parentId = byId[parentId]?.parentId;
      }
    }
    // A parent that includes its sub-categories covers them: no separate ticks.
    for (final e in [..._picked.entries]) {
      if (e.value) _descendants(e.key).forEach(_picked.remove);
    }
    _collapse();
  }

  // "Include sub-categories" and the sub-categories' ticks are one thing:
  // on = every sub-category ticked (stored as the parent with includeChildren,
  // which also takes in ones added later), off = none of them; ticking them
  // all turns it on, unticking one turns it off.

  Iterable<String> _descendants(String id) sync* {
    for (final c in widget.rows) {
      if (c.parentId == id) {
        yield c.id;
        yield* _descendants(c.id);
      }
    }
  }

  /// The ticked ancestor whose "include sub-categories" covers [id], if any.
  String? _coveringAncestor(String id) {
    final byId = {for (final c in widget.rows) c.id: c};
    var p = byId[id]?.parentId;
    while (p != null) {
      if (_picked[p] == true) return p;
      p = byId[p]?.parentId;
    }
    return null;
  }

  bool _shownTicked(String id) =>
      _picked.containsKey(id) || _coveringAncestor(id) != null;

  /// A ticked parent whose sub-categories are all ticked one by one becomes
  /// "include sub-categories".
  void _collapse() {
    if (!widget.showIncludeChildren) return;
    var changed = true;
    while (changed) {
      changed = false;
      for (final e in [..._picked.entries]) {
        if (e.value) continue;
        final subs = _descendants(e.key).toList();
        if (subs.isEmpty || !subs.every(_picked.containsKey)) continue;
        _picked[e.key] = true;
        subs.forEach(_picked.remove);
        changed = true;
      }
    }
  }

  void _toggle(String id) => setState(() {
    final cover = _coveringAncestor(id);
    if (cover != null) {
      // Unticking one sub-category of an "all included" parent: the parent
      // keeps the others, ticked one by one.
      final out = {id, ..._descendants(id)};
      _picked[cover] = false;
      for (final d in _descendants(cover)) {
        if (!out.contains(d)) _picked[d] = false;
      }
      return;
    }
    if (_picked.containsKey(id)) {
      _picked.remove(id);
    } else {
      _picked[id] = false;
    }
    _collapse();
  });

  void _setInclude(String id, bool on) => setState(() {
    _picked[id] = on;
    _descendants(id).forEach(_picked.remove);
  });

  int get _shownCount =>
      _picked.length +
      [
        for (final e in _picked.entries)
          if (e.value) _descendants(e.key).length,
      ].fold(0, (a, b) => a + b);

  List<CategoryMultiPick> _result() => [
    for (final e in _picked.entries) (id: e.key, includeChildren: e.value),
  ];

  @override
  Widget build(BuildContext context) {
    final l = widget.labels;
    return PickerSheet(
      title: l.title,
      searchable: true,
      searchToggle: true,
      searchHint: l.searchHint,
      footer: PickerConfirmBar(
        label: l.confirm(_shownCount),
        onPressed: () => Navigator.of(context).pop(_result()),
      ),
      builder: _body,
    );
  }

  Widget _body(BuildContext context, String query) {
    final l = widget.labels;
    final pool = widget.rows;
    final byId = {for (final c in pool) c.id: c};
    int depthOf(CategoryPickerRow c) {
      var d = 0;
      var p = c.parentId;
      while (p != null && byId[p] != null) {
        d++;
        p = byId[p]!.parentId;
      }
      return d;
    }

    Set<String>? visible;
    final forced = <String>{};
    if (query.isNotEmpty) {
      visible = {};
      for (final c in pool) {
        if (depthOf(c) > widget.maxDepth) continue;
        if (!c.name.toLowerCase().contains(query)) continue;
        visible.add(c.id);
        var p = c.parentId;
        while (p != null && byId[p] != null) {
          visible.add(p);
          forced.add(p);
          p = byId[p]!.parentId;
        }
      }
    }

    final roots = pool.where((c) => c.parentId == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final rows = <Widget>[];
    for (final root in roots) {
      _collectRows(
        rows,
        root,
        pool,
        depth: 0,
        visible: visible,
        forced: forced,
      );
    }
    final empty = query.isEmpty ? roots.isEmpty : (visible?.isEmpty ?? true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.isNotEmpty) SectionCard(first: true, children: rows),
        if (empty)
          EmptyView.compact(message: query.isEmpty ? l.empty : l.noMatch),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  void _collectRows(
    List<Widget> out,
    CategoryPickerRow category,
    List<CategoryPickerRow> pool, {
    required int depth,
    required Set<String>? visible,
    required Set<String> forced,
  }) {
    if (visible != null && !visible.contains(category.id)) return;
    final children = pool.where((c) => c.parentId == category.id).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final hasChildren = children.isNotEmpty && depth < widget.maxDepth;
    final isExpanded =
        forced.contains(category.id) || _expanded.contains(category.id);
    final picked = _shownTicked(category.id);
    final theme = Theme.of(context);

    Widget? trailing;
    if (hasChildren) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_picked.containsKey(category.id) &&
              widget.showIncludeChildren) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _setInclude(category.id, !_picked[category.id]!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.labels.includeChildren,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SelectCheck(
                    key: ValueKey('include-${category.id}'),
                    value: _picked[category.id]!,
                    tooltip: widget.labels.includeChildren,
                    onTap: () =>
                        _setInclude(category.id, !_picked[category.id]!),
                  ),
                ],
              ),
            ),
          ],
          AppIconButton.flat(
            icon: isExpanded ? AppIcons.collapse : AppIcons.expand,
            onPressed: forced.contains(category.id)
                ? null
                : () => setState(() {
                    if (!_expanded.remove(category.id)) {
                      _expanded.add(category.id);
                    }
                  }),
          ),
        ],
      );
    }

    out.add(
      PickerRow(
        key: ValueKey('row-${category.id}'),
        indent: depth * AppSpacing.xl,
        leading: IconDisplay(
          type: IconType.category,
          size: 32,
          iconCode: category.iconCode,
        ),
        title: category.name,
        checked: picked,
        onTap: () => _toggle(category.id),
        trailing: trailing,
      ),
    );

    if (hasChildren && isExpanded) {
      for (final child in children) {
        _collectRows(
          out,
          child,
          pool,
          depth: depth + 1,
          visible: visible,
          forced: forced,
        );
      }
    }
  }
}
