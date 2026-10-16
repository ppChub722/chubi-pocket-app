import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../molecules/list_row.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import '../icons/icon_code.dart';
import 'person_mark.dart';

/// A member / contact row (owner 2026-10-12, debts rework) — a [ListRow]
/// led by the person's [PersonMark] (typed name 👤 / contact avatar / linked
/// avatar + 🔗), with the 🔗 slot kept on every row so the names line up:
///
///   (ม)🔗  มาตาก                          [เจ้าของ] trailing
///          caption
///
/// - [role]: a display chip (chip 28) before [trailing] ("เจ้าของ"); a quiet
///   outlined label unless [roleTone] gives it a colour.
/// - [pending]: faded (an invite not accepted yet).
/// - [onTap] null = not tappable.
///
/// Same height as [ListRow].
class PersonRow extends StatelessWidget {
  const PersonRow({
    required this.name,
    required this.level,
    this.iconCode,
    this.caption,
    this.role,
    this.roleTone,
    this.trailing,
    this.pending = false,
    this.onTap,
    super.key,
  });

  /// The leading [PersonMark]'s size — the list row's icon circle.
  static const double markSize = 40;

  /// The display name (one line).
  final String name;
  final PersonLevel level;

  /// The contact's (linked: the user's) icon; unused for a typed name.
  final IconCode? iconCode;

  /// One muted line under the name.
  final String? caption;

  /// A role chip ("เจ้าของ").
  final String? role;

  /// Colours [role] (worn selected); null = an outlined quiet label.
  final PpForgeChipTone? roleTone;

  /// The row's end (a menu button, an amount).
  final Widget? trailing;

  /// Fades the row.
  final bool pending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget? end = role == null && trailing == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (role != null)
                PpForgeChip(
                  label: role!,
                  size: ChipSize.chip,
                  tone: roleTone ?? PpForgeChipTone.neutral,
                  selected: roleTone != null,
                ),
              if (role != null && trailing != null)
                const SizedBox(width: PpForgeSpacing.sm),
              ?trailing,
            ],
          );
    return ListRow(
      leading: PersonMark(
        name: name,
        level: level,
        iconCode: iconCode,
        size: markSize,
        reserveLinkSlot: true,
      ),
      title: name,
      subtitle: caption,
      trailing: end,
      dimmed: pending,
      onTap: onTap,
    );
  }
}
