import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
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

  void _add() => context.push('/scheduled-transactions/new');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.scheduledTitle, showBack: true),
      body: BlocConsumer<ScheduledTransactionsCubit, ScheduledTransactionsState>(
        listenWhen: (a, b) =>
            a.errorMessage != b.errorMessage && b.errorMessage != null,
        listener: (ctx, s) =>
            showAppSnackBar(ctx, s.errorMessage!, tone: Tone.danger),
        builder: (context, state) {
          if (state.status == ScheduledTransactionsStatus.loading &&
              state.entries.isEmpty) {
            return ListView(children: [
              for (var i = 0; i < 4; i++) const SkeletonListTile(),
            ]);
          }
          if (state.entries.isEmpty) {
            return EmptyView(
              icon: AppIcons.scheduled,
              title: l.scheduledEmptyTitle,
              message: l.scheduledEmptyMessage,
              cta: AddTile(label: l.scheduledAddNew, onTap: _add),
            );
          }
          return PullToRefresh(
            onRefresh: () => context.read<ScheduledTransactionsCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
              children: [
                for (final e in state.entries) ...[
                  ScheduledCard(
                    entry: e,
                    onTap: () => context.push('/scheduled-transactions/${e.id}'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AddTile(label: l.scheduledAddNew, onTap: _add),
              ],
            ),
          );
        },
      ),
    );
  }
}
