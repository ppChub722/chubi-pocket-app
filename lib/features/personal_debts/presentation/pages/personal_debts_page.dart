import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/quick_create_look.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../preferences/page_prefs.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/debt_directory.dart';
import '../../domain/debt_plans.dart';
import '../cubit/debt_directory_cubit.dart';
import '../../domain/debt_ledger.dart';
import '../cubit/debt_people_cubit.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../debt_wiring.dart';
import 'new_debt_plan_page.dart';

/// หนี้ · รายการหนี้ (owner 2026-10-22, mock DebtsList): a list hero like the
/// other lists (tile + "หนี้สุทธิ | N คน" + the big net; facts รอรับ / รอจ่าย
/// / ค้างเกิน 30 วัน; filter chips), then ONE card of people, oldest first.
class PersonalDebtsPage extends StatelessWidget {
  const PersonalDebtsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        DebtPeopleCubit(directory: context.read<DebtDirectoryCubit>())
          ..setFilter(_rememberedFilter(context))
          ..start(),
    child: const _PeopleView(),
  );

  /// The filter chip remembered on the account (default ทั้งหมด).
  static DebtListFilter _rememberedFilter(BuildContext context) {
    final pref = readPagePref(context, PagePrefIds.debts);
    final field = pagePrefPage(
      PagePrefIds.debts,
    ).fields.firstWhere((f) => f.key == 'filter');
    return DebtListFilter.values.asNameMap()[field.pick(pref)] ??
        DebtListFilter.all;
  }
}

class _PeopleView extends StatefulWidget {
  const _PeopleView();

  @override
  State<_PeopleView> createState() => _PeopleViewState();
}

class _PeopleViewState extends State<_PeopleView> {
  final _search = TextEditingController();
  final _toolbar = PpForgeListToolbarState.of('personal_debts');

  /// หนี้แบบที่ 1 (0.4.3): my cards / PayLater wallets holding a debt.
  List<CardSummary> _cards = const [];

  /// My open plans I owe (the hero's ผ่อนต่อเดือน).
  List<DebtPlan> _plans = const [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final repo = context.read<PersonalDebtsRepository>();
    try {
      final plans = await repo.plans();
      if (mounted) {
        setState(
          () => _plans = [
            for (final p in plans)
              if (p.iOwe && !p.plan.closed && p.plan.next != null) p,
          ],
        );
      }
    } catch (_) {}
    try {
      final cards = await repo.cardSummaries();
      if (mounted) {
        setState(
          () => _cards = [
            for (final c in cards)
              if (c.owed > 0.005 || c.plans.isNotEmpty) c,
          ],
        );
      }
    } catch (_) {
      // the people list still shows; cards come back on the next visit
    }
  }

  /// One card (S-Debts): its bill and due date, what it holds; under it the
  /// bill to pay and its plans (n/N, the next round billed).
  Widget _cardRow(AppLocalizations l, CardSummary c) {
    final symbol = debtCurrencySymbol(context);
    String money(double v) => moneyString(context, v, symbol: symbol);
    String day(DateTime d) => DateFormatter.friendly(
      d,
      today: l.commonToday,
      yesterday: l.commonYesterday,
      locale: Localizations.localeOf(context).languageCode,
    );
    final due = c.bill.dueDate;
    final summary = [
      '${l.debtCardBill} ${money(c.bill.left)}',
      if (due != null && c.bill.left > 0.005) l.debtCardDue(day(due)),
    ].join(' · ');
    void open() => openPage(context, '/personal-debts/cards/${c.account.id}');
    return CollapsibleSection(
      key: ValueKey('debtCard-${c.account.id}'),
      title: c.account.name,
      summary: summary,
      leading: const PpForgeIcon(AppIcons.wallet, size: PpForgeIconSize.md),
      trailing: MoneyText(c.owed, tone: MoneyTone.expense),
      children: [
        if (c.bill.left > 0.005)
          PpForgeListRow(
            key: ValueKey('debtCardBill-${c.account.id}'),
            leading: const PpForgeIcon(AppIcons.date, size: PpForgeIconSize.md),
            title: l.debtCardBill,
            line2: due == null
                ? null
                : ListRowLine(
                    parts: [l.debtCardDue(day(due))],
                    tone: Tone.warning,
                  ),
            trailing: ListRowTrailing.value(
              MoneyText(c.bill.left, tone: MoneyTone.expense),
            ),
            onTap: open,
          ),
        for (final p in c.plans)
          PpForgeListRow(
            key: ValueKey('debtCardPlan-${p.id}'),
            leading: const PpForgeIcon(
              AppIcons.payLater,
              size: PpForgeIconSize.md,
            ),
            title: p.name,
            line2: ListRowLine(
              parts: [
                '${p.plan.done}/${p.plan.count}',
                if (p.plan.next != null)
                  '${day(p.plan.next!.dueDate)} · ${money(p.plan.next!.amount)}',
              ],
            ),
            trailing: ListRowTrailing.value(MoneyText(p.plan.leftTotal)),
            onTap: () => openPage(context, '/personal-debts/plans/${p.id}'),
          ),
        DueMoreRow(
          key: ValueKey('debtCardOpen-${c.account.id}'),
          label: l.debtsOpenPage,
          onTap: open,
        ),
      ],
    );
  }

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

  /// Line 2: the due date when there is one ("ครบกำหนด 30 ต.ค." /
  /// "เลยกำหนด 3 วัน"), else how long it's been open.
  (String?, bool) _line2(AppLocalizations l, PersonBalance p) {
    final due = p.nextDueDate;
    if (due != null) {
      final now = DateTime.now();
      final late = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(due.year, due.month, due.day)).inDays;
      if (late > 0) return (l.debtOverdueDays(late), true);
      return (
        l.debtDueOn(
          DateFormatter.friendly(
            due,
            today: l.commonToday,
            yesterday: l.commonYesterday,
            locale: Localizations.localeOf(context).languageCode,
          ),
        ),
        false,
      );
    }
    final days = p.daysOutstanding;
    return (days == null ? null : l.debtsOwingDays(days), (days ?? 0) > 30);
  }

  /// The app's data row: the section above says the side, the amount's
  /// colour repeats it.
  Widget _row(AppLocalizations l, PersonBalance p) {
    final (line2, warn) = _line2(l, p);
    return PpForgeListRow(
      key: ValueKey(p.key),
      leading: _mark(p),
      title: p.institution?.name ?? p.person.name,
      line2: line2 == null
          ? null
          : ListRowLine(parts: [line2], tone: warn ? Tone.warning : null),
      trailing: ListRowTrailing.value(
        MoneyText(
          p.net.abs(),
          tone: p.net > 0.005
              ? MoneyTone.income
              : p.net < -0.005
              ? MoneyTone.expense
              : MoneyTone.plain,
        ),
      ),
      onTap: () => _open(p),
    );
  }

  /// 0.4.3: สถาบันการเงิน, then บุคคล; one group per counterparty (its mark,
  /// name and net; ⌄ folds it), its first rows from the BE and "ดูทั้ง N"
  /// to its page. A row from an older BE with no preview stays one row.
  List<Widget> _sections(AppLocalizations l, DebtPeopleState s, String symbol) {
    final institutions = [
      for (final p in s.items)
        if (p.isInstitution) p,
    ];
    final people = [
      for (final p in s.items)
        if (!p.isInstitution) p,
    ];
    Widget head(String title, IconData icon, int count) => PpForgeListHeader(
      key: ValueKey('debtsSection-$title'),
      leading: PpForgeIcon(icon, size: PpForgeIconSize.md),
      title: title,
      count: count,
    );
    return [
      if (_cards.isNotEmpty) ...[
        head(l.debtsSectionCards, AppIcons.wallet, _cards.length),
        for (final c in _cards) _cardRow(l, c),
      ],
      if (institutions.isNotEmpty) ...[
        head(l.debtsSectionInstitutions, AppIcons.bank, institutions.length),
        for (final p in institutions) _group(l, p, symbol),
      ],
      if (people.isNotEmpty) ...[
        head(l.debtsSectionPeople, AppIcons.contact, people.length),
        for (final p in people) _group(l, p, symbol),
      ],
      DueMoreRow(
        key: const ValueKey('debtPlanNew'),
        label: l.debtPlanNew,
        onTap: () => openNewDebtPlan(context),
      ),
    ];
  }

  Widget _mark(PersonBalance p, {double size = 36}) {
    final i = p.institution;
    return i != null
        ? InstitutionMark(name: i.name, iconCode: i.iconCode, size: size)
        : PersonMark(
            level: debtPersonLevel(p.person),
            avatar: p.person.avatar,
            size: size,
          );
  }

  MoneyText _net(double net) => MoneyText(
    net.abs(),
    tone: net > 0.005
        ? MoneyTone.income
        : net < -0.005
        ? MoneyTone.expense
        : MoneyTone.plain,
  );

  Widget _group(AppLocalizations l, PersonBalance p, String symbol) {
    if (p.entriesPreview.isEmpty) return _row(l, p);
    final (line2, _) = _line2(l, p);
    final all = p.entriesCount ?? p.entryCount;
    return CollapsibleSection(
      key: ValueKey('debtGroup-${p.key}'),
      title: p.institution?.name ?? p.person.name,
      summary: line2,
      leading: _mark(p),
      trailing: _net(p.net),
      children: [
        for (final r in p.entriesPreview.take(3)) _previewRow(l, p, r, symbol),
        DueMoreRow(
          key: ValueKey('debtGroupAll-${p.key}'),
          label: all > 3 ? l.debtsSeeAll(all) : l.debtsOpenPage,
          onTap: () => _open(p),
        ),
      ],
    );
  }

  /// One of a group's first rows: a debt / repayment, a recurring item (n/N
  /// and its next date), a card's debt or the general debts in one line.
  Widget _previewRow(
    AppLocalizations l,
    PersonBalance p,
    DebtPreviewRow r,
    String symbol,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final date = r.date;
    String? when(DateTime? d) => d == null
        ? null
        : DateFormatter.friendly(
            d,
            today: l.commonToday,
            yesterday: l.commonYesterday,
            locale: locale,
          );
    final plan = r.plan;
    final (String title, IconData icon, String? path) = switch (r.kind) {
      DebtPreviewKind.recurring => (
        r.title ?? '',
        AppIcons.recurring,
        r.id == null ? null : '/recurring/${r.id}',
      ),
      DebtPreviewKind.cardDebt => (
        '${l.debtsCardDebt} | ${r.title ?? ''}',
        AppIcons.creditCard,
        r.id == null ? null : '/accounts/${r.id}',
      ),
      DebtPreviewKind.general => (
        r.count == null ? l.debtsGeneral : l.debtsGeneralCount(r.count!),
        AppIcons.debt,
        null,
      ),
      DebtPreviewKind.entry => (
        r.title ?? l.debtsGeneral,
        AppIcons.debt,
        r.id == null ? null : '/personal-debts/${r.id}',
      ),
    };
    return PpForgeListRow(
      key: ValueKey('debtPreview-${p.key}-${r.kind.name}-${r.id}'),
      leading: PpForgeAvatar.icon(icon, size: 32),
      title: title,
      line2: ListRowLine(
        parts: [if (plan != null) '${plan.done}/${plan.count}', ?when(date)],
      ),
      trailing: ListRowTrailing.value(_net(r.amount)),
      onTap: path == null ? () => _open(p) : () => openPage(context, path),
    );
  }

  Widget _hero(AppLocalizations l, DebtPeopleState s, String symbol) {
    final cubit = context.read<DebtPeopleCubit>();
    final t = s.totals;
    final counts = s.counts;
    int count(DebtListFilter f) => counts[f] ?? 0;
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    // 0.4.3 (S-Debts): a card's balance is a debt I owe; its bill due this
    // month is money to pay this month.
    final now = DateTime.now();
    var cardsOwed = 0.0, cardsDue = 0.0;
    for (final c in _cards) {
      cardsOwed += c.owed;
      final due = c.bill.dueDate;
      if (due != null && due.year == now.year && due.month == now.month) {
        cardsDue += c.bill.left;
      }
    }
    var perMonth = 0.0;
    for (final p in _plans) {
      perMonth += p.plan.next?.amount ?? 0;
    }
    final net = t.net - cardsOwed;
    final payThisMonth = (t.payThisMonth ?? 0) + cardsDue;
    return PpForgeHeroCard(
      // The จดหนี้ button's colour, so the page reads as the debt module.
      style: HeroStyle.tinted(color: ModuleColors.of(context).debt),
      margin: const EdgeInsets.fromLTRB(
        PpForgeSpacing.lg,
        PpForgeSpacing.sm,
        PpForgeSpacing.lg,
        PpForgeSpacing.md,
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
            builder: (context, _) => PpForgeListToolbarToggle(
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
              moneyString(context, t.iOwe + cardsOwed, symbol: symbol),
              icon: AppIcons.flowOut,
              iconColor: palette.expense,
              color: palette.expense,
            ),
            if (t.payThisMonth != null || cardsDue > 0)
              HeroFact(
                l.debtsThisMonthPay,
                moneyString(context, payThisMonth, symbol: symbol),
                icon: AppIcons.date,
              ),
            if (_plans.isNotEmpty)
              HeroFact(
                l.debtsPlansPerMonth(_plans.length),
                moneyString(context, perMonth, symbol: symbol),
                icon: AppIcons.payLater,
              ),
            if (t.receiveThisMonth != null)
              HeroFact(
                l.debtsThisMonthReceive,
                moneyString(context, t.receiveThisMonth!, symbol: symbol),
                icon: AppIcons.date,
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
              (
                DebtListFilter.receivable,
                l.debtsOwedToMe,
                PpForgeChipTone.success,
              ),
              (DebtListFilter.payable, l.debtsIOwe, PpForgeChipTone.danger),
              (
                DebtListFilter.overdue30,
                l.debtsOver30Label,
                PpForgeChipTone.warning,
              ),
            ])
              HeroFilter(
                label: label,
                count: count(f),
                tone: tone,
                selected: s.filter == f,
                onTap: () {
                  cubit.setFilter(f);
                  unawaited(
                    rememberPagePref(context, PagePrefIds.debts, {
                      'filter': f.name,
                    }),
                  );
                },
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
      preset: const QuickCreatePreset.debt().withLook(
        QuickCreateLook.debt(context),
      ),
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
              topInset: PpForgeSpacing.sm,
              header: [
                _hero(l, s, symbol),
                PpForgeListToolbar(
                  state: _toolbar,
                  search: ListToolbarSearch(
                    controller: _search,
                    onChanged: cubit.search,
                    hint: l.debtsSearchHint,
                  ),
                ),
              ],
              children: _sections(l, s, symbol),
            ),
          ),
        ),
      ),
    );
  }
}
