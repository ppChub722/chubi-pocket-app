import 'package:flutter/material.dart';

import '../atoms/connection_scope.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../molecules/danger_row.dart';

/// An extra, neutral button of a [ManageSection] (ปิดงบ, close goal): the
/// primary colour, above the archive / delete ones.
class ManageAction {
  const ManageAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.submits = true,
  });

  final String label;
  final IconData icon;

  /// Null = disabled (saving).
  final VoidCallback? onTap;

  /// Sends to the server: disabled while offline (default true).
  final bool submits;
}

/// The archive / delete buttons of a detail page, EDIT MODE ONLY, at the bottom
/// before the record info (owner 2026-10-12: NOT a section — no heading, no
/// grouped box, just the buttons): เก็บถาวร in amber, ลบ in red, the same
/// shape. Pass only what the entity has — archive only where it supports it.
///
/// ```dart
/// if (editing)
///   ManageSection(
///     archiveLabel: l.budgetArchive, onArchive: isSaving ? null : _archive,
///     deleteLabel: l.budgetDelete,   onDelete: isSaving ? null : _delete,
///   ),
/// ```
/// Each action's callback null = that button is disabled (saving); leave
/// its LABEL null to leave the button out.
class ManageSection extends StatelessWidget {
  const ManageSection({
    this.archiveLabel,
    this.onArchive,
    this.deleteLabel,
    this.onDelete,
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

  /// Neutral buttons above archive / delete (ปิดงบ).
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
