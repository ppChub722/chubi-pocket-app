import 'package:flutter/material.dart';

import '../atoms/connection_scope.dart';
import '../molecules/danger_row.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';

enum EndZoneKind { close, archive, delete }

class EndZoneAction {
  const EndZoneAction({
    required this.kind,
    required this.label,
    required this.onTap,
    this.consequence,
    this.submits = true,
    this.icon,
  });

  final EndZoneKind kind;
  final String label;

  final String? consequence;

  final VoidCallback? onTap;

  final bool submits;

  final IconData? icon;
}

class EndZone extends StatelessWidget {
  const EndZone({required this.actions, this.first = false, super.key})
    : assert(actions.length > 0, 'EndZone needs at least one action');

  final List<EndZoneAction> actions;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final offline = ConnectionScope.isOffline(context);
    final sorted = [...actions]
      ..sort((a, b) => a.kind.index.compareTo(b.kind.index));
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : AppSpacing.lg),
      child: Column(
        children: [
          for (final (i, a) in sorted.indexed)
            DangerRow(
              icon:
                  a.icon ??
                  switch (a.kind) {
                    EndZoneKind.close => AppIcons.check,
                    EndZoneKind.archive => AppIcons.archive,
                    EndZoneKind.delete => AppIcons.delete,
                  },
              label: a.label,
              consequence: a.consequence,
              neutral: a.kind == EndZoneKind.close,
              caution: a.kind == EndZoneKind.archive,
              padding: EdgeInsets.only(top: i > 0 ? AppSpacing.sm : 0),
              onTap: a.submits && offline ? null : a.onTap,
            ),
        ],
      ),
    );
  }
}
