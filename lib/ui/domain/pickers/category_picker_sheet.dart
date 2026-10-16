import 'package:flutter/material.dart';

import 'package:pp_forge/pp_forge.dart';
import '../icons/icon_type.dart';

/// One category row of [showCategoryPicker] — plain values, no feature
/// model. The caller passes only the rows that may be shown (already
/// filtered by type / system / excluded) and the [iconCode] to draw (already
/// resolved, e.g. inherited from the L1 parent).
@immutable
class CategoryPickerRow {
  const CategoryPickerRow({
    required this.id,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    this.iconCode,
  });

  final String id;
  final String name;
  final String? parentId;
  final int sortOrder;
  final IconCode? iconCode;
}

/// The words of the category picker — the caller passes its localised
/// strings (the kit never reads the app's l10n).
class CategoryPickerLabels {
  const CategoryPickerLabels({
    required this.title,
    required this.searchHint,
    required this.none,
    required this.addNew,
    required this.empty,
    required this.noMatch,
  });

  final String title;
  final String searchHint;

  /// The "None" row (clear / top-level).
  final String none;

  /// The create row under the tree (only with `onCreate`).
  final String addNew;

  /// No rows at all.
  final String empty;

  /// A search with no match.
  final String noMatch;
}

/// What [showCategoryPicker] resolves (null = dismissed).
sealed class CategoryPickerChoice {
  const CategoryPickerChoice();
}

/// A row was picked.
class CategoryPickerPicked extends CategoryPickerChoice {
  const CategoryPickerPicked(this.id);
  final String id;
}

/// The None row was picked.
class CategoryPickerNone extends CategoryPickerChoice {
  const CategoryPickerNone();
}

/// THE category-tree picker — a PRESENTATIONAL organism on [PickerSheet]:
/// header + close, a search that keeps the tree (a match's parents open
/// around it), the picked row highlighted (no tick). Tap a row to pick it;
/// the chevron — only on rows with children — opens / closes a level.
///
/// - [maxDepth]: deepest level (0-based) shown and selectable.
/// - [selectedId]: highlighted; its ancestors open and it scrolls into view.
/// - [allowNone]: a None row (cleared) first.
/// - [onCreate]: when set, a create row under the tree; it runs the caller's
///   create flow and returns the new row's id (null = nothing created, the
///   picker stays), which is then picked and closes the sheet.
Future<CategoryPickerChoice?> showCategoryPicker(
  BuildContext context, {
  required List<CategoryPickerRow> rows,
  required CategoryPickerLabels labels,
  String? selectedId,
  bool allowNone = true,
  int maxDepth = 2,
  Future<String?> Function()? onCreate,
}) {
  return showPpForgeSheetCustom<CategoryPickerChoice>(
    context,
    builder: (_) => CategoryPickerSheet(
      rows: rows,
      labels: labels,
      selectedId: selectedId,
      allowNone: allowNone,
      maxDepth: maxDepth,
      onCreate: onCreate,
    ),
  );
}

/// The sheet body of [showCategoryPicker]; pops a
/// [CategoryPickerChoice].
class CategoryPickerSheet extends StatefulWidget {
  const CategoryPickerSheet({
    required this.rows,
    required this.labels,
    this.selectedId,
    this.allowNone = true,
    this.maxDepth = 2,
    this.onCreate,
    super.key,
  });

  final List<CategoryPickerRow> rows;
  final CategoryPickerLabels labels;
  final String? selectedId;
  final bool allowNone;
  final int maxDepth;
  final Future<String?> Function()? onCreate;

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  /// Ids whose subtree is currently expanded.
  final Set<String> _expanded = <String>{};

  /// The picked row — scrolled into view on open.
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // A deep pick opens down to its level: expand every ancestor, then
    // bring the row into view.
    final byId = {for (final c in widget.rows) c.id: c};
    var parentId = byId[widget.selectedId]?.parentId;
    while (parentId != null && _expanded.add(parentId)) {
      parentId = byId[parentId]?.parentId;
    }
    if (widget.selectedId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final row = _selectedKey.currentContext;
        if (row != null && row.mounted) {
          Scrollable.ensureVisible(row, alignment: 0.4);
        }
      });
    }
  }

  Future<void> _create() async {
    final id = await widget.onCreate!();
    if (!mounted || id == null) return;
    Navigator.of(context).pop(CategoryPickerPicked(id));
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.labels;
    return PickerSheet(
      title: l.title,
      searchable: true,
      searchHint: l.searchHint,
      footer: widget.onCreate != null
          ? PickerCreateRow(label: l.addNew, onTap: _create)
          : null,
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

    // Searching: the matches (within reach) and every parent above them,
    // opened — so a match always shows where it sits.
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
    final rows = <Widget>[
      if (widget.allowNone && query.isEmpty)
        PickerRow(
          leading: const PpForgeIcon(PpForgeIcons.noCategory),
          title: l.none,
          selected: widget.selectedId == null,
          onTap: () => Navigator.of(context).pop(const CategoryPickerNone()),
        ),
    ];
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
        const SizedBox(height: PpForgeSpacing.sm),
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
    // Children past [maxDepth] are neither shown nor expandable.
    final canDescend = depth < widget.maxDepth;
    final hasChildren = children.isNotEmpty && canDescend;
    final isExpanded =
        forced.contains(category.id) || _expanded.contains(category.id);
    final picked = widget.selectedId == category.id;

    out.add(
      PickerRow(
        key: picked ? _selectedKey : null,
        indent: depth * PpForgeSpacing.xl,
        leading: IconDisplay(
          type: IconType.category,
          size: 32,
          iconCode: category.iconCode,
        ),
        title: category.name,
        selected: picked,
        onTap: () =>
            Navigator.of(context).pop(CategoryPickerPicked(category.id)),
        // The chevron only where there's a level to open (a right chevron
        // would mean "go somewhere else" in this app).
        trailing: hasChildren
            ? PpForgeIconButton.flat(
                icon: isExpanded ? PpForgeIcons.collapse : PpForgeIcons.expand,
                onPressed: forced.contains(category.id)
                    ? null
                    : () => setState(() {
                        if (!_expanded.remove(category.id)) {
                          _expanded.add(category.id);
                        }
                      }),
              )
            : null,
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
