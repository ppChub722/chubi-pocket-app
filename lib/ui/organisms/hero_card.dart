import 'package:flutter/material.dart';

import '../atoms/ui_config.dart';
import '../molecules/card_action_button.dart';
import '../molecules/hero_shell.dart';
import '../molecules/hero_style.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import 'hero/app_hero_card.dart';
import 'hero/hero_identity.dart';
import 'hero/hero_tiles.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.style,
    this.editing = false,
    this.chips = const [],
    this.links = const [],
    this.search,
    this.onEdit,
    this.icon,
    this.name,
    this.fact,
    this.description,
    this.number,
    this.amountField,
    this.bar,
    this.tiles = const [],
    this.alert,
    this.embedded,
    this.settingsLine,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    super.key,
  });

  final HeroStyle style;

  final bool editing;

  final List<Widget> chips;

  final List<Widget> links;

  final Widget? search;

  final VoidCallback? onEdit;

  final Widget? icon;

  final Widget? name;
  final Widget? fact;

  final Widget? description;

  final Widget? number;

  final Widget? amountField;

  final Widget? bar;

  final List<Widget> tiles;

  final Widget? alert;

  final Widget? embedded;

  final Widget? settingsLine;

  /// The detail pages' 16 inset, until they move to [AppHeroCard] directly.
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final edit = !editing && onEdit != null
        ? CardActionButton(
            icon: AppIcons.edit,
            tooltip: UiConfig.stringsOf(context).edit,
            onTap: onEdit,
          )
        : null;
    final actions = editing
        ? const <Widget>[]
        : <Widget>[...links, ?search, ?edit];
    final topRow = chips.isNotEmpty || actions.isNotEmpty
        ? HeroTopRow(leading: chips, trailing: actions)
        : null;
    final hasText = name != null || fact != null || description != null;
    final identity = icon == null && !hasText
        ? null
        : HeroIdentity(
            icon: icon,
            name: name,
            fact: fact,
            description: description,
          );
    return AppHeroCard(
      style: style,
      mode: editing ? HeroCardMode.edit : HeroCardMode.view,
      onTap: onTap,
      padding: padding,
      content: [
        topRow,
        identity,
        if (editing) amountField else number,
        if (!editing) bar,
        if (!editing && tiles.isNotEmpty) HeroTiles(children: tiles),
        if (!editing) alert,
        if (!editing) embedded,
        if (!editing) settingsLine,
      ],
    );
  }
}
