import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_icon.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import '../tokens/icon_size.dart';

/// The tag row under a hero: a tag icon, then the wrapping mini chips
/// ([tags], already-built `AppChip(size: ChipSize.mini)`s). Same in view and
/// edit mode. [onAdd] adds a dashed "+ tag" chip labelled [addLabel].
class TagRow extends StatelessWidget {
  const TagRow({required this.tags, this.onAdd, this.addLabel, super.key});

  final List<Widget> tags;
  final VoidCallback? onAdd;
  final String? addLabel;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: AppIcon(AppIcons.tag, size: AppIconSize.sm, color: muted),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              ...tags,
              if (onAdd != null)
                AppChip(
                  label: addLabel ?? '',
                  icon: AppIcons.add,
                  size: ChipSize.mini,
                  dashed: true,
                  onTap: onAdd,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
