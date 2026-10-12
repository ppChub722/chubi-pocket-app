import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../atoms/ui_config.dart';
import '../molecules/danger_row.dart';
import '../molecules/detail_rows.dart';

/// การจัดการ — the last section of a detail page, EDIT MODE ONLY (owner
/// 2026-10-11): เก็บถาวร in amber, ลบ in red, the same shape. Pass only
/// what the entity has — archive only where it supports archive.
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
    return SectionCard(
      first: first,
      title: UiConfig.stringsOf(context).manageTitle,
      dividers: false,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.md,
          ),
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
        ),
      ],
    );
  }
}
