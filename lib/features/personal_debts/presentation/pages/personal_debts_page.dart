import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../preferences/page_prefs.dart';
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
  final _toolbar = AppListToolbarState.of('personal_debts');

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
    return AppListRow(
      key: ValueKey(p.key),
      leading: PersonMark(
        name: p.person.name,
        level: debtPersonLevel(p.person),
        iconCode: p.person.iconCode,
        avatar: p.person.avatar,
        size: 36,
      ),
      title: p.person.name,
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

  /// ลูกหนี้ / เจ้าหนี้ / เคลียร์แล้ว, each under its header (icon, people,
  /// total); the totals are the whole list's, not just the loaded pages.
  List<Widget> _sections(AppLocalizations l, DebtPeopleState s, String symbol) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final owedToMe = [
      for (final p in s.items)
        if (p.net > 0.005) p,
    ];
    final iOwe = [
      for (final p in s.items)
        if (p.net < -0.005) p,
    ];
    final even = [
      for (final p in s.items)
        if (p.net.abs() <= 0.005) p,
    ];
    Widget head(
      String title,
      IconData icon,
      Color color,
      int count,
      double? total,
    ) => AppListHeader(
      key: ValueKey('debtsSection-$title'),
      leading: AppIcon(icon, size: AppIconSize.md, color: color),
      title: title,
      count: count,
      trailing: total == null
          ? null
          : ListHeaderTrailing.value(
              MoneyText(
                total,
                symbol: symbol,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: color),
              ),
              prefix: l.debtsSectionTotal,
            ),
    );
    return [
      if (owedToMe.isNotEmpty) ...[
        head(
          l.debtsOwedToMe,
          AppIcons.flowIn,
          palette.income,
          s.counts[DebtListFilter.receivable] ?? owedToMe.length,
          s.totals.owedToMe,
        ),
        for (final p in owedToMe) _row(l, p),
      ],
      if (iOwe.isNotEmpty) ...[
        head(
          l.debtsIOwe,
          AppIcons.flowOut,
          palette.expense,
          s.counts[DebtListFilter.payable] ?? iOwe.length,
          s.totals.iOwe,
        ),
        for (final p in iOwe) _row(l, p),
      ],
      if (even.isNotEmpty) ...[
        head(
          l.debtsEven,
          AppIcons.check,
          scheme.onSurfaceVariant,
          even.length,
          null,
        ),
        for (final p in even) _row(l, p),
      ],
    ];
  }

  Widget _hero(AppLocalizations l, DebtPeopleState s, String symbol) {
    final cubit = context.read<DebtPeopleCubit>();
    final t = s.totals;
    final counts = s.counts;
    int count(DebtListFilter f) => counts[f] ?? 0;
    final palette = Theme.of(context).extension<AppColors>()!;
    final net = t.net;
    return AppHeroCard(
      // The จดหนี้ button's colour, so the page reads as the debt module.
      style: HeroStyle.tinted(color: ModuleColors.of(context).debt),
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
            builder: (context, _) => AppListToolbarToggle(
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
              topInset: AppSpacing.sm,
              header: [
                _hero(l, s, symbol),
                AppListToolbar(
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
