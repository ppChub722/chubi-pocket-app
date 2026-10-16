import 'package:flutter/material.dart';

/// The one on / off switch (owner 2026-10-12). In a detail page it is the
/// trailing of a `DetailRow` (the whole row toggles it); never a
/// `SwitchListTile`. [onChanged] null = disabled.
class PpForgeSwitch extends StatelessWidget {
  const PpForgeSwitch({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// What the switch controls, for screen readers (the row label).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    toggled: value,
    child: Switch(value: value, onChanged: onChanged),
  );
}
