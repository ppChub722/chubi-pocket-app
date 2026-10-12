import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
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
              builder: (context, state) => ListPageBody(
                // Only the FIRST load shows the skeleton: a reload keeps the
                // rows (a skeleton would kill a pull-to-refresh).
                loading:
                    (state.status == ScheduledTransactionsStatus.initial ||
                        state.status == ScheduledTransactionsStatus.loading) &&
                    state.entries.isEmpty,
                error: state.entries.isEmpty ? state.error : null,
                isEmpty: state.entries.isEmpty,
                onRetry: context.read<ScheduledTransactionsCubit>().load,
                topInset: AppSpacing.md,
                empty: EmptyView(
                  icon: AppIcons.scheduled,
                  title: l.scheduledEmptyTitle,
                  message: l.scheduledEmptyMessage,
                  cta: AddTile(label: l.scheduledAddNew, onTap: _add),
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
    );
  }
}
