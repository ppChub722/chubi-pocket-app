import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../cubit/scheduled_transactions_cubit.dart';
import '../widgets/scheduled_card.dart';

/// `/scheduled-transactions` — schedule cards with a dashed "+ เพิ่ม" at the
/// end (§1.2 card page — no top-bar add).
class ScheduledTransactionsListPage extends StatefulWidget {
  const ScheduledTransactionsListPage({super.key});

  @override
  State<ScheduledTransactionsListPage> createState() =>
      _ScheduledTransactionsListPageState();
}

class _ScheduledTransactionsListPageState
    extends State<ScheduledTransactionsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ScheduledTransactionsCubit>().loadIfNeeded();
    });
  }

  /// Creating goes through the quick create sheet (scheduled mode).
  void _add() => showQuickCreateSheet(context, scheduled: true);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.scheduledTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child:
            BlocBuilder<ScheduledTransactionsCubit, ScheduledTransactionsState>(
              builder: (context, state) => AsyncStateView(
                loading:
                    state.status == ScheduledTransactionsStatus.initial ||
                    state.status == ScheduledTransactionsStatus.loading,
                error: state.error,
                isEmpty: state.entries.isEmpty,
                onRetry: context.read<ScheduledTransactionsCubit>().load,
                skeleton: ListView(
                  children: [
                    for (var i = 0; i < 4; i++) const SkeletonListTile(),
                  ],
                ),
                empty: EmptyView(
                  icon: AppIcons.scheduled,
                  title: l.scheduledEmptyTitle,
                  message: l.scheduledEmptyMessage,
                  cta: AddTile(label: l.scheduledAddNew, onTap: _add),
                ),
                builder: (context) => PullToRefresh(
                  onRefresh: () =>
                      context.read<ScheduledTransactionsCubit>().load(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    // Top: clear the transparent top bar.
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      MediaQuery.paddingOf(context).top + AppSpacing.md,
                      AppSpacing.lg,
                      96 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      for (final e in state.entries) ...[
                        ScheduledCard(
                          entry: e,
                          onTap: () =>
                              context.push('/scheduled-transactions/${e.id}'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      AddTile(label: l.scheduledAddNew, onTap: _add),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
