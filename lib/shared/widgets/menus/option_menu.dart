import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../icon_maker/icon_registry.dart';
import '../layout/selectable_frame.dart';
import '../sheets/option_sheet.dart';

/// Popovers — menus anchored to the widget that opened them.
///
/// **Rule:** short, non-searchable choices (≤ ~7 options: status, type,
/// sort, colour) → popover. Long or searchable lists (currency, contacts,
/// accounts) → `showOptionSheet` bottom sheet.
///
/// Every anchor takes a `builder(context, toggle)`: render your trigger
/// (a `FilterDropdownChip`, `StatusPill`, button…) and call `toggle` on tap.

typedef PopoverTriggerBuilder =
    Widget Function(BuildContext context, VoidCallback toggle);

MenuStyle _menuStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return MenuStyle(
    backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
    elevation: const WidgetStatePropertyAll(4),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(vertical: AppSpacing.xs),
    ),
  );
}

void _toggle(MenuController c) => c.isOpen ? c.close() : c.open();

/// One popover row. Selected rows get the highlight ring (primary outline +
/// tint, inset from the menu edge) instead of a ✓ — same language as
/// `SelectableFrame`.
class _PopoverItem extends StatelessWidget {
  const _PopoverItem({
    required this.option,
    required this.selected,
    required this.onPressed,
    this.closeOnActivate = true,
  });

  final SheetOption<Object?> option;
  final bool selected;
  final VoidCallback? onPressed;
  final bool closeOnActivate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 2,
      ),
      child: MenuItemButton(
        closeOnActivate: closeOnActivate,
        onPressed: option.enabled ? onPressed : null,
        leadingIcon: option.leading,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(140, 44)),
          backgroundColor: WidgetStatePropertyAll(
            selected ? scheme.primary.withValues(alpha: 0.12) : null,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: selected
                  ? BorderSide(color: scheme.primary, width: 1.5)
                  : BorderSide.none,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              option.label,
              style: (option.labelStyle ?? const TextStyle()).copyWith(
                color: selected ? scheme.primary : null,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
            ),
            if (option.subtitle != null)
              Text(
                option.subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

/// Single-select popover. Picking an option closes it and calls
/// [onSelected]; the current [selected] option is ring-highlighted.
class OptionMenuAnchor<T> extends StatelessWidget {
  const OptionMenuAnchor({
    required this.options,
    required this.onSelected,
    required this.builder,
    this.selected,
    super.key,
  });

  final List<SheetOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final PopoverTriggerBuilder builder;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: _menuStyle(context),
      alignmentOffset: const Offset(0, AppSpacing.xs),
      menuChildren: [
        for (final o in options)
          _PopoverItem(
            option: o,
            selected: o.value == selected,
            onPressed: () => onSelected(o.value),
          ),
      ],
      builder: (context, controller, _) =>
          builder(context, () => _toggle(controller)),
    );
  }
}

/// "ล้าง" row at the bottom of every multi-select popover (option lists
/// and swatch grids) — same look everywhere. Hidden by the caller when
/// nothing is selected.
class PopoverClearItem extends StatelessWidget {
  const PopoverClearItem({required this.onPressed, this.label, super.key});

  final VoidCallback onPressed;

  /// Defaults to the localized "ล้าง".
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: AppSpacing.sm),
        MenuItemButton(
          leadingIcon: const Icon(AppIcons.clear, size: 18),
          onPressed: onPressed,
          child: Text(label ?? AppLocalizations.of(context)!.commonClear),
        ),
      ],
    );
  }
}

/// Multi-select popover. Selected rows are ring-highlighted; it stays open
/// while toggling and reports the whole new selection via [onChanged].
/// A "ล้าง" row appears once something is selected ([showClear]).
class MultiOptionMenuAnchor<T> extends StatelessWidget {
  const MultiOptionMenuAnchor({
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.builder,
    this.showClear = true,
    this.clearLabel,
    super.key,
  });

  final List<SheetOption<T>> options;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;
  final PopoverTriggerBuilder builder;
  final bool showClear;

  /// Overrides the localized "ล้าง".
  final String? clearLabel;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: _menuStyle(context),
      alignmentOffset: const Offset(0, AppSpacing.xs),
      menuChildren: [
        for (final o in options)
          _PopoverItem(
            option: o,
            selected: selected.contains(o.value),
            closeOnActivate: false,
            onPressed: () {
              final next = {...selected};
              next.contains(o.value) ? next.remove(o.value) : next.add(o.value);
              onChanged(next);
            },
          ),
        if (showClear && selected.isNotEmpty)
          PopoverClearItem(
            label: clearLabel,
            onPressed: () => onChanged(<T>{}),
          ),
      ],
      builder: (context, controller, _) =>
          builder(context, () => _toggle(controller)),
    );
  }
}

/// Popover with arbitrary content (colour grid, icon grid, mini form).
/// [contentBuilder] gets a `close` callback; the content stays open until
/// it calls it or the user taps outside. Rebuild-safe: content should read
/// state from the parent, which rebuilds the anchor.
class PopoverAnchor extends StatelessWidget {
  const PopoverAnchor({
    required this.builder,
    required this.contentBuilder,
    this.maxWidth = 304,
    super.key,
  });

  final PopoverTriggerBuilder builder;
  final Widget Function(BuildContext context, VoidCallback close)
  contentBuilder;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: _menuStyle(context),
      alignmentOffset: const Offset(0, AppSpacing.xs),
      menuChildren: [
        Builder(
          builder: (ctx) {
            final controller = MenuController.maybeOf(ctx);
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: contentBuilder(ctx, () => controller?.close()),
              ),
            );
          },
        ),
      ],
      builder: (context, controller, _) =>
          builder(context, () => _toggle(controller)),
    );
  }
}

/// Colour-swatch grid for [PopoverAnchor] — multi-select circles,
/// ring-highlighted when picked, with the same "ล้าง" row as
/// [MultiOptionMenuAnchor] once something is selected ([onClear]).
class ColorSwatchGrid extends StatelessWidget {
  const ColorSwatchGrid({
    required this.colors,
    required this.selected,
    required this.onToggle,
    this.onClear,
    this.clearLabel,
    this.size = 32,
    super.key,
  });

  final List<Color> colors;
  final Set<int> selected;

  /// Called with the tapped colour's index.
  final ValueChanged<int> onToggle;

  /// Clears the selection; null hides the "ล้าง" row.
  final VoidCallback? onClear;
  final String? clearLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final grid = _grid();
    if (onClear == null || selected.isEmpty) return grid;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        grid,
        PopoverClearItem(label: clearLabel, onPressed: onClear!),
      ],
    );
  }

  Widget _grid() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < colors.length; i++)
          InkResponse(
            onTap: () => onToggle(i),
            radius: size / 2 + 6,
            child: SelectableFrame(
              selected: selected.contains(i),
              radius: size / 2,
              color: colors[i],
              gap: 2,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Icon-swatch grid for [PopoverAnchor] — the [ColorSwatchGrid] of glyphs
/// (an icon filter): multi-select circles by icon id, ring-highlighted when
/// picked, + the same "ล้าง" row once something is selected ([onClear]).
class IconSwatchGrid extends StatelessWidget {
  const IconSwatchGrid({
    required this.glyphs,
    required this.selected,
    required this.onToggle,
    this.onClear,
    this.clearLabel,
    this.fallback = AppIcons.category,
    this.size = 32,
    super.key,
  });

  /// Icon ids ([IconRegistry] keys).
  final List<String> glyphs;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  /// Clears the selection; null hides the "ล้าง" row.
  final VoidCallback? onClear;
  final String? clearLabel;

  /// Shown for an id the registry doesn't know.
  final IconData fallback;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grid = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final g in glyphs)
          InkResponse(
            onTap: () => onToggle(g),
            radius: size / 2 + 6,
            child: SelectableFrame(
              selected: selected.contains(g),
              radius: size / 2,
              gap: 2,
              child: CircleAvatar(
                radius: size / 2,
                backgroundColor: scheme.surfaceContainerHighest,
                child: Icon(
                  IconRegistry.get(g, fallback: fallback),
                  size: size * 0.56,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
      ],
    );
    if (onClear == null || selected.isEmpty) return grid;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        grid,
        PopoverClearItem(label: clearLabel, onPressed: onClear!),
      ],
    );
  }
}
