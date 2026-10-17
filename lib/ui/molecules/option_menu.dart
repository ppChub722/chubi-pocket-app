import 'package:flutter/material.dart';
import '../atoms/app_divider.dart';
import '../atoms/connection_scope.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../atoms/ui_config.dart';
import '../domain/icons/icon_registry.dart';
import '../atoms/app_avatar.dart';
import 'selectable_frame.dart';
import '../organisms/option_sheet.dart';

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

class _PopoverTitle extends StatelessWidget {
  const _PopoverTitle(this.title, {this.padding});

  final String title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.md + 2,
            AppSpacing.xs,
            AppSpacing.md + 2,
            AppSpacing.xs,
          ),
      child: Text(
        title,
        style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

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
    final enabled =
        option.enabled &&
        !(option.submits && ConnectionScope.isOffline(context));
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 2,
      ),
      child: MenuItemButton(
        closeOnActivate: closeOnActivate,
        onPressed: enabled ? onPressed : null,
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

class OptionMenuAnchor<T> extends StatelessWidget {
  const OptionMenuAnchor({
    required this.options,
    required this.onSelected,
    required this.builder,
    this.selected,
    this.title,
    super.key,
  });

  final List<SheetOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final PopoverTriggerBuilder builder;

  final String? title;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: _menuStyle(context),
      consumeOutsideTap: true,
      alignmentOffset: const Offset(0, AppSpacing.xs),
      menuChildren: [
        if (title != null) _PopoverTitle(title!),
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

class PopoverClearItem extends StatelessWidget {
  const PopoverClearItem({required this.onPressed, this.label, super.key});

  final VoidCallback onPressed;

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppDivider(height: AppSpacing.sm),
        MenuItemButton(
          leadingIcon: const Icon(AppIcons.clear, size: 18),
          onPressed: onPressed,
          child: Text(label ?? UiConfig.stringsOf(context).clear),
        ),
      ],
    );
  }
}

class MultiOptionMenuAnchor<T> extends StatelessWidget {
  const MultiOptionMenuAnchor({
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.builder,
    this.showClear = true,
    this.clearLabel,
    this.title,
    super.key,
  });

  final List<SheetOption<T>> options;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;
  final PopoverTriggerBuilder builder;
  final bool showClear;

  final String? title;

  final String? clearLabel;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: _menuStyle(context),
      consumeOutsideTap: true,
      alignmentOffset: const Offset(0, AppSpacing.xs),
      menuChildren: [
        if (title != null) _PopoverTitle(title!),
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

class PopoverAnchor extends StatelessWidget {
  const PopoverAnchor({
    required this.builder,
    required this.contentBuilder,
    this.maxWidth = 304,
    this.title,
    super.key,
  });

  final PopoverTriggerBuilder builder;
  final Widget Function(BuildContext context, VoidCallback close)
  contentBuilder;
  final double maxWidth;

  final String? title;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: _menuStyle(context),
      consumeOutsideTap: true,
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
                child: title == null
                    ? contentBuilder(ctx, () => controller?.close())
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PopoverTitle(
                            title!,
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                          ),
                          contentBuilder(ctx, () => controller?.close()),
                        ],
                      ),
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

  final ValueChanged<int> onToggle;

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

  final List<String> glyphs;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  final VoidCallback? onClear;
  final String? clearLabel;

  final IconData fallback;
  final double size;

  @override
  Widget build(BuildContext context) {
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
              child: AppAvatar.icon(
                IconRegistry.get(g, fallback: fallback),
                size: size,
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
