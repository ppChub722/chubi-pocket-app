import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../home/presentation/cubit/dashboard_cubit.dart';
import '../../../recurring/domain/recurrence_rule.dart' show today;
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../data/budgets_repository.dart';
import '../../domain/budget.dart';
import '../../domain/budget_detail.dart';
import '../../domain/budget_period.dart';
import '../budget_draft.dart';
import '../budget_labels.dart';
import '../budget_period_sheet.dart';
import '../budget_scope_pickers.dart';
import '../budget_view_sections.dart';
import '../cubit/budgets_cubit.dart';

/// `/budgets/new`, `/budgets/:id` (+ `/edit`) — ONE page for a budget of any
/// kind (spec 08 v2): view ⇄ edit in place ([EditModeMixin]).
///
/// - a RECURRING budget has the tabs [รอบงบ] (the period shown: dashboard,
///   by source / category, the period list, the counted items; "เฉพาะรอบนี้"
///   edits that period alone) and [ตั้งค่า] (the setup);
/// - a one-off / open-ended budget is ONE page: the setup box, the dashboard,
///   the items; open-ended ones end with "ปิดงบ".
///
/// Open = one call (`getBudget`); every write answers with the page, so the
/// page takes the new state from the response. A transaction write reloads
/// it once.
class BudgetDetailPage extends StatefulWidget {
  const BudgetDetailPage({this.id, this.startEditing = false, super.key});

  /// Null = create.
  final String? id;

  /// `/budgets/:id/edit` opens straight in edit mode.
  final bool startEditing;

  bool get isCreate => id == null;

  @override
  State<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

enum _Tab { periods, setup }

/// Which text field a typing burst belongs to (undo grouping).
enum _Field { name, description, amount, note }

class _BudgetDetailPageState extends State<BudgetDetailPage>
    with EditModeMixin<BudgetDetailPage, BudgetDraft> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = {for (final f in _Field.values) f: TextEditingController()};
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _noteFocus = FocusNode();

  BudgetDetail? _detail;
  bool _loading = false;
  Object? _error;
  _Tab _tab = _Tab.periods;

  /// The period shown (null = the current one).
  String? _periodId;

  /// All periods, once "ดูรอบก่อนหน้าทั้งหมด" was tapped.
  BudgetPeriodPage? _allPeriods;
  bool _moreBusy = false;
  Object? _moreError;

  /// Save was tried with nothing to count.
  bool _scopeMissing = false;

  BudgetsRepository get _repo => BudgetsRepository.of(context);
  Budget? get _budget => _detail?.budget;

  @override
  void initState() {
    super.initState();
    initDraft(BudgetDraft.blank(), editing: widget.isCreate);
    onDraftRestored();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoriesCubit>().loadIfNeeded();
      context.read<TagsCubit>().loadIfNeeded();
      context.read<AccountsCubit>().loadIfNeeded();
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

  // ── Loading ─────────────────────────────────────────────────────────

  /// `getBudget` at [periodId] (null = current). A reload while editing keeps
  /// the draft.
  Future<void> _load({String? periodId, bool first = false}) async {
    final keep = !first && _detail != null;
    if (!keep) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final d = await _repo.get(widget.id!, periodId: periodId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _periodId = periodId;
        _error = null;
        _allPeriods = null;
      });
      if (!isEditing) resetDraft(BudgetDraft.from(d.budget));
      if (first && widget.startEditing && d.budget.actions.edit) {
        _enterSetup();
      }
    } catch (e, st) {
      if (!mounted) return;
      if (_detail == null) {
        setState(() => _error = ApiException.from(e, st));
      } else {
        showAppSnackBarOn(
          pageMessenger!,
          ApiException.from(e, st).message,
          tone: Tone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _afterWrite(BudgetDetail d) {
    setState(() {
      _detail = d;
      _periodId = null;
      _allPeriods = null;
    });
    context.read<BudgetsCubit>().markStale();
    context.read<DashboardCubit>().markStale();
  }

  Future<void> _loadMoreItems() async {
    final d = _detail;
    if (d == null || !d.items.hasMore || _moreBusy) return;
    setState(() {
      _moreBusy = true;
      _moreError = null;
    });
    try {
      final next = await _repo.items(
        d.budget.id,
        periodId: d.budget.period.id,
        page: d.items.page + 1,
      );
      if (mounted) {
        setState(() => _detail = d.copyWith(items: d.items.append(next)));
      }
    } catch (e, st) {
      if (mounted) setState(() => _moreError = ApiException.from(e, st));
    } finally {
      if (mounted) setState(() => _moreBusy = false);
    }
  }

  Future<void> _loadAllPeriods() async {
    final d = _detail;
    if (d == null || _moreBusy) return;
    setState(() {
      _moreBusy = true;
      _moreError = null;
    });
    try {
      final current = _allPeriods;
      final next = await _repo.periods(
        d.budget.id,
        page: current == null ? 1 : current.page + 1,
      );
      if (mounted) {
        setState(
          () => _allPeriods = current == null ? next : current.append(next),
        );
      }
    } catch (e, st) {
      if (mounted) setState(() => _moreError = ApiException.from(e, st));
    } finally {
      if (mounted) setState(() => _moreBusy = false);
    }
  }

  // ── EditModeMixin hooks ─────────────────────────────────────────────

  @override
  bool get leaveOnCancel => widget.isCreate;

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

  /// A picker / switch in view mode starts editing first.
  void _change(BudgetDraft next) {
    if (!isEditing) _enterSetup();
    applyChange(next);
  }

  /// Editing happens on the setup (a recurring budget's ตั้งค่า tab).
  void _enterSetup({FocusNode? focus}) {
    if (working.recurring) setState(() => _tab = _Tab.setup);
    enterEdit(focus: focus);
  }

  // ── Pickers ─────────────────────────────────────────────────────────

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

  Future<void> _pickCategories() async {
    final cats = context.read<CategoriesCubit>().state.categories;
    final r = await showBudgetCategoriesPicker(
      context,
      all: cats,
      selected: working.categories,
    );
    if (!mounted || r == null) return;
    setState(() => _scopeMissing = false);
    _change(working.copyWith(categories: r));
  }

  Future<void> _pickTags() async {
    final tags = context.read<TagsCubit>();
    final l = AppLocalizations.of(context)!;
    final selectedIds = [
      for (final t in tags.state.tags)
        if (working.tags.contains(t.name)) t.id,
    ];
    final picked = await showTagPickerSheet(
      context,
      selected: selectedIds.toSet(),
      title: l.bgScopeTags,
    );
    if (picked == null || !mounted) return;
    setState(() => _scopeMissing = false);
    _change(
      working.copyWith(
        tags: [
          for (final id in picked)
            if (tags.byId(id) case final t?) t.name,
        ],
      ),
    );
  }

  Future<void> _pickWallets() async {
    final accounts = context.read<AccountsCubit>().state.accounts;
    final ids = await showBudgetWalletsPicker(
      context,
      all: accounts,
      selected: [for (final w in working.wallets) w.id],
    );
    if (!mounted || ids == null) return;
    setState(() => _scopeMissing = false);
    _change(
      working.copyWith(
        wallets: budgetWalletRefs(accounts, ids, working.wallets),
      ),
    );
  }

  Future<void> _pickStart() async {
    final current = working.start;
    final now = today();
    final picked = await showAppDatePicker(
      context,
      initial: current,
      first: DateTime(now.year - 2, 1, 1),
      last: DateTime(now.year + 5, 12, 31),
    );
    if (!mounted || picked is! AppDatePicked) return;
    _change(working.copyWith(start: picked.date));
  }

  /// A recurring budget: every N day | week | month | year + the end (the
  /// kit sheet, simple mode).
  Future<void> _pickRule() async {
    final r = await showRecurrenceSheet(
      context,
      initial: working.kitRule,
      simple: true,
    );
    if (!mounted || r == null) return;
    _change(working.withKitRule(r));
  }

  /// A one-off budget's end: none (open until ปิดงบ) or a date.
  Future<void> _pickEnd() async {
    if (working.recurring) return _pickRule();
    final l = AppLocalizations.of(context)!;
    final choice = await showOptionSheet<bool>(
      context,
      title: l.bgFieldEnd,
      selected: working.end.kind == 'date',
      options: [
        SheetOption(value: false, label: l.bgEndNone),
        SheetOption(value: true, label: l.bgEndPickDate),
      ],
    );
    if (!mounted || choice == null) return;
    if (!choice) return _change(working.copyWith(end: const BudgetEnd.none()));
    final start = working.start;
    final picked = await showAppDatePicker(
      context,
      initial: working.end.date ?? start.add(const Duration(days: 30)),
      first: start,
      last: DateTime(start.year + 5, 12, 31),
    );
    if (!mounted || picked is! AppDatePicked) return;
    _change(working.copyWith(end: BudgetEnd.onDate(picked.date)));
  }

  /// "แก้เฉพาะรอบนี้": the shown period's own amount / note.
  Future<void> _editPeriod() async {
    final d = _detail;
    if (d == null || !d.budget.actions.edit) return;
    final r = await showBudgetPeriodSheet(context, period: d.budget.period);
    if (!mounted || r == null) return;
    setSaving(true);
    try {
      final next = await _repo.updatePeriod(
        d.budget.id,
        d.budget.period.id,
        amount: r.amount,
        note: r.note,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _detail = next);
      context.read<BudgetsCubit>().markStale();
      context.read<DashboardCubit>().markStale();
      setSaving(false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
    }
  }

  // ── Save / lifecycle ────────────────────────────────────────────────

  Future<void> _save() async {
    commitTextSession();
    final l = AppLocalizations.of(context)!;
    final formOk = _formKey.currentState?.validate() ?? false;
    final scopeOk = !working.scopeEmpty;
    if (!scopeOk) setState(() => _scopeMissing = true);
    if (!formOk || !scopeOk) return;

    final b = _budget;
    String? apply;
    if (b != null &&
        b.recurring &&
        working.recurring &&
        working.periodShapeDiffers(original)) {
      final picked = await showScopePrompt(
        context,
        title: l.bgScopeChoiceTitle,
        cancelLabel: l.linkedCancel,
        followingLabel: l.bgScopeFollowing,
        allLabel: l.bgScopeAllPeriods,
      );
      if (!mounted || picked == null) return;
      apply = picked == EditScope.all ? 'all' : 'following';
    }

    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      final write = working.toWrite();
      final d = b == null
          ? await _repo.create(write)
          : await _repo.update(b.id, write, apply: apply);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      context.read<BudgetsCubit>().markStale();
      context.read<DashboardCubit>().markStale();
      if (widget.isCreate) {
        commitSaved(working);
        leavePage();
        return;
      }
      _afterWrite(d);
      commitSaved(BudgetDraft.from(d.budget));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
    }
  }

  /// A lifecycle call (close / archive / restore): the page takes the
  /// returned state.
  Future<void> _run(Future<BudgetDetail> Function() call) async {
    setSaving(true);
    try {
      final d = await call();
      if (!mounted) return;
      _afterWrite(d);
      commitSaved(BudgetDraft.from(d.budget));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
    }
  }

  Future<void> _close(Budget b) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.bgCloseConfirmTitle,
      message: l.bgCloseConfirmBody,
      confirmLabel: l.bgClose,
    );
    if (!ok || !mounted) return;
    await _run(() => _repo.close(b.id));
  }

  Future<void> _archive(Budget b) async {
    final l = AppLocalizations.of(context)!;
    if (!b.isArchived) {
      final ok = await showConfirmDialog(
        context,
        title: l.budgetArchiveConfirmTitle,
        message: l.budgetArchiveConfirmBody,
        confirmLabel: l.budgetArchiveConfirmAction,
      );
      if (!ok || !mounted) return;
    }
    await _run(() => b.isArchived ? _repo.restore(b.id) : _repo.archive(b.id));
  }

  Future<void> _delete(Budget b) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.budgetDeleteConfirmTitle,
      message: l.budgetDeleteConfirmBody,
      confirmLabel: l.budgetDeleteConfirmAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setSaving(true);
    try {
      await _repo.delete(b.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    context.read<BudgetsCubit>().markStale();
    context.read<DashboardCubit>().markStale();
    // Pop without the discard prompt — the budget is gone.
    commitSaved(working);
    leavePage();
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!widget.isCreate && _detail == null) {
      return Scaffold(
        appBar: AppTopBar(title: l.budgetsTitle, showBack: true),
        extendBodyBehindAppBar: true,
        body: AsyncStateView.fallback(
          loading: _loading || _error == null,
          error: _error,
          onRetry: () => _load(first: true),
          notFound: EmptyView(
            icon: AppIcons.empty,
            title: l.budgetDetailNotFound,
            message: l.budgetDetailNotFoundMessage,
          ),
        ),
      );
    }
    final b = _budget;
    return BlocListener<TransactionsCubit, TransactionsState>(
      listenWhen: (a, c) => a.revision != c.revision,
      // A transaction write: this page's figures moved — one reload.
      listener: (_, _) {
        if (!widget.isCreate && !isSaving) _load(periodId: _periodId);
      },
      child: QuickCreatePresetScope(
        preset: _preset(),
        child: editScope(
          Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppTopBar(
              // Titles never change with the mode.
              title: b == null
                  ? l.budgetFormTitle
                  : (b.name.isEmpty ? l.budgetDetailFallbackTitle : b.name),
              showBack: true,
              editing: isEditing,
              onBack: handleBack,
            ),
            body: Form(
              key: _formKey,
              child: Builder(builder: (context) => _body(context, l, b)),
            ),
            bottomNavigationBar: isEditing
                ? editActionBar(onSave: _save)
                : null,
          ),
        ),
      ),
    );
  }

  /// The + presets the budget's category when it counts exactly one.
  QuickCreatePreset _preset() {
    final b = _budget;
    if (b == null || b.scope.categories.length != 1 || b.scope.all) {
      return QuickCreatePreset.none;
    }
    final id = b.scope.categories.first.category.id;
    Category? c;
    for (final x in context.read<CategoriesCubit>().state.categories) {
      if (x.id == id && x.type == CategoryType.expense) c = x;
    }
    return c == null ? QuickCreatePreset.none : QuickCreatePreset(category: c);
  }

  Widget _body(BuildContext context, AppLocalizations l, Budget? b) {
    final editing = isEditing;
    final recurring = working.recurring;
    final showTabs = recurring && !widget.isCreate;
    final setupTab = !showTabs || _tab == _Tab.setup || editing;
    final detail = _detail;
    return DetailPageBody(
      onRefresh: widget.isCreate ? null : () => _load(periodId: _periodId),
      topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
      bottomInset: AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
      hero: _hero(l, b),
      tabBar: showTabs && !editing
          ? AppTabBar<_Tab>(
              selected: _tab,
              onChanged: (t) => setState(() => _tab = t),
              tabs: [
                AppTab(value: _Tab.periods, label: l.bgTabPeriods),
                AppTab(value: _Tab.setup, label: l.bgTabSetup),
              ],
            )
          : null,
      sections: [
        if (detail != null && !setupTab || (detail != null && !recurring))
          ...budgetViewSections(
            context,
            detail: detail,
            allPeriods: _allPeriods,
            editingLocked: editing,
            moreBusy: _moreBusy,
            moreError: _moreError,
            onEditPeriod: _editPeriod,
            onOpenPeriod: (p) => _load(periodId: p.id),
            onMoreItems: _loadMoreItems,
            onMorePeriods: _loadAllPeriods,
          ),
        if (setupTab) ..._setupSections(l),
      ],
      manage: _manage(l, b),
      metaLines: b == null
          ? const []
          : detailMetaLines(
              context,
              createdAt: b.createdAt,
              updatedAt: b.updatedAt,
            ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────

  Widget _hero(AppLocalizations l, Budget? b) {
    final editing = isEditing;
    final palette = Theme.of(context).extension<AppColors>()!;
    final period = b?.period;
    final accent = (b != null && period != null)
        ? budgetToneColor(context, b, period)
        : working.iconCode.tintFor(palette);
    return HeaderCard(
      accent: accent,
      glyph: AppIcons.budget,
      onEdit: (editing || (b != null && !b.actions.edit)) ? null : _enterSetup,
      topRow: [
        if (b != null) ...[
          if (b.recurring && b.rule != null)
            AppChip(
              label: l.bgChipRecurring(budgetRuleLabel(l, b.rule!)),
              tone: AppChipTone.neutral,
              selected: true,
            ),
          if (period != null)
            AppChip(
              label: budgetRange(context, period.start, period.end),
              icon: AppIcons.date,
              tone: AppChipTone.neutral,
              selected: true,
            ),
          if (b.openEnded)
            AppChip(
              label: l.bgRowOpenEnded,
              tone: AppChipTone.neutral,
              selected: true,
            ),
          if (period != null && period.overridden)
            AppChip(
              label: l.bgPeriodOverridden,
              tone: AppChipTone.info,
              selected: true,
            ),
          ?budgetStatusChip(l, b),
        ],
      ],
      leading: EditableCircle(
        size: 52,
        onTap: editing ? _pickIcon : null,
        onLongPress: editing
            ? null
            : () {
                _enterSetup();
                _pickIcon();
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
        onEnterEdit: () => _enterSetup(focus: _nameFocus),
        onChanged: (v) => _onText(_Field.name, v),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? l.bgNameRequired : null,
      ),
      description: HeroDescription(
        controller: _ctrl[_Field.description]!,
        editing: editing,
        hint: l.commonDescription,
        maxLength: TextLimits.description,
        focusNode: _descriptionFocus,
        onEnterEdit: () => _enterSetup(focus: _descriptionFocus),
        onChanged: (v) => _onText(_Field.description, v),
      ),
      footer: (b == null || period == null)
          ? null
          : budgetHeroStats(context, b, period),
    );
  }

  // ── Setup sections ──────────────────────────────────────────────────

  List<Widget? Function(bool)> _setupSections(AppLocalizations l) {
    final editing = isEditing;
    final w = working;
    return [
      // Headless: merged into the page's top box.
      (first) => SectionCard(
        first: first,
        children: [
          if (editing)
            DetailStacked(
              label: w.recurring
                  ? l.budgetFormAmountLabel
                  : l.bgFieldAmountOnce,
              child: AmountInput(
                controller: _ctrl[_Field.amount]!,
                onChanged: (v) => _onText(_Field.amount, v),
                validator: (v) {
                  final n = AmountInput.parse(v);
                  return (n == null || n <= 0)
                      ? l.budgetFormAmountInvalid
                      : null;
                },
              ),
            )
          else
            DetailRow(
              label: w.recurring
                  ? l.budgetFormAmountLabel
                  : l.bgFieldAmountOnce,
              onLongPress: _enterSetup,
              trailing: MoneyText(AmountInput.parse(w.amount) ?? 0),
            ),
          DetailRow(
            label: l.bgFieldRecurring,
            helper: l.bgFieldRecurringHint,
            trailing: AppSwitch(
              value: w.recurring,
              semanticLabel: l.bgFieldRecurring,
              onChanged: (v) => _change(
                w.copyWith(
                  recurring: v,
                  // A one-off keeps no count end.
                  end: !v && w.end.kind == 'count'
                      ? const BudgetEnd.none()
                      : w.end,
                ),
              ),
            ),
          ),
          DetailStacked(
            label: l.commonNote,
            onLongPress: editing ? null : _enterSetup,
            child: AppInput.inline(
              editing: editing,
              controller: _ctrl[_Field.note]!,
              focusNode: _noteFocus,
              maxLines: 3,
              maxLength: TextLimits.note,
              viewHint: l.commonLongPressToEdit,
              onEnterEdit: () => _enterSetup(focus: _noteFocus),
              onChanged: (v) => _onText(_Field.note, v),
            ),
          ),
        ],
      ),
      (first) => SectionCard(
        first: first,
        title: l.bgSectionScope,
        description: l.bgScopeDescription,
        children: [
          DetailRow(
            label: l.bgScopeAll,
            trailing: AppSwitch(
              value: w.allScope,
              semanticLabel: l.bgScopeAll,
              onChanged: (v) {
                setState(() => _scopeMissing = false);
                _change(w.copyWith(allScope: v));
              },
            ),
          ),
          if (!w.allScope) ...[
            DetailRow.pick(
              label: l.bgScopeCategories,
              valueChips: [
                for (final c in w.categories)
                  _scopeChip(
                    c.includeChildren
                        ? '${c.category.name} ${l.bgScopeChildren}'
                        : c.category.name,
                    c.category.iconCode,
                    AppIcons.category,
                  ),
              ],
              emptyText: l.quickEventNone,
              onTap: _pickCategories,
            ),
            DetailRow.pick(
              label: l.bgScopeTags,
              helper: w.tags.isEmpty ? null : l.bgScopeTagsHint,
              valueChips: [
                for (final t in w.tags) _scopeChip(t, null, AppIcons.tag),
              ],
              emptyText: l.quickEventNone,
              onTap: _pickTags,
            ),
            DetailRow.pick(
              label: l.bgScopeWallets,
              valueChips: [
                for (final x in w.wallets)
                  _scopeChip(x.name, x.iconCode, AppIcons.wallet),
              ],
              emptyText: l.quickEventNone,
              error: _scopeMissing && w.scopeEmpty ? l.bgScopeRequired : null,
              onTap: _pickWallets,
            ),
          ],
        ],
      ),
      (first) => SectionCard(
        first: first,
        title: l.bgSectionPeriod,
        children: [
          if (w.recurring)
            DetailRow.pick(
              label: l.bgFieldRepeat,
              value: budgetRuleLabel(l, w.rule),
              emptyText: l.quickEventNone,
              onTap: _pickRule,
            ),
          DetailRow.pick(
            label: l.bgFieldStart,
            value: budgetDate(context, w.start),
            emptyText: l.quickEventNone,
            onTap: _pickStart,
          ),
          DetailRow.pick(
            label: l.bgFieldEnd,
            value: switch (w.end.kind) {
              'date' => budgetDate(context, w.end.date!),
              'count' => l.bgEndPeriods(w.end.count ?? 0),
              _ => l.bgEndNone,
            },
            emptyText: l.quickEventNone,
            onTap: _pickEnd,
          ),
        ],
      ),
      (first) => SectionCard(
        first: first,
        title: l.bgSectionWarn,
        children: [
          OptionMenuAnchor<int>(
            selected: w.warnPct ?? 0,
            options: [
              for (final p in const [70, 80, 90, 95])
                SheetOption(value: p, label: l.bgWarnPct(p)),
              SheetOption(value: 0, label: l.bgWarnOff),
            ],
            onSelected: (p) => _change(
              p == 0 ? w.copyWith(clearWarn: true) : w.copyWith(warnPct: p),
            ),
            builder: (context, toggle) => DetailRow.pick(
              label: l.bgFieldWarn,
              helper: l.bgWarnHint,
              value: w.warnPct == null ? l.bgWarnOff : l.bgWarnPct(w.warnPct!),
              emptyText: l.quickEventNone,
              onTap: toggle,
            ),
          ),
        ],
      ),
    ];
  }

  // ── Manage ──────────────────────────────────────────────────────────

  /// One counted thing as a chip: its icon + colour.
  Widget _scopeChip(String label, IconCode? code, IconData fallback) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return AppChip(
      label: label,
      icon: IconRegistry.get(code?.icon, fallback: fallback),
      color: code.tintFor(palette),
      size: ChipSize.chip,
      maxWidth: 200,
    );
  }

  Widget? _manage(AppLocalizations l, Budget? b) {
    if (b == null) return null;
    final editing = isEditing;
    final close = !editing && b.actions.close;
    if (!close && !editing) return null;
    return ManageSection(
      extraActions: [
        if (close)
          ManageAction(
            label: l.bgClose,
            icon: AppIcons.close,
            onTap: isSaving ? null : () => _close(b),
          ),
      ],
      archiveLabel: editing
          ? (b.isArchived ? l.bgRestore : l.budgetDetailArchive)
          : null,
      onArchive:
          !editing || isSaving || !(b.actions.archive || b.actions.restore)
          ? null
          : () => _archive(b),
      deleteLabel: editing ? l.budgetDeleteThis : null,
      onDelete: !editing || isSaving ? null : () => _delete(b),
    );
  }
}
