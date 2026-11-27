import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../recurring/domain/rule_draft.dart';
import '../../../recurring/domain/rule_group.dart';
import '../../../recurring/presentation/pages/rule_page.dart';
import '../../../recurring/presentation/widgets/rule_due_box.dart';
import '../../../recurring/presentation/widgets/rules_box.dart';
import '../../../../app/shell/app_page.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/quick_create_look.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../../contacts/presentation/widgets/contact_picker.dart';
import '../../../recurring/data/recurring_repository.dart';
import '../../../recurring/domain/recurring.dart' show RecurringKind;
import '../../../transactions/domain/refs.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';

import '../../data/personal_debts_repository.dart';
import '../../domain/debt_plans.dart';
import '../../domain/debt_ledger.dart';
import '../cubit/debt_people_cubit.dart';
import '../cubit/debt_person_cubit.dart';
import '../debt_person_preset.dart';
import '../debt_wiring.dart';

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
  /// Bumped when a rule is saved here: ต้องทำ loads again.
  int _rulesTick = 0;
  final _heroKey = GlobalKey();
  final _search = TextEditingController();
  final _toolbar = PpForgeListToolbarState.local();
  bool _linking = false;
  bool _showEarlier = false;

  /// 0.4.3: this counterparty's debt plans that no reminder pays (those that
  /// one pays show in the รายการประจำ section).
  List<DebtPlan> _plans = const [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final key = context
        .findAncestorWidgetOfExactType<DebtPersonPage>()
        ?.personKey;
    final repo = context.read<PersonalDebtsRepository>();
    try {
      final all = await repo.plans();
      if (mounted) {
        setState(
          () => _plans = [
            for (final p in all)
              if (p.creditorKey == key && p.recurringId == null) p,
          ],
        );
      }
    } catch (_) {
      // the page shows without them
    }
  }

  Widget? _plansSection(AppLocalizations l) {
    if (_plans.isEmpty) return null;
    return SectionCard(
      key: const ValueKey('debtPlans'),
      title: '${l.debtPlanTitle} | ${_plans.length}',
      children: [
        for (final p in _plans)
          InfoRow(
            key: ValueKey('debtPlan-${p.id}'),
            label: '${p.name} · ${p.plan.done}/${p.plan.count}',
            valueWidget: MoneyText(p.plan.leftTotal),
            showChevron: true,
            onTap: () async {
              await context.push('/personal-debts/plans/${p.id}');
              if (mounted) _loadPlans();
            },
          ),
      ],
    );
  }

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
  ).withLook(QuickCreateLook.debt(context));

  /// Every statement line opens its own page, debt or repayment (0.4.1-1 D4:
  /// a repayment is a person-book row, its id the entry's, a transaction
  /// optional).
  void _openEntry(DebtEntry e) =>
      openPage(context, '/personal-debts/entries/${e.id}');

  /// [จ่ายคืน ฿x] / [รับคืน ฿x]: quick create, settle chip, the open amount.
  Future<void> _settle(DebtPersonState s) async {
    final net = s.balance?.net ?? 0;
    final saved = await showQuickCreateSheet(
      context,
      preset: QuickCreatePreset.debt(
        person: _person(s),
        debtDirection: debtDirectionFor(net),
        debtSub: DebtEntrySub.repay,
        amount: net.abs(),
      ),
    );
    if (saved && mounted) await _offerInstallmentMark(s, owedToMe: net > 0);
  }

  /// After a repayment: ทำเครื่องหมายว่าจ่ายงวดแล้ว on the oldest unticked
  /// installment of this counterparty's plan item on that side (a tick only;
  /// the money is the repayment).
  Future<void> _offerInstallmentMark(
    DebtPersonState s, {
    required bool owedToMe,
  }) async {
    final pick = installmentToMark(s.recurrings, owedToMe: owedToMe);
    if (pick == null) return;
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.debtsMarkInstallment,
      message: l.debtsMarkInstallmentOf(pick.item.name, pick.seq),
      confirmLabel: l.recurringInstallmentMarkPaid,
    );
    if (!ok || !mounted) return;
    try {
      await RecurringRepository.of(
        context,
      ).markInstallment(pick.item.id, pick.seq, paid: true);
      if (mounted) unawaited(_cubit.load());
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _copy(String text) async {
    final l = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showPpForgeSnackBar(context, l.fpDebtsCopied, tone: Tone.success);
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
    return showPpForgeSheet<void>(
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
      showPpForgeSnackBar(
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
      showErrorSnackBar(context, e);
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
          child: AppPage(
            topBar: AppTopBar(title: _name(s), showBack: true),
            body: CompactHeroScope(
              heroKey: _heroKey,
              bar: s.balance == null ? null : _compactBar(context, s),
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
      KeyedSubtree(key: _heroKey, child: _hero(context, s)),
      if (s.balance!.person.contactId == null && !s.balance!.isInstitution)
        SectionCard(
          children: [
            PpForgeDetailRow(
              leading: _linking
                  ? const PpForgeSpinner(size: PpForgeSpinnerSize.medium)
                  : const PpForgeIcon(AppIcons.addContact),
              label: l.debtsPersonAddContact,
              helper: l.debtsPersonAddContactHint,
              showChevron: true,
              onTap: _linking ? null : _linkToContact,
            ),
          ],
        ),
      if (s.balance case final b?) ...[
        // ต้องทำ: the due rounds of this counterparty's rules
        RuleDueBox(
          key: ValueKey('personDue:${b.key}'),
          filter: RuleFilter(debtKey: b.key),
          reloadKey: _rulesTick,
          onChanged: () => unawaited(_cubit.load()),
        ),
        _rulesBox(l, b),
      ],
      ?_plansSection(l),
      PpForgeListToolbar(
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

  /// + จดหนี้: quick create in debt mode with this person.
  Future<void> _record(DebtPersonState s) => showQuickCreateSheet(
    context,
    preset: QuickCreatePreset.debt(
      person: _person(s),
      debtSub: DebtEntrySub.record,
    ),
  );

  /// + รายการประจำ: a new หนี้ item with this counterparty picked.
  /// A debt rule with this person / institution, its side from the net (I
  /// owe them = received).
  RuleDraft _rulePreset(PersonBalance b) =>
      RuleDraft.blank(RecurringKind.debt).copyWith(
        person: b.isInstitution ? null : b.person,
        institution: b.institution,
        direction: b.net < 0
            ? DebtEntryDirection.received
            : DebtEntryDirection.paid,
      );

  /// รายการอัตโนมัติ: the debt rules of this counterparty (spec §2.1, §3;
  /// mock Person): pulled by its key, + prefills the person.
  Widget _rulesBox(AppLocalizations l, PersonBalance b) => RulesBox(
    key: ValueKey('personRules:${b.key}'),
    filter: RuleFilter(debtKey: b.key),
    preset: _rulePreset(b),
    newName: l.rulesNewNamePerson(b.person.name),
    trackingType: b.isInstitution ? 'installment' : 'person_debt',
    onChanged: () {
      setState(() => _rulesTick++);
      unawaited(_cubit.load());
    },
  );

  void _newRecurring(DebtPersonState s) {
    final b = s.balance!;
    unawaited(
      context.push<Object?>(
        '/recurring-rules/new',
        extra: RulePageArgs(
          fromPage: RuleFromPage(
            newName: AppLocalizations.of(
              context,
            )!.rulesNewNamePerson(b.person.name),
            preset: _rulePreset(b),
            trackingType: b.isInstitution ? 'installment' : 'person_debt',
          ),
        ),
      ),
    );
  }

  /// The hero, small: the person (or institution), name and the net.
  PpForgeCompactHeroCard _compactBar(BuildContext context, DebtPersonState s) {
    final b = s.balance!;
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    final color = switch (NetSide.of(b.net)) {
      NetSide.owedToMe => palette.income,
      NetSide.iOwe => palette.expense,
      NetSide.even => null,
    };
    return PpForgeCompactHeroCard(
      style: color == null
          ? const HeroStyle.plain()
          : HeroStyle.tinted(color: color),
      leading: b.institution != null
          ? InstitutionMark(
              name: b.institution!.name,
              iconCode: b.institution!.iconCode,
              size: 28,
            )
          : PersonMark(
              level: debtPersonLevel(b.person),
              avatar: b.person.avatar,
              size: 28,
            ),
      title: PpForgeText(b.person.name, role: PpForgeTextRole.title),
      trailing: PpForgeText(
        moneyString(context, b.net.abs(), symbol: debtCurrencySymbol(context)),
        role: PpForgeTextRole.money,
        color: color,
      ),
    );
  }

  Widget _hero(BuildContext context, DebtPersonState s) {
    final l = AppLocalizations.of(context)!;
    final b = s.balance!;
    final symbol = debtCurrencySymbol(context);
    final palette = Theme.of(context).extension<PpForgeColors>()!;
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
    return PpForgeHeroCard(
      style: style,
      content: [
        HeroIdentity(
          icon: b.institution != null
              ? InstitutionMark(
                  name: b.institution!.name,
                  iconCode: b.institution!.iconCode,
                )
              : PersonMark(
                  level: debtPersonLevel(b.person),
                  avatar: b.person.avatar,
                  size: 40,
                ),
          name: Text(name),
          fact: fact.isEmpty ? null : DebtAgeText(fact, warn: (days ?? 0) > 30),
          actions: [
            if (b.institution != null)
              CardActionButton(
                icon: AppIcons.bank,
                tooltip: l.debtsInstitutionInfo,
                onTap: () =>
                    openPage(context, '/institutions/${b.institution!.id}'),
              ),
            if (b.person.contactId != null)
              CardActionButton(
                icon: AppIcons.contact,
                tooltip: l.debtsPersonOpenContact,
                onTap: () =>
                    openPage(context, '/contacts/${b.person.contactId}'),
              ),
            ListenableBuilder(
              listenable: _search,
              builder: (context, _) => PpForgeListToolbarToggle(
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
        HeroChipRow(
          chips: [
            if (!b.isInstitution)
              PpForgeChip(
                key: const ValueKey('debtAddEntry'),
                label: l.debtAddEntry,
                icon: AppIcons.add,
                onTap: () => unawaited(_record(s)),
              ),
            PpForgeChip(
              key: const ValueKey('debtAddRecurring'),
              label: l.debtAddRecurring,
              icon: AppIcons.add,
              onTap: () => _newRecurring(s),
            ),
          ],
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
            w is PpForgeListHeader ? w : Opacity(opacity: 0.7, child: w),
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
    final palette = Theme.of(context).extension<PpForgeColors>()!;
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
            PpForgeListHeader(
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
      showErrorSnackBar(context, err);
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
    final palette = Theme.of(context).extension<PpForgeColors>()!;
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
    return PpForgeListRow(
      key: ValueKey(e.id),
      leading: leading,
      title: title,
      titleChips: [
        if (e.recurring case final ref?)
          ListRowChip(
            debtRecurringTagText(ref, _cubit.state.recurrings),
            icon: AppIcons.recurring,
          ),
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
    builder: (context, toggle) => PpForgeChip(
      label: '$label: ${options[value]}',
      selected: value != null,
      trailing: PpForgeChipTrailing.dropdown,
      onTap: toggle,
    ),
  );
}
