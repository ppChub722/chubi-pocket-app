import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../shared/widgets/chips/pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../category_label.dart';
import '../cubit/categories_cubit.dart';

/// A category as a pill — `[icon] name` in the category's colour, the same
/// look as a tag's [TagChip] picker chip. [selected] = the full colour,
/// otherwise a neutral outline (the icon keeps its colour). The quick
/// create's "recent categories" row.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.category,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final Category category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final all = context.watch<CategoriesCubit>().state.categories;
    // L2/L3 wear their top-level parent's icon, as everywhere else.
    final code = CategoryTree.resolveIconCode(category, all);
    final color = code?.accentColorFor(palette) ?? palette.primary;
    final fg = selected ? color : scheme.onSurfaceVariant;
    return Material(
      color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? color : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // The one chip size (PillSize.normal, owner 2026-10-11).
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: PillSize.normal.height),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: PillSize.normal.padding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconRegistry.get(code?.icon, fallback: AppIcons.category),
                  size: PillSize.normal.icon,
                  color: color,
                ),
                SizedBox(width: PillSize.normal.gap),
                // Flexible: a chip given a fixed width (the detail card's
                // half-row) ellipsises a long name instead of overflowing.
                Flexible(
                  child: Text(
                    categoryDisplayName(
                      AppLocalizations.of(context)!,
                      category,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PillSize.normal
                        .textStyle(context)
                        ?.copyWith(color: fg, fontWeight: PillSize.chipWeight),
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
