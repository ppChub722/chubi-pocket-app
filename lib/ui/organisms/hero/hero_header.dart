import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../atoms/ui_config.dart';
import '../../molecules/card_action_button.dart';
import '../../molecules/hero_shell.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/chip_size.dart';
import '../../tokens/hero_metrics.dart';
import 'app_hero_card.dart';
import 'hero_summary_head.dart';

/// Adds the ✏️ (view mode) and the fold button (when the card folds) itself.
///
/// With [fill] it is a list hero's head: ONE row, [leading] · [fill] taking
/// all the room left · [actions], every control as tall as the module tile
/// ([HeroModuleTile.size]) and centred on one axis. A [StepperPill] in [fill]
/// takes the full width, ‹ › at its ends. The fold ⌄ / ⌃ stays in the corner.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    this.leading = const [],
    this.fill,
    this.actions = const [],
    this.onEdit,
    this.editTooltip,
    super.key,
  });

  final List<Widget> leading;

  /// Stretches between [leading] and [actions] (the period stepper).
  final Widget? fill;
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
    final trailing = [
      ...actions,
      ?edit,
      if (fold != null) const SizedBox(width: _foldReserve),
    ];
    final fill = this.fill;
    Widget row = fill == null
        ? HeroTopRow(leading: leading, trailing: trailing)
        : _ListHeadRow(leading: leading, fill: fill, trailing: trailing);
    row = ChipSizeScope(size: ChipSize.control, child: row);
    if (fold == null) return row;
    // The fold chevron sits small in the card's corner (half in the card
    // padding), so it doesn't read as another round action button.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        row,
        PositionedDirectional(top: -_foldTuck, end: -_foldTuck, child: fold),
      ],
    );
  }

  static const double _foldTuck = 10;
  static const double _foldReserve = AppHeroFoldButton.size - _foldTuck - 4;
}

/// The list head row: controls sized to the module tile, the fill stretched.
class _ListHeadRow extends StatelessWidget {
  const _ListHeadRow({
    required this.leading,
    required this.fill,
    required this.trailing,
  });

  final List<Widget> leading;
  final Widget fill;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = HeroMetrics.of(context).itemGap;
    final sizes = ControlSizes.of(
      context,
    ).copyWith(control: HeroModuleTile.size);
    return Theme(
      data: theme.copyWith(extensions: [...theme.extensions.values, sizes]),
      child: SizedBox(
        height: HeroModuleTile.size,
        child: Row(
          children: [
            for (final w in leading) ...[w, SizedBox(width: gap)],
            Expanded(child: fill),
            for (final t in trailing) ...[SizedBox(width: gap), t],
          ],
        ),
      ),
    );
  }
}
