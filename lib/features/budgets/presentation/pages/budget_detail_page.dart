import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/budget.dart';
import '../cubit/budgets_cubit.dart';
import '../widgets/budget_card.dart';

/// `/budgets/:id`: header (spent big, limit, progress, remaining, period
/// range, over-limit warning) → breakdown by sub-category → note. Top bar
/// `[🗑 ลบ][✏️]`; "เก็บถาวร" is the quiet button at the bottom.
class BudgetDetailPage extends StatelessWidget {
  const BudgetDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<BudgetsCubit, BudgetsState>(
      builder: (context, state) {
        final budget = context.read<BudgetsCubit>().byId(id);
        if (budget != null) return _Loaded(budget: budget);
        return Scaffold(
          appBar: AppTopBar(title: l.budgetsTitle, showBack: true),
          body: state.status == BudgetsStatus.loading
              ? const LoadingView()
              : EmptyView(
                  icon: AppIcons.empty,
                  title: l.budgetDetailNotFound,
                  message: l.budgetDetailNotFoundMessage,
                ),
        );
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.budget});
  final Budget budget;

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    required Future<void> Function(BudgetsCubit) run,
  }) async {
    final ok = await showConfirmDialog(
      context,
      title: title,
      message: body,
      confirmLabel: action,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final router = GoRouter.of(context);
    try {
      await run(context.read<BudgetsCubit>());
      if (router.canPop()) router.pop();
    } on ApiException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cp = budget.currentPeriod;
    final over = cp?.overLimit ?? false;
    final pct = cp?.utilizationPct ?? 0;
    final accent = budgetAccent(context, budget);
    final category = budget.category?.name ?? '';
    final hasDesc = budget.description?.isNotEmpty ?? false;
    final title =
        hasDesc ? budget.description! : (category.isEmpty ? l.budgetDetailFallbackTitle : category);
    final subtitle = [
      if (hasDesc && category.isNotEmpty) category,
      budgetPeriodLabel(l, budget.period),
    ].join(' · ');

    return Scaffold(
      appBar: AppTopBar(
        title: title,
        showBack: true,
        actions: [
          AppBarAction(
            icon: AppIcons.delete,
            tooltip: l.budgetDetailDelete,
            destructive: true,
            onPressed: () => _confirmAndRun(
              context,
              title: l.budgetDeleteConfirmTitle,
              body: l.budgetDeleteConfirmBody,
              action: l.budgetDeleteConfirmAction,
              run: (c) => c.remove(budget.id),
            ),
          ),
          AppBarAction(
            icon: AppIcons.edit,
            tooltip: l.budgetDetailEdit,
            onPressed: () => context.push('/budgets/${budget.id}/edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
        children: [
          HeaderCard(
            accent: accent,
            leading: IconDisplay(
                type: IconType.category, size: 52, iconCode: budget.iconCode),
            title: Text(title),
            subtitle: Text(subtitle),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoneyText(
                  cp?.spent ?? 0,
                  style: textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: accent),
                ),
                Text(l.budgetDetailOfLimit(moneyString(context, budget.amount)),
                    style: textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                ProgressRow(
                  value: pct / 100,
                  color: accent,
                  label: cp == null
                      ? null
                      : l.budgetDetailRemainingLine(moneyString(context, cp.remaining)),
                  trailing: '${pct.toStringAsFixed(0)}%',
                ),
                if (cp != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.budgetDetailPeriodRange(cp.start, cp.end),
                      style: textTheme.bodySmall),
                ],
                if (over) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(AppIcons.warning, color: scheme.error, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(l.budgetDetailOverLimitWarning,
                            style: textTheme.bodySmall
                                ?.copyWith(color: scheme.error)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (budget.childBreakdown.isNotEmpty)
            SectionCard(
              title: l.budgetDetailBreakdownTitle,
              children: [
                for (final row in budget.childBreakdown)
                  DetailRow(label: row.name, trailing: MoneyText(row.spent)),
              ],
            ),
          if (budget.note?.isNotEmpty ?? false)
            SectionCard(
              children: [
                DetailStacked(
                    label: l.accountDetailNote, child: Text(budget.note!)),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: AppButton(
              label: l.budgetDetailArchive,
              icon: AppIcons.archive,
              variant: AppButtonVariant.text,
              onPressed: () => _confirmAndRun(
                context,
                title: l.budgetArchiveConfirmTitle,
                body: l.budgetArchiveConfirmBody,
                action: l.budgetArchiveConfirmAction,
                run: (c) => c.archive(budget.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
