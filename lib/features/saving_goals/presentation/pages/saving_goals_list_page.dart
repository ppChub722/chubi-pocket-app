import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../cubit/saving_goals_cubit.dart';
import '../widgets/saving_goal_card.dart';

/// `/saving-goals` — goal cards with a dashed "+ เพิ่มเป้าหมาย" at the end
/// (§1.2 card page — no top-bar add).
class SavingGoalsListPage extends StatefulWidget {
  const SavingGoalsListPage({super.key});

  @override
  State<SavingGoalsListPage> createState() => _SavingGoalsListPageState();
}

class _SavingGoalsListPageState extends State<SavingGoalsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SavingGoalsCubit>().loadIfNeeded();
    });
  }

  void _add() => context.push('/saving-goals/new');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.savingGoalsTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: BlocBuilder<SavingGoalsCubit, SavingGoalsState>(
          builder: (context, state) => ListPageBody(
            // Only the FIRST load shows the skeleton: a reload keeps the rows
            // (a skeleton would kill a pull-to-refresh).
            loading:
                (state.status == SavingGoalsStatus.initial ||
                    state.status == SavingGoalsStatus.loading) &&
                state.goals.isEmpty,
            error: state.goals.isEmpty ? state.error : null,
            isEmpty: state.goals.isEmpty,
            onRetry: context.read<SavingGoalsCubit>().load,
            topInset: AppSpacing.md,
            empty: EmptyView(
              icon: AppIcons.savingGoal,
              title: l.savingGoalsEmptyTitle,
              message: l.savingGoalsEmptyMessage,
              cta: AddTile(label: l.savingGoalsAddNew, onTap: _add),
            ),
            children: [
              for (final g in state.goals) ...[
                SavingGoalCard(
                  goal: g,
                  onTap: () => context.push('/saving-goals/${g.id}'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AddTile(label: l.savingGoalsAddNew, onTap: _add),
            ],
          ),
        ),
      ),
    );
  }
}
