import 'package:flutter/material.dart';

import '../atoms/app_icon_button.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/tone.dart';

/// One action of an [AppMessage] ("เลิกทำ", "ลองใหม่").
class AppMessageAction {
  const AppMessageAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// THE message body (PROPOSAL, owner 2026-10-12): one look for the snackbar
/// AND the banner — same tone colours, icon set, radius, padding and type;
/// only placement and lifetime differ. The rule stays: something that just
/// happened → a snackbar, something still true → a banner.
///
/// - **Banner** (`AppMessage(...)`) — inline in a page / section, stays until
///   resolved or closed ([onClose] adds the ✕); 1–2 [actions].
/// - **Snackbar** ([showAppMessage]) — the same body [floating] at the bottom
///   (a soft shadow), gone after a few seconds; at most one action.
///
/// Tones: [Tone.info] (also neutral / primary), success, warning, danger.
/// One action sits at the end of the text; two go under the text, right-aligned.
class AppMessage extends StatelessWidget {
  const AppMessage({
    required this.message,
    this.tone = Tone.info,
    this.actions = const [],
    this.onClose,
    this.floating = false,
    super.key,
  });

  final String message;
  final Tone tone;
  final List<AppMessageAction> actions;

  /// Banner: adds a ✕.
  final VoidCallback? onClose;

  /// The snackbar's placement: the same body with a soft shadow.
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

    Widget button(AppMessageAction a) => TextButton(
      onPressed: a.onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      child: Text(a.label),
    );

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(iconOf(tone), color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
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
            AppSpacing.sm + 2,
            onClose == null && actions.length != 1
                ? AppSpacing.md
                : AppSpacing.xs,
            AppSpacing.sm + 2,
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

/// PROPOSED snackbar: an [AppMessage] floating at the bottom, replacing the
/// current one, gone after a few seconds, at most one action. (Inside a sheet
/// the existing top toast still applies until the app adopts this.)
void showAppMessage(
  BuildContext context,
  String message, {
  Tone tone = Tone.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
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
