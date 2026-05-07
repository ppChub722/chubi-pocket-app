import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../cubit/budgets_cubit.dart';
import '../widgets/budget_card.dart';

/// `/budgets` — entry point from the More menu (Phase 1c).
///
/// Renders user-scope budgets only — project-scope budgets live inside
/// the project detail page so members see them in context.
class BudgetsListPage extends StatefulWidget {
  const BudgetsListPage({super.key});

  @override
  State<BudgetsListPage> createState() => _BudgetsListPageState();
}

class _BudgetsListPageState extends State<BudgetsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BudgetsCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.budgetsTitle),
        actions: [
          IconButton(
            tooltip: l.budgetsAddNew,
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/budgets/new'),
          ),
        ],
      ),
      body: BlocConsumer<BudgetsCubit, BudgetsState>(
        listenWhen: (a, b) =>
            a.errorMessage != b.errorMessage && b.errorMessage != null,
        listener: (ctx, state) {
          ScaffoldMessenger.of(ctx)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          if (state.status == BudgetsStatus.loading &&
              state.budgets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.budgets.isEmpty) {
            return EmptyView(
              icon: Icons.savings_outlined,
              title: l.budgetsEmptyTitle,
              message: l.budgetsEmptyMessage,
              cta: FilledButton.icon(
                onPressed: () => context.push('/budgets/new'),
                icon: const Icon(Icons.add),
                label: Text(l.budgetsAddNew),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<BudgetsCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.huge,
              ),
              itemCount: state.budgets.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final budget = state.budgets[i];
                return BudgetCard(
                  budget: budget,
                  onTap: () => context.push('/budgets/${budget.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
