import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../atoms/ui_config.dart';
import '../../molecules/card_action_button.dart';
import '../../molecules/hero_shell.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/chip_size.dart';
import 'app_hero_card.dart';

/// Adds the ✏️ (view mode) and the fold button (when the card folds) itself.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    this.leading = const [],
    this.actions = const [],
    this.onEdit,
    this.editTooltip,
    super.key,
  });

  final List<Widget> leading;
  final List<Widget> actions;

  final VoidCallback? onEdit;
  final String? editTooltip;

  @override
  Widget build(BuildContext context) {
    final scope = AppHeroScope.maybeOf(context);
    final mode = scope?.mode ?? HeroCardMode.view;
    final edit = mode == HeroCardMode.view && onEdit != null
        ? CardActionButton(
            key: const ValueKey('heroEdit'),
            icon: AppIcons.edit,
            tooltip: editTooltip ?? UiConfig.stringsOf(context).edit,
            onTap: onEdit,
          )
        : null;
    final fold = scope != null && scope.canFold
        ? const AppHeroFoldButton(key: ValueKey('heroFold'))
        : null;
    if (fold == null) {
      return ChipSizeScope(
        size: ChipSize.control,
        child: HeroTopRow(leading: leading, trailing: [...actions, ?edit]),
      );
    }
    // The fold chevron sits small in the card's corner (half in the card
    // padding), so it doesn't read as another round action button.
    return ChipSizeScope(
      size: ChipSize.control,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          HeroTopRow(
            leading: leading,
            trailing: [
              ...actions,
              ?edit,
              const SizedBox(width: _foldReserve),
            ],
          ),
          PositionedDirectional(top: -_foldTuck, end: -_foldTuck, child: fold),
        ],
      ),
    );
  }

  static const double _foldTuck = 10;
  static const double _foldReserve = AppHeroFoldButton.size - _foldTuck - 4;
}
