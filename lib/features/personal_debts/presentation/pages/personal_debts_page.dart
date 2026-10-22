import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/debt_directory.dart';
import '../cubit/debt_directory_cubit.dart';
import '../../domain/debt_ledger.dart';
import '../cubit/debt_people_cubit.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../debt_wiring.dart';

/// หนี้ · รายการหนี้ (owner 2026-10-22, mock DebtsList): a list hero like the
/// other lists (tile + "หนี้สุทธิ | N คน" + the big net; facts รอรับ / รอจ่าย
/// / ค้างเกิน 30 วัน; filter chips), then ONE card of people, oldest first.
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

  /// The in-page + and the empty state's จดหนี้ (mock QuickCreateBtn):
  /// quick create in debt mode, like the centre button here.
  Future<bool> _create() =>
      showQuickCreateSheet(context, preset: const QuickCreatePreset.debt());

  void _open(PersonBalance p) =>
      openPage(context, debtPersonPath(p.key), extra: p.person.name);

  /// "ค่าตั๋วคอนเสิร์ต | 1 ก.ย." / "คุณจ่ายคืน ฿400 | 10 ต.ค." /
  /// "มิ้นท์คืน ฿100 | 15 ต.ค.".
  String? _lastLine(AppLocalizations l, PersonBalance p, String symbol) {
    final a = p.lastActivity;
    if (a == null) return null;
    final money = moneyString(context, a.amount, symbol: symbol);
    final what =
        a.title ??
        (a.isRepayment
            ? (a.direction == DebtEntryDirection.paid
                  ? l.debtsLastIPaidBack(money)
                  : l.debtsLastTheyPaidBack(p.person.name, money))
            : money);
    final date = a.date;
    if (date == null) return what;
    return l.debtsLastLine(
      what,
      DateFormatter.friendly(
        date,
        today: l.commonToday,
        yesterday: l.commonYesterday,
        locale: Localizations.localeOf(context).languageCode,
      ),
    );
  }

  Widget _hero(AppLocalizations l, DebtPeopleState s, String symbol) {
    final cubit = context.read<DebtPeopleCubit>();
    final t = s.totals;
    final counts = s.counts;
    int count(DebtListFilter f) => counts[f] ?? 0;
    final palette = Theme.of(context).extension<AppColors>()!;
    final net = t.net;
    return AppHeroCard(
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      header: HeroSummaryHead(
        icon: AppIcons.debt,
        label: l.debtsHeroNet(count(DebtListFilter.all)),
        amount: MoneyText(net, tone: MoneyTone.signed, symbol: symbol),
        amountColor: net.abs() <= 0.005
            ? null
            : debtStateColor(context, owedToMe: net > 0),
        actions: [
          ListenableBuilder(
            listenable: _search,
            builder: (context, _) => ToolbarToggleButton(
              state: _toolbar,
              filtered: _search.text.isNotEmpty,
              tooltip: l.commonSearch,
            ),
          ),
          QuickCreateHeadButton(
            key: const ValueKey('debtsAdd'),
            mode: QuickCreateMode.debt,
            tooltip: l.quickCreateBtnDebt,
            onPressed: _create,
          ),
        ],
      ),
      content: [
        HeroFactList(
          facts: [
            HeroFact(
              l.fpDebtsOwedToMeTile(count(DebtListFilter.receivable)),
              moneyString(context, t.owedToMe, symbol: symbol),
              icon: AppIcons.flowIn,
              iconColor: palette.income,
              color: palette.income,
            ),
            HeroFact(
              l.fpDebtsIOweTile(count(DebtListFilter.payable)),
              moneyString(context, t.iOwe, symbol: symbol),
              icon: AppIcons.flowOut,
              iconColor: palette.expense,
              color: palette.expense,
            ),
            HeroFact(
              l.debtsOver30Label,
              l.debtsPeopleCount(count(DebtListFilter.overdue30)),
              icon: AppIcons.payLater,
              iconColor: Tone.warning.color(context),
              color: Tone.warning.color(context),
            ),
          ],
        ),
      ],
      footer: [
        HeroFilterChips(
          filters: [
            for (final (f, label, tone) in [
              (DebtListFilter.all, l.debtsFilterAll, null),
              (DebtListFilter.receivable, l.debtsOwedToMe, AppChipTone.success),
              (DebtListFilter.payable, l.debtsIOwe, AppChipTone.danger),
              (
                DebtListFilter.overdue30,
                l.debtsOver30Label,
                AppChipTone.warning,
              ),
            ])
              HeroFilter(
                label: label,
                count: count(f),
                tone: tone,
                selected: s.filter == f,
                onTap: () => cubit.setFilter(f),
              ),
          ],
        ),
      ],
    );
  }

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
                      title: l.debtsEmptyOpenTitle,
                      message: l.debtsEmptyOpenMessage,
                      cta: QuickCreateCtaButton(
                        key: const ValueKey('debtsEmptyAdd'),
                        mode: QuickCreateMode.debt,
                        label: l.quickCreateBtnDebt,
                        onPressed: _create,
                      ),
                    ),
              hasMore: s.hasMore,
              loadingMore: s.loadingMore,
              onLoadMore: cubit.loadMore,
              loadMoreError: s.moreError,
              // ONE card of people (mock).
              rowCards: true,
              rowDividers: true,
              rowDividerIndent: 72,
              topInset: AppSpacing.sm,
              header: [
                _hero(l, s, symbol),
                ListToolbar(
                  collapse: _toolbar,
                  searchController: _search,
                  onSearchChanged: cubit.search,
                  searchHint: l.debtsSearchHint,
                ),
              ],
              children: [
                for (final p in s.items)
                  PersonBalanceRow(
                    key: ValueKey(p.key),
                    name: p.person.name,
                    level: debtPersonLevel(p.person),
                    iconCode: p.person.iconCode,
                    subtitle: _lastLine(l, p, symbol),
                    net: p.net,
                    owedToMeLabel: l.debtsOwedToMe,
                    iOweLabel: l.debtsIOwe,
                    settledLabel: l.debtsEven,
                    currencySymbol: symbol,
                    age: p.daysOutstanding == null
                        ? null
                        : l.fpDebtsDaysOutstanding(p.daysOutstanding!),
                    ageWarn: (p.daysOutstanding ?? 0) > 30,
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
