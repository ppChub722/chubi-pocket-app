import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../domain/saving_goal.dart';
import '../cubit/saving_goals_cubit.dart';

/// `/saving-goals/:id` — read-only detail page.
///
/// Shows the hero progress + linked-account ref + numeric stats; the
/// overflow menu offers Edit / Archive / Delete. Restoring an archived
/// goal lives elsewhere (archived list view, deferred to the list page's
/// status filter once archived browsing ships).
class SavingGoalDetailPage extends StatelessWidget {
  const SavingGoalDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavingGoalsCubit, SavingGoalsState>(
      builder: (context, state) {
        if (state.goals.isEmpty &&
            state.status == SavingGoalsStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final goal = context.read<SavingGoalsCubit>().byId(id);
        if (goal == null) return _NotFoundScaffold();
        return _LoadedScaffold(goal: goal);
      },
    );
  }
}

class _NotFoundScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: EmptyView(
        icon: Icons.find_in_page_outlined,
        title: l.savingGoalDetailNotFound,
        message: l.savingGoalDetailNotFoundMessage,
      ),
    );
  }
}

class _LoadedScaffold extends StatelessWidget {
  const _LoadedScaffold({required this.goal});
  final SavingGoal goal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          PopupMenuButton<_OverflowAction>(
            onSelected: (action) => _onMenuAction(context, l, action),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _OverflowAction.edit,
                child: Row(children: [
                  const Icon(Icons.edit_outlined),
                  const SizedBox(width: AppSpacing.md),
                  Text(l.savingGoalDetailEdit),
                ]),
              ),
              PopupMenuItem(
                value: _OverflowAction.archive,
                child: Row(children: [
                  const Icon(Icons.archive_outlined),
                  const SizedBox(width: AppSpacing.md),
                  Text(l.savingGoalDetailArchive),
                ]),
              ),
              PopupMenuItem(
                value: _OverflowAction.delete,
                child: Row(children: [
                  const Icon(Icons.delete_outline),
                  const SizedBox(width: AppSpacing.md),
                  Text(l.savingGoalDetailDelete),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Hero(goal: goal),
          const SizedBox(height: AppSpacing.lg),
          _StatsCard(goal: goal),
          if (goal.note != null && goal.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _NoteCard(note: goal.note!),
          ],
        ],
      ),
    );
  }

  Future<void> _onMenuAction(
    BuildContext context,
    AppLocalizations l,
    _OverflowAction action,
  ) async {
    switch (action) {
      case _OverflowAction.edit:
        context.push('/saving-goals/${goal.id}/edit');
      case _OverflowAction.archive:
        await _confirmAndRun(
          context,
          l,
          title: l.savingGoalArchiveConfirmTitle,
          body: l.savingGoalArchiveConfirmBody,
          action: l.savingGoalArchiveConfirmAction,
          run: (cubit) => cubit.archive(goal.id),
        );
      case _OverflowAction.delete:
        await _confirmAndRun(
          context,
          l,
          title: l.savingGoalDeleteConfirmTitle,
          body: l.savingGoalDeleteConfirmBody,
          action: l.savingGoalDeleteConfirmAction,
          run: (cubit) => cubit.remove(goal.id),
        );
    }
  }

  Future<void> _confirmAndRun(
    BuildContext context,
    AppLocalizations l, {
    required String title,
    required String body,
    required String action,
    required Future<void> Function(SavingGoalsCubit cubit) run,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final cubit = context.read<SavingGoalsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await run(cubit);
      if (router.canPop()) router.pop();
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

enum _OverflowAction { edit, archive, delete }

class _Hero extends StatelessWidget {
  const _Hero({required this.goal});
  final SavingGoal goal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = goal.iconCode?.accentColorFor(palette) ?? scheme.primary;
    final progress = (goal.progressPct / 100).clamp(0.0, 1.0);
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconDisplay(
                  type: IconType.account,
                  size: 56,
                  iconCode: goal.iconCode,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (goal.linkedAccount != null)
                        Text(
                          goal.linkedAccount!.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              CurrencyFormatter.format(goal.currentAmount),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              l.savingGoalDetailOfTarget(
                CurrencyFormatter.format(goal.targetAmount),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.progressPct.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (goal.isCompleted)
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: accent, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l.savingGoalCompletedLabel,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.goal});
  final SavingGoal goal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow(
              icon: Icons.percent,
              label: l.savingGoalDetailAllocation,
              value: '${goal.allocationPct.toStringAsFixed(1)}%',
            ),
            _StatRow(
              icon: Icons.savings_outlined,
              label: l.savingGoalDetailRemaining,
              value: CurrencyFormatter.format(goal.remainingAmount),
            ),
            if (goal.deadline != null)
              _StatRow(
                icon: Icons.event_outlined,
                label: l.savingGoalDetailDeadline,
                value: goal.deadline!,
              ),
            if (goal.daysRemaining != null)
              _StatRow(
                icon: Icons.timer_outlined,
                label: l.savingGoalDetailDaysRemaining,
                value: l.savingGoalDetailDaysValue(goal.daysRemaining!),
              ),
            if (goal.requiredMonthly != null)
              _StatRow(
                icon: Icons.trending_up,
                label: l.savingGoalDetailRequiredMonthly,
                value: CurrencyFormatter.format(goal.requiredMonthly!),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.sticky_note_2_outlined,
                size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                note,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
