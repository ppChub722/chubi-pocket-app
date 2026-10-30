import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/data/write_effects.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_picker.dart';
import '../../../personal_debts/domain/debt_direction.dart';
import '../../../personal_debts/domain/debt_ledger.dart' show debtPersonKey;
import '../../../personal_debts/presentation/debt_wiring.dart'
    show debtPersonLevel;
import '../../../saving_goals/data/saving_goals_repository.dart';
import '../../../saving_goals/domain/saving_goal.dart';
import '../../../saving_goals/domain/saving_goals_overview.dart';
import '../../../saving_goals/presentation/widgets/saving_goal_picker.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_picker.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/domain/refs.dart' show EmbeddedPerson;
import '../../../transactions/presentation/widgets/category_pick_card.dart';
import '../../../transactions/presentation/widgets/debt_entry_form.dart'
    show DebtPick, showDebtPersonPicker;
import '../../data/recurring_repository.dart';
import '../../domain/recurrence_rule.dart';
import '../../domain/recurring.dart';
import '../../domain/recurring_item.dart';
import '../due_boxes.dart';
import '../item_write_apply.dart';
import '../occurrence_actions.dart';
import '../recurring_draft.dart';
import '../recurring_rows.dart';

enum _Tab { past, upcoming }

enum _Field { name, description, amount, note }

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

  /// Amounts changed in the tabs' waiting rows, by occurrence.
  final _rowAmounts = <String, double?>{};
  bool _busy = false;
  bool _changed = false;
  bool _walletMissing = false;
  bool _goalMissing = false;
  bool _personMissing = false;

  /// ออมเงิน: the goals for the goal tile (loaded once a saving rule shows).
  SavingGoalsOverview? _goals;
  bool _goalsAsked = false;

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
    initDraft(
      RecurringDraft.blank(preset: widget.preset),
      editing: widget.isCreate,
    );
    onDraftRestored();
    _offEffects = WriteEffectsBus.instance.listen(_onEffects);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
      context.read<TagsCubit>().loadIfNeeded();
      if (!widget.isCreate) _load(first: true);
    });
  }

  void Function()? _offEffects;

  /// B2: this rule's slots any write changed (a tx deleted or unlinked
  /// elsewhere too) patch the lists in place; no re-fetch.
  void _onEffects(WriteEffects e) {
    final r = ItemWriteResult.fromEffects(e);
    final id = widget.id;
    if (r == null || id == null || !mounted || _detail == null) return;
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
    for (final c in _ctrl.values) {
      c.dispose();
    }
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _noteFocus.dispose();
    _sheetTick.dispose();
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

  /// A no-end rule's next year (ดูปีถัดไป), else the next page.
  Future<void> _loadMoreUpcoming() async {
    final current = _upcoming;
    final from = current.nextFrom;
    if (current.windowed ? from == null : !current.hasMore) return;
    await _fetchUpcoming(
      () => _repo.items(
        widget.id!,
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
      if (mounted) showErrorSnackBar(context, e);
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
    final date = r.date == i.date ? null : r.date;
    await _occurrenceCall(
      () => _repo.updateOccurrence(i.ruleId!, i.slot!, {
        'date': ?(date == null ? null : ymd(date)),
        'amount': ?r.amount,
      }),
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
    await _occurrenceCall(() => _repo.skipOccurrence(i.ruleId!, i.slot!));
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
      if (mounted) showErrorSnackBar(context, e);
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
    final r = await AccountPicker.one(
      context,
      selectedId: to ? working.toAccountId : working.accountId,
      excludeIds: {?(to ? working.accountId : working.toAccountId)},
      title: to ? l.recurringFieldToWallet : null,
      // หนี้: no wallet = ledger-only entries.
      allowNone: working.isDebt,
    );
    if (!mounted) return;
    if (r is AccountPickedNone && working.isDebt) {
      _change(working.copyWith(clearAccount: true));
      return;
    }
    if (r is! AccountPicked) return;
    setState(() => _walletMissing = false);
    _change(
      to
          ? working.copyWith(toAccountId: r.account.id)
          : working.copyWith(accountId: r.account.id),
    );
  }

  void _loadGoals() {
    if (_goalsAsked) return;
    _goalsAsked = true;
    final repo = context.read<SavingGoalsRepository>();
    unawaited(
      repo.list().then(
        (o) {
          if (mounted) setState(() => _goals = o);
        },
        onError: (Object _) {
          if (mounted) setState(() => _goals = const SavingGoalsOverview());
        },
      ),
    );
  }

  Future<void> _pickGoal() async {
    final w = working;
    final r = await SavingGoalPicker.one(
      context,
      selectedId: w.goalId,
      spareSelected: w.goalPicked && w.goalId == null,
      overview: _goals,
    );
    if (!mounted || r == null) return;
    setState(() => _goalMissing = false);
    _change(working.withGoal(r.goalId));
  }

  Future<void> _pickCategory() async {
    final l = AppLocalizations.of(context)!;
    final r = await CategoryPicker.one(
      context,
      types: {
        working.type == TransactionType.income
            ? CategoryType.income
            : CategoryType.expense,
      },
      selectedId: working.categoryId,
      allowNone: true,
      title: l.recurringFieldCategory,
      allowCreate: true,
    );
    if (!mounted || r == null) return;
    _change(switch (r) {
      CategoryPicked(:final category) => working.copyWith(
        categoryId: category.id,
      ),
      CategoryPickedNone() => working.copyWith(clearCategory: true),
    });
  }

  Future<void> _pickTags() async {
    final l = AppLocalizations.of(context)!;
    final picked = await TagPicker.many(
      context,
      selected: working.tagIds,
      title: l.transactionFormTagsLabel,
    );
    if (picked == null || !mounted) return;
    _change(working.copyWith(tagIds: picked.ids));
  }

  void _setMode(TransactionType picked) {
    if (picked == working.type) return;
    _change(
      working.copyWith(
        type: picked,
        clearCategory: true,
        accountId: working.accountId,
      ),
    );
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
    final picked = await AppDatePicker.show(
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
    final picked = await AppRecurrenceSheet.show(
      context,
      initial: working.rule,
    );
    if (!mounted || picked == null) return;
    _change(working.copyWith(rule: picked));
  }

  Future<void> _pickTrial() async {
    final l = AppLocalizations.of(context)!;
    final now = today();
    final current = working.trialUntil;
    final picked = await AppDatePicker.show(
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
    final goalOk = working.goalOk;
    final personOk = working.personOk;
    if (!walletOk || !goalOk || !personOk) {
      setState(() {
        _walletMissing = !walletOk;
        _goalMissing = !goalOk;
        _personMissing = !personOk;
      });
    }
    if (!formOk || !walletOk || !goalOk || !personOk) return;
    if (!working.countOk) {
      showAppSnackBarOn(
        pageMessenger!,
        l.fpRecurringCountRequired,
        tone: Tone.danger,
      );
      return;
    }

    // A rule edit never touches filled slots (R6): their tx keep their own
    // values.
    final r = _recurring;
    FocusScope.of(context).unfocus();
    setSaving(true);
    final accounts = context.read<AccountsCubit>();
    try {
      final write = working.toWrite();
      final d = r == null
          ? await _repo.create(write)
          : await _repo.update(r.id, write);
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
      showErrorSnackBarOn(pageMessenger!, e);
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
      showErrorSnackBarOn(pageMessenger!, e);
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
      showErrorSnackBarOn(pageMessenger!, e);
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
        showErrorSnackBarOn(pageMessenger!, e);
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
      showErrorSnackBarOn(pageMessenger!, e);
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
        body: BusyScope(
          busy: _busy,
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
        : AppMessage(tone: Tone.danger, message: errorText(l, _refreshError!));
    return TabbedDetailBody<_Tab>(
      hero: _viewHero(l, d),
      belowHero: [
        ?banner,
        ?_notice(l, r),
        ?_focusCard(l, r),
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
          icon: AppIcons.history,
        ),
        AppTab(
          value: _Tab.upcoming,
          label: l.fpRecurringTabUpcoming,
          icon: AppIcons.date,
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

  AppCompactHeroCard _compactBar(Recurring r) {
    final amount = r.amount;
    return AppCompactHeroCard(
      style: _style(r),
      leading: IconDisplay(
        type: IconType.category,
        size: 28,
        iconCode: r.shownIconCode,
      ),
      title: AppText(r.name, role: AppTextRole.title),
      trailing: amount == null || amount <= 0
          ? null
          : MoneyText(
              signedOf(r.type, amount, saving: r.isSaving),
              tone: toneOf(r.type, saving: r.isSaving),
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
      // R7: why it's paused; resume starts at the current period (R8).
      return switch (r.pauseReason) {
        RecurringPauseReason.overdueLimit => AppMessage(
          message: l.recurringPausedOverdue,
          tone: Tone.warning,
        ),
        RecurringPauseReason.goalInactive => AppMessage(
          message: l.recurringPausedGoal,
        ),
        // K13: a new debt with the person starts it again by itself.
        RecurringPauseReason.noBalance => AppMessage(
          message: l.recurringPausedNoBalance,
        ),
        _ => AppMessage(message: l.recurringPausedNotice),
      };
    }
    return null;
  }

  /// Under the hero, one card. Something to do (a due occurrence, or this
  /// month's coming one with no amount yet): ต้องจัดการ, the oldest one big
  /// with its buttons, the all-at-once row, ดูทั้ง n งวด, then ครั้งถัดไป as a
  /// line. Nothing to do: the next occurrence with แก้ยอด / เลื่อนวัน / ข้าม.
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
    final next = _nextItem;
    final symbol = context.readUserCurrencySymbol;
    final warning = Theme.of(context).extension<AppColors>()!.warning;
    bool unknown(RecurringItem i) => i.amount == null || i.amount! <= 0;
    Widget money(RecurringItem i) => MoneyText(
      signedOf(i.type, i.amount!, saving: i.isSaving),
      tone: toneOf(i.type, saving: i.isSaving),
      symbol: symbol,
    );
    String nextLabel(RecurringItem i) {
      final when = dueLabel(l, date: i.date, daysUntil: i.daysUntil);
      final seq = i.seq;
      final total = i.total;
      return r.kind == RecurringKind.installment && seq != null && total != null
          ? l.fpRecurringNextInstallment(seq, total, when)
          : l.fpRecurringNextOnce(when);
    }

    if (todo.isEmpty) {
      if (next == null) return null;
      final u = unknown(next);
      return OccurrenceFocusCard(
        key: const ValueKey('heroNext'),
        date: next.date,
        label: nextLabel(next),
        value: u ? Text(l.fpRecurringAwaitingValue) : money(next),
        valueColor: u ? warning : null,
        primaryFirst: u,
        actions: [
          OccurrenceAction(
            label: u ? l.fpRecurringActEnterAmount : l.fpRecurringActEditAmount,
            onTap: () =>
                unawaited(_editOccurrence(next, focus: OccurrenceFocus.amount)),
          ),
          OccurrenceAction(
            label: l.fpRecurringActMove,
            onTap: () =>
                unawaited(_editOccurrence(next, focus: OccurrenceFocus.date)),
          ),
          OccurrenceAction(
            label: l.fpRecurringActSkip,
            onTap: () => unawaited(_skip(next)),
          ),
        ],
        onTap: () => _openOccurrence(next),
      );
    }
    final total = r.counts.notCreated > due.length
        ? r.counts.notCreated + todo.length - due.length
        : todo.length;
    final nextLine = next != null && !todo.any((i) => i.id == next.id)
        ? OccurrenceFocusNext(
            key: const ValueKey('focusNext'),
            label: nextLabel(next),
            amount: unknown(next) ? null : money(next),
            onTap: () => _openOccurrence(next),
          )
        : null;
    if (todo.length > 1) return _dueList(l, todo, total, nextLine);
    final first = todo.first;
    final u = unknown(first);
    return OccurrenceFocusCard(
      key: const ValueKey('detailDue'),
      warning: true,
      title: l.occurrenceDueTitle,
      trailing: total > 1 ? l.fpRecurringCountUnit(total) : null,
      date: first.date,
      label: dueLabel(l, date: first.date, daysUntil: first.daysUntil),
      tag: first.state == OccurrenceState.upcoming
          ? null
          : AppChip(
              label: waitingLabel(l, first),
              tone: AppChipTone.warning,
              selected: true,
              size: ChipSize.mini,
            ),
      value: u ? Text(l.fpRecurringAwaitingValue) : money(first),
      valueColor: u ? warning : null,
      primaryFirst: true,
      actions: occurrenceFocusActions(context, first, onChanged: _applyItems),
      onTap: () => _openOccurrence(first),
      footer: [
        if (total > 1)
          DueMoreRow(
            label: l.occurrenceDueMore(total),
            onTap: () => _onTab(_Tab.past),
          ),
        ?nextLine,
      ],
    );
  }

  /// ต้องจัดการ with 2 or more: the two boxes (รอใส่ยอด / รอยืนยัน) as on
  /// the list page, the date on the left (it is one rule), up to 5 per box,
  /// ดูทั้ง n งวด to the ประวัติ tab, then ครั้งถัดไป.
  Widget _dueList(
    AppLocalizations l,
    List<RecurringItem> todo,
    int total,
    Widget? nextLine,
  ) {
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
      footer: nextLine,
    );
  }

  /// The occurrence's own sheet (แก้เฉพาะงวดนี้).
  void _openOccurrence(RecurringItem i) =>
      openOccurrenceSheet(context, i, onChanged: _applyItems);

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

  String get _locale => Localizations.localeOf(context).toLanguageTag();

  /// "ก.ย. 27": the month with a short year.
  String _monthYear(DateTime d) =>
      '${DateFormat.MMM(_locale).format(d)} ${DateFormat('yy').format(d)}';

  /// Who it is and its round, the chain (or the amounts line for a bill that
  /// changes), three numbers in one box, then the status and what it books
  /// into as chips. The next occurrence sits under the card (_focusCard).
  Widget _viewHero(AppLocalizations l, RecurringDetail d) {
    final r = d.recurring;
    final rule = r.rule;
    final description = (r.description ?? '').trim();
    final stats = _stats(l, r, d.stats);
    return AppHeroCard(
      style: _style(r),
      content: [
        HeroIdentity(
          icon: EditableCircle(
            size: HeroIdentity.iconSize,
            onLongPress: () {
              enterEdit();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _pickIcon();
              });
            },
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
                  controller: _ctrl[_Field.description]!,
                  editing: false,
                  focusNode: _descriptionFocus,
                  hint: l.commonDescription,
                  maxLength: TextLimits.description,
                  onEnterEdit: () => enterEdit(focus: _descriptionFocus),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeroInfoBox(
                key: const ValueKey('heroRound'),
                icon: AppIcons.recurring,
                title: recurrenceLabel(l, rule),
                subtitle: rule.end.kind == RecurrenceEndKind.never
                    ? l.fpRecurringSince(
                        DateFormat.yMMM(_locale).format(rule.start),
                      )
                    : _endText(l, rule.end),
              ),
              const SizedBox(width: AppSpacing.sm),
              CardActionButton(
                key: const ValueKey('heroEdit'),
                icon: AppIcons.edit,
                tooltip: UiConfig.stringsOf(context).edit,
                onTap: enterEdit,
              ),
            ],
          ),
        ),
        ?_track(l, r, d.stats),
        if (stats.isNotEmpty) HeroTiles(joined: true, children: stats),
        ?_pickCards(l),
        HeroChipRow(chips: _heroChips(l, r)),
      ],
    );
  }

  /// The next occurrence still to come.
  RecurringItem? get _nextItem {
    for (final i in _upcoming.items) {
      if (i.state == OccurrenceState.upcoming) return i;
    }
    return null;
  }

  /// A bill whose amount changes draws its recorded amounts as a line;
  /// everything else its occurrences as a chain.
  Widget? _track(AppLocalizations l, Recurring r, RecurringStats? s) {
    final series = s?.series ?? const [];
    final dayLabels =
        r.rule.freq == RecurrenceFreq.daily ||
        r.rule.freq == RecurrenceFreq.weekly;
    String x(DateTime d) => dayLabels
        ? DateFormat.Md(_locale).format(d)
        : DateFormat.MMM(_locale).format(d);
    if (!r.hasAmount && series.length >= 2) {
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
    final open = r.rule.end.kind == RecurrenceEndKind.never;
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

  /// A rule with an end: every occurrence (the BE's `chain`, else from the
  /// progress). No end: the loaded history, the next one and two after.
  ({List<ChainDot> dots, DateTime? first, DateTime? current}) _chain(
    Recurring r,
  ) {
    final ended = endChainDots(r);
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

  /// Installment: paid / left / last one. A bill that changes: average /
  /// last time / highest. Else: per month / per year / recorded.
  List<Widget> _stats(AppLocalizations l, Recurring r, RecurringStats? s) {
    final symbol = context.readUserCurrencySymbol;
    String money(double v) => moneyString(context, v, symbol: symbol);
    Widget tile(String label, String value) => SummaryTileView(
      tile: SummaryTile(label: label, value: value),
    );
    if (r.kind == RecurringKind.installment) {
      final per = r.amount ?? 0;
      final total = r.progressTotal;
      final left =
          s?.remainingTotal ??
          (total == null ? null : per * (total - r.progressDone));
      final allShown = !_upcoming.windowed && !_upcoming.hasMore;
      final last =
          r.chain?.lastOrNull?.slot ??
          (allShown ? _upcoming.items.lastOrNull?.date : null) ??
          r.rule.end.date;
      return [
        tile(
          l.fpRecurringStatPaid,
          money(s?.paidTotal ?? per * r.progressDone),
        ),
        if (left != null) tile(l.fpRecurringStatRemaining, money(left)),
        if (last != null) tile(l.fpRecurringStatLast, _monthYear(last)),
      ];
    }
    if (!r.hasAmount) {
      final avg = s?.avgAmount ?? r.avgAmount;
      final prev = s?.lastAmount;
      final max = s?.maxAmount;
      return [
        if (avg != null) tile(l.fpRecurringStatAvg, money(avg)),
        if (prev != null) tile(l.fpRecurringStatPrev, money(prev)),
        if (max != null) tile(l.fpRecurringStatMax, money(max)),
      ];
    }
    final monthly = r.monthlyAmount;
    return [
      if (monthly != null && monthly > 0)
        tile(l.fpM5bRecurringPerMonth, money(monthly)),
      tile(l.fpRecurringTileYearly, money(r.yearlyCost)),
      tile(
        l.fpRecurringTileSaved,
        l.fpRecurringCountUnit(s?.paidCount ?? r.savedCount),
      ),
    ];
  }

  /// Status ▾ (pause / resume), the kind, tags and บันทึกอัตโนมัติ (the
  /// category and wallets are the tiles above).
  List<Widget> _heroChips(AppLocalizations l, Recurring r) {
    return [
      if (r.actions.pause || r.actions.resume)
        OptionMenuAnchor<RecurringAction>(
          options: [
            if (r.actions.pause)
              SheetOption(
                value: RecurringAction.pause,
                label: l.recurringPause,
                leading: const AppIcon(AppIcons.pause),
                submits: true,
              ),
            if (r.actions.resume)
              SheetOption(
                value: RecurringAction.resume,
                label: l.recurringResume,
                leading: const AppIcon(AppIcons.resume),
                submits: true,
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
      for (final t in r.tags) _tagChip(t.name, t.iconCode),
      if (r.autoCreate)
        AppChip(
          key: const ValueKey('heroAutoCreate'),
          label: l.fpRecurringAutoChip,
          icon: AppIcons.recurring,
          selected: true,
          tone: AppChipTone.primary,
        ),
    ];
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

  /// Edit: when it runs. ทำซ้ำ opens the kit's custom-repeat sheet (its end
  /// too); เลือกวันเอง picks single dates instead of a round.
  Widget _periodSection(AppLocalizations l) {
    final rule = working.rule;
    final dates = rule.freq == RecurrenceFreq.dates;
    return SectionCard(
      first: true,
      title: l.recurringSectionPeriod,
      children: [
        if (!dates)
          AppDetailRow(
            label: l.recurringFieldStart,
            trailing: Text(
              _date(rule.start),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            showChevron: true,
            onTap: _pickStart,
          ),
        AppDetailRow.pick(
          key: const ValueKey('repeatRow'),
          label: l.recurringFieldRepeat,
          valueChips: _repeatChips(l, rule),
          emptyText: '',
          onTap: _openRecurrenceSheet,
        ),
        AppDetailRow.pick(
          key: const ValueKey('datesRow'),
          label: l.recurringFieldDates,
          value: dates ? _datesText(rule.dates) : null,
          emptyText: '',
          onTap: _pickDates,
        ),
      ],
    );
  }

  List<Widget> _repeatChips(AppLocalizations l, RecurrenceRule rule) {
    if (rule.freq == RecurrenceFreq.dates) {
      return [
        AppChip(
          label: l.recurringFieldDates,
          icon: AppIcons.date,
          tone: AppChipTone.primary,
          size: ChipSize.chip,
        ),
      ];
    }
    final end = rule.end;
    return [
      AppChip(
        label: recurrenceLabel(l, rule),
        icon: AppIcons.recurring,
        tone: AppChipTone.primary,
        size: ChipSize.chip,
      ),
      AppChip(
        label:
            working.kind == RecurringKind.installment &&
                end.kind == RecurrenceEndKind.afterCount
            ? l.fpRecurringCountValue(end.count ?? 0)
            : _endText(l, end),
        size: ChipSize.chip,
      ),
    ];
  }

  /// The picked dates: the first two, then "+n".
  String _datesText(List<DateTime> dates) {
    final f = DateFormat.MMMd(_locale);
    return [
      for (final d in dates.take(2)) f.format(d),
      if (dates.length > 2) '+${dates.length - 2}',
    ].join(' | ');
  }

  /// หมวดหมู่ + กระเป๋า as the pair of tiles quick create uses; a transfer is
  /// กระเป๋า → กระเป๋า. View mode: a tap opens the category / wallet, a long
  /// press edits it, and a missing one is left out.
  Widget? _pickCards(AppLocalizations l) {
    final editing = isEditing;
    final accounts = context.watch<AccountsCubit>();
    final w = working;
    final account = accounts.byId(w.accountId ?? '');
    final toAccount = accounts.byId(w.toAccountId ?? '');
    final category = w.isTransfer
        ? null
        : context.watch<CategoriesCubit>().byId(w.categoryId ?? '');
    String? missing(Account? a) => editing && _walletMissing && a == null
        ? l.recurringWalletRequired
        : null;
    Widget wallet(Account? a, String label, {bool to = false}) =>
        WalletPickCard(
          account: a,
          label: label,
          placeholder: l.quickPickWallet,
          dense: true,
          editable: editing,
          errorText: missing(a),
          onTap: editing
              ? () => _pickWallet(to: to)
              : () => openPage(context, '/accounts/${a!.id}'),
          onLongPress: editing
              ? null
              : () => enterEdit(then: () => _pickWallet(to: to)),
        );
    if (w.isTransfer) {
      if (!editing && account == null && toAccount == null) return null;
      return FlowCards(
        from: wallet(account, l.fpRecurringFieldFromWallet),
        to: wallet(toAccount, l.recurringFieldToWallet, to: true),
      );
    }
    if (w.isSaving) {
      return FlowCards(
        from: wallet(account, l.transactionFormAccountLabel),
        to: _goalCard(l),
      );
    }
    if (w.isDebt) return _debtCards(l, account);
    final categoryCard = !editing && category == null
        ? null
        : CategoryPickCard(
            category: category,
            label: l.recurringFieldCategory,
            placeholder: l.transactionFormCategoryNone,
            dense: true,
            editable: editing,
            onTap: editing
                ? _pickCategory
                : () => openPage(context, '/categories/${category!.id}'),
            onLongPress: editing ? null : () => enterEdit(then: _pickCategory),
          );
    final walletCard = !editing && account == null
        ? null
        : wallet(account, l.transactionFormAccountLabel);
    if (categoryCard == null || walletCard == null) {
      return categoryCard ?? walletCard;
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: categoryCard),
          // As far apart as the cards sit from the hero's edge.
          SizedBox(width: HeroMetrics.of(context).padding.left),
          Expanded(child: walletCard),
        ],
      ),
    );
  }

  /// หนี้: [กับใคร] ⇄ [กระเป๋า] in the money's direction (paid = me → them),
  /// as quick create's debt mode; the arrow swaps it. No wallet = the entries
  /// stay in the person book only ("ไม่ระบุกระเป๋า").
  Widget _debtCards(AppLocalizations l, Account? account) {
    final editing = isEditing;
    final w = working;
    final p = w.person;
    final person = PickCard(
      label: l.debtPersonPickerTitle,
      value: p?.name,
      placeholder: l.debtPickPerson,
      dense: true,
      editable: editing,
      accent: Theme.of(context).colorScheme.primary,
      errorText: editing && _personMissing ? l.debtPickPerson : null,
      leading: p == null
          ? const PickCardEmptyIcon(AppIcons.contact, size: 32)
          : PersonMark(
              name: p.name,
              level: debtPersonLevel(p),
              iconCode: p.iconCode,
              avatar: p.avatar,
              size: 32,
            ),
      onTap: editing
          ? _pickPerson
          : () => openPage(context, debtPersonPath(p!)),
      onLongPress: editing ? null : () => enterEdit(then: _pickPerson),
    );
    final wallet = WalletPickCard(
      account: account,
      label: l.transactionFormAccountLabel,
      placeholder: l.debtNoWallet,
      dense: true,
      editable: editing,
      onTap: editing
          ? () => _pickWallet(to: false)
          : (account == null
                ? null
                : () => openPage(context, '/accounts/${account.id}')),
      onLongPress: editing
          ? null
          : () => enterEdit(then: () => _pickWallet(to: false)),
    );
    final paid = w.direction == DebtEntryDirection.paid;
    return FlowCards(
      key: const ValueKey('debtFlow'),
      from: paid ? wallet : person,
      to: paid ? person : wallet,
      swapTooltip: l.quickSwap,
      onSwap: editing
          ? () => _change(
              w.withDebt(
                direction: paid
                    ? DebtEntryDirection.received
                    : DebtEntryDirection.paid,
              ),
            )
          : null,
    );
  }

  static String debtPersonPath(EmbeddedPerson p) =>
      '/personal-debts/people/'
      '${Uri.encodeComponent(debtPersonKey(contactId: p.contactId, name: p.name))}';

  Future<void> _pickPerson() async {
    final p = working.person;
    final picked = await showDebtPersonPicker(
      context,
      selected: p == null
          ? null
          : DebtPick(
              key: debtPersonKey(contactId: p.contactId, name: p.name),
              person: p,
            ),
    );
    if (picked == null || !mounted) return;
    setState(() => _personMissing = false);
    _change(working.withDebt(person: picked.person));
  }

  /// ออมเงิน: where it goes. View mode: a tap opens the goal (or
  /// ยังไม่จัดสรร), a long press edits it.
  Widget _goalCard(AppLocalizations l) {
    _loadGoals();
    final editing = isEditing;
    final w = working;
    SavingGoal? goal;
    for (final g in _goals?.goals ?? const <SavingGoal>[]) {
      if (g.id == w.goalId) goal = g;
    }
    final spare = w.goalPicked && w.goalId == null;
    return SavingGoalPickCard(
      // Until the goals load, the rule's own goal name shows.
      goal: goal,
      spare: spare,
      spareAmount: _goals?.spare.amount,
      label: l.savingEntryGoalLabel,
      placeholder: w.goalId != null
          ? (_recurring?.goal?.name ?? l.savingEntryPickGoal)
          : l.savingEntryPickGoal,
      spareLabel: l.savingEntrySpare,
      dense: true,
      editable: editing,
      errorText: editing && _goalMissing ? l.savingEntryPickGoal : null,
      onTap: editing
          ? _pickGoal
          : () => openPage(
              context,
              '/saving-goals/${w.goalId ?? SavingGoalsRepository.spareId}',
            ),
      onLongPress: editing ? null : () => enterEdit(then: _pickGoal),
    );
  }

  /// Edit: what it is and its options. ประเภท and แบบ drop down in place.
  Widget _detailSection(AppLocalizations l) {
    final w = working;
    final transfer = w.isTransfer;
    return SectionCard(
      children: [
        SettingDropdownRow<RecurringKind>(
          key: const ValueKey('kindRow'),
          label: l.recurringFieldKind,
          value: recurringKindLabel(l, w.kind),
          icon: recurringKindIcon(w.kind),
          iconColor: w.kind.iconDefault.color,
          selected: w.kind,
          submits: false,
          onSelected: (k) {
            if (k != w.kind) _change(w.withKind(k));
          },
          options: [
            // A saved rule can't switch between ออมเงิน / หนี้ and a money
            // kind.
            for (final k in RecurringKind.values)
              if (_recurring == null ||
                  ((k == RecurringKind.saving) == _recurring!.isSaving &&
                      (k == RecurringKind.debt) == _recurring!.isDebt))
                SheetOption(
                  value: k,
                  label: recurringKindLabel(l, k),
                  leading: AppIcon(
                    recurringKindIcon(k),
                    color: k.iconDefault.color,
                  ),
                ),
          ],
        ),
        if (w.kind == RecurringKind.reminder)
          SettingDropdownRow<TransactionType>(
            label: l.fpRecurringFieldMode,
            value: transfer
                ? l.transactionTypeTransfer
                : l.transactionTypeExpense,
            icon: transfer ? AppIcons.transfer : AppIcons.expense,
            selected: w.type,
            submits: false,
            onSelected: _setMode,
            options: [
              SheetOption(
                value: TransactionType.expense,
                label: l.transactionTypeExpense,
                leading: const AppIcon(AppIcons.expense),
              ),
              SheetOption(
                value: TransactionType.transfer,
                label: l.transactionTypeTransfer,
                leading: const AppIcon(AppIcons.transfer),
              ),
            ],
          ),
        if (w.isDebt)
          SettingDropdownRow<DebtEntrySub>(
            key: const ValueKey('debtSubRow'),
            label: l.fpRecurringFieldMode,
            value: w.debtSub == DebtEntrySub.record
                ? l.debtRecordChip
                : l.debtSettleChip,
            icon: AppIcons.debt,
            selected: w.debtSub,
            submits: false,
            onSelected: (s) => _change(w.withDebt(sub: s)),
            options: [
              SheetOption(value: DebtEntrySub.record, label: l.debtRecordChip),
              SheetOption(value: DebtEntrySub.repay, label: l.debtSettleChip),
            ],
          ),
        if (w.kind == RecurringKind.subscription)
          AppDetailRow(
            label: l.fpRecurringTrialUntil,
            onTap: _pickTrial,
            trailing: DatePickChip(
              date: w.trialUntil,
              onPick: _pickTrial,
              onClear: () => _change(w.copyWith(clearTrial: true)),
            ),
          ),
        SettingToggleRow(
          key: const ValueKey('autoCreateRow'),
          label: l.fpRecurringAutoCreate,
          caption: w.canAutoCreate
              ? l.fpRecurringAutoCreateHint
              : l.fpRecurringAutoCreateNeedsWallet,
          value: w.autoCreate && w.canAutoCreate,
          submits: false,
          onChanged: w.canAutoCreate
              ? (v) => _change(w.copyWith(autoCreate: v))
              : null,
        ),
        if (w.autoCreateWarns)
          Padding(
            key: const ValueKey('autoCreateZeroWarn'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: AppMessage(
              tone: Tone.warning,
              message: l.fpRecurringAutoCreateZeroWarn,
            ),
          ),
      ],
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
    return AppListRow(
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
              child: AppChip(
                label: pill,
                tone: tone == null
                    ? AppChipTone.neutral
                    : AppChipTone.fromTone(tone),
                selected: tone != null,
                size: ChipSize.mini,
                maxWidth: AppListRow.chipMaxWidth,
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
      isEmpty: items.isEmpty,
      onRetry: _load,
      rowCards: true,
      topInset: AppSpacing.sm,
      hasMore: _produced.hasMore,
      loadingMore: _producedMore,
      onLoadMore: _loadMoreProduced,
      loadMoreError: _producedMoreError,
      onRetryMore: _loadMoreProduced,
      empty: EmptyView.compact(message: l.recurringItemsEmpty),
      children: [
        for (final item in items)
          _occurrenceRow(l, r, item, onTap: () => _openOccurrence(item)),
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
      topInset: AppSpacing.sm,
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
            AppListRow(
              key: const ValueKey('upcomingCustomize'),
              leading: const AppAvatar.icon(AppIcons.edit),
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
      showAppSheetCustom<void>(
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
              top: AppSpacing.sm,
              bottom: AppSpacing.xs + 2,
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
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...body,
            if (_upcomingMore) ...[
              const SizedBox(height: AppSpacing.sm),
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
    final palette = Theme.of(context).extension<AppColors>()!;
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

  Widget _editBody(
    BuildContext context,
    AppLocalizations l,
    Recurring? r,
    double barInset,
    double bottom,
  ) {
    final w = working;
    final palette = Theme.of(context).extension<AppColors>()!;
    final icon = recurringIconCode(
      kind: w.kind,
      own: w.iconCode,
      category: context
          .watch<CategoriesCubit>()
          .byId(w.isTransfer ? '' : w.categoryId ?? '')
          ?.iconCode,
    );
    final accent = icon.tintFor(palette);
    final tags = context.watch<TagsCubit>();
    return DetailLayout(
      topInset: barInset + AppSpacing.lg,
      bottomInset: bottom,
      onRefresh: widget.isCreate ? null : _load,
      hero: AppHeroCard(
        style: HeroStyle.tinted(color: accent, glyph: AppIcons.scheduled),
        mode: HeroCardMode.edit,
        content: [
          HeroIdentity(
            icon: EditableCircle(
              size: 44,
              onTap: _pickIcon,
              child: IconDisplay(
                type: IconType.category,
                size: 44,
                iconCode: icon,
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
            symbol: context.readUserCurrencySymbol,
            onChanged: (v) => _onText(_Field.amount, v),
            validator: (v) {
              final n = AmountInput.parse(v);
              if (w.amountOptional && (v ?? '').trim().isEmpty) return null;
              return (n == null || n <= 0) ? l.recurringAmountInvalid : null;
            },
          ),
          ?_pickCards(l),
        ],
      ),
      // ออมเงิน and หนี้ have no tags.
      tags: w.isSaving || w.isDebt
          ? null
          : TagRow(
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
          _periodSection(l),
          _detailSection(l),
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
