import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/text_limits.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_tree.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_pick_card.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../domain/budget.dart';
import '../../domain/budget_period.dart';
import '../../domain/budget_scope.dart';
import '../../domain/budget_status.dart';
import '../cubit/budgets_cubit.dart';
import '../widgets/budget_card.dart';

/// `/budgets/new`, `/budgets/:id` (+ `/edit`) — one page for a user-scope
/// budget, view ⇄ edit in place ([EditModeMixin], category style).
///
/// Header: category icon, name (blank → the server names it after the
/// category), spent / limit / progress / period range. Body: category
/// (live — editable after create, BE accepts `category_id` on PUT; doesn't
/// rename), limit, period (live cards), description, note. Edit mode ends
/// with archive · delete, both of which leave to the list.
///
/// Project-scope budgets are created from the project, not here; `scope`
/// / `project_id` aren't editable on PUT (spec §3.4). The icon always comes
/// from the category (migration 000037), so there's no icon picker.
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

/// Which text field a typing burst belongs to (undo grouping).
enum _Field { name, amount, description, note }

class _BudgetDetailPageState extends State<BudgetDetailPage>
    with EditModeMixin<BudgetDetailPage, _BudgetDraft> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = {for (final f in _Field.values) f: TextEditingController()};
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _noteFocus = FocusNode();

  /// Last budget shown. After archive / delete the cubit drops it while
  /// this page is still animating away — keep painting it instead of
  /// flashing "not found".
  Budget? _last;

  /// `startEditing` on a deep link: enter edit once the budget arrives.
  bool _startEditPending = false;

  /// Save was tried with no category → error under the card.
  bool _categoryMissing = false;

  @override
  void initState() {
    super.initState();
    if (widget.isCreate) {
      initDraft(const _BudgetDraft(), editing: true);
    } else {
      final cached = context.read<BudgetsCubit>().byId(widget.id!);
      _last = cached;
      _startEditPending = cached == null && widget.startEditing;
      initDraft(
        cached == null ? const _BudgetDraft() : _BudgetDraft.from(cached),
        editing: cached != null && widget.startEditing,
      );
    }
    onDraftRestored();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoriesCubit>().loadIfNeeded();
      if (!widget.isCreate) context.read<BudgetsCubit>().loadIfNeeded();
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

  /// The cubit changed: rebase onto the fresh budget (no-op mid-edit).
  void _onBudgets() {
    if (widget.isCreate) return;
    final b = context.read<BudgetsCubit>().byId(widget.id!);
    if (b == null || b == _last) return;
    setState(() => _last = b);
    resetDraft(_BudgetDraft.from(b));
    if (_startEditPending) {
      _startEditPending = false;
      enterEdit();
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
    sync(_Field.amount, working.amount);
    sync(_Field.description, working.description);
    sync(_Field.note, working.note);
  }

  void _onText(_Field f, String v) => applyTextChange(f, switch (f) {
    _Field.name => working.copyWith(name: v),
    _Field.amount => working.copyWith(amount: v),
    _Field.description => working.copyWith(description: v),
    _Field.note => working.copyWith(note: v),
  });

  // ── Actions ─────────────────────────────────────────────────────────

  Future<void> _pickCategory(List<Category> all, Category? current) async {
    final result = await showCategoryPickerSheet(
      context: context,
      categories: all,
      type: CategoryType.expense,
      selected: current,
      allowNone: false,
    );
    if (!mounted || result is! CategoryPickerSelected) return;
    setState(() => _categoryMissing = false);
    applyChange(working.copyWith(categoryId: result.category.id));
  }

  Future<void> _save(Budget? budget) async {
    commitTextSession();
    final formOk = _formKey.currentState?.validate() ?? false;
    setState(() => _categoryMissing = working.categoryId == null);
    if (!formOk || working.categoryId == null) return;

    final cubit = context.read<BudgetsCubit>();
    final w = working.trimmed();
    final amount = AmountField.parse(w.amount)!;
    final description = w.description.isEmpty ? null : w.description;
    final note = w.note.isEmpty ? null : w.note;
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      if (budget == null) {
        await cubit.add(
          Budget(
            id: 'draft',
            categoryId: w.categoryId!,
            amount: amount,
            period: w.period,
            scope: BudgetScope.user,
            currency: 'THB',
            status: BudgetStatus.active,
            // Blank → the server names it after the category.
            name: w.name,
            description: description,
            note: note,
          ),
        );
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        leavePage();
        return;
      }
      // Constructed directly (not copyWith) so cleared text goes out as
      // JSON null — the BE treats that as a clear. A cleared name resets
      // to the current category's name.
      final recategorized = w.categoryId != budget.categoryId;
      await cubit.update(
        Budget(
          id: budget.id,
          categoryId: w.categoryId!,
          amount: amount,
          period: w.period,
          scope: budget.scope,
          currency: budget.currency,
          status: budget.status,
          projectId: budget.projectId,
          name: w.name,
          description: description,
          note: note,
          // The old embedded category is stale after a re-anchor; the
          // server response brings the new one.
          category: recategorized ? null : budget.category,
        ),
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      final saved = cubit.byId(budget.id);
      if (saved != null) _last = saved;
      commitSaved(saved == null ? w : _BudgetDraft.from(saved));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _archive(Budget budget) {
    final l = AppLocalizations.of(context)!;
    return _confirmAndLeave(
      title: l.budgetArchiveConfirmTitle,
      body: l.budgetArchiveConfirmBody,
      action: l.budgetArchiveConfirmAction,
      run: (c) => c.archive(budget.id),
    );
  }

  Future<void> _delete(Budget budget) {
    final l = AppLocalizations.of(context)!;
    return _confirmAndLeave(
      title: l.budgetDeleteConfirmTitle,
      body: l.budgetDeleteConfirmBody,
      action: l.budgetDeleteConfirmAction,
      run: (c) => c.remove(budget.id),
    );
  }

  /// Confirm → run (archive / delete — either way the budget leaves the
  /// active list) → back to the list.
  Future<void> _confirmAndLeave({
    required String title,
    required String body,
    required String action,
    required Future<void> Function(BudgetsCubit) run,
  }) async {
    final ok = await showConfirmDialog(
      context,
      title: title,
      message: body,
      confirmLabel: action,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setSaving(true);
    try {
      await run(context.read<BudgetsCubit>());
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    // Pop without the discard prompt — the budget is gone.
    commitSaved(working);
    leavePage();
  }

  // ── Derived display ─────────────────────────────────────────────────

  /// The picked category — from the categories store, else (store not
  /// loaded yet) the budget's embedded snapshot.
  Category? _category(List<Category> all, Budget? budget) {
    final id = working.categoryId;
    if (id == null) return null;
    for (final c in all) {
      if (c.id == id) return c;
    }
    final ref = budget?.category;
    if (ref == null || ref.id != id) return null;
    return Category(
      id: ref.id,
      name: ref.name,
      type: CategoryType.expense,
      iconCode: ref.iconCode,
    );
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.watch<BudgetsCubit>();
    final budget = widget.isCreate ? null : (cubit.byId(widget.id!) ?? _last);

    return BlocListener<BudgetsCubit, BudgetsState>(
      listener: (_, _) => _onBudgets(),
      child: !widget.isCreate && budget == null
          ? _missing(l, cubit)
          : _page(l, budget),
    );
  }

  /// Deep link before the list has loaded → skeleton; loaded without this
  /// id → not found.
  Widget _missing(AppLocalizations l, BudgetsCubit cubit) {
    final state = cubit.state;
    final loading =
        state.status == BudgetsStatus.initial ||
        state.status == BudgetsStatus.loading;
    return Scaffold(
      appBar: AppTopBar(title: l.budgetsTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: loading
          // The generic skeleton is a padded list — clear the bar.
          ? Builder(
              builder: (context) => Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                ),
                child: const LoadingView(),
              ),
            )
          : state.error != null
          ? ErrorView(error: state.error!, onRetry: cubit.load)
          : EmptyView(
              icon: AppIcons.empty,
              title: l.budgetDetailNotFound,
              message: l.budgetDetailNotFoundMessage,
            ),
    );
  }

  Widget _page(AppLocalizations l, Budget? budget) {
    final all = context.watch<CategoriesCubit>().state.categories;
    final category = _category(all, budget);
    return editScope(
      Scaffold(
        // The bar floats over the list; its first item is padded below it.
        extendBodyBehindAppBar: true,
        appBar: AppTopBar(
          title: _title(l),
          showBack: true,
          editing: isEditing,
          onBack: handleBack,
        ),
        body: Form(
          key: _formKey,
          // Builder: its context sees the floating bar's height.
          child: Builder(
            builder: (context) => PullToRefresh(
              enabled: !widget.isCreate,
              onRefresh: context.read<BudgetsCubit>().load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  MediaQuery.paddingOf(context).top + AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _header(l, budget, category, all),
                  const SizedBox(height: AppSpacing.lg),
                  _fields(l, all, category),
                  if (budget != null && budget.childBreakdown.isNotEmpty)
                    SectionCard(
                      title: l.budgetDetailBreakdownTitle,
                      locked: isEditing,
                      children: [
                        for (final row in budget.childBreakdown)
                          DetailRow(
                            label: row.name,
                            trailing: MoneyText(row.spent),
                          ),
                      ],
                    ),
                  // Archive · delete — edit mode only, always last (the top
                  // bar carries no page actions).
                  if (isEditing && budget != null) ...[
                    DangerRow(
                      icon: AppIcons.archive,
                      label: l.budgetDetailArchive,
                      onTap: isSaving ? null : () => _archive(budget),
                    ),
                    DangerRow(
                      icon: AppIcons.delete,
                      label: l.budgetDeleteThis,
                      onTap: isSaving ? null : () => _delete(budget),
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: isEditing
            ? editActionBar(onSave: () => _save(budget))
            : null,
      ),
    );
  }

  String _title(AppLocalizations l) {
    if (widget.isCreate) return l.budgetFormTitle;
    if (isEditing) return l.budgetFormTitleEdit;
    final name = working.name.trim();
    return name.isEmpty ? l.budgetDetailFallbackTitle : name;
  }

  Widget _header(
    AppLocalizations l,
    Budget? budget,
    Category? category,
    List<Category> all,
  ) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final categoryName = category?.name ?? '';
    // The embedded icon while the category is unchanged (matches the list
    // card); the picked one's resolved icon after a change / on create.
    final iconCode =
        (budget != null && budget.categoryId == working.categoryId
            ? budget.iconCode
            : null) ??
        (category == null ? null : CategoryTree.resolveIconCode(category, all));
    final accent = budget != null
        ? budgetAccent(context, budget)
        : (iconCode?.accentColorFor(palette) ?? palette.primary);

    // Blank is fine — the server names it after the category, so that's
    // the placeholder.
    final title = InlineTitleField(
      editing: isEditing,
      controller: _ctrl[_Field.name]!,
      focusNode: _nameFocus,
      hint: categoryName.isEmpty ? l.commonName : categoryName,
      maxLength: TextLimits.name,
      onEnterEdit: () => enterEdit(focus: _nameFocus),
      onChanged: (v) => _onText(_Field.name, v),
    );
    final name = working.name.trim();

    return HeaderCard(
      accent: accent,
      onEdit: isEditing ? null : enterEdit,
      leading: IconDisplay(
        type: IconType.category,
        size: 52,
        iconCode: iconCode,
      ),
      title: title,
      subtitle: Text(
        [
          // Skipped while the name already says it (the default).
          if (name.isNotEmpty &&
              categoryName.isNotEmpty &&
              categoryName != name)
            categoryName,
          budgetPeriodLabel(l, working.period),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      footer: budget == null
          ? _createFooter(l, accent, textTheme)
          : _footer(l, budget, accent, textTheme),
    );
  }

  /// Create: nothing spent yet — just the limit being typed.
  Widget _createFooter(AppLocalizations l, Color accent, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.budgetFormAmountLabel, style: textTheme.labelMedium),
        MoneyText(
          AmountField.parse(working.amount) ?? 0,
          hideable: false,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      ],
    );
  }

  Widget _footer(
    AppLocalizations l,
    Budget budget,
    Color accent,
    TextTheme textTheme,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final cp = budget.currentPeriod;
    final pct = cp?.utilizationPct ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoneyText(
          cp?.spent ?? 0,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
        Text(
          l.budgetDetailOfLimit(moneyString(context, budget.amount)),
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ProgressRow(
          value: pct / 100,
          color: accent,
          label: cp == null
              ? null
              : l.budgetDetailRemainingLine(moneyString(context, cp.remaining)),
          trailing: '${pct.toStringAsFixed(0)}%',
        ),
        if (cp != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            budgetPeriodRange(context, cp.start, cp.end),
            style: textTheme.bodySmall,
          ),
        ],
        if (cp?.overLimit ?? false) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(AppIcons.warning, color: scheme.error, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l.budgetDetailOverLimitWarning,
                  style: textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Category · limit · period · description · note. Category and period
  /// stay live in view mode (using them enters edit mode); text fields
  /// enter it on long-press.
  Widget _fields(AppLocalizations l, List<Category> all, Category? category) {
    final editing = isEditing;
    return SectionCard(
      first: true,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: CategoryPickCard(
            category: category,
            label: l.budgetFormCategoryLabel,
            placeholder: l.budgetFormCategoryPlaceholder,
            errorText: _categoryMissing ? l.budgetFormCategoryRequired : null,
            onTap: isSaving ? null : () => _pickCategory(all, category),
          ),
        ),
        if (editing)
          DetailStacked(
            label: l.budgetFormAmountLabel,
            child: AmountField(
              controller: _ctrl[_Field.amount]!,
              onChanged: (v) => _onText(_Field.amount, v),
              validator: (v) {
                final n = AmountField.parse(v);
                return (n == null || n <= 0) ? l.budgetFormAmountInvalid : null;
              },
            ),
          )
        else
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: enterEdit,
            child: DetailRow(
              label: l.budgetFormAmountLabel,
              trailing: MoneyText(AmountField.parse(working.amount) ?? 0),
            ),
          ),
        DetailStacked(
          label: l.budgetFormPeriodLabel,
          child: SelectCardGroup<BudgetPeriod>(
            selected: working.period,
            onChanged: isSaving
                ? null
                : (p) => applyChange(working.copyWith(period: p)),
            options: [
              for (final p in BudgetPeriod.values)
                SelectCardOption(value: p, label: budgetPeriodLabel(l, p)),
            ],
          ),
        ),
        DetailStacked(
          label: l.commonDescription,
          child: InlineField(
            editing: editing,
            controller: _ctrl[_Field.description]!,
            focusNode: _descriptionFocus,
            maxLines: 3,
            maxLength: TextLimits.description,
            onEnterEdit: () => enterEdit(focus: _descriptionFocus),
            onChanged: (v) => _onText(_Field.description, v),
          ),
        ),
        DetailStacked(
          label: l.commonNote,
          child: InlineField(
            editing: editing,
            controller: _ctrl[_Field.note]!,
            focusNode: _noteFocus,
            maxLines: 3,
            maxLength: TextLimits.note,
            onEnterEdit: () => enterEdit(focus: _noteFocus),
            onChanged: (v) => _onText(_Field.note, v),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Immutable editing snapshot — drives dirty-check + undo history.
// ────────────────────────────────────────────────────────────────────

class _BudgetDraft {
  const _BudgetDraft({
    this.categoryId,
    this.amount = '',
    this.period = BudgetPeriod.monthly,
    this.name = '',
    this.description = '',
    this.note = '',
  });

  factory _BudgetDraft.from(Budget b) => _BudgetDraft(
    categoryId: b.categoryId,
    amount: AmountField.format(b.amount),
    period: b.period,
    name: b.name,
    description: b.description ?? '',
    note: b.note ?? '',
  );

  final String? categoryId;

  /// Formatted text, as in the field.
  final String amount;
  final BudgetPeriod period;

  /// Empty = the server names it after the category.
  final String name;
  final String description;
  final String note;

  /// What the server stores (text trimmed).
  _BudgetDraft trimmed() => copyWith(
    amount: amount.trim(),
    name: name.trim(),
    description: description.trim(),
    note: note.trim(),
  );

  _BudgetDraft copyWith({
    String? categoryId,
    String? amount,
    BudgetPeriod? period,
    String? name,
    String? description,
    String? note,
  }) => _BudgetDraft(
    categoryId: categoryId ?? this.categoryId,
    amount: amount ?? this.amount,
    period: period ?? this.period,
    name: name ?? this.name,
    description: description ?? this.description,
    note: note ?? this.note,
  );

  @override
  bool operator ==(Object other) =>
      other is _BudgetDraft &&
      other.categoryId == categoryId &&
      other.amount == amount &&
      other.period == period &&
      other.name == name &&
      other.description == description &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(categoryId, amount, period, name, description, note);
}
