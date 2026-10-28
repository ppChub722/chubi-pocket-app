import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/data/write_effects.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../preferences/page_prefs.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurrence_rule.dart' show today;
import '../../domain/recurring.dart';
import '../../domain/recurring_item.dart';
import '../cubit/recurring_directory_cubit.dart';
import '../due_boxes.dart';
import '../occurrence_actions.dart';
import '../recurring_rows.dart';

enum RecurringHomeTab { overview, calendar }

/// The calendar list's status filter.
enum _MonthStatus { all, toFill, toConfirm, upcoming, done, skipped }

enum _MonthSort { date, amount, name }

/// Recurring, two tabs over one month, pinned at the top. ภาพรวม: the
/// month's totals, ต้องจัดการ (pick rows to ยืนยัน / ข้าม together), then
/// every rule by kind. ปฏิทิน: the month as a calendar in the hero, then the
/// whole month's occurrences, or a picked day's.
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

  /// Null: the calendar lists the whole month.
  DateTime? _day;

  List<RecurringItem>? _items;

  /// The month [_items] are of: they stay up while the next month loads.
  DateTime? _itemsMonth;
  Object? _itemsError;
  int _itemsSeq = 0;
  List<RecurringItem> _due = const [];

  final _dueKey = GlobalKey();
  late bool _focusDue = widget.focusDue;

  final _search = TextEditingController();
  final _toolbar = AppListToolbarState.of('recurring');
  String _query = '';

  // The calendar list's 🔍 / filters / sort, behind its own toggle.
  final _monthSearch = TextEditingController();

  /// Amounts typed in the calendar list's rows, by occurrence.
  final _rowAmounts = <String, double?>{};
  final _monthToolbar = AppListToolbarState.of('recurringMonth');
  String _monthQuery = '';
  _MonthStatus _status = _MonthStatus.all;
  RecurringKind? _kind;
  _MonthSort _sort = _MonthSort.date;

  static DateTime get _thisMonth {
    final t = today();
    return DateTime(t.year, t.month);
  }

  RecurringRepository get _repo => RecurringRepository.of(context);

  void Function()? _offEffects;

  @override
  void initState() {
    super.initState();
    _restorePrefs();
    _offEffects = WriteEffectsBus.instance.listen(_onEffects);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<RecurringDirectoryCubit>().loadIfNeeded());
      unawaited(_loadMonth());
      unawaited(_loadDue());
    });
  }

  /// The month list's status / kind / sort remembered on the account.
  void _restorePrefs() {
    final pref = readPagePref(context, PagePrefIds.recurring);
    final fields = pagePrefPage(PagePrefIds.recurring).fields;
    String pick(String key) =>
        fields.firstWhere((f) => f.key == key).pick(pref);
    _status = _MonthStatus.values.asNameMap()[pick('status')] ?? _status;
    _kind = RecurringKind.values.asNameMap()[pick('kind')];
    _sort = _MonthSort.values.asNameMap()[pick('sort')] ?? _sort;
  }

  void _remember(Map<String, Object?> patch) =>
      unawaited(rememberPagePref(context, PagePrefIds.recurring, patch));

  /// B2: slots any write changed (a tx deleted or unlinked elsewhere too)
  /// patch both lists in place; one that newly needs handling reloads
  /// ต้องจัดการ.
  void _onEffects(WriteEffects e) {
    final r = ItemWriteResult.fromEffects(e);
    if (r == null || !mounted) return;
    final known = {for (final i in _due) i.id};
    final newTodo = r.items.any((i) => _todo(i) && !known.contains(i.id));
    setState(() {
      final items = _items;
      if (items != null) _items = r.applyTo(items);
      _due = [
        for (final i in r.applyTo(_due))
          if (_todo(i)) i,
      ];
    });
    if (newTodo) unawaited(_loadDue());
  }

  @override
  void dispose() {
    _offEffects?.call();
    _search.dispose();
    _monthSearch.dispose();
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
    setState(() {
      _month = first;
      _day = null;
    });
    unawaited(_loadMonth());
  }

  /// ต้องจัดการ sits right under the hero: bring it into view.
  void _scrollToDue() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _dueKey.currentContext;
      if (!mounted || target == null) return;
      unawaited(
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      );
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
          topInset: AppSpacing.md,
          // The tabs stay on screen while the month scrolls under them.
          header: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: AppTabBar<RecurringHomeTab>(
                tabs: [
                  AppTab(
                    value: RecurringHomeTab.overview,
                    label: l.recurringHomeTabOverview,
                    icon: AppIcons.pie,
                  ),
                  AppTab(
                    value: RecurringHomeTab.calendar,
                    label: l.fpRecurringTabCalendar,
                    icon: AppIcons.date,
                  ),
                ],
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
          ],
          children: [
            _hero(l, items),
            if (_tab == RecurringHomeTab.overview) ...[
              if (_due.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _dueCard(l, dir),
              ],
              ..._allRules(l, dir),
            ] else
              ..._calendarList(l, items),
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

  /// The month's money out, a bar of how much of it is already paid, then
  /// the month's income, its ออมเงิน (saved / planned) and count in one box
  /// (ต้องจัดการ below says what waits). ออมเงิน is none of the money out,
  /// the bar or the count.
  Widget _hero(AppLocalizations l, List<RecurringItem> items) {
    var pay = 0.0;
    var paid = 0.0;
    var income = 0.0;
    var count = 0;
    var savePlan = 0.0;
    var saved = 0.0;
    var anySaving = false;
    for (final i in items) {
      if (i.state == OccurrenceState.archived) continue;
      final a = i.amount;
      if (i.isSaving) {
        anySaving = true;
        if (a == null) continue;
        savePlan += a;
        if (i.state.settled) saved += a;
        continue;
      }
      count++;
      if (a == null) continue;
      if (i.type == TransactionType.expense) {
        pay += a;
        if (i.state.settled) paid += a;
      } else if (i.type == TransactionType.income) {
        income += a;
      }
    }
    final symbol = context.readUserCurrencySymbol;
    final captions = _tab == RecurringHomeTab.calendar
        ? _captions(l, items)
        : const <int, CalendarCaption>{};
    return AppHeroCard(
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      header: HeroHeader(
        leading: const [HeroModuleTile(AppIcons.recurring)],
        fill: Align(
          alignment: AlignmentDirectional.centerStart,
          child: StepperPill.month(
            value: _month,
            onChanged: _onMonth,
            caret: false,
          ),
        ),
      ),
      content: [
        HeroNumber(
          label: anySaving
              ? l.recurringHomeMonthPayNoSaving
              : l.recurringHomeMonthPay,
          value: MoneyText(-pay, tone: MoneyTone.signed, symbol: symbol),
        ),
        if (pay > 0)
          HeroBar(
            key: const ValueKey('heroPaidBar'),
            value: (paid / pay).clamp(0.0, 1.0),
            fillLabel: '${(paid / pay * 100).clamp(0, 100).round()}%',
            left: '${l.occurrenceStatePaid} ${_money(paid)}',
            right: l.recurringHomeLeft(_money(pay - paid)),
          ),
        HeroTiles(
          joined: true,
          children: [
            SummaryTileView(
              tile: SummaryTile(
                label: l.homeIncome,
                value: signedMoneyString(
                  context,
                  income,
                  negative: false,
                  symbol: symbol,
                ),
                tone: income > 0
                    ? SummaryTileTone.green
                    : SummaryTileTone.neutral,
              ),
            ),
            if (anySaving)
              SummaryTileView(
                key: const ValueKey('heroSaved'),
                tile: SummaryTile(
                  label: l.recurringHomeMonthSave,
                  value: '${_money(saved)} / ${_money(savePlan)}',
                ),
              ),
            SummaryTileView(
              tile: SummaryTile(
                label: l.recurringHomeMonthCount,
                value: l.recurringHomeItemCount(count),
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
            captions: captions,
            // The box edged in the day's tone: waiting, out or in.
            edges: {
              for (final MapEntry(:key, :value) in captions.entries)
                if (value.tone != CalendarDot.neutral) key: value.tone,
            },
            onMonthChanged: _onMonth,
            onSelect: (d) => setState(() {
              final day = _day;
              _day = day != null && DateUtils.isSameDay(day, d) ? null : d;
            }),
          ),
      ],
    );
  }

  bool get _monthFiltered =>
      _monthQuery.isNotEmpty ||
      _status != _MonthStatus.all ||
      _kind != null ||
      _sort != _MonthSort.date;

  String _statusLabel(AppLocalizations l, _MonthStatus s) => switch (s) {
    _MonthStatus.all => l.recurringFilterAllStatus,
    _MonthStatus.toFill => l.fpRecurringAwaitingValue,
    _MonthStatus.toConfirm => l.occurrenceStateNotCreated,
    _MonthStatus.upcoming => l.occurrenceStateUpcoming,
    _MonthStatus.done => l.occurrenceStateDone,
    _MonthStatus.skipped => l.occurrenceStateArchived,
  };

  /// The calendar list after 🔍, the status and kind filters and the sort.
  /// Skipped ones show only under their own filter.
  List<RecurringItem> _monthItems(List<RecurringItem> items) {
    final dir = context.read<RecurringDirectoryCubit>().state;
    final needle = _monthQuery.toLowerCase();
    bool status(RecurringItem i) {
      final skipped = i.state == OccurrenceState.archived;
      final waiting = _todo(i) || _unknown(i);
      return switch (_status) {
        _MonthStatus.all => !skipped,
        _MonthStatus.toFill => !skipped && waiting && needsAmountInput(i),
        _MonthStatus.toConfirm => !skipped && waiting && !needsAmountInput(i),
        _MonthStatus.upcoming =>
          i.state == OccurrenceState.upcoming && !waiting,
        _MonthStatus.done =>
          i.state == OccurrenceState.done || i.state == OccurrenceState.paid,
        _MonthStatus.skipped => skipped,
      };
    }

    double size(RecurringItem i) => i.amount ?? _ruleOf(dir, i)?.avgAmount ?? 0;
    final out = [
      for (final i in items)
        if (status(i) &&
            (_kind == null ||
                (i.recurring?.kind ?? _ruleOf(dir, i)?.kind) == _kind) &&
            (needle.isEmpty || _name(i).toLowerCase().contains(needle)))
          i,
    ];
    switch (_sort) {
      case _MonthSort.date:
        break;
      case _MonthSort.amount:
        out.sort((a, b) => size(b).compareTo(size(a)));
      case _MonthSort.name:
        out.sort((a, b) => _name(a).compareTo(_name(b)));
    }
    return out;
  }

  /// The calendar list's head: the month, or the picked day as a ✕ chip that
  /// goes back to the month; the count; the status and kind filters and 🔍,
  /// which opens the search box and the sort under it.
  List<Widget> _calendarHead(
    AppLocalizations l,
    String title,
    int count, {
    bool day = false,
  }) => [
    AppListHeader(
      title: title,
      count: count,
      onClearTitle: day ? () => setState(() => _day = null) : null,
      actions: [
        ListHeaderAction.filter<_MonthStatus>(
          label: _statusLabel(l, _status),
          value: _status,
          active: _status != _MonthStatus.all,
          options: [
            for (final s in _MonthStatus.values)
              SheetOption(value: s, label: _statusLabel(l, s)),
          ],
          onSelected: (s) {
            setState(() => _status = s);
            _remember({'status': s.name});
          },
        ),
        ListHeaderAction.filter<RecurringKind?>(
          label: _kind == null
              ? l.recurringFilterAllKinds
              : recurringKindLabel(l, _kind!),
          value: _kind,
          active: _kind != null,
          options: [
            SheetOption(value: null, label: l.recurringFilterAllKinds),
            for (final k in const [
              RecurringKind.subscription,
              RecurringKind.installment,
              RecurringKind.reminder,
              RecurringKind.income,
              RecurringKind.saving,
            ])
              SheetOption(value: k, label: recurringKindLabel(l, k)),
          ],
          onSelected: (k) {
            setState(() => _kind = k);
            _remember({'kind': k?.name ?? 'all'});
          },
        ),
        ListHeaderAction.toolbar(
          _monthToolbar,
          filtered: _monthQuery.isNotEmpty || _sort != _MonthSort.date,
          tooltip: l.recurringSearchHint,
        ),
      ],
    ),
    AppListToolbar(
      state: _monthToolbar,
      search: ListToolbarSearch(
        controller: _monthSearch,
        onChanged: (v) => setState(() => _monthQuery = v.trim()),
        hint: l.recurringSearchHint,
      ),
      sort: SortChip<_MonthSort>(
        value: _sort,
        tooltip: l.recurringSortTooltip,
        options: [
          SortOption(_MonthSort.date, l.recurringSortDate),
          SortOption(_MonthSort.amount, l.recurringSortAmount),
          SortOption(_MonthSort.name, l.commonName),
        ],
        onChanged: (s) {
          setState(() => _sort = s);
          _remember({'sort': s.name});
        },
      ),
      sidePadding: 0,
    ),
  ];

  /// ปฏิทิน under the hero: the whole month's occurrences, or the picked
  /// day's (tap it again, or ✕ ทั้งเดือน, to go back), through the list's
  /// 🔍 / filters / sort. A day with none says so where they would be.
  List<Widget> _calendarList(AppLocalizations l, List<RecurringItem> items) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final day = _day;
    final shown = _monthItems(items);
    if (day == null) {
      return [
        ..._calendarHead(
          l,
          DateFormat.yMMMM(locale).format(_month),
          shown.length,
        ),
        SectionCard(
          key: const ValueKey('calendarMonthList'),
          children: shown.isEmpty
              ? [
                  EmptyView.compact(
                    message: _monthFiltered
                        ? l.recurringMonthNoMatch
                        : l.recurringEmptyTitle,
                  ),
                ]
              : _monthRows(l, shown),
        ),
      ];
    }
    final rows = [
      for (final i in shown)
        if (DateUtils.isSameDay(i.date, day)) i,
    ];
    return [
      ..._calendarHead(l, itemDateLabel(context, day), rows.length, day: true),
      SectionCard(
        key: const ValueKey('calendarDayList'),
        children: rows.isEmpty
            ? [
                EmptyView.compact(
                  message: l.recurringDayEmpty(
                    DateFormat.MMMd(locale).format(day),
                  ),
                ),
              ]
            : [for (final i in rows) _row(l, i)],
      ),
    ];
  }

  /// The month in the list's order. By date, this month: the today line,
  /// the past dimmed unless still waiting. A past month all dimmed; a coming
  /// one none.
  List<Widget> _monthRows(AppLocalizations l, List<RecurringItem> items) {
    final now = today();
    final thisMonth = _month == _thisMonth;
    final pastMonth = _month.isBefore(_thisMonth);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final rows = <Widget>[];
    var lined = !thisMonth || _sort != _MonthSort.date;
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
        _monthRow(l, i, dimmed: pastMonth || (thisMonth && past && !waiting)),
      );
    }
    if (!lined) {
      rows.add(
        TodayLine(
          label: l.recurringHomeToday(DateFormat.MMMd(locale).format(now)),
        ),
      );
    }
    return rows;
  }

  IconCode? _iconOf(RecurringItem i) {
    final rule = _ruleOf(context.read<RecurringDirectoryCubit>().state, i);
    final kind = rule?.kind ?? i.recurring?.kind;
    final own = i.recurring?.iconCode ?? rule?.iconCode;
    final category = rule?.category?.iconCode ?? i.category?.iconCode;
    return kind == null
        ? own ?? category
        : recurringIconCode(kind: kind, own: own, category: category);
  }

  Widget _icon(RecurringItem i) =>
      IconDisplay(type: IconType.category, size: 36, iconCode: _iconOf(i));

  /// The rule's own name, without "ประจำเดือน ต.ค. 2026": the date and
  /// n/total are on the row already.
  String _name(RecurringItem i) =>
      i.recurring?.name ??
      _ruleOf(context.read<RecurringDirectoryCubit>().state, i)?.name ??
      i.title;

  Widget _monthRow(
    AppLocalizations l,
    RecurringItem i, {
    bool dimmed = false,
  }) => _listRow(l, i, withDate: true, dimmed: dimmed);

  /// A picked day's row: the day is in the head above.
  Widget _row(AppLocalizations l, RecurringItem i) =>
      _listRow(l, i, withDate: false);

  /// Waiting on the user: due, or no amount yet.
  bool _actionable(RecurringItem i) =>
      i.state != OccurrenceState.archived &&
      !i.state.settled &&
      (_todo(i) || _unknown(i));

  /// A list row (AppListRow): the item's icon, its name and state pill,
  /// then its wallet and date | ⏲ n/total. One waiting on the user ends with
  /// its amount in a field (filled in when known; empty = รอใส่ยอด) and ✓;
  /// the rest show the amount, พรุ่งนี้ under it.
  Widget _listRow(
    AppLocalizations l,
    RecurringItem i, {
    required bool withDate,
    bool dimmed = false,
  }) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final act = _actionable(i);
    final field = act;
    return AppListRow(
      key: ValueKey('occ-${i.id}'),
      leading: _icon(i),
      title: _name(i),
      status: _stateChip(l, i),
      // On this page the wallet leads line 2, so the name keeps its room.
      line2: ListRowLine(
        lead: occurrenceWalletChip(context, i.account),
        parts: [
          ...occurrenceDebtParts(l, i),
          if (withDate) DateFormat.MMMEd(locale).format(i.date),
        ],
        glyphs: [
          if (i.seq != null && i.total != null)
            ListRowGlyph(AppIcons.progress, text: '${i.seq}/${i.total}'),
        ],
      ),
      trailing: field || _unknown(i)
          ? null
          : ListRowTrailing.value(
              MoneyText(
                signedOf(i.type, i.amount ?? 0, saving: i.isSaving),
                tone: toneOf(i.type, saving: i.isSaving),
                symbol: context.readUserCurrencySymbol,
              ),
              caption: !act && i.daysUntil == 1
                  ? l.homeUpcomingInDays(1)
                  : null,
            ),
      actions: [
        if (field)
          ListRowAction.amount(
            key: ValueKey('rowAmount-${i.id}'),
            value: _rowAmounts.containsKey(i.id)
                ? _rowAmounts[i.id]
                : knownAmount(i),
            onChanged: (v) => _rowAmounts[i.id] = v,
            hint: l.fpRecurringAwaitingAmount,
          ),
        if (act)
          ListRowAction.button(
            AppIcons.check,
            tooltip: l.occurrenceConfirm,
            onTap: () => confirmOccurrenceRow(
              context,
              i,
              typed: _rowAmounts[i.id],
              onChanged: _onChanged,
              onOpen: () => unawaited(_openItem(i)),
            ),
          ),
      ],
      dimmed: dimmed,
      onTap: () => _openItem(i),
    );
  }

  /// The state worth a pill: waiting ones in warning, then จ่ายแล้ว (linked
  /// to a tx or marked) / ข้าม / อัตโนมัติ.
  ListRowChip? _stateChip(AppLocalizations l, RecurringItem i) =>
      switch (i.state) {
        OccurrenceState.notCreated ||
        OccurrenceState.pending => waitingChip(waitingLabel(l, i)),
        OccurrenceState.archived => ListRowChip(l.occurrenceStateArchived),
        OccurrenceState.done when i.autoCreated => ListRowChip(
          l.fpRecurringAutoChip,
        ),
        OccurrenceState.paid ||
        OccurrenceState.done => ListRowChip(l.occurrenceStatePaid),
        _ => null,
      };

  /// Days with something waiting (due, or no amount yet): edged in warning.
  Set<int> _alerts(List<RecurringItem> items) => {
    for (final i in items)
      if (i.state != OccurrenceState.archived && (_todo(i) || _unknown(i)))
        i.date.day,
  };

  /// Each day's total under its number ("-419", "+35,000"), in the warning
  /// colour while something waits. One with no amount yet counts its rule's
  /// average, shown "~1,305"; with no average either, "รอใส่ยอด".
  Map<int, CalendarCaption> _captions(
    AppLocalizations l,
    List<RecurringItem> items,
  ) {
    final dir = context.read<RecurringDirectoryCubit>().state;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat.decimalPattern(locale);
    final sums = <int, double>{};
    final guessed = <int>{};
    final blank = <int>{};
    final waiting = _alerts(items);
    for (final i in items) {
      if (i.state == OccurrenceState.archived) continue;
      // Money in and out only: ออมเงิน is neither.
      if (i.type == TransactionType.transfer || i.isSaving) continue;
      final d = i.date.day;
      var a = i.amount;
      if (a == null || a <= 0) {
        a = _ruleOf(dir, i)?.avgAmount;
        if (a == null || a <= 0) {
          blank.add(d);
          continue;
        }
        guessed.add(d);
      }
      sums[d] = (sums[d] ?? 0) + signedOf(i.type, a);
    }
    final captions = <int, CalendarCaption>{};
    for (final d in {...sums.keys, ...blank}) {
      final s = sums[d] ?? 0;
      if (s.round() != 0) {
        final sign = guessed.contains(d) ? '~' : (s > 0 ? '+' : '-');
        captions[d] = CalendarCaption(
          '$sign${number.format(s.abs().round())}',
          tone: waiting.contains(d)
              ? CalendarDot.warning
              : s > 0
              ? CalendarDot.income
              : CalendarDot.expense,
        );
      } else if (blank.contains(d)) {
        captions[d] = CalendarCaption(
          l.fpRecurringAwaitingValue,
          tone: CalendarDot.warning,
        );
      }
    }
    return captions;
  }

  /// ต้องจัดการ: one รอยืนยัน card. Each row: the item's icon and short name,
  /// its wallet and date, the amount field and ✓.
  Widget _dueCard(AppLocalizations l, RecurringDirectoryState dir) => DueBoxes(
    key: _dueKey,
    items: _due,
    leading: _icon,
    titleOf: _name,
    // R7: its rule stopped at 3 waiting occurrences; K13: a หนี้ one with
    // nothing owed 3 rounds.
    tag: (i) => pauseReasonChip(l, i.recurring?.pauseReason),
    onChanged: _onChanged,
    onOpen: (i) => unawaited(_openItem(i)),
  );

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
      AppListHeader(
        title: l.recurringHomeAllTitle,
        actions: [
          ListHeaderAction.toolbar(
            _toolbar,
            filtered: _query.trim().isNotEmpty,
            tooltip: l.recurringSearchHint,
          ),
          ListHeaderAction.button(
            AppIcons.add,
            tooltip: l.recurringAdd,
            onTap: () => _open('/recurring/new'),
          ),
        ],
      ),
      AppListToolbar(
        state: _toolbar,
        search: ListToolbarSearch(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          hint: l.recurringSearchHint,
        ),
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
        AppListHeader(title: l.fpRecurringPausedGroup, count: paused.length),
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
      RecurringKind.income || RecurringKind.saving || RecurringKind.debt =>
        l.recurringHomePerMonth(_money(sum((r) => r.monthlyAmount))),
    };
    return [
      AppListHeader(
        title: recurringKindLabel(l, kind),
        count: rules.length,
        trailing: ListHeaderTrailing.text(totals),
      ),
      SectionCard(children: [for (final r in rules) _ruleRow(r)]),
    ];
  }

  /// A rule; one with an end (installments) gets its chain of occurrences
  /// in the row's footer.
  Widget _ruleRow(Recurring r) {
    final dots = endChainDots(r);
    return RecurringRow(
      recurring: r,
      footer: dots == null ? null : OccurrenceChain(dots: dots),
      onTap: () => _open('/recurring/${r.id}'),
    );
  }
}
