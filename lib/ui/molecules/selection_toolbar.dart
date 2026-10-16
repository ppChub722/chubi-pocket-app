import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/bulk_delete_button.dart';
import '../atoms/select_check.dart';
import '../tokens/app_spacing.dart';
import 'filter_bar.dart';

/// One bulk action of a [SelectionToolbar] ("สี", "ไอคอน", "นำเข้าสลิป").
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

  /// Dimmed until something is selected (default); false = always available
  /// (an "import" next to the select-all).
  final bool needsSelection;
}

/// The select-mode bar of a list (owner 2026-10-12: one control on every
/// multi-select list): `[☐ n/N] [action] [action] …  [🗑]` — select / deselect
/// everything shown, the bulk actions on the selection (dimmed until
/// something is selected), and the red trash at the end.
///
/// Not [ModeActionBar] (that is the bottom Cancel · Save bar of an edit
/// mode); this sits at the top of the list.
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

  /// How many are picked, of how many shown.
  final int selected;
  final int total;

  /// Select all / deselect all.
  final VoidCallback? onSelectAll;
  final String? selectAllTooltip;
  final List<SelectionAction> actions;

  /// Null = no trash.
  final VoidCallback? onDelete;
  final String? deleteTooltip;

  /// Extra widgets at the end, before the trash.
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
          PpForgeChip(
            icon: a.icon,
            label: a.label,
            tone: PpForgeChipTone.primary,
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
                  const SizedBox(width: PpForgeSpacing.sm),
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
