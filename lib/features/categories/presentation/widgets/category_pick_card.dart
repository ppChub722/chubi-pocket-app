import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../cubit/categories_cubit.dart';

/// A category as a [PickCard]: once picked, the card takes the category's
/// own icon and colour (inherited from its top-level parent, as on the
/// categories page) with the parent path underneath. Nothing picked → the
/// dashed empty card. Opening the picker is the caller's [onTap].
class CategoryPickCard extends StatelessWidget {
  const CategoryPickCard({
    required this.category,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.errorText,
    this.dense = false,
    super.key,
  });

  final Category? category;
  final String label;
  final String placeholder;
  final VoidCallback? onTap;
  final String? errorText;

  /// [PickCard.dense], with a smaller icon — two cards on one row.
  final bool dense;

  double get _icon => dense ? 32 : 40;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final all = context.watch<CategoriesCubit>().state.categories;
    final c = category;
    final iconCode = c == null ? null : CategoryTree.resolveIconCode(c, all);
    final path = c == null ? '' : CategoryTree.breadcrumb(c, all);
    return PickCard(
      label: label,
      value: c?.name,
      placeholder: placeholder,
      leading: c == null
          ? PickCardEmptyIcon(AppIcons.category, size: _icon)
          : IconDisplay(
              type: IconType.category,
              size: _icon,
              iconCode: iconCode,
            ),
      subtitle: path.isEmpty ? null : Text(path),
      accent: iconCode?.accentColorFor(palette) ?? palette.primary,
      onTap: onTap,
      errorText: errorText,
      dense: dense,
    );
  }
}
