import 'package:flutter/material.dart';

import 'package:pp_forge_core/ui.dart';
import '../tokens/app_icons.dart';

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

  /// The ⋯ button's label; defaults to [PpForgeStrings.more].
  final String? moreTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget button = PpForgeButton(
      label: primary.label,
      onPressed: primary.onTap,
      submits: primary.submits,
      size: PpForgeButtonSize.chip,
      variant: primary.destructive
          ? PpForgeButtonVariant.destructive
          : PpForgeButtonVariant.primary,
    );
    if (primary.warning && !primary.destructive) {
      final warning = theme.extension<PpForgeColors>()!.warning;
      button = Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: warning,
            onPrimary: PpForgeChip.readableOn(warning, Colors.white),
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
          const SizedBox(width: PpForgeSpacing.xs),
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
            builder: (context, toggle) => PpForgeIconButton(
              icon: AppIcons.more,
              tooltip: moreTooltip ?? PpForgeConfig.stringsOf(context).more,
              onPressed: toggle,
            ),
          ),
        ],
      ),
    );
  }
}
