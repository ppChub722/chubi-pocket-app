import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../pages/category_detail_page.dart';

/// Result returned by [showCategoryPickerSheet]. Distinct from `null`
/// (which means "user dismissed without picking") — `cleared` means
/// "user explicitly chose the None option".
sealed class CategoryPickerResult {
  const CategoryPickerResult();
}

class CategoryPickerSelected extends CategoryPickerResult {
  const CategoryPickerSelected(this.category);
  final Category category;
}

class CategoryPickerCleared extends CategoryPickerResult {
  const CategoryPickerCleared();
}

/// Shared category-tree picker, on the kit [PickerSheet] (owner
/// 2026-10-10): header + ✕, a search that keeps the tree (a match's
/// parents open around it), the picked row highlighted (no ✓). Tap a row
/// to pick it; ▾ / ▴ — only on rows that have children — opens / closes
/// a level.
///
/// Reusable across features via arguments:
/// - [maxDepth] — deepest level (0-based: L1=0, L2=1, L3=2) that is shown
///   **and** selectable. Quick-create picks any of 3 levels (`maxDepth: 2`);
///   the category-parent picker only allows L1/L2 (`maxDepth: 1`) because a
///   child of the picked parent must stay within 3 levels.
/// - [excludeIds] — rows (and their whole subtree) to hide. The parent
///   picker passes the edited category + its descendants so you can't pick
///   yourself or create a cycle.
/// - [allowNone] / [noneLabel] — show a "None" row (clear / top-level).
/// - [title] — sheet heading (default "เลือกหมวดหมู่").
/// - [allowCreate] — a "＋ เพิ่มหมวดหมู่" row: opens the create page over the
///   sheet; saving there picks the new category and closes the picker, back
///   returns to the picker (owner 2026-10-10).
///
/// System categories are always filtered out (server auto-assigns them).
Future<CategoryPickerResult?> showCategoryPickerSheet({
  required BuildContext context,
  required List<Category> categories,
  required CategoryType type,
  Category? selected,
  bool allowNone = true,
  String? title,
  String? noneLabel,
  int maxDepth = 2,
  Set<String> excludeIds = const <String>{},
  bool allowCreate = false,
}) {
  return showAppSheetCustom<CategoryPickerResult>(
    context,
    builder: (_) => _CategoryPicker(
      title: title,
      categories: categories,
      type: type,
      selected: selected,
      allowNone: allowNone,
      noneLabel: noneLabel,
      maxDepth: maxDepth,
      excludeIds: excludeIds,
      allowCreate: allowCreate,
    ),
  );
}

class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({
    required this.title,
    required this.categories,
    required this.type,
    required this.selected,
    required this.allowNone,
    required this.noneLabel,
    required this.maxDepth,
    required this.excludeIds,
    required this.allowCreate,
  });

  final String? title;
  final List<Category> categories;
  final CategoryType type;
  final Category? selected;
  final bool allowNone;
  final String? noneLabel;
  final int maxDepth;
  final Set<String> excludeIds;
  final bool allowCreate;

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  /// Ids whose subtree is currently expanded.
  final Set<String> _expanded = <String>{};

  /// The picked row — scrolled into view on open.
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // A deep pick opens down to its level (owner 2026-10-10): expand every
    // ancestor, then bring the row into view.
    final byId = {for (final c in widget.categories) c.id: c};
    var parentId = widget.selected?.parentId;
    while (parentId != null && _expanded.add(parentId)) {
      parentId = byId[parentId]?.parentId;
    }
    if (widget.selected != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final row = _selectedKey.currentContext;
        if (row != null && row.mounted) {
          Scrollable.ensureVisible(row, alignment: 0.4);
        }
      });
    }
  }

  /// The create page, pushed over the sheet. Saving there pops with the
  /// new category → pick it; back (nothing saved) returns to the picker.
  Future<void> _create() async {
    final created = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<Category>(
        builder: (_) =>
            CategoryDetailPage(initialType: widget.type, popOnCreate: true),
      ),
    );
    if (!mounted || created == null) return;
    Navigator.of(context).pop(CategoryPickerSelected(created));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PickerSheet(
      title: widget.title ?? l.categoryPickerTitle,
      searchable: true,
      searchHint: l.categoryPickerSearchHint,
      footer: widget.allowCreate
          ? PickerCreateRow(label: l.categoriesAddNew, onTap: _create)
          : null,
      builder: _body,
    );
  }

  Widget _body(BuildContext context, String query) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final pool = widget.categories
        .where(
          (c) =>
              !c.isSystem &&
              c.type == widget.type &&
              !widget.excludeIds.contains(c.id),
        )
        .toList();
    final byId = {for (final c in pool) c.id: c};
    int depthOf(Category c) {
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
          leading: const Icon(AppIcons.noCategory),
          title: widget.noneLabel ?? l.transactionFormCategoryPickerNoneOption,
          selected: widget.selected == null,
          onTap: () => Navigator.of(context).pop(const CategoryPickerCleared()),
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
    if (empty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            query.isEmpty
                ? l.transactionFormCategoryPickerEmpty
                : l.categoryPickerNoMatch,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...rows,
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  void _collectRows(
    List<Widget> out,
    Category category,
    List<Category> pool, {
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
    final picked = widget.selected?.id == category.id;

    out.add(
      PickerRow(
        key: picked ? _selectedKey : null,
        indent: depth * AppSpacing.xl,
        leading: IconDisplay(
          type: IconType.category,
          size: 32,
          iconCode: CategoryTree.resolveIconCode(category, widget.categories),
        ),
        title: category.name,
        selected: picked,
        onTap: () =>
            Navigator.of(context).pop(CategoryPickerSelected(category)),
        // ▾ / ▴ only where there's a level to open (› would mean "go
        // somewhere else" in this app).
        trailing: hasChildren
            ? IconButton(
                icon: Icon(isExpanded ? AppIcons.collapse : AppIcons.expand),
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
