import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/user_currency.dart';
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
import '../budget_scope_pickers.dart';
import '../cubit/budgets_cubit.dart';

class BudgetDetailPage extends StatefulWidget {
  const BudgetDetailPage({this.id, this.startEditing = false, super.key});

  final String? id;

  final bool startEditing;

  bool get isCreate => id == null;

  @override
  State<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

enum _Tab { items, periods }

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

  ApiException? _error;

  ApiException? _refreshError;
  _Tab _tab = _Tab.items;

  BudgetPeriodPage? _allPeriods;
  bool _itemsBusy = false;
  Object? _itemsError;
  bool _periodsBusy = false;
  Object? _periodsError;

  bool _scopeMissing = false;

  BudgetsRepository get _repo => BudgetsRepository.of(context);
  Budget? get _budget => _detail?.budget;
  bool get _canEdit => _budget?.actions.edit ?? true;

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
      setState(() {
        _detail = d;
        _error = null;
        _refreshError = null;
        _allPeriods = null;
      });
      if (!isEditing) resetDraft(BudgetDraft.from(d.budget));
      if (first && widget.startEditing && d.budget.actions.edit) enterEdit();
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

  void _afterWrite(BudgetDetail d) {
    setState(() {
      _detail = d;
      _allPeriods = null;
    });
    context.read<BudgetsCubit>().markStale();
    context.read<DashboardCubit>().markStale();
  }

  Future<void> _loadMoreItems() async {
    final d = _detail;
    if (d == null || !d.items.hasMore || _itemsBusy) return;
    setState(() {
      _itemsBusy = true;
      _itemsError = null;
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
      if (mounted) setState(() => _itemsError = ApiException.from(e, st));
    } finally {
      if (mounted) setState(() => _itemsBusy = false);
    }
  }

  Future<void> _loadAllPeriods() async {
    final d = _detail;
    if (d == null || _periodsBusy) return;
    setState(() {
      _periodsBusy = true;
      _periodsError = null;
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
      if (mounted) setState(() => _periodsError = ApiException.from(e, st));
    } finally {
      if (mounted) setState(() => _periodsBusy = false);
    }
  }

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

  void _change(BudgetDraft next) {
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

  Future<void> _pickRule() async {
    final r = await showRecurrenceSheet(
      context,
      initial: working.kitRule,
      simple: true,
    );
    if (!mounted || r == null) return;
    _change(working.withKitRule(r));
  }

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

  Future<void> _editPeriod(BudgetPeriod p) async {
    final d = _detail;
    if (d == null || !d.budget.actions.edit || isSaving) return;
    final l = AppLocalizations.of(context)!;
    final r = await showPeriodLimitSheet(
      context,
      title: l.bgPeriodEditTitle,
      amountLabel: l.bgPeriodAmountField,
      noteLabel: l.commonNote,
      saveLabel: l.commonSave,
      symbol: context.readUserCurrencySymbol,
      amount: p.amount,
      baseAmount: p.baseAmount,
      overridden: p.overridden,
      resetLabel: l.fpBudgetsPeriodReset(budgetRowMoney(context, p.baseAmount)),
      note: p.note,
    );
    if (!mounted || r == null) return;
    setSaving(true);
    try {
      final next = await _repo.updatePeriod(
        d.budget.id,
        p.id,
        amount: r.amount,
        note: r.note,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _detail = (_detail ?? d).afterPeriodWrite(next);
        _allPeriods = _allPeriods?.replace(next.budget.period);
      });
      context.read<BudgetsCubit>().markStale();
      context.read<DashboardCubit>().markStale();
      setSaving(false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
    }
  }

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
    setSaving(true);
    final BudgetDeletePreview? preview;
    try {
      preview = (await _repo.get(b.id, deletePreview: true)).deletePreview;
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    setSaving(false);
    final ok = await showConfirmDialog(
      context,
      title: l.budgetDeleteConfirmTitle,
      message: preview == null
          ? l.budgetDeleteConfirmBody
          : l.fpM5BudgetDeleteBody(
              preview.periods,
              preview.overriddenPeriods,
              preview.categories,
              preview.wallets,
            ),
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
      listenWhen: (a, c) =>
          a.revision != c.revision ||
          !identical(a.transactions, c.transactions),
      listener: (_, _) {
        if (!widget.isCreate && !isSaving) _load();
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
              child: Builder(
                builder: (context) {
                  final barInset = MediaQuery.paddingOf(context).top;
                  final bottom =
                      AppSpacing.huge + MediaQuery.paddingOf(context).bottom;
                  final d = _detail;
                  return (d == null || isEditing)
                      ? _editBody(context, l, b, barInset, bottom)
                      : _viewBody(context, l, d, barInset, bottom);
                },
              ),
            ),
            bottomNavigationBar: isEditing
                ? editActionBar(onSave: _save)
                : null,
          ),
        ),
      ),
    );
  }

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

  Widget _viewBody(
    BuildContext context,
    AppLocalizations l,
    BudgetDetail d,
    double barInset,
    double bottom,
  ) {
    final b = d.budget;
    final settings = _settings(l, editing: false);
    final note = NoteSection(
      label: l.commonNote,
      editing: false,
      text: b.note,
      hint: l.commonLongPressToEdit,
      onLongPress: _canEdit ? () => enterEdit(focus: _noteFocus) : null,
    );
    final meta = detailMetaLines(
      context,
      createdAt: b.createdAt,
      updatedAt: b.updatedAt,
    );
    final banner = _refreshError == null
        ? null
        : AppMessage(tone: Tone.danger, message: _refreshError!.message);

    if (!b.recurring) {
      return DetailLayout(
        topInset: barInset + AppSpacing.lg,
        bottomInset: bottom,
        onRefresh: _load,
        hero: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (banner != null) ...[
              banner,
              SizedBox(height: HeroMetrics.of(context).after),
            ],
            _viewHero(l, d),
          ],
        ),
        settings: settings,
        note: note,
        records: SectionCard(
          title: l.fpBudgetsTabItems,
          children: [
            if (d.items.items.isEmpty)
              EmptyView.compact(message: l.bgItemsEmpty)
            else
              ..._itemRows(l, d),
            if (d.items.hasMore)
              DetailRow.pick(
                label: l.bgItemsMore,
                emptyText: l.quickEventNone,
                error: _itemsError == null ? null : '$_itemsError',
                onTap: _itemsBusy ? null : _loadMoreItems,
              ),
          ],
        ),
        metaLines: meta,
      );
    }

    return TabbedDetailBody<_Tab>(
      hero: _viewHero(l, d),
      belowHero: [?banner, settings, note],
      tabs: [
        AppTab(value: _Tab.items, label: l.fpBudgetsTabItems),
        AppTab(value: _Tab.periods, label: l.fpBudgetsTabPeriods),
      ],
      selected: _tab,
      onChanged: (t) => setState(() => _tab = t),
      compactBar: _compactBar(d),
      tabBuilder: (context, t) => switch (t) {
        _Tab.items => _itemsTab(l, d, meta),
        _Tab.periods => _periodsTab(l, d),
      },
    );
  }

  CompactHeroBar _compactBar(BudgetDetail d) {
    final b = d.budget;
    final p = b.period;
    final over = p.overBy > 0;
    return CompactHeroBar(
      style: HeroStyle.tinted(
        color: budgetTint(context, b),
        glyph: AppIcons.budget,
      ),
      leading: IconDisplay(
        type: IconType.category,
        size: 28,
        iconCode: b.iconCode,
      ),
      title: AppText(b.name, role: AppTextRole.title),
      trailing: MoneyText(
        over ? p.overBy : p.remaining,
        symbol: context.readUserCurrencySymbol,
        style: AppTypography.of(
          context,
          AppTextRole.money,
        )?.copyWith(color: budgetToneColor(context, b, p)),
      ),
    );
  }

  Widget _viewHero(AppLocalizations l, BudgetDetail d) {
    final b = d.budget;
    final p = b.period;
    final f = d.forecast;
    final symbol = context.readUserCurrencySymbol;
    final accent = budgetToneColor(context, b, p);
    final over = p.overBy > 0;
    final range = budgetRange(context, p.start, p.end);
    final status = b.state == BudgetState.active
        ? null
        : budgetStatusChip(l, b);
    return HeroCard(
      style: HeroStyle.tinted(
        color: budgetTint(context, b),
        glyph: AppIcons.budget,
      ),
      chips: [
        ?status,
        if (b.recurring && b.rule != null)
          AppChip(
            label: l.bgChipRecurring(budgetRuleLabel(l, b.rule!)),
            selected: true,
          ),
        AppChip(
          label: f.elapsedDays != null && f.totalDays != null
              ? l.fpBudgetsRangeDay(range, f.elapsedDays!, f.totalDays!)
              : range,
          icon: AppIcons.date,
          selected: true,
        ),
        if (b.openEnded) AppChip(label: l.bgRowOpenEnded, selected: true),
        if (p.overridden)
          AppChip(
            label: l.bgPeriodOverridden,
            tone: AppChipTone.info,
            selected: true,
          ),
      ],
      onEdit: _canEdit ? enterEdit : null,
      icon: EditableCircle(
        size: 40,
        onLongPress: _canEdit
            ? () {
                enterEdit();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _pickIcon();
                });
              }
            : null,
        child: IconDisplay(
          type: IconType.category,
          size: 40,
          iconCode: b.iconCode,
        ),
      ),
      description: HeroDescription(
        controller: _ctrl[_Field.description]!,
        editing: false,
        focusNode: _descriptionFocus,
        hint: l.commonDescription,
        maxLength: TextLimits.description,
        onEnterEdit: _canEdit
            ? () => enterEdit(focus: _descriptionFocus)
            : null,
      ),
      number: HeroNumber(
        label: over ? l.fpBudgetsOverLabel : l.fpBudgetsLeftLabel,
        value: MoneyText(over ? p.overBy : p.remaining, symbol: symbol),
        color: accent,
        target: l.fpBudgetsLimitTarget(budgetRowMoney(context, p.amount)),
      ),
      bar: HeroBar(
        value: p.usedRatio,
        expected: p.expected > 0 ? p.expectedRatio : null,
        marker: f.pacePct == null ? null : f.pacePct! / 100,
        color: accent,
        left: l.fpBudgetsUsedCaption(budgetRowMoney(context, p.used)),
        right: f.pacePct == null ? null : l.fpBudgetsPaceCaption(f.pacePct!),
      ),
      tiles: _tiles(l, d),
    );
  }

  List<Widget> _tiles(AppLocalizations l, BudgetDetail d) {
    final f = d.forecast;
    Widget tile(String label, String value, [SummaryTileTone? tone]) =>
        SummaryTileView(
          tile: SummaryTile(
            label: label,
            value: value,
            tone: tone ?? SummaryTileTone.neutral,
          ),
        );
    return [
      if (f.dailyAllowance != null)
        tile(
          l.fpBudgetsTileDaily,
          budgetRowMoney(context, f.dailyAllowance!),
          SummaryTileTone.green,
        ),
      if (f.projectedEnd != null)
        tile(
          l.fpBudgetsTileProjected,
          budgetRowMoney(context, f.projectedEnd!),
          (f.forecastOverBy ?? 0) > 0 ? SummaryTileTone.amber : null,
        ),
      if (f.daysLeft != null)
        tile(l.fpBudgetsTileDaysLabel, l.fpBudgetsDaysValue(f.daysLeft!)),
      if (f.avgMonthly != null)
        tile(l.bgTileAvgMonthly, budgetRowMoney(context, f.avgMonthly!)),
      if (f.thisMonth != null)
        tile(l.bgTileThisMonth, budgetRowMoney(context, f.thisMonth!)),
    ].take(4).toList();
  }

  Widget _itemsTab(AppLocalizations l, BudgetDetail d, List<String> meta) {
    return ListPageBody(
      loading: false,
      error: null,
      isEmpty: d.items.items.isEmpty,
      onRetry: _load,
      empty: EmptyView.compact(message: l.bgItemsEmpty),
      rowDividers: true,
      topInset: 0,
      loadingMore: _itemsBusy,
      loadMoreError: _itemsError,
      onRetryMore: _loadMoreItems,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.items.hasMore)
            AppButton(
              label: l.bgItemsMore,
              variant: AppButtonVariant.outlined,
              onPressed: _itemsBusy ? null : _loadMoreItems,
            ),
          DetailMeta(lines: meta),
        ],
      ),
      children: _itemRows(l, d),
    );
  }

  Widget _periodsTab(AppLocalizations l, BudgetDetail d) {
    final b = d.budget;
    final periods = _allPeriods?.periods ?? d.periods.periods;
    final more = _allPeriods?.hasMore ?? d.periods.hasMore;
    return ListPageBody(
      loading: false,
      error: null,
      isEmpty: periods.isEmpty,
      onRetry: _load,
      empty: EmptyView.compact(message: l.fpBudgetsTabPeriods),
      rowDividers: true,
      topInset: 0,
      loadingMore: _periodsBusy,
      loadMoreError: _periodsError,
      onRetryMore: _loadAllPeriods,
      footer: more
          ? AppButton(
              label: l.bgPeriodsAll,
              variant: AppButtonVariant.outlined,
              onPressed: _periodsBusy ? null : _loadAllPeriods,
            )
          : null,
      children: [
        for (final x in periods)
          ProgressCard.compact(
            title: budgetPeriodTitle(context, b, x),
            badge: _periodBadge(l, b, x),
            value: x.usedRatio,
            expected: x.expected > 0 ? x.expectedRatio : null,
            tone: budgetRowTone(x),
            paceMarker: x.isCurrent && d.forecast.pacePct != null
                ? d.forecast.pacePct! / 100
                : null,
            label: l.bgRowUsed(
              budgetRowMoney(context, x.used),
              budgetRowMoney(context, x.amount),
            ),
            struckLabel: x.overridden && x.amount != x.baseAmount
                ? budgetRowMoney(context, x.baseAmount)
                : null,
            percentText: '${x.pct}%',
            onTap: b.actions.edit ? () => _editPeriod(x) : null,
          ),
      ],
    );
  }

  Widget? _periodBadge(AppLocalizations l, Budget b, BudgetPeriod x) {
    if (x.isCurrent) {
      return AppChip(label: l.bgPeriodNow, size: ChipSize.mini, selected: true);
    }
    if (x.overridden) {
      return AppChip(
        label: l.bgPeriodOverridden,
        size: ChipSize.mini,
        selected: true,
        tone: AppChipTone.info,
      );
    }
    return budgetStatusChip(l, b, period: x, size: ChipSize.mini);
  }

  List<Widget> _itemRows(AppLocalizations l, BudgetDetail d) {
    final out = <Widget>[];
    DateTime? last;
    for (final i in d.items.items) {
      final date = i.date;
      if (date != null && date != last) {
        out.add(DateGroupHeader(label: budgetDate(context, date)));
        last = date;
      }
      out.add(_itemRow(l, d.budget, i));
    }
    return out;
  }

  Widget _itemRow(AppLocalizations l, Budget b, BudgetItem i) {
    final title = (i.description ?? '').isNotEmpty
        ? i.description!
        : (i.category?.name ?? i.event?.name ?? '—');
    final reason = budgetReasonText(l, b, i);
    return TxRow(
      leading: IconDisplay(
        type: IconType.category,
        size: 36,
        iconCode: i.category?.iconCode ?? i.event?.iconCode,
      ),
      title: title,
      amount: -i.amount,
      walletLabel: i.account?.name,
      walletIcon: i.account == null
          ? null
          : IconDisplay(
              type: IconType.account,
              size: 14,
              iconCode: i.account!.iconCode,
            ),
      source: AppChip(
        label: i.event != null && i.source == BudgetSource.event
            ? '${l.bgSourceEvent} ${i.event!.name}'
            : budgetSourceLabel(l, i.source),
        size: ChipSize.mini,
        tone: AppChipTone.neutral,
      ),
      category: i.category != null && i.category!.name != title
          ? i.category!.name
          : null,
      meta: [?reason],
      recurring: i.recurringItemId != null,
      progress: i.recurringSeq == null
          ? null
          : (i.recurringTotal == null
                ? '${i.recurringSeq}'
                : '${i.recurringSeq}/${i.recurringTotal}'),
      dimmed: i.expected,
      onTap: i.kind == 'transaction'
          ? () => openPage(context, '/transactions/${i.id}')
          : null,
    );
  }

  Widget _settings(AppLocalizations l, {required bool editing}) {
    final w = working;
    final scope = budgetScopeSummary(
      l,
      all: w.allScope,
      categories: w.categories,
      tags: w.tags,
      wallets: w.wallets,
    );
    final warn = w.warnPct == null ? l.bgWarnOff : l.bgWarnPct(w.warnPct!);
    return SettingsSection(
      title: l.settingsTitle,
      description: l.fpBudgetsSettingsDesc,
      children: [
        if (!editing)
          SettingSummaryRow(
            label: l.fpBudgetsCountsWhat,
            summary: scope ?? l.quickEventNone,
            onTap: _canEdit ? enterEdit : null,
          )
        else ...[
          SettingToggleRow(
            label: l.bgScopeAll,
            value: w.allScope,
            submits: false,
            onChanged: (v) {
              setState(() => _scopeMissing = false);
              _change(w.copyWith(allScope: v));
            },
          ),
          if (!w.allScope) ...[
            SettingSummaryRow(
              label: l.bgScopeCategories,
              summary: w.categories.isEmpty
                  ? l.quickEventNone
                  : budgetScopeSummary(
                      l,
                      all: false,
                      categories: w.categories,
                      tags: const [],
                      wallets: const [],
                    ),
              onTap: _pickCategories,
            ),
            SettingSummaryRow(
              label: l.bgScopeTags,
              summary: w.tags.isEmpty ? l.quickEventNone : w.tags.join(', '),
              onTap: _pickTags,
            ),
            SettingSummaryRow(
              label: l.bgScopeWallets,
              summary: w.wallets.isEmpty
                  ? l.quickEventNone
                  : w.wallets.map((x) => x.name).join(', '),
              error: _scopeMissing && w.scopeEmpty ? l.bgScopeRequired : null,
              onTap: _pickWallets,
            ),
          ],
        ],
        if (editing)
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
            builder: (context, toggle) => SettingDropdownRow(
              label: l.fpBudgetsWarnAt,
              value: warn,
              onTap: toggle,
            ),
          )
        else
          SettingSummaryRow(
            label: l.fpBudgetsWarnAt,
            summary: warn,
            onTap: _canEdit ? enterEdit : null,
          ),
        SettingToggleRow(
          label: l.fpBudgetsRepeat,
          caption: l.fpBudgetsRepeatCaption,
          value: w.recurring,
          submits: false,
          onChanged: _canEdit
              ? (v) => _change(
                  w.copyWith(
                    recurring: v,
                    end: !v && w.end.kind == 'count'
                        ? const BudgetEnd.none()
                        : w.end,
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Widget _editBody(
    BuildContext context,
    AppLocalizations l,
    Budget? b,
    double barInset,
    double bottom,
  ) {
    final w = working;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = w.iconCode.tintFor(palette);
    return DetailLayout(
      topInset: barInset + AppSpacing.lg,
      bottomInset: bottom,
      onRefresh: widget.isCreate ? null : _load,
      hero: HeroCard(
        style: HeroStyle.tinted(color: accent, glyph: AppIcons.budget),
        editing: true,
        chips: [
          if (w.recurring)
            AppChip(
              label: l.bgChipRecurring(budgetRuleLabel(l, w.rule)),
              selected: true,
              trailing: AppChipTrailing.dropdown,
              onTap: _pickRule,
            ),
        ],
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
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.bgNameRequired : null,
        ),
        description: HeroDescription(
          controller: _ctrl[_Field.description]!,
          editing: true,
          hint: l.commonDescription,
          maxLength: TextLimits.description,
          focusNode: _descriptionFocus,
          onChanged: (v) => _onText(_Field.description, v),
        ),
        amountField: HeroAmountField(
          controller: _ctrl[_Field.amount]!,
          label: l.fpBudgetsLimitLabel,
          accent: accent,
          symbol: context.readUserCurrencySymbol,
          onChanged: (v) => _onText(_Field.amount, v),
          validator: (v) {
            final n = AmountInput.parse(v);
            return (n == null || n <= 0) ? l.budgetFormAmountInvalid : null;
          },
        ),
      ),
      info: InfoBox(
        rows: [
          InfoRow(
            label: l.bgFieldStart,
            value: budgetDate(context, w.start),
            showChevron: true,
            onTap: _pickStart,
          ),
          InfoRow(
            label: l.bgFieldEnd,
            value: switch (w.end.kind) {
              'date' => budgetDate(context, w.end.date!),
              'count' => l.bgEndPeriods(w.end.count ?? 0),
              _ => l.bgEndNone,
            },
            showChevron: true,
            onTap: _pickEnd,
          ),
        ],
      ),
      settings: _settings(l, editing: true),
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
            onChanged: (v) => _onText(_Field.note, v),
          ),
        ),
      ),
      endZone: b == null ? null : _endZone(l, b),
      metaLines: b == null
          ? const []
          : detailMetaLines(
              context,
              createdAt: b.createdAt,
              updatedAt: b.updatedAt,
            ),
    );
  }

  Widget _endZone(AppLocalizations l, Budget b) {
    final canArchive = b.isArchived ? b.actions.restore : b.actions.archive;
    return EndZone(
      actions: [
        if (b.actions.close)
          EndZoneAction(
            kind: EndZoneKind.close,
            label: l.bgClose,
            consequence: l.fpBudgetsCloseConsequence,
            onTap: isSaving ? null : () => _close(b),
          ),
        if (canArchive)
          EndZoneAction(
            kind: EndZoneKind.archive,
            label: b.isArchived ? l.bgRestore : l.budgetDetailArchive,
            consequence: b.isArchived
                ? l.fpBudgetsRestoreConsequence
                : l.fpBudgetsArchiveConsequence,
            onTap: isSaving ? null : () => _archive(b),
          ),
        EndZoneAction(
          kind: EndZoneKind.delete,
          label: l.budgetDeleteThis,
          consequence: l.fpBudgetsDeleteConsequence,
          onTap: isSaving ? null : () => _delete(b),
        ),
      ],
    );
  }
}
