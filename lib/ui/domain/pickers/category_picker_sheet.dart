import 'package:flutter/material.dart';

import '../../atoms/app_icon.dart';
import '../../atoms/app_icon_button.dart';
import '../../molecules/detail_rows.dart';
import '../../molecules/empty_view.dart';
import '../../organisms/app_sheet.dart';
import '../../organisms/picker_sheet.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../icons/icon_code.dart';
import '../icons/icon_display.dart';
import '../icons/icon_type.dart';

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

/// The words of the category picker — the caller passes its localised strings
/// (the kit never reads the app's l10n).
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

  final String none;

  final String addNew;

  final String empty;

  final String noMatch;
}

sealed class CategoryPickerChoice {
  const CategoryPickerChoice();
}

class CategoryPickerPicked extends CategoryPickerChoice {
  const CategoryPickerPicked(this.id);
  final String id;
}

class CategoryPickerNone extends CategoryPickerChoice {
  const CategoryPickerNone();
}

Future<CategoryPickerChoice?> showCategoryPicker(
  BuildContext context, {
  required List<CategoryPickerRow> rows,
  required CategoryPickerLabels labels,
  String? selectedId,
  bool allowNone = true,
  int maxDepth = 2,
  Future<String?> Function()? onCreate,
}) {
  return showAppSheetCustom<CategoryPickerChoice>(
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
  final Set<String> _expanded = <String>{};

  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
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
      searchToggle: true,
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
          leading: const AppIcon(AppIcons.noCategory),
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
    final canDescend = depth < widget.maxDepth;
    final hasChildren = children.isNotEmpty && canDescend;
    final isExpanded =
        forced.contains(category.id) || _expanded.contains(category.id);
    final picked = widget.selectedId == category.id;

    out.add(
      PickerRow(
        key: picked ? _selectedKey : null,
        indent: depth * AppSpacing.xl,
        leading: IconDisplay(
          type: IconType.category,
          size: 32,
          iconCode: category.iconCode,
        ),
        title: category.name,
        selected: picked,
        onTap: () =>
            Navigator.of(context).pop(CategoryPickerPicked(category.id)),
        // The chevron only where there's a level to open (a right chevron would
        // mean "go somewhere else" in this app).
        trailing: hasChildren
            ? AppIconButton.flat(
                icon: isExpanded ? AppIcons.collapse : AppIcons.expand,
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
