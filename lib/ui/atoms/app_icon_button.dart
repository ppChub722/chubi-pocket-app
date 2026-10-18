import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import 'app_chip.dart';
import '../tokens/chip_size.dart';
import 'app_icon.dart';
import 'count_badge.dart';

enum IconChipActivity { none, progress, done }

class AppIconButton extends StatelessWidget {
  static const double targetFlat = 48;
  static const double targetDense = 40;
  static const double glyphFlat = 24;
  static const double glyphSmall = 20;
  static const double glyphXs = 18;

  /// [size] if given, else the enclosing [ChipSizeScope]'s height, else the
  /// theme's control height ([ControlSizes]) — so a round button is always
  /// level with the chips of its row.
  static double resolveSize(BuildContext context, [double? size]) =>
      size ?? (ChipSizeScope.of(context) ?? ChipSize.control).heightOf(context);

  const AppIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badgeCount = 0,
    this.destructive = false,
    this.selected = false,
    this.size,
    this.activity = IconChipActivity.none,
    this.progress,
    super.key,
  }) : _flat = false,
       iconSize = null,
       color = null,
       dense = false;

  const AppIconButton.edit({
    required this.onPressed,
    this.tooltip,
    this.size,
    super.key,
  }) : icon = AppIcons.edit,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = false,
       iconSize = null,
       color = null,
       dense = false;

  const factory AppIconButton.bare({
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
    double? size,
    Color? color,
    Key? key,
  }) = _BareIconButton;

  const AppIconButton._bare({
    this.color,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size,
    super.key,
  }) : badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = false,
       iconSize = null,
       dense = false;

  const AppIconButton.flat({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : size = null,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  const AppIconButton.close({
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : icon = AppIcons.close,
       size = null,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  const AppIconButton.clear({
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : icon = AppIcons.clear,
       size = null,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  const AppIconButton.more({
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : icon = AppIcons.more,
       size = null,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  const AppIconButton.back({
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : icon = AppIcons.back,
       size = null,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  final bool _flat;

  final double? iconSize;
  final Color? color;
  final bool dense;

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final int badgeCount;
  final bool destructive;

  final bool selected;
  final double? size;
  final IconChipActivity activity;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    if (_flat) {
      final target = dense ? targetDense : targetFlat;
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: target, height: target),
        color: color,
        icon: AppIcon(icon, size: iconSize ?? glyphFlat),
      );
    }
    final size = resolveSize(context, this.size);
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final iconColor = destructive
        ? scheme.error
        : selected
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final working = activity == IconChipActivity.progress;
    final done = activity == IconChipActivity.done;
    final glyphSize = size * 0.55;
    const fade = Duration(milliseconds: 160);
    final glyph = Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          duration: fade,
          opacity: done ? 0.3 : 1,
          child: Icon(icon, size: glyphSize, color: iconColor),
        ),
        AnimatedOpacity(
          duration: fade,
          opacity: done ? 1 : 0,
          child: Icon(AppIcons.check, size: glyphSize, color: scheme.primary),
        ),
      ],
    );

    final circle = Opacity(
      opacity: enabled ? 1 : 0.38,
      child: Material(
        color: destructive
            ? Color.alphaBlend(
                scheme.error.withValues(alpha: 0.12),
                scheme.surfaceContainerHigh,
              )
            : selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHigh,
        elevation: enabled ? 1.5 : 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.2),
        shape: CircleBorder(
          side: destructive
              ? BorderSide(color: scheme.error, width: 1.5)
              : BorderSide(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                glyph,
                if (working)
                  Positioned(
                    bottom: size * 0.1,
                    child: SizedBox(
                      width: size * 0.42,
                      height: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          color: scheme.primary,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    Widget chip = working
        ? circle
        : CountBadge.floating(child: circle, count: badgeCount);
    chip = UnconstrainedBox(
      alignment: AlignmentDirectional.topStart,
      child: chip,
    );
    if (tooltip != null) chip = Tooltip(message: tooltip!, child: chip);
    return chip;
  }
}

class _BareIconButton extends AppIconButton {
  const _BareIconButton({
    required super.icon,
    required super.onPressed,
    super.tooltip,
    super.size,
    super.color,
    super.key,
  }) : super._bare();

  @override
  Widget build(BuildContext context) {
    final size = AppIconButton.resolveSize(context, this.size);
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    Widget button = Opacity(
      opacity: enabled ? 1 : 0.38,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: onPressed,
          radius: size / 2,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Icon(
                icon,
                size: size * 0.55,
                color: color ?? scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}
