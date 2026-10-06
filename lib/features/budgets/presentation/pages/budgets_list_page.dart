import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../cubit/budgets_cubit.dart';
import '../widgets/budget_card.dart';

/// `/budgets` — user-scope budgets as cards with a dashed "+ เพิ่มงบ" at
/// the end (§1.2 card page — no top-bar add). Project budgets live on the
/// project.
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
      if (mounted) context.read<BudgetsCubit>().loadIfNeeded();
    });
  }

  void _add() => context.push('/budgets/new');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.budgetsTitle, showBack: true),
      body: BlocConsumer<BudgetsCubit, BudgetsState>(
        listenWhen: (a, b) =>
            a.errorMessage != b.errorMessage && b.errorMessage != null,
        listener: (ctx, s) =>
            showAppSnackBar(ctx, s.errorMessage!, tone: Tone.danger),
        builder: (context, state) {
          if (state.status == BudgetsStatus.loading && state.budgets.isEmpty) {
            return ListView(children: [
              for (var i = 0; i < 4; i++) const SkeletonListTile(),
            ]);
          }
          if (state.budgets.isEmpty) {
            return EmptyView(
              icon: AppIcons.budget,
              title: l.budgetsEmptyTitle,
              message: l.budgetsEmptyMessage,
              cta: AddTile(label: l.budgetsAddNew, onTap: _add),
            );
          }
          return PullToRefresh(
            onRefresh: () => context.read<BudgetsCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
              children: [
                for (final b in state.budgets) ...[
                  BudgetCard(
                    budget: b,
                    onTap: () => context.push('/budgets/${b.id}'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AddTile(label: l.budgetsAddNew, onTap: _add),
              ],
            ),
          );
        },
      ),
    );
  }
}
