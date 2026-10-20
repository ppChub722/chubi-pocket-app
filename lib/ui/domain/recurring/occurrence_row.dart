import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_chip.dart';
import '../../atoms/app_icon_button.dart';
import '../../atoms/ui_config.dart';
import '../../molecules/option_menu.dart';
import '../../organisms/option_sheet.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';

/// One occurrence of a recurring item in a list: its date (or an icon), its
/// name on up to two lines, a tag and a muted line under it, the amount on the
/// right and an optional [action] (ใส่ยอด / ยืนยัน).
class OccurrenceRow extends StatelessWidget {
  const OccurrenceRow({
    required this.leading,
    required this.title,
    this.tag,
    this.sub,
    this.amount,
    this.amountWaiting,
    this.amountCaption,
    this.action,
    this.titleMaxLines = 2,
    this.dimmed = false,
    this.onTap,
    super.key,
  });

  /// A [DateTile] or an icon.
  final Widget leading;
  final String title;

  /// A small state / kind pill before [sub] ("รอยืนยัน", "อัตโนมัติ").
  final Widget? tag;
  final String? sub;

  /// MoneyText.
  final Widget? amount;

  /// In place of [amount] in the warning colour while it is unknown
  /// ("รอใส่ยอด").
  final String? amountWaiting;
  final String? amountCaption;
  final Widget? action;
  final int titleMaxLines;

  /// Past occurrences in a month's list.
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final small = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final hasMeta = tag != null || (sub != null && sub!.isNotEmpty);
    final money =
        amount ??
        (amountWaiting == null
            ? null
            : Text(
                amountWaiting!,
                style: TextStyle(
                  color: Theme.of(context).extension<AppColors>()!.warning,
                ),
              ));
    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge,
                  ),
                  if (hasMeta)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: Row(
                        children: [
                          if (tag != null) ...[
                            tag!,
                            if (sub != null && sub!.isNotEmpty)
                              const SizedBox(width: AppSpacing.xs),
                          ],
                          if (sub != null && sub!.isNotEmpty)
                            Flexible(
                              child: Text(
                                sub!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: small,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (money != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    child: money,
                  ),
                  if (amountCaption != null)
                    Text(amountCaption!, maxLines: 1, style: small),
                ],
              ),
            ],
            if (action != null) ...[
              const SizedBox(width: AppSpacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
    return dimmed ? Opacity(opacity: 0.55, child: row) : row;
  }
}

/// One thing a due occurrence can do.
@immutable
class OccurrenceAction {
  const OccurrenceAction({
    required this.label,
    required this.onTap,
    this.warning = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onTap;

  /// The button in the warning colour ("ใส่ยอด" when the amount is unknown).
  final bool warning;
  final bool destructive;
}

/// A due occurrence's actions: the main one as a button, the rest behind ⋯
/// (จ่ายแล้ว / ข้าม / ผูกกับรายการที่มีอยู่).
class OccurrenceActions extends StatelessWidget {
  const OccurrenceActions({
    required this.primary,
    this.more = const [],
    this.moreTooltip,
    super.key,
  });

  final OccurrenceAction primary;
  final List<OccurrenceAction> more;

  /// The ⋯ button's label; defaults to [UiStrings.more].
  final String? moreTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget button = AppButton(
      label: primary.label,
      onPressed: primary.onTap,
      size: AppButtonSize.chip,
      variant: primary.destructive
          ? AppButtonVariant.destructive
          : AppButtonVariant.primary,
    );
    if (primary.warning && !primary.destructive) {
      final warning = theme.extension<AppColors>()!.warning;
      button = Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: warning,
            onPrimary: AppChip.readableOn(warning, Colors.white),
          ),
        ),
        child: button,
      );
    }
    if (more.isEmpty) return button;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        OptionMenuAnchor<int>(
          options: [
            for (final (i, a) in more.indexed)
              SheetOption(
                value: i,
                label: a.label,
                enabled: a.onTap != null,
                destructive: a.destructive,
              ),
          ],
          onSelected: (i) => more[i].onTap?.call(),
          builder: (context, toggle) => AppIconButton(
            icon: AppIcons.more,
            tooltip: moreTooltip ?? UiConfig.stringsOf(context).more,
            onPressed: toggle,
          ),
        ),
      ],
    );
  }
}
