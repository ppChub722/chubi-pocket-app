import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import 'brand_palette.dart';
import 'icon_code.dart';
import 'icon_registry.dart';

/// Controls how the picker tints icons and what it stores in [IconCode].
enum IconMakerStyle {
  /// Solid circle background + white icon (accounts, categories, projects).
  /// Colour row picks `bgColors`; `iconColors` is always `['#FFFFFF']`.
  background,

  /// Transparent background + tinted icon (tags).
  /// Colour row picks `iconColors`; `bgColors` stays empty.
  iconColor,
}

/// Return type from [showIconMakerSheet].
sealed class IconMakerResult {
  const IconMakerResult();
}

/// User confirmed a selection.
class IconMakerSelected extends IconMakerResult {
  const IconMakerSelected(this.iconCode);
  final IconCode iconCode;
}

/// User tapped "Remove" (only shown when [showIconMakerSheet.removeLabel] is
/// set, i.e. on an existing entity's edit form).
class IconMakerRemoved extends IconMakerResult {
  const IconMakerRemoved();
}

/// Opens the icon + colour picker.
///
/// Returns [IconMakerSelected], [IconMakerRemoved], or `null` (cancelled).
///
/// - [iconIds] — ordered list of icon IDs to show in the grid. Use the
///   per-domain constants from [IconRegistry]: `accountIconIds`, etc.
/// - [style] — controls colour slot and preview rendering.
/// - [initial] — prefill state (current entity's [IconCode]).
/// - [previewBuilder] — optional live preview; receives the in-progress
///   [IconCode] after every change.
/// - [showColorSection] — pass `false` to hide the swatch row (e.g. L2/L3
///   categories that inherit their colour from the parent).
Future<IconMakerResult?> showIconMakerSheet({
  required BuildContext context,
  required List<String> iconIds,
  required IconMakerStyle style,
  IconCode? initial,
  Widget? previewSubtitle,
  Widget Function(IconCode)? previewBuilder,
  String? iconSectionLabel,
  String? colorSectionLabel,
  String? useThisLabel,
  String? removeLabel,
  bool showColorSection = true,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= 600;
  final body = _Sheet(
    iconIds: iconIds,
    style: style,
    initial: initial,
    previewSubtitle: previewSubtitle,
    previewBuilder: previewBuilder,
    iconSectionLabel: iconSectionLabel,
    colorSectionLabel: colorSectionLabel,
    useThisLabel: useThisLabel,
    removeLabel: removeLabel,
    showColorSection: showColorSection,
  );

  if (isWide) {
    return showDialog<IconMakerResult>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: body,
        ),
      ),
    );
  }
  return showModalBottomSheet<IconMakerResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => body,
  );
}

class _Sheet extends StatefulWidget {
  const _Sheet({
    required this.iconIds,
    required this.style,
    required this.initial,
    required this.previewSubtitle,
    required this.previewBuilder,
    required this.iconSectionLabel,
    required this.colorSectionLabel,
    required this.useThisLabel,
    required this.removeLabel,
    required this.showColorSection,
  });

  final List<String> iconIds;
  final IconMakerStyle style;
  final IconCode? initial;
  final Widget? previewSubtitle;
  final Widget Function(IconCode)? previewBuilder;
  final String? iconSectionLabel;
  final String? colorSectionLabel;
  final String? useThisLabel;
  final String? removeLabel;
  final bool showColorSection;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  late String _iconId;
  late BrandSwatch _swatch;

  @override
  void initState() {
    super.initState();
    final ic = widget.initial;
    _iconId = ic?.icon ??
        (widget.iconIds.isNotEmpty ? widget.iconIds.first : 'category');

    if (widget.style == IconMakerStyle.background) {
      _swatch = BrandPalette.byHex(ic?.bgColors.firstOrNull);
    } else {
      _swatch = BrandPalette.byHex(ic?.iconColors.firstOrNull);
    }
  }

  IconCode get _current {
    if (widget.style == IconMakerStyle.background) {
      return IconCode(
        icon: _iconId,
        iconColors: const ['#FFFFFF'],
        background: 'solid',
        bgColors: [_swatch.hex],
      );
    } else {
      return IconCode(
        icon: _iconId,
        iconColors: [_swatch.hex],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final iconCode = _current;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.previewBuilder != null)
              widget.previewBuilder!(iconCode)
            else
              Center(child: _DefaultPreview(iconCode: iconCode, style: widget.style)),
            if (widget.previewSubtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(child: widget.previewSubtitle!),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
              text: widget.iconSectionLabel ?? l.iconPickerSectionStyle,
            ),
            const SizedBox(height: AppSpacing.sm),
            _IconGrid(
              iconIds: widget.iconIds,
              selectedId: _iconId,
              swatch: _swatch,
              style: widget.style,
              onSelected: (id) => setState(() => _iconId = id),
            ),
            if (widget.showColorSection) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                text: widget.colorSectionLabel ?? l.iconPickerSectionColor,
              ),
              const SizedBox(height: AppSpacing.sm),
              _SwatchRow(
                selected: _swatch,
                onSelected: (s) => setState(() => _swatch = s),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (widget.removeLabel != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pop<IconMakerResult>(const IconMakerRemoved()),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(widget.removeLabel!),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context)
                        .pop<IconMakerResult>(IconMakerSelected(_current)),
                    child: Text(widget.useThisLabel ?? l.iconPickerUseThis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultPreview extends StatelessWidget {
  const _DefaultPreview({required this.iconCode, required this.style});
  final IconCode iconCode;
  final IconMakerStyle style;

  @override
  Widget build(BuildContext context) {
    final iconData = IconRegistry.get(iconCode.icon);
    if (style == IconMakerStyle.iconColor) {
      final color = iconCode.resolvedIconColor ?? const Color(0xFF64B5F6);
      return SizedBox(
        width: 96,
        height: 96,
        child: Icon(iconData, size: 56, color: color),
      );
    }
    final bgColor = iconCode.resolvedBgColor ?? const Color(0xFF64B5F6);
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
      child: Icon(iconData, size: 52, color: Colors.white),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({
    required this.iconIds,
    required this.selectedId,
    required this.swatch,
    required this.style,
    required this.onSelected,
  });

  final List<String> iconIds;
  final String selectedId;
  final BrandSwatch swatch;
  final IconMakerStyle style;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1,
      children: iconIds.map((id) {
        final isSelected = id == selectedId;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelected(id),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Center(child: _Thumb(id: id, swatch: swatch, style: style)),
          ),
        );
      }).toList(),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.id, required this.swatch, required this.style});
  final String id;
  final BrandSwatch swatch;
  final IconMakerStyle style;

  @override
  Widget build(BuildContext context) {
    final iconData = IconRegistry.get(id);
    if (style == IconMakerStyle.iconColor) {
      return Icon(iconData, size: 26, color: swatch.color);
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(shape: BoxShape.circle, color: swatch.color),
      child: Icon(iconData, size: 22, color: Colors.white),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.selected, required this.onSelected});
  final BrandSwatch selected;
  final ValueChanged<BrandSwatch> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: BrandPalette.all.map((s) {
        final isSelected = s.id == selected.id;
        return InkResponse(
          onTap: () => onSelected(s),
          radius: 28,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.color,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
