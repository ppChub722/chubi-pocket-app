import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_icon.dart';
import '../tokens/pp_forge_icons.dart';
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
          child: PpForgeIcon(PpForgeIcons.tag, size: PpForgeIconSize.sm, color: muted),
        ),
        const SizedBox(width: PpForgeSpacing.sm),
        Expanded(
          child: Wrap(
            spacing: PpForgeSpacing.xs,
            runSpacing: PpForgeSpacing.xs,
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
                PpForgeChip(
                  label: addLabel ?? '',
                  icon: PpForgeIcons.add,
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
