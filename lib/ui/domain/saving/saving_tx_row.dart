import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../atoms/icon_tile.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import '../money/money_text.dart';

/// The kind of a saving tx (goals v2): its own record, never a real tx.
enum SavingTxKind {
  deposit,

  withdraw,

  allocate;

  IconData get icon => switch (this) {
    SavingTxKind.deposit => AppIcons.savingDeposit,
    SavingTxKind.withdraw => AppIcons.savingWithdraw,
    SavingTxKind.allocate => AppIcons.savingAllocate,
  };
}

class SavingTxRow extends StatelessWidget {
  const SavingTxRow({
    required this.kind,
    required this.title,
    required this.amount,
    this.walletLabel,
    this.walletIcon,
    this.date,
    this.from,
    this.to,
    this.source,
    this.draft = false,
    this.draftChips = const [],
    this.select,
    this.accent,
    this.dimmed = false,
    this.onTap,
    super.key,
  });

  final SavingTxKind kind;
  final String title;

  final num amount;
  final String? walletLabel;
  final Widget? walletIcon;

  final String? date;

  final String? from;

  final String? to;

  final Widget? source;
  final bool draft;

  final List<Widget> draftChips;
  final Widget? select;

  final Color? accent;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final small = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final out = kind == SavingTxKind.withdraw;
    final tint = out ? scheme.onSurfaceVariant : (accent ?? palette.income);

    Widget wallet() => walletLabel == null
        ? const SizedBox.shrink()
        : ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: AppChip(
              label: walletLabel!,
              leading: walletIcon,
              size: ChipSize.mini,
            ),
          );
    Widget bucket(String? s) => s == null
        ? const SizedBox.shrink()
        : Flexible(
            child: Text(
              s,
              style: small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
    Widget arrow() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text('→', style: small),
    );
    const gap = SizedBox(width: AppSpacing.xs);
    // Line 2 keeps the height of a TxRow text line: a mini chip (20) in it
    // overflows evenly instead of growing the row.
    final lineHeight = (TextPainter(
      text: TextSpan(text: 'Ag', style: small),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout()).height;

    final line2 = <Widget>[
      if (date != null && !draft) ...[Text(date!, style: small), gap],
      if (draft) ...[
        for (final c in draftChips) ...[Flexible(child: c), gap],
        bucket(to),
      ] else
        ...switch (kind) {
          SavingTxKind.deposit => [
            Flexible(child: wallet()),
            arrow(),
            bucket(to),
          ],
          SavingTxKind.withdraw => [
            bucket(from),
            arrow(),
            Flexible(child: wallet()),
          ],
          SavingTxKind.allocate => [
            Flexible(child: wallet()),
            gap,
            bucket(from),
            arrow(),
            bucket(to),
          ],
        },
    ];

    final Widget row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (select != null) ...[
              select!,
              const SizedBox(width: AppSpacing.sm),
            ],
            draft
                ? DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: CircleBorder(
                        side: BorderSide(color: tint, width: 1.5),
                      ),
                    ),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(kind.icon, size: 18, color: tint),
                    ),
                  )
                : IconTile(icon: kind.icon, color: tint),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge,
                        ),
                      ),
                      if (draft && walletLabel != null) ...[gap, wallet()],
                      if (source != null) ...[gap, source!],
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SizedBox(
                      height: lineHeight,
                      child: OverflowBox(
                        maxHeight: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: Row(children: line2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  out ? '−' : '+',
                  style: textTheme.titleSmall?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                MoneyText(
                  amount.abs(),
                  style: textTheme.titleSmall?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (draft) return Opacity(opacity: 0.8, child: row);
    return dimmed ? Opacity(opacity: 0.55, child: row) : row;
  }
}
