import 'package:flutter/material.dart';

import '../ui.dart';

/// A round checkbox the size of a [CardActionButton]: the circle is the box,
/// an empty ring or filled in [color] with a ✓.
class CheckCircleButton extends StatelessWidget {
  const CheckCircleButton({
    required this.checked,
    required this.onChanged,
    this.color,
    this.tooltip,
    this.loading = false,
    this.size,
    super.key,
  });

  /// Null = a [CardActionButton]'s size; a list row's leading passes 36.
  final double? size;

  final bool checked;

  /// Saving: a spinner in the circle, taps ignored.
  final bool loading;

  /// Null = read-only.
  final ValueChanged<bool>? onChanged;

  /// The fill when checked; defaults to the hero's accent, else primary.
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = AppIconButton.resolveSize(context, this.size);
    final fill = color ?? HeroColors.maybeOf(context)?.accent ?? scheme.primary;
    final onFill = ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final change = loading ? null : onChanged;
    Widget box = Material(
      type: MaterialType.transparency,
      child: InkResponse(
        onTap: change == null ? null : () => change(!checked),
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: checked ? fill : Colors.transparent,
            border: Border.all(color: checked ? fill : scheme.outline, width: 2),
          ),
          child: loading
              ? Padding(
                  padding: EdgeInsets.all(size * 0.25),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: checked ? onFill : fill,
                  ),
                )
              : checked
              ? Icon(AppIcons.check, size: size * 0.55, color: onFill)
              : null,
        ),
      ),
    );
    if (tooltip != null) box = Tooltip(message: tooltip!, child: box);
    return Semantics(checked: checked, button: true, child: box);
  }
}
