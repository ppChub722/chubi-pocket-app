import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'app_spinner.dart';
import 'connection_scope.dart';

enum AppButtonVariant {
  primary,

  tonal,

  outlined,

  text,

  destructive,

  destructiveOutlined,
}

enum AppButtonSize { regular, large }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.loading = false,
    this.expand = false,
    this.submits = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool loading;
  final bool expand;

  final bool submits;

  double get _height => size == AppButtonSize.large ? 48 : 40;

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
      return AppSpinner(size: AppSpinnerSize.small, color: spinnerColor);
    }
    // One line always: a long label ends in "…" instead of wrapping.
    if (icon == null) {
      return Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
