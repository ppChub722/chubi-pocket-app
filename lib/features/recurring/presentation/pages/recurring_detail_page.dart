import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/app_page.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/data/write_effects.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurrence_rule.dart';
import '../../domain/recurring.dart';
import '../../domain/recurring_item.dart';
import '../../domain/recurring_page.dart';
import '../due_boxes.dart';
import '../item_write_apply.dart';
import '../occurrence_actions.dart';
import '../recurring_rows.dart';
import '../widgets/rule_row.dart';
import 'recurring_form_page.dart' show trackingTypeLabel;
import 'rule_page.dart' show RulePageArgs;

enum _Tab { past, upcoming }

class RecurringDetailPage extends StatefulWidget {
  const RecurringDetailPage({required this.id, super.key});

  final String id;

  @override
  State<RecurringDetailPage> createState() => _RecurringDetailPageState();
}

class _RecurringDetailPageState extends State<RecurringDetailPage> {
  RecurringDetail? _detail;
  bool _loading = false;

  ApiException? _error;

  ApiException? _refreshError;

  _Tab _tab = _Tab.upcoming;

  /// Amounts changed in the tabs' waiting rows, by occurrence.
  final _rowAmounts = <String, double?>{};
  bool _busy = false;
  bool _changed = false;

  // the hero's description (read only; ✎ edits it on /settings)
  final _description = TextEditingController();
  final _descriptionFocus = FocusNode();

  ItemPage _produced = const ItemPage();
  bool _producedMore = false;
  Object? _producedMoreError;

  ItemPage _upcoming = const ItemPage();
  bool _upcomingMore = false;
  Object? _upcomingMoreError;

  /// Bumped on every setState: the ปรับแต่งล่วงหน้า sheet (another route)
  /// rebuilds from it.
  final _sheetTick = ValueNotifier<int>(0);

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _sheetTick.value++;
  }

  RecurringRepository get _repo => RecurringRepository.of(context);
  Recurring? get _recurring => _detail?.recurring;

  @override
  void initState() {
    super.initState();
    _offEffects = WriteEffectsBus.instance.listen(_onEffects);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
      context.read<TagsCubit>().loadIfNeeded();
      _load(first: true);
    });
  }

  void Function()? _offEffects;

  /// B2: this rule's slots any write changed (a tx deleted or unlinked
  /// elsewhere too) patch the lists in place; no re-fetch.
  void _onEffects(WriteEffects e) {
    final r = ItemWriteResult.fromEffects(e);
    final id = widget.id;
    if (r == null || !mounted || _detail == null) return;
    final mine = [
      for (final i in r.items)
        if (i.ruleId == id) i,
    ];
    if (mine.isEmpty) return;
    final applied = applyItemWrite(
      ItemWriteResult(items: mine),
      produced: _produced,
      upcoming: _upcoming,
      detail: _detail,
      now: today(),
    );
    setState(() {
      _produced = applied.produced;
      _upcoming = applied.upcoming;
      _detail = applied.detail;
    });
  }

  @override
  void dispose() {
    _offEffects?.call();
    _sheetTick.dispose();
    _description.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _load({bool first = false}) async {
    if (_detail == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final d = await _repo.get(widget.id);
      if (!mounted) return;
      _take(d);
      setState(() {
        _error = null;
        _refreshError = null;
      });
    } catch (e, st) {
      if (!mounted) return;
      final err = ApiException.from(e, st);
      setState(() {
        if (_detail == null) {
          _error = err;
        } else {
          _refreshError = err;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _take(RecurringDetail d) {
    context.read<AccountsCubit>().patchBalances(d.balances);
    setState(() {
      _detail = d;
      _produced = d.produced;
      _upcoming = d.upcoming;
    });
    _description.text = d.recurring.description ?? '';
  }

  Future<void> _loadMoreProduced() async {
    if (!_produced.hasMore || _producedMore) return;
    final current = _produced;
    setState(() {
      _producedMore = true;
      _producedMoreError = null;
    });
    try {
      final next = await _repo.items(
        widget.id,
        upcoming: false,
        page: current.page + 1,
      );
      if (mounted) setState(() => _produced = next.after(current));
    } catch (e, st) {
      if (mounted) {
        setState(() => _producedMoreError = ApiException.from(e, st));
      }
    } finally {
      if (mounted) setState(() => _producedMore = false);
    }
  }

  /// A no-end rule's next year (ดูปีถัดไป), else the next page.
  Future<void> _loadMoreUpcoming() async {
    final current = _upcoming;
    final from = current.nextFrom;
    if (current.windowed ? from == null : !current.hasMore) return;
    await _fetchUpcoming(
      () => _repo.items(
        widget.id,
        upcoming: true,
        page: current.page + 1,
        from: from,
      ),
      after: current,
    );
  }

  Future<void> _fetchUpcoming(
    Future<ItemPage> Function() call, {
    ItemPage? after,
  }) async {
    if (_upcomingMore) return;
    setState(() {
      _upcomingMore = true;
      _upcomingMoreError = null;
    });
    try {
      final next = await call();
      if (mounted) {
        setState(() => _upcoming = after == null ? next : next.after(after));
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => _upcomingMoreError = ApiException.from(e, st));
      }
    } finally {
      if (mounted) setState(() => _upcomingMore = false);
    }
  }

  void _onTab(_Tab t) => setState(() => _tab = t);

  void _applyItems(ItemWriteResult r) {
    _changed = true;
    final applied = applyItemWrite(
      r,
      produced: _produced,
      upcoming: _upcoming,
      detail: _detail,
      now: today(),
    );
    setState(() {
      _produced = applied.produced;
      _upcoming = applied.upcoming;
      _detail = applied.detail;
    });
    if (r.setting == null) _load();
  }

  Future<void> _action(RecurringAction a) =>
      _detailCall(() => _repo.action(widget.id, a));

  /// The form on one line ([lineId]) or a new blank one ([newLine]); the
  /// item's other lines go back unchanged.

  Future<void> _openPlanTable() async {
    final List<PlanInstallment> rows;
    try {
      rows = await _repo.installments(widget.id);
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
      return;
    }
    if (!mounted) return;
    await showPlanTable(
      context,
      rows,
      onPick: (i) => unawaited(_installmentMenu(i)),
    );
  }

  Future<void> _installmentMenu(PlanInstallment i) async {
    final id = widget.id;
    final a = await showInstallmentMenu(context, i);
    if (!mounted || a == null) return;
    switch (a) {
      case InstallmentMenu.edit:
        final r = await showInstallmentEditSheet(context, i);
        if (r == null || !mounted) return;
        await _detailCall(
          () => _repo.updateInstallment(
            id,
            i.seq,
            dueDate: r.due,
            amount: r.amount,
            principal: r.principal,
            interest: r.interest,
          ),
        );
      case InstallmentMenu.markPaid || InstallmentMenu.unmark:
        await _detailCall(
          () => _repo.markInstallment(
            id,
            i.seq,
            paid: a == InstallmentMenu.markPaid,
          ),
        );
    }
  }

  /// One call that answers with the item page; the page takes it.
  Future<void> _detailCall(Future<RecurringDetail> Function() call) async {
    setState(() => _busy = true);
    try {
      final d = await call();
      if (!mounted) return;
      _changed = true;
      HapticFeedback.mediumImpact();
      _take(d);
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final d = _detail;
    if (d == null) {
      return AppPage(
        topBar: AppTopBar(title: l.recurringTitle, showBack: true),
        body: AsyncStateView.fallback(
          loading: _loading || _error == null,
          error: _error,
          onRetry: () => _load(first: true),
          notFound: EmptyView(
            icon: AppIcons.empty,
            title: l.recurringNotFound,
            message: l.recurringNotFoundMessage,
          ),
        ),
      );
    }
    // View only: the recurring's own fields edit on /settings, a rule on
    // its page (mock DetailNew).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_changed);
      },
      child: AppPage(
        topBar: AppTopBar(
          title: d.recurring.name,
          showBack: true,
          onBack: () => context.pop(_changed),
        ),
        body: BusyScope(
          busy: _busy,
          child: Builder(builder: (context) => _viewBody(context, l, d)),
        ),
      ),
    );
  }

  HeroStyle _style(Recurring r) {
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    return HeroStyle.tinted(
      color: r.shownIconCode.tintFor(palette),
      glyph: AppIcons.scheduled,
    );
  }

  Widget _viewBody(
    BuildContext context,
    AppLocalizations l,
    RecurringDetail d,
  ) {
    final r = d.recurring;
    final banner = _refreshError == null
        ? null
        : PpForgeMessage(
            tone: Tone.danger,
            message: errorText(l, _refreshError!),
          );
    return TabbedDetailBody<_Tab>(
      hero: _viewHero(l, d),
      belowHero: [
        ?banner,
        ?_notice(l, r),
        ?_focusCard(l, r),
        if (d.page?.plan case final plan?)
          RecurringPlanSection(plan: plan, onTable: _openPlanTable),
        if (d.page case final page?) ..._rulesSection(l, page),
      ],
      tabs: [
        PpForgeTab(
          value: _Tab.upcoming,
          label: l.fpRecurringTabUpcoming,
          icon: AppIcons.date,
        ),
        PpForgeTab(
          value: _Tab.past,
          label: l.fpRecurringTabPast,
          icon: AppIcons.history,
        ),
      ],
      selected: _tab,
      onChanged: _onTab,
      compactBar: _compactBar(r),
      tabBuilder: (context, t) => switch (t) {
        _Tab.past => _pastTab(l, r),
        _Tab.upcoming => _upcomingTab(l, r),
      },
    );
  }

  /// Rules | n (+ เพิ่ม rule, top right) and one row per rule (mock
  /// DetailNew): a tap opens the rule page, ⋯ = พัก / ทำต่อ / ลบ.
  List<Widget> _rulesSection(AppLocalizations l, RecurringPage page) => [
    PpForgeListHeader(
      key: const ValueKey('detailRulesHeader'),
      title: l.recurringRulesTitle,
      count: page.lines.length,
      actions: [
        if (page.actions.addLine)
          ListHeaderAction.button(
            AppIcons.add,
            tooltip: l.recurringAddRule,
            onTap: () => unawaited(_openRule(null)),
          ),
      ],
    ),
    SectionCard(
      key: const ValueKey('detailRules'),
      first: true,
      children: [
        for (final line in page.lines)
          RuleRow.of(
            line,
            key: ValueKey('detailRule:${line.id}'),
            onTap: () => unawaited(_openRule(line)),
            onMenu: (m) => unawaited(_ruleMenu(line, m)),
          ),
      ],
    ),
  ];

  /// The rule page (a saved rule, or [line] null = a new one); back with the
  /// recurring page it answered.
  Future<void> _openRule(RecurringLine? line) async {
    final r = await context.push<Object?>(
      '/recurring/${widget.id}/rules/${line?.id ?? 'new'}',
      extra: RulePageArgs(seq: line?.seq, recurringName: _detail?.page?.name),
    );
    if (!mounted) return;
    if (r is RecurringDetail) {
      _take(r);
    } else {
      unawaited(_load());
    }
  }

  Future<void> _ruleMenu(RecurringLine line, RuleRowMenu m) => _detailCall(
    () => switch (m) {
      RuleRowMenu.pause => _repo.lineAction(
        widget.id,
        line.id,
        RecurringAction.pause,
      ),
      RuleRowMenu.resume => _repo.lineAction(
        widget.id,
        line.id,
        RecurringAction.resume,
      ),
      RuleRowMenu.delete => _repo.deleteLine(widget.id, line.id),
    },
  );

  /// ✎: the recurring's own fields (icon, name, description, tracking
  /// type, note; พัก / เก็บถาวร / ลบ) on the edit page.
  Future<void> _openForm() async {
    await context.push<Object?>('/recurring/${widget.id}/settings');
    if (mounted) unawaited(_load());
  }

  PpForgeCompactHeroCard _compactBar(Recurring r) {
    final amount = r.amount;
    return PpForgeCompactHeroCard(
      style: _style(r),
      leading: IconDisplay(
        type: IconType.category,
        size: 28,
        iconCode: r.shownIconCode,
      ),
      title: PpForgeText(r.name, role: PpForgeTextRole.title),
      trailing: amount == null || amount <= 0
          ? null
          : MoneyText(
              signedOf(r.type, amount, saving: r.isSaving),
              tone: toneOf(r.type, saving: r.isSaving),
              symbol: context.readUserCurrencySymbol,
              style: PpForgeTypography.of(context, PpForgeTextRole.money),
            ),
    );
  }

  Widget? _notice(AppLocalizations l, Recurring r) {
    if (r.endingSoon && r.actions.extend) {
      return PpForgeMessage(
        message: l.recurringEndingSoon(r.counts.upcoming),
        tone: Tone.warning,
        actions: [
          PpForgeMessageAction(
            label: l.recurringExtend,
            onPressed: () => _detailCall(
              () =>
                  _repo.extend(widget.id, lineId: _detail?.page?.mainLine?.id),
            ),
          ),
        ],
      );
    }
    if (r.status == RecurringStatus.paused) {
      // R7: why it's paused; resume starts at the current period (R8).
      return switch (r.pauseReason) {
        RecurringPauseReason.overdueLimit => PpForgeMessage(
          message: l.recurringPausedOverdue,
          tone: Tone.warning,
        ),
        RecurringPauseReason.goalInactive => PpForgeMessage(
          message: l.recurringPausedGoal,
        ),
        // K13: a new debt with the person starts it again by itself.
        RecurringPauseReason.noBalance => PpForgeMessage(
          message: l.recurringPausedNoBalance,
        ),
        _ => PpForgeMessage(message: l.recurringPausedNotice),
      };
    }
    return null;
  }

  /// Under the hero: what to do (a due occurrence, or this month's coming
  /// one with no amount yet) as the list page's รอยืนยัน box, for any count
  /// (plan E). Nothing to do: nothing here; the next one is in the hero.
  /// ที่จะมา (S-Elec): the next 3 rounds not waiting in ต้องทำ; ดูทั้งหมด = the
  /// ที่จะมา tab.
  Widget? _focusCard(AppLocalizations l, Recurring r) {
    final due = [
      for (final i in _produced.items)
        if (i.state == OccurrenceState.notCreated ||
            i.state == OccurrenceState.pending)
          i,
    ]..sort((a, b) => a.date.compareTo(b.date));
    final todo = [
      ...due,
      for (final i in _upcoming.items)
        if (i.needsAmount && i.state == OccurrenceState.upcoming) i,
    ];
    if (todo.isEmpty) return null;
    final total = r.counts.notCreated > due.length
        ? r.counts.notCreated + todo.length - due.length
        : todo.length;
    return _dueList(l, todo, total);
  }

  /// "งวดถัดไป (6/12) | อีก 12 วัน" for an item with an end, else
  /// "งวดถัดไป | อีก 20 วัน".
  String _nextLabel(AppLocalizations l, Recurring r, RecurringItem i) {
    final when = dueLabel(l, date: i.date, daysUntil: i.daysUntil);
    final seq = i.seq;
    final total = i.total;
    return r.hasEnd && seq != null && total != null
        ? l.fpRecurringNextInstallment(seq, total, when)
        : l.fpRecurringNextOnce(when);
  }

  /// The hero's last row: the next occurrence; a tap edits it.
  Widget? _heroNext(AppLocalizations l, Recurring r) {
    // A plan's next installment, with principal / interest (a card plan
    // has no rounds of its own: it is billed on the card).
    final plan = _detail?.page?.plan;
    if (plan != null &&
        plan.next != null &&
        (plan.onCard || _nextItem == null)) {
      final i = plan.next!;
      final symbol = context.readUserCurrencySymbol;
      return HeroNextOccurrence(
        key: const ValueKey('heroNextInstallment'),
        label: [
          planNextLabel(
            l,
            plan,
            i,
            (v) => moneyString(context, v, symbol: symbol),
          ),
          if (plan.onCard) l.recurringPlanBilledOnCard,
        ].join(' | '),
        amount: MoneyText(-i.amount, tone: MoneyTone.signed, symbol: symbol),
        onTap: () => unawaited(_installmentMenu(i)),
      );
    }
    final next = _nextItem;
    if (next == null) return null;
    final unknown = next.amount == null || next.amount! <= 0;
    final nextLine = _detail?.page?.lines
        .where((x) => x.id == next.ruleId)
        .firstOrNull;
    return HeroNextOccurrence(
      key: const ValueKey('heroNext'),
      label: [
        _nextLabel(l, r, next),
        if (nextLine != null)
          [
            l.ruleTitle(nextLine.seq),
            ?nextLine.account?.name ?? nextLine.paidBy?.name,
          ].join(' · '),
      ].join(' | '),
      amount: unknown
          ? null
          : MoneyText(
              signedOf(next.type, next.amount!, saving: next.isSaving),
              tone: toneOf(next.type, saving: next.isSaving),
              symbol: context.readUserCurrencySymbol,
            ),
      amountText: unknown ? l.fpRecurringAwaitingValue : null,
      amountColor: unknown
          ? Theme.of(context).extension<PpForgeColors>()!.warning
          : null,
      onTap: () => _openOccurrence(next),
    );
  }

  /// ต้องจัดการ: the รอยืนยัน box as on the list page, the date on the left
  /// (it is one item), ดูทั้ง n งวด to the past tab.
  Widget _dueList(AppLocalizations l, List<RecurringItem> todo, int total) {
    final hidden = total - todo.length;
    return DueBoxes(
      key: const ValueKey('detailDue'),
      items: todo,
      showDate: false,
      titleOf: (i) => i.recurring?.name ?? _recurring?.name ?? i.title,
      // The section's name says รอใส่ยอด / รอยืนยัน already: no state pill.
      leading: (i) => DateTile(date: i.date),
      onChanged: _applyItems,
      onOpen: _openOccurrence,
      more: hidden > 0
          ? DueMoreRow(
              label: l.occurrenceDueMore(total),
              onTap: () => _onTab(_Tab.past),
            )
          : null,
    );
  }

  /// The occurrence's own sheet (แก้เฉพาะงวดนี้).
  void _openOccurrence(RecurringItem i) =>
      openOccurrenceSheet(context, i, onChanged: _applyItems);

  Widget _statusChip(AppLocalizations l, Recurring r, {VoidCallback? onTap}) {
    final (label, kind) = switch (r.status) {
      _ when r.isComplete => (l.recurringStatusDone, StatusKind.done),
      RecurringStatus.active => (l.recurringStatusActive, StatusKind.active),
      RecurringStatus.done => (l.recurringStatusDone, StatusKind.done),
      RecurringStatus.paused => (l.recurringStatusPaused, StatusKind.paused),
      RecurringStatus.archived => (
        l.recurringStatusArchived,
        StatusKind.archived,
      ),
    };
    return StatusChip(label: label, kind: kind, onTap: onTap);
  }

  String get _locale => Localizations.localeOf(context).toLanguageTag();

  /// "ก.ย. 27": the month with a short year.
  String _monthYear(DateTime d) =>
      '${DateFormat.MMM(_locale).format(d)} ${DateFormat('yy').format(d)}';

  /// Who it is and its round, the chain (or the amounts line for a bill that
  /// changes), three numbers in one box, then the status and what it books
  /// into as chips. The next occurrence sits under the card (_focusCard).
  Widget _viewHero(AppLocalizations l, RecurringDetail d) {
    final r = d.recurring;
    final plan = d.page?.plan;
    final rule = plan?.rule ?? r.rule;
    final description = (r.description ?? '').trim();
    final stats = plan != null ? _planStats(l, plan) : _stats(l, r, d.stats);
    return PpForgeHeroCard(
      style: _style(r),
      content: [
        HeroIdentity(
          icon: EditableCircle(
            size: HeroIdentity.iconSize,
            onLongPress: () => unawaited(_openForm()),
            child: IconDisplay(
              type: IconType.category,
              size: HeroIdentity.iconSize,
              iconCode: r.shownIconCode,
            ),
          ),
          name: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          description: description.isEmpty
              ? null
              : HeroDescription(
                  controller: _description,
                  editing: false,
                  focusNode: _descriptionFocus,
                  hint: l.commonDescription,
                  maxLength: TextLimits.description,
                  onEnterEdit: () => unawaited(_openForm()),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeroInfoBox(
                key: const ValueKey('heroRound'),
                icon: AppIcons.recurring,
                title: l.recurringRulesCount(d.page?.lines.length ?? 1),
                subtitle: l.fpRecurringSince(
                  DateFormat.yMMM(_locale).format(_firstStart(d) ?? rule.start),
                ),
              ),
              const SizedBox(width: PpForgeSpacing.sm),
              CardActionButton(
                key: const ValueKey('heroEdit'),
                icon: AppIcons.edit,
                tooltip: PpForgeConfig.stringsOf(context).edit,
                onTap: () => unawaited(_openForm()),
              ),
            ],
          ),
        ),
        if (plan != null) _planTrack(l, plan) else ?_track(l, r, d.stats),
        if (stats.isNotEmpty) HeroTiles(joined: true, children: stats),
        ?_purchaseRow(l, plan),
        HeroChipRow(chips: _heroChips(l, r, plan)),
        ?_heroNext(l, r),
      ],
    );
  }

  /// The earliest start over the rules (ตั้งแต่ …).
  DateTime? _firstStart(RecurringDetail d) {
    DateTime? out;
    for (final line in d.page?.lines ?? const <RecurringLine>[]) {
      final s = line.rule.start;
      if (out == null || s.isBefore(out)) out = s;
    }
    return out;
  }

  /// The next occurrence still to come.
  RecurringItem? get _nextItem {
    for (final i in _upcoming.items) {
      if (i.state == OccurrenceState.upcoming) return i;
    }
    return null;
  }

  /// One rule for the chain, the tiles and the wording (plan E): an item
  /// with an end ([Recurring.hasEnd]) draws every occurrence as a numbered
  /// chain; an open-ended one whose amount changes draws its recorded
  /// amounts as a line, else its recent occurrences as an open chain.
  Widget? _track(AppLocalizations l, Recurring r, RecurringStats? s) {
    final series = s?.series ?? const [];
    final dayLabels =
        r.rule.freq == RecurrenceFreq.daily ||
        r.rule.freq == RecurrenceFreq.weekly;
    String x(DateTime d) => dayLabels
        ? DateFormat.Md(_locale).format(d)
        : DateFormat.MMM(_locale).format(d);
    if (!r.hasEnd && !r.hasAmount && series.length >= 2) {
      final recent = series.length > 6
          ? series.sublist(series.length - 6)
          : series;
      final avg = s?.avgAmount ?? r.avgAmount;
      final next = _nextItem;
      return AmountLineChart(
        key: const ValueKey('heroAmounts'),
        points: [for (final p in recent) AmountPoint(x(p.slot), p.amount)],
        average: avg,
        averageLabel: avg == null
            ? null
            : l.fpRecurringAvgLine(
                NumberFormat.decimalPattern(_locale).format(avg.round()),
              ),
        nextLabel: next == null ? null : x(next.date),
        semanticLabel: l.fpRecurringChartLabel,
      );
    }
    final chain = _chain(r);
    if (chain.dots.isEmpty) return null;
    final open = !r.hasEnd;
    final total = r.progressTotal;
    return OccurrenceChain(
      key: const ValueKey('heroChain'),
      dots: chain.dots,
      open: open,
      firstLabel: open && chain.first != null ? x(chain.first!) : null,
      currentLabel: open && chain.current != null ? x(chain.current!) : null,
      semanticLabel: total == null
          ? null
          : l.fpRecurringChainLabel(r.progressDone, total),
    );
  }

  /// With an end: every occurrence (the BE's `chain`, else from the
  /// progress). Open-ended: the loaded history, the next one and two after.
  ({List<ChainDot> dots, DateTime? first, DateTime? current}) _chain(
    Recurring r,
  ) {
    final ended = r.hasEnd ? endChainDots(r) : null;
    if (ended != null) return (dots: ended, first: null, current: null);
    final past = _produced.items.take(8).toList().reversed.toList();
    final ahead = [
      for (final i in _upcoming.items)
        if (i.state == OccurrenceState.upcoming) i,
    ].take(3).toList();
    return (
      dots: [
        for (final i in past)
          switch (i.state) {
            OccurrenceState.done || OccurrenceState.paid => ChainDot.paid,
            OccurrenceState.archived => ChainDot.skipped,
            _ => ChainDot.wait,
          },
        for (final (n, _) in ahead.indexed)
          n == 0 ? ChainDot.current : ChainDot.future,
      ],
      first: past.isEmpty ? null : past.first.date,
      current: ahead.isEmpty ? null : ahead.first.date,
    );
  }

  /// A plan's installments as a numbered chain.
  Widget _planTrack(AppLocalizations l, RecurringPlan plan) {
    final dots = [
      for (final c in plan.chain)
        switch (c.status) {
          InstallmentStatus.paid => ChainDot.paid,
          InstallmentStatus.skipped => ChainDot.skipped,
          InstallmentStatus.due => ChainDot.wait,
          InstallmentStatus.upcoming => ChainDot.future,
        },
    ];
    final next = dots.indexOf(ChainDot.future);
    if (next >= 0) dots[next] = ChainDot.current;
    return OccurrenceChain(
      key: const ValueKey('heroPlanChain'),
      dots: dots,
      semanticLabel: l.fpRecurringChainLabel(plan.done, plan.count),
    );
  }

  /// A plan's three tiles: paid (a card plan: billed) / left / the last one.
  List<Widget> _planStats(AppLocalizations l, RecurringPlan plan) {
    final symbol = context.readUserCurrencySymbol;
    Widget tile(String label, String value) => SummaryTileView(
      tile: SummaryTile(label: label, value: value),
    );
    final last = plan.lastDate;
    return [
      tile(
        plan.onCard ? l.recurringPlanBilled : l.fpRecurringStatPaid,
        moneyString(context, plan.paidTotal, symbol: symbol),
      ),
      tile(
        l.recurringPlanLeft,
        moneyString(context, plan.leftTotal, symbol: symbol),
      ),
      tile(l.fpRecurringStatLast, last == null ? '–' : _monthYear(last)),
    ];
  }

  /// A card plan's purchase: the full-price expense on the card; a tap
  /// opens it.
  Widget? _purchaseRow(AppLocalizations l, RecurringPlan? plan) {
    final p = plan?.purchase;
    if (p == null) return null;
    final when = DateFormat.MMMd(_locale).format(p.date);
    return HeroNextOccurrence(
      key: const ValueKey('heroPurchase'),
      icon: AppIcons.receipt,
      label: l.recurringPlanPurchase(when),
      amount: MoneyText(
        -p.amount,
        tone: MoneyTone.signed,
        symbol: context.readUserCurrencySymbol,
      ),
      onTap: () => openPage(context, '/transactions/${p.id}'),
    );
  }

  /// Always three tiles (plan E), by [Recurring.hasEnd]. With an end: paid /
  /// left / the last one (picked dates: รวม, never ปีละ). Open-ended with an
  /// amount that changes: average / last time / highest; else per month /
  /// per year / recorded. A value not known yet shows "–".
  List<Widget> _stats(AppLocalizations l, Recurring r, RecurringStats? s) {
    final symbol = context.readUserCurrencySymbol;
    String money(double? v) =>
        v == null ? '–' : moneyString(context, v, symbol: symbol);
    Widget tile(String label, String value) => SummaryTileView(
      tile: SummaryTile(label: label, value: value),
    );
    if (r.hasEnd) {
      final per = r.amount ?? 0;
      final count = r.progressTotal;
      final paid = s?.paidTotal ?? per * r.progressDone;
      final left =
          s?.remainingTotal ??
          (count == null || !r.hasAmount
              ? null
              : per * (count - r.progressDone));
      if (r.rule.freq == RecurrenceFreq.dates) {
        return [
          tile(l.fpRecurringStatPaid, money(paid)),
          tile(l.fpRecurringStatRemaining, money(left)),
          tile(
            l.fpRecurringStatTotal,
            money(left == null ? null : paid + left),
          ),
        ];
      }
      final allShown = !_upcoming.windowed && !_upcoming.hasMore;
      final last =
          r.chain?.lastOrNull?.slot ??
          (allShown ? _upcoming.items.lastOrNull?.date : null) ??
          r.rule.end.date;
      return [
        tile(l.fpRecurringStatPaid, money(paid)),
        tile(l.fpRecurringStatRemaining, money(left)),
        tile(l.fpRecurringStatLast, last == null ? '–' : _monthYear(last)),
      ];
    }
    if (!r.hasAmount) {
      return [
        tile(l.fpRecurringStatAvg, money(s?.avgAmount ?? r.avgAmount)),
        tile(l.fpRecurringStatPrev, money(s?.lastAmount)),
        tile(l.fpRecurringStatMax, money(s?.maxAmount)),
      ];
    }
    final monthly = r.monthlyAmount;
    return [
      tile(
        l.fpM5bRecurringPerMonth,
        money(monthly != null && monthly > 0 ? monthly : null),
      ),
      tile(l.fpRecurringTileYearly, money(r.yearlyCost)),
      tile(
        l.fpRecurringTileSaved,
        l.fpRecurringCountUnit(s?.paidCount ?? r.savedCount),
      ),
    ];
  }

  /// Status ▾ (pause / resume), the kind, tags and บันทึกอัตโนมัติ (the
  /// category and wallets are the tiles above).
  List<Widget> _heroChips(
    AppLocalizations l,
    Recurring r,
    RecurringPlan? plan,
  ) {
    return [
      if (r.actions.pause || r.actions.resume)
        OptionMenuAnchor<RecurringAction>(
          options: [
            if (r.actions.pause)
              SheetOption(
                value: RecurringAction.pause,
                label: l.recurringPause,
                leading: const PpForgeIcon(AppIcons.pause),
                submits: true,
              ),
            if (r.actions.resume)
              SheetOption(
                value: RecurringAction.resume,
                label: l.recurringResume,
                leading: const PpForgeIcon(AppIcons.resume),
                submits: true,
              ),
          ],
          onSelected: _action,
          builder: (context, toggle) => _statusChip(l, r, onTap: toggle),
        )
      else
        _statusChip(l, r),
      PpForgeChip(
        key: const ValueKey('heroTracking'),
        label: plan == null
            ? trackingTypeLabel(l, _detail?.page?.trackingType ?? 'other')
            : '${trackingTypeLabel(l, _detail?.page?.trackingType ?? 'other')} · ${plan.onCard ? l.recurringPlanOnCard : l.recurringPlanChip(plan.count)}',
        selected: true,
        tone: PpForgeChipTone.neutral,
      ),
      if (plan != null)
        PpForgeChip(
          key: const ValueKey('heroPlanRate'),
          label: _rateLabel(l, plan),
          selected: true,
          tone: PpForgeChipTone.neutral,
        ),
      for (final t in r.tags) _tagChip(t.name, t.iconCode),
      if (r.autoCreate)
        PpForgeChip(
          key: const ValueKey('heroAutoCreate'),
          label: l.fpRecurringAutoChip,
          icon: AppIcons.recurring,
          selected: true,
          tone: PpForgeChipTone.primary,
        ),
    ];
  }

  /// "0%", else "Flat 2.99%/ปี".
  String _rateLabel(AppLocalizations l, RecurringPlan plan) {
    final rate = plan.rate;
    if (!plan.hasInterest || rate == null) return '0%';
    final method = switch (plan.method) {
      PlanInterestMethod.flat => l.recurringPlanMethodFlat,
      PlanInterestMethod.reducing => l.recurringPlanMethodReducing,
      PlanInterestMethod.fixed => l.recurringPlanMethodFixed,
      PlanInterestMethod.manual => l.recurringPlanMethodManual,
      PlanInterestMethod.none => l.recurringPlanMethodNone,
    };
    return l.recurringPlanRateChip(
      method,
      NumberFormat.decimalPattern(_locale).format(rate),
    );
  }

  Widget _tagChip(String name, PpForgeIconCode? iconCode) {
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    return PpForgeChip(
      label: name,
      icon: PpForgeIconRegistry.get(iconCode?.icon, fallback: AppIcons.tag),
      color: EventTagRef(name, iconCode: iconCode).colorOf(palette),
      selected: true,
      size: ChipSize.mini,
    );
  }

  /// One occurrence in either tab, as a row of ต้องจัดการ: its date, its
  /// name on one line, then its wallet, state pill and a hint. One waiting to
  /// be recorded ends with its amount in a field (filled in when known) and
  /// ✓; the rest show the amount ("รอใส่ยอด" when unknown).
  Widget _occurrenceRow(
    AppLocalizations l,
    Recurring r,
    RecurringItem i, {
    VoidCallback? onTap,
    bool next = false,
    bool last = false,
  }) {
    final symbol = context.readUserCurrencySymbol;
    final skipped = i.state == OccurrenceState.archived;
    final due =
        (i.state == OccurrenceState.notCreated ||
            i.state == OccurrenceState.pending) &&
        !i.state.settled;
    final unknown = i.amount == null || i.amount! <= 0;
    final slot = parseYmd(i.slot);
    final moved = slot != null && slot != i.date;
    final usual = r.amount;
    final (String? pill, Tone? tone, String? sub) = skipped
        ? (
            l.occurrenceStateArchived,
            null,
            i.date.isBefore(today()) ? null : l.fpRecurringTapToRestore,
          )
        : due
        ? (waitingLabel(l, i), Tone.warning, null)
        : next
        ? (
            l.fpRecurringTagNext,
            Tone.primary,
            [
              dueLabel(l, date: i.date, daysUntil: i.daysUntil),
              if (unknown) l.fpRecurringTapToEnter,
            ].join(' | '),
          )
        : moved
        ? (
            l.fpRecurringTagMoved,
            Tone.info,
            l.fpRecurringMovedFrom(DateFormat.MMMd(_locale).format(slot)),
          )
        : i.edited
        ? (
            l.fpRecurringEditedChip,
            Tone.info,
            !unknown && usual != null && usual > 0 && i.amount != usual
                ? l.fpRecurringUsualAmount(
                    moneyString(context, usual, symbol: symbol),
                  )
                : null,
          )
        : last
        ? (l.fpRecurringTagLast, Tone.success, null)
        // Paid = linked to a tx, or marked paid without one.
        : i.state == OccurrenceState.paid || i.state == OccurrenceState.done
        ? (l.occurrenceStatePaid, null, null)
        : (null, null, null);
    return PpForgeListRow(
      key: ValueKey('occ-${i.id}'),
      leading: DateTile(date: i.date),
      // The rule's own name: the date is on the left, n/total on line 2.
      title: i.recurring?.name ?? r.name,
      // The wallet, then the state pill, on line 2: the name keeps its room.
      line2: ListRowLine(
        lead: occurrenceWalletChip(context, i.account),
        glyphs: [
          if (i.seq != null && i.total != null)
            ListRowGlyph(AppIcons.progress, text: '${i.seq}/${i.total}'),
        ],
        spans: [
          if (pill != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: PpForgeChip(
                label: pill,
                tone: tone == null
                    ? PpForgeChipTone.neutral
                    : PpForgeChipTone.fromTone(tone),
                selected: tone != null,
                size: ChipSize.mini,
                maxWidth: PpForgeListRow.chipMaxWidth,
              ),
            ),
          if (sub != null) TextSpan(text: sub),
        ],
      ),
      trailing: due
          ? null
          : unknown
          ? ListRowTrailing.text(
              l.fpRecurringAwaitingValue,
              tone: skipped ? null : Tone.warning,
            )
          : ListRowTrailing.value(
              MoneyText(
                signedOf(i.type, i.amount!, saving: i.isSaving),
                tone: toneOf(i.type, saving: i.isSaving),
                symbol: symbol,
              ),
            ),
      actions: [
        if (due) ...[
          ListRowAction.amount(
            key: ValueKey('occAmount-${i.id}'),
            value: _rowAmounts.containsKey(i.id)
                ? _rowAmounts[i.id]
                : knownAmount(i),
            onChanged: (v) => _rowAmounts[i.id] = v,
            hint: l.fpRecurringAwaitingAmount,
          ),
          ListRowAction.button(
            AppIcons.check,
            tooltip: l.occurrenceConfirm,
            onTap: () => confirmOccurrenceRow(
              context,
              i,
              typed: _rowAmounts[i.id],
              onChanged: _applyItems,
              onOpen: () => _openOccurrence(i),
            ),
          ),
        ],
      ],
      dimmed: skipped,
      onTap: onTap,
    );
  }

  Widget _pastTab(AppLocalizations l, Recurring r) {
    final items = _produced.items;
    return ListPageBody(
      loading: false,
      error: null,
      // S-Elec: the note closes the page, after ที่ผ่านมา
      isEmpty: items.isEmpty && (r.note ?? '').trim().isEmpty,
      onRetry: _load,
      rowCards: true,
      topInset: PpForgeSpacing.sm,
      hasMore: _produced.hasMore,
      loadingMore: _producedMore,
      onLoadMore: _loadMoreProduced,
      loadMoreError: _producedMoreError,
      onRetryMore: _loadMoreProduced,
      empty: EmptyView.compact(message: l.recurringItemsEmpty),
      children: [
        for (final item in items)
          _occurrenceRow(l, r, item, onTap: () => _openOccurrence(item)),
        NoteSection(
          key: const ValueKey('recurringNote'),
          label: l.commonNote,
          editing: false,
          text: r.note,
          hint: l.commonLongPressToEdit,
          onLongPress: _openForm,
        ),
      ],
    );
  }

  /// ล่วงหน้า in two sections: ถัดไป (the next one) and ปรับแต่งล่วงหน้า (the
  /// way in, then the ones already changed ahead).
  Widget _upcomingTab(AppLocalizations l, Recurring r) {
    final items = _upcoming.items;
    final next = _nextItem;
    final changed = [
      for (final i in items)
        if (!identical(i, next) && _changedAhead(i)) i,
    ];
    return ListPageBody(
      loading: false,
      error: null,
      isEmpty: items.isEmpty,
      onRetry: _load,
      topInset: PpForgeSpacing.sm,
      rowGap: 0,
      empty: EmptyView(
        icon: AppIcons.scheduled,
        title: l.recurringUpcomingEmpty,
        message: l.recurringUpcomingEmptyMessage,
      ),
      children: [
        if (next != null)
          SectionCard(
            key: const ValueKey('upcomingNext'),
            first: true,
            title: l.recurringAheadNext,
            children: [
              _occurrenceRow(
                l,
                r,
                next,
                next: true,
                onTap: () => _openOccurrence(next),
              ),
            ],
          ),
        // ปรับแต่งล่วงหน้า: the way in, then the ones already changed ahead.
        SectionCard(
          key: const ValueKey('upcomingCustomizeSection'),
          first: next == null,
          title: l.recurringAheadCustomize,
          children: [
            PpForgeListRow(
              key: const ValueKey('upcomingCustomize'),
              leading: const PpForgeAvatar.icon(AppIcons.edit),
              title: l.recurringAheadCustomize,
              titleStrong: true,
              line2: ListRowLine(parts: [l.recurringAheadCustomizeHint]),
              trailing: ListRowTrailing.value(_chevron()),
              onTap: () => _openAheadSheet(l),
            ),
            for (final i in changed)
              _occurrenceRow(l, r, i, onTap: () => _openOccurrence(i)),
          ],
        ),
      ],
    );
  }

  Widget _chevron() => Icon(
    AppIcons.chevronRight,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// Moved, its amount changed, or skipped ahead.
  bool _changedAhead(RecurringItem i) {
    final slot = parseYmd(i.slot);
    return i.state == OccurrenceState.archived ||
        i.edited ||
        (slot != null && slot != i.date);
  }

  /// ปรับแต่งล่วงหน้า: every occurrence to come as a month grid, a year at a
  /// time; a tap opens its own sheet (แก้ยอด / เลื่อนวัน / ข้าม).
  void _openAheadSheet(AppLocalizations l) {
    unawaited(_loadAllUpcoming());
    final first = _nextItem?.date ?? _upcoming.items.firstOrNull?.date;
    final year = ValueNotifier<int>((first ?? today()).year);
    unawaited(
      showPpForgeSheetCustom<void>(
        context,
        builder: (_) => ValueListenableBuilder<int>(
          valueListenable: _sheetTick,
          builder: (_, _, _) => ValueListenableBuilder<int>(
            valueListenable: year,
            builder: (_, y, _) => _aheadSheet(l, y, year),
          ),
        ),
      ).whenComplete(year.dispose),
    );
  }

  Widget _aheadSheet(AppLocalizations l, int y, ValueNotifier<int> year) {
    final r = _recurring;
    if (r == null) return const SizedBox.shrink();
    final page = _upcoming;
    final items = page.items;
    final next = _nextItem;
    final complete = !page.windowed && !page.hasMore;
    final more = page.nextFrom != null;
    final years = {for (final i in items) i.date.year}.toList()..sort();
    final shown = years.contains(y) || years.isEmpty ? y : years.first;
    final lastYear = years.isEmpty
        ? shown
        : (more ? years.last + 1 : years.last);
    void goTo(DateTime d) {
      year.value = d.year;
      final last = _upcoming.items.lastOrNull?.date;
      if (_upcoming.nextFrom != null &&
          !_upcomingMore &&
          (last == null || last.year <= d.year)) {
        unawaited(_loadMoreUpcoming());
      }
    }

    final weekly =
        r.rule.freq == RecurrenceFreq.weekly ||
        r.rule.freq == RecurrenceFreq.daily;
    final inYear = [
      for (final (n, i) in items.indexed)
        if (i.date.year == shown) (n, i),
    ];
    Widget tile((int, RecurringItem) e) => _aheadTile(
      l,
      r,
      e.$2,
      next: identical(e.$2, next),
      last: complete && e.$1 == items.length - 1,
      weekly: weekly,
    );
    final symbol = context.readUserCurrencySymbol;
    final amount = r.amount;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final List<Widget> body;
    if (weekly) {
      final byMonth = <int, List<(int, RecurringItem)>>{};
      for (final e in inYear) {
        (byMonth[e.$2.date.month] ??= []).add(e);
      }
      body = [
        for (final MapEntry(key: m, value: list) in byMonth.entries) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: PpForgeSpacing.sm,
              bottom: PpForgeSpacing.xs + 2,
            ),
            child: Text(
              DateFormat.yMMMM(_locale).format(DateTime(shown, m)),
              style: text.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          OccurrenceTileGrid(children: [for (final e in list) tile(e)]),
        ],
      ];
    } else {
      body = [
        OccurrenceTileGrid(children: [for (final e in inYear) tile(e)]),
      ];
    }
    return PickerSheet(
      title: l.recurringAheadCustomize,
      subtitle: [
        r.name,
        recurrenceLabel(l, r.rule),
        if (amount != null && amount > 0)
          moneyString(context, amount, symbol: symbol),
      ].join(' | '),
      header: years.isEmpty || lastYear == years.first
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: PpForgeSpacing.sm),
              child: Center(
                child: StepperPill.period(
                  key: const ValueKey('aheadYear'),
                  unit: StepperUnit.year,
                  value: DateTime(shown),
                  first: DateTime(years.first),
                  last: DateTime(lastYear),
                  caret: false,
                  onChanged: goTo,
                ),
              ),
            ),
      builder: (_, _) => Padding(
        padding: const EdgeInsets.fromLTRB(
          PpForgeSpacing.lg,
          0,
          PpForgeSpacing.lg,
          PpForgeSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...body,
            if (_upcomingMore) ...[
              const SizedBox(height: PpForgeSpacing.sm),
              const ListRowSkeleton(),
            ],
          ],
        ),
      ),
    );
  }

  /// One cell of the ahead grid: its month (weekday for a weekly rule), the
  /// day, the amount; tagged ถัดไป / เลื่อน / แก้ / ข้าม / สุดท้าย.
  Widget _aheadTile(
    AppLocalizations l,
    Recurring r,
    RecurringItem i, {
    required bool next,
    required bool last,
    required bool weekly,
  }) {
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    final symbol = context.readUserCurrencySymbol;
    final skipped = i.state == OccurrenceState.archived;
    final slot = parseYmd(i.slot);
    final moved = slot != null && slot != i.date;
    final unknown = i.amount == null || i.amount! <= 0;
    final usual = r.amount;
    final (String? tag, Tone tone) = next
        ? (l.recurringAheadNext, Tone.primary)
        : skipped
        ? (l.occurrenceStateArchived, Tone.neutral)
        : moved
        ? (l.recurringTileMoved, Tone.info)
        : i.edited
        ? (l.recurringTileEdited, Tone.info)
        : last
        ? (l.fpRecurringTagLast, Tone.success)
        : (null, Tone.neutral);
    final edited = !moved && i.edited;
    return OccurrenceTile(
      key: ValueKey('aheadTile-${i.id}'),
      label: weekly
          ? DateFormat.EEEE(_locale).format(i.date)
          : DateFormat.MMM(_locale).format(i.date),
      day: i.date.day,
      amount: unknown
          ? l.fpRecurringAwaitingValue
          : moneyString(context, i.amount!, symbol: symbol),
      amountColor: unknown
          ? Tone.warning.color(context)
          : edited
          ? Tone.info.color(context)
          : switch (i.type) {
              TransactionType.income => palette.income,
              TransactionType.expense => palette.expense,
              _ => null,
            },
      tag: tag,
      tone: tone,
      was: moved
          ? DateFormat.MMMd(_locale).format(slot)
          : edited &&
                !unknown &&
                usual != null &&
                usual > 0 &&
                i.amount != usual
          ? moneyString(context, usual, symbol: symbol)
          : null,
      highlight: next,
      struck: skipped,
      onTap: () => _openOccurrence(i),
    );
  }

  /// A rule with an end: the rest of its pages, so the sheet lists them all.
  Future<void> _loadAllUpcoming() async {
    for (var n = 0; n < 20; n++) {
      final page = _upcoming;
      if (!mounted || page.windowed || !page.hasMore) return;
      await _loadMoreUpcoming();
      if (_upcomingMoreError != null) return;
    }
  }
}
