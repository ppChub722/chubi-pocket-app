import 'package:flutter/material.dart';

/// A radio circle (one of a few, exactly one picked): a ring, filled with a
/// dot when [selected]. Only the mark; the row around it takes the tap.
/// [enabled] false = the muted ring (a "coming soon" choice).
class AppRadioMark extends StatelessWidget {
  const AppRadioMark({
    required this.selected,
    this.enabled = true,
    this.size = 20,
    super.key,
  });

  final bool selected;
  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = !enabled
        ? scheme.outlineVariant
        : selected
        ? scheme.primary
        : scheme.outline;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: selected
            ? Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            : null,
      ),
    );
  }
}
