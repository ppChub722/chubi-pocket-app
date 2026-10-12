import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/debt_ledger.dart';
import '../cubit/debt_people_cubit.dart';
import '../debt_wiring.dart';

/// `/personal-debts` — ONE people list (ติดคุณ and คุณติด together): the
/// summary (net + the two sides, a tap filters), search + "ทั้งหมด", then
/// one row per person → their page. Open = 1 call; search / filter / next
/// page = 1 call each, on the server. The centre + opens debt mode.
class PersonalDebtsPage extends StatelessWidget {
  const PersonalDebtsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        DebtPeopleCubit(repository: context.read<PersonalDebtsRepository>())
          ..load(),
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
          // A failed reload with rows on screen keeps them + a snackbar
          // (the template).
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
                DebtSummaryCard(
                  net: s.totals.net,
                  owedToMe: s.totals.owedToMe,
                  iOwe: s.totals.iOwe,
                  netLabel: l.debtsNet,
                  owedToMeLabel: l.debtsOwedToMe,
                  iOweLabel: l.debtsIOwe,
                  owedToMeSelected: s.side == NetSide.owedToMe,
                  iOweSelected: s.side == NetSide.iOwe,
                  onOwedToMeTap: () => cubit.toggleSide(NetSide.owedToMe),
                  onIOweTap: () => cubit.toggleSide(NetSide.iOwe),
                  currencySymbol: symbol,
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                ),
                ListToolbar(
                  searchController: _search,
                  onSearchChanged: cubit.search,
                  searchHint: l.debtsSearchHint,
                  chips: [
                    AppChip(
                      label: l.debtsStatusAll,
                      selected: s.all,
                      onTap: () => cubit.showAll(!s.all),
                    ),
                  ],
                ),
              ],
              children: [
                for (final p in s.items)
                  PersonBalanceRow(
                    key: ValueKey(p.key),
                    name: p.person.name,
                    level: debtPersonLevel(p.person),
                    iconCode: p.person.iconCode,
                    subtitle: l.debtsOpenCount(p.openCount),
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
