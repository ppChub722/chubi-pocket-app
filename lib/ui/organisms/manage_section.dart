import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../molecules/danger_row.dart';

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
    this.first = false,
    super.key,
  }) : assert(
         archiveLabel != null || deleteLabel != null,
         'ManageSection needs at least one action',
       );

  final String? archiveLabel;
  final VoidCallback? onArchive;
  final String? deleteLabel;
  final VoidCallback? onDelete;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : AppSpacing.lg),
      child: Column(
        children: [
          if (archiveLabel != null)
            DangerRow(
              icon: AppIcons.archive,
              label: archiveLabel!,
              caution: true,
              padding: EdgeInsets.zero,
              onTap: onArchive,
            ),
          if (deleteLabel != null)
            DangerRow(
              icon: AppIcons.delete,
              label: deleteLabel!,
              padding: EdgeInsets.only(
                top: archiveLabel != null ? AppSpacing.sm : 0,
              ),
              onTap: onDelete,
            ),
        ],
      ),
    );
  }
}
