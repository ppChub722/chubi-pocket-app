import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../tokens/chip_size.dart';

enum StatusKind {
  active(AppChipTone.success),

  paused(AppChipTone.neutral),

  archived(AppChipTone.neutral),

  endingSoon(AppChipTone.warning),

  warning(AppChipTone.warning),

  over(AppChipTone.danger),

  done(AppChipTone.success),

  cancelled(AppChipTone.neutral),

  upcoming(AppChipTone.info),

  pending(AppChipTone.warning),

  /// Never produced (its date came, nothing was made).
  notCreated(AppChipTone.neutral);

  const StatusKind(this.tone);

  final AppChipTone tone;
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
    required AppChipTone this.tone,
    this.icon,
    this.size,
    this.onTap,
    this.emphasis = false,
    super.key,
  }) : _kind = null;

  final String label;
  final AppChipTone? tone;
  final StatusKind? _kind;

  final IconData? icon;

  final ChipSize? size;

  final VoidCallback? onTap;

  /// A bold label: the chip is the headline status of its card (e.g. a list
  /// hero's summary in place of a caption).
  final bool emphasis;

  @override
  Widget build(BuildContext context) => AppChip(
    label: label,
    tone: tone ?? _kind!.tone,
    icon: icon,
    dot: icon == null,
    selected: true,
    size: size,
    trailing: onTap == null ? AppChipTrailing.none : AppChipTrailing.dropdown,
    onTap: onTap,
    bold: emphasis,
  );
}
