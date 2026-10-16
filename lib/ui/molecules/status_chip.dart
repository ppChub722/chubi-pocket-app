import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../tokens/chip_size.dart';

/// What a status means — each kind has ONE chip tone app-wide, so a "paused"
/// recurring, a "near the limit" budget and a "waiting" occurrence read the
/// same everywhere (owner 2026-10-13: shared by recurring, budgets, goals).
enum StatusKind {
  /// Running normally.
  active(PpForgeChipTone.success),

  /// Stopped for now; resumes.
  paused(PpForgeChipTone.neutral),

  /// Put away (hidden from the default lists).
  archived(PpForgeChipTone.neutral),

  /// Close to its end / limit.
  endingSoon(PpForgeChipTone.warning),

  /// Needs a look (near a budget limit, a goal that stopped counting).
  warning(PpForgeChipTone.warning),

  /// Past its limit.
  over(PpForgeChipTone.danger),

  /// Finished / reached.
  done(PpForgeChipTone.success),

  /// Called off.
  cancelled(PpForgeChipTone.neutral),

  /// Still in the future.
  upcoming(PpForgeChipTone.info),

  /// Waiting for the user (a draft to confirm).
  pending(PpForgeChipTone.warning),

  /// Never produced (its date came, nothing was made).
  notCreated(PpForgeChipTone.neutral);

  const StatusKind(this.tone);

  final PpForgeChipTone tone;
}

/// A status as a chip (owner 2026-10-11: status badges are chips): the
/// [kind]'s tone, selected (filled), with a leading dot or [icon]. The size
/// follows the [ChipSizeScope] (a hero's top row = control, a list row =
/// pass [size] mini). Display only — unless [onTap]: then a ▾ says it
/// opens a menu (a recurring's พัก / ทำต่อ).
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required StatusKind kind,
    this.icon,
    this.size,
    this.onTap,
    super.key,
  }) : tone = null,
       _kind = kind;

  /// A raw chip tone when no [StatusKind] fits.
  const StatusChip.tone({
    required this.label,
    required PpForgeChipTone this.tone,
    this.icon,
    this.size,
    this.onTap,
    super.key,
  }) : _kind = null;

  final String label;
  final PpForgeChipTone? tone;
  final StatusKind? _kind;

  /// Replaces the dot.
  final IconData? icon;

  /// Null = the scope's size.
  final ChipSize? size;

  /// Non-null → tappable, with a trailing ▾ (it opens a menu / sheet).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => PpForgeChip(
    label: label,
    tone: tone ?? _kind!.tone,
    icon: icon,
    dot: icon == null,
    selected: true,
    size: size,
    trailing: onTap == null
        ? PpForgeChipTrailing.none
        : PpForgeChipTrailing.dropdown,
    onTap: onTap,
  );
}
