import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../cubit/categories_cubit.dart';
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

/// Shared category-tree picker (bottom sheet). Shows the user's tree for
/// [type] with collapsible parents; tap a row to select it.
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
/// - [title] — sheet heading.
/// - [allowCreate] — a "+ เพิ่มหมวดหมู่" row: opens the create page over the
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
  return showAppSheet<CategoryPickerResult>(
    context,
    title:
        title ??
        AppLocalizations.of(context)!.transactionFormCategoryPickerTitle,
    builder: (_) => _CategoryPickerBody(
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

class _CategoryPickerBody extends StatefulWidget {
  const _CategoryPickerBody({
    required this.categories,
    required this.type,
    required this.selected,
    required this.allowNone,
    required this.noneLabel,
    required this.maxDepth,
    required this.excludeIds,
    required this.allowCreate,
  });

  final List<Category> categories;
  final CategoryType type;
  final Category? selected;
  final bool allowNone;
  final String? noneLabel;
  final int maxDepth;
  final Set<String> excludeIds;
  final bool allowCreate;

  @override
  State<_CategoryPickerBody> createState() => _CategoryPickerBodyState();
}

class _CategoryPickerBodyState extends State<_CategoryPickerBody> {
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

  /// The create page, pushed over the sheet. A category of this type that
  /// wasn't there before is the one just made → pick it.
  Future<void> _create() async {
    final cubit = context.read<CategoriesCubit>();
    final before = {for (final c in cubit.state.categories) c.id};
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryDetailPage(initialType: widget.type),
      ),
    );
    if (!mounted) return;
    final created = cubit.state.categories
        .where((c) => c.type == widget.type && !before.contains(c.id))
        .lastOrNull;
    if (created != null) {
      Navigator.of(context).pop(CategoryPickerSelected(created));
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final roots = pool.where((c) => c.parentId == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final rows = <Widget>[];
    if (widget.allowNone) {
      rows.add(
        _NoneRow(
          label: widget.noneLabel ?? l.transactionFormCategoryPickerNoneOption,
          selected: widget.selected == null,
          onTap: () => Navigator.of(context).pop(const CategoryPickerCleared()),
        ),
      );
    }
    for (final root in roots) {
      _collectRows(rows, root, pool, depth: 0);
    }

    // [AppSheetScaffold] (title row + drag handle) scrolls the body.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (roots.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              l.transactionFormCategoryPickerEmpty,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          )
        else
          ...rows,
        if (widget.allowCreate)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              0,
            ),
            child: AddTile(
              label: l.categoriesAddNew,
              variant: AddTileVariant.row,
              onTap: _create,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  void _collectRows(
    List<Widget> out,
    Category category,
    List<Category> pool, {
    required int depth,
  }) {
    final children = pool.where((c) => c.parentId == category.id).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    // Children past [maxDepth] are neither shown nor expandable.
    final canDescend = depth < widget.maxDepth;
    final hasChildren = children.isNotEmpty && canDescend;
    final isExpanded = _expanded.contains(category.id);

    out.add(
      _CategoryRow(
        key: widget.selected?.id == category.id ? _selectedKey : null,
        category: category,
        iconCode: CategoryTree.resolveIconCode(category, widget.categories),
        depth: depth,
        isSelected: widget.selected?.id == category.id,
        hasChildren: hasChildren,
        isExpanded: isExpanded,
        onTap: () {
          Navigator.of(context).pop(CategoryPickerSelected(category));
        },
        onToggleExpand: hasChildren
            ? () {
                setState(() {
                  if (isExpanded) {
                    _expanded.remove(category.id);
                  } else {
                    _expanded.add(category.id);
                  }
                });
              }
            : null,
      ),
    );

    if (hasChildren && isExpanded) {
      for (final child in children) {
        _collectRows(out, child, pool, depth: depth + 1);
      }
    }
  }
}

/// Background of the picked row — the "this one" highlight (no ✓).
Color _selectedTint(BuildContext context) =>
    Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    super.key,
    required this.category,
    required this.iconCode,
    required this.depth,
    required this.isSelected,
    required this.hasChildren,
    required this.isExpanded,
    required this.onTap,
    required this.onToggleExpand,
  });

  final Category category;

  /// Inherited from the top-level parent, as on the categories page.
  final IconCode? iconCode;
  final int depth;
  final bool isSelected;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Material(
        color: isSelected ? _selectedTint(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm + depth * AppSpacing.xxl,
              AppSpacing.sm,
              0,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                IconDisplay(
                  type: IconType.category,
                  size: 32,
                  iconCode: iconCode,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    category.name,
                    style: isSelected
                        ? textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          )
                        : textTheme.bodyLarge,
                  ),
                ),
                if (hasChildren)
                  IconButton(
                    icon: AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: const Icon(AppIcons.chevronRight),
                    ),
                    onPressed: onToggleExpand,
                  )
                else
                  // Keep names aligned with expandable rows.
                  const SizedBox(width: 48, height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoneRow extends StatelessWidget {
  const _NoneRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Material(
        color: selected ? _selectedTint(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.category,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w700 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
