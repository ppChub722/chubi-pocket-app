import 'package:flutter/material.dart';

import 'busy_scope.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.loading = false,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  final String? semanticLabel;

  /// The flipped switch while its save runs: a spinner in its place, same
  /// size, flips ignored (see [BusyScope]).
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final busy = BusyScope.control(
      context,
      loading: loading,
      enabled: onChanged != null,
    );
    return Semantics(
      label: semanticLabel,
      toggled: value,
      child: BusyLock(
        locked: busy.locked,
        inert: busy.spinning,
        child: BusySwap(
          loading: busy.spinning,
          child: Switch(value: value, onChanged: onChanged),
        ),
      ),
    );
  }
}
