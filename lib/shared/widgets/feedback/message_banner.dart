import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../chips/tone.dart';

/// Inline message above a form or section — "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง",
/// "ไม่มีการเชื่อมต่อ". Tinted by [tone]; [onClose] adds a ✕.
/// Snackbars are for results of an action; this is for state the user
/// needs to read before trying again.
class MessageBanner extends StatelessWidget {
  const MessageBanner({
    required this.message,
    this.tone = Tone.danger,
    this.onClose,
    super.key,
  });

  final String message;
  final Tone tone;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final color = tone.color(context);
    final icon = switch (tone) {
      Tone.danger => AppIcons.error,
      Tone.warning => AppIcons.warning,
      Tone.success => AppIcons.success,
      _ => AppIcons.info,
    };
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        onClose == null ? AppSpacing.md : AppSpacing.xs,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (onClose != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(AppIcons.clear, color: color, size: 18),
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}
