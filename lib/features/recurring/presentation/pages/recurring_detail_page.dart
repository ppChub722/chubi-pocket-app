import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_chip_path.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/widgets/account_picker_sheet.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurrence_rule.dart';
import '../../domain/recurring.dart';
import '../../domain/recurring_item.dart';
import '../recurring_draft.dart';
import '../recurring_item_actions.dart';
import '../recurring_rows.dart';

enum _Tab { past, upcoming }

enum _Field { name, description, amount, note }

enum _Occ { editAmount, move, skip, restore, editFull }

class RecurringDetailPage extends StatefulWidget {
  const RecurringDetailPage({
    this.id,
    this.startEditing = false,
    this.preset = const RecurringPreset(),
    super.key,
  });

  final String? id;

  final bool startEditing;

  final RecurringPreset preset;

  bool get isCreate => id == null;

  @override
  State<RecurringDetailPage> createState() => _RecurringDetailPageState();
}

class _RecurringDetailPageState extends State<RecurringDetailPage>
    with EditModeMixin<RecurringDetailPage, RecurringDraft> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = {for (final f in _Field.values) f: TextEditingController()};
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _noteFocus = FocusNode();

  RecurringDetail? _detail;
  bool _loading = false;

  ApiException? _error;

  ApiException? _refreshError;

  _Tab _tab = _Tab.past;
  bool _busy = false;
  bool _changed = false;
  bool _walletMissing = false;

  ItemPage _produced = const ItemPage();
  bool _producedMore = false;
  Object? _producedMoreError;
  final Set<String> _selected = {};
  bool _selecting = false;

  ItemPage _upcoming = const ItemPage();
  bool _upcomingMore = false;
  Object? _upcomingMoreError;

  RecurringRepository get _repo => RecurringRepository.of(context);
  Recurring? get _recurring => _detail?.recurring;

  @override
  void initState() {
    super.initState();
    initDraft(
      RecurringDraft.blank(preset: widget.preset),
      editing: widget.isCreate,
    );
    onDraftRestored();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
      context.read<TagsCubit>().loadIfNeeded();
      if (!widget.isCreate) _load(first: true);
    });
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _noteFocus.dispose();
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
      final d = await _repo.get(widget.id!);
      if (!mounted) return;
      _take(d);
      setState(() {
        _error = null;
        _refreshError = null;
      });
      if (first && widget.startEditing) enterEdit();
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
      _selected.retainAll(d.produced.items.map((i) => i.id));
    });
    if (!isEditing) resetDraft(RecurringDraft.from(d.recurring));
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
        widget.id!,
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

  Future<void> _loadMoreUpcoming() async {
    final current = _upcoming;
    if (!current.hasMore || _upcomingMore) return;
    setState(() {
      _upcomingMore = true;
      _upcomingMoreError = null;
    });
    try {
      final next = await _repo.items(
        widget.id!,
        upcoming: true,
        page: current.page + 1,
      );
      if (mounted) setState(() => _upcoming = next.after(current));
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
    final all = [..._produced.items, ..._upcoming.items];
    final known = {for (final i in all) i.id};
    final merged = [
      ...r.applyTo(all),
      for (final i in r.items)
        if (!known.contains(i.id)) i,
    ];
    final up = _upcoming;
    setState(() {
      _produced = ItemPage(
        items: [
          for (final i in merged)
            if (i.state != OccurrenceState.upcoming) i,
        ]..sort((a, b) => b.date.compareTo(a.date)),
        page: _produced.page,
        totalPages: _produced.totalPages,
      );
      _upcoming = ItemPage(
        items: [
          for (final i in merged)
            if (i.state == OccurrenceState.upcoming) i,
        ]..sort((a, b) => a.date.compareTo(b.date)),
        page: up.page,
        totalPages: up.totalPages,
      );
      _selected.removeAll(r.deletedIds);
      final setting = r.setting;
      final d = _detail;
      if (setting != null && d != null) {
        _detail = RecurringDetail(
          recurring: setting,
          produced: d.produced,
          upcoming: d.upcoming,
          balances: d.balances,
        );
      }
    });
    if (r.setting == null) _load();
  }

  Future<void> _occurrenceCall(Future<ItemWriteResult> Function() call) async {
    setState(() => _busy = true);
    final accounts = context.read<AccountsCubit>();
    try {
      final r = await call();
      accounts.patchBalances(r.balances);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _applyItems(r);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editOccurrence(
    RecurringItem i, {
    required OccurrenceFocus focus,
  }) async {
    final l = AppLocalizations.of(context)!;
    final unknown = i.amount == null || i.amount! <= 0;
    final now = today();
    final r = await showOccurrenceSheet(
      context,
      title: focus == OccurrenceFocus.date
          ? l.fpRecurringOccMoveTitle
          : (unknown ? l.fpRecurringOccEnterTitle : l.fpRecurringOccEditTitle),
      saveLabel: l.commonSave,
      dateLabel: l.fpRecurringOccDate,
      amountLabel: l.fpRecurringOccAmount,
      date: i.date,
      amount: unknown ? null : i.amount,
      symbol: context.readUserCurrencySymbol,
      first: i.date.isBefore(now) ? i.date : now,
      last: DateTime(now.year + 2, now.month, now.day),
      withAmount: focus == OccurrenceFocus.amount,
      amountRequired: unknown,
      focus: focus,
    );
    if (!mounted || r == null) return;
    await _occurrenceCall(
      () => _repo.editOccurrence(
        i.id,
        date: r.date == i.date ? null : r.date,
        amount: r.amount,
      ),
    );
  }

  Future<void> _skip(RecurringItem i) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.fpRecurringSkipTitle,
      message: l.fpRecurringSkipBody,
      confirmLabel: l.fpRecurringActSkip,
    );
    if (!ok || !mounted) return;
    await _occurrenceCall(() => _repo.setItemArchived(i.id, archived: true));
  }

  Future<void> _restoreItem(RecurringItem i) =>
      _occurrenceCall(() => _repo.setItemArchived(i.id, archived: false));

  Future<void> _occurrenceMenu(RecurringItem i) async {
    final l = AppLocalizations.of(context)!;
    final skipped = i.state == OccurrenceState.archived;
    final picked = await showOptionSheet<_Occ>(
      context,
      title: DateFormat.MMMd(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(i.date),
      options: [
        if (!skipped) ...[
          SheetOption(
            value: _Occ.editAmount,
            label: l.fpRecurringActEditAmount,
            leading: const AppIcon(AppIcons.edit),
          ),
          SheetOption(
            value: _Occ.move,
            label: l.fpRecurringActMove,
            leading: const AppIcon(AppIcons.date),
          ),
          SheetOption(
            value: _Occ.skip,
            label: l.fpRecurringActSkip,
            leading: const AppIcon(AppIcons.archive),
          ),
        ] else
          SheetOption(
            value: _Occ.restore,
            label: l.recurringItemRestore,
            leading: const AppIcon(AppIcons.unarchive),
          ),
        SheetOption(value: _Occ.editFull, label: l.recurringItemEditTitle),
      ],
    );
    if (!mounted || picked == null) return;
    switch (picked) {
      case _Occ.editAmount:
        await _editOccurrence(i, focus: OccurrenceFocus.amount);
      case _Occ.move:
        await _editOccurrence(i, focus: OccurrenceFocus.date);
      case _Occ.skip:
        await _skip(i);
      case _Occ.restore:
        await _restoreItem(i);
      case _Occ.editFull:
        await editRecurringItem(context, i, onChanged: _applyItems);
    }
  }

  Future<void> _batch(ItemBatchAction action) async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    ItemTarget? target;
    bool? deleteLinked;
    if (action == ItemBatchAction.create) {
      target = await askCreateTarget(context);
      if (target == null) return;
    } else if (action == ItemBatchAction.delete) {
      final linkedTx = _produced.items.any(
        (i) => _selected.contains(i.id) && i.transaction != null,
      );
      deleteLinked = await askDeleteLinked(
        context,
        linkedTx: linkedTx,
        count: ids.length,
      );
      if (deleteLinked == null) return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    final accounts = context.read<AccountsCubit>();
    try {
      final r = await _repo.batch(
        ids,
        action,
        target: target,
        deleteLinkedTx: deleteLinked,
      );
      accounts.patchBalances(r.balances);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      _applyItems(r);
      setState(() {
        _selected.clear();
        _selecting = false;
      });
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(RecurringAction a) async {
    setState(() => _busy = true);
    try {
      final d = await _repo.action(widget.id!, a);
      if (!mounted) return;
      _changed = true;
      HapticFeedback.mediumImpact();
      _take(d);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  bool get leaveOnCancel => widget.isCreate;

  @override
  void leavePage() {
    if (context.canPop()) {
      context.pop(_changed);
    } else {
      super.leavePage();
    }
  }

  @override
  void onDraftRestored() {
    void sync(_Field f, String v) {
      if (_ctrl[f]!.text != v) _ctrl[f]!.text = v;
    }

    sync(_Field.name, working.name);
    sync(_Field.description, working.description);
    sync(_Field.amount, working.amount);
    sync(_Field.note, working.note);
  }

  void _onText(_Field f, String v) => applyTextChange(f, switch (f) {
    _Field.name => working.copyWith(name: v),
    _Field.description => working.copyWith(description: v),
    _Field.amount => working.copyWith(amount: v),
    _Field.note => working.copyWith(note: v),
  });

  void _change(RecurringDraft next) {
    if (!isEditing) enterEdit();
    applyChange(next);
  }

  Future<void> _pickIcon() async {
    final l = AppLocalizations.of(context)!;
    final r = await showIconMakerSheet(
      context: context,
      type: IconType.category,
      initial: working.iconCode,
      title: l.recurringFieldIcon,
    );
    if (!mounted || r == null) return;
    if (r is IconMakerSelected) {
      _change(working.copyWith(iconCode: r.iconCode));
    } else if (r is IconMakerRemoved) {
      _change(working.copyWith(clearIcon: true));
    }
  }

  Future<void> _pickWallet({required bool to}) async {
    final l = AppLocalizations.of(context)!;
    final accounts = context.read<AccountsCubit>();
    final r = await showAccountPickerSheet(
      context: context,
      accounts: accounts.state.accounts,
      selected: accounts.byId(
        (to ? working.toAccountId : working.accountId) ?? '',
      ),
      excludeId: to ? working.accountId : working.toAccountId,
      title: to ? l.recurringFieldToWallet : null,
    );
    if (!mounted || r is! AccountPickerSelected) return;
    setState(() => _walletMissing = false);
    _change(
      to
          ? working.copyWith(toAccountId: r.account.id)
          : working.copyWith(accountId: r.account.id),
    );
  }

  Future<void> _pickCategory() async {
    final l = AppLocalizations.of(context)!;
    final cats = context.read<CategoriesCubit>();
    final r = await showCategoryPickerSheet(
      context: context,
      categories: cats.state.categories,
      type: working.type == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense,
      selected: cats.byId(working.categoryId ?? ''),
      title: l.recurringFieldCategory,
      allowCreate: true,
    );
    if (!mounted || r == null) return;
    _change(switch (r) {
      CategoryPickerSelected(:final category) => working.copyWith(
        categoryId: category.id,
      ),
      CategoryPickerCleared() => working.copyWith(clearCategory: true),
    });
  }

  Future<void> _pickTags() async {
    final l = AppLocalizations.of(context)!;
    final picked = await showTagPickerSheet(
      context,
      selected: working.tagIds,
      title: l.transactionFormTagsLabel,
    );
    if (picked == null || !mounted) return;
    _change(working.copyWith(tagIds: picked));
  }

  Future<void> _pickMode() async {
    final l = AppLocalizations.of(context)!;
    final picked = await showOptionSheet<TransactionType>(
      context,
      title: l.fpRecurringFieldMode,
      selected: working.type,
      options: [
        SheetOption(
          value: TransactionType.expense,
          label: l.transactionTypeExpense,
        ),
        SheetOption(
          value: TransactionType.transfer,
          label: l.transactionTypeTransfer,
        ),
      ],
    );
    if (!mounted || picked == null || picked == working.type) return;
    _change(
      working.copyWith(
        type: picked,
        clearCategory: true,
        accountId: working.accountId,
      ),
    );
  }

  Future<void> _pickRepeat() async {
    final l = AppLocalizations.of(context)!;
    final start = working.rule.start;
    final end = working.rule.end;
    final nth = (start.day - 1) ~/ 7 + 1;
    final presets = <RecurrenceRule>[
      RecurrenceRule(freq: RecurrenceFreq.daily, start: start, end: end),
      RecurrenceRule(
        freq: RecurrenceFreq.weekly,
        start: start,
        weekdays: {start.weekday},
        end: end,
      ),
      RecurrenceRule(
        freq: RecurrenceFreq.weekly,
        start: start,
        interval: 2,
        weekdays: {start.weekday},
        end: end,
      ),
      RecurrenceRule(
        freq: RecurrenceFreq.monthly,
        start: start,
        monthly: RecurrenceMonthly.onDay(start.day),
        end: end,
      ),
      if (nth <= 4)
        RecurrenceRule(
          freq: RecurrenceFreq.monthly,
          start: start,
          monthly: RecurrenceMonthly.onWeekday(
            nth: nth,
            weekday: start.weekday,
          ),
          end: end,
        ),
      RecurrenceRule(freq: RecurrenceFreq.yearly, start: start, end: end),
    ];
    final current = working.rule;
    final picked = await showOptionSheet<Object>(
      context,
      title: l.recurringFieldRepeat,
      selected: presets.contains(current)
          ? current
          : (current.freq == RecurrenceFreq.dates ? _RepeatMore.dates : null),
      options: [
        for (final p in presets)
          SheetOption<Object>(value: p, label: recurrenceLabel(l, p)),
        SheetOption<Object>(
          value: _RepeatMore.custom,
          label: l.recurringRepeatCustom,
        ),
        SheetOption<Object>(
          value: _RepeatMore.dates,
          label: l.recurringRepeatDates,
        ),
      ],
    );
    if (!mounted || picked == null) return;
    if (picked is RecurrenceRule) {
      _change(working.copyWith(rule: picked));
    } else if (picked == _RepeatMore.custom) {
      await _openRecurrenceSheet();
    } else if (picked == _RepeatMore.dates) {
      await _pickDates();
    }
  }

  Future<void> _pickDates() async {
    final l = AppLocalizations.of(context)!;
    final first = today();
    final days = await showMultiDatePicker(
      context,
      initial: {
        if (working.rule.freq == RecurrenceFreq.dates) ...working.rule.dates,
      },
      first: first,
      last: DateTime(first.year + 2, first.month, first.day),
      title: l.recurringRepeatDatesTitle,
      confirmLabel: l.recurringRepeatDatesConfirm,
    );
    if (!mounted || days == null || days.isEmpty) return;
    final sorted = days.toList()..sort();
    _change(
      working.copyWith(
        rule: RecurrenceRule(
          freq: RecurrenceFreq.dates,
          start: sorted.first,
          dates: sorted,
        ),
      ),
    );
  }

  Future<void> _pickStart() async {
    final now = today();
    final current = working.rule.start;
    final picked = await showAppDatePicker(
      context,
      initial: current,
      first: current.isBefore(now) ? current : now,
      last: DateTime(now.year + 2, now.month, now.day),
    );
    if (!mounted || picked is! AppDatePicked) return;
    final d = picked.date;
    final r = working.rule;
    _change(
      working.copyWith(
        rule: r.copyWith(
          start: d,
          weekdays: r.weekdays.length == 1 ? {d.weekday} : null,
          monthly: r.monthly?.mode == RecurrenceMonthlyMode.day
              ? RecurrenceMonthly.onDay(d.day)
              : null,
        ),
      ),
    );
  }

  Future<void> _openRecurrenceSheet() async {
    final picked = await showRecurrenceSheet(context, initial: working.rule);
    if (!mounted || picked == null) return;
    _change(working.copyWith(rule: picked));
  }

  Future<void> _pickEnd() async {
    final l = AppLocalizations.of(context)!;
    final rule = working.rule;
    final choice = await showOptionSheet<RecurrenceEndKind>(
      context,
      title: l.recurringFieldEnd,
      selected: rule.end.kind,
      options: [
        SheetOption(value: RecurrenceEndKind.never, label: l.recurringEndNever),
        SheetOption(
          value: RecurrenceEndKind.onDate,
          label: l.recurringEndOnDateOption,
        ),
        SheetOption(
          value: RecurrenceEndKind.afterCount,
          label: l.recurringEndAfterCountOption,
        ),
      ],
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case RecurrenceEndKind.never:
        _change(
          working.copyWith(
            rule: rule.copyWith(end: const RecurrenceEnd.never()),
          ),
        );
      case RecurrenceEndKind.onDate:
        final start = rule.start;
        final picked = await showAppDatePicker(
          context,
          initial: rule.end.date ?? start.add(const Duration(days: 365)),
          first: start,
          last: DateTime(start.year + 2, start.month, start.day),
        );
        if (!mounted || picked is! AppDatePicked) return;
        _change(
          working.copyWith(
            rule: rule.copyWith(end: RecurrenceEnd.onDate(picked.date)),
          ),
        );
      case RecurrenceEndKind.afterCount:
        await _pickCount();
    }
  }

  Future<void> _pickCount() async {
    final l = AppLocalizations.of(context)!;
    final n = await showCountSheet(
      context,
      title: l.fpRecurringFieldCount,
      label: l.fpRecurringFieldCount,
      saveLabel: l.commonSave,
      initial: working.rule.end.count,
    );
    if (!mounted || n == null) return;
    _change(
      working.copyWith(
        rule: working.rule.copyWith(end: RecurrenceEnd.afterCount(n)),
      ),
    );
  }

  Future<void> _pickTrial() async {
    final l = AppLocalizations.of(context)!;
    final now = today();
    final current = working.trialUntil;
    final picked = await showAppDatePicker(
      context,
      initial: current ?? now.add(const Duration(days: 30)),
      first: now,
      last: DateTime(now.year + 2, now.month, now.day),
      title: l.fpRecurringTrialUntil,
      clearable: current != null,
    );
    if (!mounted || picked == null) return;
    if (picked is AppDatePicked) {
      _change(working.copyWith(trialUntil: picked.date));
    } else if (picked is AppDateCleared) {
      _change(working.copyWith(clearTrial: true));
    }
  }

  Future<void> _save() async {
    commitTextSession();
    final l = AppLocalizations.of(context)!;
    final formOk = _formKey.currentState?.validate() ?? false;
    final walletOk = working.walletOk;
    if (!walletOk) setState(() => _walletMissing = true);
    if (!formOk || !walletOk) return;
    if (!working.countOk) {
      showAppSnackBarOn(
        pageMessenger!,
        l.fpRecurringCountRequired,
        tone: Tone.danger,
      );
      return;
    }

    var scope = EditScope.upcoming;
    var alsoUpdateLink = false;
    final r = _recurring;
    if (r != null && working.valuesDiffer(original)) {
      final picked = await showEditScopeChoice(
        context,
        title: l.recurringScopeTitle,
        options: {
          EditScope.upcoming: l.recurringScopeUpcoming,
          EditScope.all: l.recurringScopeAll,
        },
        selected: EditScope.upcoming,
      );
      if (!mounted || picked == null) return;
      scope = picked;
      if (scope == EditScope.all && r.counts.pending + r.counts.done > 0) {
        final choice = await showLinkedPrompt(
          context,
          title: l.linkedSaveTitle,
          cancelLabel: l.linkedCancel,
          thisSideLabel: l.linkedSaveThisOnly,
          bothSidesLabel: l.linkedSaveBoth,
        );
        if (!mounted || choice == null) return;
        alsoUpdateLink = choice == LinkedChoice.bothSides;
      }
    }

    FocusScope.of(context).unfocus();
    setSaving(true);
    final accounts = context.read<AccountsCubit>();
    try {
      final write = working.toWrite();
      final d = r == null
          ? await _repo.create(write)
          : await _repo.update(
              r.id,
              write,
              scope: scope,
              alsoUpdateLink: alsoUpdateLink,
            );
      accounts.patchBalances(d.balances);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _changed = true;
      if (widget.isCreate) {
        commitSaved(working);
        leavePage();
        return;
      }
      _take(d);
      commitSaved(RecurringDraft.from(d.recurring));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
    }
  }

  Future<void> _run(Future<RecurringDetail> Function() call) async {
    setSaving(true);
    try {
      final d = await call();
      if (!mounted) return;
      _changed = true;
      _take(d);
      commitSaved(RecurringDraft.from(d.recurring));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
    }
  }

  Future<void> _archive(Recurring r, {required bool restore}) async {
    final l = AppLocalizations.of(context)!;
    if (!restore) {
      final ok = await showConfirmDialog(
        context,
        title: l.recurringArchiveTitle,
        message: l.recurringArchiveBody,
        confirmLabel: l.recurringArchive,
      );
      if (!ok || !mounted) return;
    }
    await _run(
      () => _repo.action(
        r.id,
        restore ? RecurringAction.restore : RecurringAction.archive,
      ),
    );
  }

  Future<void> _duplicate(Recurring r) async {
    setSaving(true);
    try {
      final d = await _repo.duplicate(r.id);
      if (!mounted) return;
      _changed = true;
      commitSaved(working);
      context.pushReplacement('/recurring/${d.recurring.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
    }
  }

  Future<void> _delete(Recurring r) async {
    final l = AppLocalizations.of(context)!;
    bool deleteTxs = false;
    final RecurringDeletePreview? preview;
    try {
      preview = (await _repo.get(r.id, deletePreview: true)).deletePreview;
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
      }
      return;
    }
    if (!mounted) return;
    final linked = preview?.linkedTransactions ?? 0;
    final numbers = preview == null
        ? l.recurringDeleteBody
        : l.fpM5bRecurringDeleteNumbers(
            preview.items,
            preview.pendingDrafts,
            preview.linkedTransactions,
          );
    if (linked > 0) {
      final choice = await showLinkedPrompt(
        context,
        title: l.recurringDeleteTitle,
        message: numbers,
        cancelLabel: l.linkedCancel,
        thisSideLabel: l.recurringDeleteKeepTxs,
        bothSidesLabel: l.recurringDeleteWithTxs(linked),
        destructive: true,
      );
      if (!mounted || choice == null) return;
      deleteTxs = choice == LinkedChoice.bothSides;
    } else {
      final ok = await showConfirmDialog(
        context,
        title: l.recurringDeleteTitle,
        message: numbers,
        confirmLabel: l.commonDelete,
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    setSaving(true);
    final accounts = context.read<AccountsCubit>();
    try {
      final balances = await _repo.delete(r.id, deleteLinkedTxs: deleteTxs);
      accounts.patchBalances(balances);
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    _changed = true;
    // Pop without the discard prompt — it is gone.
    commitSaved(working);
    leavePage();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!widget.isCreate && _detail == null) {
      return Scaffold(
        appBar: AppTopBar(title: l.recurringTitle, showBack: true),
        extendBodyBehindAppBar: true,
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
    final r = _recurring;
    return editScope(
      Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppTopBar(
          // Titles never change with the mode.
          title: r == null ? l.recurringNewTitle : r.name,
          showBack: true,
          editing: isEditing,
          onBack: handleBack,
        ),
        body: SavingOverlay(
          saving: _busy,
          child: Form(
            key: _formKey,
            child: Builder(
              builder: (context) {
                final barInset = MediaQuery.paddingOf(context).top;
                final bottom =
                    AppSpacing.huge + MediaQuery.paddingOf(context).bottom;
                final d = _detail;
                return (d == null || isEditing)
                    ? _editBody(context, l, r, barInset, bottom)
                    : _viewBody(context, l, d);
              },
            ),
          ),
        ),
        bottomNavigationBar: isEditing ? editActionBar(onSave: _save) : null,
      ),
    );
  }

  HeroStyle _style(Recurring r) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return HeroStyle.tinted(
      color: (r.iconCode ?? r.category?.iconCode).tintFor(palette),
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
        : AppMessage(tone: Tone.danger, message: _refreshError!.message);
    return TabbedDetailBody<_Tab>(
      hero: _viewHero(l, r),
      belowHero: [
        ?banner,
        ?_notice(l, r),
        ?_viewTags(r),
        _infoBox(l, r, editing: false),
        NoteSection(
          label: l.commonNote,
          editing: false,
          text: r.note,
          hint: l.commonLongPressToEdit,
          onLongPress: () => enterEdit(focus: _noteFocus),
        ),
      ],
      tabs: [
        AppTab(
          value: _Tab.past,
          label: l.fpRecurringTabPast,
          badgeCount: r.counts.notCreated,
        ),
        AppTab(value: _Tab.upcoming, label: l.fpRecurringTabUpcoming),
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

  AppCompactHeroCard _compactBar(Recurring r) {
    final amount = r.amount;
    return AppCompactHeroCard(
      style: _style(r),
      leading: IconDisplay(
        type: IconType.category,
        size: 28,
        iconCode: r.iconCode ?? r.category?.iconCode,
      ),
      title: AppText(r.name, role: AppTextRole.title),
      trailing: amount == null || amount <= 0
          ? null
          : MoneyText(
              signedOf(r.type, amount),
              tone: toneOf(r.type),
              symbol: context.readUserCurrencySymbol,
              style: AppTypography.of(context, AppTextRole.money),
            ),
    );
  }

  Widget? _notice(AppLocalizations l, Recurring r) {
    if (r.endingSoon && r.actions.extend) {
      return AppMessage(
        message: l.recurringEndingSoon(r.counts.upcoming),
        tone: Tone.warning,
        actions: [
          AppMessageAction(
            label: l.recurringExtend,
            onPressed: () => _action(RecurringAction.extend),
          ),
        ],
      );
    }
    if (r.status == RecurringStatus.paused) {
      return AppMessage(message: l.recurringPausedNotice);
    }
    return null;
  }

  Widget _statusChip(AppLocalizations l, Recurring r, {VoidCallback? onTap}) {
    final (label, kind) = switch (r.status) {
      RecurringStatus.active => (l.recurringStatusActive, StatusKind.active),
      RecurringStatus.paused => (l.recurringStatusPaused, StatusKind.paused),
      RecurringStatus.archived => (
        l.recurringStatusArchived,
        StatusKind.archived,
      ),
    };
    return StatusChip(label: label, kind: kind, onTap: onTap);
  }

  Widget _viewHero(AppLocalizations l, Recurring r) {
    final symbol = context.readUserCurrencySymbol;
    final amount = r.amount;
    final known = amount != null && amount > 0;
    final monthly = r.monthlyAmount;
    final next = r.nextDate;
    final installment = r.kind == RecurringKind.installment;
    SummaryTileView tile(String label, String value, [SummaryTileTone? tone]) =>
        SummaryTileView(
          tile: SummaryTile(
            label: label,
            value: value,
            tone: tone ?? SummaryTileTone.neutral,
          ),
        );
    return AppHeroCard(
      style: _style(r),
      header: HeroHeader(
        leading: [
          if (r.actions.pause || r.actions.resume)
            OptionMenuAnchor<RecurringAction>(
              options: [
                if (r.actions.pause)
                  SheetOption(
                    value: RecurringAction.pause,
                    label: l.recurringPause,
                    leading: const AppIcon(AppIcons.pause),
                  ),
                if (r.actions.resume)
                  SheetOption(
                    value: RecurringAction.resume,
                    label: l.recurringResume,
                    leading: const AppIcon(AppIcons.resume),
                  ),
              ],
              onSelected: _action,
              builder: (context, toggle) => _statusChip(l, r, onTap: toggle),
            )
          else
            _statusChip(l, r),
          AppChip(
            label: recurringKindLabel(l, r.kind),
            selected: true,
            tone: AppChipTone.neutral,
          ),
        ],
        onEdit: enterEdit,
      ),
      content: [
        HeroIdentity(
          icon: EditableCircle(
            size: 40,
            onLongPress: () {
              enterEdit();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _pickIcon();
              });
            },
            child: IconDisplay(
              type: IconType.category,
              size: 40,
              iconCode: r.iconCode ?? r.category?.iconCode,
            ),
          ),
          description: HeroDescription(
            controller: _ctrl[_Field.description]!,
            editing: false,
            focusNode: _descriptionFocus,
            hint: l.commonDescription,
            maxLength: TextLimits.description,
            onEnterEdit: () => enterEdit(focus: _descriptionFocus),
          ),
        ),
        HeroNumber(
          label: l.fpM5bRecurringPerMonth,
          value: monthly != null && monthly > 0
              ? MoneyText(
                  signedOf(r.type, monthly),
                  tone: toneOf(r.type),
                  symbol: symbol,
                )
              : Text(l.fpRecurringAwaitingValue),
        ),
        !known && next != null
            ? HeroAlert(
                text: l.fpRecurringAlertAwaiting(
                  dueLabel(l, date: next, daysUntil: r.daysUntil),
                ),
              )
            : null,
      ],
      footer: [
        for (final List<Widget> tiles in [
          [
            if (installment)
              tile(
                l.fpRecurringTileInstallment,
                r.progressTotal == null
                    ? '${r.progressDone}'
                    : '${r.progressDone}/${r.progressTotal}',
              )
            else
              tile(
                l.fpRecurringTileYearly,
                moneyString(context, r.yearlyCost, symbol: symbol),
              ),
            tile(l.fpRecurringTileSaved, l.fpRecurringCountUnit(r.savedCount)),
            tile(
              l.fpRecurringTilePending,
              l.fpRecurringCountUnit(r.pendingCount),
              r.pendingCount > 0 ? SummaryTileTone.amber : null,
            ),
          ],
        ])
          if (tiles.isNotEmpty) HeroTiles(children: tiles),
      ],
    );
  }

  Widget? _viewTags(Recurring r) {
    if (r.tags.isEmpty) return null;
    return TagRow(tags: [for (final t in r.tags) _tagChip(t.name, t.iconCode)]);
  }

  Widget _tagChip(String name, IconCode? iconCode) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return AppChip(
      label: name,
      icon: IconRegistry.get(iconCode?.icon, fallback: AppIcons.tag),
      color: EventTagRef(name, iconCode: iconCode).colorOf(palette),
      selected: true,
      size: ChipSize.mini,
    );
  }

  String _date(DateTime d) => DateFormatter.medium(
    d,
    locale: Localizations.localeOf(context).toLanguageTag(),
  );

  String _endText(AppLocalizations l, RecurrenceEnd end) => switch (end.kind) {
    RecurrenceEndKind.never => l.recurringEndNever,
    RecurrenceEndKind.onDate => l.recurEndUntil(_date(end.date!)),
    RecurrenceEndKind.afterCount => l.recurEndCount(end.count ?? 0),
  };

  Widget _infoBox(AppLocalizations l, Recurring? r, {required bool editing}) {
    final accounts = context.watch<AccountsCubit>();
    final cats = context.watch<CategoriesCubit>();
    final w = working;
    final rule = w.rule;
    final account = accounts.byId(w.accountId ?? '');
    final toAccount = accounts.byId(w.toAccountId ?? '');
    final category = cats.byId(w.categoryId ?? '');
    final transfer = w.isTransfer;
    final next = r?.nextDate;
    final installment = w.kind == RecurringKind.installment;
    final walletLabel = transfer
        ? l.fpRecurringFieldFromWallet
        : (w.type == TransactionType.income
              ? l.fpRecurringFieldIntoWallet
              : l.fpRecurringFieldPayFrom);
    Widget? walletChip(String? name, IconCode? icon) => name == null
        ? null
        : walletValueChip(context, name: name, iconCode: icon);
    final repeatValue = [
      recurrenceLabel(l, rule),
      if (!editing && next != null)
        l.fpRecurringNextInline(
          _date(next),
          dueLabel(l, date: next, daysUntil: r?.daysUntil),
        ),
    ].join(' | ');
    return InfoBox(
      rows: [
        InfoRow(
          label: l.recurringFieldRepeat,
          value: repeatValue,
          showChevron: editing,
          onTap: editing ? _pickRepeat : null,
        ),
        if (!transfer && (editing || category != null))
          InfoRow(
            label: l.recurringFieldCategory,
            valueChip: category == null
                ? null
                : categoryChipPath(
                    context,
                    category,
                    all: cats.state.categories,
                  ),
            value: category == null ? l.quickEventNone : null,
            showChevron: editing,
            onTap: editing ? _pickCategory : null,
          ),
        InfoRow(
          label: walletLabel,
          valueChip: walletChip(account?.name, account?.iconCode),
          value: account == null ? l.quickEventNone : null,
          showChevron: editing,
          onTap: editing ? () => _pickWallet(to: false) : null,
        ),
        if (transfer)
          InfoRow(
            label: l.recurringFieldToWallet,
            valueChip: walletChip(toAccount?.name, toAccount?.iconCode),
            value: toAccount == null ? l.quickEventNone : null,
            showChevron: editing,
            onTap: editing ? () => _pickWallet(to: true) : null,
          ),
        if (editing && w.kind == RecurringKind.reminder)
          InfoRow(
            label: l.fpRecurringFieldMode,
            value: transfer
                ? l.transactionTypeTransfer
                : l.transactionTypeExpense,
            showChevron: true,
            onTap: _pickMode,
          ),
        if (editing) ...[
          InfoRow(
            label: l.recurringFieldStart,
            value: _date(rule.start),
            showChevron: true,
            onTap: _pickStart,
          ),
          if (rule.freq != RecurrenceFreq.dates)
            installment
                ? InfoRow(
                    label: l.fpRecurringFieldCount,
                    value: l.fpRecurringCountValue(rule.end.count ?? 0),
                    showChevron: true,
                    onTap: _pickCount,
                  )
                : InfoRow(
                    label: l.recurringFieldEnd,
                    value: _endText(l, rule.end),
                    showChevron: true,
                    onTap: _pickEnd,
                  ),
          if (w.kind == RecurringKind.subscription)
            InfoRow(
              label: l.fpRecurringTrialUntil,
              value: w.trialUntil == null
                  ? l.quickEventNone
                  : _date(w.trialUntil!),
              showChevron: true,
              onTap: _pickTrial,
            ),
        ] else ...[
          if (r != null && r.hasAmount)
            InfoRow(
              label: l.fpM5bRecurringAmountPerTime,
              value: moneyString(
                context,
                r.amount!,
                symbol: context.readUserCurrencySymbol,
              ),
            ),
          if (rule.freq != RecurrenceFreq.dates)
            InfoRow(
              label: l.fpRecurringInfoSpan,
              value: '${_date(rule.start)} | ${_endText(l, rule.end)}',
            ),
          if (w.trialUntil != null)
            InfoRow(
              label: l.fpRecurringTrialUntil,
              value: _date(w.trialUntil!),
            ),
        ],
      ],
    );
  }

  Widget _pastTab(AppLocalizations l, Recurring r) {
    final items = _produced.items;
    return ListPageBody(
      loading: false,
      error: null,
      isEmpty: items.isEmpty,
      onRetry: _load,
      rowDividers: true,
      topInset: AppSpacing.sm,
      hasMore: _produced.hasMore,
      loadingMore: _producedMore,
      onLoadMore: _loadMoreProduced,
      loadMoreError: _producedMoreError,
      onRetryMore: _loadMoreProduced,
      header: [
        if (_selecting && items.isNotEmpty)
          SelectionToolbar(
            selected: _selected.length,
            total: items.length,
            selectAllTooltip: l.recurringSelectAll,
            onSelectAll: () => setState(
              () => _selected.length == items.length
                  ? _selected.clear()
                  : _selected.addAll(items.map((i) => i.id)),
            ),
            actions: [
              SelectionAction(
                label: l.recurringItemCreate,
                icon: AppIcons.add,
                onTap: () => _batch(ItemBatchAction.create),
              ),
              SelectionAction(
                label: l.recurringItemArchive,
                icon: AppIcons.archive,
                onTap: () => _batch(ItemBatchAction.archive),
              ),
            ],
            trailing: [
              AppChip(
                label: l.fpRecurringSelectDone,
                onTap: () => setState(() {
                  _selecting = false;
                  _selected.clear();
                }),
              ),
            ],
            deleteTooltip: l.commonDelete,
            onDelete: () => _batch(ItemBatchAction.delete),
          ),
      ],
      empty: EmptyView.compact(message: l.recurringItemsEmpty),
      children: [
        for (final group in groupItemsByDate(items)) ...[
          DateGroupHeader(label: itemDateLabel(context, group.date)),
          for (final item in group.items)
            RecurringItemActions(
              item: item,
              onChanged: _applyItems,
              onBusy: (b) => setState(() => _busy = b),
              builder: (context, open) => RecurringItemRow(
                item: item,
                select: _selecting
                    ? SelectCheck(
                        value: _selected.contains(item.id),
                        onTap: () => _toggle(item),
                      )
                    : null,
                onTap: _selecting ? () => _toggle(item) : open,
                onLongPress: _selecting
                    ? null
                    : () => setState(() {
                        _selecting = true;
                        _selected.add(item.id);
                      }),
              ),
            ),
        ],
        AddTile(
          label: l.recurringAddItem,
          inList: true,
          onTap: () => addRecurringItem(context, r, onChanged: _applyItems),
        ),
      ],
    );
  }

  void _toggle(RecurringItem item) => setState(
    () => _selected.contains(item.id)
        ? _selected.remove(item.id)
        : _selected.add(item.id),
  );

  Widget _upcomingTab(AppLocalizations l, Recurring r) {
    final page = _upcoming;
    final items = page.items;
    final next = items.isEmpty ? null : items.first;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String day(DateTime d) => DateFormat.MMMd(locale).format(d);
    final symbol = context.readUserCurrencySymbol;
    final rest = <RecurringItem>[
      ...items.skip(1),
      for (final i in _produced.items)
        if (i.state == OccurrenceState.archived && i.date.isAfter(today())) i,
    ]..sort((a, b) => a.date.compareTo(b.date));
    OccurrenceDate chip(RecurringItem i) {
      final skipped = i.state == OccurrenceState.archived;
      final known = i.amount != null && i.amount! > 0;
      return OccurrenceDate(
        label: skipped
            ? l.fpRecurringChipSkipped(day(i.date))
            : (i.edited && known
                  ? l.fpRecurringChipEdited(
                      day(i.date),
                      moneyString(context, i.amount!, symbol: symbol),
                    )
                  : day(i.date)),
        kind: skipped
            ? OccurrenceDateKind.skipped
            : (i.edited
                  ? OccurrenceDateKind.edited
                  : OccurrenceDateKind.normal),
        onTap: () => _occurrenceMenu(i),
      );
    }

    return ListPageBody(
      loading: false,
      error: null,
      isEmpty: items.isEmpty,
      onRetry: _load,
      rowDividers: false,
      topInset: AppSpacing.sm,
      empty: EmptyView(
        icon: AppIcons.scheduled,
        title: l.recurringUpcomingEmpty,
        message: l.recurringUpcomingEmptyMessage,
      ),
      children: [
        if (next != null) _nextCard(l, next, symbol),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          OccurrenceDates(
            title: l.fpRecurringThenTitle(r.counts.upcoming),
            dates: [for (final i in rest) chip(i)],
            moreLabel: page.hasMore ? l.fpRecurringMoreDates : null,
            onMore: _upcomingMore ? null : _loadMoreUpcoming,
          ),
        ],
        if (_upcomingMoreError != null)
          LoadMoreErrorRow(onRetry: _loadMoreUpcoming),
      ],
    );
  }

  Widget _nextCard(AppLocalizations l, RecurringItem i, String symbol) {
    final unknown = i.amount == null || i.amount! <= 0;
    return NextOccurrenceCard(
      title: l.fpRecurringNextTitle(
        dueLabel(l, date: i.date, daysUntil: i.daysUntil),
      ),
      caption: l.fpRecurringNextCaption,
      chips: [
        if (i.edited)
          AppChip(
            label: l.fpRecurringEditedChip,
            size: ChipSize.mini,
            tone: AppChipTone.warning,
            selected: true,
          ),
      ],
      amount: unknown
          ? Text(l.fpRecurringAwaitingValue)
          : MoneyText(
              signedOf(i.type, i.amount!),
              tone: toneOf(i.type),
              symbol: symbol,
            ),
      actions: [
        NextOccurrenceAction(
          label: unknown
              ? l.fpRecurringActEnterAmount
              : l.fpRecurringActEditAmount,
          primary: unknown,
          onTap: () => _editOccurrence(i, focus: OccurrenceFocus.amount),
        ),
        NextOccurrenceAction(
          label: l.fpRecurringActMove,
          onTap: () => _editOccurrence(i, focus: OccurrenceFocus.date),
        ),
        NextOccurrenceAction(
          label: l.fpRecurringActSkip,
          onTap: () => _skip(i),
        ),
      ],
    );
  }

  Widget _editBody(
    BuildContext context,
    AppLocalizations l,
    Recurring? r,
    double barInset,
    double bottom,
  ) {
    final w = working;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = w.iconCode.tintFor(palette);
    final tags = context.watch<TagsCubit>();
    return DetailLayout(
      topInset: barInset + AppSpacing.lg,
      bottomInset: bottom,
      onRefresh: widget.isCreate ? null : _load,
      hero: AppHeroCard(
        style: HeroStyle.tinted(color: accent, glyph: AppIcons.scheduled),
        mode: HeroCardMode.edit,
        header: HeroHeader(
          leading: [
            for (final k in RecurringKind.values)
              AppChip(
                label: recurringKindLabel(l, k),
                selected: w.kind == k,
                onTap: () => _change(w.withKind(k)),
              ),
          ],
        ),
        content: [
          HeroIdentity(
            icon: EditableCircle(
              size: 44,
              onTap: _pickIcon,
              child: IconDisplay(
                type: IconType.category,
                size: 44,
                iconCode: w.iconCode,
              ),
            ),
            name: HeroNameInput(
              editing: true,
              controller: _ctrl[_Field.name]!,
              focusNode: _nameFocus,
              hint: l.commonName,
              maxLength: TextLimits.name,
              onChanged: (v) => _onText(_Field.name, v),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.recurringNameRequired
                  : null,
            ),
            description: HeroDescription(
              controller: _ctrl[_Field.description]!,
              editing: true,
              hint: l.commonDescription,
              maxLength: TextLimits.description,
              focusNode: _descriptionFocus,
              onChanged: (v) => _onText(_Field.description, v),
            ),
          ),
          HeroAmountField(
            controller: _ctrl[_Field.amount]!,
            label: w.amountOptional
                ? l.fpRecurringAmountOptional
                : l.fpRecurringAmountLabel,
            accent: accent,
            symbol: context.readUserCurrencySymbol,
            onChanged: (v) => _onText(_Field.amount, v),
            validator: (v) {
              final n = AmountInput.parse(v);
              if (w.amountOptional && (v ?? '').trim().isEmpty) return null;
              return (n == null || n <= 0) ? l.recurringAmountInvalid : null;
            },
          ),
        ],
      ),
      tags: TagRow(
        tags: [
          for (final id in w.tagIds)
            if (tags.byId(id) case final t?) _tagChip(t.name, t.iconCode),
        ],
        onAdd: _pickTags,
        addLabel: l.tagsAddNew,
      ),
      info: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (w.kind == RecurringKind.reminder) ...[
            AppMessage(message: l.fpRecurringReminderHint),
            const SizedBox(height: AppSpacing.md),
          ],
          _infoBox(l, r, editing: true),
          if (_walletMissing && !w.walletOk)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: AppText(
                l.recurringWalletRequired,
                role: AppTextRole.caption,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
      note: NoteSection(
        label: l.commonNote,
        editing: true,
        controller: _ctrl[_Field.note]!,
        maxLength: TextLimits.note,
        editField: DetailStacked(
          label: l.commonNote,
          child: AppInput.inline(
            editing: true,
            controller: _ctrl[_Field.note]!,
            focusNode: _noteFocus,
            maxLines: 3,
            maxLength: TextLimits.note,
            hint: l.recurringNoteHint,
            onChanged: (v) => _onText(_Field.note, v),
          ),
        ),
      ),
      endZone: r == null ? null : _endZone(l, r),
      metaLines: r == null
          ? const []
          : detailMetaLines(
              context,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            ),
    );
  }

  Widget _endZone(AppLocalizations l, Recurring r) {
    final archived = r.status == RecurringStatus.archived;
    final canArchive = archived ? r.actions.restore : r.actions.archive;
    return EndZone(
      actions: [
        EndZoneAction(
          kind: EndZoneKind.close,
          icon: AppIcons.copy,
          label: l.fpRecurringDuplicate,
          consequence: l.fpRecurringDuplicateConsequence,
          onTap: isSaving ? null : () => _duplicate(r),
        ),
        if (canArchive)
          EndZoneAction(
            kind: EndZoneKind.archive,
            label: archived ? l.recurringRestore : l.recurringArchive,
            consequence: archived
                ? l.fpRecurringRestoreConsequence
                : l.fpRecurringArchiveConsequence,
            onTap: isSaving ? null : () => _archive(r, restore: archived),
          ),
        EndZoneAction(
          kind: EndZoneKind.delete,
          label: l.recurringDelete,
          consequence: l.fpRecurringDeleteConsequence,
          onTap: isSaving ? null : () => _delete(r),
        ),
      ],
    );
  }
}

enum _RepeatMore { custom, dates }
