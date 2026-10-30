import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../../contacts/presentation/widgets/contact_picker.dart';
import '../../../recurring/domain/recurring.dart'
    show RecurringKind, RecurringStatus;
import '../../../recurring/presentation/recurring_rows.dart'
    show debtParts, pauseReasonChip, recurringIconCode;
import '../../../transactions/domain/refs.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';

import '../../data/personal_debts_repository.dart';
import '../../domain/debt_ledger.dart';
import '../cubit/debt_people_cubit.dart';
import '../cubit/debt_person_cubit.dart';
import '../debt_person_preset.dart';
import '../debt_wiring.dart';
import '../../../settings/presentation/widgets/auto_sync_setting.dart';

/// หนี้ · หน้าคน (owner 2026-10-22, mock DebtPerson): the hero (avatar,
/// name, age | since, 🔍; "รอจ่ายให้ลี" + the big amount; [จ่ายคืน ฿x]
/// [สรุปยอด / ทวง]), then the statement in the tx-list style — day groups
/// with the day's change, each day's lines in one card, repayments on a soft
/// background — and the earlier cycles behind "เคลียร์ครบ … | ดูรอบก่อน ▾".
class DebtPersonPage extends StatelessWidget {
  const DebtPersonPage({required this.personKey, this.name, super.key});

  final String personKey;

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
  final _toolbar = AppListToolbarState.local();
  bool _linking = false;
  bool _showEarlier = false;

  @override
  void dispose() {
    _search.dispose();
    _toolbar.dispose();
    super.dispose();
  }

  DebtPersonCubit get _cubit => context.read<DebtPersonCubit>();

  String get _locale => Localizations.localeOf(context).languageCode;

  String _name(DebtPersonState s) =>
      s.balance?.person.name ?? widget.name ?? '';

  EmbeddedPerson _person(DebtPersonState s) =>
      debtPersonOf(personKey: s.personKey, name: _name(s), balance: s.balance);

  QuickCreatePreset _preset(DebtPersonState s) => debtPersonPreset(
    personKey: s.personKey,
    name: _name(s),
    balance: s.balance,
  );

  /// Every statement line opens its own page, debt or repayment (0.4.1-1 D4:
  /// a repayment is a person-book row, its id the entry's, a transaction
  /// optional).
  void _openEntry(DebtEntry e) =>
      openPage(context, '/personal-debts/entries/${e.id}');

  /// [จ่ายคืน ฿x] / [รับคืน ฿x]: quick create, settle chip, the open amount.
  Future<void> _settle(DebtPersonState s) async {
    final net = s.balance?.net ?? 0;
    await showQuickCreateSheet(
      context,
      preset: QuickCreatePreset.debt(
        person: _person(s),
        debtDirection: debtDirectionFor(net),
        debtSub: DebtEntrySub.repay,
        amount: net.abs(),
      ),
    );
  }

  Future<void> _copy(String text) async {
    final l = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAppSnackBar(context, l.fpDebtsCopied, tone: Tone.success);
  }

  Future<void> _share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));

  /// สรุปยอด (I owe) / ทวง (they owe me): pick รอบนี้ / ยอดคงเหลืออย่าง
  /// เดียว, edit, copy or share.
  Future<void> _openShare(DebtPersonState s) {
    final l = AppLocalizations.of(context)!;
    final name = _name(s);
    final owedToMe = (s.balance?.net ?? 0) > 0;
    final m = s.message;
    return showAppSheet<void>(
      context,
      title: owedToMe
          ? l.debtPersonChaseTitle(name)
          : l.debtPersonSummaryTitle(name),
      builder: (_) => DebtShareSheet(
        variants: [
          (label: l.debtShareThisCycle, text: m.text),
          if (m.textBalanceOnly.isNotEmpty)
            (label: l.debtShareBalanceOnly, text: m.textBalanceOnly),
        ],
        fieldLabel: l.debtShareFieldLabel,
        copyLabel: l.fpDebtsCopy,
        shareLabel: l.debtShareSend,
        onCopy: _copy,
        onShare: _share,
      ),
    );
  }

  Future<void> _linkToContact() async {
    final l = AppLocalizations.of(context)!;
    final name = _name(_cubit.state);
    // A contact picked or just created both link this name to it.
    final contact = await ContactPicker.contactFor(context, name: name);
    if (contact == null || !mounted) return;
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

  void _toggleEarlier() {
    setState(() => _showEarlier = !_showEarlier);
    if (_showEarlier) _cubit.openEarlier();
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
                // Each day's lines in one card (the tx list's look).
                rowCards: true,
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

  List<Widget> _header(BuildContext context, DebtPersonState s) {
    final l = AppLocalizations.of(context)!;
    final q = s.query;
    return [
      _hero(context, s),
      if (s.balance!.person.contactId == null)
        SectionCard(
          children: [
            AppDetailRow(
              leading: _linking
                  ? const AppSpinner(size: AppSpinnerSize.medium)
                  : const AppIcon(AppIcons.addContact),
              label: l.debtsPersonAddContact,
              helper: l.debtsPersonAddContactHint,
              showChevron: true,
              onTap: _linking ? null : _linkToContact,
            ),
          ],
        ),
      // Auto sync only reaches a linked person; one account-wide value.
      if (s.balance!.person.linked) autoSyncSection(l, AutoSyncKind.debts),
      _recurringSection(l, s),
      AppListToolbar(
        state: _toolbar,
        search: ListToolbarSearch(
          controller: _search,
          onChanged: _cubit.search,
          hint: l.debtsEntrySearchHint,
        ),
        filters: [
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
        sort: SortChip<DebtEntrySort>(
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

  /// K13: the person's หนี้ recurring settings (each opens its page), then
  /// ตั้งเป็นรายการประจำ: a new หนี้ setting with this person picked.
  Widget _recurringSection(AppLocalizations l, DebtPersonState s) {
    final person = s.balance!.person;
    final rules = s.recurring;
    return SectionCard(
      title: rules.isEmpty ? null : l.recurringTitle,
      children: [
        for (final r in rules) _recurringRow(l, r),
        DetailAddRow(
          key: const ValueKey('debtPersonAddRecurring'),
          label: l.debtsPersonAddRecurring,
          icon: AppIcons.recurring,
          onTap: () => openPage(
            context,
            Uri(
              path: '/recurring/new',
              queryParameters: {
                'kind': RecurringKind.debt.toJson(),
                'person_name': person.name,
                'contact': ?person.contactId,
              },
            ).toString(),
          ),
        ),
      ],
    );
  }

  /// One setting: its icon and name (ไม่มียอดค้าง / พักไว้ beside it), then
  /// จดหนี้ | จ่ายหนี้ and when it is next; its next amount on the right.
  Widget _recurringRow(AppLocalizations l, DebtPersonRecurring r) {
    final paused = r.status == RecurringStatus.paused;
    final next = r.nextDate;
    final amount = r.nextAmount ?? r.amount;
    final received = r.direction == DebtEntryDirection.received;
    return AppListRow(
      key: ValueKey('debtPersonRecurring:${r.id}'),
      leading: IconDisplay(
        type: IconType.category,
        size: 36,
        iconCode: recurringIconCode(kind: RecurringKind.debt, own: r.iconCode),
      ),
      title: r.name,
      status: paused
          ? (pauseReasonChip(l, r.pauseReason) ??
                ListRowChip(
                  l.recurringStatusPaused,
                  tone: Tone.warning,
                  icon: AppIcons.pause,
                ))
          : r.dueCount > 0
          ? ListRowChip(
              l.occurrenceStateNotCreated,
              tone: Tone.warning,
              selected: true,
            )
          : null,
      line2: ListRowLine(
        icon: AppIcons.recurring,
        parts: [
          ...debtParts(l, person: null, sub: r.sub),
          if (next != null && !paused) dueLabel(l, date: next),
        ],
      ),
      trailing: amount > 0
          ? ListRowTrailing.value(
              MoneyText(
                received ? amount : -amount,
                tone: MoneyTone.signed,
                symbol: debtCurrencySymbol(context),
              ),
            )
          : null,
      dimmed: paused,
      onTap: () => openPage(context, '/recurring/${r.id}'),
    );
  }

  Widget _hero(BuildContext context, DebtPersonState s) {
    final l = AppLocalizations.of(context)!;
    final b = s.balance!;
    final symbol = debtCurrencySymbol(context);
    final palette = Theme.of(context).extension<AppColors>()!;
    final side = NetSide.of(b.net);
    final color = switch (side) {
      NetSide.owedToMe => palette.income,
      NetSide.iOwe => palette.expense,
      NetSide.even => null,
    };
    final style = color == null
        ? const HeroStyle.plain()
        : HeroStyle.tinted(color: color);
    final name = b.person.name;
    final days = b.daysOutstanding;
    final first = b.firstActivityAt;
    final fact = [
      if (days != null) l.fpDebtsDaysOutstanding(days),
      if (first != null)
        l.debtPersonSince(DateFormat.yMMM(_locale).format(first)),
    ].join(' | ');
    final money = moneyString(context, b.net.abs(), symbol: symbol);
    return AppHeroCard(
      style: style,
      content: [
        HeroIdentity(
          icon: PersonMark(
            name: name,
            level: debtPersonLevel(b.person),
            iconCode: b.person.iconCode,
            avatar: b.person.avatar,
            size: 40,
          ),
          name: Text(name),
          fact: fact.isEmpty ? null : DebtAgeText(fact, warn: (days ?? 0) > 30),
          actions: [
            if (b.person.contactId != null)
              CardActionButton(
                icon: AppIcons.contact,
                tooltip: l.debtsPersonOpenContact,
                onTap: () =>
                    openPage(context, '/contacts/${b.person.contactId}'),
              ),
            ListenableBuilder(
              listenable: _search,
              builder: (context, _) => AppListToolbarToggle(
                state: _toolbar,
                filtered: _search.text.isNotEmpty || s.query.isFiltered,
                tooltip: l.commonSearch,
              ),
            ),
          ],
        ),
        // [↙ ลูกหนี้] ฿x from the start (owner 2026-10-23); settled = the word.
        DebtAmountLine(
          key: const ValueKey('debtSentence'),
          net: b.net,
          owedToMeLabel: l.debtsOwedToMe,
          iOweLabel: l.debtsIOwe,
          settledLabel: l.debtsEven,
          currencySymbol: symbol,
        ),
        DebtPersonActions(
          color: color,
          settleLabel: switch (side) {
            NetSide.owedToMe => l.debtPersonSettleReceive(money),
            NetSide.iOwe => l.debtPersonSettlePay(money),
            NetSide.even => null,
          },
          onSettle: side == NetSide.even ? null : () => _settle(s),
          shareLabel: side == NetSide.owedToMe
              ? l.debtPersonChase
              : l.debtPersonSummary,
          onShare: () => _openShare(s),
        ),
      ],
    );
  }

  List<Widget> _statement(BuildContext context, DebtPersonState s) {
    final l = AppLocalizations.of(context)!;
    final q = s.query;
    final cleared = s.balance!.clearedAt;
    return [
      ..._rows(context, s, s.current),
      if (s.current.items.isEmpty &&
          s.current.status == DebtLoadStatus.loaded &&
          (q.isFiltered || s.counts.earlier == 0))
        EmptyView.compact(
          message: q.isFiltered ? l.debtsEntriesNoMatch : l.debtsTimelineEmpty,
        ),
      if (s.counts.earlier > 0) ...[
        CycleDivider(
          key: const ValueKey('earlierDivider'),
          label: _showEarlier
              ? l.debtEarlierHide
              : cleared == null
              ? l.debtEarlierShowPlain
              : l.debtEarlierShow(_dayLabel(cleared, withWeekday: false)),
          onTap: _toggleEarlier,
        ),
        if (_showEarlier)
          for (final w in _rows(context, s, s.earlier))
            w is AppListHeader ? w : Opacity(opacity: 0.7, child: w),
      ],
    ];
  }

  /// "ศ. 10 ต.ค. 2026".
  String _dayLabel(DateTime d, {bool withWeekday = true}) => withWeekday
      ? DateFormat('EEE d MMM y', _locale).format(d)
      : DateFormat.MMMd(_locale).format(d);

  /// The day's words (mock): away from zero = "เพิ่ม ฿x" in the side's
  /// colour, toward zero = "ลดลง ฿x" in the brand colour.
  (String, Color) _dayNote(double change, double? after, String symbol) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final money = moneyString(context, change.abs(), symbol: symbol);
    final end = after ?? _cubit.state.balance?.net ?? change;
    final before = end - change;
    final grows = end.abs() > before.abs() + 0.004;
    if (!grows) {
      return (l.debtDayDown(money), Theme.of(context).colorScheme.primary);
    }
    return (l.debtDayUp(money), end > 0 ? palette.income : palette.expense);
  }

  List<Widget> _rows(
    BuildContext context,
    DebtPersonState s,
    DebtEntryList list,
  ) {
    final l = AppLocalizations.of(context)!;
    final symbol = debtCurrencySymbol(context);
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
    // The BE's day totals when it sends them; else the lines' own sum.
    final beDays = {for (final d in list.days) _ymd(d.date): d};
    final out = <Widget>[];
    String? day;
    for (var i = 0; i < list.items.length; i++) {
      final e = list.items[i];
      final date = e.date;
      final key = date == null ? '' : _ymd(date);
      if (key != day) {
        day = key;
        if (date != null) {
          final be = beDays[key];
          final sameDay = [
            for (final x in list.items.skip(i))
              if (x.date != null && _ymd(x.date!) == key) x,
          ];
          final change =
              be?.change ??
              sameDay.fold<double>(0, (a, x) => a + x.signedAmount);
          final after = be?.balanceAfter ?? sameDay.first.runningBalance;
          final (note, color) = _dayNote(change, after, symbol);
          out.add(
            AppListHeader(
              key: ValueKey('day:$key:${identical(list, s.earlier)}'),
              title: _dayLabel(date),
              trailing: ListHeaderTrailing.text(note, color: color),
            ),
          );
        }
      }
      out.add(_statementRow(l, e, name, symbol));
    }
    return out;
  }

  static String _ymd(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Rows whose ✓ is saving: one save per row, the circle spins.
  final Set<String> _paidSaving = {};

  Future<void> _togglePaid(DebtEntry e) async {
    if (!_paidSaving.add(e.id)) return;
    setState(() {});
    try {
      await _cubit.setPaid(e.id, !e.paid);
    } catch (err) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      showAppSnackBar(
        context,
        err is ApiException ? err.message : l.errorUnknownMessage,
        tone: Tone.danger,
      );
    } finally {
      if (mounted) setState(() => _paidSaving.remove(e.id));
    }
  }

  /// The sub-line: where a debt came from (a split, someone paid, an event);
  /// the wallet is a chip by the title instead (owner 2026-10-23).
  String? _originLine(AppLocalizations l, DebtEntry e, String name) {
    if (e.isRepayment) return null;
    final o = e.origin;
    switch (o?.kind) {
      case 'paid_by' || 'partner':
        return l.debtRowTheyPaid(name);
      case 'split':
        final amount = o?.amount;
        return amount == null
            ? l.debtRowIPaid
            : l.debtRowSplitBill(
                moneyString(
                  context,
                  amount,
                  symbol: debtCurrencySymbol(context),
                ),
              );
      case 'event':
        return l.debtRowEvent(o?.title ?? '');
    }
    return null;
  }

  Widget _statementRow(
    AppLocalizations l,
    DebtEntry e,
    String name,
    String symbol,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final paid = e.direction == DebtEntryDirection.paid;
    final title =
        e.description ??
        (e.isRepayment
            ? (paid ? l.debtRowIPaidBack(name) : l.debtRowTheyPaidBack(name))
            : (paid ? l.debtEntryPaidTo(name) : l.debtEntryReceivedFrom(name)));
    final sub = _originLine(l, e, name);
    final wallet = e.origin?.account ?? e.transaction?.account;
    final palette = Theme.of(context).extension<AppColors>()!;
    // A debt's icon IS its จ่ายแล้ว circle (the detail page's): tap it to
    // tick / untick here; the rest of the row opens the debt.
    final Widget leading = e.isRepayment
        ? IconTile(
            icon: AppIcons.cash,
            color: scheme.primary,
            size: 36,
            style: IconTileStyle.solid,
          )
        : CheckCircleButton(
            key: ValueKey('debtPaidMark:${e.id}'),
            checked: e.paid,
            loading: _paidSaving.contains(e.id),
            onChanged: (_) => _togglePaid(e),
            size: 36,
            color: palette.income,
            tooltip: l.debtsPaidChip,
          );
    // A repayment's amount stays plain, a debt's takes the side's colour.
    return AppListRow(
      key: ValueKey(e.id),
      leading: leading,
      title: title,
      titleChips: [
        if (wallet != null)
          walletRowChip(
            context,
            name: wallet.name,
            iconCode: wallet.iconCode,
            type: wallet.type,
          ),
      ],
      line2: sub == null ? null : ListRowLine(parts: [sub]),
      trailing: ListRowTrailing.value(
        MoneyText(
          e.amount,
          symbol: symbol,
          tone: e.isRepayment
              ? MoneyTone.plain
              : paid
              ? MoneyTone.income
              : MoneyTone.expense,
        ),
      ),
      onTap: () => _openEntry(e),
    );
  }

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
