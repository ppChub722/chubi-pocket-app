import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../users/data/users_repository.dart';
import '../../domain/category.dart';
import '../../domain/category_reorder_logic.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../cubit/categories_cubit.dart';
import '../widgets/category_chip_path.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/category_preview_card.dart';

/// One screen, two modes (view ⇄ edit) for a single category — the
/// reference detail page for the whole app (`ux-overhaul-plan.md` §1.5).
///
/// Every field is the same widget in both modes (only its border and
/// editability change), so nothing reflows. Discrete controls (type chips
/// on create, the report switch, parent picker) stay live in view mode and
/// enter edit mode on use; long-pressing a text field or the icon enters
/// edit mode on it. Lifecycle (undo, discard, nav hiding) is
/// [EditModeMixin].
class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({
    this.editingId,
    this.initialType,
    this.popOnCreate = false,
    super.key,
  });

  /// `/categories/new?type=income` — create on the list tab's type (QA F3).
  /// Anything but `income` starts on expense.
  CategoryDetailPage.create({String? type, Key? key})
    : this(
        initialType: type == CategoryType.income.toJson()
            ? CategoryType.income
            : CategoryType.expense,
        key: key,
      );

  final String? editingId;

  /// Create only: the type to start with (a picker for income opens the
  /// create page on income).
  final CategoryType? initialType;

  /// Create pushed over a picker (Navigator, not the router): saving pops
  /// with the new [Category] instead of becoming its view, so the page
  /// underneath stays (QA F5).
  final bool popOnCreate;

  bool get isCreate => editingId == null;

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

/// Which text field a typing burst belongs to (undo grouping).
enum _TextField { name, description, note }

class _CategoryDetailPageState extends State<CategoryDetailPage>
    with EditModeMixin<CategoryDetailPage, _CategoryDraft> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _noteFocus = FocusNode();

  /// The persisted category — Save `copyWith`s onto it to keep id /
  /// sortOrder / isSystem. Null while creating, or until the cubit's list
  /// has it (opened before the list loaded).
  Category? _persisted;
  bool _notFound = false;

  /// Create until the first save — then this page becomes the saved
  /// category's view in place.
  bool get _isCreate => widget.isCreate && _persisted == null;

  /// The one `GET /categories/:id` of this page: counts + the fee flag
  /// (preference `fee_category_id`, spec 15 §7: fee drafts from bank slips
  /// get it). Null while creating or until the call lands.
  CategoryDetail? _detail;
  bool _feeBusy = false;

  /// This month's total / count: from the list row, then the detail GET.
  /// Write answers carry 0, so they never overwrite these.
  num _monthSpent = 0;
  int _monthCount = 0;

  /// The report switch while its instant save is in flight (view mode).
  bool? _includeOverride;
  bool _includeBusy = false;

  /// A save error in words: the depth limit in Thai, else the server's.
  String _errorText(ApiException e, AppLocalizations l) =>
      e.code == 'MAX_DEPTH_EXCEEDED' ? l.categoryErrorMaxDepth : e.message;

  @override
  void initState() {
    super.initState();
    if (widget.isCreate) {
      initDraft(
        _CategoryDraft(type: widget.initialType ?? CategoryType.expense),
        editing: true,
      );
    } else {
      final cubit = context.read<CategoriesCubit>();
      _persisted = cubit.byId(widget.editingId!);
      _monthSpent = _persisted?.monthSpent ?? 0;
      _monthCount = _persisted?.monthCount ?? 0;
      initDraft(
        _persisted == null
            ? const _CategoryDraft()
            : _CategoryDraft.fromCategory(_persisted!),
      );
      // Opened before the list loaded (a deep link, a cold tab): load it
      // and take the row when it arrives ([_syncFromCubit]) — not-found
      // only once a loaded list really lacks it.
      if (_persisted == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await cubit.loadIfNeeded();
          if (mounted) _syncFromCubit(cubit.state);
        });
      }
    }
    onDraftRestored();
    if (!widget.isCreate) _loadDetail();
  }

  /// The cubit's list changed (first load, pull-to-refresh, an edit
  /// elsewhere): rebase on the fresh row unless an edit is in progress.
  void _syncFromCubit(CategoriesState state) {
    final id = _persisted?.id ?? widget.editingId;
    if (id == null) return;
    Category? fresh;
    for (final c in state.categories) {
      if (c.id == id) fresh = c;
    }
    if (fresh == null) {
      // Never had it, and the list is in: it doesn't exist. (A row that
      // vanishes later — deleted here — keeps its last view while leaving.)
      if (_persisted == null &&
          !_notFound &&
          state.status == CategoriesStatus.loaded) {
        setState(() => _notFound = true);
      }
      return;
    }
    if (fresh == _persisted) return;
    final first = _persisted == null;
    _persisted = fresh;
    if (first) setState(() => _notFound = false);
    resetDraft(_CategoryDraft.fromCategory(fresh));
  }

  /// The page's one read: `GET /categories/:id` (counts, fee flag, path).
  /// The cubit patches the list row from it; a row the list lacks (a deep
  /// link) is taken from it directly.
  Future<void> _loadDetail() async {
    final cubit = context.read<CategoriesCubit>();
    try {
      final d = await cubit.fetchDetail(widget.editingId!);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _monthSpent = d.monthSpent;
        _monthCount = d.monthCount;
        _notFound = false;
      });
      if (_persisted == null) {
        _persisted = d;
        resetDraft(_CategoryDraft.fromCategory(d));
      }
    } on ApiException catch (e) {
      if (mounted && _persisted == null && e.code == 'NOT_FOUND') {
        setState(() => _notFound = true);
      }
      // Otherwise keep the list row; counts fall back to zero.
    }
  }

  /// Applies at once (a user preference, not part of the category's
  /// draft). On: this category; off: none. One at a time — turning it on
  /// here moves it off any other.
  Future<void> _setFeeCategory(bool on) async {
    final id = _persisted?.id;
    if (id == null) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _feeBusy = true);
    try {
      final me = await context.read<UsersRepository>().setFeeCategory(
        on ? id : null,
      );
      if (!mounted) return;
      context.read<AuthCubit>().updateUser(me);
      // Patch the flag locally; no re-read.
      setState(() => _detail = _detail?.withFee(on));
    } on ApiException {
      if (mounted) {
        showAppSnackBarOn(
          pageMessenger!,
          l.categoryFeeSwitchFailed,
          tone: Tone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _feeBusy = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  // ── EditModeMixin hooks ─────────────────────────────────────────────

  @override
  bool get leaveOnCancel => _isCreate;

  @override
  void onDraftRestored() {
    void sync(TextEditingController c, String v) {
      if (c.text != v) c.text = v;
    }

    sync(_nameController, working.name);
    sync(_descriptionController, working.description);
    sync(_noteController, working.note);
  }

  void _onText(_TextField field, String v) =>
      applyTextChange(field, switch (field) {
        _TextField.name => working.copyWith(name: v),
        _TextField.description => working.copyWith(description: v),
        _TextField.note => working.copyWith(note: v),
      });

  void _enterEditThenOpenMaker() {
    enterEdit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openIconMaker();
    });
  }

  // ── Save / delete ───────────────────────────────────────────────────

  Future<void> _save() async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<CategoriesCubit>();
    final l = AppLocalizations.of(context)!;
    if (_isCreate && !cubit.canAddMore) {
      showAppSnackBarOn(
        pageMessenger!,
        l.categoriesLimitReached,
        tone: Tone.warning,
      );
      return;
    }

    final w = working;
    final description = w.description.trim();
    final note = w.note.trim();
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      if (_isCreate) {
        final created = await cubit.add(
          Category(
            id: 'draft',
            name: w.name.trim(),
            type: w.type,
            iconCode: w.iconCode,
            parentId: w.parentId,
            description: description.isEmpty ? null : description,
            note: note.isEmpty ? null : note,
            includeInReport: w.includeInReport,
          ),
        );
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        if (widget.popOnCreate) {
          // Pop without the discard prompt — the picker takes it from here.
          commitSaved(_CategoryDraft.fromCategory(created));
          Navigator.of(context).pop(created);
          return;
        }
        // Become the saved category right here — edit → view in place, as
        // contacts do. `replace` only fixes the URL: same page key, so no
        // transition and this state is kept.
        setState(() {
          _persisted = created;
          _detail = CategoryDetail.fromCategory(created);
        });
        commitSaved(_CategoryDraft.fromCategory(created));
        context.replace('/categories/${created.id}');
        return;
      } else {
        final next = _persisted!.copyWith(
          name: w.name.trim(),
          parentId: w.parentId,
          clearParent: w.parentId == null,
          iconCode: w.iconCode,
          description: description.isEmpty ? null : description,
          // Emptied = cleared: the update sends an explicit null.
          clearDescription: description.isEmpty,
          note: note.isEmpty ? null : note,
          clearNote: note.isEmpty,
          includeInReport: w.includeInReport,
        );
        final saved = await cubit.update(next);
        _persisted = saved;
        _detail = saved.withFee(_detail?.isFeeCategory ?? saved.isFeeCategory);
      }
    } on CategoryLimitExceeded {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(
        pageMessenger!,
        l.categoriesLimitReached,
        tone: Tone.warning,
      );
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, _errorText(e, l), tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    commitSaved(working.trimmed());
  }

  /// Always a real delete. The confirm spells out the fallout (fetched
  /// loaded): children move up, transactions become uncategorised, budgets
  /// on this category are deleted with it.
  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final c = _persisted!;
    final cubit = context.read<CategoriesCubit>();
    // The counts come from the detail loaded on open: no extra call.
    final txCount = _detail?.transactionCount ?? 0;
    final budgetCount = _detail?.budgetCount ?? 0;
    final ok = await showConfirmDialog(
      context,
      title: l.categoryDeleteTitle(c.name),
      message: [
        l.categoryDeleteBody,
        if (txCount > 0) l.categoryDeleteTxImpact(txCount),
        if (budgetCount > 0) l.categoryDeleteBudgetImpact(budgetCount),
      ].join('\n'),
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setSaving(true);
    try {
      await cubit.remove(c.id);
      if (!mounted) return;
      showAppSnackBar(
        context,
        l.categoryDeletedResult(c.name),
        tone: Tone.success,
      );
      // Pop without the discard prompt — the row is gone.
      commitSaved(working);
      leavePage();
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBarOn(pageMessenger!, e.message, tone: Tone.danger);
    }
  }

  // ── Derived display ─────────────────────────────────────────────────

  Category _previewCategory() => Category(
    id: _persisted?.id ?? 'preview',
    name: working.name,
    type: working.type,
    iconCode: _resolvedDisplayIconCode(),
    parentId: working.parentId,
    includeInReport: working.includeInReport,
  );

  /// Every level shows its own icon (owner 2026-10-11); a row with none yet
  /// falls back to its L1 ancestor's, as the list does.
  IconCode? _resolvedDisplayIconCode() {
    if (working.iconCode != null || working.parentId == null) {
      return working.iconCode;
    }
    final all = context.read<CategoriesCubit>().state.categories;
    final parent = context.read<CategoriesCubit>().byId(working.parentId!);
    return parent == null ? null : CategoryTree.resolveIconCode(parent, all);
  }

  /// The chosen parent from the list, or null (none / not loaded).
  Category? _parentCategory(List<Category> all) {
    final id = working.parentId;
    if (id == null) return null;
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  String? _parentBreadcrumb(List<Category> all) {
    if (working.parentId == null) return null;
    // Unchanged parent: the row's own server path.
    final row = _persisted;
    if (row != null &&
        row.parentId == working.parentId &&
        row.path.isNotEmpty) {
      return row.path.map((p) => p.name).join(' › ');
    }
    final parent = all.firstWhere(
      (c) => c.id == working.parentId,
      orElse: _previewCategory,
    );
    final ancestors = CategoryTree.breadcrumb(parent, all);
    return ancestors.isEmpty ? parent.name : '$ancestors › ${parent.name}';
  }

  Future<void> _openIconMaker() async {
    final l = AppLocalizations.of(context)!;
    final all = context.read<CategoriesCubit>().state.categories;
    final breadcrumb = _parentBreadcrumb(all);
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.category,
      initial: _resolvedDisplayIconCode(),
      title: l.categoryFormIconLabel,
      iconSectionLabel: l.categoryFormIconLabel,
      colorSectionLabel: l.categoryFormColorLabel,
      previewBuilder: (iconCode) => CategoryPreviewCard(
        category: _previewCategory().copyWith(iconCode: iconCode),
        parentPath: breadcrumb,
      ),
    );
    if (!mounted || result is! IconMakerSelected) return;
    // Any level edits its whole icon — glyph and colours.
    applyChange(working.copyWith(iconCode: result.iconCode));
  }

  Future<void> _openParentPicker(List<Category> all) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<CategoriesCubit>();
    final selectedParent = working.parentId == null
        ? null
        : cubit.byId(working.parentId!);
    // Can't parent into yourself or your own subtree (would cycle).
    final exclude = _persisted == null
        ? <String>{}
        : CategoryReorderLogic.subtreeIds(_persisted!.id, all).toSet();
    // This row and everything under it must stay within 3 levels (QA F4):
    // a parent at level d (1-based) needs d + height ≤ 3, so only levels up
    // to 3 − height are offered. A 3-level subtree can only be top-level.
    final height = _persisted == null
        ? 1
        : CategoryReorderLogic.subtreeHeight(_persisted!.id, all);
    final deepestParent = CategoryTree.maxDepth - height; // 1-based
    if (deepestParent < 1) {
      exclude.addAll([
        for (final c in all)
          if (c.type == working.type) c.id,
      ]);
    }
    final result = await showCategoryPickerSheet(
      context: context,
      categories: all,
      type: working.type,
      selected: selectedParent,
      allowNone: true,
      noneLabel: l.categoryFormParentNone,
      title: l.categoryFormParentLabel,
      // The picker counts levels from 0.
      maxDepth: deepestParent < 1 ? 0 : deepestParent - 1,
      excludeIds: exclude,
    );
    if (!mounted || result == null) return;
    if (result is CategoryPickerSelected) {
      applyChange(working.copyWith(parentId: result.category.id));
    } else if (result is CategoryPickerCleared) {
      applyChange(working.copyWith(clearParent: true));
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocListener<CategoriesCubit, CategoriesState>(
      listener: (context, state) => _syncFromCubit(state),
      child: _isCreate || _persisted != null
          ? _page(l)
          : Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppTopBar(title: l.categoriesTitle, showBack: true),
              // Skeleton → error + retry → not found (AsyncStateView).
              body: BlocBuilder<CategoriesCubit, CategoriesState>(
                builder: (context, state) => AsyncStateView.fallback(
                  loading: !_notFound && state.error == null,
                  error: _notFound ? null : state.error,
                  onRetry: context.read<CategoriesCubit>().load,
                  notFound: EmptyView(
                    icon: AppIcons.empty,
                    title: l.categoryDetailNotFound,
                    message: l.categoryDetailNotFoundMessage,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _page(AppLocalizations l) {
    // The + presets this category (and its type) while this page is on
    // screen.
    return QuickCreatePresetScope(
      preset: QuickCreatePreset(category: _persisted),
      child: editScope(_scaffold(l)),
    );
  }

  Widget _scaffold(AppLocalizations l) {
    return Scaffold(
      // The bar floats over the list; its first item is padded below it.
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        title: _title(l),
        showBack: true,
        editing: isEditing,
        onBack: handleBack,
      ),
      body: BlocBuilder<CategoriesCubit, CategoriesState>(
        // This context sits inside the Scaffold body, so it sees the bar
        // height in its top padding.
        builder: (context, state) => Form(
          key: _formKey,
          child: _body(
            l,
            state.categories,
            topInset: MediaQuery.paddingOf(context).top,
            bottomInset: MediaQuery.paddingOf(context).bottom,
          ),
        ),
      ),
      bottomNavigationBar: isEditing ? editActionBar(onSave: _save) : null,
    );
  }

  /// Titles never change with the mode (owner, QA T1): the saved name in
  /// view and edit alike (not the one being typed).
  String _title(AppLocalizations l) {
    if (_isCreate) return l.categoryFormTitleNew;
    final name = _persisted?.name ?? '';
    return name.isEmpty ? l.categoriesTitle : name;
  }

  /// Instant save of the report switch in view mode (a live toggle): one
  /// update with only that field changed; reverts with a snackbar on failure.
  Future<void> _setIncludeLive(bool v) async {
    final row = _persisted;
    if (row == null || _includeBusy) return;
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<CategoriesCubit>();
    setState(() {
      _includeOverride = v;
      _includeBusy = true;
    });
    try {
      final saved = await cubit.update(row.copyWith(includeInReport: v));
      if (!mounted) return;
      _persisted = saved;
      _detail = saved.withFee(_detail?.isFeeCategory ?? saved.isFeeCategory);
      resetDraft(_CategoryDraft.fromCategory(saved));
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBarOn(pageMessenger!, _errorText(e, l), tone: Tone.danger);
      }
    } finally {
      if (mounted) {
        setState(() {
          _includeOverride = null;
          _includeBusy = false;
        });
      }
    }
  }

  /// "ต.ค. ใช้ไป · 12 รายการ ›" — the month name from the device locale.
  String _monthLabel(AppLocalizations l, bool income) {
    final month = DateFormat.MMM(
      Localizations.localeOf(context).toString(),
    ).format(DateTime.now());
    return income
        ? l.categoryMonthEarnedLabel(month, _monthCount)
        : l.categoryMonthSpentLabel(month, _monthCount);
  }

  /// The category's transactions this month (the dashboard drill-down route,
  /// which is expense-only — income has no link yet).
  VoidCallback? _openMonthTransactions() {
    final c = _persisted;
    if (c == null || c.type != CategoryType.expense) return null;
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final q = Uri(
      path: '/browse',
      queryParameters: {'category': c.id, 'title': c.name, 'month': month},
    );
    return () => openPage(context, q.toString());
  }

  Widget _body(
    AppLocalizations l,
    List<Category> all, {
    required double topInset,
    required double bottomInset,
  }) {
    final editing = isEditing;
    final breadcrumb = _parentBreadcrumb(all);
    final parent = _parentCategory(all);
    final canDelete = !_isCreate && !(_persisted?.isSystem ?? true);
    return DetailLayout(
      // Pull = the page's one read (`GET /categories/:id`); off in create.
      onRefresh: _isCreate ? null : _loadDetail,
      physics: const AlwaysScrollableScrollPhysics(),
      topInset: topInset + AppSpacing.lg,
      bottomInset: AppSpacing.huge + bottomInset,
      hero: _hero(l, all, editing),
      info: InfoBox(
        rows: [
          InfoRow(
            label: l.categoryFormParentLabel,
            // Parent = its ancestor path as chips; the text breadcrumb stays
            // the fallback while the parent isn't in the list.
            valueChip: parent == null
                ? null
                : categoryChipPath(context, parent, all: all),
            value: parent == null
                ? (breadcrumb ?? l.categoryFormParentNone)
                : null,
            showChevron: true,
            // View mode: enter edit, then open the picker.
            onTap: () {
              if (!editing) enterEdit();
              _openParentPicker(all);
            },
          ),
        ],
      ),
      settings: SettingsSection(
        title: l.categorySectionSettings,
        description: l.categorySettingsSectionDescription,
        children: [
          SettingToggleRow(
            label: l.categoryFormIncludeInReportLabel,
            caption: l.categoryFormIncludeInReportHelper,
            value: editing
                ? working.includeInReport
                : (_includeOverride ?? working.includeInReport),
            // Edit / create edit the draft (no request); view saves at once.
            submits: !editing,
            onChanged: editing
                ? (v) => applyChange(working.copyWith(includeInReport: v))
                : (_persisted == null || _includeBusy ? null : _setIncludeLive),
          ),
          // Expense categories only, and only once saved (needs an id).
          if (_persisted != null && working.type == CategoryType.expense)
            SettingToggleRow(
              label: l.categoryFeeSwitchLabel,
              caption: l.categoryFeeSwitchHelper,
              value: _detail?.isFeeCategory ?? false,
              onChanged: _feeBusy ? null : _setFeeCategory,
            ),
        ],
      ),
      note: NoteSection(
        label: l.commonNote,
        editing: editing,
        text: working.note,
        hint: l.commonLongPressToEdit,
        onLongPress: () => enterEdit(focus: _noteFocus),
        editField: DetailTextField(
          label: l.commonNote,
          controller: _noteController,
          editing: true,
          focusNode: _noteFocus,
          maxLines: 3,
          maxLength: TextLimits.note,
          onChanged: (v) => _onText(_TextField.note, v),
        ),
      ),
      endZone: editing && canDelete
          ? EndZone(
              actions: [
                EndZoneAction(
                  kind: EndZoneKind.delete,
                  label: l.categoryDelete,
                  consequence: l.categoryDeleteConsequence,
                  onTap: isSaving ? null : _delete,
                ),
              ],
            )
          : null,
      metaLines: _isCreate
          ? const []
          : detailMetaLines(
              context,
              createdAt: _persisted?.createdAt,
              updatedAt: _persisted?.updatedAt,
            ),
    );
  }

  Widget _hero(AppLocalizations l, List<Category> all, bool editing) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final isIncome = working.type == CategoryType.income;
    final typeColor = isIncome ? palette.income : palette.expense;
    final iconCode = _resolvedDisplayIconCode();
    final typeLabel = isIncome ? l.categoryTypeIncome : l.categoryTypeExpense;
    final typeIcon = isIncome ? AppIcons.income : AppIcons.expense;
    final Widget typeChip = _isCreate
        ? OptionMenuAnchor<CategoryType>(
            selected: working.type,
            // Changing the type clears the parent (it belongs to the type).
            onSelected: (t) =>
                applyChange(working.copyWith(type: t, clearParent: true)),
            options: [
              SheetOption(
                value: CategoryType.expense,
                label: l.categoryTypeExpense,
              ),
              SheetOption(
                value: CategoryType.income,
                label: l.categoryTypeIncome,
              ),
            ],
            builder: (context, toggle) => AppChip(
              label: typeLabel,
              icon: typeIcon,
              color: typeColor,
              selected: true,
              trailing: AppChipTrailing.dropdown,
              onTap: toggle,
            ),
          )
        : AppChip(
            label: typeLabel,
            icon: typeIcon,
            color: typeColor,
            selected: true,
          );
    final style = HeroStyle.tinted(
      color: iconCode.tintFor(palette, fallback: typeColor),
      glyph: AppIcons.category,
    );
    final description = HeroDescription(
      controller: _descriptionController,
      editing: editing,
      focusNode: _descriptionFocus,
      hint: l.commonDescription,
      maxLength: TextLimits.description,
      onEnterEdit: () => enterEdit(focus: _descriptionFocus),
      onChanged: (v) => _onText(_TextField.description, v),
    );
    if (editing) {
      return HeroCard(
        style: style,
        editing: true,
        chips: [typeChip],
        icon: EditableCircle(
          size: 44,
          onTap: _openIconMaker,
          child: IconDisplay(
            type: IconType.category,
            size: 44,
            iconCode: iconCode,
          ),
        ),
        name: HeroNameInput(
          editing: true,
          controller: _nameController,
          focusNode: _nameFocus,
          hint: l.commonName,
          maxLength: TextLimits.name,
          onChanged: (v) => _onText(_TextField.name, v),
          validator: (v) => _validateName(v, all),
        ),
        description: description,
      );
    }
    return HeroCard(
      style: style,
      chips: [typeChip],
      onEdit: enterEdit,
      icon: EditableCircle(
        size: 40,
        onLongPress: _enterEditThenOpenMaker,
        child: IconDisplay(
          type: IconType.category,
          size: 40,
          iconCode: iconCode,
        ),
      ),
      description: description,
      number: _persisted == null
          ? null
          : HeroNumber(
              label: _monthLabel(l, isIncome),
              onLabelTap: _openMonthTransactions(),
              color: typeColor,
              value: MoneyText(_monthSpent),
            ),
    );
  }

  String? _validateName(String? v, List<Category> all) {
    final l = AppLocalizations.of(context)!;
    final name = v?.trim() ?? '';
    if (name.isEmpty) return l.categoryFormNameRequired;
    if (name.length > TextLimits.name) return l.categoryFormNameTooLong;
    if (CategoryTree.hasSiblingWithName(
      name: name,
      parentId: working.parentId,
      type: working.type,
      all: all,
      excludeId: _persisted?.id,
    )) {
      return l.categoryFormNameDuplicate;
    }
    return null;
  }
}

// ────────────────────────────────────────────────────────────────────
// Immutable editing snapshot — drives dirty-check + undo history.
// ────────────────────────────────────────────────────────────────────

class _CategoryDraft {
  const _CategoryDraft({
    this.name = '',
    this.type = CategoryType.expense,
    this.parentId,
    this.iconCode,
    this.description = '',
    this.note = '',
    this.includeInReport = true,
  });

  final String name;
  final CategoryType type;
  final String? parentId;
  final IconCode? iconCode;
  final String description;
  final String note;
  final bool includeInReport;

  factory _CategoryDraft.fromCategory(Category c) => _CategoryDraft(
    name: c.name,
    type: c.type,
    parentId: c.parentId,
    iconCode: c.iconCode,
    description: c.description ?? '',
    note: c.note ?? '',
    includeInReport: c.includeInReport,
  );

  /// What the server stores (text trimmed) — the post-save baseline.
  _CategoryDraft trimmed() => copyWith(
    name: name.trim(),
    description: description.trim(),
    note: note.trim(),
  );

  _CategoryDraft copyWith({
    String? name,
    CategoryType? type,
    String? parentId,
    bool clearParent = false,
    IconCode? iconCode,
    String? description,
    String? note,
    bool? includeInReport,
  }) {
    return _CategoryDraft(
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      iconCode: iconCode ?? this.iconCode,
      description: description ?? this.description,
      note: note ?? this.note,
      includeInReport: includeInReport ?? this.includeInReport,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _CategoryDraft &&
      other.name == name &&
      other.type == type &&
      other.parentId == parentId &&
      other.iconCode == iconCode &&
      other.description == description &&
      other.note == note &&
      other.includeInReport == includeInReport;

  @override
  int get hashCode => Object.hash(
    name,
    type,
    parentId,
    iconCode,
    description,
    note,
    includeInReport,
  );
}
