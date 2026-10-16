import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_chip.dart';
import '../../atoms/app_text.dart';
import '../../atoms/corner_badge.dart';
import '../people/user_avatar.dart';
import '../../molecules/confirm_dialog.dart';
import '../../molecules/list_row.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import '../../tokens/typography.dart';
import '../../icons/icon_code.dart';

/// The words of the reject confirmation of a [NotificationTileView].
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

/// One inbox row, presentational: sender avatar with a type badge, the
/// sentence, time (+ amount), a dot when unread. When [pending] it shows big
/// accept / reject buttons under the text; [rejectConfirm] non-null asks
/// before [onReject]. [acceptedLabel] non-null shows the "done" chip.
/// All words come from the caller.
class NotificationTileView extends StatelessWidget {
  const NotificationTileView({
    required this.actorName,
    required this.title,
    required this.timeText,
    required this.typeIcon,
    required this.acceptLabel,
    required this.rejectLabel,
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

  /// The sender avatar's diameter.
  static const double _avatar = 40;

  final String actorName;
  final IconCode? actorIconCode;
  final String title;
  final String timeText;
  final String? amountText;
  final IconData typeIcon;
  final bool unread;

  /// Still awaiting an answer: shows the accept / reject buttons.
  final bool pending;

  /// Non-null = answered: the success chip with this label.
  final String? acceptedLabel;
  final String acceptLabel;
  final String rejectLabel;
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
            leading: CornerBadge(
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
                PpForgeText(
                  title,
                  weight: unread ? FontWeight.w600 : FontWeight.w400,
                ),
                PpForgeText(
                  [timeText, ?amountText].join(' · '),
                  role: PpForgeTextRole.caption,
                ),
                if (acceptedLabel != null) ...[
                  const SizedBox(height: PpForgeSpacing.xs),
                  PpForgeChip(
                    label: acceptedLabel!,
                    icon: PpForgeIcons.success,
                    tone: PpForgeChipTone.success,
                    selected: true,
                    size: ChipSize.mini,
                  ),
                ],
              ],
            ),
            trailing: unread
                ? Icon(
                    Icons.circle,
                    size: PpForgeSpacing.sm,
                    color: scheme.primary,
                  )
                : null,
          ),
          if (pending)
            // The answer buttons sit under the text, past the avatar.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PpForgeSpacing.lg + _avatar + PpForgeSpacing.md,
                0,
                PpForgeSpacing.lg,
                PpForgeSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: PpForgeButton(
                      label: acceptLabel,
                      icon: PpForgeIcons.check,
                      submits: true,
                      onPressed: onAccept,
                    ),
                  ),
                  const SizedBox(width: PpForgeSpacing.sm),
                  Expanded(
                    child: PpForgeButton(
                      label: rejectLabel,
                      variant: PpForgeButtonVariant.outlined,
                      submits: true,
                      onPressed: () => _reject(context),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
