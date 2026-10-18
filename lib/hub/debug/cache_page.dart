import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/bloc/clearable_cubit.dart';
import '../../features/accounts/presentation/cubit/accounts_cubit.dart';
import '../../features/accounts/presentation/cubit/providers_cubit.dart';
import '../../features/personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../../features/projects/presentation/cubit/project_directory_cubit.dart';
import '../../features/recurring/presentation/cubit/recurring_directory_cubit.dart';
import '../../features/transactions/presentation/cubit/form_defaults_cubit.dart';
import '../../features/budgets/presentation/cubit/budgets_cubit.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/contacts/presentation/cubit/contacts_cubit.dart';
import '../../features/home/presentation/cubit/dashboard_cubit.dart';
import '../../features/notifications/presentation/cubit/unread_badge_cubit.dart';
import '../../features/pending/presentation/cubit/pending_cubit.dart';
import '../../features/projects/presentation/cubit/projects_cubit.dart';
import '../../features/saving_goals/presentation/cubit/saving_goals_cubit.dart';
import '../../features/tags/presentation/cubit/tags_cubit.dart';
import '../../features/transactions/presentation/cubit/transactions_cubit.dart';
import '../../ui/ui.dart';

/// `/dev/debug/cache` — what the app is holding in memory: every app-wide
/// store (cubit) with its load status and how many items it caches. Reload
/// re-fetches that store from the server (a read); Clear empties it locally
/// (the next page that needs it loads it again). Nothing here writes server
/// data.
class CachePage extends StatefulWidget {
  const CachePage({super.key});

  @override
  State<CachePage> createState() => _CachePageState();
}

class _Entry {
  const _Entry({
    required this.name,
    required this.what,
    required this.status,
    required this.count,
    required this.reload,
    required this.clear,
  });

  final String name;
  final String what;
  final String status;
  final String count;
  final Future<void> Function()? reload;
  final VoidCallback clear;
}

class _CachePageState extends State<CachePage> {
  final Set<String> _busy = {};

  List<_Entry> _entries(BuildContext context) {
    final r = context.read;
    final w = context.watch;

    _Entry list<C extends Cubit<S>, S>({
      required String name,
      required String what,
      required String Function(S s) status,
      required int Function(S s) count,
      Future<void> Function(C c)? load,
    }) {
      final c = r<C>();
      final s = w<C>().state;
      return _Entry(
        name: name,
        what: what,
        status: status(s),
        count: '${count(s)}',
        reload: load == null ? null : () => load(c),
        clear: () => (c as Clearable).clear(),
      );
    }

    return [
      list<AccountsCubit, AccountsState>(
        name: 'Accounts',
        what: 'active wallets',
        status: (s) => s.status.name,
        count: (s) => s.accounts.length,
        load: (c) => c.load(),
      ),
      list<CategoriesCubit, CategoriesState>(
        name: 'Categories',
        what: 'the category tree (names, icons, system flags)',
        status: (s) => s.status.name,
        count: (s) => s.categories.length,
        load: (c) => c.load(),
      ),
      list<TagsCubit, TagsState>(
        name: 'Tags',
        what: 'tags',
        status: (s) => s.status.name,
        count: (s) => s.tags.length,
        load: (c) => c.load(),
      ),
      list<DebtDirectoryCubit, DebtDirectoryState>(
        name: 'Debt people',
        what: 'everyone with a debt entry, settled included (shared dataset)',
        status: (s) => s.status.name,
        count: (s) => s.people.length,
        load: (c) => c.load(),
      ),
      list<ProjectDirectoryCubit, ProjectDirectoryState>(
        name: 'Event directory',
        what: 'every event the pickers choose from (shared dataset)',
        status: (s) => s.status.name,
        count: (s) => s.projects.length,
        load: (c) => c.load(),
      ),
      list<RecurringDirectoryCubit, RecurringDirectoryState>(
        name: 'Recurring directory',
        what: 'every recurring setting (shared dataset)',
        status: (s) => s.status.name,
        count: (s) => s.rules.length,
        load: (c) => c.load(),
      ),
      list<FormDefaultsCubit, FormDefaultsState>(
        name: 'Form defaults',
        what: 'the default wallet and fee category (shared dataset)',
        status: (s) => s.status.name,
        count: (s) => s.status == FormDefaultsStatus.loaded ? 1 : 0,
        load: (c) => c.loadIfNeeded(),
      ),
      list<ProvidersCubit, ProvidersState>(
        name: 'Payment providers',
        what: 'banks and e-wallets (shared dataset)',
        status: (s) => s.status.name,
        count: (s) => s.providers.length,
        load: (c) => c.loadIfNeeded(),
      ),
      list<TransactionsCubit, TransactionsState>(
        name: 'Transactions',
        what: 'the transactions list on screen (paged)',
        status: (s) => s.status.name,
        count: (s) => s.transactions.length,
        load: (c) => c.load(),
      ),
      list<ContactsCubit, ContactsState>(
        name: 'Contacts',
        what: 'contacts (status filter applies)',
        status: (s) => s.status.name,
        count: (s) => s.contacts.length,
        load: (c) => c.load(),
      ),
      list<ProjectsCubit, ProjectsState>(
        name: 'Events',
        what: 'events (status filter applies)',
        status: (s) => s.status.name,
        count: (s) => s.projects.length,
        load: (c) => c.load(),
      ),
      list<SavingGoalsCubit, SavingGoalsState>(
        name: 'Saving goals',
        what: 'saving goals',
        status: (s) => s.status.name,
        count: (s) => s.goals.length,
        load: (c) => c.load(),
      ),
      list<BudgetsCubit, BudgetsState>(
        name: 'Budgets',
        what: 'budgets',
        status: (s) => s.status.name,
        count: (s) => s.budgets.length,
        load: (c) => c.load(),
      ),
      list<DashboardCubit, DashboardState>(
        name: 'Dashboard',
        what: 'the home summary (one object)',
        status: (s) => s.status.name,
        count: (s) => s.data == null ? 0 : 1,
        load: (c) => c.load(),
      ),
      list<PendingCubit, PendingState>(
        name: 'Pending',
        what: 'drafts waiting to be confirmed',
        status: (s) => s.status.name,
        count: (s) => s.items.length,
        load: (c) => c.load(),
      ),
      _Entry(
        name: 'Unread badge',
        what: 'the bell count (polled every 30 s)',
        status: 'polling',
        count: '${w<UnreadBadgeCubit>().state}',
        reload: () => r<UnreadBadgeCubit>().refresh(),
        clear: () => r<UnreadBadgeCubit>().clear(),
      ),
    ];
  }

  Future<void> _reload(_Entry e) async {
    setState(() => _busy.add(e.name));
    try {
      await e.reload?.call();
    } finally {
      if (mounted) setState(() => _busy.remove(e.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache'),
        actions: [
          TextButton(
            onPressed: () {
              for (final e in entries) {
                e.clear();
              }
            },
            child: const Text('Clear all'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        children: [
          Text(
            'In-memory stores shared across pages. A page that opens with a '
            'loaded store shows it at once (no request); an empty store loads '
            'on first use. Reload re-reads from the server; Clear empties it '
            'locally.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(e.name, style: text.titleSmall),
                              const SizedBox(width: AppSpacing.sm),
                              AppChip(
                                label: e.status,
                                size: ChipSize.mini,
                                selected: true,
                                tone: switch (e.status) {
                                  'loaded' || 'polling' => AppChipTone.success,
                                  'error' => AppChipTone.danger,
                                  'loading' => AppChipTone.info,
                                  _ => AppChipTone.neutral,
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${e.count} · ${e.what}',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (e.reload != null)
                      _busy.contains(e.name)
                          ? const Padding(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              child: AppSpinner(size: AppSpinnerSize.small),
                            )
                          : IconButton(
                              tooltip: 'Reload',
                              icon: const Icon(AppIcons.refresh),
                              onPressed: () => unawaited(_reload(e)),
                            ),
                    IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(AppIcons.clear),
                      onPressed: e.clear,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
