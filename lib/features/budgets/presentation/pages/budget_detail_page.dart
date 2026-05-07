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
import '../../domain/budget.dart';
import '../../domain/budget_period.dart';
import '../cubit/budgets_cubit.dart';

/// `/budgets/:id` — read-only detail. Hero progress + child breakdown +
/// overflow menu (Edit / Archive / Delete).
class BudgetDetailPage extends StatelessWidget {
  const BudgetDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetsCubit, BudgetsState>(
      builder: (context, state) {
        if (state.budgets.isEmpty &&
            state.status == BudgetsStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final budget = context.read<BudgetsCubit>().byId(id);
        if (budget == null) return _NotFoundScaffold();
        return _LoadedScaffold(budget: budget);
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
        title: l.budgetDetailNotFound,
        message: l.budgetDetailNotFoundMessage,
      ),
    );
  }
}

class _LoadedScaffold extends StatelessWidget {
  const _LoadedScaffold({required this.budget});
  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Description wins as the page title when set; otherwise fall back
    // to the linked category name (then a generic label as last resort).
    final headerTitle = (budget.description?.isNotEmpty ?? false)
        ? budget.description!
        : (budget.category?.name ?? l.budgetDetailFallbackTitle);
    return Scaffold(
      appBar: AppBar(
        title: Text(headerTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<_OverflowAction>(
            onSelected: (action) => _onMenuAction(context, l, action),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _OverflowAction.edit,
                child: Row(children: [
                  const Icon(Icons.edit_outlined),
                  const SizedBox(width: AppSpacing.md),
                  Text(l.budgetDetailEdit),
                ]),
              ),
              PopupMenuItem(
                value: _OverflowAction.archive,
                child: Row(children: [
                  const Icon(Icons.archive_outlined),
                  const SizedBox(width: AppSpacing.md),
                  Text(l.budgetDetailArchive),
                ]),
              ),
              PopupMenuItem(
                value: _OverflowAction.delete,
                child: Row(children: [
                  const Icon(Icons.delete_outline),
                  const SizedBox(width: AppSpacing.md),
                  Text(l.budgetDetailDelete),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Hero(budget: budget),
          if (budget.childBreakdown.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _ChildBreakdown(budget: budget),
          ],
          if (budget.note != null && budget.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _NoteCard(note: budget.note!),
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
        context.push('/budgets/${budget.id}/edit');
      case _OverflowAction.archive:
        await _confirmAndRun(
          context,
          l,
          title: l.budgetArchiveConfirmTitle,
          body: l.budgetArchiveConfirmBody,
          action: l.budgetArchiveConfirmAction,
          run: (cubit) => cubit.archive(budget.id),
        );
      case _OverflowAction.delete:
        await _confirmAndRun(
          context,
          l,
          title: l.budgetDeleteConfirmTitle,
          body: l.budgetDeleteConfirmBody,
          action: l.budgetDeleteConfirmAction,
          run: (cubit) => cubit.remove(budget.id),
        );
    }
  }

  Future<void> _confirmAndRun(
    BuildContext context,
    AppLocalizations l, {
    required String title,
    required String body,
    required String action,
    required Future<void> Function(BudgetsCubit cubit) run,
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
    final cubit = context.read<BudgetsCubit>();
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
  const _Hero({required this.budget});
  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final cp = budget.currentPeriod;
    final overLimit = cp?.overLimit ?? false;
    final utilization = cp?.utilizationPct ?? 0;
    final accent = overLimit
        ? scheme.error
        : utilization >= 80
            ? Colors.orange
            : (budget.iconCode?.accentColorFor(palette) ?? scheme.primary);
    final progress = (utilization / 100).clamp(0.0, 1.0);

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
                  type: IconType.category,
                  size: 56,
                  iconCode: budget.iconCode,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _HeroTitle(budget: budget),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              CurrencyFormatter.format(cp?.spent ?? 0),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              l.budgetDetailOfLimit(
                CurrencyFormatter.format(budget.amount),
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
                  '${utilization.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (cp != null)
                  Text(
                    l.budgetDetailRemainingLine(
                      CurrencyFormatter.format(cp.remaining),
                    ),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            if (cp != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l.budgetDetailPeriodRange(cp.start, cp.end),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (overLimit) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: scheme.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l.budgetDetailOverLimitWarning,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.error,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

}

/// Two-line hero label: description (or category name) on top + a muted
/// secondary line that combines category + period when description is
/// set, or just the period otherwise.
class _HeroTitle extends StatelessWidget {
  const _HeroTitle({required this.budget});
  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final categoryName = budget.category?.name ?? '';
    final hasDescription =
        budget.description != null && budget.description!.isNotEmpty;
    final primary = hasDescription ? budget.description! : categoryName;
    final periodLabel = _periodLabelOf(l, budget.period);
    final secondary = hasDescription
        ? (categoryName.isEmpty
            ? periodLabel
            : '$categoryName · $periodLabel')
        : periodLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          primary,
          style: Theme.of(context).textTheme.titleLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          secondary,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

String _periodLabelOf(AppLocalizations l, BudgetPeriod p) {
  switch (p) {
    case BudgetPeriod.weekly:
      return l.budgetPeriodWeekly;
    case BudgetPeriod.monthly:
      return l.budgetPeriodMonthly;
    case BudgetPeriod.yearly:
      return l.budgetPeriodYearly;
  }
}

class _ChildBreakdown extends StatelessWidget {
  const _ChildBreakdown({required this.budget});
  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.budgetDetailBreakdownTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final row in budget.childBreakdown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(row.spent),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
