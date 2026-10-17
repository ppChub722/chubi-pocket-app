import 'package:flutter/material.dart';

import '../../molecules/list_row.dart';
import '../icons/icon_code.dart';
import '../money/net_balance.dart';
import 'person_mark.dart';
import 'person_row.dart';

/// The debts people row (owner 2026-10-12) — on the people list and in the
/// person picker:
///
///   (ม)🔗  มาตาก                              ฿1,200.00
///          ค้าง 2 รายการ                         ติดคุณ
///
/// [PersonMark] (40, 🔗 slot kept so names line up) · name · [subtitle] ·
/// a [NetBalance] (row size) at the end. [selected] = the picker's highlight
/// tint (never a ✓). Same height as [PersonRow] / [ListRow].
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

  /// The subtitle in the warning colour ("ค้าง 45 วัน", over 30 days).
  final bool subtitleWarn;

  /// false: only the coloured amount at the end, no side caption.
  final bool showCaption;

  final String name;
  final PersonLevel level;

  /// The contact's (linked: the user's) icon; unused for a typed name.
  final IconCode? iconCode;

  /// One muted line under the name ("ค้าง 2 รายการ").
  final String? subtitle;

  /// The signed net: + = they owe me, − = I owe them (see [NetBalance]).
  final num net;
  final String owedToMeLabel;
  final String iOweLabel;
  final String settledLabel;
  final String currencySymbol;

  /// The picker's current pick: a primary tint over the row.
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
