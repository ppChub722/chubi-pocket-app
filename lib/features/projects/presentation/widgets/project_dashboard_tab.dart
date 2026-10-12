import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/project.dart';
import 'project_common.dart';

/// "สรุป" tab (§12b, default): totals, plan vs actual, my position,
/// members, who paid, top-5 tags. Every figure comes from the BE summary
/// (thin FE: no client-side aggregates); "รายการล่าสุด" was dropped (owner
/// 2026-10-12, E7) — the รายการ tab is one swipe away.
class ProjectDashboardTab extends StatelessWidget {
  const ProjectDashboardTab({
    required this.view,
    required this.onChanged,
    required this.onOpenMembers,
    required this.onInvite,
    this.onAdd,
    this.onShowTag,
    this.onImportTags,
    super.key,
  });

  final ProjectView view;

  /// Pull-to-refresh: the page's one "open" call.
  final Future<void> Function() onChanged;
  final VoidCallback onOpenMembers;

  /// Null = can't invite (not owner / locked).
  final VoidCallback? onInvite;

  /// Add a transaction (quick create); null = can't add (locked / not a
  /// member who may add).
  final VoidCallback? onAdd;

  /// A tag row: the รายการ tab filtered by that tag.
  final ValueChanged<BoardTag>? onShowTag;

  /// "นำเข้าทั้งหมด": every event tag I don't have yet into my own set
  /// (null = nothing to import).
  final VoidCallback? onImportTags;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final v = view;
    final s = v.summary;
    final symbol = v.symbol;
    final palette = Theme.of(context).extension<AppColors>()!;
    final members = v.currentMembers;
    final total = s?.totalExpense ?? 0;
    double shareOf(double x) => total <= 0 ? 0 : x / total;
    final payers = [
      for (final p in s?.positions ?? const <ProjectMemberPosition>[])
        if (p.paid > 0) p,
    ];
    // BE-sorted (total desc); the untagged bucket isn't a tag.
    final tags = [
      for (final t in s?.byTag ?? const <ProjectTagTotal>[])
        if (!t.isUntagged) t,
    ].take(5).toList();

    return PullToRefresh(
      onRefresh: onChanged,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          SectionCard(
            first: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SummaryStats(
                  stats: [
                    SummaryStat(
                      label: l.projectDashTotalExpense,
                      amount: s?.totalExpense ?? 0,
                      tone: MoneyTone.expense,
                    ),
                    SummaryStat(
                      label: l.projectDashTotalIncome,
                      amount: s?.totalIncome ?? 0,
                      tone: MoneyTone.income,
                    ),
                  ],
                ),
              ),
              if (s != null && s.hasPlan)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ProgressRow(
                    value: (s.plannedAmount ?? 0) == 0
                        ? 0
                        : (s.spentNet ?? 0) / s.plannedAmount!,
                    label: s.isOverPlan
                        ? l.projectPlannedOverLine(
                            moneyString(
                              context,
                              (s.remaining ?? 0).abs(),
                              symbol: symbol,
                            ),
                          )
                        : l.projectPlannedLine(
                            moneyString(
                              context,
                              s.plannedAmount!,
                              symbol: symbol,
                            ),
                            moneyString(
                              context,
                              s.remaining ?? 0,
                              symbol: symbol,
                            ),
                          ),
                  ),
                ),
              // Caller's standing, computed by the BE (contract §6a).
              if (s?.myNet != null)
                DetailRow(
                  label: l.projectMyNet,
                  helper: l.projectMyPosition(
                    moneyString(context, s!.myPaid ?? 0, symbol: symbol),
                    moneyString(context, s.myShare ?? 0, symbol: symbol),
                  ),
                  trailing: MoneyText(
                    s.myNet!,
                    tone: MoneyTone.signed,
                    symbol: symbol,
                  ),
                ),
              DetailRow(label: l.projectDashTxCount(s?.transactionCount ?? 0)),
              // Add a bill right from the first tab (same handler as the
              // รายการ tab's tile) — folded into the top box, not a lone one.
              if (onAdd != null)
                DetailAddRow(label: l.projectAddTransaction, onTap: onAdd),
            ],
          ),
          SectionCard(
            title: '${l.projectDashMembers} · ${members.length}',
            trailing: AppButton(
              label: l.projectMembersTitle,
              variant: AppButtonVariant.text,
              onPressed: onOpenMembers,
            ),
            dividers: false,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: MemberStrip(
                  members: [
                    for (final m in members)
                      PersonRef(
                        name: m.displayName,
                        iconCode: m.iconCode,
                        isOwner: m.isOwner,
                        pending: m.status == MemberStatus.pending,
                      ),
                  ],
                  onMemberTap: (_) => onOpenMembers(),
                  onInvite: onInvite,
                  inviteLabel: l.projectMembersInvite,
                ),
              ),
            ],
          ),
          if (payers.isNotEmpty)
            SectionCard(
              title: l.projectDashWhoPaid,
              children: [
                for (final p in payers)
                  PositionRow(
                    leading: memberAvatar(v.member(p.memberId), size: 28),
                    label: p.displayName,
                    amount: p.paid,
                    share: shareOf(p.paid),
                    symbol: symbol,
                  ),
              ],
            ),
          if (tags.isNotEmpty)
            SectionCard(
              title: l.projectDashTopTags,
              trailing: onImportTags == null
                  ? null
                  : AppButton(
                      label: l.eventTagsImportAll,
                      variant: AppButtonVariant.text,
                      onPressed: onImportTags,
                    ),
              children: [
                for (final t in tags)
                  PositionRow(
                    leading: IconTile(
                      icon: IconRegistry.get(
                        t.tag?.iconCode?.icon,
                        fallback: AppIcons.tag,
                      ),
                      color: EventTagRef(
                        t.name,
                        iconCode: t.tag?.iconCode,
                      ).colorOf(palette),
                      size: 28,
                    ),
                    label: t.name,
                    amount: t.total,
                    share: shareOf(t.total),
                    symbol: symbol,
                    color: palette.expense,
                    onTap: onShowTag == null || t.tag == null
                        ? null
                        : () => onShowTag!(t.tag!),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
