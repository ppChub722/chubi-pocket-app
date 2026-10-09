import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/project.dart';
import 'project_common.dart';
import 'project_tx_tiles.dart';

enum _Sort { time, amount, member, tag }

/// "รายการ" tab (§12b): search, [ประเภท ▾] [เฉพาะฉัน] + sort, rows grouped
/// under date headers when sorted by date. A dashed "+ เพิ่มรายการ" tile
/// heads the rows (and is the empty state's CTA) when [onAdd] is set.
class ProjectTxListTab extends StatefulWidget {
  const ProjectTxListTab({
    required this.view,
    required this.onChanged,
    this.onAdd,
    super.key,
  });

  final ProjectView view;
  final Future<void> Function() onChanged;

  /// Adds a row to the project; null = the user can't (locked / viewer).
  final VoidCallback? onAdd;

  @override
  State<ProjectTxListTab> createState() => _ProjectTxListTabState();
}

class _ProjectTxListTabState extends State<ProjectTxListTab> {
  String _query = '';
  String? _type; // null = all, 'expense', 'income'
  bool _mine = false;
  _Sort _sort = _Sort.time;

  List<ProjectTxTree> _shown() {
    final v = widget.view;
    final q = _query.trim().toLowerCase();
    final my = v.me?.id;
    final list = v.trees.where((t) {
      final p = t.parent;
      if (_type != null && p.type != _type) return false;
      if (_mine &&
          (my == null ||
              (p.transactionMemberId != my &&
                  !t.children.any((c) => c.transactionMemberId == my)))) {
        return false;
      }
      if (q.isEmpty) return true;
      return [
        p.description,
        p.note,
        ...p.tags,
        v.member(p.transactionMemberId).displayName,
      ].any((s) => s?.toLowerCase().contains(q) ?? false);
    }).toList();
    list.sort(
      (a, b) => switch (_sort) {
        _Sort.time => b.parent.date.compareTo(a.parent.date),
        _Sort.amount => b.parent.amount.compareTo(a.parent.amount),
        _Sort.member =>
          v
              .member(a.parent.transactionMemberId)
              .displayName
              .compareTo(v.member(b.parent.transactionMemberId).displayName),
        _Sort.tag => (a.parent.tags.firstOrNull ?? '').compareTo(
          b.parent.tags.firstOrNull ?? '',
        ),
      },
    );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final shown = _shown();
    final typeLabels = {
      'expense': l.projectTxTypeExpense,
      'income': l.projectTxTypeIncome,
    };

    final rows = <Widget>[];
    String? lastDate;
    for (final t in shown) {
      if (_sort == _Sort.time && t.parent.date != lastDate) {
        lastDate = t.parent.date;
        rows.add(DateGroupHeader(label: projectTxDateLabel(context, lastDate)));
      }
      rows.add(
        ProjectTxTreeTile(
          tree: t,
          view: widget.view,
          onChanged: widget.onChanged,
        ),
      );
    }

    return PullToRefresh(
      onRefresh: widget.onChanged,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          AppSearchBar(
            hint: l.projectTxSearchHint,
            onChanged: (v) => setState(() => _query = v),
          ),
          FilterBar(
            chips: [
              OptionMenuAnchor<String?>(
                selected: _type,
                onSelected: (t) => setState(() => _type = t),
                options: [
                  SheetOption(value: null, label: l.projectTxTypeAll),
                  for (final e in typeLabels.entries)
                    SheetOption(value: e.key, label: e.value),
                ],
                builder: (context, toggle) => FilterDropdownChip(
                  label: l.projectTxTypeLabel,
                  valueLabel: _type == null ? null : typeLabels[_type],
                  onTap: toggle,
                ),
              ),
              FilterChip(
                label: Text(l.projectTxOnlyMine),
                selected: _mine,
                onSelected: (v) => setState(() => _mine = v),
                showCheckmark: false,
                shape: const StadiumBorder(),
              ),
            ],
            trailing: SortChip<_Sort>(
              selected: _sort,
              onSelected: (s) => setState(() => _sort = s),
              options: [
                SortOption(_Sort.time, l.projectTxSortTime),
                SortOption(_Sort.amount, l.projectTxSortAmount),
                SortOption(_Sort.member, l.projectTxSortMember),
                SortOption(_Sort.tag, l.projectTxSortTag),
              ],
            ),
          ),
          if (widget.view.trees.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: EmptyView(
                icon: AppIcons.empty,
                title: l.projectTxEmpty,
                message: '',
                cta: widget.onAdd == null
                    ? null
                    : AddTile(
                        label: l.projectAddTransaction,
                        onTap: widget.onAdd,
                      ),
              ),
            )
          else ...[
            if (widget.onAdd != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: AddTile(
                  label: l.projectAddTransaction,
                  variant: AddTileVariant.row,
                  onTap: widget.onAdd,
                ),
              ),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(l.projectTxNoMatch, textAlign: TextAlign.center),
              )
            else
              ...rows,
          ],
        ],
      ),
    );
  }
}
