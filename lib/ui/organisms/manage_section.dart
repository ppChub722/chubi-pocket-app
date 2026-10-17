import 'package:flutter/material.dart';

import '../atoms/connection_scope.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../molecules/danger_row.dart';

class ManageAction {
  const ManageAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.submits = true,
  });

  final String label;
  final IconData icon;

  final VoidCallback? onTap;

  final bool submits;
}

class ManageSection extends StatelessWidget {
  const ManageSection({
    this.archiveLabel,
    this.onArchive,
    this.deleteLabel,
    this.onDelete,
    this.archiveConsequence,
    this.deleteConsequence,
    this.extraActions = const [],
    this.first = false,
    super.key,
  }) : assert(
         archiveLabel != null || deleteLabel != null || extraActions.length > 0,
         'ManageSection needs at least one action',
       );

  final String? archiveLabel;
  final VoidCallback? onArchive;
  final String? deleteLabel;
  final VoidCallback? onDelete;

  final String? archiveConsequence;
  final String? deleteConsequence;

  final List<ManageAction> extraActions;
  final bool first;

  @override
  Widget build(BuildContext context) {
    // Offline: archive / delete can't reach the server — disabled.
    final offline = ConnectionScope.isOffline(context);
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : AppSpacing.lg),
      child: Column(
        children: [
          for (final (i, a) in extraActions.indexed)
            DangerRow(
              icon: a.icon,
              label: a.label,
              neutral: true,
              padding: EdgeInsets.only(top: i > 0 ? AppSpacing.sm : 0),
              onTap: a.submits && offline ? null : a.onTap,
            ),
          if (archiveLabel != null)
            DangerRow(
              icon: AppIcons.archive,
              label: archiveLabel!,
              consequence: archiveConsequence,
              caution: true,
              padding: EdgeInsets.only(
                top: extraActions.isNotEmpty ? AppSpacing.sm : 0,
              ),
              onTap: offline ? null : onArchive,
            ),
          if (deleteLabel != null)
            DangerRow(
              icon: AppIcons.delete,
              label: deleteLabel!,
              consequence: deleteConsequence,
              padding: EdgeInsets.only(
                top: archiveLabel != null || extraActions.isNotEmpty
                    ? AppSpacing.sm
                    : 0,
              ),
              onTap: offline ? null : onDelete,
            ),
        ],
      ),
    );
  }
}
