import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import 'app_chip.dart';
import '../tokens/chip_size.dart';
import '../tokens/app_opacity.dart';
import '../tokens/hero_colors.dart';
import 'app_spinner.dart';
import 'busy_scope.dart';
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
    this.loading = false,
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
    this.loading = false,
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

  /// No circle until [selected] (then primaryContainer).
  const factory AppIconButton.bare({
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
    bool loading,
    double? size,
    Color? color,
    bool selected,
    Key? key,
  }) = _BareIconButton;

  /// Filled in primary with the icon in onPrimary (a row's ✓).
  const factory AppIconButton.filled({
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
    bool loading,
    double? size,
    Key? key,
  }) = _FilledIconButton;

  /// The page's floating action (Scaffold.floatingActionButton).
  const factory AppIconButton.fab({
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
    bool loading,
    Key? key,
  }) = _FabIconButton;

  const AppIconButton._bare({
    this.color,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.loading = false,
    this.size,
    this.selected = false,
    super.key,
  }) : badgeCount = 0,
       destructive = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = false,
       iconSize = null,
       dense = false;

  const AppIconButton.flat({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.loading = false,
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
    this.loading = false,
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
    this.loading = false,
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
    this.loading = false,
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
    this.loading = false,
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

  /// The pressed button while its call runs: a spinner in place of the
  /// glyph, same size, presses ignored (see [BusyScope]).
  final bool loading;

  static void _ignore() {}

  /// The callback for Material's own buttons: kept non-null while spinning
  /// (enabled colours), the lock drops the presses.
  VoidCallback? _press(bool spinning) => spinning ? _ignore : onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = BusyScope.control(
      context,
      loading: loading,
      enabled: onPressed != null,
    );
    if (_flat) {
      final target = dense ? targetDense : targetFlat;
      final glyph = iconSize ?? glyphFlat;
      return BusyLock(
        locked: busy.locked,
        inert: busy.spinning,
        child: IconButton(
          tooltip: tooltip,
          onPressed: _press(busy.spinning),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: target, height: target),
          color: color,
          icon: BusySwap(
            loading: busy.spinning,
            color: color,
            spinnerSize: glyph * 0.8,
            child: AppIcon(icon, size: glyph),
          ),
        ),
      );
    }
    final size = resolveSize(context, this.size);
    final scheme = Theme.of(context).colorScheme;
    final hero = HeroColors.maybeOf(context);
    final enabled = onPressed != null || busy.spinning;
    final iconColor = destructive
        ? scheme.error
        : selected
        ? scheme.onPrimaryContainer
        : hero?.accent ?? scheme.onSurface;
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
      opacity: enabled ? 1 : AppOpacity.disabled,
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
                  color: selected
                      ? scheme.primary
                      : hero?.line ?? scheme.outlineVariant,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy.spinning ? null : onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                BusySwap(
                  loading: busy.spinning,
                  color: iconColor,
                  spinnerSize: glyphSize * 0.8,
                  child: glyph,
                ),
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
    return BusyLock(locked: busy.locked, inert: busy.spinning, child: chip);
  }
}

class _FilledIconButton extends AppIconButton {
  const _FilledIconButton({
    required super.icon,
    required super.onPressed,
    super.tooltip,
    super.loading,
    super.size,
    super.key,
  }) : super._bare();

  @override
  Widget build(BuildContext context) {
    final size = AppIconButton.resolveSize(context, this.size);
    final scheme = Theme.of(context).colorScheme;
    final busy = BusyScope.control(
      context,
      loading: loading,
      enabled: onPressed != null,
    );
    final enabled = onPressed != null || busy.spinning;
    Widget button = Material(
      color: enabled
          ? scheme.primary
          : scheme.onSurface.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy.spinning ? null : onPressed,
        child: SizedBox.square(
          dimension: size,
          child: BusySwap(
            loading: busy.spinning,
            color: scheme.onPrimary,
            spinnerSize: size * 0.5,
            child: Icon(
              icon,
              size: size * 0.6,
              color: enabled
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: AppOpacity.disabled),
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return BusyLock(
      locked: busy.locked,
      inert: busy.spinning,
      child: Semantics(button: true, child: button),
    );
  }
}

class _FabIconButton extends AppIconButton {
  const _FabIconButton({
    required super.icon,
    required super.onPressed,
    super.tooltip,
    super.loading,
    super.key,
  }) : super._bare();

  @override
  Widget build(BuildContext context) {
    final busy = BusyScope.control(
      context,
      loading: loading,
      enabled: onPressed != null,
    );
    return BusyLock(
      locked: busy.locked,
      inert: busy.spinning,
      child: FloatingActionButton(
        heroTag: null,
        tooltip: tooltip,
        onPressed: _press(busy.spinning),
        child: BusySwap(
          loading: busy.spinning,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          spinnerSize: AppSpinnerSize.medium.dimension,
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _BareIconButton extends AppIconButton {
  const _BareIconButton({
    required super.icon,
    required super.onPressed,
    super.tooltip,
    super.loading,
    super.size,
    super.color,
    super.selected,
    super.key,
  }) : super._bare();

  @override
  Widget build(BuildContext context) {
    final size = AppIconButton.resolveSize(context, this.size);
    final scheme = Theme.of(context).colorScheme;
    final busy = BusyScope.control(
      context,
      loading: loading,
      enabled: onPressed != null,
    );
    final enabled = onPressed != null || busy.spinning;
    final tint = selected ? scheme.primary : color ?? scheme.onSurfaceVariant;
    Widget button = Opacity(
      opacity: enabled ? 1 : AppOpacity.disabled,
      child: Material(
        type: selected ? MaterialType.circle : MaterialType.transparency,
        color: selected ? scheme.primaryContainer : null,
        child: InkResponse(
          onTap: busy.spinning ? null : onPressed,
          radius: size / 2,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: BusySwap(
                loading: busy.spinning,
                color: tint,
                spinnerSize: size * 0.45,
                child: Icon(icon, size: size * 0.55, color: tint),
              ),
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return BusyLock(locked: busy.locked, inert: busy.spinning, child: button);
  }
}
