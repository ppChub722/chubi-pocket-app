import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../category_label.dart';
import '../cubit/categories_cubit.dart';

class CategoryPickCard extends StatelessWidget {
  const CategoryPickCard({
    required this.category,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.errorText,
    this.dense = false,
    this.editable = false,
    this.onLongPress,
    super.key,
  });

  final Category? category;
  final String label;
  final String placeholder;
  final VoidCallback? onTap;
  final String? errorText;

  final bool editable;
  final VoidCallback? onLongPress;

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
      reserveSubtitle: true,
      label: label,
      value: c == null
          ? null
          : categoryDisplayName(AppLocalizations.of(context)!, c),
      placeholder: placeholder,
      leading: c == null
          ? PickCardEmptyIcon(AppIcons.category, size: _icon)
          : IconDisplay(
              type: IconType.category,
              size: _icon,
              iconCode: iconCode,
            ),
      subtitle: path.isEmpty ? null : Text(path),
      accent: iconCode.tintFor(palette),
      onTap: onTap,
      editable: editable,
      onLongPress: onLongPress,
      errorText: errorText,
      dense: dense,
    );
  }
}
