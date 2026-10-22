import 'package:flutter/material.dart';

import '../tokens/chip_size.dart';

/// The "A" toggle after an amount that can fill itself (owner 2026-10-21):
/// on = the row takes the remainder of the bill (a soft primary chip);
/// off = the person typed their own amount (an outlined grey chip). Typing in
/// the amount turns it off; tapping it turns it back on.
class AutoToggleChip extends StatelessWidget {
  const AutoToggleChip({
    required this.value,
    required this.onChanged,
    this.label = 'A',
    this.tooltip,
    super.key,
  });

  final bool value;

  /// Null = shown, not tappable.
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? tooltip;

  static const double size = 26;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = value;
    final chip = Semantics(
      button: onChanged != null,
      toggled: on,
      label: tooltip ?? label,
      child: InkResponse(
        onTap: onChanged == null ? null : () => onChanged!(!on),
        radius: size,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on
                ? Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.16),
                    scheme.surface,
                  )
                : scheme.surface,
            border: Border.all(
              color: on ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: ChipSize.chip
                .textStyle(context)
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: on ? scheme.primary : scheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
    final tip = tooltip;
    return tip == null ? chip : Tooltip(message: tip, child: chip);
  }
}
