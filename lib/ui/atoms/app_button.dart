import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'app_spinner.dart';
import 'connection_scope.dart';

/// Visual weight of an [PpForgeButton].
enum PpForgeButtonVariant {
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
enum PpForgeButtonSize { regular, large }

/// The one button the app uses. Wraps the Material buttons so every screen
/// gets the same heights, icon spacing, loading state and destructive
/// styling without restating `styleFrom` each time.
///
/// - [loading] swaps the label for a spinner and disables the button.
/// - [expand] stretches to the parent width (form / sheet footers).
/// - `onPressed: null` renders the disabled state.
/// - [submits] marks a button that sends something to the server (save,
///   submit, sign in, delete …): it disables itself while the app is offline
///   ([ConnectionScope]) — the banner says why — and typed input is left
///   alone. Pages never check the connection themselves.
class PpForgeButton extends StatelessWidget {
  const PpForgeButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = PpForgeButtonVariant.primary,
    this.size = PpForgeButtonSize.regular,
    this.loading = false,
    this.expand = false,
    this.submits = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PpForgeButtonVariant variant;
  final PpForgeButtonSize size;
  final bool loading;
  final bool expand;

  /// Sends to the server: disabled while offline (see the class doc).
  final bool submits;

  double get _height => size == PpForgeButtonSize.large ? 48 : 40;

  /// Whether the button takes taps right now ([onPressed] set, not
  /// [loading], and not a [submits] button while offline).
  bool isEnabled(BuildContext context) =>
      onPressed != null &&
      !loading &&
      !(submits && ConnectionScope.isOffline(context));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = isEnabled(context);
    final callback = enabled ? onPressed : null;
    final minSize = Size(expand ? double.infinity : 0, _height);
    const padding = EdgeInsets.symmetric(horizontal: PpForgeSpacing.lg);

    final Widget button;
    switch (variant) {
      case PpForgeButtonVariant.primary:
        button = FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(minimumSize: minSize, padding: padding),
          child: _content(scheme.onPrimary),
        );
      case PpForgeButtonVariant.tonal:
        button = FilledButton.tonal(
          onPressed: callback,
          style: FilledButton.styleFrom(minimumSize: minSize, padding: padding),
          child: _content(scheme.onSecondaryContainer),
        );
      case PpForgeButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: callback,
          style: OutlinedButton.styleFrom(
            minimumSize: minSize,
            padding: padding,
          ),
          child: _content(scheme.primary),
        );
      case PpForgeButtonVariant.text:
        button = TextButton(
          onPressed: callback,
          style: TextButton.styleFrom(minimumSize: minSize, padding: padding),
          child: _content(scheme.primary),
        );
      case PpForgeButtonVariant.destructive:
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
      case PpForgeButtonVariant.destructiveOutlined:
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
      return PpForgeSpinner(
        size: PpForgeSpinnerSize.small,
        color: spinnerColor,
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: PpForgeSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
