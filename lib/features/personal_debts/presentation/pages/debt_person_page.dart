import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../../contacts/presentation/widgets/contact_picker_sheet.dart';
import '../../../transactions/domain/refs.dart';

import '../../data/personal_debts_repository.dart';
import '../../domain/debt_ledger.dart';
import '../cubit/debt_people_cubit.dart';
import '../cubit/debt_person_cubit.dart';
import '../debt_wiring.dart';

/// `/personal-debts/people/:key` — a STATEMENT with one person (reference
/// §4): the hero (name · age, the side pill + the amount, the editable
/// summary message while a balance is open), then the entries grouped by
/// debt cycle — "ที่มาของยอด · ตั้งแต่เคลียร์ครบ `date`" (the current cycle),
/// and behind "รอบก่อนหน้านี้ ›" the earlier ones. No tabs, no buttons under
/// the card; the shell's + opens debt mode preset to this person. Open = 1
/// call; the earlier cycles = 1 call on the fold's first open; search /
/// filter / sort / next page = 1 call each.
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
  final _search = TextEditingController();
  final _toolbar = ToolbarToggleState.local();
  bool _linking = false;

  @override
  void dispose() {
    _search.dispose();
    _toolbar.dispose();
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

  /// The shell's + opens this preset. A saved entry reaches the page through
  /// [DebtBook] (the balance patches, the page call re-runs).
  QuickCreatePreset _preset(DebtPersonState s) => QuickCreatePreset.debt(
    person: _person(s),
    debtDirection: debtDirectionFor(s.balance?.net),
  );

  /// The entry's detail = the transaction detail page in debt mode
  /// (fe-core). TODO(debt-mode): push `/personal-debts/entries/<id>` once
  /// that route exists; until then an entry with a wallet tx opens the tx.
  void _openEntry(DebtEntry e) {
    final tx = e.transaction;
    if (tx != null) openPage(context, '/transactions/${tx.id}');
  }

  Future<void> _copy(String text) async {
    final l = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAppSnackBar(context, l.fpDebtsCopied, tone: Tone.success);
  }

  Future<void> _share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));

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
            body: TabSwitchBody(
              child: ListPageBody(
                loading: s.firstLoad,
                error: notFound ? null : s.error,
                isEmpty: s.balance == null,
                onRetry: _cubit.load,
                empty: EmptyView(
                  icon: AppIcons.debt,
                  title: l.debtsTimelineEmpty,
                  message: l.debtsEmptyMessage,
                ),
                hasMore: s.hasMore,
                loadingMore: s.current.loadingMore || s.earlier.loadingMore,
                onLoadMore: _cubit.loadMore,
                loadMoreError: s.current.moreError ?? s.earlier.moreError,
                rowDividers: true,
                scrollHeader: s.balance == null
                    ? const []
                    : _header(context, s),
                children: s.balance == null ? const [] : _statement(context, s),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Scrolls with the list: the hero, the link row, the hidden toolbar.
  List<Widget> _header(BuildContext context, DebtPersonState s) {
    final l = AppLocalizations.of(context)!;
    final q = s.query;
    return [
      _hero(context, s),
      if (s.balance!.person.contactId == null)
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
      ListToolbar(
        collapse: _toolbar,
        searchController: _search,
        onSearchChanged: _cubit.search,
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
              q.copyWith(direction: d, clearDirection: d == null),
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
          onChanged: (v) => _cubit.setQuery(q.copyWith(sort: v)),
        ),
      ),
    ];
  }

  /// The statement: the current cycle, then the earlier ones behind a fold.
  List<Widget> _statement(BuildContext context, DebtPersonState s) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final q = s.query;
    final cleared = s.balance!.clearedAt;
    return [
      // The current cycle: where the balance comes from.
      if (s.current.items.isNotEmpty || s.counts.current > 0)
        SectionHeader(
          title: cleared == null
              ? l.fpDebtsCycleHeader
              : l.fpDebtsCycleHeaderSince(
                  DateFormatter.short(cleared, locale: locale),
                ),
        ),
      ..._rows(context, s, s.current),
      if (s.current.items.isEmpty &&
          s.current.status == DebtLoadStatus.loaded &&
          (q.isFiltered || s.counts.earlier == 0))
        EmptyView.compact(
          message: q.isFiltered ? l.debtsEntriesNoMatch : l.debtsTimelineEmpty,
        ),
      // The earlier cycles, behind the fold.
      if (s.counts.earlier > 0)
        if (!s.earlier.opened)
          DetailRow(
            label: l.fpDebtsEarlierLink,
            showChevron: true,
            onTap: _cubit.openEarlier,
          )
        else ...[
          SectionHeader(title: l.fpDebtsEarlierHeader),
          ..._rows(context, s, s.earlier),
        ],
    ];
  }

  Widget _hero(BuildContext context, DebtPersonState s) {
    final l = AppLocalizations.of(context)!;
    final b = s.balance!;
    final symbol = debtCurrencySymbol(context);
    final palette = Theme.of(context).extension<AppColors>()!;
    final side = NetSide.of(b.net);
    final style = switch (side) {
      NetSide.owedToMe => HeroStyle.tinted(color: palette.income),
      NetSide.iOwe => HeroStyle.tinted(color: palette.expense),
      NetSide.even => const HeroStyle.plain(),
    };
    final days = b.daysOutstanding;
    return HeroCard(
      style: style,
      links: [
        if (b.person.contactId != null)
          CardActionButton(
            icon: AppIcons.contact,
            tooltip: l.debtsPersonOpenContact,
            onTap: () => openPage(context, '/contacts/${b.person.contactId}'),
          ),
      ],
      search: ListenableBuilder(
        listenable: _search,
        builder: (context, _) => ToolbarToggleButton(
          state: _toolbar,
          filtered: _search.text.isNotEmpty || s.query.isFiltered,
          tooltip: l.commonSearch,
        ),
      ),
      icon: PersonMark(
        name: b.person.name,
        level: debtPersonLevel(b.person),
        iconCode: b.person.iconCode,
        size: 40,
      ),
      name: Text(b.person.name),
      fact: days == null
          ? null
          : DebtAgeText(l.fpDebtsDaysOutstanding(days), warn: days > 30),
      number: DebtAmountLine(
        net: b.net,
        owedToMeLabel: l.debtsOwedToMe,
        iOweLabel: l.debtsIOwe,
        settledLabel: l.debtsEven,
        currencySymbol: symbol,
      ),
      // Only while a balance is open.
      embedded: side == NetSide.even || s.message.text.isEmpty
          ? null
          : DebtSummaryMessageBox(
              text: s.message.text,
              label: l.fpDebtsMessageLabel,
              copyLabel: l.fpDebtsCopy,
              shareLabel: l.fpDebtsShare,
              onCopy: _copy,
              onShare: _share,
            ),
    );
  }

  /// One cycle's rows (a skeleton / retry while the list has none yet).
  List<Widget> _rows(
    BuildContext context,
    DebtPersonState s,
    DebtEntryList list,
  ) {
    final l = AppLocalizations.of(context)!;
    final symbol = debtCurrencySymbol(context);
    final locale = Localizations.localeOf(context).languageCode;
    final name = _name(s);
    if (list.items.isEmpty) {
      if (list.status == DebtLoadStatus.loading) {
        return const [ListRowSkeleton(), ListRowSkeleton()];
      }
      if (list.status == DebtLoadStatus.error) {
        return [
          LoadMoreErrorRow(
            onRetry: identical(list, s.earlier)
                ? _cubit.retryEarlier
                : _cubit.load,
          ),
        ];
      }
    }
    return [for (final e in list.items) _ledgerRow(l, e, name, symbol, locale)];
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
      signed: true,
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
