import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/app_icon_button.dart';
import '../atoms/app_spinner.dart';
import '../atoms/ui_config.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/tone.dart';
import 'snack_stack.dart';

class AppMessageAction {
  const AppMessageAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// The one body of every banner and snackbar.
///
/// Shapes (owner 2026-10-30):
/// - one line, when the text fits beside at most one action: icon, text,
///   action and close share one centre line;
/// - two lines, with two actions or one action the text cannot sit beside:
///   line 1 = icon + text + close, all on the first text line; line 2 = the
///   actions, right-aligned under the text.
///
/// The close ✕ is the only way to dismiss. An action is a verb that does
/// something (Undo, Retry, View, Update), never "Dismiss" / "Close".
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

  static const _iconSize = 20.0;
  static const _border = 1.0;

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

    Widget button(AppMessageAction a) => AppButton(
      label: a.label,
      onPressed: a.onPressed,
      variant: AppButtonVariant.text,
      size: AppButtonSize.control,
      color: color,
    );

    Widget leading() => busy
        ? SizedBox.square(
            dimension: _iconSize,
            child: Center(
              child: AppSpinner(size: AppSpinnerSize.small, color: color),
            ),
          )
        : Icon(icon ?? iconOf(tone), color: color, size: _iconSize);

    final closeBtn = onClose == null
        ? null
        : AppIconButton.clear(
            dense: true,
            iconSize: 18,
            color: color,
            // Above the Navigator (the app shell's banner) there is no
            // Overlay for a tooltip.
            tooltip: Overlay.maybeOf(context) == null
                ? null
                : UiConfig.stringsOf(context).close,
            onPressed: onClose,
          );

    return Semantics(
      liveRegion: floating,
      child: Material(
        color: fill,
        elevation: floating ? 4 : 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: LayoutBuilder(
          builder: (context, box) {
            final stacked = _stacked(context, box.maxWidth, text.bodyMedium!);
            final Widget body;
            if (!stacked) {
              // Icon, text, action and close share one centre line (owner
              // 2026-10-28: the text sat high next to the button).
              body = Row(
                children: [
                  leading(),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(message, style: text.bodyMedium)),
                  if (actions.length == 1) button(actions.first),
                  ?closeBtn,
                ],
              );
            } else {
              final lineH = _measure(context, 'A', text.bodyMedium!).height;
              final headH = closeBtn == null
                  ? lineH
                  : math.max(lineH, AppIconButton.targetDense);
              body = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: headH,
                        child: Center(child: leading()),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: (headH - lineH) / 2),
                          child: Text(message, style: text.bodyMedium),
                        ),
                      ),
                      if (closeBtn != null)
                        SizedBox(
                          height: headH,
                          child: Center(child: closeBtn),
                        ),
                    ],
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children: [for (final a in actions) button(a)],
                    ),
                  ),
                ],
              );
            }
            return Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                _rightPadding(stacked),
                AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: body,
            );
          },
        ),
      ),
    );
  }

  double _rightPadding(bool stacked) {
    final tight = stacked
        ? onClose != null
        : onClose != null || actions.length == 1;
    return tight ? AppSpacing.xs : AppSpacing.md;
  }

  Size _measure(
    BuildContext context,
    String s,
    TextStyle style, {
    double maxWidth = double.infinity,
    int? maxLines,
    void Function(bool exceeded)? onExceeded,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);
    final size = tp.size;
    onExceeded?.call(tp.didExceedMaxLines);
    tp.dispose();
    return size;
  }

  /// Two lines: two actions, or one action the text cannot sit beside on one
  /// line. Measured at the real width and text scale, not guessed by length.
  bool _stacked(BuildContext context, double maxWidth, TextStyle style) {
    if (actions.length >= 2) return true;
    if (actions.isEmpty || !maxWidth.isFinite) return false;
    final label = Theme.of(context).textTheme.labelLarge ?? style;
    // Over-estimates the control button (label + side padding) a little, so
    // a close call goes to two lines rather than squeezing the text.
    final actionW =
        _measure(context, actions.first.label, label).width + 2 * AppSpacing.md;
    final closeW = onClose == null ? 0.0 : AppIconButton.targetDense;
    final room =
        maxWidth -
        _border * 2 -
        AppSpacing.md -
        _rightPadding(false) -
        _iconSize -
        AppSpacing.sm -
        actionW -
        closeW;
    if (room <= 0) return true;
    var wraps = false;
    _measure(
      context,
      message,
      style,
      maxWidth: room,
      maxLines: 1,
      onExceeded: (e) => wraps = e,
    );
    return wraps;
  }
}

void showAppMessage(
  BuildContext context,
  String message, {
  Tone tone = Tone.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) => showAppMessageOn(
  ScaffoldMessenger.of(context),
  message,
  tone: tone,
  actionLabel: actionLabel,
  onAction: onAction,
  duration: duration,
);

/// A snack on the messenger's SnackStack (see SnackStack).
void showAppMessageOn(
  ScaffoldMessengerState messenger,
  String message, {
  Tone tone = Tone.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) => SnackStack.of(messenger).show(
  message,
  tone: tone,
  actionLabel: actionLabel,
  onAction: onAction,
  duration: duration,
);
