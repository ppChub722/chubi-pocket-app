import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../domain/personal_debt.dart';
import '../cubit/personal_debts_cubit.dart';
import '../widgets/debt_widgets.dart';

/// `/personal-debts` — one page, by person (§11): summary (net + ติดคุณ /
/// คุณติด, tap a box to filter), search, status, then one row per person →
/// their page.
class PersonalDebtsPage extends StatefulWidget {
  const PersonalDebtsPage({super.key});

  @override
  State<PersonalDebtsPage> createState() => _PersonalDebtsPageState();
}

enum _Status { open, all }

class _PersonalDebtsPageState extends State<PersonalDebtsPage> {
  String _query = '';
  _Status _status = _Status.open;

  /// Summary-box filter: owedToMe = net > 0, iOwe = net < 0.
  DebtDirection? _dir;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PersonalDebtsCubit>().load();
      final contacts = context.read<ContactsCubit>();
      if (contacts.state.contacts.isEmpty) contacts.load();
    });
  }

  List<DebtPerson> _filter(List<DebtPerson> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      if (_status == _Status.open && p.openCount == 0) return false;
      if (_dir == DebtDirection.owedToMe && p.net <= 0) return false;
      if (_dir == DebtDirection.iOwe && p.net >= 0) return false;
      return q.isEmpty || p.displayName.toLowerCase().contains(q);
    }).toList();
  }

  void _openPerson(DebtPerson p) => context.push(
    Uri(
      path: '/personal-debts/person',
      queryParameters: {'contact': ?p.contactId, 'name': p.displayName},
    ).toString(),
  );

  void _addDebt() => context.push('/personal-debts/new');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.moreDebts, showBack: true),
      extendBodyBehindAppBar: true,
      body: BlocBuilder<PersonalDebtsCubit, PersonalDebtsState>(
        builder: (context, state) => AsyncStateView(
          loading:
              state.status == PersonalDebtsStatus.initial ||
              state.status == PersonalDebtsStatus.loading,
          error: state.error,
          isEmpty: state.debts.isEmpty,
          onRetry: context.read<PersonalDebtsCubit>().load,
          empty: EmptyView(
            icon: AppIcons.debt,
            title: l.debtsEmptyTitle,
            message: l.debtsEmptyMessage,
            cta: AddTile(label: l.debtsAddNew, onTap: _addDebt),
          ),
          builder: (context) {
            final people = state.people;
            final shown = _filter(people);
            final owed = people.fold<double>(0, (a, p) => a + p.owedToMeOpen);
            final owe = people.fold<double>(0, (a, p) => a + p.iOweOpen);
            final symbol = Currencies.symbolOf(
              people.isEmpty ? 'THB' : people.first.currency,
            );
            return PullToRefresh(
              onRefresh: () => context.read<PersonalDebtsCubit>().load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                // Top: clear the floating top bar.
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                  bottom: 96,
                ),
                children: [
                  _Summary(
                    owedToMe: owed,
                    iOwe: owe,
                    symbol: symbol,
                    selected: _dir,
                    onSelect: (d) =>
                        setState(() => _dir = _dir == d ? null : d),
                  ),
                  AppSearchBar(
                    hint: l.debtsSearchHint,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  FilterBar(
                    chips: [
                      OptionMenuAnchor<_Status>(
                        selected: _status,
                        onSelected: (s) => setState(() => _status = s),
                        options: [
                          SheetOption(
                            value: _Status.open,
                            label: l.debtsStatusOpen,
                          ),
                          SheetOption(
                            value: _Status.all,
                            label: l.debtsStatusAll,
                          ),
                        ],
                        builder: (context, toggle) => FilterDropdownChip(
                          label: l.debtsStatusLabel,
                          valueLabel: _status == _Status.open
                              ? l.debtsStatusOpen
                              : l.debtsStatusAll,
                          active: _status != _Status.open,
                          onTap: toggle,
                        ),
                      ),
                    ],
                  ),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(l.debtsNoMatch, textAlign: TextAlign.center),
                    )
                  else
                    for (final (i, p) in shown.indexed) ...[
                      if (i > 0) const RowDivider(),
                      _PersonRow(person: p, onTap: () => _openPerson(p)),
                    ],
                  // Add lives at the end of the list (no top-bar actions).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: AddTile(label: l.debtsAddNew, onTap: _addDebt),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.owedToMe,
    required this.iOwe,
    required this.symbol,
    required this.selected,
    required this.onSelect,
  });

  final double owedToMe;
  final double iOwe;
  final String symbol;
  final DebtDirection? selected;
  final ValueChanged<DebtDirection> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    Widget box(DebtDirection d, String label, double amount, Color color) {
      return Expanded(
        child: SelectableFrame(
          selected: selected == d,
          color: color,
          radius: AppRadius.md,
          child: Material(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => onSelect(d),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    MoneyText(
                      amount,
                      symbol: symbol,
                      style: textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l.debtsNet,
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                const MoneyVisibilityToggle(),
              ],
            ),
            MoneyText(
              owedToMe - iOwe,
              symbol: symbol,
              tone: MoneyTone.signed,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                box(
                  DebtDirection.owedToMe,
                  l.debtsOwedToMe,
                  owedToMe,
                  palette.income,
                ),
                const SizedBox(width: AppSpacing.sm),
                box(DebtDirection.iOwe, l.debtsIOwe, iOwe, palette.expense),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, required this.onTap});

  final DebtPerson person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final p = person;
    final even = p.net.abs() < 0.005;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: DebtAvatar(contactId: p.contactId, name: p.displayName),
      title: Row(
        children: [
          Flexible(
            child: Text(
              p.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (p.contactId != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(AppIcons.link, size: 14, color: scheme.onSurfaceVariant),
          ],
        ],
      ),
      subtitle: Text(l.debtsOpenCount(p.openCount)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!even)
            MoneyText(
              p.net.abs(),
              symbol: Currencies.symbolOf(p.currency),
              tone: p.net > 0 ? MoneyTone.income : MoneyTone.expense,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          Text(
            even ? l.debtsEven : (p.net > 0 ? l.debtsOwedToMe : l.debtsIOwe),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
