import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../tokens/chip_size.dart';

/// What a status means — each kind has ONE chip tone app-wide, so a "paused"
/// recurring, a "near the limit" budget and a "waiting" occurrence read the
/// same everywhere (owner 2026-10-13: shared by recurring, budgets, goals).
enum StatusKind {
  /// Running normally.
  active(AppChipTone.success),

  /// Stopped for now; resumes.
  paused(AppChipTone.neutral),

  /// Put away (hidden from the default lists).
  archived(AppChipTone.neutral),

  /// Close to its end / limit.
  endingSoon(AppChipTone.warning),

  /// Needs a look (near a budget limit, a goal that stopped counting).
  warning(AppChipTone.warning),

  /// Past its limit.
  over(AppChipTone.danger),

  /// Finished / reached.
  done(AppChipTone.success),

  /// Called off.
  cancelled(AppChipTone.neutral),

  /// Still in the future.
  upcoming(AppChipTone.info),

  /// Waiting for the user (a draft to confirm).
  pending(AppChipTone.warning),

  /// Never produced (its date came, nothing was made).
  notCreated(AppChipTone.neutral);

  const StatusKind(this.tone);

  final AppChipTone tone;
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
    required AppChipTone this.tone,
    this.icon,
    this.size,
    this.onTap,
    super.key,
  }) : _kind = null;

  final String label;
  final AppChipTone? tone;
  final StatusKind? _kind;

  /// Replaces the dot.
  final IconData? icon;

  /// Null = the scope's size.
  final ChipSize? size;

  /// Non-null → tappable, with a trailing ▾ (it opens a menu / sheet).
  final VoidCallback? onTap;

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
  );
}
