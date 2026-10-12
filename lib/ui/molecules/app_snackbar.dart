import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/tone.dart';
import 'app_message.dart';

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

/// [showAppSnackBar] on a messenger captured up front — for calls after an
/// `await` / pop, when the original context may already be gone. Now the one
/// message design ([AppMessage]); kept as the app-wide entry point.
void showAppSnackBarOn(
  ScaffoldMessengerState messenger,
  String message, {
  Tone tone = Tone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) => showAppMessageOn(
  messenger,
  message,
  tone: tone,
  actionLabel: actionLabel,
  onAction: onAction,
);

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
          child: GestureDetector(
            onTap: _hide,
            child: AppMessage(
              message: widget.message,
              tone: widget.tone,
              floating: true,
              actions: widget.actionLabel != null && widget.onAction != null
                  ? [
                      AppMessageAction(
                        label: widget.actionLabel!,
                        onPressed: () {
                          _hide();
                          widget.onAction!();
                        },
                      ),
                    ]
                  : const [],
            ),
          ),
        ),
      ),
    );
  }
}
