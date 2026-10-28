import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/app_icon_button.dart';
import '../atoms/app_spinner.dart';
import '../atoms/ui_config.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/tone.dart';

class AppMessageAction {
  const AppMessageAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

class AppMessage extends StatelessWidget {
  const AppMessage({
    required this.message,
    this.tone = Tone.info,
    this.actions = const [],
    this.onClose,
    this.floating = false,
    this.icon,
    this.busy = false,
    super.key,
  });

  final String message;
  final Tone tone;

  final IconData? icon;

  /// A spinner in place of the icon: something is in progress (connecting).
  final bool busy;
  final List<AppMessageAction> actions;

  final VoidCallback? onClose;

  final bool floating;

  static IconData iconOf(Tone tone) => switch (tone) {
    Tone.danger => AppIcons.error,
    Tone.warning => AppIcons.warning,
    Tone.success => AppIcons.success,
    _ => AppIcons.info,
  };

  @override
  Widget build(BuildContext context) {
    assert(actions.length <= 2, 'an AppMessage has at most two actions');
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = tone.color(context);
    // Opaque (a tint over the surface) so it reads over page content too.
    final fill = Color.alphaBlend(
      color.withValues(alpha: 0.10),
      scheme.surface,
    );
    final two = actions.length == 2;

    Widget button(AppMessageAction a) => AppButton(
      label: a.label,
      onPressed: a.onPressed,
      variant: AppButtonVariant.text,
      size: AppButtonSize.control,
      color: color,
    );

    // Icon, text, action and close share one centre line (owner
    // 2026-10-28: the text sat high next to the button).
    final body = Row(
      children: [
        if (busy)
          SizedBox.square(
            dimension: 20,
            child: Center(
              child: AppSpinner(size: AppSpinnerSize.small, color: color),
            ),
          )
        else
          Icon(icon ?? iconOf(tone), color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message, style: text.bodyMedium),
              if (two)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    children: [for (final a in actions) button(a)],
                  ),
                ),
            ],
          ),
        ),
        if (actions.length == 1) button(actions.first),
        if (onClose != null)
          AppIconButton.clear(
            dense: true,
            iconSize: 18,
            color: color,
            // Above the Navigator (the app shell's banner) there is no
            // Overlay for a tooltip.
            tooltip: Overlay.maybeOf(context) == null
                ? null
                : UiConfig.stringsOf(context).close,
            onPressed: onClose,
          ),
      ],
    );

    return Semantics(
      liveRegion: floating,
      child: Material(
        color: fill,
        elevation: floating ? 4 : 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            onClose == null && actions.length != 1
                ? AppSpacing.md
                : AppSpacing.xs,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: body,
        ),
      ),
    );
  }
}

void showAppMessage(
  BuildContext context,
  String message, {
  Tone tone = Tone.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) => showAppMessageOn(
  ScaffoldMessenger.of(context),
  message,
  tone: tone,
  actionLabel: actionLabel,
  onAction: onAction,
  duration: duration,
);

void showAppMessageOn(
  ScaffoldMessengerState messenger,
  String message, {
  Tone tone = Tone.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(AppSpacing.md),
        content: AppMessage(
          message: message,
          tone: tone,
          floating: true,
          actions: actionLabel != null && onAction != null
              ? [AppMessageAction(label: actionLabel, onPressed: onAction)]
              : const [],
        ),
      ),
    );
}
