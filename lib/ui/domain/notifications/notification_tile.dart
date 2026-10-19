import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_chip.dart';
import '../../atoms/app_text.dart';
import '../../atoms/corner_badge.dart';
import '../../atoms/icon_tile.dart';
import '../../atoms/user_avatar.dart';
import '../../molecules/confirm_dialog.dart';
import '../../molecules/list_row.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import '../../tokens/typography.dart';
import '../icons/icon_code.dart';

class NotificationRejectConfirm {
  const NotificationRejectConfirm({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;
}

class NotificationTileView extends StatelessWidget {
  const NotificationTileView({
    required this.actorName,
    required this.title,
    required this.timeText,
    required this.typeIcon,
    required this.acceptLabel,
    this.rejectLabel,
    this.system = false,
    this.actorIconCode,
    this.amountText,
    this.unread = false,
    this.pending = false,
    this.acceptedLabel,
    this.rejectConfirm,
    this.onTap,
    this.onAccept,
    this.onReject,
    super.key,
  });

  static const double _avatar = 40;

  final String actorName;
  final IconCode? actorIconCode;
  final String title;
  final String timeText;
  final String? amountText;
  final IconData typeIcon;
  final bool unread;

  final bool pending;

  final String? acceptedLabel;
  final String acceptLabel;

  final String? rejectLabel;

  final bool system;
  final NotificationRejectConfirm? rejectConfirm;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  Future<void> _reject(BuildContext context) async {
    final c = rejectConfirm;
    if (c == null) return onReject?.call();
    final ok = await showConfirmDialog(
      context,
      title: c.title,
      message: c.message,
      confirmLabel: c.confirmLabel,
      destructive: true,
    );
    if (ok) onReject?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.primary.withValues(alpha: unread ? 0.06 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListRow(
            onTap: onTap,
            leading: system
                ? IconTile(icon: typeIcon, color: scheme.primary, size: _avatar)
                : CornerBadge(
                    size: _avatar,
                    icon: typeIcon,
                    child: UserAvatar(
                      displayName: actorName,
                      iconCode: actorIconCode,
                      size: _avatar,
                    ),
                  ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  title,
                  weight: unread ? FontWeight.w600 : FontWeight.w400,
                ),
                AppText(
                  [timeText, ?amountText].join(' | '),
                  role: AppTextRole.caption,
                ),
                if (acceptedLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppChip(
                    label: acceptedLabel!,
                    icon: AppIcons.success,
                    tone: AppChipTone.success,
                    selected: true,
                    size: ChipSize.mini,
                  ),
                ],
              ],
            ),
            trailing: unread
                ? Icon(Icons.circle, size: AppSpacing.sm, color: scheme.primary)
                : null,
          ),
          if (pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg + _avatar + AppSpacing.md,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: acceptLabel,
                      icon: AppIcons.check,
                      submits: true,
                      onPressed: onAccept,
                    ),
                  ),
                  if (rejectLabel != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: rejectLabel!,
                        variant: AppButtonVariant.outlined,
                        submits: true,
                        onPressed: () => _reject(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
