import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../cubit/scheduled_transactions_cubit.dart';
import '../widgets/scheduled_card.dart';

/// `/scheduled-transactions` — entry point from the More menu (Phase 1c).
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
      if (!mounted) return;
      context.read<ScheduledTransactionsCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.scheduledTitle),
        actions: [
          IconButton(
            tooltip: l.scheduledAddNew,
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/scheduled-transactions/new'),
          ),
        ],
      ),
      body:
          BlocConsumer<ScheduledTransactionsCubit, ScheduledTransactionsState>(
        listenWhen: (a, b) =>
            a.errorMessage != b.errorMessage && b.errorMessage != null,
        listener: (ctx, state) {
          ScaffoldMessenger.of(ctx)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          if (state.status == ScheduledTransactionsStatus.loading &&
              state.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.entries.isEmpty) {
            return EmptyView(
              icon: Icons.schedule_outlined,
              title: l.scheduledEmptyTitle,
              message: l.scheduledEmptyMessage,
              cta: FilledButton.icon(
                onPressed: () =>
                    context.push('/scheduled-transactions/new'),
                icon: const Icon(Icons.add),
                label: Text(l.scheduledAddNew),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                context.read<ScheduledTransactionsCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.huge,
              ),
              itemCount: state.entries.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final entry = state.entries[i];
                return ScheduledCard(
                  entry: entry,
                  onTap: () => context.push(
                    '/scheduled-transactions/${entry.id}',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
