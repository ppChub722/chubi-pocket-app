import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../tokens/chip_size.dart';

enum StatusKind {
  active(PpForgeChipTone.success),

  paused(PpForgeChipTone.neutral),

  archived(PpForgeChipTone.neutral),

  endingSoon(PpForgeChipTone.warning),

  warning(PpForgeChipTone.warning),

  over(PpForgeChipTone.danger),

  done(PpForgeChipTone.success),

  cancelled(PpForgeChipTone.neutral),

  upcoming(PpForgeChipTone.info),

  pending(PpForgeChipTone.warning),

  /// Never produced (its date came, nothing was made).
  notCreated(PpForgeChipTone.neutral);

  const StatusKind(this.tone);

  final PpForgeChipTone tone;
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required StatusKind kind,
    this.icon,
    this.size,
    this.onTap,
    this.emphasis = false,
    super.key,
  }) : tone = null,
       _kind = kind;

  const StatusChip.tone({
    required this.label,
    required PpForgeChipTone this.tone,
    this.icon,
    this.size,
    this.onTap,
    this.emphasis = false,
    super.key,
  }) : _kind = null;

  final String label;
  final PpForgeChipTone? tone;
  final StatusKind? _kind;

  final IconData? icon;

  final ChipSize? size;

  final VoidCallback? onTap;

  /// A bold label: the chip is the headline status of its card (e.g. a list
  /// hero's summary in place of a caption).
  final bool emphasis;

  @override
  Widget build(BuildContext context) => PpForgeChip(
    label: label,
    tone: tone ?? _kind!.tone,
    icon: icon,
    dot: icon == null,
    selected: true,
    size: size,
    trailing: onTap == null ? PpForgeChipTrailing.none : PpForgeChipTrailing.dropdown,
    onTap: onTap,
    bold: emphasis,
  );
}
