import 'package:flutter/material.dart';

import '../../atoms/icon_tile.dart';
import '../../molecules/app_list_row.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../icons/icon_code.dart';
import '../icons/icon_display.dart';
import '../icons/icon_type.dart';
import 'row_parts.dart';

/// What a money row is; picks its icon when it has no category. Savings take
/// the money colours: in = income, out = expense, a move = transfer.
enum TxListKind { expense, income, transfer, savingIn, savingOut, savingMove }

/// The one row of a money item, the same on every page that lists it
/// (รายการ, กระเป๋า, งบ, การ์ดผูกรายการ): the category's icon (else the
/// kind's) | [source mark] title + [status] / wallet | parts / tags | amount.
/// Pages pass data, never layout.
class TxListRow extends StatelessWidget {
  const TxListRow({
    required this.kind,
    required this.title,
    this.icon,
    this.amount,
    this.source,
    this.wallet,
    this.parts = const [],
    this.glyphs = const [],
    this.tags = const [],
    this.status,
    this.dimmed = false,
    this.checked,
    this.onCheck,
    this.checkTooltip,
    this.actions = const [],
    this.alert,
    this.onTap,
    super.key,
  });

  final TxListKind kind;
  final String title;

  /// The category's icon; null = the [kind]'s.
  final IconCode? icon;

  /// The value at the right (a MoneyText); left out while [actions] show.
  final Widget? amount;
  final TxSource? source;

  /// Leads line 2 ([walletRowChip]); null = no wallet, nothing shown.
  final ListRowChip? wallet;

  /// Line 2 after the wallet: the category, the date, "→ goal".
  final List<String> parts;
  final List<ListRowGlyph> glyphs;

  /// Line 3 ([tagSpan]s); none = no line.
  final List<InlineSpan> tags;

  /// Beside the title (อีก 3 วัน / เลยกำหนด).
  final ListRowChip? status;

  /// An expected / future one.
  final bool dimmed;
  final bool? checked;
  final VoidCallback? onCheck;
  final String? checkTooltip;

  /// A due occurrence: amount field + ✓ instead of the amount.
  final List<ListRowAction> actions;
  final ListRowAlert? alert;
  final VoidCallback? onTap;

  Widget _leading(BuildContext context) {
    final code = icon;
    if (code != null) {
      return IconDisplay(type: IconType.category, size: 36, iconCode: code);
    }
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    return IconTile(
      icon: switch (kind) {
        TxListKind.expense => AppIcons.expense,
        TxListKind.income => AppIcons.income,
        TxListKind.transfer || TxListKind.savingMove => AppIcons.transfer,
        TxListKind.savingIn => AppIcons.savingIn,
        TxListKind.savingOut => AppIcons.savingOut,
      },
      color: switch (kind) {
        TxListKind.expense || TxListKind.savingOut => palette.expense,
        TxListKind.income || TxListKind.savingIn => palette.income,
        TxListKind.transfer || TxListKind.savingMove => scheme.onSurfaceVariant,
      },
      size: 36,
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = this.amount;
    final source = this.source;
    return AppListRow(
      leading: _leading(context),
      title: title,
      titleMark: source == null ? null : txSourceMark(context, source),
      status: status,
      line2: ListRowLine(lead: wallet, parts: parts, glyphs: glyphs),
      line3: tags.isEmpty ? null : ListRowLine(spans: tags),
      trailing: actions.isEmpty && amount != null
          ? ListRowTrailing.value(amount)
          : null,
      actions: actions,
      alert: alert,
      dimmed: dimmed,
      checked: checked,
      onCheck: onCheck,
      checkTooltip: checkTooltip,
      onTap: onTap,
    );
  }
}
