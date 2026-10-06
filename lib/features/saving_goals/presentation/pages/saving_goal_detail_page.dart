import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/saving_goal.dart';
import '../cubit/saving_goals_cubit.dart';

/// `/saving-goals/:id`: header (current big, target, progress, completed)
/// → stats (allocation, remaining, deadline, days left, per month) →
/// note. Top bar `[🗑 ลบ][✏️]`; "เก็บถาวร" is the quiet bottom button.
class SavingGoalDetailPage extends StatelessWidget {
  const SavingGoalDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<SavingGoalsCubit, SavingGoalsState>(
      builder: (context, state) {
        final goal = context.read<SavingGoalsCubit>().byId(id);
        if (goal != null) return _Loaded(goal: goal);
        return Scaffold(
          appBar: AppTopBar(title: l.savingGoalsTitle, showBack: true),
          body: state.status == SavingGoalsStatus.loading
              ? const LoadingView()
              : EmptyView(
                  icon: AppIcons.empty,
                  title: l.savingGoalDetailNotFound,
                  message: l.savingGoalDetailNotFoundMessage,
                ),
        );
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.goal});
  final SavingGoal goal;

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    required Future<void> Function(SavingGoalsCubit) run,
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
      await run(context.read<SavingGoalsCubit>());
      if (router.canPop()) router.pop();
    } on ApiException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final accent = goal.iconCode?.accentColorFor(palette) ?? palette.primary;
    final g = goal;
    return Scaffold(
      appBar: AppTopBar(
        title: g.name,
        showBack: true,
        actions: [
          AppBarAction(
            icon: AppIcons.delete,
            tooltip: l.savingGoalDetailDelete,
            destructive: true,
            onPressed: () => _confirmAndRun(
              context,
              title: l.savingGoalDeleteConfirmTitle,
              body: l.savingGoalDeleteConfirmBody,
              action: l.savingGoalDeleteConfirmAction,
              run: (c) => c.remove(g.id),
            ),
          ),
          AppBarAction(
            icon: AppIcons.edit,
            tooltip: l.savingGoalDetailEdit,
            onPressed: () => context.push('/saving-goals/${g.id}/edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
        children: [
          HeaderCard(
            accent: accent,
            leading:
                IconDisplay(type: IconType.account, size: 52, iconCode: g.iconCode),
            title: Text(g.name),
            subtitle: g.linkedAccount == null ? null : Text(g.linkedAccount!.name),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoneyText(
                  g.currentAmount,
                  style: textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: accent),
                ),
                Text(l.savingGoalDetailOfTarget(moneyString(context, g.targetAmount)),
                    style: textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                ProgressRow(
                  value: g.progressPct / 100,
                  color: accent,
                  trailing: '${g.progressPct.toStringAsFixed(0)}%',
                ),
                if (g.isCompleted) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppBadge(
                      label: l.savingGoalCompletedLabel,
                      icon: AppIcons.success,
                      tone: Tone.success,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SectionCard(
            children: [
              DetailRow(
                label: l.savingGoalDetailAllocation,
                trailing: Text('${g.allocationPct.toStringAsFixed(0)}%'),
              ),
              const RowDivider(),
              DetailRow(
                label: l.savingGoalDetailRemaining,
                trailing: MoneyText(g.remainingAmount),
              ),
              if (g.deadline != null) ...[
                const RowDivider(),
                DetailRow(
                  leading: const Icon(AppIcons.date),
                  label: l.savingGoalDetailDeadline,
                  trailing: Text(g.deadline!),
                ),
              ],
              if (g.daysRemaining != null) ...[
                const RowDivider(),
                DetailRow(
                  label: l.savingGoalDetailDaysRemaining,
                  trailing: Text(l.savingGoalDetailDaysValue(g.daysRemaining!)),
                ),
              ],
              if (g.requiredMonthly != null) ...[
                const RowDivider(),
                DetailRow(
                  label: l.savingGoalDetailRequiredMonthly,
                  trailing: MoneyText(g.requiredMonthly!),
                ),
              ],
              if (g.note?.isNotEmpty ?? false) ...[
                const RowDivider(),
                DetailStacked(label: l.accountDetailNote, child: Text(g.note!)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: AppButton(
              label: l.savingGoalDetailArchive,
              icon: AppIcons.archive,
              variant: AppButtonVariant.text,
              onPressed: () => _confirmAndRun(
                context,
                title: l.savingGoalArchiveConfirmTitle,
                body: l.savingGoalArchiveConfirmBody,
                action: l.savingGoalArchiveConfirmAction,
                run: (c) => c.archive(g.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
