import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
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
import '../../../saving_goals/data/saving_goals_repository.dart';
import '../../../saving_goals/domain/saving_goal.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurrence_rule.dart';
import '../../domain/recurring.dart';
import '../../domain/recurring_item.dart';
import '../recurring_writes.dart';

/// What the settings page hands back to whoever opened it: the new page
/// state (create / save / archive / restore), or [deleted].
class RecurringSettingsResult {
  const RecurringSettingsResult.saved(RecurringDetail this.detail)
    : deleted = false;
  const RecurringSettingsResult.deleted() : detail = null, deleted = true;

  final RecurringDetail? detail;
  final bool deleted;
}

/// Recurring settings = the generator (owner 2026-10-13, part 1): create
/// (`/recurring/new`, [id] null), view + in-place edit
/// (`/recurring/:id/settings`). Detail-page standard: hero (icon, name,
/// description; type chip) → tags → one box (amount, wallet, category,
/// ทำซ้ำ, เริ่ม, สิ้นสุด, note) → archive / delete in edit mode → meta.
/// Open = one call; save = one call (+ the scope / linked prompts first).
/// Pops with a [RecurringSettingsResult] when something changed.
class RecurringSettingsPage extends StatefulWidget {
  const RecurringSettingsPage({
    this.id,
    this.saving = false,
    this.goalId,
    this.accountId,
    super.key,
  });

  /// null = create.
  final String? id;

  /// Create presets (a goal page's "🔁 ออมอัตโนมัติ" →
  /// `/recurring/new?type=saving&goal=<id>`): start as ออม, into [goalId]
  /// (null = ยังไม่จัดสรร), from [accountId].
  final bool saving;
  final String? goalId;
  final String? accountId;

  bool get isCreate => id == null;

  @override
  State<RecurringSettingsPage> createState() => _RecurringSettingsPageState();
}

enum _Field { name, description, amount, note }

class _RecurringSettingsPageState extends State<RecurringSettingsPage>
    with EditModeMixin<RecurringSettingsPage, _Draft> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = {for (final f in _Field.values) f: TextEditingController()};
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _noteFocus = FocusNode();

  RecurringDetail? _detail;
  bool _loading = false;
  Object? _error;
  bool _walletMissing = false;

  /// Goal names by id (the recurring's own goal + the goals list once seen).
  final Map<String, String> _goalNames = {};

  /// The last write's result, handed back on leave.
  RecurringSettingsResult? _result;

  RecurringRepository get _repo => RecurringRepository.of(context);
  Recurring? get _recurring => _detail?.recurring;

  @override
  void initState() {
    super.initState();
    initDraft(
      _Draft(
        rule: RecurrenceRule(
          freq: RecurrenceFreq.monthly,
          start: today(),
          monthly: RecurrenceMonthly.onDay(today().day),
        ),
        saving: widget.isCreate && widget.saving,
        goalId: widget.isCreate && widget.saving ? widget.goalId : null,
        accountId: widget.isCreate && widget.saving ? widget.accountId : null,
      ),
      editing: widget.isCreate,
    );
    onDraftRestored();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
      context.read<TagsCubit>().loadIfNeeded();
      if (!widget.isCreate) _load();
      if (widget.isCreate && widget.saving && widget.goalId != null) {
        _loadGoalNames();
      }
    });
  }

  /// The active goals' names (for the preset goal and the picker).
  Future<List<SavingGoal>> _loadGoalNames() async {
    try {
      final o = await context.read<SavingGoalsRepository>().list();
      if (!mounted) return o.goals;
      setState(() {
        for (final g in o.goals) {
          _goalNames[g.id] = g.name;
        }
      });
      return o.goals;
    } catch (_) {
      return const [];
    }
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _repo.get(widget.id!);
      if (!mounted) return;
      setState(() {
        _detail = d;
        final g = d.recurring.goal;
        if (g != null) _goalNames[g.id] = g.name;
      });
      resetDraft(_Draft.from(d.recurring));
    } catch (e, st) {
      if (mounted) setState(() => _error = ApiException.from(e, st));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── EditModeMixin hooks ─────────────────────────────────────────────

  @override
  bool get leaveOnCancel => widget.isCreate;

  /// Back with what changed (the opener patches itself from it).
  @override
  void leavePage() {
    if (context.canPop()) {
      context.pop(_result);
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

  /// A picker in view mode starts editing.
  void _change(_Draft next) {
    if (!isEditing) enterEdit();
    applyChange(next);
  }

  // ── Pickers ─────────────────────────────────────────────────────────

  Future<void> _openIconMaker() async {
    final l = AppLocalizations.of(context)!;
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.category,
      initial: working.iconCode,
      title: l.recurringFieldIcon,
    );
    if (!mounted || result == null) return;
    if (result is IconMakerSelected) {
      _change(working.copyWith(iconCode: result.iconCode));
    } else if (result is IconMakerRemoved) {
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
      title: to ? l.recurringFieldToWallet : l.recurringFieldWallet,
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

  /// ออม default name: "ออม · goal name" or "ออมเงิน" (the name is optional).
  String _savingName(AppLocalizations l, String? goalId) {
    final goal = goalId == null ? null : _goalNames[goalId];
    return goal == null
        ? l.recurringSavingName
        : l.recurringSavingNameGoal(goal);
  }

  /// ออมเข้า: ยังไม่จัดสรร or one of the active goals.
  Future<void> _pickGoal() async {
    final l = AppLocalizations.of(context)!;
    final goals = await _loadGoalNames();
    if (!mounted) return;
    const spare = '';
    final picked = await showOptionSheet<String>(
      context,
      title: l.recurringFieldGoal,
      selected: working.goalId ?? spare,
      options: [
        SheetOption(value: spare, label: l.savingEntrySpare),
        for (final g in goals) SheetOption(value: g.id, label: g.name),
      ],
    );
    if (!mounted || picked == null) return;
    _change(
      picked == spare
          ? working.copyWith(clearGoal: true)
          : working.copyWith(goalId: picked),
    );
  }

  /// ทำซ้ำ: the presets for the start date (Google Calendar style), then
  /// เลือกวันเอง… (hand-picked dates).
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
    // Day-anchored rules follow the new start (like Google Calendar).
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

  /// สิ้นสุด: the recurrence sheet (never / on a date ≤ 2 years / after N).
  Future<void> _pickEnd() => _openRecurrenceSheet();

  /// กำหนดเอง…: every N, weekdays, Nth weekday, ends — the kit sheet.
  Future<void> _openRecurrenceSheet() async {
    final picked = await showRecurrenceSheet(context, initial: working.rule);
    if (!mounted || picked == null) return;
    _change(working.copyWith(rule: picked));
  }

  // ── Save / archive / delete ─────────────────────────────────────────

  RecurringWrite _write() {
    final w = working;
    final description = w.description.trim();
    final note = w.note.trim();
    final transfer = w.type == TransactionType.transfer;
    return RecurringWrite(
      name: w.name.trim().isEmpty && w.saving
          ? _savingName(AppLocalizations.of(context)!, w.goalId)
          : w.name.trim(),
      description: description.isEmpty ? null : description,
      note: note.isEmpty ? null : note,
      iconCode: w.iconCode,
      type: w.type,
      amount: AmountInput.parse(w.amount) ?? 0,
      accountId: w.accountId,
      toAccountId: transfer && !w.saving ? w.toAccountId : null,
      categoryId: transfer || w.saving ? null : w.categoryId,
      tagIds: w.saving ? const [] : w.tagIds.toList(),
      rule: w.rule,
      isSaving: w.saving,
      goalId: w.saving ? w.goalId : null,
    );
  }

  Future<void> _save() async {
    commitTextSession();
    final l = AppLocalizations.of(context)!;
    final formOk = _formKey.currentState?.validate() ?? false;
    final walletOk =
        working.accountId != null &&
        (working.saving ||
            working.type != TransactionType.transfer ||
            working.toAccountId != null);
    if (!walletOk) setState(() => _walletMissing = true);
    if (!formOk || !walletOk) return;

    var scope = EditScope.upcoming;
    var alsoUpdateLink = false;
    final r = _recurring;
    if (r != null && working.valuesDiffer(original)) {
      // Value changes: which items take them (the rule only rebuilds the
      // upcoming ones).
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
      final d = r == null
          ? await _repo.create(_write())
          : await _repo.update(
              r.id,
              _write(),
              scope: scope,
              alsoUpdateLink: alsoUpdateLink,
            );
      accounts.patchBalances(d.balances);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      markRecurringChanged(context);
      _result = RecurringSettingsResult.saved(d);
      if (widget.isCreate) {
        commitSaved(working);
        leavePage();
        return;
      }
      setState(() => _detail = d);
      commitSaved(_Draft.from(d.recurring));
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

  Future<void> _delete(Recurring r) async {
    final l = AppLocalizations.of(context)!;
    bool deleteTxs = false;
    if (r.counts.done > 0) {
      final choice = await showLinkedPrompt(
        context,
        title: l.recurringDeleteTitle,
        message: l.recurringDeleteLinkedBody(r.counts.done),
        cancelLabel: l.linkedCancel,
        thisSideLabel: l.recurringDeleteKeepTxs,
        bothSidesLabel: l.recurringDeleteWithTxs(r.counts.done),
        destructive: true,
      );
      if (!mounted || choice == null) return;
      deleteTxs = choice == LinkedChoice.bothSides;
    } else {
      final ok = await showConfirmDialog(
        context,
        title: l.recurringDeleteTitle,
        message: l.recurringDeleteBody,
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
    markRecurringChanged(context);
    _result = const RecurringSettingsResult.deleted();
    commitSaved(working);
    leavePage();
  }

  /// A lifecycle call (archive / restore): the page takes the returned state.
  Future<void> _run(Future<RecurringDetail> Function() call) async {
    setSaving(true);
    try {
      final d = await call();
      if (!mounted) return;
      markRecurringChanged(context);
      _result = RecurringSettingsResult.saved(d);
      setState(() => _detail = d);
      commitSaved(_Draft.from(d.recurring));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

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
          onRetry: _load,
          notFound: EmptyView(
            icon: AppIcons.empty,
            title: l.recurringNotFound,
            message: l.recurringNotFoundMessage,
          ),
        ),
      );
    }
    final r = _recurring;
    final editing = isEditing;
    return editScope(
      Scaffold(
        appBar: AppTopBar(
          // Titles never change with the mode.
          title: r == null ? l.recurringNewTitle : r.name,
          showBack: true,
          editing: editing,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          child: Builder(
            builder: (context) => DetailPageBody(
              onRefresh: r == null ? null : _load,
              topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
              bottomInset:
                  AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
              hero: _hero(l, r),
              tags: _tags(l),
              sections: [(first) => _box(l, first)],
              manage: editing && r != null
                  ? ManageSection(
                      archiveLabel: r.status == RecurringStatus.archived
                          ? l.recurringRestore
                          : l.recurringArchive,
                      onArchive: isSaving
                          ? null
                          : () => _archive(
                              r,
                              restore: r.status == RecurringStatus.archived,
                            ),
                      deleteLabel: l.recurringDelete,
                      onDelete: isSaving ? null : () => _delete(r),
                    )
                  : null,
              metaLines: r == null
                  ? const []
                  : detailMetaLines(
                      context,
                      createdAt: r.createdAt,
                      updatedAt: r.updatedAt,
                    ),
            ),
          ),
        ),
        bottomNavigationBar: editing ? editActionBar(onSave: _save) : null,
      ),
    );
  }

  String _typeLabel(AppLocalizations l, TransactionType t) => switch (t) {
    TransactionType.expense => l.transactionTypeExpense,
    TransactionType.income => l.transactionTypeIncome,
    TransactionType.transfer => l.transactionTypeTransfer,
  };

  Widget _hero(AppLocalizations l, Recurring? r) {
    final editing = isEditing;
    final palette = Theme.of(context).extension<AppColors>()!;
    return HeaderCard(
      accent: working.iconCode.tintFor(palette),
      glyph: AppIcons.scheduled,
      onEdit: editing ? null : enterEdit,
      topRow: [
        if (editing) ...[
          AppChip(
            label: l.recurringKindTx,
            selected: !working.saving,
            onTap: () => _change(working.copyWith(saving: false)),
          ),
          AppChip(
            label: l.recurringKindSaving,
            icon: AppIcons.savingDeposit,
            selected: working.saving,
            onTap: () =>
                _change(working.copyWith(saving: true, clearCategory: true)),
          ),
        ] else if (working.saving)
          AppChip(
            label: l.recurringKindSaving,
            icon: AppIcons.savingDeposit,
            selected: true,
            tone: AppChipTone.neutral,
          ),
        if (!working.saving)
          OptionMenuAnchor<TransactionType>(
            selected: working.type,
            options: [
              for (final t in TransactionType.values)
                SheetOption(value: t, label: _typeLabel(l, t)),
            ],
            onSelected: (t) => _change(
              working.copyWith(type: t, clearCategory: t != working.type),
            ),
            builder: (context, toggle) => AppChip(
              label: _typeLabel(l, working.type),
              trailing: editing
                  ? AppChipTrailing.dropdown
                  : AppChipTrailing.none,
              selected: true,
              tone: AppChipTone.neutral,
              onTap: editing ? toggle : null,
            ),
          ),
        if (r != null && r.status != RecurringStatus.active)
          StatusChip(
            label: r.status == RecurringStatus.paused
                ? l.recurringStatusPaused
                : l.recurringStatusArchived,
            kind: r.status == RecurringStatus.paused
                ? StatusKind.paused
                : StatusKind.archived,
          ),
      ],
      leading: EditableCircle(
        size: 52,
        onTap: editing ? _openIconMaker : null,
        onLongPress: editing
            ? null
            : () {
                enterEdit();
                _openIconMaker();
              },
        child: IconDisplay(
          type: IconType.category,
          size: 52,
          iconCode: working.iconCode,
        ),
      ),
      title: HeroNameInput(
        editing: editing,
        controller: _ctrl[_Field.name]!,
        focusNode: _nameFocus,
        hint: l.commonName,
        maxLength: TextLimits.name,
        onEnterEdit: () => enterEdit(focus: _nameFocus),
        onChanged: (v) => _onText(_Field.name, v),
        validator: (v) => (v == null || v.trim().isEmpty) && !working.saving
            ? l.recurringNameRequired
            : null,
      ),
      description: HeroDescription(
        controller: _ctrl[_Field.description]!,
        editing: editing,
        hint: l.commonDescription,
        maxLength: TextLimits.description,
        focusNode: _descriptionFocus,
        onEnterEdit: () => enterEdit(focus: _descriptionFocus),
        onChanged: (v) => _onText(_Field.description, v),
      ),
    );
  }

  Widget? _tags(AppLocalizations l) {
    final tags = context.watch<TagsCubit>();
    if (working.saving) return null;
    if (working.tagIds.isEmpty && !isEditing) return null;
    final palette = Theme.of(context).extension<AppColors>()!;
    return ChipRow(
      icon: AppIcons.tag,
      chips: [
        for (final id in working.tagIds)
          if (tags.byId(id) case final t?)
            AppChip(
              label: t.name,
              icon: IconRegistry.get(t.iconCode?.icon, fallback: AppIcons.tag),
              color: EventTagRef(t.name, iconCode: t.iconCode).colorOf(palette),
              selected: true,
              size: ChipSize.chip,
              onTap: _pickTags,
            ),
      ],
      onMore: _pickTags,
    );
  }

  Widget _box(AppLocalizations l, bool first) {
    final editing = isEditing;
    final accounts = context.watch<AccountsCubit>();
    final cats = context.watch<CategoriesCubit>();
    final w = working;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final account = accounts.byId(w.accountId ?? '');
    final toAccount = accounts.byId(w.toAccountId ?? '');
    final category = cats.byId(w.categoryId ?? '');
    final saving = w.saving;
    final transfer = w.type == TransactionType.transfer && !saving;
    final goalName = w.goalId == null ? null : _goalNames[w.goalId!];
    final symbol = Currencies.symbolOf(account?.currency ?? 'THB');
    final rule = w.rule;
    final end = rule.end;
    return SectionCard(
      first: first,
      children: [
        if (editing)
          DetailStacked(
            label: l.recurringFieldAmount,
            child: AmountInput(
              controller: _ctrl[_Field.amount]!,
              currencySymbol: symbol,
              onChanged: (v) => _onText(_Field.amount, v),
              validator: (v) {
                final n = AmountInput.parse(v);
                return (n == null || n <= 0) ? l.recurringAmountInvalid : null;
              },
            ),
          )
        else
          DetailRow(
            label: l.recurringFieldAmount,
            trailing: MoneyText(
              AmountInput.parse(w.amount) ?? 0,
              symbol: symbol,
            ),
          ),
        DetailRow.pick(
          label: saving ? l.recurringFieldFromWallet : l.recurringFieldWallet,
          valueChip: account == null
              ? null
              : walletValueChip(
                  context,
                  name: account.name,
                  iconCode: account.iconCode,
                ),
          emptyText: l.quickEventNone,
          helper: _walletMissing && w.accountId == null
              ? l.recurringWalletRequired
              : null,
          onTap: () => _pickWallet(to: false),
        ),
        if (saving)
          DetailRow.pick(
            label: l.recurringFieldGoal,
            value: w.goalId == null
                ? l.savingEntrySpare
                : (goalName ?? l.savingEntryPickGoal),
            emptyText: l.savingEntrySpare,
            onTap: _pickGoal,
          )
        else if (transfer)
          DetailRow.pick(
            label: l.recurringFieldToWallet,
            valueChip: toAccount == null
                ? null
                : walletValueChip(
                    context,
                    name: toAccount.name,
                    iconCode: toAccount.iconCode,
                  ),
            emptyText: l.quickEventNone,
            helper: _walletMissing && w.toAccountId == null
                ? l.recurringWalletRequired
                : null,
            onTap: () => _pickWallet(to: true),
          )
        else
          DetailRow.pick(
            label: l.recurringFieldCategory,
            valueChip: category == null
                ? null
                : categoryChipPath(
                    context,
                    category,
                    all: cats.state.categories,
                  ),
            emptyText: l.quickEventNone,
            onTap: _pickCategory,
          ),
        DetailRow.pick(
          label: l.recurringFieldRepeat,
          value: recurrenceLabel(l, rule),
          emptyText: l.quickEventNone,
          onTap: _pickRepeat,
        ),
        if (rule.freq != RecurrenceFreq.dates) ...[
          DetailRow.pick(
            label: l.recurringFieldStart,
            value: DateFormatter.medium(rule.start, locale: locale),
            emptyText: l.quickEventNone,
            onTap: _pickStart,
          ),
          DetailRow.pick(
            label: l.recurringFieldEnd,
            value: switch (end.kind) {
              RecurrenceEndKind.never => l.recurringEndNever,
              RecurrenceEndKind.onDate => l.recurEndUntil(
                DateFormatter.medium(end.date!, locale: locale),
              ),
              RecurrenceEndKind.afterCount => l.recurEndCount(end.count ?? 0),
            },
            emptyText: l.quickEventNone,
            onTap: _pickEnd,
          ),
        ],
        DetailStacked(
          label: l.commonNote,
          child: AppInput.inline(
            editing: editing,
            controller: _ctrl[_Field.note]!,
            focusNode: _noteFocus,
            maxLines: 3,
            maxLength: TextLimits.note,
            viewHint: l.commonLongPressToEdit,
            onEnterEdit: () => enterEdit(focus: _noteFocus),
            onChanged: (v) => _onText(_Field.note, v),
          ),
        ),
      ],
    );
  }
}

enum _RepeatMore { custom, dates }

/// The editing snapshot (dirty check + undo).
class _Draft {
  const _Draft({
    required this.rule,
    this.name = '',
    this.description = '',
    this.note = '',
    this.amount = '',
    this.iconCode,
    this.type = TransactionType.expense,
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.tagIds = const {},
    this.saving = false,
    this.goalId,
  });

  factory _Draft.from(Recurring r) => _Draft(
    saving: r.isSaving,
    goalId: r.goal?.id,
    rule: r.rule,
    name: r.name,
    description: r.description ?? '',
    note: r.note ?? '',
    amount: AmountInput.format(r.amount),
    iconCode: r.iconCode,
    type: r.type,
    accountId: r.account?.id,
    toAccountId: r.toAccount?.id,
    categoryId: r.category?.id,
    tagIds: {for (final t in r.tags) t.id},
  );

  final RecurrenceRule rule;
  final String name;
  final String description;
  final String note;
  final String amount;
  final IconCode? iconCode;
  final TransactionType type;
  final String? accountId;
  final String? toAccountId;
  final String? categoryId;
  final Set<String> tagIds;

  /// ออม: into [goalId] (null = ยังไม่จัดสรร).
  final bool saving;
  final String? goalId;

  /// A change to what the items carry (not the rule / name / icon): the
  /// save asks which items take it.
  bool valuesDiffer(_Draft o) =>
      description.trim() != o.description.trim() ||
      note.trim() != o.note.trim() ||
      AmountInput.parse(amount) != AmountInput.parse(o.amount) ||
      type != o.type ||
      accountId != o.accountId ||
      toAccountId != o.toAccountId ||
      categoryId != o.categoryId ||
      saving != o.saving ||
      goalId != o.goalId ||
      !_sameSet(tagIds, o.tagIds);

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  _Draft copyWith({
    RecurrenceRule? rule,
    String? name,
    String? description,
    String? note,
    String? amount,
    IconCode? iconCode,
    bool clearIcon = false,
    TransactionType? type,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    bool clearCategory = false,
    Set<String>? tagIds,
    bool? saving,
    String? goalId,
    bool clearGoal = false,
  }) => _Draft(
    saving: saving ?? this.saving,
    goalId: clearGoal ? null : (goalId ?? this.goalId),
    rule: rule ?? this.rule,
    name: name ?? this.name,
    description: description ?? this.description,
    note: note ?? this.note,
    amount: amount ?? this.amount,
    iconCode: clearIcon ? null : (iconCode ?? this.iconCode),
    type: type ?? this.type,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId ?? this.toAccountId,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    tagIds: tagIds ?? this.tagIds,
  );

  @override
  bool operator ==(Object other) =>
      other is _Draft &&
      other.rule == rule &&
      other.name == name &&
      other.description == description &&
      other.note == note &&
      other.amount == amount &&
      other.iconCode == iconCode &&
      other.type == type &&
      other.accountId == accountId &&
      other.toAccountId == toAccountId &&
      other.categoryId == categoryId &&
      other.saving == saving &&
      other.goalId == goalId &&
      _sameSet(other.tagIds, tagIds);

  @override
  int get hashCode => Object.hash(
    rule,
    name,
    description,
    note,
    amount,
    iconCode,
    type,
    accountId,
    toAccountId,
    categoryId,
    saving,
    goalId,
    Object.hashAllUnordered(tagIds),
  );
}
