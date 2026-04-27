import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';

/// One choice in the icon grid. `id` is stable across asset migrations.
class IconPickerOption {
  const IconPickerOption({
    required this.id,
    required this.icon,
    this.assetPath,
    this.customThumb,
  });

  final String id;
  final IconData icon;

  /// Bundled image — preferred over [icon] when set; fallback to [icon] if
  /// the asset is missing.
  final String? assetPath;

  /// Per-option override for how the grid cell renders. Receives the
  /// currently-selected swatch color (for tinting). When null, the picker
  /// falls back to the default colored circle with [icon] / [assetPath].
  ///
  /// Used by the avatar picker's "Initials" preset, which shows the user's
  /// first letter on the swatch instead of an icon — domain-specific
  /// rendering the consumer owns.
  final Widget Function(Color swatchColor)? customThumb;
}

/// One choice in the color row.
class IconPickerSwatch {
  const IconPickerSwatch({required this.id, required this.color});

  final String id;
  final Color color;
}

/// Result of [showIconColorPickerSheet]. `null` means cancelled (user
/// dismissed without saving).
sealed class IconColorPickerResult {
  const IconColorPickerResult();
}

/// User picked an icon + swatch and tapped "Use this".
class IconColorPickerSelected extends IconColorPickerResult {
  const IconColorPickerSelected({required this.iconId, required this.swatchId});
  final String iconId;
  final String swatchId;
}

/// User tapped "Remove" — only available when the consumer enables the remove
/// button (it makes sense for editing an existing avatar / account, not for
/// creation flows).
class IconColorPickerRemoved extends IconColorPickerResult {
  const IconColorPickerRemoved();
}

/// Builder for the large preview circle at the top of the sheet. Lets each
/// consumer render its own preview — e.g. an account form draws a colored
/// circle with the icon, while a user-avatar form may want to render initials
/// over the swatch when "initials" preset is selected.
typedef IconColorPickerPreviewBuilder = Widget Function(
  IconPickerOption icon,
  IconPickerSwatch swatch,
);

/// Universal icon + color picker sheet. Used for any "pick an icon and a
/// color" flow — accounts, future categories / tags / projects, eventually
/// user avatars when the existing avatar picker migrates here.
///
/// **Designed to be flexible to change later** — the sheet has no hard-coded
/// presets, swatches, labels, or preview content. Every consumer plugs its
/// own:
/// - [iconOptions] — preset list to show in the grid
/// - [swatches] — color row
/// - [previewBuilder] — what the big circle on top looks like (defaults to a
///   colored circle with the selected icon)
/// - [previewSubtitle] — widget rendered just below the preview (e.g. a name
///   text, a "Account" pill badge, anything)
/// - Section + button labels
///
/// On phone width (<600 dp) renders as a draggable bottom sheet; on tablet+
/// renders as a centered dialog (max 480 dp wide), matching the existing
/// avatar picker's responsive behaviour.
Future<IconColorPickerResult?> showIconColorPickerSheet({
  required BuildContext context,
  required List<IconPickerOption> iconOptions,
  required List<IconPickerSwatch> swatches,
  required String initialIconId,
  required String initialSwatchId,
  Widget? previewSubtitle,
  IconColorPickerPreviewBuilder? previewBuilder,
  String? iconSectionLabel,
  String? colorSectionLabel,
  String? useThisLabel,
  String? removeLabel,
  String? uploadComingSoonLabel,
  String? cropComingSoonLabel,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= 600;
  final body = _Sheet(
    iconOptions: iconOptions,
    swatches: swatches,
    initialIconId: initialIconId,
    initialSwatchId: initialSwatchId,
    previewSubtitle: previewSubtitle,
    previewBuilder: previewBuilder,
    iconSectionLabel: iconSectionLabel,
    colorSectionLabel: colorSectionLabel,
    useThisLabel: useThisLabel,
    removeLabel: removeLabel,
    uploadComingSoonLabel: uploadComingSoonLabel,
    cropComingSoonLabel: cropComingSoonLabel,
  );

  if (isWide) {
    return showDialog<IconColorPickerResult>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: body,
        ),
      ),
    );
  }
  return showModalBottomSheet<IconColorPickerResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => body,
  );
}

class _Sheet extends StatefulWidget {
  const _Sheet({
    required this.iconOptions,
    required this.swatches,
    required this.initialIconId,
    required this.initialSwatchId,
    required this.previewSubtitle,
    required this.previewBuilder,
    required this.iconSectionLabel,
    required this.colorSectionLabel,
    required this.useThisLabel,
    required this.removeLabel,
    required this.uploadComingSoonLabel,
    required this.cropComingSoonLabel,
  });

  final List<IconPickerOption> iconOptions;
  final List<IconPickerSwatch> swatches;
  final String initialIconId;
  final String initialSwatchId;
  final Widget? previewSubtitle;
  final IconColorPickerPreviewBuilder? previewBuilder;
  final String? iconSectionLabel;
  final String? colorSectionLabel;
  final String? useThisLabel;
  final String? removeLabel;
  final String? uploadComingSoonLabel;
  final String? cropComingSoonLabel;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  late String _iconId = widget.initialIconId;
  late String _swatchId = widget.initialSwatchId;

  IconPickerOption get _currentIcon => widget.iconOptions.firstWhere(
        (o) => o.id == _iconId,
        orElse: () => widget.iconOptions.first,
      );

  IconPickerSwatch get _currentSwatch => widget.swatches.firstWhere(
        (s) => s.id == _swatchId,
        orElse: () => widget.swatches.first,
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final showUploadCropRow =
        widget.uploadComingSoonLabel != null ||
            widget.cropComingSoonLabel != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // When a [previewBuilder] is supplied, the consumer owns the
            // preview's layout (e.g. the account form passes a full-width
            // AccountCard, not a centered circle). The default preview only
            // gets centered when no builder is passed.
            if (widget.previewBuilder != null)
              widget.previewBuilder!(_currentIcon, _currentSwatch)
            else
              Center(
                child: _DefaultPreview(
                  icon: _currentIcon,
                  swatch: _currentSwatch,
                ),
              ),
            if (widget.previewSubtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(child: widget.previewSubtitle!),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
                text: widget.iconSectionLabel ?? l.iconPickerSectionStyle),
            const SizedBox(height: AppSpacing.sm),
            _PresetGrid(
              options: widget.iconOptions,
              selectedId: _iconId,
              swatchColor: _currentSwatch.color,
              onSelected: (o) => setState(() => _iconId = o.id),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
                text: widget.colorSectionLabel ?? l.iconPickerSectionColor),
            const SizedBox(height: AppSpacing.sm),
            _SwatchRow(
              swatches: widget.swatches,
              selectedId: _swatchId,
              onSelected: (s) => setState(() => _swatchId = s.id),
            ),
            if (showUploadCropRow) ...[
              const SizedBox(height: AppSpacing.xl),
              _DisabledUploadCropRow(
                uploadLabel: widget.uploadComingSoonLabel,
                cropLabel: widget.cropComingSoonLabel,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (widget.removeLabel != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pop<IconColorPickerResult>(
                              const IconColorPickerRemoved()),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(widget.removeLabel!),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop<IconColorPickerResult>(
                      IconColorPickerSelected(
                        iconId: _iconId,
                        swatchId: _swatchId,
                      ),
                    ),
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
  const _DefaultPreview({required this.icon, required this.swatch});
  final IconPickerOption icon;
  final IconPickerSwatch swatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(shape: BoxShape.circle, color: swatch.color),
      child: icon.assetPath != null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset(
                icon.assetPath!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Icon(icon.icon, color: Colors.white, size: 48),
              ),
            )
          : Icon(icon.icon, color: Colors.white, size: 48),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }
}

class _PresetGrid extends StatelessWidget {
  const _PresetGrid({
    required this.options,
    required this.selectedId,
    required this.swatchColor,
    required this.onSelected,
  });

  final List<IconPickerOption> options;
  final String selectedId;
  final Color swatchColor;
  final ValueChanged<IconPickerOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1,
      children: options.map((opt) {
        final isSelected = opt.id == selectedId;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelected(opt),
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
            child: Center(
              child: opt.customThumb != null
                  ? opt.customThumb!(swatchColor)
                  : _DefaultThumb(option: opt, swatchColor: swatchColor),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Default grid cell — colored circle with the option's icon (or bundled
/// asset). Used whenever an [IconPickerOption] doesn't supply its own
/// [IconPickerOption.customThumb].
class _DefaultThumb extends StatelessWidget {
  const _DefaultThumb({required this.option, required this.swatchColor});
  final IconPickerOption option;
  final Color swatchColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(shape: BoxShape.circle, color: swatchColor),
      child: option.assetPath != null
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                option.assetPath!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Icon(option.icon, color: Colors.white, size: 22),
              ),
            )
          : Icon(option.icon, color: Colors.white, size: 22),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({
    required this.swatches,
    required this.selectedId,
    required this.onSelected,
  });

  final List<IconPickerSwatch> swatches;
  final String selectedId;
  final ValueChanged<IconPickerSwatch> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: swatches.map((s) {
        final isSelected = s.id == selectedId;
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

class _DisabledUploadCropRow extends StatelessWidget {
  const _DisabledUploadCropRow({
    required this.uploadLabel,
    required this.cropLabel,
  });

  final String? uploadLabel;
  final String? cropLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (uploadLabel != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.upload_outlined),
              label: Text(uploadLabel!),
            ),
          ),
        if (uploadLabel != null && cropLabel != null)
          const SizedBox(width: AppSpacing.sm),
        if (cropLabel != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.crop_outlined),
              label: Text(cropLabel!),
            ),
          ),
      ],
    );
  }
}
