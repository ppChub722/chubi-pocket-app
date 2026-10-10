import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/text_limits.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/type_indicator.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../users/data/users_repository.dart';
import '../../domain/category.dart';
import '../../domain/category_reorder_logic.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../cubit/categories_cubit.dart';
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
  const CategoryDetailPage({this.editingId, this.initialType, super.key});

  final String? editingId;

  /// Create only: the type to start with (a picker for income opens the
  /// create page on income).
  final CategoryType? initialType;

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

  /// The user's fee category (preference `fee_category_id`, spec 15 §7):
  /// fee drafts from bank slips get it. Starts from the signed-in user,
  /// refreshed from `GET /users/me` (login answers without preferences).
  String? _feeCategoryId;
  bool _feeBusy = false;

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
    if (!widget.isCreate) _loadFeeCategory();
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

  Future<void> _loadFeeCategory() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) _feeCategoryId = auth.user.feeCategoryId;
    try {
      final me = await context.read<UsersRepository>().getMe();
      if (!mounted) return;
      setState(() => _feeCategoryId = me.feeCategoryId);
      context.read<AuthCubit>().updateUser(me);
    } on ApiException {
      // Keep what the signed-in user had; the switch still works.
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
      setState(() => _feeCategoryId = me.feeCategoryId);
    } on ApiException {
      if (mounted) {
        showAppSnackBar(context, l.categoryFeeSwitchFailed, tone: Tone.danger);
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
      showAppSnackBar(context, l.categoriesLimitReached, tone: Tone.warning);
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
        // Become the saved category right here — edit → view in place, as
        // contacts do. `replace` only fixes the URL: same page key, so no
        // transition and this state is kept.
        setState(() => _persisted = created);
        commitSaved(_CategoryDraft.fromCategory(created));
        context.replace('/categories/${created.id}');
        _loadFeeCategory();
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
        await cubit.update(next);
        _persisted = cubit.byId(next.id) ?? next;
      }
    } on CategoryLimitExceeded {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, l.categoriesLimitReached, tone: Tone.warning);
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    commitSaved(working.trimmed());
  }

  /// Always a real delete. The confirm spells out the fallout (fetched
  /// fresh): children move up, transactions become uncategorised, budgets
  /// on this category are deleted with it.
  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final c = _persisted!;
    final cubit = context.read<CategoriesCubit>();
    setSaving(true);
    final ({int transactions, int budgets}) usage;
    try {
      usage = await cubit.usage(c.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    setSaving(false);
    final ok = await showConfirmDialog(
      context,
      title: l.categoryDeleteTitle(c.name),
      message: [
        l.categoryDeleteBody,
        if (usage.transactions > 0)
          l.categoryDeleteTxImpact(usage.transactions),
        if (usage.budgets > 0) l.categoryDeleteBudgetImpact(usage.budgets),
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
      showAppSnackBar(context, e.message, tone: Tone.danger);
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

  /// L1 shows its own colours; L2/L3 inherit the L1 ancestor's (as the
  /// list does).
  IconCode? _resolvedDisplayIconCode() {
    if (working.parentId == null) return working.iconCode;
    final all = context.read<CategoriesCubit>().state.categories;
    String? cursor = working.parentId;
    while (cursor != null) {
      final parent = all.firstWhere(
        (c) => c.id == cursor,
        orElse: () => Category(id: cursor!, name: '', type: working.type),
      );
      if (parent.parentId == null) return parent.iconCode;
      cursor = parent.parentId;
    }
    return working.iconCode;
  }

  bool get _isColorEditable => working.parentId == null;

  String? _parentBreadcrumb(List<Category> all) {
    if (working.parentId == null) return null;
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
      showColorSection: _isColorEditable,
      previewBuilder: (iconCode) => CategoryPreviewCard(
        category: _previewCategory().copyWith(iconCode: iconCode),
        parentPath: breadcrumb,
      ),
    );
    if (!mounted || result is! IconMakerSelected) return;
    if (_isColorEditable) {
      applyChange(working.copyWith(iconCode: result.iconCode));
    } else {
      // L2/L3: keep own colours, take only the glyph.
      final next = (working.iconCode ?? const IconCode()).copyWith(
        icon: result.iconCode.icon,
      );
      applyChange(working.copyWith(iconCode: next));
    }
  }

  Future<void> _openParentPicker(List<Category> all) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<CategoriesCubit>();
    final selectedParent = working.parentId == null
        ? null
        : cubit.byId(working.parentId!);
    // Can't parent into yourself or your own subtree (would cycle).
    final exclude = _persisted == null
        ? const <String>{}
        : CategoryReorderLogic.subtreeIds(_persisted!.id, all).toSet();
    final result = await showCategoryPickerSheet(
      context: context,
      categories: all,
      type: working.type,
      selected: selectedParent,
      allowNone: true,
      noneLabel: l.categoryFormParentNone,
      title: l.categoryFormParentLabel,
      maxDepth: 1, // L1 + L2 only — a child of this stays within 3 levels
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
              body: _notFound
                  ? EmptyView(
                      icon: AppIcons.empty,
                      title: l.categoryDetailNotFound,
                      message: l.categoryDetailNotFoundMessage,
                    )
                  : const LoadingView(),
            ),
    );
  }

  Widget _page(AppLocalizations l) {
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
        body: BlocBuilder<CategoriesCubit, CategoriesState>(
          // This context sits inside the Scaffold body, so it sees the bar
          // height in its top padding.
          builder: (context, state) => Form(
            key: _formKey,
            child: PullToRefresh(
              enabled: !_isCreate,
              onRefresh: context.read<CategoriesCubit>().load,
              child: _body(
                l,
                state.categories,
                topInset: MediaQuery.paddingOf(context).top,
                bottomInset: MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ),
        ),
        bottomNavigationBar: isEditing ? editActionBar(onSave: _save) : null,
      ),
    );
  }

  String _title(AppLocalizations l) {
    if (_isCreate) return l.categoryFormTitleNew;
    if (isEditing) return l.categoryFormTitleEdit;
    return working.name.isEmpty ? l.categoriesTitle : working.name;
  }

  /// [topInset] / [bottomInset] clear the transparent top bar and the
  /// floating nav (read from a context inside the Scaffold body).
  Widget _body(
    AppLocalizations l,
    List<Category> all, {
    required double topInset,
    required double bottomInset,
  }) {
    final editing = isEditing;
    final preview = _previewCategory();
    final breadcrumb = _parentBreadcrumb(all);
    final canDelete = !_isCreate && !(_persisted?.isSystem ?? true);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topInset + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.huge + bottomInset,
      ),
      children: [
        _Header(
          category: preview,
          parentPath: breadcrumb,
          editing: editing,
          onEdit: editing ? null : enterEdit,
          nameField: InlineTitleField(
            editing: editing,
            controller: _nameController,
            focusNode: _nameFocus,
            hint: l.commonName,
            maxLength: TextLimits.name,
            onEnterEdit: () => enterEdit(focus: _nameFocus),
            onChanged: (v) => _onText(_TextField.name, v),
            validator: (v) => _validateName(v, all),
          ),
          onIconTap: _openIconMaker,
          onIconLongPress: _enterEditThenOpenMaker,
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          first: true,
          children: [
            // Type is immutable once created (spec §3.4).
            DetailRow(
              label: l.categoryFormTypeLabel,
              helper: _isCreate ? null : l.categoryFormTypeImmutableHelper,
              trailing: _typeTrailing(l),
            ),
            // The parent picker — the row opens the category picker.
            DetailRow(
              label: l.categoryFormParentLabel,
              showChevron: true,
              onTap: () => _openParentPicker(all),
              trailing: _parentValue(l, breadcrumb),
            ),
            // maxLength caps the input, so no length validator.
            DetailStacked(
              label: l.commonDescription,
              child: InlineField(
                editing: editing,
                controller: _descriptionController,
                focusNode: _descriptionFocus,
                maxLines: 3,
                maxLength: TextLimits.description,
                onEnterEdit: () => enterEdit(focus: _descriptionFocus),
                onChanged: (v) => _onText(_TextField.description, v),
              ),
            ),
            DetailStacked(
              label: l.commonNote,
              child: InlineField(
                editing: editing,
                controller: _noteController,
                focusNode: _noteFocus,
                maxLines: 3,
                maxLength: TextLimits.note,
                onEnterEdit: () => enterEdit(focus: _noteFocus),
                onChanged: (v) => _onText(_TextField.note, v),
              ),
            ),
            DetailRow(
              label: l.categoryFormIncludeInReportLabel,
              helper: l.categoryFormIncludeInReportHelper,
              trailing: Switch(
                value: working.includeInReport,
                onChanged: (v) =>
                    applyChange(working.copyWith(includeInReport: v)),
              ),
            ),
            // Expense categories only, and only once saved (needs an id).
            if (_persisted != null && working.type == CategoryType.expense)
              DetailRow(
                label: l.categoryFeeSwitchLabel,
                helper: l.categoryFeeSwitchHelper,
                trailing: Switch(
                  value: _feeCategoryId == _persisted!.id,
                  onChanged: _feeBusy ? null : _setFeeCategory,
                ),
              ),
          ],
        ),
        // Delete lives at the bottom of the body in edit mode (the top bar
        // carries no page actions).
        if (editing && canDelete)
          DangerRow(
            icon: AppIcons.delete,
            label: l.categoryDelete,
            onTap: isSaving ? null : _delete,
          ),
      ],
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

  /// Type: a fixed [TypeIndicator] once saved; while creating, an
  /// expense / income [ChoicePill] pair (changing it clears the parent).
  Widget _typeTrailing(AppLocalizations l) {
    final isIncome = working.type == CategoryType.income;
    if (!_isCreate) return TypeIndicator(isIncome: isIncome);
    Widget pill(CategoryType t, String label) => ChoicePill(
      label: label,
      size: PillSize.medium,
      selected: working.type == t,
      onTap: () => applyChange(working.copyWith(type: t, clearParent: true)),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        pill(CategoryType.expense, l.categoryTypeExpense),
        const SizedBox(width: AppSpacing.sm),
        pill(CategoryType.income, l.categoryTypeIncome),
      ],
    );
  }

  /// The parent row's value: its icon + breadcrumb, or "none".
  Widget _parentValue(AppLocalizations l, String? breadcrumb) {
    final iconCode = working.parentId == null
        ? null
        : context.read<CategoriesCubit>().byId(working.parentId!)?.iconCode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (breadcrumb != null && iconCode != null) ...[
          IconDisplay(type: IconType.category, size: 20, iconCode: iconCode),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            breadcrumb ?? l.categoryFormParentNone,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Header — kit HeaderCard with the category's accent border. View mode:
// ✏️ chip → edit; long-press the icon → edit + maker. Edit mode: tap the
// icon → maker.
// ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.category,
    required this.parentPath,
    required this.editing,
    required this.nameField,
    required this.onIconTap,
    required this.onIconLongPress,
    this.onEdit,
  });

  final Category category;
  final String? parentPath;
  final bool editing;
  final Widget nameField;
  final VoidCallback onIconTap;
  final VoidCallback onIconLongPress;

  /// The ✏️ chip (view mode → edit); null while editing.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final hasPath = parentPath != null && parentPath!.isNotEmpty;
    return HeaderCard(
      accent: category.iconCode?.accentColorFor(palette) ?? palette.primary,
      onEdit: onEdit,
      // EditableCircle keeps a constant footprint with or without onTap,
      // so the name column never shifts between modes.
      leading: GestureDetector(
        onLongPress: editing ? null : onIconLongPress,
        child: EditableCircle(
          size: 44,
          onTap: editing ? onIconTap : null,
          child: IconDisplay(
            type: IconType.category,
            size: 44,
            iconCode: category.iconCode,
          ),
        ),
      ),
      title: nameField,
      subtitle: hasPath || !category.includeInReport
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPath)
                  Text(
                    parentPath!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (!category.includeInReport)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: LabelPill(
                      label: l.categoryHiddenFromReport,
                      icon: AppIcons.hidden,
                      size: PillSize.small,
                    ),
                  ),
              ],
            )
          : null,
    );
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
