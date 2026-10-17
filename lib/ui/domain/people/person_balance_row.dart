import 'package:flutter/material.dart';

import '../../molecules/list_row.dart';
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
    this.onTap,
    super.key,
  });

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
          trailing: NetBalance(
            showCaption: showCaption,
            amount: net,
            owedToMeLabel: owedToMeLabel,
            iOweLabel: iOweLabel,
            settledLabel: settledLabel,
            currencySymbol: currencySymbol,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
