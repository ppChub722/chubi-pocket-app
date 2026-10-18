import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import '../recurring_rows.dart';

enum RecurringHomeTab { recurring, reminder, calendar }

class RecurringHomePage extends StatefulWidget {
  const RecurringHomePage({
    this.initialTab = RecurringHomeTab.recurring,
    super.key,
  });

  final RecurringHomeTab initialTab;

  @override
  State<RecurringHomePage> createState() => _RecurringHomePageState();
}

class _RecurringHomePageState extends State<RecurringHomePage> {
  late RecurringHomeTab _tab = widget.initialTab;
  late final PageController _pager = PageController(
    initialPage: RecurringHomeTab.values.indexOf(widget.initialTab),
  );

  final _search = TextEditingController();
  final _toolbar = ToolbarToggleState.of('recurring');
  String _query = '';
  RecurringFilter _filter = RecurringFilter.current;
  RecurringList? _list;
  ApiException? _listError;

  late DateTime _month = DateTime(today().year, today().month);
  late DateTime _day = today();
  ItemPage? _calendar;
  Object? _calendarError;
  int _calendarSeq = 0;

  RecurringRepository get _repo => RecurringRepository.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<RecurringDirectoryCubit>().loadIfNeeded());
      if (_tab == RecurringHomeTab.calendar) _loadCalendar();
    });
  }

  @override
  void dispose() {
    _pager.dispose();
    _search.dispose();
    super.dispose();
  }

  RecurringList? _listOf(RecurringDirectoryState s) {
    if (s.status != RecurringDirectoryStatus.loaded) return null;
    final needle = _query.trim().toLowerCase();
    return RecurringList(
      items: [
        for (final r in s.rules)
          if (switch (_filter) {
                RecurringFilter.current => r.status != RecurringStatus.archived,
                RecurringFilter.archived =>
                  r.status == RecurringStatus.archived,
                RecurringFilter.all => true,
              } &&
              (needle.isEmpty || r.name.toLowerCase().contains(needle)))
            r,
      ],
      counts: {
        'current': s.currentCount,
        'archived': s.archivedCount,
        'all': s.rules.length,
      },
      summary: s.summary,
    );
  }

  Future<void> _loadCalendar() async {
    final seq = ++_calendarSeq;
    try {
      final page = await _repo.calendar(_month);
      if (!mounted || seq != _calendarSeq) return;
      setState(() {
        _calendar = page;
        _calendarError = null;
      });
    } catch (e, st) {
      if (!mounted || seq != _calendarSeq) return;
      final err = ApiException.from(e, st);
      if (_calendar == null) {
        setState(() => _calendarError = err);
      } else {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.fpRecurringRefreshFailed,
          tone: Tone.danger,
        );
      }
    }
  }

  void _setQuery(String v) => setState(() => _query = v);

  bool get _filtered =>
      _search.text.trim().isNotEmpty || _filter != RecurringFilter.current;

  String _statusLabel(AppLocalizations l, RecurringFilter f) => switch (f) {
    RecurringFilter.current => l.recurringFilterCurrent,
    RecurringFilter.archived => l.recurringFilterArchived,
    RecurringFilter.all => l.recurringFilterAll,
  };

  void _setFilter(RecurringFilter f) {
    if (f == _filter) return;
    setState(() => _filter = f);
  }

  void _onMonth(DateTime m) {
    final first = DateTime(m.year, m.month);
    setState(() {
      _month = first;
      final last = DateUtils.getDaysInMonth(first.year, first.month);
      _day = DateTime(first.year, first.month, _day.day > last ? 1 : _day.day);
    });
    _loadCalendar();
  }

  void _goTab(RecurringHomeTab t) {
    setState(() => _tab = t);
    if (_pager.hasClients) {
      _pager.animateToPage(
        RecurringHomeTab.values.indexOf(t),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    if (t == RecurringHomeTab.calendar && _calendar == null) _loadCalendar();
  }

  void _open(String path) => openPage(context, path);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dir = context.watch<RecurringDirectoryCubit>().state;
    _list = _listOf(dir);
    _listError = _list == null && dir.status == RecurringDirectoryStatus.error
        ? dir.error
        : null;
    final summary = _list?.summary;
    return Scaffold(
      appBar: AppTopBar(title: l.recurringTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: TabbedListPageBody<RecurringHomeTab>(
          tabs: [
            AppTab(
              value: RecurringHomeTab.recurring,
              label: l.recurringTabRecurring,
            ),
            AppTab(
              value: RecurringHomeTab.reminder,
              label: l.fpRecurringTabReminder,
              badgeCount: summary?.awaitingAmountCount ?? 0,
            ),
            AppTab(
              value: RecurringHomeTab.calendar,
              label: l.fpRecurringTabCalendar,
            ),
          ],
          header: [if (_list != null) _summaryCard(context, l)],
          selected: _tab,
          onChanged: (t) {
            setState(() => _tab = t);
            if (t == RecurringHomeTab.calendar && _calendar == null) {
              _loadCalendar();
            }
          },
          controller: _pager,
          pageBuilder: (context, tab) => switch (tab) {
            RecurringHomeTab.recurring => _recurringTab(l),
            RecurringHomeTab.reminder => _reminderTab(l),
            RecurringHomeTab.calendar => _calendarTab(l),
          },
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, AppLocalizations l) {
    final s = _list?.summary;
    final symbol = context.readUserCurrencySymbol;
    String money(num v) => moneyString(context, v, symbol: symbol);
    return ListSummaryCard(
      caption: l.fpRecurringListCaption,
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      actions: [
        if (_tab != RecurringHomeTab.calendar)
          ListenableBuilder(
            listenable: _search,
            builder: (context, _) => ToolbarToggleButton(
              state: _toolbar,
              filtered: _filtered,
              tooltip: l.recurringSearchHint,
            ),
          ),
      ],
      amount: s?.due30dTotal ?? 0,
      symbol: symbol,
      alert: (s?.awaitingAmountCount ?? 0) > 0
          ? l.fpRecurringAwaitingAlert(s!.awaitingAmountCount)
          : null,
      onAlertTap: () => _goTab(RecurringHomeTab.reminder),
      infoLine: s == null
          ? null
          : AppText(
              l.fpRecurringMonthLine(money(s.monthPay), money(s.monthReceive)),
              role: AppTextRole.caption,
            ),
    );
  }

  Widget _toolbarRow(AppLocalizations l) => ListToolbar(
    collapse: _toolbar,
    searchController: _search,
    onSearchChanged: _setQuery,
    searchHint: l.recurringSearchHint,
    chips: [
      OptionMenuAnchor<RecurringFilter>(
        selected: _filter,
        onSelected: _setFilter,
        options: [
          for (final f in RecurringFilter.values)
            SheetOption(value: f, label: _statusLabel(l, f)),
        ],
        builder: (context, toggle) => AppChip(
          label: '${l.recurringStatusLabel}: ${_statusLabel(l, _filter)}',
          selected: _filter != RecurringFilter.current,
          trailing: AppChipTrailing.dropdown,
          onTap: toggle,
        ),
      ),
    ],
  );

  Widget _listBody(
    AppLocalizations l, {
    required List<Recurring> rows,
    required List<Widget> children,
    required EmptyView empty,
  }) {
    final list = _list;
    return ListPageBody(
      loading: list == null && _listError == null,
      error: list == null ? _listError : null,
      isEmpty: rows.isEmpty,
      onRetry: context.read<RecurringDirectoryCubit>().load,
      rowDividers: true,
      topInset: AppSpacing.sm,
      header: [_toolbarRow(l)],
      empty: _query.trim().isNotEmpty
          ? EmptyView.compact(message: l.recurringNoMatch)
          : empty,
      children: children,
    );
  }

  Widget _recurringTab(AppLocalizations l) {
    final rows = [
      for (final r in _list?.items ?? const <Recurring>[])
        if (r.kind != RecurringKind.reminder) r,
    ];
    final live = [
      for (final r in rows)
        if (r.status != RecurringStatus.paused) r,
    ];
    final paused = [
      for (final r in rows)
        if (r.status == RecurringStatus.paused) r,
    ];
    final canAdd = _filter != RecurringFilter.archived;
    return _listBody(
      l,
      rows: rows,
      empty: EmptyView(
        icon: AppIcons.scheduled,
        title: _filter == RecurringFilter.archived
            ? l.recurringArchivedEmpty
            : l.recurringEmptyTitle,
        message: l.recurringEmptyMessage,
        cta: canAdd
            ? AddTile(
                label: l.recurringAdd,
                onTap: () => _open('/recurring/new'),
              )
            : null,
      ),
      children: [
        for (final r in live)
          RecurringRow(recurring: r, onTap: () => _open('/recurring/${r.id}')),
        if (paused.isNotEmpty) ...[
          SectionHeader(title: l.fpRecurringPausedGroup, count: paused.length),
          for (final r in paused)
            RecurringRow(
              recurring: r,
              onTap: () => _open('/recurring/${r.id}'),
            ),
        ],
        if (canAdd)
          AddTile(
            label: l.recurringAdd,
            inList: true,
            onTap: () => _open('/recurring/new'),
          ),
      ],
    );
  }

  Widget _reminderTab(AppLocalizations l) {
    final rows = [
      for (final r in _list?.items ?? const <Recurring>[])
        if (r.kind == RecurringKind.reminder) r,
    ];
    bool due(Recurring r) {
      final s = r.currentOccurrence?.status;
      return s == OccurrenceState.pending || s == OccurrenceState.notCreated;
    }

    final dueRows = [
      for (final r in rows)
        if (due(r)) r,
    ];
    final comingRows = [
      for (final r in rows)
        if (!due(r)) r,
    ];
    Widget row(Recurring r) => RecurringRow(
      recurring: r,
      amount: r.nextAmount ?? r.currentOccurrence?.amount ?? r.amount,
      onTap: () => _open('/recurring/${r.id}'),
    );
    final canAdd = _filter != RecurringFilter.archived;
    return _listBody(
      l,
      rows: rows,
      empty: EmptyView(
        icon: AppIcons.scheduled,
        title: l.recurringEmptyTitle,
        message: l.recurringEmptyMessage,
        cta: canAdd
            ? AddTile(
                label: l.fpRecurringAddReminder,
                onTap: () => _open('/recurring/new?kind=reminder'),
              )
            : null,
      ),
      children: [
        if (dueRows.isNotEmpty) ...[
          SectionHeader(title: l.fpRecurringGroupDue, count: dueRows.length),
          for (final r in dueRows) row(r),
        ],
        if (comingRows.isNotEmpty) ...[
          SectionHeader(
            title: l.fpRecurringGroupComing,
            count: comingRows.length,
          ),
          for (final r in comingRows) row(r),
        ],
        if (canAdd)
          AddTile(
            label: l.fpRecurringAddReminder,
            inList: true,
            onTap: () => _open('/recurring/new?kind=reminder'),
          ),
      ],
    );
  }

  CalendarDot _dot(RecurringItem i) => switch (i.type) {
    TransactionType.income => CalendarDot.income,
    TransactionType.expense => CalendarDot.expense,
    TransactionType.transfer => CalendarDot.neutral,
  };

  Widget _calendarTab(AppLocalizations l) {
    final page = _calendar;
    final items = page?.items ?? const <RecurringItem>[];
    final dots = <int, List<CalendarDot>>{};
    for (final i in items) {
      if (i.state == OccurrenceState.archived) continue;
      final list = dots.putIfAbsent(i.date.day, () => []);
      final d = _dot(i);
      if (!list.contains(d)) list.add(d);
    }
    final dayItems = [
      for (final i in items)
        if (DateUtils.isSameDay(i.date, _day)) i,
    ];
    return ListPageBody(
      loading: page == null && _calendarError == null,
      error: page == null ? _calendarError : null,
      isEmpty: false,
      onRetry: _loadCalendar,
      rowDividers: false,
      topInset: AppSpacing.sm,
      empty: EmptyView.compact(message: l.fpRecurringCalendarNone),
      children: [
        MonthCalendar(
          month: _month,
          today: today(),
          selected: _day,
          dots: dots,
          onMonthChanged: _onMonth,
          onSelect: (d) => setState(() => _day = d),
        ),
        DateGroupHeader(label: itemDateLabel(context, _day)),
        if (dayItems.isEmpty)
          EmptyView.compact(message: l.fpRecurringCalendarNone)
        else
          for (final i in dayItems)
            RecurringItemRow(
              item: i,
              showParent: true,
              onTap: i.recurring == null
                  ? null
                  : () => _open('/recurring/${i.recurring!.id}'),
            ),
      ],
    );
  }
}
