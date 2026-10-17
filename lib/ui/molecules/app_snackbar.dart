import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/tone.dart';
import 'app_message.dart';

/// Shows a floating snackbar, replacing any current one (so rapid actions don't
/// queue a backlog).
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
