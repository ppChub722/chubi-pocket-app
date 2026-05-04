import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/personal_debt.dart';
import '../cubit/personal_debts_cubit.dart';

/// `/personal-debts` — main screen.
///
/// Two views (tabs): People (aggregated, default) / Items (flat list).
class PersonalDebtsPage extends StatefulWidget {
  const PersonalDebtsPage({super.key});

  @override
  State<PersonalDebtsPage> createState() => _PersonalDebtsPageState();
}

class _PersonalDebtsPageState extends State<PersonalDebtsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonalDebtsCubit>().loadPeople();
      context.read<PersonalDebtsCubit>().loadList();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal debts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New debt',
            onPressed: () => context.push('/personal-debts/new'),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'People'), Tab(text: 'Items')],
        ),
      ),
      body: BlocConsumer<PersonalDebtsCubit, PersonalDebtsState>(
        listenWhen: (a, b) => a.errorMessage != b.errorMessage,
        listener: (ctx, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(ctx)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (ctx, state) {
          return TabBarView(
            controller: _tabs,
            children: [
              _PeopleView(
                state: state,
                onPersonTap: (p) {
                  // Set the counterparty filter on cubit + switch to Items.
                  // Items view filters client-side via state.filteredDebts.
                  context.read<PersonalDebtsCubit>().setCounterpartyFilter(
                        CounterpartyFilter(
                          contactId: p.contactId,
                          displayName: p.displayName,
                        ),
                      );
                  _tabs.animateTo(1);
                },
              ),
              _ItemsView(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _PeopleView extends StatelessWidget {
  const _PeopleView({required this.state, required this.onPersonTap});
  final PersonalDebtsState state;
  final ValueChanged<PersonRow> onPersonTap;

  @override
  Widget build(BuildContext context) {
    final people = state.people;
    if (people == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () => context.read<PersonalDebtsCubit>().loadPeople(),
      child: ListView(
        children: [
          _Totals(
            owedToMe: people.totalOwedToMe,
            iOwe: people.totalIOwe,
            netPosition: people.netPosition,
          ),
          if (people.data.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No outstanding debts')),
            )
          else
            ...people.data.map((p) => _PersonRowTile(
                  person: p,
                  onTap: () => onPersonTap(p),
                )),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    required this.owedToMe,
    required this.iOwe,
    required this.netPosition,
  });
  final double owedToMe;
  final double iOwe;
  final double netPosition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _Col(
                    label: 'Owed to me',
                    value: owedToMe.toStringAsFixed(2),
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _Col(
                    label: 'I owe',
                    value: iOwe.toStringAsFixed(2),
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Net position', style: theme.textTheme.labelSmall),
            Text(
              netPosition.toStringAsFixed(2),
              style: theme.textTheme.titleLarge?.copyWith(
                color: netPosition >= 0 ? Colors.green : Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: color)),
      ],
    );
  }
}

class _PersonRowTile extends StatelessWidget {
  const _PersonRowTile({required this.person, required this.onTap});
  final PersonRow person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = person.theyOweMeNet
        ? Colors.green
        : person.iOweThemNet
            ? Colors.redAccent
            : theme.colorScheme.onSurface;
    final label = person.theyOweMeNet
        ? 'owes you'
        : person.iOweThemNet
            ? 'you owe'
            : 'even';

    return ListTile(
      leading: CircleAvatar(
        child: Text(
          person.displayName.isNotEmpty
              ? person.displayName[0].toUpperCase()
              : '?',
        ),
      ),
      title: Text(person.displayName),
      subtitle: Text(
        '${person.openCount} open · ${person.theyOweMeNet ? '+' : person.iOweThemNet ? '-' : ''}'
        '${person.netPosition.abs().toStringAsFixed(2)}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            person.netPosition.abs().toStringAsFixed(2),
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ItemsView extends StatelessWidget {
  const _ItemsView({required this.state});
  final PersonalDebtsState state;

  @override
  Widget build(BuildContext context) {
    final filtered = state.filteredDebts;
    return RefreshIndicator(
      onRefresh: () => context.read<PersonalDebtsCubit>().loadList(),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'i_owe', label: Text('I owe')),
                ButtonSegment(
                    value: 'owed_to_me', label: Text('Owed to me')),
              ],
              selected: {
                state.directionFilter == DebtDirection.iOwe
                    ? 'i_owe'
                    : state.directionFilter == DebtDirection.owedToMe
                        ? 'owed_to_me'
                        : 'all'
              },
              onSelectionChanged: (v) {
                final cubit = context.read<PersonalDebtsCubit>();
                final picked = v.first;
                if (picked == 'all') {
                  cubit.loadList(clearDirection: true);
                } else if (picked == 'i_owe') {
                  cubit.loadList(directionFilter: DebtDirection.iOwe);
                } else {
                  cubit.loadList(directionFilter: DebtDirection.owedToMe);
                }
              },
            ),
          ),
          if (state.counterpartyFilter case final cf?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: const Icon(Icons.person, size: 18),
                  label: Text('Filter: ${cf.displayName}'),
                  onDeleted: () => context
                      .read<PersonalDebtsCubit>()
                      .setCounterpartyFilter(null),
                ),
              ),
            ),
          if (state.status == PersonalDebtsStatus.loading && state.debts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No items')),
            )
          else
            ...filtered.map((d) => _DebtRow(debt: d)),
        ],
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({required this.debt});
  final PersonalDebt debt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = debt.isOwedToMe ? Colors.green : Colors.redAccent;
    final dirLabel = debt.isOwedToMe ? 'owes you' : 'you owe';
    return ListTile(
      title: Text(debt.counterpartyPersonName),
      subtitle: Text(
        '$dirLabel · ${debt.outstanding.toStringAsFixed(2)} ${debt.currency} outstanding',
      ),
      trailing: Chip(
        label: Text(debt.status.wire),
        backgroundColor:
            color.withValues(alpha: debt.isOpen ? 0.15 : 0.05),
        side: BorderSide(color: color),
        visualDensity: VisualDensity.compact,
        labelStyle: theme.textTheme.labelSmall,
      ),
      onTap: () => context.push('/personal-debts/${debt.id}'),
    );
  }
}
