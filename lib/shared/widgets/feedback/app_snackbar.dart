import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../chips/tone.dart';

/// Shows a floating snackbar, replacing any current one (so rapid actions
/// don't queue a backlog). [tone] adds a leading status icon.
///
/// From inside a sheet or a dialog ([PopupRoute] — every [showAppSheet] /
/// quick create / picker) a snackbar would land on the page's Scaffold,
/// UNDER the sheet and its barrier — invisible (QA run-3 S1). There the
/// message shows as a toast on top of the sheet instead ([_SheetToast]).
void showAppSnackBar(
  BuildContext context,
  String message, {
  Tone tone = Tone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  if (ModalRoute.of(context) is PopupRoute) {
    _SheetToast.show(
      context,
      message,
      tone: tone,
      actionLabel: actionLabel,
      onAction: onAction,
    );
    return;
  }
  showAppSnackBarOn(
    ScaffoldMessenger.of(context),
    message,
    tone: tone,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

IconData? _iconOf(Tone tone) => switch (tone) {
  Tone.success => AppIcons.success,
  Tone.danger => AppIcons.error,
  Tone.warning => AppIcons.warning,
  Tone.info => AppIcons.info,
  _ => null,
};

/// [showAppSnackBar] on a messenger captured up front — for calls after an
/// `await` / pop, when the original context may already be gone.
void showAppSnackBarOn(
  ScaffoldMessengerState messenger,
  String message, {
  Tone tone = Tone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final icon = _iconOf(tone);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              // Resolved inside the snackbar (under the app theme) so a
              // captured messenger works without a live caller context.
              Builder(
                builder: (ctx) => Icon(icon, size: 20, color: tone.color(ctx)),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
}

/// The snackbar's look as an overlay entry, at the top of the screen (clear
/// of a sheet's pinned buttons and the keyboard), above the sheet that
/// raised it. One at a time; tap to dismiss; gone after a few seconds.
class _SheetToast extends StatefulWidget {
  const _SheetToast({
    required this.message,
    required this.tone,
    required this.onDone,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final Tone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDone;

  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    required Tone tone,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SheetToast(
        message: message,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction,
        onDone: () {
          if (_current == entry) _current = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  @override
  State<_SheetToast> createState() => _SheetToastState();
}

class _SheetToastState extends State<_SheetToast> {
  static const _shown = Duration(seconds: 4);
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _timer = Timer(_shown, _hide);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _hide() {
    if (!mounted) return;
    setState(() => _visible = false);
    Timer(const Duration(milliseconds: 200), widget.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snack = theme.snackBarTheme;
    final scheme = theme.colorScheme;
    final icon = _iconOf(widget.tone);
    final fg = snack.contentTextStyle?.color ?? scheme.onInverseSurface;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, -0.4),
        duration: animate ? const Duration(milliseconds: 200) : Duration.zero,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: animate ? const Duration(milliseconds: 200) : Duration.zero,
          child: Semantics(
            liveRegion: true,
            child: Material(
              color: snack.backgroundColor ?? scheme.inverseSurface,
              elevation: 6,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: _hide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: widget.tone.color(context)),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          widget.message,
                          style:
                              (snack.contentTextStyle ??
                                      theme.textTheme.bodyMedium)
                                  ?.copyWith(color: fg),
                        ),
                      ),
                      if (widget.actionLabel != null && widget.onAction != null)
                        TextButton(
                          onPressed: () {
                            _hide();
                            widget.onAction!();
                          },
                          child: Text(widget.actionLabel!),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
