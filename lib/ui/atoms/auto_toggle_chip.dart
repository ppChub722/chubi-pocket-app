import 'package:flutter/material.dart';

import 'busy_scope.dart';
import '../tokens/app/app_icons.dart';

/// The auto toggle after an amount that can fill itself (owner 2026-10-21;
/// the auto icon, the same everywhere, 2026-10-23): on = the row takes the
/// remainder of the bill (a soft primary chip); off = the person typed their
/// own amount (an outlined grey chip). Typing in the amount turns it off;
/// tapping it turns it back on. [label] is the screen-reader word.
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

  // Faded and inert under a locked [BusyScope] (a save runs elsewhere).
  @override
  Widget build(BuildContext context) => BusyLock(
    locked: onChanged != null && BusyScope.isLocked(context),
    child: _build(context),
  );

  Widget _build(BuildContext context) {
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
          child: Icon(
            AppIcons.auto,
            size: 16,
            color: on ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
    final tip = tooltip;
    return tip == null ? chip : Tooltip(message: tip, child: chip);
  }
}
