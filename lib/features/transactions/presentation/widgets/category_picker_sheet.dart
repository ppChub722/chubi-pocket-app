import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../../shared/icon_maker/icon_registry.dart';

/// Result returned by [showCategoryPickerSheet]. Distinct from `null`
/// (which means "user dismissed without picking") — `clear` means
/// "user explicitly chose Uncategorized".
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

/// Modal bottom sheet that shows the user's category tree filtered by
/// [type], with all levels selectable and collapsible parents.
///
/// Behavior:
/// - **Tap a row body** → select that level (parent or leaf, both fine).
/// - **Tap the chevron** → toggle expand/collapse, no selection change.
/// - **"Uncategorized" first row** → clears the category (only when
///   [allowNone] is true; transfers don't see this).
/// - System categories are filtered out — they're auto-assigned by the
///   server for transfers and shouldn't surface in pickers.
///
/// Default expansion: only L1 (no parent) categories show; L2/L3 are
/// hidden until the user expands the parent. Expansion state is local
/// to the sheet — closing and reopening resets it.
Future<CategoryPickerResult?> showCategoryPickerSheet({
  required BuildContext context,
  required List<Category> categories,
  required CategoryType type,
  Category? selected,
  bool allowNone = true,
}) {
  return showModalBottomSheet<CategoryPickerResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CategoryPickerBody(
      categories: categories,
      type: type,
      selected: selected,
      allowNone: allowNone,
    ),
  );
}

class _CategoryPickerBody extends StatefulWidget {
  const _CategoryPickerBody({
    required this.categories,
    required this.type,
    required this.selected,
    required this.allowNone,
  });

  final List<Category> categories;
  final CategoryType type;
  final Category? selected;
  final bool allowNone;

  @override
  State<_CategoryPickerBody> createState() => _CategoryPickerBodyState();
}

class _CategoryPickerBodyState extends State<_CategoryPickerBody> {
  /// Ids whose subtree is currently expanded. L1 is implicitly always
  /// rendered — this set tracks expanded **L2 and L3 ancestors**.
  /// Keeping it explicit rather than a per-row bool avoids stateful
  /// widgets per row.
  final Set<String> _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final pool = widget.categories
        .where((c) => !c.isSystem && c.type == widget.type)
        .toList();
    final roots = pool.where((c) => c.parentId == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final rows = <Widget>[];
    if (widget.allowNone) {
      rows.add(_NoneRow(
        selected: widget.selected == null,
        onTap: () => Navigator.of(context).pop(const CategoryPickerCleared()),
      ));
    }
    for (final root in roots) {
      _collectRows(rows, root, pool, depth: 0);
    }

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Text(
              l.transactionFormCategoryPickerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (roots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l.transactionFormCategoryPickerEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: rows,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
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
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expanded.contains(category.id);

    out.add(_CategoryRow(
      category: category,
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
    ));

    if (hasChildren && isExpanded) {
      for (final child in children) {
        _collectRows(out, child, pool, depth: depth + 1);
      }
    }
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.depth,
    required this.isSelected,
    required this.hasChildren,
    required this.isExpanded,
    required this.onTap,
    required this.onToggleExpand,
  });

  final Category category;
  final int depth;
  final bool isSelected;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg + depth * AppSpacing.xxl,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: category.iconCode?.resolvedBgColor ?? Colors.grey,
              child: Icon(IconRegistry.get(category.iconCode?.icon, fallback: Icons.category_outlined), color: Colors.white, size: 16),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Icon(Icons.check, color: scheme.primary, size: 20),
              ),
            if (hasChildren)
              IconButton(
                icon: AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: const Icon(Icons.chevron_right),
                ),
                onPressed: onToggleExpand,
              ),
          ],
        ),
      ),
    );
  }
}

class _NoneRow extends StatelessWidget {
  const _NoneRow({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.label_off_outlined, color: scheme.onSurfaceVariant),
      title: Text(l.transactionFormCategoryPickerNoneOption),
      trailing: selected ? Icon(Icons.check, color: scheme.primary) : null,
      onTap: onTap,
    );
  }
}
