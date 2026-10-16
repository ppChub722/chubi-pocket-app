import 'package:flutter/material.dart';

import '../atoms/app_icon.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/icon_size.dart';

/// 🔗 + a short line under fields that are shared with another record
/// (owner 2026-10-12: a bill pulled into an event from a personal
/// transaction keeps its money linked — "แก้แล้วเปลี่ยนทั้งสองฝั่ง"). Shown in
/// edit mode on both sides (the tx detail, the event bill), muted, never a
/// banner: it explains, it doesn't warn.
class LinkedFieldHint extends StatelessWidget {
  const LinkedFieldHint({required this.text, this.padding, super.key});

  final String text;

  /// Around the line (default: none).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PpForgeIcon(
          PpForgeIcons.link,
          size: PpForgeIconSize.sm,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: PpForgeSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
    return padding == null ? line : Padding(padding: padding!, child: line);
  }
}
