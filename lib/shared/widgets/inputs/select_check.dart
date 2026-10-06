import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';

/// Round multi-select check — the app's selection mark in edit mode (grid
/// cells, rows) and for "select all" above them, so both look the same.
///
/// [value]: `true` ✓ · `false` empty · `null` partial (−, select-all only).
class SelectCheck extends StatelessWidget {
  const SelectCheck({
    required this.value,
    required this.onTap,
    this.size = 20,
    this.tooltip,
    super.key,
  });

  final bool? value;
  final VoidCallback? onTap;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = value != false;
    final check = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: filled ? scheme.primary : scheme.outline,
          width: 1.5,
        ),
      ),
      child: filled
          ? Icon(
              value == null ? Icons.remove : AppIcons.check,
              size: size * 0.7,
              color: scheme.onPrimary,
            )
          : null,
    );
    final tappable = InkResponse(
      onTap: onTap,
      radius: size,
      child: Padding(padding: const EdgeInsets.all(4), child: check),
    );
    return tooltip == null ? tappable : Tooltip(message: tooltip!, child: tappable);
  }
}
