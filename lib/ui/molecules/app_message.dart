import 'package:flutter/material.dart';

import '../atoms/app_icon_button.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/tone.dart';

/// One action of an [PpForgeMessage] ("เลิกทำ", "ลองใหม่").
class PpForgeMessageAction {
  const PpForgeMessageAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// THE message body (owner 2026-10-12): one look for the snackbar
/// AND the banner — same tone colours, icon set, radius, padding and type;
/// only placement and lifetime differ. The rule stays: something that just
/// happened → a snackbar, something still true → a banner.
///
/// - **Banner** (`PpForgeMessage(...)`) — inline in a page / section, stays until
///   resolved or closed ([onClose] adds the ✕); 1–2 [actions].
/// - **Snackbar** ([showPpForgeMessage]) — the same body [floating] at the bottom
///   (a soft shadow), gone after a few seconds; at most one action.
///
/// Tones: [Tone.info] (also neutral / primary), success, warning, danger.
/// One action sits at the end of the text; two go under the text, right-aligned.
class PpForgeMessage extends StatelessWidget {
  const PpForgeMessage({
    required this.message,
    this.tone = Tone.info,
    this.actions = const [],
    this.onClose,
    this.floating = false,
    this.icon,
    super.key,
  });

  final String message;
  final Tone tone;

  /// Replaces the tone's icon (a 🔒 on a "locked" banner); the colour is
  /// still the tone's.
  final IconData? icon;
  final List<PpForgeMessageAction> actions;

  /// Banner: adds a ✕.
  final VoidCallback? onClose;

  /// The snackbar's placement: the same body with a soft shadow.
  final bool floating;

  static IconData iconOf(Tone tone) => switch (tone) {
    Tone.danger => PpForgeIcons.error,
    Tone.warning => PpForgeIcons.warning,
    Tone.success => PpForgeIcons.success,
    _ => PpForgeIcons.info,
  };

  @override
  Widget build(BuildContext context) {
    assert(actions.length <= 2, 'an PpForgeMessage has at most two actions');
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = tone.color(context);
    // Opaque (a tint over the surface) so it reads over page content too.
    final fill = Color.alphaBlend(
      color.withValues(alpha: 0.10),
      scheme.surface,
    );
    final two = actions.length == 2;

    Widget button(PpForgeMessageAction a) => TextButton(
      onPressed: a.onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: PpForgeSpacing.sm),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      child: Text(a.label),
    );

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon ?? iconOf(tone), color: color, size: 20),
        ),
        const SizedBox(width: PpForgeSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message, style: text.bodyMedium),
              if (two)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Wrap(
                    spacing: PpForgeSpacing.xs,
                    children: [for (final a in actions) button(a)],
                  ),
                ),
            ],
          ),
        ),
        if (actions.length == 1) button(actions.first),
        if (onClose != null)
          PpForgeIconButton.clear(
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
        borderRadius: BorderRadius.circular(PpForgeRadius.md),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            PpForgeSpacing.md,
            PpForgeSpacing.sm + 2,
            onClose == null && actions.length != 1
                ? PpForgeSpacing.md
                : PpForgeSpacing.xs,
            PpForgeSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PpForgeRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: body,
        ),
      ),
    );
  }
}

/// The snackbar: an [PpForgeMessage] floating at the bottom, replacing the
/// current one, gone after a few seconds, at most one action. (Inside a sheet
/// the same body shows as a toast on top of it — see [showPpForgeSnackBar].)
void showPpForgeMessage(
  BuildContext context,
  String message, {
  Tone tone = Tone.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) => showPpForgeMessageOn(
  ScaffoldMessenger.of(context),
  message,
  tone: tone,
  actionLabel: actionLabel,
  onAction: onAction,
  duration: duration,
);

/// [showPpForgeMessage] on a messenger captured up front — for calls after an
/// `await` / pop, when the original context may already be gone.
void showPpForgeMessageOn(
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
        margin: const EdgeInsets.all(PpForgeSpacing.md),
        content: PpForgeMessage(
          message: message,
          tone: tone,
          floating: true,
          actions: actionLabel != null && onAction != null
              ? [PpForgeMessageAction(label: actionLabel, onPressed: onAction)]
              : const [],
        ),
      ),
    );
}
