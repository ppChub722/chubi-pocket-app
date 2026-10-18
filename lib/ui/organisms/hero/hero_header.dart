import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../atoms/ui_config.dart';
import '../../molecules/card_action_button.dart';
import '../../molecules/hero_shell.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/chip_size.dart';
import 'app_hero_card.dart';

/// An [AppHeroCard]'s header: [leading] (chips, a period pill) on the left,
/// [actions] (links, 🔍, 👁) on the right, then what the card adds by
/// itself — the ✏️ ([onEdit], view mode only) and the ⌄ / ⌃ (when the card
/// can fold). Everything in it is control-sized and one height.
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

  /// Shows the ✏️ in view mode. Null = no ✏️.
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
    return ChipSizeScope(
      size: ChipSize.control,
      child: HeroTopRow(leading: leading, trailing: [...actions, ?edit, ?fold]),
    );
  }
}
