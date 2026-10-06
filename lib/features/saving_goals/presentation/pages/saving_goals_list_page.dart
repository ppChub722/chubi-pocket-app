import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
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
      body: BlocConsumer<SavingGoalsCubit, SavingGoalsState>(
        listenWhen: (a, b) =>
            a.errorMessage != b.errorMessage && b.errorMessage != null,
        listener: (ctx, s) =>
            showAppSnackBar(ctx, s.errorMessage!, tone: Tone.danger),
        builder: (context, state) {
          if (state.status == SavingGoalsStatus.loading && state.goals.isEmpty) {
            return ListView(children: [
              for (var i = 0; i < 3; i++) const SkeletonListTile(),
            ]);
          }
          if (state.goals.isEmpty) {
            return EmptyView(
              icon: AppIcons.savingGoal,
              title: l.savingGoalsEmptyTitle,
              message: l.savingGoalsEmptyMessage,
              cta: AddTile(label: l.savingGoalsAddNew, onTap: _add),
            );
          }
          return PullToRefresh(
            onRefresh: () => context.read<SavingGoalsCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
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
          );
        },
      ),
    );
  }
}
