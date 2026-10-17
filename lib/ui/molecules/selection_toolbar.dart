import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/bulk_delete_button.dart';
import '../atoms/select_check.dart';
import '../tokens/app_spacing.dart';
import 'filter_bar.dart';

class SelectionAction {
  const SelectionAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.needsSelection = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  final bool needsSelection;
}

class SelectionToolbar extends StatelessWidget {
  const SelectionToolbar({
    required this.selected,
    required this.total,
    required this.onSelectAll,
    this.selectAllTooltip,
    this.actions = const [],
    this.onDelete,
    this.deleteTooltip,
    this.trailing = const [],
    super.key,
  });

  final int selected;
  final int total;

  final VoidCallback? onSelectAll;
  final String? selectAllTooltip;
  final List<SelectionAction> actions;

  final VoidCallback? onDelete;
  final String? deleteTooltip;

  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final any = selected > 0;
    return FilterBar(
      chips: [
        SelectAllCount(
          selected: selected,
          total: total,
          tooltip: selectAllTooltip,
          onTap: onSelectAll,
        ),
        for (final a in actions)
          AppChip(
            icon: a.icon,
            label: a.label,
            tone: AppChipTone.primary,
            selected: true,
            enabled: a.onTap != null && (!a.needsSelection || any),
            onTap: a.onTap,
          ),
      ],
      trailing: trailing.isEmpty && onDelete == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final w in trailing) ...[
                  w,
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (onDelete != null)
                  BulkDeleteButton(
                    tooltip: deleteTooltip,
                    onPressed: any ? onDelete : null,
                  ),
              ],
            ),
    );
  }
}
