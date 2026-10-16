import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;

import '../../atoms/app_chip.dart';
import '../../atoms/icon_tile.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import 'money_text.dart';

/// Which way a [LedgerRow]'s money went, seen from me.
enum LedgerDirection {
  /// I paid out to / for them (lend, repay what I owe, a split I paid): ↗,
  /// the expense colour.
  paid,

  /// It came to me from them (borrow, they repay me, a split they paid): ↙,
  /// the income colour.
  received,
}

/// One debt ledger entry (owner 2026-10-12, debts rework) — the person
/// page's timeline / payment-history row. Same geometry as the transaction
/// row (`TxRow`: height, paddings, text slots), so ledger and tx lists look
/// alike:
///
///   (↗)  title                                        ฿500.00
///        12 ต.ค. [wallet] [จ่ายแล้ว] · source
///
/// - [direction] picks the leading arrow and the colour (paid = expense,
///   received = income); [amount] is always shown positive.
/// - line 2: [dateLabel] · the wallet as a mini chip ([walletLabel] +
///   [walletIcon]) · [paidLabel] as a mini chip · [sourceLabel] (the split
///   transaction / event it came from). The mini chips ride on the text line
///   without making it taller.
///
/// Never shows a category. Strings come from the caller (the title is
/// `description ?? a fallback` there).
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    required this.direction,
    required this.amount,
    required this.title,
    required this.dateLabel,
    this.walletLabel,
    this.walletIcon,
    this.paidLabel,
    this.sourceLabel,
    this.currencySymbol = '฿',
    this.onTap,
    super.key,
  });

  final LedgerDirection direction;

  /// Shown as its magnitude; [direction] carries the way.
  final num amount;
  final String title;
  final String dateLabel;

  /// The wallet that moved the money — null = a pure ledger entry, no chip.
  final String? walletLabel;

  /// The wallet's icon, inside the chip.
  final Widget? walletIcon;

  /// The "paid" label chip ("จ่ายแล้ว") — null = not labelled.
  final String? paidLabel;

  /// Where the entry came from (a split's transaction / event title).
  final String? sourceLabel;
  final String currencySymbol;
  final VoidCallback? onTap;

  /// The leading tile's size — the transaction row's.
  static const double leadingSize = 36;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    final paid = direction == LedgerDirection.paid;
    final color = paid ? palette.expense : palette.income;
    final small = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    // ↗ / ↙ from the one forward arrow; the round tile doesn't show the turn.
    final leading = Transform.rotate(
      angle: paid ? -math.pi / 4 : math.pi * 3 / 4,
      child: IconTile(
        icon: PpForgeIcons.arrowForward,
        color: color,
        size: leadingSize,
      ),
    );

    Widget mini(String label, {Widget? icon, PpForgeChipTone? tone}) =>
        Flexible(
          child: _OnLine(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: PpForgeChip(
                label: label,
                leading: icon,
                tone: tone,
                selected: tone != null,
                size: ChipSize.mini,
              ),
            ),
          ),
        );

    // Three groups share a tight line (date · chips · source), each shrinking
    // (ellipsis) only when the line is full.
    final hasChips = walletLabel != null || paidLabel != null;
    final line2 = Row(
      children: [
        Flexible(
          child: Text(
            dateLabel,
            style: small,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasChips) ...[
          const SizedBox(width: PpForgeSpacing.xs),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (walletLabel != null) mini(walletLabel!, icon: walletIcon),
                if (walletLabel != null && paidLabel != null)
                  const SizedBox(width: PpForgeSpacing.xs),
                if (paidLabel != null)
                  mini(paidLabel!, tone: PpForgeChipTone.success),
              ],
            ),
          ),
        ],
        if (sourceLabel != null && sourceLabel!.isNotEmpty)
          Flexible(
            child: Text(
              ' · ${sourceLabel!}',
              style: small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PpForgeSpacing.lg,
          vertical: PpForgeSpacing.sm,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: PpForgeSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge,
                  ),
                  Padding(padding: const EdgeInsets.only(top: 2), child: line2),
                ],
              ),
            ),
            const SizedBox(width: PpForgeSpacing.sm),
            MoneyText(
              amount.abs(),
              symbol: currencySymbol,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Puts a mini chip (20) on a text line without making the line taller: it
/// takes no height in the layout and is painted centred on the line (a hair
/// into the gap above and the padding below), so the row keeps the
/// transaction row's height.
class _OnLine extends StatelessWidget {
  const _OnLine({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 0,
    child: OverflowBox(
      minHeight: 0,
      maxHeight: double.infinity,
      fit: OverflowBoxFit.deferToChild,
      child: child,
    ),
  );
}
