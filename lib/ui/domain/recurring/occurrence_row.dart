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
import '../../tokens/chip_size.dart';

/// One thing a due occurrence can do.
@immutable
class OccurrenceAction {
  const OccurrenceAction({
    required this.label,
    required this.onTap,
    this.warning = false,
    this.destructive = false,
    this.submits = true,
  });

  final String label;
  final VoidCallback? onTap;

  /// Writes to the server, so it is off while offline (almost every one is).
  final bool submits;

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
      submits: primary.submits,
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
    // ⋯ as tall as the chip-size button beside it.
    return ChipSizeScope(
      size: ChipSize.chip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          const SizedBox(width: AppSpacing.xs),
          OptionMenuAnchor<int>(
            options: [
              for (final (i, a) in more.indexed)
                SheetOption(
                  value: i,
                  label: a.label,
                  enabled: a.onTap != null,
                  submits: a.submits,
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
      ),
    );
  }
}
