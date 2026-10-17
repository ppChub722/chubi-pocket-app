import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../molecules/list_row.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import '../icons/icon_code.dart';
import 'person_mark.dart';

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

  static const double markSize = 40;

  final String name;
  final PersonLevel level;

  final IconCode? iconCode;

  final String? caption;

  final String? role;

  final AppChipTone? roleTone;

  final Widget? trailing;

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
                AppChip(
                  label: role!,
                  size: ChipSize.chip,
                  tone: roleTone ?? AppChipTone.neutral,
                  selected: roleTone != null,
                ),
              if (role != null && trailing != null)
                const SizedBox(width: AppSpacing.sm),
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
