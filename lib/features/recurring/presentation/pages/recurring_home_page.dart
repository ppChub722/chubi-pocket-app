import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurrence_rule.dart' show today;
import '../../domain/recurring.dart';
import '../../domain/recurring_item.dart';
import '../cubit/recurring_directory_cubit.dart';
import '../occurrence_actions.dart';
import '../recurring_rows.dart';

enum RecurringHomeTab { overview, calendar }

/// Recurring, two big tabs over one month. ภาพรวม: the month's totals and its
/// occurrences in date order (a today line), ต้องจัดการ, then every rule by
/// kind. ปฏิทิน: the month as a calendar and the picked day's occurrences.
class RecurringHomePage extends StatefulWidget {
  const RecurringHomePage({
    this.initialTab = RecurringHomeTab.overview,
    this.focusDue = false,
    super.key,
  });

  final RecurringHomeTab initialTab;

  /// `?focus=due` (the due notice): scroll to ต้องจัดการ once it is there.
  final bool focusDue;

  @override
  State<RecurringHomePage> createState() => _RecurringHomePageState();
}

class _RecurringHomePageState extends State<RecurringHomePage> {
  late RecurringHomeTab _tab = widget.initialTab;
  late DateTime _month = _thisMonth;
  late DateTime _day = today();

  List<RecurringItem>? _items;

  /// The month [_items] are of: they stay up while the next month loads.
  DateTime? _itemsMonth;
  Object? _itemsError;
  int _itemsSeq = 0;
  List<RecurringItem> _due = const [];

  final _scroll = ScrollController();
  final _dueKey = GlobalKey();
  late bool _focusDue = widget.focusDue;

  final _search = TextEditingController();
  final _toolbar = ToolbarToggleState.of('recurring');
  String _query = '';

  static DateTime get _thisMonth {
    final t = today();
    return DateTime(t.year, t.month);
  }

  RecurringRepository get _repo => RecurringRepository.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<RecurringDirectoryCubit>().loadIfNeeded());
      unawaited(_loadMonth());
      unawaited(_loadDue());
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadMonth() async {
    final seq = ++_itemsSeq;
    final month = _month;
    try {
      final items = await _repo.monthItems(month);
      if (!mounted || seq != _itemsSeq) return;
      setState(() {
        _items = items..sort((a, b) => a.date.compareTo(b.date));
        _itemsMonth = month;
        _itemsError = null;
      });
    } catch (e, st) {
      if (!mounted || seq != _itemsSeq) return;
      final err = ApiException.from(e, st);
      if (_items == null || _itemsMonth != month) {
        setState(() {
          _items = null;
          _itemsError = err;
        });
      } else {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.fpRecurringRefreshFailed,
          tone: Tone.danger,
        );
      }
    }
  }

  /// Due, waiting to confirm, or still needing an amount this month.
  static bool _todo(RecurringItem i) =>
      i.state == OccurrenceState.notCreated ||
      i.state == OccurrenceState.pending ||
      (i.needsAmount && !i.state.settled);

  Future<void> _loadDue() async {
    try {
      final items = await _repo.dueItems();
      if (!mounted) return;
      setState(() {
        _due = [
          for (final i in items)
            if (_todo(i)) i,
        ]..sort((a, b) => a.date.compareTo(b.date));
      });
    } on ApiException {
      // The card stays hidden; the month list still shows what is due.
    }
    if (_focusDue && _due.isNotEmpty) {
      _focusDue = false;
      _scrollToDue();
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadMonth(),
      _loadDue(),
      context.read<RecurringDirectoryCubit>().load(),
    ]);
  }

  void _onChanged(ItemWriteResult r) {
    setState(() {
      final items = _items;
      if (items != null) _items = r.applyTo(items);
      _due = [
        for (final i in r.applyTo(_due))
          if (_todo(i)) i,
      ];
    });
    unawaited(_loadMonth());
    unawaited(_loadDue());
    unawaited(context.read<RecurringDirectoryCubit>().load());
  }

  void _onMonth(DateTime m) {
    final first = DateTime(m.year, m.month);
    if (first == _month) return;
    final last = DateUtils.getDaysInMonth(first.year, first.month);
    setState(() {
      _month = first;
      _day = DateTime(first.year, first.month, _day.day > last ? 1 : _day.day);
    });
    unawaited(_loadMonth());
  }

  /// ต้องจัดการ sits under the hero, which may be long: step down until it is
  /// built, then bring it into view.
  void _scrollToDue([int tries = 0]) {
    if (_tab != RecurringHomeTab.overview) {
      setState(() => _tab = RecurringHomeTab.overview);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _dueKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        return;
      }
      if (tries >= 8 || !_scroll.hasClients) return;
      final p = _scroll.position;
      _scroll.jumpTo(
        (p.pixels + p.viewportDimension).clamp(0, p.maxScrollExtent),
      );
      _scrollToDue(tries + 1);
    });
  }

  void _open(String path) => openPage(context, path);

  Future<void> _openItem(RecurringItem i) =>
      openOccurrenceSheet(context, i, onChanged: _onChanged);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dir = context.watch<RecurringDirectoryCubit>().state;
    final items = _items ?? const <RecurringItem>[];
    return Scaffold(
      appBar: AppTopBar(title: l.recurringTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: ListPageBody(
          loading: _items == null && _itemsError == null,
          error: _items == null ? _itemsError : null,
          // Until the month is in: the skeleton, or the error with a retry.
          isEmpty: _items == null,
          onRetry: _refresh,
          empty: EmptyView.compact(message: l.recurringEmptyTitle),
          controller: _scroll,
          topInset: AppSpacing.sm,
          children: [
            SegmentedChoice<RecurringHomeTab>(
              expand: true,
              segments: [
                ChoiceSegment(
                  RecurringHomeTab.overview,
                  l.recurringHomeTabOverview,
                ),
                ChoiceSegment(
                  RecurringHomeTab.calendar,
                  l.fpRecurringTabCalendar,
                ),
              ],
              selected: _tab,
              onChanged: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: AppSpacing.md),
            _hero(l, items),
            if (_tab == RecurringHomeTab.overview) ...[
              if (_due.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _dueCard(l, dir),
              ],
              ..._allRules(l, dir),
            ] else
              ..._dayList(l, items),
          ],
        ),
      ),
    );
  }

  String _money(num v) =>
      moneyString(context, v, symbol: context.readUserCurrencySymbol);

  Recurring? _ruleOf(RecurringDirectoryState dir, RecurringItem i) {
    final id = i.ruleId ?? i.recurring?.id;
    if (id == null) return null;
    for (final r in dir.rules) {
      if (r.id == id) return r;
    }
    return null;
  }

  static bool _unknown(RecurringItem i) => i.amount == null && !i.state.settled;

  Widget _hero(AppLocalizations l, List<RecurringItem> items) {
    var pay = 0.0;
    var income = 0.0;
    var count = 0;
    var awaiting = 0;
    for (final i in items) {
      if (i.state == OccurrenceState.archived) continue;
      count++;
      final a = i.amount;
      if (a == null) {
        if (!i.state.settled) awaiting++;
      } else if (i.type == TransactionType.expense) {
        pay += a;
      } else if (i.type == TransactionType.income) {
        income += a;
      }
    }
    final symbol = context.readUserCurrencySymbol;
    return AppHeroCard(
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      header: HeroHeader(
        leading: [
          const HeroModuleTile(AppIcons.scheduled),
          StepperPill.month(value: _month, onChanged: _onMonth),
        ],
        actions: const [MoneyVisibilityToggle()],
      ),
      content: [
        HeroNumber(
          label: l.recurringHomeMonthPay,
          value: MoneyText(-pay, tone: MoneyTone.signed, symbol: symbol),
        ),
        HeroNote(
          child: AppText(
            l.recurringHomeMonthIncome(_money(income)),
            role: AppTextRole.caption,
          ),
        ),
        HeroTiles(
          children: [
            SummaryTileView(
              tile: SummaryTile(
                label: l.recurringHomeMonthCount,
                value: l.recurringHomeItemCount(count),
              ),
            ),
            SummaryTileView(
              tile: SummaryTile(
                label: l.fpRecurringAwaitingValue,
                value: l.recurringHomeItemCount(awaiting),
                tone: awaiting > 0
                    ? SummaryTileTone.amber
                    : SummaryTileTone.neutral,
                onTap: awaiting > 0 && _due.isNotEmpty ? _scrollToDue : null,
              ),
            ),
          ],
        ),
        if (_tab == RecurringHomeTab.calendar)
          MonthCalendar(
            month: _month,
            showStepper: false,
            today: today(),
            selected: _day,
            dots: _dots(items),
            onMonthChanged: _onMonth,
            onSelect: (d) => setState(() => _day = d),
          )
        else if (items.isNotEmpty)
          _monthList(l, items),
      ],
    );
  }

  /// The month in date order. This month: the today line, the past dimmed
  /// unless still waiting. A past month all dimmed; a coming one none.
  Widget _monthList(AppLocalizations l, List<RecurringItem> items) {
    final now = today();
    final thisMonth = _month == _thisMonth;
    final pastMonth = _month.isBefore(_thisMonth);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final rows = <Widget>[];
    var lined = !thisMonth;
    for (final i in items) {
      final past = i.date.isBefore(now);
      if (!lined && !past) {
        rows.add(
          TodayLine(
            label: l.recurringHomeToday(DateFormat.MMMd(locale).format(now)),
          ),
        );
        lined = true;
      }
      final waiting = _todo(i) || _unknown(i);
      rows.add(
        _row(l, i, dimmed: pastMonth || (thisMonth && past && !waiting)),
      );
    }
    if (!lined) {
      rows.add(
        TodayLine(
          label: l.recurringHomeToday(DateFormat.MMMd(locale).format(now)),
        ),
      );
    }
    return HeroInsetBox(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(children: rows),
    );
  }

  /// One occurrence: its date, name, state tag, wallet | n/total, amount (or
  /// รอใส่ยอด with the rule's average).
  Widget _row(
    AppLocalizations l,
    RecurringItem i, {
    bool dimmed = false,
    bool actions = false,
  }) {
    final dir = context.read<RecurringDirectoryCubit>().state;
    final unknown = _unknown(i);
    final avg = _ruleOf(dir, i)?.avgAmount;
    final tomorrow = i.daysUntil == 1;
    final tag = switch (i.state) {
      OccurrenceState.notCreated ||
      OccurrenceState.pending => _tag(i.state.label(l), AppChipTone.warning),
      OccurrenceState.paid => _tag(l.occurrenceStatePaid, null),
      OccurrenceState.archived => _tag(l.occurrenceStateArchived, null),
      OccurrenceState.done when i.autoCreated => _tag(
        l.fpRecurringAutoChip,
        null,
      ),
      _ => null,
    };
    return OccurrenceRow(
      key: ValueKey('occ-${i.id}'),
      leading: DateTile(
        date: i.date,
        caption: tomorrow ? l.homeUpcomingInDays(1) : null,
      ),
      title: i.title,
      tag: tag,
      sub: [
        ?i.account?.name,
        if (i.seq != null && i.total != null) '${i.seq}/${i.total}',
      ].join(' | '),
      amount: unknown
          ? null
          : MoneyText(
              signedOf(i.type, i.amount ?? 0),
              tone: toneOf(i.type),
              symbol: context.readUserCurrencySymbol,
            ),
      amountWaiting: unknown ? l.fpRecurringAwaitingValue : null,
      amountCaption: unknown && avg != null && avg > 0
          ? l.fpRecurringAvgLine(_money(avg))
          : null,
      action: actions
          ? occurrenceActionsFor(context, i, onChanged: _onChanged)
          : null,
      dimmed: dimmed,
      onTap: () => _openItem(i),
    );
  }

  Widget _tag(String label, AppChipTone? tone) => AppChip(
    label: label,
    tone: tone ?? AppChipTone.neutral,
    selected: tone != null,
    size: ChipSize.mini,
  );

  Map<int, List<CalendarDot>> _dots(List<RecurringItem> items) {
    final dots = <int, List<CalendarDot>>{};
    for (final i in items) {
      if (i.state == OccurrenceState.archived) continue;
      final d = _todo(i) || _unknown(i)
          ? CalendarDot.warning
          : switch (i.type) {
              TransactionType.income => CalendarDot.income,
              TransactionType.expense => CalendarDot.expense,
              TransactionType.transfer => CalendarDot.neutral,
            };
      final list = dots.putIfAbsent(i.date.day, () => []);
      if (!list.contains(d)) list.add(d);
    }
    return dots;
  }

  /// ปฏิทิน: the picked day's occurrences, with their buttons.
  List<Widget> _dayList(AppLocalizations l, List<RecurringItem> items) {
    final day = [
      for (final i in items)
        if (DateUtils.isSameDay(i.date, _day)) i,
    ];
    if (day.isEmpty) return const [];
    return [
      DateGroupHeader(label: itemDateLabel(context, _day)),
      SectionCard(children: [for (final i in day) _row(l, i, actions: true)]),
    ];
  }

  /// ต้องจัดการ, one rule at a time: a rule with several gets its
  /// all-at-once buttons and, past 3, a row to its page.
  Widget _dueCard(AppLocalizations l, RecurringDirectoryState dir) {
    final byRule = <String, List<RecurringItem>>{};
    for (final i in _due) {
      byRule.putIfAbsent(i.ruleId ?? i.recurring?.id ?? i.id, () => []).add(i);
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    final children = <Widget>[];
    for (final MapEntry(key: ruleId, value: list) in byRule.entries) {
      if (list.length > 1) {
        final first = list.first;
        children.add(
          DueGroupHeader(
            label: first.recurring?.name ?? first.title,
            caption: [
              l.occurrenceDueSince(DateFormat.yMMM(locale).format(first.date)),
              l.fpRecurringCountUnit(list.length),
            ].join(' | '),
            actions: first.bySlot
                ? settleAllActions(context, ruleId, onChanged: _onChanged)
                : null,
          ),
        );
      }
      for (final i in list.take(3)) {
        children.add(_dueRow(l, i));
      }
      if (list.length > 3) {
        children.add(
          DueMoreRow(
            label: l.occurrenceDueMore(list.length),
            onTap: () => _open('/recurring/$ruleId'),
          ),
        );
      }
    }
    return DueCard(
      key: _dueKey,
      title: l.occurrenceDueTitle,
      trailing: l.fpRecurringCountUnit(_due.length),
      children: children,
    );
  }

  Widget _dueRow(AppLocalizations l, RecurringItem i) {
    final known = i.amount != null && i.amount! > 0;
    return OccurrenceRow(
      key: ValueKey('due-${i.id}'),
      leading: DateTile(date: i.date),
      title: i.title,
      tag: _tag(
        i.state == OccurrenceState.upcoming
            ? dueLabel(l, date: i.date, daysUntil: i.daysUntil)
            : i.state.label(l),
        AppChipTone.warning,
      ),
      sub: [if (known) _money(i.amount!), ?i.account?.name].join(' | '),
      action: occurrenceActionsFor(context, i, onChanged: _onChanged),
      onTap: () => _openItem(i),
    );
  }

  /// รายการประจำทั้งหมด: 🔍 and +, then the rules by kind with each kind's
  /// totals, the paused ones last. No archived ones.
  List<Widget> _allRules(AppLocalizations l, RecurringDirectoryState dir) {
    final needle = _query.trim().toLowerCase();
    final rules = [
      for (final r in dir.rules)
        if (r.status != RecurringStatus.archived &&
            (needle.isEmpty || r.name.toLowerCase().contains(needle)))
          r,
    ];
    final head = [
      SectionHeader(
        title: l.recurringHomeAllTitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListenableBuilder(
              listenable: _search,
              builder: (context, _) => ToolbarToggleButton(
                state: _toolbar,
                filtered: _search.text.trim().isNotEmpty,
                tooltip: l.recurringSearchHint,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CardActionButton(
              icon: AppIcons.add,
              tooltip: l.recurringAdd,
              onTap: () => _open('/recurring/new'),
            ),
          ],
        ),
      ),
      ListToolbar(
        collapse: _toolbar,
        searchController: _search,
        onSearchChanged: (v) => setState(() => _query = v),
        searchHint: l.recurringSearchHint,
        sidePadding: 0,
      ),
    ];
    final loaded = dir.status == RecurringDirectoryStatus.loaded;
    if (rules.isEmpty && loaded) {
      return [
        ...head,
        if (needle.isNotEmpty)
          EmptyView.compact(message: l.recurringNoMatch)
        else
          EmptyView(
            icon: AppIcons.scheduled,
            title: l.recurringEmptyTitle,
            message: l.recurringEmptyMessage,
            cta: AddTile(
              label: l.recurringAdd,
              onTap: () => _open('/recurring/new'),
            ),
          ),
      ];
    }
    final live = [
      for (final r in rules)
        if (r.status != RecurringStatus.paused) r,
    ];
    final paused = [
      for (final r in rules)
        if (r.status == RecurringStatus.paused) r,
    ];
    return [
      ...head,
      for (final k in const [
        RecurringKind.subscription,
        RecurringKind.installment,
        RecurringKind.reminder,
        RecurringKind.income,
      ])
        ..._kindGroup(l, k, [
          for (final r in live)
            if (r.kind == k) r,
        ]),
      if (paused.isNotEmpty) ...[
        SectionHeader(title: l.fpRecurringPausedGroup, count: paused.length),
        SectionCard(children: [for (final r in paused) _ruleRow(r)]),
      ],
    ];
  }

  List<Widget> _kindGroup(
    AppLocalizations l,
    RecurringKind kind,
    List<Recurring> rules,
  ) {
    if (rules.isEmpty) return const [];
    double sum(double? Function(Recurring r) of) =>
        rules.fold(0, (s, r) => s + (of(r) ?? 0));
    final totals = switch (kind) {
      RecurringKind.subscription => l.recurringHomePerMonthYear(
        _money(sum((r) => r.monthlyAmount)),
        _money(sum((r) => r.yearlyCost)),
      ),
      RecurringKind.installment => l.recurringHomeLeft(
        _money(
          sum(
            (r) => r.progressTotal == null
                ? null
                : (r.amount ?? 0) * (r.progressTotal! - r.progressDone),
          ),
        ),
      ),
      RecurringKind.reminder => l.recurringHomeAvgPerMonth(
        _money(sum((r) => r.avgAmount ?? r.monthlyAmount)),
      ),
      RecurringKind.income => l.recurringHomePerMonth(
        _money(sum((r) => r.monthlyAmount)),
      ),
    };
    return [
      SectionHeader(
        title: recurringKindLabel(l, kind),
        count: rules.length,
        trailing: AppText(totals, role: AppTextRole.caption),
      ),
      SectionCard(children: [for (final r in rules) _ruleRow(r)]),
    ];
  }

  /// A rule; one with an end (installments) gets its chain of occurrences.
  Widget _ruleRow(Recurring r) {
    final row = RecurringRow(
      recurring: r,
      onTap: () => _open('/recurring/${r.id}'),
    );
    final dots = endChainDots(r);
    if (dots == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: OccurrenceChain(dots: dots),
        ),
      ],
    );
  }
}
