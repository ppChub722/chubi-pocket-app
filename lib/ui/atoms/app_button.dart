import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import 'busy_scope.dart';
import 'connection_scope.dart';

enum AppButtonVariant {
  primary,

  tonal,

  outlined,

  text,

  destructive,

  destructiveOutlined,
}

/// [mini], [chip] and [control] match the chip heights, padding, icon and label
/// style of the same-named `ChipSize`.
enum AppButtonSize {
  mini(ChipSize.mini),
  chip(ChipSize.chip),
  control(ChipSize.control),
  regular(null),
  large(null);

  const AppButtonSize(this.chipSize);

  final ChipSize? chipSize;
}

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconColor,
    this.trailingIcon,
    this.color,
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

  /// Null = the button's text colour.
  final Color? iconColor;

  /// After the label, e.g. ▾ on a button that opens a menu.
  final IconData? trailingIcon;

  /// Text and outlined only: the label / border colour in place of primary,
  /// e.g. a tone's colour on a tinted message.
  final Color? color;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// This is the button that was pressed and its call runs: a spinner in
  /// place of the label (same size, same colours), presses ignored. An
  /// active [BusyScope] above does the same; a locked one fades it.
  final bool loading;
  final bool expand;

  final bool submits;

  /// Told the label of every tap; the app sets it to record the user's steps
  /// (the kit itself knows no logger).
  static void Function(String label)? tapObserver;

  double _height(BuildContext context) =>
      size.chipSize?.heightOf(context) ??
      (size == AppButtonSize.large ? 48 : 40);

  bool isEnabled(BuildContext context) =>
      onPressed != null && !(submits && ConnectionScope.isOffline(context));

  static void _ignore() {}

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = isEnabled(context);
    final busy = BusyScope.control(context, loading: loading, enabled: enabled);
    final spinning = busy.spinning;
    final observe = tapObserver;
    // While it spins it keeps its enabled colours (it is the pressed one);
    // the lock's IgnorePointer drops the presses.
    final callback = spinning
        ? _ignore
        : !enabled
        ? null
        : observe == null
        ? onPressed
        : () {
            observe(label);
            onPressed!();
          };
    final chip = size.chipSize;
    final minSize = Size(expand ? double.infinity : 0, _height(context));
    final padding = EdgeInsets.symmetric(
      horizontal: chip?.padding ?? AppSpacing.lg,
    );
    final textStyle = chip
        ?.textStyle(context)
        ?.copyWith(fontWeight: ChipSize.chipWeight);
    final tapTarget = chip == null ? null : MaterialTapTargetSize.shrinkWrap;
    final OutlinedBorder? shape = chip == null ? null : const StadiumBorder();
    // Desktop's compact density would shave 8 off the height we set here.
    final density = chip == null ? null : VisualDensity.standard;

    final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            padding: padding,
            textStyle: textStyle,
            tapTargetSize: tapTarget,
            shape: shape,
            visualDensity: density,
          ),
          child: _content(spinning, scheme.onPrimary),
        );
      case AppButtonVariant.tonal:
        button = FilledButton.tonal(
          onPressed: callback,
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            padding: padding,
            textStyle: textStyle,
            tapTargetSize: tapTarget,
            shape: shape,
            visualDensity: density,
          ),
          child: _content(spinning, scheme.onSecondaryContainer),
        );
      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: callback,
          style: OutlinedButton.styleFrom(
            minimumSize: minSize,
            padding: padding,
            textStyle: textStyle,
            tapTargetSize: tapTarget,
            shape: shape,
            visualDensity: density,
            foregroundColor: color,
            side: color == null ? null : BorderSide(color: color!),
          ),
          child: _content(spinning, color ?? scheme.primary),
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: callback,
          style: TextButton.styleFrom(
            minimumSize: minSize,
            padding: padding,
            textStyle: textStyle,
            tapTargetSize: tapTarget,
            shape: shape,
            visualDensity: density,
            foregroundColor: color,
          ),
          child: _content(spinning, color ?? scheme.primary),
        );
      case AppButtonVariant.destructive:
        button = FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            padding: padding,
            textStyle: textStyle,
            tapTargetSize: tapTarget,
            shape: shape,
            visualDensity: density,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: _content(spinning, scheme.onError),
        );
      case AppButtonVariant.destructiveOutlined:
        button = OutlinedButton(
          onPressed: callback,
          style: OutlinedButton.styleFrom(
            minimumSize: minSize,
            padding: padding,
            textStyle: textStyle,
            tapTargetSize: tapTarget,
            shape: shape,
            visualDensity: density,
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error),
          ),
          child: _content(spinning, scheme.error),
        );
    }
    return BusyLock(locked: busy.locked, inert: spinning, child: button);
  }

  /// The label (and icons) stay laid out under the spinner, so a loading
  /// button is exactly as wide as before.
  Widget _content(bool spinning, Color spinnerColor) => BusySwap(
    loading: spinning,
    color: spinnerColor,
    spinnerSize: size.chipSize?.icon,
    child: _label(),
  );

  Widget _label() {
    final chip = size.chipSize;
    final iconSize = chip?.icon ?? 18;
    final gap = chip?.gap ?? AppSpacing.sm;
    // One line always: a long label ends in "…" instead of wrapping.
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
    if (icon == null && trailingIcon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: iconColor),
          SizedBox(width: gap),
        ],
        Flexible(child: text),
        if (trailingIcon != null) ...[
          SizedBox(width: gap),
          Icon(trailingIcon, size: iconSize + 4),
        ],
      ],
    );
  }
}
