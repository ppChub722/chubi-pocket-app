import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../../contacts/presentation/widgets/contact_picker_sheet.dart';
import '../../../transactions/domain/refs.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/debt_ledger.dart';
import '../cubit/debt_people_cubit.dart';
import '../cubit/debt_person_cubit.dart';
import '../debt_wiring.dart';

/// `/personal-debts/people/:key` — everything with one person: the hero
/// (net), ONE button "+ บันทึกรายการ" (quick create in debt mode, preset to
/// this person), then the tabs "รายการหนี้" (every entry) / "ประวัติการจ่าย"
/// (entries that moved wallet money). Open = 1 call; the money tab = 1 call
/// on its first open; search / filter / sort / next page = 1 call each.
class DebtPersonPage extends StatelessWidget {
  const DebtPersonPage({required this.personKey, this.name, super.key});

  /// `c:<contact id>` / `n:<name>` (decoded).
  final String personKey;

  /// The name the opener already knows (the top bar before the load).
  final String? name;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => DebtPersonCubit(
      repository: context.read<PersonalDebtsRepository>(),
      personKey: personKey,
    )..load(),
    child: _PersonView(name: name),
  );
}

class _PersonView extends StatefulWidget {
  const _PersonView({this.name});

  final String? name;

  @override
  State<_PersonView> createState() => _PersonViewState();
}

class _PersonViewState extends State<_PersonView> {
  DebtPersonTab _tab = DebtPersonTab.entries;
  final _search = {
    for (final t in DebtPersonTab.values) t: TextEditingController(),
  };
  bool _linking = false;

  @override
  void dispose() {
    for (final c in _search.values) {
      c.dispose();
    }
    super.dispose();
  }

  DebtPersonCubit get _cubit => context.read<DebtPersonCubit>();

  String _name(DebtPersonState s) =>
      s.balance?.person.name ?? widget.name ?? '';

  /// The person for quick create's preset — known from the key before the
  /// load lands (a contact id / the typed name).
  EmbeddedPerson _person(DebtPersonState s) {
    final p = s.balance?.person;
    if (p != null) return p;
    final key = s.personKey;
    return EmbeddedPerson(
      name: _name(s),
      contactId: key.startsWith('c:') ? key.substring(2) : null,
    );
  }

  void _selectTab(DebtPersonTab t) {
    setState(() => _tab = t);
    _cubit.openTab(t);
  }

  /// The shell's + and this button open the same preset. The page patches
  /// from the write response through [DebtBook] (no re-fetch).
  QuickCreatePreset _preset(DebtPersonState s) => QuickCreatePreset.debt(
    person: _person(s),
    debtDirection: debtDirectionFor(s.balance?.net),
  );

  Future<void> _addEntry() async {
    await showQuickCreateSheet(context, preset: _preset(_cubit.state));
  }

  /// The entry's detail = the transaction detail page in debt mode
  /// (fe-core). TODO(debt-mode): push `/personal-debts/entries/<id>` once
  /// that route exists; until then an entry with a wallet tx opens the tx.
  void _openEntry(DebtEntry e) {
    final tx = e.transaction;
    if (tx != null) openPage(context, '/transactions/${tx.id}');
  }

  /// A typed name joins a contact (absorb); the page moves to the contact's
  /// key.
  Future<void> _linkToContact() async {
    final l = AppLocalizations.of(context)!;
    final name = _name(_cubit.state);
    final picked = await showContactPickerSheet(context, allowFreeText: false);
    if (picked is! ContactPicked || !mounted) return;
    final contact = picked.contact;
    setState(() => _linking = true);
    try {
      final n = (await context.read<ContactsCubit>().absorb(contact.id, [
        name,
      ])).absorbedCount;
      if (!mounted) return;
      showAppSnackBar(
        context,
        l.debtsPersonLinked(n, contact.name),
        tone: Tone.success,
      );
      // Same tab: the page moves to the contact's key.
      context.pushReplacement(
        Uri(path: '/personal-debts/people/c:${contact.id}').toString(),
        extra: contact.name,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _linking = false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<DebtPersonCubit, DebtPersonState>(
      builder: (context, s) {
        final notFound = s.error?.statusCode == 404;
        return QuickCreatePresetScope(
          preset: _preset(s),
          child: Scaffold(
            appBar: AppTopBar(title: _name(s), showBack: true),
            extendBodyBehindAppBar: true,
            body: AsyncStateView(
              loading: s.firstLoad,
              error: notFound ? null : s.error,
              isEmpty: s.balance == null,
              onRetry: _cubit.load,
              empty: EmptyView(
                icon: AppIcons.debt,
                title: l.debtsTimelineEmpty,
                message: l.debtsEmptyMessage,
              ),
              builder: (context) => _body(context, s),
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, DebtPersonState s) {
    final l = AppLocalizations.of(context)!;
    final b = s.balance!;
    final symbol = debtCurrencySymbol(context);
    final palette = Theme.of(context).extension<AppColors>()!;
    final style = HeroStyle.tinted(
      color: b.person.iconCode.tintFor(palette, avatarName: b.person.name),
    );
    return TabbedDetailBody<DebtPersonTab>(
      hero: HeaderCard(
        heroStyle: style,
        leading: PersonMark(
          name: b.person.name,
          level: debtPersonLevel(b.person),
          iconCode: b.person.iconCode,
          size: 52,
        ),
        title: Text(b.person.name),
        trailing: b.person.contactId == null
            ? null
            : AppIconButton(
                icon: AppIcons.contact,
                tooltip: l.debtsPersonOpenContact,
                onPressed: () =>
                    openPage(context, '/contacts/${b.person.contactId}'),
              ),
        footer: NetBalance(
          amount: b.net,
          size: NetBalanceSize.hero,
          owedToMeLabel: l.debtsOwedToMe,
          iOweLabel: l.debtsIOwe,
          settledLabel: l.debtsEven,
          currencySymbol: symbol,
        ),
      ),
      compactBar: CompactHeroBar(
        title: Text(b.person.name),
        leading: PersonMark(
          name: b.person.name,
          level: debtPersonLevel(b.person),
          iconCode: b.person.iconCode,
          size: 28,
        ),
        style: style,
      ),
      belowHero: [
        AppButton(
          label: l.debtsAddEntry,
          icon: AppIcons.add,
          expand: true,
          onPressed: _addEntry,
        ),
        if (b.person.contactId == null)
          SectionCard(
            children: [
              DetailRow(
                leading: _linking
                    ? const AppSpinner(size: AppSpinnerSize.medium)
                    : const AppIcon(AppIcons.link),
                label: l.debtsPersonLinkContact,
                helper: l.debtsPersonLinkContactHint,
                showChevron: true,
                onTap: _linking ? null : _linkToContact,
              ),
            ],
          ),
      ],
      tabs: [
        AppTab(value: DebtPersonTab.entries, label: l.debtsTabEntries),
        AppTab(value: DebtPersonTab.money, label: l.debtsTabMoney),
      ],
      selected: _tab,
      onChanged: _selectTab,
      tabBuilder: (context, t) => BlocBuilder<DebtPersonCubit, DebtPersonState>(
        buildWhen: (a, b) => a.tab(t) != b.tab(t) || a.balance != b.balance,
        builder: (context, s) => _tabList(context, s, t),
      ),
    );
  }

  Widget _tabList(BuildContext context, DebtPersonState s, DebtPersonTab t) {
    final l = AppLocalizations.of(context)!;
    final list = s.tab(t);
    final q = list.query;
    final symbol = debtCurrencySymbol(context);
    final locale = Localizations.localeOf(context).languageCode;
    final name = _name(s);
    return ListPageBody(
      clearTopBar: false,
      loading:
          list.status == DebtLoadStatus.initial ||
          list.status == DebtLoadStatus.loading,
      error: list.error,
      isEmpty: list.items.isEmpty,
      onRetry: _cubit.load,
      empty: q.isFiltered
          ? EmptyView.compact(message: l.debtsEntriesNoMatch)
          : EmptyView.compact(
              message: t == DebtPersonTab.entries
                  ? l.debtsTimelineEmpty
                  : l.debtsMoneyEmpty,
            ),
      hasMore: list.hasMore,
      loadingMore: list.loadingMore,
      onLoadMore: () => _cubit.loadMore(t),
      loadMoreError: list.moreError,
      rowDividers: true,
      header: [
        ListToolbar(
          searchController: _search[t],
          onSearchChanged: (v) => _cubit.search(t, v),
          searchHint: l.debtsEntrySearchHint,
          chips: [
            _optionChip<DebtEntryDirection?>(
              label: l.debtsDirLabel,
              value: q.direction,
              options: {
                null: l.debtsStatusAll,
                DebtEntryDirection.paid: l.debtsDirPaid,
                DebtEntryDirection.received: l.debtsDirReceived,
              },
              onSelected: (d) => _cubit.setQuery(
                t,
                q.copyWith(direction: d, clearDirection: d == null),
              ),
            ),
            if (t == DebtPersonTab.entries)
              _optionChip<bool?>(
                label: l.debtsStatusLabel,
                value: q.paid,
                options: {
                  null: l.debtsStatusAll,
                  false: l.debtsStatusOpen,
                  true: l.debtsPaidChip,
                },
                onSelected: (p) => _cubit.setQuery(
                  t,
                  q.copyWith(paid: p, clearPaid: p == null),
                ),
              ),
          ],
          trailing: SortChip<DebtEntrySort>(
            value: q.sort,
            tooltip: l.debtsSortLabel,
            options: [
              SortOption(DebtEntrySort.dateDesc, l.debtsSortNewest),
              SortOption(DebtEntrySort.dateAsc, l.debtsSortOldest),
              SortOption(DebtEntrySort.amountDesc, l.debtsSortAmountDesc),
              SortOption(DebtEntrySort.amountAsc, l.debtsSortAmountAsc),
            ],
            onChanged: (v) => _cubit.setQuery(t, q.copyWith(sort: v)),
          ),
        ),
      ],
      children: [
        for (final row in _rows(list.items, q))
          row is DateTime
              ? DateGroupHeader(label: _dayLabel(l, row, locale))
              : _ledgerRow(l, row as DebtEntry, name, symbol, locale),
      ],
    );
  }

  /// Day headers only in the default date order (a search / filter / amount
  /// sort shows the entries alone).
  List<Object> _rows(List<DebtEntry> items, DebtEntryQuery q) {
    final byDate =
        q.sort == DebtEntrySort.dateDesc || q.sort == DebtEntrySort.dateAsc;
    if (!byDate) return items;
    final out = <Object>[];
    DateTime? day;
    for (final e in items) {
      final d = e.date;
      if (d != null && (day == null || !DateUtils.isSameDay(day, d))) {
        day = d;
        out.add(d);
      }
      out.add(e);
    }
    return out;
  }

  Widget _ledgerRow(
    AppLocalizations l,
    DebtEntry e,
    String name,
    String symbol,
    String locale,
  ) {
    final wallet = e.transaction?.account;
    return LedgerRow(
      key: ValueKey(e.id),
      direction: e.iPaid ? LedgerDirection.paid : LedgerDirection.received,
      amount: e.amount,
      title:
          e.description ??
          (e.iPaid ? l.debtEntryPaidTo(name) : l.debtEntryReceivedFrom(name)),
      dateLabel: e.date == null
          ? ''
          : DateFormatter.short(e.date!, locale: locale),
      walletLabel: wallet?.name,
      walletIcon: wallet == null
          ? null
          : IconDisplay(
              type: IconType.account,
              size: 14,
              iconCode: wallet.iconCode,
            ),
      paidLabel: e.paid ? l.debtsPaidChip : null,
      sourceLabel: e.source?.title,
      currencySymbol: symbol,
      onTap: e.transaction == null ? null : () => _openEntry(e),
    );
  }

  String _dayLabel(AppLocalizations l, DateTime d, String locale) =>
      DateFormatter.friendly(
        d,
        today: l.commonToday,
        yesterday: l.commonYesterday,
        locale: locale,
      );

  /// A filter chip with the central popover (few short options).
  Widget _optionChip<T>({
    required String label,
    required T value,
    required Map<T, String> options,
    required ValueChanged<T> onSelected,
  }) => OptionMenuAnchor<T>(
    selected: value,
    onSelected: onSelected,
    options: [
      for (final o in options.entries)
        SheetOption(value: o.key, label: o.value),
    ],
    builder: (context, toggle) => AppChip(
      label: '$label: ${options[value]}',
      selected: value != null,
      trailing: AppChipTrailing.dropdown,
      onTap: toggle,
    ),
  );
}
