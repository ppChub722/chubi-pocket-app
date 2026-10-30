import 'package:flutter/material.dart';

import '../../ui.dart';
import '../../../features/saving_goals/domain/saving_goal.dart';

/// Where a saving goes, as a pick tile: the chosen [goal], ยังไม่จัดสรร
/// ([spare], a real choice so it reads as picked), or nothing yet (dashed
/// "+ [placeholder]").
class SavingGoalPickCard extends StatelessWidget {
  const SavingGoalPickCard({
    required this.goal,
    required this.label,
    required this.placeholder,
    required this.spareLabel,
    required this.onTap,
    this.spare = false,
    this.spareAmount,
    this.errorText,
    this.dense = false,
    this.editable = false,
    this.onLongPress,
    super.key,
  });

  final SavingGoal? goal;

  /// ยังไม่จัดสรร is chosen (used when [goal] is null).
  final bool spare;
  final String label;
  final String placeholder;
  final String spareLabel;

  /// What ยังไม่จัดสรร holds, its line under the name.
  final double? spareAmount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? errorText;
  final bool dense;
  final bool editable;

  double get _icon => dense ? 32 : 40;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final g = goal;
    String money(double v) => moneyString(context, v);
    final target = g?.targetAmount;
    final String? status = g != null
        ? (target == null
              ? money(g.savedAmount)
              : '${money(g.savedAmount)} / ${money(target)}')
        : spare && spareAmount != null
        ? money(spareAmount!)
        : null;
    final picked = g != null || spare;
    return PickCard(
      label: label,
      value: g?.name ?? (spare ? spareLabel : null),
      placeholder: placeholder,
      reserveSubtitle: true,
      subtitle: status == null ? null : Text(status),
      dense: dense,
      editable: editable,
      errorText: errorText,
      accent: !picked
          ? null
          : g == null
          ? ModuleColors.of(context).planning
          : g.iconCode.tintFor(palette),
      leading: g == null
          ? PickCardEmptyIcon(AppIcons.quickSaving, size: _icon)
          : IconDisplay(
              type: IconType.category,
              size: _icon,
              iconCode: g.iconCode,
            ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
