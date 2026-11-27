import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/app_page.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/quick_create_look.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/data/write_effects.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurrence_rule.dart' show today;
import '../../domain/recurring.dart';
import '../../domain/recurring_item.dart';
import '../../domain/recurring_page.dart' show RecurringTouch;
import '../../domain/recurring_summary.dart';
import '../cubit/recurring_directory_cubit.dart';
import '../due_boxes.dart';
import '../occurrence_actions.dart';
import '../recurring_rows.dart';
import 'recurring_form_page.dart'
    show recurringTrackingTypes, trackingTypeLabel;

/// รายการประจำ (spec §3, mock ListPage / ListDay / ListRange): one page, no
/// tabs. The hero holds this month's figures and the month calendar; nothing
/// picked = ต้องทำ + every recurring (ตั้งเอง / เกี่ยวกับหน้าอื่น, the tracking
/// chips); a day, or a second day = the range, lists its rounds with the
/// ones that need action on top.
class RecurringHomePage extends StatefulWidget {
  const RecurringHomePage({this.focusDue = false, super.key});

  /// `?focus=due` (the due notice): scroll to ต้องทำ once it is there.
  final bool focusDue;

  @override
  State<RecurringHomePage> createState() => _RecurringHomePageState();
}

class _RecurringHomePageState extends State<RecurringHomePage> {
  late DateTime _month = _thisMonth;

  /// A picked day (start = end) or range; null = nothing picked.
  DateTimeRange? _range;

  List<RecurringItem>? _items;

  /// The month [_items] are of: they stay up while the next month loads.
  DateTime? _itemsMonth;
  Object? _itemsError;
  int _itemsSeq = 0;
  List<RecurringItem> _due = const [];

  final _dueKey = GlobalKey();
  late bool _focusDue = widget.focusDue;

  final _search = TextEditingController();
  final _toolbar = PpForgeListToolbarState.of('recurring');
  String _query = '';

  /// รายการประจำทั้งหมด's tracking chip (null = ทั้งหมด).
  String? _tracking;

  /// Amounts typed in the rows, by occurrence.
  final _rowAmounts = <String, double?>{};

  static DateTime get _thisMonth {
    final t = today();
    return DateTime(t.year, t.month);
  }

  RecurringRepository get _repo => RecurringRepository.of(context);

  void Function()? _offEffects;

  @override
  void initState() {
    super.initState();
    _offEffects = WriteEffectsBus.instance.listen(_onEffects);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<RecurringDirectoryCubit>().loadIfNeeded());
      unawaited(_loadMonth());
      unawaited(_loadDue());
    });
  }

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
        showPpForgeSnackBar(
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
      _range = null;
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

  /// The centre button goes to this page's create page (owner 2026-11-12).
  @override
  Widget build(BuildContext context) => QuickCreatePresetScope(
    preset: QuickCreatePreset.create(
      QuickCreateLook.add(
        context,
        color: ModuleColors.of(context).planning,
        icon: AppIcons.recurring,
      ),
      () => _open('/recurring/new'),
    ),
    child: _page(context),
  );

  /// One page, no tabs (spec §3 recurring list; mock ListPage / ListDay /
  /// ListRange): the month calendar in the hero; nothing picked = ต้องทำ +
  /// every recurring; a day / range = its rounds, ต้องจัดการ on top.
  Widget _page(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dir = context.watch<RecurringDirectoryCubit>().state;
    final items = _items ?? const <RecurringItem>[];
    return AppPage(
      topBar: AppTopBar(title: l.recurringTitle, showBack: true),
      body: ListPageBody(
        loading: _items == null && _itemsError == null,
        error: _items == null ? _itemsError : null,
        isEmpty: _items == null,
        onRetry: _refresh,
        empty: EmptyView.compact(message: l.recurringEmptyTitle),
        children: [
          _hero(l, items, dir),
          if (_range == null) ...[
            if (_due.isNotEmpty) ...[
              const SizedBox(height: PpForgeSpacing.md),
              _dueCard(l, dir),
            ],
            ..._allRules(l, dir),
          ] else
            ..._rangeList(l, items),
        ],
      ),
    );
  }

  String _money(num v) =>
      moneyString(context, v, symbol: context.readUserCurrencySymbol);

  Recurring? _ruleOf(RecurringDirectoryState dir, RecurringItem i) {
    final id = i.recurring?.id;
    for (final r in dir.rules) {
      if (r.id == id) return r;
    }
    return null;
  }

  static bool _unknown(RecurringItem i) => i.amount == null && !i.state.settled;

  /// The month's figures (mock ListPage): this month = the BE's (it knows the
  /// card plans' installments); another month = its rounds here. A round
  /// with no amount counts its rule's average ("~").
  MonthHero _figures(List<RecurringItem> items, RecurringDirectoryState dir) {
    if (_month == _thisMonth && dir.summary != null) return dir.summary!.month;
    var expense = 0.0, paid = 0.0, income = 0.0, saving = 0.0, install = 0.0;
    var approx = false;
    for (final i in items) {
      if (i.state == OccurrenceState.archived) continue;
      final rule = _ruleOf(dir, i);
      var a = i.amount;
      if (a == null || a <= 0) {
        a = rule?.avgAmount ?? 0;
        if (i.type == TransactionType.expense) approx = true;
      }
      if (i.isSaving) {
        saving += a;
      } else if (rule?.kind == RecurringKind.debt) {
        if (i.type == TransactionType.expense) install += a;
      } else if (i.type == TransactionType.expense) {
        expense += a;
        if (i.state.settled) paid += a;
      } else if (i.type == TransactionType.income) {
        income += a;
      }
    }
    return MonthHero(
      expense: expense,
      approx: approx,
      paid: paid,
      income: income,
      saving: saving,
      installment: install,
    );
  }

  /// รายจ่ายเดือนนี้ (no saving / installments, "~" when some are guesses),
  /// the paid bar, รายรับ / ออม / ผ่อน, then the month calendar (a day, or a
  /// second day = the range between).
  Widget _hero(
    AppLocalizations l,
    List<RecurringItem> items,
    RecurringDirectoryState dir,
  ) {
    final f = _figures(items, dir);
    final symbol = context.readUserCurrencySymbol;
    final captions = _captions(l, items);
    final number = f.approx
        ? '~${_money(f.expense)}'
        : moneyString(context, f.expense, symbol: symbol);
    return PpForgeHeroCard(
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
          key: const ValueKey('heroExpense'),
          label: l.recurringHeroExpense,
          value: Text(number),
        ),
        if (f.expense > 0)
          HeroBar(
            key: const ValueKey('heroPaidBar'),
            value: (f.paid / f.expense).clamp(0.0, 1.0),
            fillLabel: '${(f.paid / f.expense * 100).clamp(0, 100).round()}%',
            left: l.recurringHeroPaid(_money(f.paid)),
            right: l.recurringHomeLeft(
              '${f.approx ? '~' : ''}${_money(f.left)}',
            ),
          ),
        HeroTiles(
          joined: true,
          children: [
            SummaryTileView(
              key: const ValueKey('heroIncome'),
              tile: SummaryTile(
                label: l.trackingIncome,
                value: _money(f.income),
                tone: f.income > 0
                    ? SummaryTileTone.green
                    : SummaryTileTone.neutral,
              ),
            ),
            SummaryTileView(
              key: const ValueKey('heroSaving'),
              tile: SummaryTile(
                label: l.trackingSaving,
                value: _money(f.saving),
              ),
            ),
            SummaryTileView(
              key: const ValueKey('heroInstallment'),
              tile: SummaryTile(
                label: l.trackingInstallment,
                value: _money(f.installment),
              ),
            ),
          ],
        ),
        MonthCalendar(
          key: const ValueKey('recurringCalendar'),
          month: _month,
          showStepper: false,
          today: today(),
          range: _range,
          captions: captions,
          // The box edged in the day's tone: waiting, out or in.
          edges: {
            for (final MapEntry(:key, :value) in captions.entries)
              if (value.tone != CalendarDot.neutral) key: value.tone,
          },
          onMonthChanged: _onMonth,
          onSelect: (d) =>
              setState(() => _range = CalendarPick.tapRange(_range, d)),
        ),
        PpForgeText(l.recurringCalendarHint, role: PpForgeTextRole.caption),
      ],
    );
  }

  /// A picked day or range (mock ListDay / ListRange): its head (✕ clears),
  /// a range's totals, ต้องจัดการ in its own box, then everything else by
  /// date (done and coming together).
  List<Widget> _rangeList(AppLocalizations l, List<RecurringItem> items) {
    final r = _range!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final single = DateUtils.isSameDay(r.start, r.end);
    bool inRange(RecurringItem i) =>
        !i.date.isBefore(DateUtils.dateOnly(r.start)) &&
        !i.date.isAfter(DateUtils.dateOnly(r.end));
    final rows = [
      for (final i in items)
        if (i.state != OccurrenceState.archived && inRange(i)) i,
    ]..sort((a, b) => a.date.compareTo(b.date));
    final act = [
      for (final i in rows)
        if (_actionable(i)) i,
    ];
    final rest = [
      for (final i in rows)
        if (!_actionable(i)) i,
    ];
    final title = single
        ? itemDateLabel(context, r.start)
        : l.recurringRangeLabel(
            DateFormat.d(locale).format(r.start),
            DateFormat.MMMd(locale).format(r.end),
          );
    final out = <Widget>[
      PpForgeListHeader(
        key: const ValueKey('rangeHead'),
        title: title,
        count: rows.length,
        onClearTitle: () => setState(() => _range = null),
      ),
    ];
    if (!single) {
      final dir = context.read<RecurringDirectoryCubit>().state;
      var pay = 0.0, receive = 0.0, other = 0.0;
      var approx = false;
      for (final i in rows) {
        var a = i.amount;
        if (a == null || a <= 0) {
          a = _ruleOf(dir, i)?.avgAmount ?? 0;
          approx = true;
        }
        if (i.isSaving || _ruleOf(dir, i)?.kind == RecurringKind.debt) {
          other += a;
        } else if (i.type == TransactionType.income) {
          receive += a;
        } else if (i.type == TransactionType.expense) {
          pay += a;
        }
      }
      out.add(
        HeroTiles(
          key: const ValueKey('rangeTotals'),
          joined: true,
          children: [
            SummaryTileView(
              tile: SummaryTile(
                label: l.recurringRangePay,
                value: '${approx ? '~' : ''}${_money(pay)}',
                tone: SummaryTileTone.red,
              ),
            ),
            SummaryTileView(
              tile: SummaryTile(
                label: l.recurringRangeReceive,
                value: _money(receive),
                tone: SummaryTileTone.green,
              ),
            ),
            SummaryTileView(
              tile: SummaryTile(
                label: l.recurringRangeInstallSave,
                value: _money(other),
              ),
            ),
          ],
        ),
      );
    }
    if (rows.isEmpty) {
      out.add(
        EmptyView.compact(
          message: l.recurringDayEmpty(DateFormat.MMMd(locale).format(r.start)),
        ),
      );
      return out;
    }
    if (act.isNotEmpty) {
      out.add(const SizedBox(height: PpForgeSpacing.sm));
      out.add(
        SectionCard(
          key: const ValueKey('rangeAction'),
          title: l.recurringNeedsAction,
          trailing: PpForgeChip(
            label: '${act.length}',
            tone: PpForgeChipTone.warning,
            size: ChipSize.chip,
          ),
          children: [for (final i in act) _listRow(l, i, withDate: true)],
        ),
      );
    }
    if (rest.isNotEmpty) {
      out.add(
        PpForgeListHeader(title: l.recurringRangeList, count: rest.length),
      );
      out.add(
        SectionCard(
          key: const ValueKey('rangeRest'),
          children: [for (final i in rest) _listRow(l, i, withDate: true)],
        ),
      );
    }
    return out;
  }

  PpForgeIconCode? _iconOf(RecurringItem i) {
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

  /// Waiting on the user: due, or no amount yet.
  bool _actionable(RecurringItem i) =>
      i.state != OccurrenceState.archived &&
      !i.state.settled &&
      (_todo(i) || _unknown(i));

  /// A list row (PpForgeListRow): the item's icon, its name and state pill,
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
    return PpForgeListRow(
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

  /// รายการประจำทั้งหมด: 🔍 and +, the tracking chips, then two sections:
  /// เกี่ยวกับหน้าอื่น (a rule touches a goal / person / institution / plan
  /// or pays a card; chips say what) and ตั้งเอง. Paused ones dimmed, last.
  List<Widget> _allRules(AppLocalizations l, RecurringDirectoryState dir) {
    final needle = _query.trim().toLowerCase();
    final rules = [
      for (final r in dir.rules)
        if (r.status != RecurringStatus.archived &&
            (needle.isEmpty || r.name.toLowerCase().contains(needle)))
          r,
    ];
    final head = [
      PpForgeListHeader(
        title: l.recurringHomeAllTitle,
        count: rules.length,
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
      PpForgeListToolbar(
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
    final counts = <String, int>{};
    for (final r in rules) {
      counts[r.trackingType] = (counts[r.trackingType] ?? 0) + 1;
    }
    final shown =
        [
          for (final r in rules)
            if (_tracking == null || r.trackingType == _tracking) r,
        ]..sort((a, b) {
          final pa = a.status == RecurringStatus.paused ? 1 : 0;
          final pb = b.status == RecurringStatus.paused ? 1 : 0;
          if (pa != pb) return pa - pb;
          final x = a.nextDate, y = b.nextDate;
          if (x == null) return y == null ? 0 : 1;
          if (y == null) return -1;
          return x.compareTo(y);
        });
    final self = [
      for (final r in shown)
        if (!r.related) r,
    ];
    final related = [
      for (final r in shown)
        if (r.related) r,
    ];
    return [
      ...head,
      FilterBar(
        key: const ValueKey('recurringTrackingChips'),
        padding: const EdgeInsets.symmetric(vertical: PpForgeSpacing.xs),
        chips: [
          PpForgeChip(
            label: '${l.trackingAll} ${rules.length}',
            selected: _tracking == null,
            onTap: () => setState(() => _tracking = null),
          ),
          for (final t in recurringTrackingTypes)
            if ((counts[t] ?? 0) > 0)
              PpForgeChip(
                key: ValueKey('tracking:$t'),
                label: '${trackingTypeLabel(l, t)} ${counts[t]}',
                selected: _tracking == t,
                onTap: () => setState(() => _tracking = t),
              ),
        ],
      ),
      if (self.isNotEmpty) ...[
        PpForgeListHeader(
          key: const ValueKey('recurringSelf'),
          title: l.recurringSectionSelf,
          count: self.length,
        ),
        SectionCard(children: [for (final r in self) _recurringRow(l, r)]),
      ],
      if (related.isNotEmpty) ...[
        PpForgeListHeader(
          key: const ValueKey('recurringRelated'),
          title: l.recurringSectionRelated,
          count: related.length,
        ),
        SectionCard(children: [for (final r in related) _recurringRow(l, r)]),
      ],
    ];
  }

  /// A recurring (mock ListPage): icon · name · n rules · its round · its
  /// wallet, yellow chips of what it touches (a tap opens that page), the
  /// per-month amount.
  Widget _recurringRow(AppLocalizations l, Recurring r) {
    final dots = endChainDots(r);
    return RecurringRow(
      key: ValueKey('recurring:${r.id}'),
      recurring: r,
      footer: r.touches.isEmpty && dots == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (r.touches.isNotEmpty)
                  Wrap(
                    spacing: PpForgeSpacing.xs,
                    runSpacing: PpForgeSpacing.xs,
                    children: [
                      for (final t in r.touches)
                        PpForgeChip(
                          key: ValueKey('touch:${r.id}:${t.kind}:${t.id}'),
                          label: t.name,
                          tone: PpForgeChipTone.warning,
                          size: ChipSize.mini,
                          onTap: () => _open(_touchPath(t)),
                        ),
                    ],
                  ),
                ?dots == null ? null : OccurrenceChain(dots: dots),
              ],
            ),
      onTap: () => _open('/recurring/${r.id}'),
    );
  }

  static String _touchPath(RecurringTouch t) => switch (t.kind) {
    'goal' => '/saving-goals/${t.id}',
    'plan' => '/personal-debts/plans/${t.id}',
    'card' => '/personal-debts/cards/${t.id}',
    _ => '/personal-debts/people/${Uri.encodeComponent(t.key ?? '')}',
  };
}
