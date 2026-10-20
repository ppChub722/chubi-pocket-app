import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../recurring/domain/recurrence_rule.dart' show today;
import '../../../recurring/presentation/occurrence_actions.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../../tags/presentation/widgets/tag_picker.dart';
import '../../../transactions/domain/refs.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../data/budgets_repository.dart';
import '../../domain/budget.dart';
import '../../domain/budget_detail.dart';
import '../../domain/budget_period.dart';
import '../budget_draft.dart';
import '../budget_labels.dart';
import '../budget_scope_pickers.dart';

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
    final picked = await TagPicker.many(
      context,
      selected: selectedIds.toSet(),
      title: l.bgScopeTags,
    );
    if (picked == null || !mounted) return;
    setState(() => _scopeMissing = false);
    _change(working.copyWith(tags: [for (final t in picked.tags) t.name]));
  }

  Future<void> _pickWallets() async {
    final ids = await showBudgetWalletsPicker(
      context,
      selected: [for (final w in working.wallets) w.id],
    );
    if (!mounted || ids == null) return;
    // Every wallet, archived ones too: a ticked archived wallet keeps its name.
    final accounts = context.read<AccountsCubit>().state.allAccounts;
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
    final strips = _scopeStrips(l);
    final scope = strips.isEmpty
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, s) in strips.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                s,
              ],
            ],
          );
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
        tags: scope,
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
      belowHero: [?banner, ?scope, note],
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

  AppCompactHeroCard _compactBar(BudgetDetail d) {
    final b = d.budget;
    final p = b.period;
    final over = p.overBy > 0;
    return AppCompactHeroCard(
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

  /// The ring hero: the round box beside the edit button, a plan status, the
  /// ring with what is left, and the facts beside it.
  Widget _viewHero(AppLocalizations l, BudgetDetail d) {
    final b = d.budget;
    final p = b.period;
    final f = d.forecast;
    final symbol = context.readUserCurrencySymbol;
    String money(num v) => budgetRowMoney(context, v);
    // Only a warning / over period paints over the card's own color.
    final toneColor = p.tone == BudgetTone.neutral
        ? null
        : budgetToneColor(context, b, p);
    final over = p.overBy > 0;
    final active = b.state == BudgetState.active;
    final status = active ? null : budgetStatusChip(l, b);
    final pace = f.pacePct;
    final warn = b.warnPct;
    final planned = pace == null ? null : p.amount * pace / 100;
    final ahead = planned == null ? 0.0 : p.used - planned;
    final description = (b.description ?? '').trim();

    final days = [
      if (f.daysLeft != null) l.bgRowDaysLeft(f.daysLeft!),
      if (f.elapsedDays != null && f.totalDays != null)
        '${f.elapsedDays}/${f.totalDays}',
    ];
    final box = HeroInfoBox(
      key: const ValueKey('heroRound'),
      icon: b.recurring ? AppIcons.recurring : AppIcons.date,
      title: b.recurring && b.rule != null
          ? _roundText(l, working)
          : (b.openEnded ? l.bgRowOpenEnded : l.bgRowOneOff),
      subtitle: days.isEmpty ? null : days.join(' | '),
    );
    final (statusKind, statusLabel) = over
        ? (StatusKind.over, l.bgStatusOverBy(money(p.overBy)))
        : ahead >= 1
        ? (StatusKind.warning, l.bgStatusAhead(money(ahead)))
        : p.status == BudgetStatus.warn
        ? (StatusKind.warning, l.bgStatusWarn)
        : (StatusKind.active, l.bgStatusOnPlan);
    final end = p.end;
    final next = b.recurring && end != null
        ? DateTime(end.year, end.month, end.day + 1)
        : null;
    return AppHeroCard(
      style: HeroStyle.tinted(
        color: budgetTint(context, b),
        glyph: AppIcons.budget,
      ),
      header: status == null ? null : HeroHeader(leading: [status]),
      content: [
        HeroIdentity(
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
          name: Text(
            b.name.isEmpty ? l.budgetDetailFallbackTitle : b.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          description: description.isEmpty
              ? null
              : HeroDescription(
                  controller: _ctrl[_Field.description]!,
                  editing: false,
                  focusNode: _descriptionFocus,
                  hint: l.commonDescription,
                  maxLength: TextLimits.description,
                  onEnterEdit: _canEdit
                      ? () => enterEdit(focus: _descriptionFocus)
                      : null,
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              box,
              if (_canEdit) ...[
                const SizedBox(width: AppSpacing.sm),
                CardActionButton(
                  key: const ValueKey('heroEdit'),
                  icon: AppIcons.edit,
                  tooltip: UiConfig.stringsOf(context).edit,
                  onTap: enterEdit,
                ),
              ],
            ],
          ),
        ),
        HeroRingRow(
          ring: (size) => HeroRing(
            size: size,
            stroke: 14,
            value: p.usedRatio,
            expected: p.expected > 0 ? p.expectedRatio : null,
            marker: pace == null ? null : pace / 100,
            alert: warn == null ? null : warn / 100,
            color: toneColor,
            label: over ? l.fpBudgetsOverLabel : l.fpBudgetsLeftLabel,
            amount: MoneyText(over ? p.overBy : p.remaining, symbol: symbol),
            target: l.bgRingOf(money(p.amount)),
          ),
          facts: [
            HeroFact(l.bgFactUsed, money(p.used), icon: AppIcons.receipt),
            if (p.expected > 0)
              HeroFact(
                l.bgFactPending,
                money(p.expected),
                icon: AppIcons.scheduled,
              ),
            if (planned != null)
              HeroFact(
                l.bgFactPlanToday,
                money(planned),
                icon: AppIcons.trendingUp,
              ),
            if (over && next != null)
              HeroFact(
                l.bgFactNextRound,
                DateFormatter.short(
                  next,
                  locale: Localizations.localeOf(context).languageCode,
                ),
                icon: AppIcons.recurring,
              )
            else if (f.dailyAllowance != null)
              HeroFact(
                l.fpBudgetsTileDaily,
                money(f.dailyAllowance!),
                icon: AppIcons.date,
              ),
          ],
        ),
        if (active || p.overridden)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (active)
                StatusChip(
                  key: const ValueKey('heroPlanStatus'),
                  label: statusLabel,
                  kind: statusKind,
                  size: ChipSize.chip,
                ),
              if (p.overridden)
                StatusChip.tone(
                  label: l.bgPeriodOverridden,
                  tone: AppChipTone.neutral,
                  size: ChipSize.chip,
                ),
            ],
          ),
      ],
    );
  }

  Widget _itemsTab(AppLocalizations l, BudgetDetail d, List<String> meta) {
    return ListPageBody(
      loading: false,
      error: null,
      isEmpty: d.items.items.isEmpty,
      onRetry: _load,
      empty: EmptyView.compact(message: l.bgItemsEmpty),
      rowCards: true,
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
    final dayTotal = <DateTime, double>{};
    for (final i in d.items.items) {
      final date = i.date;
      if (date != null) dayTotal[date] = (dayTotal[date] ?? 0) - i.amount;
    }
    DateTime? last;
    for (final i in d.items.items) {
      final date = i.date;
      if (date != null && date != last) {
        out.add(
          DateGroupHeader(
            label: budgetDate(context, date),
            total: dayTotal[date],
          ),
        );
        last = date;
      }
      out.add(_itemRow(l, i));
    }
    return out;
  }

  Widget _itemRow(AppLocalizations l, BudgetItem i) {
    final title = (i.description ?? '').isNotEmpty
        ? i.description!
        : (i.category?.name ?? i.event?.name ?? '—');
    final palette = Theme.of(context).extension<AppColors>()!;
    final walletCode = i.account?.iconCode;
    final walletFill = walletCode?.background != null
        ? walletCode!.bgColorFor(palette)
        : null;
    final walletOnFill =
        walletFill != null && (walletCode?.iconColors.isNotEmpty ?? false)
        ? resolveColor(walletCode!.iconColors.first, palette)
        : null;
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
      walletFill: walletFill,
      walletOnFill: walletOnFill,
      walletGlyph: walletFill == null
          ? null
          : IconRegistry.get(
              walletCode!.icon,
              fallback: IconType.account.fallbackIcon,
            ),
      source: i.source == BudgetSource.normal
          ? null
          : AppChip(
              label: i.event != null && i.source == BudgetSource.event
                  ? '${l.bgSourceEvent} ${i.event!.name}'
                  : budgetSourceLabel(l, i.source),
              size: ChipSize.mini,
              tone: AppChipTone.neutral,
            ),
      category: i.category != null && i.category!.name != title
          ? i.category!.name
          : null,
      tags: [
        for (final t in i.tags)
          TextSpan(
            text: '#$t',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tagColor(i.tagIcons[t], palette),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
      recurring: i.recurringItemId != null,
      progress: i.recurringSeq == null
          ? null
          : (i.recurringTotal == null
                ? '${i.recurringSeq}'
                : '${i.recurringSeq}/${i.recurringTotal}'),
      dimmed: i.expected,
      onTap: switch (i.kind) {
        'transaction' => () => openPage(context, '/transactions/${i.id}'),
        'recurring_item'
            when i.recurringItemId != null ||
                (i.ruleId != null && i.slot != null) =>
          () => openOccurrence(
            context,
            itemId: i.recurringItemId,
            ruleId: i.ruleId,
            slot: i.slot,
            onChanged: (_) => _load(),
          ),
        _ => null,
      },
    );
  }

  String _endText(AppLocalizations l, BudgetDraft w) => switch (w.end.kind) {
    'date' => budgetDate(context, w.end.date!),
    'count' => l.bgEndPeriods(w.end.count ?? 0),
    _ => l.bgEndNone,
  };

  /// "รายสัปดาห์ ทุกวันจันทร์".
  String _roundText(AppLocalizations l, BudgetDraft w) {
    final days = recurrenceLabel(l, w.kitRule);
    final n = w.rule.interval < 1 ? 1 : w.rule.interval;
    return switch (w.rule.freq) {
      'daily' => budgetRuleLabel(l, w.rule),
      'weekly' ||
      'monthly' when n == 1 => '${budgetRuleLabel(l, w.rule)} $days',
      _ => days,
    };
  }

  String _roundEndText(AppLocalizations l, BudgetDraft w) =>
      switch (w.end.kind) {
        'date' => l.bgEndOnDate(budgetDate(context, w.end.date!)),
        'count' => l.bgEndPeriods(w.end.count ?? 0),
        _ => l.bgEndNone,
      };

  /// The round as chips: its days, the first period's dates, how it ends.
  Widget _roundChips(AppLocalizations l, BudgetDraft w) {
    var end = budgetFirstPeriodEnd(w.rule, w.start);
    final stop = w.end.kind == 'date' ? w.end.date : null;
    if (stop != null && stop.isBefore(end)) end = stop;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        AppChip(
          label: _roundText(l, w),
          icon: AppIcons.recurring,
          tone: AppChipTone.primary,
          size: ChipSize.chip,
        ),
        AppChip(
          label: budgetRangeShort(context, w.start, end),
          icon: AppIcons.date,
          tone: AppChipTone.primary,
          size: ChipSize.chip,
        ),
        AppChip(label: _roundEndText(l, w), size: ChipSize.chip),
      ],
    );
  }

  /// Edit mode only (view shows the period in the hero): start, then a check
  /// for whether it repeats beside the round, or the end date when it doesn't.
  Widget _periodSection(AppLocalizations l) {
    final w = working;
    void toggleRepeat() => _change(
      w.copyWith(
        recurring: !w.recurring,
        end: w.recurring && w.end.kind == 'count'
            ? const BudgetEnd.none()
            : w.end,
      ),
    );

    return SectionCard(
      title: l.bgSectionPeriod,
      description: l.bgSectionPeriodDesc,
      children: [
        DetailRow(
          label: l.bgFieldStart,
          helper: l.bgFieldStartHelp,
          trailing: Text(
            budgetDate(context, w.start),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          showChevron: true,
          onTap: _pickStart,
        ),
        DetailPairRow(
          first: DetailPairCell(
            label: l.bgFieldRepeatToggle,
            value: SelectCheck(value: w.recurring, onTap: null),
            onTap: toggleRepeat,
          ),
          second: DetailPairCell(
            label: w.recurring ? l.bgFieldRepeat : l.bgFieldEnd,
            value: w.recurring ? _roundChips(l, w) : Text(_endText(l, w)),
            chevron: true,
            onTap: w.recurring ? _pickRule : _pickEnd,
          ),
        ),
      ],
    );
  }

  /// View mode, under the hero: one icon + chips strip per scope list the
  /// budget uses. "All" shows none.
  List<Widget> _scopeStrips(AppLocalizations l) {
    final w = working;
    if (w.allScope) return const [];
    final hold = _canEdit ? enterEdit : null;
    return [
      for (final (icon, chips) in [
        (AppIcons.category, _categoryChips(l, w.categories)),
        (AppIcons.wallet, _walletChips(w.wallets)),
        (AppIcons.tag, _tagChips(w.tags)),
      ])
        if (chips.isNotEmpty)
          IconChipStrip(
            icon: icon,
            chips: chips,
            maxLines: 2,
            onLongPress: hold,
          ),
    ];
  }

  /// What the budget counts. Categories, wallets and tags combine with AND;
  /// inside one list any entry will do.
  Widget _scopeSection(AppLocalizations l) {
    final w = working;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hint = Text(
      l.bgScopeAndHint,
      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
    final rows = [
      _scopeRow(
        icon: AppIcons.category,
        label: l.bgScopeCategories,
        chips: _categoryChips(l, w.categories),
        pickLabel: l.multiPickCategoriesTitle,
        onPick: _pickCategories,
      ),
      _scopeRow(
        icon: AppIcons.wallet,
        label: l.bgScopeWallets,
        chips: _walletChips(w.wallets),
        pickLabel: l.multiPickWalletsTitle,
        onPick: _pickWallets,
      ),
      _scopeRow(
        icon: AppIcons.tag,
        label: l.bgScopeTags,
        chips: _tagChips(w.tags),
        pickLabel: l.bgScopePickTags,
        onPick: _pickTags,
      ),
    ];
    // No card header: the question heads the first row, its answer beside it.
    return SectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.bgSectionScope,
                      style: detailLabelStyle(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SegmentedChoice<bool>(
                    segments: [
                      ChoiceSegment(true, l.bgScopeAll),
                      ChoiceSegment(false, l.bgScopeChoose),
                    ],
                    selected: w.allScope,
                    onChanged: (all) {
                      if (all) setState(() => _scopeMissing = false);
                      _change(w.copyWith(allScope: all));
                    },
                  ),
                ],
              ),
              if (!w.allScope) ...[const SizedBox(height: AppSpacing.sm), hint],
              if (_scopeMissing && w.scopeEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.bgScopeRequired,
                  style: text.bodySmall?.copyWith(color: scheme.error),
                ),
              ],
            ],
          ),
        ),
        if (!w.allScope) ...rows,
      ],
    );
  }

  /// One scope list laid out like the note: icon, heading, the chips under
  /// it in a dashed frame that opens the picker.
  Widget _scopeRow({
    required IconData icon,
    required String label,
    required List<Widget> chips,
    required String pickLabel,
    required VoidCallback onPick,
  }) {
    final wrap = chips.isEmpty
        ? null
        : LimitedChipWrap(chips: chips, onMore: onPick, expandable: false);
    return DetailStacked(
      label: label,
      leading: AppIcon(icon),
      child: PickFrame(
        onTap: onPick,
        child: wrap ?? PickFramePrompt(pickLabel),
      ),
    );
  }

  List<Widget> _categoryChips(
    AppLocalizations l,
    List<BudgetScopeCategory> cats,
  ) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return [
      for (final c in cats)
        AppChip(
          label: c.includeChildren
              ? l.bgScopeChildren(c.category.name)
              : c.category.name,
          icon: IconRegistry.get(
            c.category.iconCode?.icon,
            fallback: AppIcons.category,
          ),
          color: c.category.iconCode.tintFor(palette),
          selected: true,
          size: ChipSize.chip,
        ),
    ];
  }

  List<Widget> _walletChips(List<AccountRef> wallets) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return [
      for (final a in wallets)
        AppChip(
          label: a.name,
          icon: IconRegistry.get(a.iconCode?.icon, fallback: a.type.icon),
          color: a.iconCode.tintFor(palette),
          selected: true,
          size: ChipSize.chip,
        ),
    ];
  }

  List<Widget> _tagChips(List<String> names) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final known = context.read<TagsCubit>().state.tags;
    return [
      for (final n in names)
        if (known.where((t) => t.name.toLowerCase() == n.toLowerCase())
            case final match)
          AppChip(
            label: n,
            icon: IconRegistry.get(
              match.firstOrNull?.iconCode?.icon,
              fallback: AppIcons.tag,
            ),
            color: match.isEmpty
                ? null
                : tagColor(match.first.iconCode, palette),
            selected: true,
            size: ChipSize.chip,
          ),
    ];
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
      hero: AppHeroCard(
        style: HeroStyle.tinted(color: accent, glyph: AppIcons.budget),
        mode: HeroCardMode.edit,
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
          ),
          HeroAmountField(
            controller: _ctrl[_Field.amount]!,
            label: l.fpBudgetsLimitLabel,
            symbol: context.readUserCurrencySymbol,
            onChanged: (v) => _onText(_Field.amount, v),
            validator: (v) {
              final n = AmountInput.parse(v);
              return (n == null || n <= 0) ? l.budgetFormAmountInvalid : null;
            },
          ),
          _warnRow(l),
        ],
      ),
      info: _periodSection(l),
      settings: _scopeSection(l),
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
            hint: l.bgNoteHint,
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

  /// "Warn at" sits with the limit it is a share of, the money spelled out.
  Widget _warnRow(AppLocalizations l) {
    final w = working;
    final limit = AmountInput.parse(_ctrl[_Field.amount]!.text);
    final pct = w.warnPct;
    return SettingMenuRow<int>(
      compact: true,
      label: l.fpBudgetsWarnAt,
      value: pct == null ? l.bgWarnOff : l.bgWarnPct(pct),
      note: limit == null || limit <= 0 || pct == null
          ? null
          : '= ${budgetRowMoney(context, limit * pct / 100)}',
      selected: pct ?? 0,
      options: [
        for (final p in const [70, 80, 90, 95])
          SheetOption(value: p, label: l.bgWarnPct(p)),
        SheetOption(value: 0, label: l.bgWarnOff),
      ],
      onSelected: (p) => _change(
        p == 0 ? w.copyWith(clearWarn: true) : w.copyWith(warnPct: p),
      ),
      // Any whole percent the backend takes (1–100).
      custom: SettingMenuCustom<int>(
        hint: l.commonCustomValue,
        suffix: '%',
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        parse: (t) {
          final n = int.tryParse(t);
          return n == null || n < 1 ? null : n.clamp(1, 100);
        },
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
