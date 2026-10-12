import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/project.dart';
import 'project_common.dart';
import 'project_tx_tiles.dart';

/// "แดชบอร์ด" tab (§12b, default): totals, plan vs actual, members, who
/// paid, top categories, the latest 3 rows → "ดูทั้งหมด". "My position"
/// comes from the BE summary (contract §6a); who-paid / categories are
/// computed on the client from the loaded rows (the summary carries them
/// too, as `members` / `by_category`).
class ProjectDashboardTab extends StatelessWidget {
  const ProjectDashboardTab({
    required this.view,
    required this.onChanged,
    required this.onSeeAll,
    required this.onOpenMembers,
    required this.onInvite,
    this.onAdd,
    super.key,
  });

  final ProjectView view;
  final Future<void> Function() onChanged;
  final VoidCallback onSeeAll;
  final VoidCallback onOpenMembers;

  /// Null = can't invite (not owner / locked).
  final VoidCallback? onInvite;

  /// Add a transaction (quick create); null = can't add (locked / not a
  /// member who may add).
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final v = view;
    final s = v.summary;
    final symbol = v.symbol;
    final palette = Theme.of(context).extension<AppColors>()!;
    final members = v.currentMembers;

    // Who paid — parent expense rows by payer.
    final expenses = v.trees.where((t) => t.parent.type == 'expense');
    final paidBy = <String, double>{};
    for (final t in expenses) {
      paidBy.update(
        t.parent.transactionMemberId,
        (a) => a + t.parent.amount,
        ifAbsent: () => t.parent.amount,
      );
    }
    final totalPaid = paidBy.values.fold<double>(0, (a, b) => a + b);
    final payers = paidBy.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top tags — a row with several tags counts under each.
    final byCat = <String, (double, ProjectTransaction)>{};
    for (final t in expenses) {
      for (final name in t.parent.tags) {
        final prev = byCat[name];
        byCat[name] = ((prev?.$1 ?? 0) + t.parent.amount, prev?.$2 ?? t.parent);
      }
    }
    final cats = byCat.entries.toList()
      ..sort((a, b) => b.value.$1.compareTo(a.value.$1));

    final recent = [...v.trees]
      ..sort((a, b) => b.parent.date.compareTo(a.parent.date));

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
              DetailRow(label: l.projectDashTxCount(v.trees.length)),
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
                for (final e in payers)
                  _barRow(
                    leading: memberAvatar(v.member(e.key), size: 28),
                    label: v.member(e.key).displayName,
                    amount: e.value,
                    share: totalPaid == 0 ? 0 : e.value / totalPaid,
                    symbol: symbol,
                  ),
              ],
            ),
          if (cats.isNotEmpty)
            SectionCard(
              title: l.projectDashTopTags,
              children: [
                for (final e in cats.take(5))
                  _barRow(
                    leading: ProjectTxIcon(tx: e.value.$2, size: 28),
                    label: e.key,
                    amount: e.value.$1,
                    share: totalPaid == 0 ? 0 : e.value.$1 / totalPaid,
                    symbol: symbol,
                    color: palette.expense,
                  ),
              ],
            ),
          if (recent.isNotEmpty)
            SectionCard(
              title: l.projectDashRecent,
              trailing: AppButton(
                label: l.projectDashSeeAll,
                variant: AppButtonVariant.text,
                onPressed: onSeeAll,
              ),
              children: [
                for (final t in recent.take(3))
                  ProjectTxTreeTile(tree: t, view: v, onChanged: onChanged),
              ],
            ),
        ],
      ),
    );
  }
}

/// One bar of a ranking (who paid, top tags): avatar / icon, name + amount,
/// and the share of the total under them.
Widget _barRow({
  required Widget leading,
  required String label,
  required double amount,
  required double share,
  required String symbol,
  Color? color,
}) {
  return ListRow(
    leading: leading,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            MoneyText(amount, symbol: symbol),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ProgressRow(value: share, color: color, height: 6),
      ],
    ),
  );
}
