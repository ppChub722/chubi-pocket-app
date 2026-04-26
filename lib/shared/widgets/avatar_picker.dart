import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import 'avatar_presets.dart';
import 'user_avatar.dart';

/// Returns the localized label for a [preset]. Falls back to [AvatarPreset.label]
/// when no localizations are available.
String localizedAvatarPresetLabel(AppLocalizations l, AvatarPreset preset) {
  switch (preset.id) {
    case 'initials':
      return l.avatarPresetInitials;
    case 'male':
      return l.avatarPresetMale;
    case 'female':
      return l.avatarPresetFemale;
    case 'chubby':
      return l.avatarPresetChubby;
    case 'snacker':
      return l.avatarPresetSnacker;
    case 'strong':
      return l.avatarPresetStrong;
    default:
      return preset.label;
  }
}

String localizedAvatarColorLabel(AppLocalizations l, AvatarColor color) {
  switch (color.id) {
    case 'red':
      return l.avatarColorRed;
    case 'green':
      return l.avatarColorGreen;
    case 'blue':
      return l.avatarColorBlue;
    case 'teal':
      return l.avatarColorTeal;
    case 'pink':
      return l.avatarColorPink;
    default:
      return color.label;
  }
}

/// Result returned by [showAvatarPicker]. `null` means the user cancelled.
sealed class AvatarPickerResult {
  const AvatarPickerResult();
}

/// User picked a preset+color combination — encoded as `preset:<icon>:<color>`.
class AvatarPickerPresetSelected extends AvatarPickerResult {
  const AvatarPickerPresetSelected(this.encoded);
  final String encoded;
}

/// User asked to remove the avatar (server: `avatar_url = null`).
class AvatarPickerRemove extends AvatarPickerResult {
  const AvatarPickerRemove();
}

/// Show the picker as a bottom sheet (mobile / narrow web) or dialog (wide
/// web). Returns the user's choice, or `null` if cancelled.
Future<AvatarPickerResult?> showAvatarPicker({
  required BuildContext context,
  required String displayName,
  required String? currentAvatarUrl,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= 600;
  final initial = AvatarPresetSelection.tryParse(currentAvatarUrl) ??
      AvatarPresetSelection.defaultSelection;

  if (isWide) {
    return showDialog<AvatarPickerResult>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _AvatarPickerSheet(
            displayName: displayName,
            initial: initial,
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<AvatarPickerResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _AvatarPickerSheet(
      displayName: displayName,
      initial: initial,
    ),
  );
}

class _AvatarPickerSheet extends StatefulWidget {
  const _AvatarPickerSheet({
    required this.displayName,
    required this.initial,
  });

  final String displayName;
  final AvatarPresetSelection initial;

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  late AvatarPresetSelection _sel;

  @override
  void initState() {
    super.initState();
    _sel = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: UserAvatar(
                displayName: widget.displayName,
                avatarUrl: _sel.encode(),
                size: 96,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.avatarPickerStyleLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            _PresetGrid(
              selectedId: _sel.preset.id,
              color: _sel.color.color,
              displayName: widget.displayName,
              onSelect: (p) => setState(() => _sel = _sel.copyWith(preset: p)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.avatarPickerColorLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ColorRow(
              selectedId: _sel.color.id,
              onSelect: (c) => setState(() => _sel = _sel.copyWith(color: c)),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _DisabledUploadCropRow(),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pop<AvatarPickerResult>(const AvatarPickerRemove()),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l.commonRemove),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context)
                        .pop<AvatarPickerResult>(
                            AvatarPickerPresetSelected(_sel.encode())),
                    child: Text(l.avatarPickerUseThis),
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

class _PresetGrid extends StatelessWidget {
  const _PresetGrid({
    required this.selectedId,
    required this.color,
    required this.displayName,
    required this.onSelect,
  });

  final String selectedId;
  final Color color;
  final String displayName;
  final void Function(AvatarPreset) onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 0.85,
      children: AvatarPreset.all.map((p) {
        final selected = p.id == selectedId;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelect(p),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: selected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PresetThumb(preset: p, color: color, displayName: displayName),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  localizedAvatarPresetLabel(l, p),
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PresetThumb extends StatelessWidget {
  const _PresetThumb({
    required this.preset,
    required this.color,
    required this.displayName,
  });

  final AvatarPreset preset;
  final Color color;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    if (preset.id == AvatarPreset.initials.id) {
      return UserAvatar(
        displayName: displayName,
        avatarUrl: 'preset:initials:teal', // colour overridden via container
        size: 40,
      );
    }
    final assetPath = preset.assetPath;
    return CircleAvatar(
      radius: 20,
      backgroundColor: color,
      child: assetPath != null
          ? Image.asset(
              assetPath,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Icon(preset.icon, color: Colors.white, size: 22),
            )
          : Icon(preset.icon, color: Colors.white, size: 22),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.selectedId, required this.onSelect});

  final String selectedId;
  final void Function(AvatarColor) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: AvatarColor.all.map((c) {
        final selected = c.id == selectedId;
        return InkResponse(
          onTap: () => onSelect(c),
          radius: 28,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.color,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _DisabledUploadCropRow extends StatelessWidget {
  const _DisabledUploadCropRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.upload_outlined),
            label: Text(l.avatarPickerUploadDisabled),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.crop_outlined),
            label: Text(l.avatarPickerCropDisabled),
          ),
        ),
      ],
    );
  }
}
