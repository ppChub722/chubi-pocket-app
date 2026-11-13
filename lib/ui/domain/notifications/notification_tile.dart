import 'package:flutter/material.dart';

import 'package:pp_forge_core/ui.dart';
import '../tokens/app_icons.dart';
import '../people/avatar_data.dart';
import 'type_actor_mark.dart';

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
    required this.actorAvatar,
    this.rejectLabel,
    this.system = false,
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

  /// The actor's `.avatar` (a name-only actor: built from the name).
  final AvatarData actorAvatar;
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
    final done = acceptedLabel != null;
    final mark = done ? scheme.onSurfaceVariant : scheme.primary;
    return ColoredBox(
      color: scheme.primary.withValues(alpha: unread ? 0.06 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handled (owner 2026-11-04): the whole row greys out, its type
          // icon grey too, see-through with the rest.
          Opacity(
            opacity: done ? 0.55 : 1,
            child: PpForgeListRow(
              onTap: onTap,
              leading: system
                  ? IconTile(icon: typeIcon, color: mark, size: _avatar)
                  : TypeActorMark(
                      icon: typeIcon,
                      color: mark,
                      size: _avatar,
                      actor: actorAvatar,
                    ),
              title: title,
              titleStrong: unread,
              titleMaxLines: 3,
              line2: ListRowLine(
                lead: acceptedLabel == null
                    ? null
                    : ListRowChip(
                        acceptedLabel!,
                        icon: AppIcons.success,
                        tone: Tone.neutral,
                        selected: true,
                      ),
                parts: [timeText, ?amountText],
              ),
              // A handled notice opens its page: › says so (owner 2026-11-04,
              // in place of "แตะเพื่อเปิด").
              trailing: unread || acceptedLabel != null
                  ? ListRowTrailing.value(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (unread)
                            Icon(
                              Icons.circle,
                              size: PpForgeSpacing.sm,
                              color: scheme.primary,
                            ),
                          if (acceptedLabel != null)
                            Icon(
                              AppIcons.chevronRight,
                              color: scheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          if (pending)
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
                      icon: AppIcons.check,
                      submits: true,
                      onPressed: onAccept,
                    ),
                  ),
                  if (rejectLabel != null) ...[
                    const SizedBox(width: PpForgeSpacing.sm),
                    Expanded(
                      child: PpForgeButton(
                        label: rejectLabel!,
                        variant: PpForgeButtonVariant.outlined,
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
