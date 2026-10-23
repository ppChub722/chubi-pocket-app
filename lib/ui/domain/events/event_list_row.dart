import 'package:flutter/material.dart';

import '../../molecules/app_list_row.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/tone.dart';
import '../icons/icon_code.dart';
import '../icons/icon_display.dart';
import '../icons/icon_type.dart';
import '../money/money_text.dart';

class EventListRow extends StatelessWidget {
  const EventListRow({
    required this.name,
    this.iconCode,
    this.meta = const [],
    this.amount = 0,
    this.tone = MoneyTone.plain,
    this.caption,
    this.symbol,
    this.members,
    this.status,
    this.footer,
    this.dimmed = false,
    this.onTap,
    super.key,
  });

  static const double iconSize = 40;

  final String name;
  final IconCode? iconCode;

  /// Line 2, joined with " | ".
  final List<String> meta;
  final num amount;
  final MoneyTone tone;
  final String? caption;
  final String? symbol;

  /// Shown as a mini 👥 N chip after the name.
  final int? members;
  final ListRowChip? status;

  /// Full width under the row (the budget bar).
  final Widget? footer;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppListRow(
      leading: IconDisplay(
        type: IconType.project,
        size: iconSize,
        iconCode: iconCode,
      ),
      title: name,
      titleChips: [
        if (members != null) ListRowChip('$members', icon: AppIcons.project),
      ],
      status: status,
      line2: ListRowLine(parts: meta),
      trailing: ListRowTrailing.value(
        MoneyText(amount, tone: tone, symbol: symbol),
        caption: caption,
        captionTone: switch (tone) {
          MoneyTone.income => Tone.success,
          MoneyTone.expense => Tone.danger,
          _ => null,
        },
      ),
      footer: footer,
      dimmed: dimmed,
      onTap: onTap,
    );
  }
}
