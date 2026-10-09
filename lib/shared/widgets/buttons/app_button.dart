import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

/// Visual weight of an [AppButton].
enum AppButtonVariant {
  /// Filled brand colour — the one main action on a screen.
  primary,

  /// Filled tonal — secondary actions that still deserve weight.
  tonal,

  /// Outlined — cancel / neutral alternatives.
  outlined,

  /// Text only — low-emphasis actions (inline links, "view all").
  text,

  /// Filled error colour — confirm a destructive action.
  destructive,

  /// Outlined error colour — a destructive entry point (logout, delete row).
  destructiveOutlined,
}

/// Button heights. Both meet the 40dp+ touch-target rule; [large] is the
/// full-width form / bottom-bar size.
enum AppButtonSize { regular, large }

/// The one button the app uses. Wraps the Material buttons so every screen
/// gets the same heights, icon spacing, loading state and destructive
/// styling without restating `styleFrom` each time.
///
/// - [loading] swaps the label for a spinner and disables the button.
/// - [expand] stretches to the parent width (form / sheet footers).
/// - `onPressed: null` renders the disabled state.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.loading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool loading;
  final bool expand;

  double get _height => size == AppButtonSize.large ? 48 : 40;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !loading;
    final callback = enabled ? onPressed : null;
    final minSize = Size(expand ? double.infinity : 0, _height);
    const padding = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

    final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(minimumSize: minSize, padding: padding),
          child: _content(scheme.onPrimary),
        );
      case AppButtonVariant.tonal:
        button = FilledButton.tonal(
          onPressed: callback,
          style: FilledButton.styleFrom(minimumSize: minSize, padding: padding),
          child: _content(scheme.onSecondaryContainer),
        );
      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: callback,
          style: OutlinedButton.styleFrom(
            minimumSize: minSize,
            padding: padding,
          ),
          child: _content(scheme.primary),
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: callback,
          style: TextButton.styleFrom(minimumSize: minSize, padding: padding),
          child: _content(scheme.primary),
        );
      case AppButtonVariant.destructive:
        button = FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            padding: padding,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: _content(scheme.onError),
        );
      case AppButtonVariant.destructiveOutlined:
        button = OutlinedButton(
          onPressed: callback,
          style: OutlinedButton.styleFrom(
            minimumSize: minSize,
            padding: padding,
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error),
          ),
          child: _content(scheme.error),
        );
    }
    return button;
  }

  Widget _content(Color spinnerColor) {
    if (loading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: spinnerColor),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
