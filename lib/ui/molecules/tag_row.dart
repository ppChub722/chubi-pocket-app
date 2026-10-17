import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_icon.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import '../tokens/icon_size.dart';

class TagRow extends StatelessWidget {
  const TagRow({
    required this.tags,
    this.onAdd,
    this.addLabel,
    this.label,
    super.key,
  });

  final String? label;
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
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '$label:',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: muted),
                  ),
                ),
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
