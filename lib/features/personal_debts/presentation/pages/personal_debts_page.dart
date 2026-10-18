import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../cubit/debt_directory_cubit.dart';
import '../../domain/debt_ledger.dart';
import '../cubit/debt_people_cubit.dart';
import '../debt_wiring.dart';

class PersonalDebtsPage extends StatelessWidget {
  const PersonalDebtsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        DebtPeopleCubit(directory: context.read<DebtDirectoryCubit>())..start(),
    child: const _PeopleView(),
  );
}

class _PeopleView extends StatefulWidget {
  const _PeopleView();

  @override
  State<_PeopleView> createState() => _PeopleViewState();
}

class _PeopleViewState extends State<_PeopleView> {
  final _search = TextEditingController();
  final _toolbar = ToolbarToggleState.of('personal_debts');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(PersonBalance p) =>
      openPage(context, debtPersonPath(p.key), extra: p.person.name);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final symbol = debtCurrencySymbol(context);
    final cubit = context.read<DebtPeopleCubit>();
    return QuickCreatePresetScope(
      preset: const QuickCreatePreset.debt(),
      child: Scaffold(
        appBar: AppTopBar(title: l.moreDebts, showBack: true),
        extendBodyBehindAppBar: true,
        body: TabSwitchBody(
          child: BlocBuilder<DebtPeopleCubit, DebtPeopleState>(
            builder: (context, s) => ListPageBody(
              loading:
                  s.status == DebtLoadStatus.initial ||
                  s.status == DebtLoadStatus.loading,
              error: s.error,
              isEmpty: s.items.isEmpty,
              onRetry: cubit.load,
              empty: s.isFiltered
                  ? EmptyView.compact(message: l.debtsNoMatch)
                  : EmptyView(
                      icon: AppIcons.debt,
                      title: l.debtsEmptyTitle,
                      message: l.debtsEmptyMessage,
                    ),
              hasMore: s.hasMore,
              loadingMore: s.loadingMore,
              onLoadMore: cubit.loadMore,
              loadMoreError: s.moreError,
              rowDividers: true,
              rowDividerIndent: 72,
              topInset: AppSpacing.sm,
              header: [
                ListSummaryCard(
                  caption: l.fpDebtsTotalCaption,
                  actions: [
                    ListenableBuilder(
                      listenable: _search,
                      builder: (context, _) => ToolbarToggleButton(
                        state: _toolbar,
                        filtered:
                            _search.text.isNotEmpty ||
                            s.all ||
                            s.sort != DebtPeopleSort.oldest,
                        tooltip: l.commonSearch,
                      ),
                    ),
                  ],
                  tiles: [
                    SummaryTile(
                      label: l.fpDebtsOwedToMeTile(s.totals.owedToMePeople),
                      value: moneyString(context, s.totals.owedToMe),
                      tone: SummaryTileTone.green,
                      selected: s.side == NetSide.owedToMe,
                      onTap: () => cubit.toggleSide(NetSide.owedToMe),
                    ),
                    SummaryTile(
                      label: l.fpDebtsIOweTile(s.totals.iOwePeople),
                      value: moneyString(context, s.totals.iOwe),
                      tone: SummaryTileTone.red,
                      selected: s.side == NetSide.iOwe,
                      onTap: () => cubit.toggleSide(NetSide.iOwe),
                    ),
                  ],
                  infoLine: s.totals.owedToMe > 0 && s.totals.iOwe > 0
                      ? DebtNetLine(
                          label: l.debtsNet,
                          net: s.totals.net,
                          currencySymbol: symbol,
                        )
                      : null,
                  alert: s.totals.over30DaysPeople > 0
                      ? l.fpDebtsOver30(s.totals.over30DaysPeople)
                      : null,
                ),
                ListToolbar(
                  collapse: _toolbar,
                  searchController: _search,
                  onSearchChanged: cubit.search,
                  searchHint: l.debtsSearchHint,
                  chips: [
                    AppChip(
                      label: l.fpDebtsIncludeCleared,
                      selected: s.all,
                      onTap: () => cubit.showAll(!s.all),
                    ),
                  ],
                  trailing: SortChip<DebtPeopleSort>(
                    value: s.sort,
                    tooltip: l.debtsSortLabel,
                    options: [
                      SortOption(DebtPeopleSort.oldest, l.fpDebtsSortOldest),
                      SortOption(DebtPeopleSort.amount, l.fpDebtsSortAmount),
                      SortOption(DebtPeopleSort.recent, l.fpDebtsSortRecent),
                    ],
                    onChanged: cubit.setSort,
                  ),
                ),
              ],
              children: [
                for (final p in s.items)
                  PersonBalanceRow(
                    key: ValueKey(p.key),
                    name: p.person.name,
                    level: debtPersonLevel(p.person),
                    iconCode: p.person.iconCode,
                    subtitle: p.daysOutstanding == null
                        ? null
                        : l.fpDebtsDaysOutstanding(p.daysOutstanding!),
                    subtitleWarn: (p.daysOutstanding ?? 0) > 30,
                    showCaption: false,
                    net: p.net,
                    owedToMeLabel: l.debtsOwedToMe,
                    iOweLabel: l.debtsIOwe,
                    settledLabel: l.debtsEven,
                    currencySymbol: symbol,
                    onTap: () => _open(p),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
