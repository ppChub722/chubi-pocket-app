import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_tree.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_chip_path.dart';
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
    final amount = AmountInput.parse(w.amount)!;
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
      body: AsyncStateView.fallback(
        loading: loading,
        error: state.error,
        onRetry: cubit.load,
        notFound: EmptyView(
          icon: AppIcons.empty,
          title: l.budgetDetailNotFound,
          message: l.budgetDetailNotFoundMessage,
        ),
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
            builder: (context) => DetailPageBody(
              onRefresh: widget.isCreate
                  ? null
                  : () => context.read<BudgetsCubit>().load(),
              physics: const AlwaysScrollableScrollPhysics(),
              topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
              bottomInset:
                  AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
              hero: _header(l, budget, category, all),
              sections: [
                (first) => _fields(l, all, category, first),
                (first) => budget != null && budget.childBreakdown.isNotEmpty
                    ? SectionCard(
                        first: first,
                        title: l.budgetDetailBreakdownTitle,
                        description: l.budgetDetailBreakdownDescription,
                        children: [
                          for (final row in budget.childBreakdown)
                            DetailRow(
                              locked: isEditing,
                              label: row.name,
                              trailing: MoneyText(row.spent),
                            ),
                        ],
                      )
                    : null,
              ],
              // Archive · delete — edit mode only, always last (the top
              // bar carries no page actions).
              manage: isEditing && budget != null
                  ? ManageSection(
                      archiveLabel: l.budgetDetailArchive,
                      onArchive: isSaving ? null : () => _archive(budget),
                      deleteLabel: l.budgetDeleteThis,
                      onDelete: isSaving ? null : () => _delete(budget),
                    )
                  : null,
              metaLines: budget == null
                  ? const []
                  : detailMetaLines(
                      context,
                      createdAt: budget.createdAt,
                      updatedAt: budget.updatedAt,
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

  /// Titles never change with the mode (owner, QA T1): the saved name in
  /// view and edit alike (not the one being typed).
  String _title(AppLocalizations l) {
    if (widget.isCreate) return l.budgetFormTitle;
    final name = _last?.name.trim() ?? '';
    return name.isEmpty ? l.budgetDetailFallbackTitle : name;
  }

  Widget _header(
    AppLocalizations l,
    Budget? budget,
    Category? category,
    List<Category> all,
  ) {
    final palette = Theme.of(context).extension<AppColors>()!;
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
        : (iconCode.tintFor(palette));

    // Blank is fine — the server names it after the category, so that's
    // the placeholder.
    final title = HeroNameInput(
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
      glyph: AppIcons.budget,
      onEdit: isEditing ? null : enterEdit,
      topRow: [
        AppChip(
          label: budgetPeriodLabel(l, working.period),
          icon: AppIcons.date,
          tone: AppChipTone.neutral,
          selected: true,
        ),
      ],
      leading: IconDisplay(
        type: IconType.category,
        size: 52,
        iconCode: iconCode,
      ),
      title: title,
      description: HeroDescription(
        controller: _ctrl[_Field.description]!,
        editing: isEditing,
        hint: l.commonDescription,
        maxLength: TextLimits.description,
        focusNode: _descriptionFocus,
        onEnterEdit: () => enterEdit(focus: _descriptionFocus),
        onChanged: (v) => _onText(_Field.description, v),
      ),
      subtitle:
          name.isNotEmpty && categoryName.isNotEmpty && categoryName != name
          ? Text(categoryName, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      footer: budget == null
          ? _createFooter(l, accent)
          : _footer(l, budget, accent),
    );
  }

  /// Create: nothing spent yet — just the limit being typed.
  Widget _createFooter(AppLocalizations l, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(l.budgetFormAmountLabel, role: AppTextRole.caption),
        MoneyText(
          AmountInput.parse(working.amount) ?? 0,
          hideable: false,
          style: AppTypography.of(
            context,
            AppTextRole.display,
          )?.copyWith(color: accent),
        ),
      ],
    );
  }

  Widget _footer(AppLocalizations l, Budget budget, Color accent) {
    final cp = budget.currentPeriod;
    final pct = cp?.utilizationPct ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoneyText(
          cp?.spent ?? 0,
          style: AppTypography.of(
            context,
            AppTextRole.display,
          )?.copyWith(color: accent),
        ),
        AppText(
          l.budgetDetailOfLimit(moneyString(context, budget.amount)),
          role: AppTextRole.caption,
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
          AppText(
            budgetPeriodRange(context, cp.start, cp.end),
            role: AppTextRole.caption,
          ),
        ],
        if (cp?.overLimit ?? false) ...[
          const SizedBox(height: AppSpacing.sm),
          AppMessage(
            message: l.budgetDetailOverLimitWarning,
            tone: Tone.danger,
          ),
        ],
      ],
    );
  }

  Widget _categoryRow(
    AppLocalizations l,
    List<Category> all,
    Category? category,
  ) {
    final row = DetailRow.pick(
      label: l.budgetFormCategoryLabel,
      valueChip: category == null
          ? null
          : categoryChipPath(context, category, all: all),
      emptyText: l.quickEventNone,
      onTap: isSaving
          ? null
          : () {
              // Empty in view mode: tapping starts adding it (edit + picker).
              if (!isEditing) enterEdit();
              _pickCategory(all, category);
            },
    );
    if (!_categoryMissing) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: AppMessage(
            message: l.budgetFormCategoryRequired,
            tone: Tone.danger,
          ),
        ),
      ],
    );
  }

  /// The period row: a popover (3 short options) anchored to the row; the
  /// current period is highlighted.
  Widget _periodRow(AppLocalizations l) {
    return OptionMenuAnchor<BudgetPeriod>(
      selected: working.period,
      options: [
        for (final p in BudgetPeriod.values)
          SheetOption(value: p, label: budgetPeriodLabel(l, p)),
      ],
      onSelected: (p) {
        if (!mounted) return;
        applyChange(working.copyWith(period: p));
      },
      builder: (context, toggle) => DetailRow.pick(
        label: l.budgetFormPeriodLabel,
        value: budgetPeriodLabel(l, working.period),
        emptyText: l.quickEventNone,
        onTap: isSaving ? null : toggle,
      ),
    );
  }

  /// Category · limit · period · note (the description is in the hero). Category and period
  /// stay live in view mode (using them enters edit mode); text fields
  /// enter it on long-press.
  Widget _fields(
    AppLocalizations l,
    List<Category> all,
    Category? category,
    bool first,
  ) {
    final editing = isEditing;
    return SectionCard(
      first: first,
      children: [
        _categoryRow(l, all, category),
        if (editing)
          DetailStacked(
            label: l.budgetFormAmountLabel,
            child: AmountInput(
              controller: _ctrl[_Field.amount]!,
              onChanged: (v) => _onText(_Field.amount, v),
              validator: (v) {
                final n = AmountInput.parse(v);
                return (n == null || n <= 0) ? l.budgetFormAmountInvalid : null;
              },
            ),
          )
        else
          DetailRow(
            label: l.budgetFormAmountLabel,
            onLongPress: enterEdit,
            trailing: MoneyText(AmountInput.parse(working.amount) ?? 0),
          ),
        _periodRow(l),
        DetailStacked(
          label: l.commonNote,
          child: AppInput.inline(
            editing: editing,
            controller: _ctrl[_Field.note]!,
            focusNode: _noteFocus,
            maxLines: 3,
            maxLength: TextLimits.note,
            viewHint: AppLocalizations.of(context)!.commonLongPressToEdit,
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
    amount: AmountInput.format(b.amount),
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
