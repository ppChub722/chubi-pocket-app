import 'package:flutter/material.dart';

import '../../molecules/list_row.dart';
import '../../tokens/tone.dart';
import '../icons/icon_code.dart';
import '../money/net_balance.dart';
import 'person_mark.dart';
import 'person_row.dart';

class PersonBalanceRow extends StatelessWidget {
  const PersonBalanceRow({
    required this.name,
    required this.level,
    required this.net,
    required this.owedToMeLabel,
    required this.iOweLabel,
    required this.settledLabel,
    this.iconCode,
    this.subtitle,
    this.currencySymbol = '฿',
    this.selected = false,
    this.subtitleWarn = false,
    this.showCaption = true,
    this.age,
    this.ageWarn = false,
    this.onTap,
    super.key,
  });

  /// Under the amount (mock DebtsList): "ค้าง 50 วัน"; [ageWarn] (past 30
  /// days) paints it the warning colour, bold.
  final String? age;
  final bool ageWarn;

  final bool subtitleWarn;

  final bool showCaption;

  final String name;
  final PersonLevel level;

  final IconCode? iconCode;

  final String? subtitle;

  final num net;
  final String owedToMeLabel;
  final String iOweLabel;
  final String settledLabel;
  final String currencySymbol;

  final bool selected;
  final VoidCallback? onTap;

  Widget _trailing(BuildContext context) {
    final balance = NetBalance(
      showCaption: showCaption,
      amount: net,
      owedToMeLabel: owedToMeLabel,
      iOweLabel: iOweLabel,
      settledLabel: settledLabel,
      currencySymbol: currencySymbol,
    );
    final age = this.age;
    if (age == null) return balance;
    final text = Theme.of(context).textTheme.labelSmall;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        balance,
        Text(
          age,
          key: const ValueKey('personAge'),
          style: text?.copyWith(
            color: ageWarn
                ? Tone.warning.color(context)
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: ageWarn ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      child: Semantics(
        selected: selected,
        child: ListRow(
          leading: PersonMark(
            name: name,
            level: level,
            iconCode: iconCode,
            size: PersonRow.markSize,
            reserveLinkSlot: true,
          ),
          title: name,
          subtitle: subtitle,
          subtitleWarn: subtitleWarn,
          trailing: _trailing(context),
          onTap: onTap,
        ),
      ),
    );
  }
}
