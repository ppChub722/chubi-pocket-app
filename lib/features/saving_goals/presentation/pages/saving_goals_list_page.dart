import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../cubit/saving_goals_cubit.dart';
import '../widgets/saving_goal_card.dart';

/// `/saving-goals` — entry point from the More menu (Phase 1c).
///
/// Outside the bottom-nav shell — owns its own Scaffold + AppBar with a
/// back button (matches `/personal-debts`, `/contacts`, `/projects`
/// convention). The `+` action in the AppBar pushes the create form.
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
      if (!mounted) return;
      context.read<SavingGoalsCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.savingGoalsTitle),
        actions: [
          IconButton(
            tooltip: l.savingGoalsAddNew,
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/saving-goals/new'),
          ),
        ],
      ),
      body: BlocConsumer<SavingGoalsCubit, SavingGoalsState>(
        listenWhen: (a, b) =>
            a.errorMessage != b.errorMessage && b.errorMessage != null,
        listener: (ctx, state) {
          ScaffoldMessenger.of(ctx)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          if (state.status == SavingGoalsStatus.loading &&
              state.goals.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.goals.isEmpty) {
            return EmptyView(
              icon: Icons.flag_outlined,
              title: l.savingGoalsEmptyTitle,
              message: l.savingGoalsEmptyMessage,
              cta: FilledButton.icon(
                onPressed: () => context.push('/saving-goals/new'),
                icon: const Icon(Icons.add),
                label: Text(l.savingGoalsAddNew),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<SavingGoalsCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.huge,
              ),
              itemCount: state.goals.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final goal = state.goals[i];
                return SavingGoalCard(
                  goal: goal,
                  onTap: () => context.push('/saving-goals/${goal.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
