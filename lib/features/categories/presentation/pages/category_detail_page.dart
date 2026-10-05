import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/main_bottom_nav.dart';
import '../../../../app/shell/more_menu_sheet.dart';
import '../../../transactions/presentation/pages/transaction_form_page.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/editable_circle.dart';
import '../../../../shared/widgets/reorder_action_bar.dart';
import '../../../../shared/widgets/type_indicator.dart';
import '../../domain/category.dart';
import '../../domain/category_reorder_logic.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../cubit/categories_cubit.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/category_preview_card.dart';

/// Editable-detail surface for a single category — one screen with two
/// modes, per the Phase 2 inline-edit UX model
/// (`product/phase2/inline-edit-ux.md`). Replaces the old `CategoryFormPage`
/// + `/:id/edit` route.
///
/// **One constant layout, two modes.** Every field is the *same* widget in
/// both modes — only its chrome changes, so nothing ever reflows:
/// - **view mode**: borderless, read-only text.
/// - **edit mode**: bordered, editable.
///
/// Text fields are edited inline; the icon opens the icon maker (a modal).
/// Discrete controls — the **type** chips (create only) and the
/// **include-in-report** switch — are live even in view mode: tapping one
/// applies the change *and* auto-enters edit mode (so the Cancel · Undo ·
/// Save bar appears). Tapping a read-only text field also enters edit mode
/// and focuses it.
///
/// Pushed **above the shell** (root navigator, full-screen dialog) → no
/// bottom nav; the AppBar auto-shows a close (✕).
///
/// **Undo** is snapshot-based: discrete controls = one step each; text
/// fields coalesce a burst into one step closed by a 0.5 s pause (or any
/// other action); undo mid-typing reverts the current burst; unlimited
/// history; undoing back to the original auto-cancels (create → pops).
class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({this.editingId, super.key});

  final String? editingId;

  bool get isCreate => editingId == null;

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

/// Which text field an open typing session belongs to.
enum _TextField { name, description, note }

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _noteFocus = FocusNode();

  /// The persisted category (edit mode only) — kept so Save can
  /// `copyWith` onto it, preserving id / sortOrder / isSystem.
  Category? _persisted;
  bool _notFound = false;

  bool _editMode = false;
  bool _saving = false;

  /// Saved/baseline values; `_working` is what the user is editing.
  late _CategoryDraft _original;
  late _CategoryDraft _working;

  /// Undo history — snapshots of the state *before* each committed change.
  final List<_CategoryDraft> _undoStack = [];

  /// Open text-typing session: snapshot of state at the start of the
  /// current burst, plus which field it's for. Null when no session.
  _CategoryDraft? _sessionStart;
  _TextField? _sessionField;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.isCreate) {
      _original = const _CategoryDraft();
      _working = _original;
      _editMode = true; // create opens straight into edit mode
    } else {
      final existing = context.read<CategoriesCubit>().byId(widget.editingId!);
      if (existing == null) {
        _notFound = true;
        _original = const _CategoryDraft();
        _working = _original;
      } else {
        _persisted = existing;
        _original = _CategoryDraft.fromCategory(existing);
        _working = _original;
      }
    }
    _syncControllers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  bool get _dirty => _working != _original;
  bool get _canUndo => _sessionStart != null || _undoStack.isNotEmpty;

  // ── Edit-mode entry ─────────────────────────────────────────────────

  void _enterEditMode() {
    if (_editMode) return;
    HapticFeedback.lightImpact();
    setState(() => _editMode = true);
  }

  /// Long-pressing a read-only text field enters edit mode and focuses it.
  void _enterEditModeAndFocus(FocusNode node) {
    if (!_editMode) {
      HapticFeedback.lightImpact();
      setState(() => _editMode = true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) node.requestFocus();
    });
  }

  /// Long-pressing the icon enters edit mode and opens the icon maker.
  void _enterEditThenOpenMaker() {
    _enterEditMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openIconMaker();
    });
  }

  /// Cancel = revert everything. Edit → back to view mode (stay). Create →
  /// nothing to view, so leave the page.
  void _cancel() {
    if (widget.isCreate) {
      _leavePage();
      return;
    }
    _debounce?.cancel();
    _debounce = null;
    FocusScope.of(context).unfocus();
    setState(() {
      _working = _original;
      _undoStack.clear();
      _sessionStart = null;
      _sessionField = null;
      _editMode = false;
      _saving = false;
      _syncControllers();
    });
  }

  void _leavePage() {
    if (context.canPop()) context.pop();
  }

  /// Top back / system back. In edit mode it acts like Cancel but asks a
  /// discard confirm first (spec item 10); in view mode it leaves the page.
  Future<void> _handleBack() async {
    if (_saving) return;
    if (_editMode) {
      if (_dirty) {
        final l = AppLocalizations.of(context)!;
        final ok = await _confirmDiscard(context, l);
        if (!ok) return;
      }
      _cancel();
    } else {
      _leavePage();
    }
  }

  // ── Undo ────────────────────────────────────────────────────────────

  /// Close any open text session into a single undo step. Called by the
  /// debounce timer and before every non-text action.
  void _commitTextSession() {
    _debounce?.cancel();
    _debounce = null;
    final start = _sessionStart;
    _sessionStart = null;
    _sessionField = null;
    if (start != null && start != _working) {
      _undoStack.add(start);
    }
  }

  void _onTextChanged(_TextField field, String value) {
    if (_sessionStart == null) {
      _sessionStart = _working;
      _sessionField = field;
    } else if (_sessionField != field) {
      // Moved to a different text field → cut the previous burst first.
      _commitTextSession();
      _sessionStart = _working;
      _sessionField = field;
    }
    setState(() => _working = _withText(field, value));
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => setState(_commitTextSession),
    );
  }

  /// Apply a discrete (non-text) change as exactly one undo step. Also
  /// auto-enters edit mode — switches / chips / icon are live in view mode.
  void _applyDiscrete(_CategoryDraft next) {
    _commitTextSession();
    setState(() {
      _editMode = true;
      _undoStack.add(_working);
      _working = next;
    });
    HapticFeedback.selectionClick();
  }

  void _undo() {
    HapticFeedback.selectionClick();
    if (_sessionStart != null) {
      // Mid-typing: revert the current burst to where it started.
      final start = _sessionStart!;
      _debounce?.cancel();
      _debounce = null;
      _sessionStart = null;
      _sessionField = null;
      setState(() {
        _working = start;
        _syncControllers();
      });
    } else if (_undoStack.isNotEmpty) {
      setState(() {
        _working = _undoStack.removeLast();
        _syncControllers();
      });
    }
    // Undone back to the original → auto-cancel + leave edit mode.
    if (_sessionStart == null && _undoStack.isEmpty && !_dirty) {
      _cancel();
    }
  }

  // ── Save ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    _commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<CategoriesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context)!;

    if (widget.isCreate && !cubit.canAddMore) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.categoriesLimitReached)));
      return;
    }

    final description = _working.description.trim();
    final note = _working.note.trim();

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      if (widget.isCreate) {
        await cubit.add(Category(
          id: 'draft',
          name: _working.name.trim(),
          type: _working.type,
          iconCode: _working.iconCode,
          parentId: _working.parentId,
          description: description.isEmpty ? null : description,
          note: note.isEmpty ? null : note,
          includeInReport: _working.includeInReport,
        ));
      } else {
        await cubit.update(_persisted!.copyWith(
          name: _working.name.trim(),
          parentId: _working.parentId,
          clearParent: _working.parentId == null,
          iconCode: _working.iconCode,
          description: description.isEmpty ? null : description,
          note: note.isEmpty ? null : note,
          includeInReport: _working.includeInReport,
        ));
      }
    } on CategoryLimitExceeded {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.categoriesLimitReached)));
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();

    if (widget.isCreate) {
      _leavePage();
      return;
    }
    // Edit: re-baseline to the just-saved values, drop to view mode.
    _persisted = _persisted!.copyWith(
      name: _working.name.trim(),
      parentId: _working.parentId,
      clearParent: _working.parentId == null,
      iconCode: _working.iconCode,
      description: description.isEmpty ? null : description,
      note: note.isEmpty ? null : note,
      includeInReport: _working.includeInReport,
    );
    setState(() {
      _original = _working;
      _undoStack.clear();
      _editMode = false;
      _saving = false;
    });
  }

  // ── Working-state helpers ───────────────────────────────────────────

  _CategoryDraft _withText(_TextField field, String value) {
    switch (field) {
      case _TextField.name:
        return _working.copyWith(name: value);
      case _TextField.description:
        return _working.copyWith(description: value);
      case _TextField.note:
        return _working.copyWith(note: value);
    }
  }

  void _syncControllers() {
    if (_nameController.text != _working.name) {
      _nameController.text = _working.name;
    }
    if (_descriptionController.text != _working.description) {
      _descriptionController.text = _working.description;
    }
    if (_noteController.text != _working.note) {
      _noteController.text = _working.note;
    }
  }

  Category _previewCategory() {
    return Category(
      id: _persisted?.id ?? 'preview',
      name: _working.name,
      type: _working.type,
      iconCode: _resolvedDisplayIconCode(),
      parentId: _working.parentId,
      includeInReport: _working.includeInReport,
    );
  }

  /// IconCode the icon should show. L1 uses its own; L2/L3 inherit the
  /// colour from the L1 ancestor (matches the list's colour inheritance).
  IconCode? _resolvedDisplayIconCode() {
    if (_working.parentId == null) return _working.iconCode;
    final all = context.read<CategoriesCubit>().state.categories;
    String? cursor = _working.parentId;
    while (cursor != null) {
      final parent = all.firstWhere(
        (c) => c.id == cursor,
        orElse: () => Category(id: cursor!, name: '', type: _working.type),
      );
      if (parent.parentId == null) return parent.iconCode;
      cursor = parent.parentId;
    }
    return _working.iconCode;
  }

  bool get _isColorEditable => _working.parentId == null;

  String? _parentBreadcrumb(List<Category> all) {
    if (_working.parentId == null) return null;
    final parent = all.firstWhere(
      (c) => c.id == _working.parentId,
      orElse: () => _previewCategory(),
    );
    final ancestors = CategoryTree.breadcrumb(parent, all);
    return ancestors.isEmpty ? parent.name : '$ancestors › ${parent.name}';
  }

  Future<void> _openIconMaker() async {
    final l = AppLocalizations.of(context)!;
    final all = context.read<CategoriesCubit>().state.categories;
    final breadcrumb = _parentBreadcrumb(all);
    final displayIconCode = _resolvedDisplayIconCode();

    final result = await showIconMakerSheet(
      context: context,
      type: IconType.category,
      initial: displayIconCode,
      iconSectionLabel: l.categoryFormIconLabel,
      colorSectionLabel: l.categoryFormColorLabel,
      showColorSection: _isColorEditable,
      previewBuilder: (iconCode) => CategoryPreviewCard(
        category: _previewCategory().copyWith(iconCode: iconCode),
        parentPath: breadcrumb,
      ),
    );
    if (!mounted || result == null) return;
    if (result is IconMakerSelected) {
      if (_isColorEditable) {
        _applyDiscrete(_working.copyWith(iconCode: result.iconCode));
      } else {
        // L2/L3: keep own bgColors, update only the glyph.
        final next = (_working.iconCode ?? const IconCode())
            .copyWith(icon: result.iconCode.icon);
        _applyDiscrete(_working.copyWith(iconCode: next));
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (_notFound) {
      return Scaffold(
        appBar: AppTopBar(title: l.categoryFormTitleEdit, showBack: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(l.categoriesEmptyTitle, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_editMode && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: _titleFor(l),
          showBack: true,
          onBack: _handleBack,
          actions: _editMode
              ? const <AppBarAction>[]
              : [
                  AppBarAction(
                    icon: Icons.edit_outlined,
                    tooltip: l.commonEdit,
                    onPressed: _enterEditMode,
                  ),
                ],
        ),
        body: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            final all = state.categories;
            return Form(
              key: _formKey,
              child: _buildBody(l, all, _editMode),
            );
          },
        ),
        bottomNavigationBar: _editMode
            ? ReorderActionBar(
                canUndo: _canUndo && !_saving,
                canSave: _dirty && !_saving,
                cancelLabel: l.commonCancel,
                saveLabel: l.commonSave,
                undoTooltip: l.categoriesUndo,
                onCancel: _saving ? () {} : _cancel,
                onUndo: _undo,
                onSave: _save,
              )
            // View mode: the universal bottom nav (this page sits above the
            // shell, so it brings its own). Edit mode replaces it with the
            // action bar above.
            : MainBottomNav(
                currentIndex: -1,
                onTabSelected: (i) {
                  switch (i) {
                    case 0:
                      context.go('/');
                    case 1:
                      context.go('/transactions');
                    case 2:
                      context.go('/accounts');
                  }
                },
                onAddPressed: () => showTransactionFormSheet(context),
                onMorePressed: () => MoreMenuSheet.show(context),
              ),
      ),
    );
  }

  String _titleFor(AppLocalizations l) {
    if (widget.isCreate) return l.categoryFormTitleNew;
    if (_editMode) return l.categoryFormTitleEdit;
    return _working.name.isEmpty ? l.categoriesTitle : _working.name;
  }

  /// One layout for both modes — a grouped card of aligned rows (label left,
  /// value right; long text full-width under its label). Fields keep the
  /// same box in view + edit, only toggling border + editability.
  Widget _buildBody(AppLocalizations l, List<Category> all, bool editing) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.huge,
      ),
      children: [
        // Header card (icon + name + breadcrumb). View mode: long-press
        // the icon → edit + maker, long-press the name → edit + focus.
        // Edit mode: tap the icon → maker, name is an inline field.
        _HeaderCard(
          category: _previewCategory(),
          parentPath: _parentBreadcrumb(all),
          editing: editing,
          nameController: _nameController,
          nameFocus: _nameFocus,
          onIconTap: _openIconMaker,
          onIconLongPress: _enterEditThenOpenMaker,
          onNameLongPress: () => _enterEditModeAndFocus(_nameFocus),
          onNameChanged: (v) => _onTextChanged(_TextField.name, v),
          nameValidator: (v) => _validateName(v, all),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionCard(
          children: [
            // Type — immutable on an existing category (spec §3.4);
            // selectable only while creating.
            _DetailRow(
              label: l.categoryFormTypeLabel,
              helper:
                  widget.isCreate ? null : l.categoryFormTypeImmutableHelper,
              trailing: _typeTrailing(l),
            ),
            const _RowDivider(),
            _DetailRow(
              label: l.categoryFormParentLabel,
              trailing: _parentTrailing(l, all),
            ),
            const _RowDivider(),
            _DetailStacked(
              label: l.categoryFormDescriptionLabel,
              child: _InlineField(
                editing: editing,
                controller: _descriptionController,
                focusNode: _descriptionFocus,
                maxLines: 3,
                onEnterEdit: () =>
                    _enterEditModeAndFocus(_descriptionFocus),
                onChanged: (v) => _onTextChanged(_TextField.description, v),
                validator: (v) => (v != null && v.length > 200)
                    ? l.categoryFormDescriptionTooLong
                    : null,
              ),
            ),
            const _RowDivider(),
            _DetailStacked(
              label: l.categoryFormNoteLabel,
              child: _InlineField(
                editing: editing,
                controller: _noteController,
                focusNode: _noteFocus,
                maxLines: 2,
                onEnterEdit: () => _enterEditModeAndFocus(_noteFocus),
                onChanged: (v) => _onTextChanged(_TextField.note, v),
                validator: (v) => (v != null && v.length > 200)
                    ? l.categoryFormNoteTooLong
                    : null,
              ),
            ),
            const _RowDivider(),
            // Include-in-report — live switch in both modes: toggling
            // auto-enters edit mode.
            _DetailRow(
              label: l.categoryFormIncludeInReportLabel,
              helper: l.categoryFormIncludeInReportHelper,
              trailing: Switch(
                value: _working.includeInReport,
                onChanged: (v) =>
                    _applyDiscrete(_working.copyWith(includeInReport: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _validateName(String? v, List<Category> all) {
    final l = AppLocalizations.of(context)!;
    final name = v?.trim() ?? '';
    if (name.isEmpty) return l.categoryFormNameRequired;
    if (name.length > 100) return l.categoryFormNameTooLong;
    if (CategoryTree.hasSiblingWithName(
      name: name,
      parentId: _working.parentId,
      type: _working.type,
      all: all,
      excludeId: _persisted?.id,
    )) {
      return l.categoryFormNameDuplicate;
    }
    return null;
  }

  Widget _typeTrailing(AppLocalizations l) {
    final isIncome = _working.type == CategoryType.income;
    if (widget.isCreate) {
      // Selectable: two pills; the unselected one is dimmed.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypePill(
            isIncome: false,
            selected: !isIncome,
            onTap: () => _applyDiscrete(
              _working.copyWith(type: CategoryType.expense, clearParent: true),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _TypePill(
            isIncome: true,
            selected: isIncome,
            onTap: () => _applyDiscrete(
              _working.copyWith(type: CategoryType.income, clearParent: true),
            ),
          ),
        ],
      );
    }
    // Existing: read-only indicator (type is immutable).
    return TypeIndicator(isIncome: isIncome);
  }

  Widget _parentTrailing(AppLocalizations l, List<Category> all) {
    final cat = _working.parentId == null
        ? null
        : context.read<CategoriesCubit>().byId(_working.parentId!);
    return _ParentBox(
      breadcrumb: _parentBreadcrumb(all),
      iconCode: cat?.iconCode,
      isNone: _working.parentId == null,
      noneLabel: l.categoryFormParentNone,
      onTap: () => _openParentPicker(all),
    );
  }

  Future<void> _openParentPicker(List<Category> all) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<CategoriesCubit>();
    final selectedParent =
        _working.parentId == null ? null : cubit.byId(_working.parentId!);
    // Can't parent into yourself or your own subtree (would cycle).
    final exclude = _persisted == null
        ? const <String>{}
        : CategoryReorderLogic.subtreeIds(_persisted!.id, all).toSet();
    final result = await showCategoryPickerSheet(
      context: context,
      categories: all,
      type: _working.type,
      selected: selectedParent,
      allowNone: true,
      noneLabel: l.categoryFormParentNone,
      title: l.categoryFormParentLabel,
      maxDepth: 1, // L1 + L2 only — a child of this stays within 3 levels
      excludeIds: exclude,
    );
    if (!mounted || result == null) return;
    if (result is CategoryPickerSelected) {
      _applyDiscrete(_working.copyWith(parentId: result.category.id));
    } else if (result is CategoryPickerCleared) {
      _applyDiscrete(_working.copyWith(clearParent: true));
    }
  }

  Future<bool> _confirmDiscard(BuildContext context, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.categoryFormDiscardTitle),
        content: Text(l.categoryFormDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.commonRemove),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

// ────────────────────────────────────────────────────────────────────
// Field border — same shape always; only the colour changes between
// modes so the box keeps its exact size (no reflow view↔edit).
// ────────────────────────────────────────────────────────────────────

UnderlineInputBorder _underlineBorder(Color color) =>
    UnderlineInputBorder(borderSide: BorderSide(color: color));

OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );

/// A text field that reads as plain text in view mode (transparent
/// underline, read-only) and as an editable field in edit mode — same
/// metrics either way, so the row never shifts. The label is supplied by
/// the enclosing [_DetailStacked] row.
class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.editing,
    required this.controller,
    required this.focusNode,
    required this.onEnterEdit,
    required this.onChanged,
    this.validator,
    this.maxLines = 1,
  });

  final bool editing;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onEnterEdit;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: !editing,
      maxLines: maxLines,
      maxLength: 200,
      style: Theme.of(context).textTheme.bodyLarge,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        // Empty + view mode → a friendly "long-press to edit" hint instead
        // of a blank line (spec item 9).
        hintText: editing
            ? null
            : AppLocalizations.of(context)!.commonLongPressToEdit,
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
        filled: false,
        isDense: true,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder:
            _fieldBorder(editing ? scheme.outline : Colors.transparent),
        focusedBorder: _fieldBorder(scheme.primary),
        border: _fieldBorder(editing ? scheme.outline : Colors.transparent),
      ),
    );
    if (editing) return field;
    // View mode: block field interaction; long-press enters edit + focus.
    return GestureDetector(
      onLongPress: onEnterEdit,
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(child: field),
    );
  }
}

/// Groups the detail rows with hairline dividers — no outer frame, the
/// fields just sit tidily on the page, separated by lines.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// A row: label (left) + value/control (right), with an optional helper
/// line under it.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.trailing,
    this.helper,
  });

  final String label;
  final Widget trailing;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      // Value is vertically centred against the whole label+helper block.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                ),
                if (helper != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    helper!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row for long values: label on top, value full-width below.
class _DetailStacked extends StatelessWidget {
  const _DetailStacked({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

/// Hairline divider between detail rows.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Header card (icon + name + breadcrumb) — the original bordered-card
// look. Name shows as text in view mode and becomes an inline field in
// edit mode; the icon opens the maker. View-mode long-press on the icon
// or name enters edit mode.
// ────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.category,
    required this.parentPath,
    required this.editing,
    required this.nameController,
    required this.nameFocus,
    required this.onIconTap,
    required this.onIconLongPress,
    required this.onNameLongPress,
    required this.onNameChanged,
    required this.nameValidator,
  });

  final Category category;
  final String? parentPath;
  final bool editing;
  final TextEditingController nameController;
  final FocusNode nameFocus;
  final VoidCallback onIconTap;
  final VoidCallback onIconLongPress;
  final VoidCallback onNameLongPress;
  final ValueChanged<String> onNameChanged;
  final FormFieldValidator<String> nameValidator;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent =
        category.iconCode?.accentColorFor(palette) ?? palette.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // EditableCircle keeps a constant 44×44 footprint whether or
            // not onTap is set, so the name column never shifts. View mode:
            // long-press → edit + maker. Edit mode: tap → maker (pencil).
            GestureDetector(
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
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Same field widget in both modes → identical height, so
                  // the card never grows when entering edit. View mode just
                  // hides the underline + blocks input (long-press enters).
                  Builder(builder: (context) {
                    final nameField = TextFormField(
                      controller: nameController,
                      focusNode: nameFocus,
                      readOnly: !editing,
                      maxLength: 100,
                      style: Theme.of(context).textTheme.titleMedium,
                      decoration: InputDecoration(
                        filled: false,
                        isDense: true,
                        counterText: '',
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 4),
                        hintText: l.categoryFormNameLabel,
                        enabledBorder: _underlineBorder(
                            editing ? scheme.outline : Colors.transparent),
                        focusedBorder: _underlineBorder(scheme.primary),
                        border: _underlineBorder(
                            editing ? scheme.outline : Colors.transparent),
                      ),
                      onChanged: onNameChanged,
                      validator: nameValidator,
                    );
                    if (editing) return nameField;
                    return GestureDetector(
                      onLongPress: onNameLongPress,
                      behavior: HitTestBehavior.opaque,
                      child: AbsorbPointer(child: nameField),
                    );
                  }),
                  if (parentPath != null && parentPath!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      parentPath!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  if (!category.includeInReport) ...[
                    const SizedBox(height: 2),
                    Text(
                      l.categoryHiddenFromReport,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Type + parent controls.
// ────────────────────────────────────────────────────────────────────

/// Tappable income/expense choice (create mode). The unselected one dims;
/// the selected one shows at full strength.
class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.isIncome,
    required this.selected,
    required this.onTap,
  });

  final bool isIncome;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: selected ? 1 : 0.4,
        child: TypeIndicator(isIncome: isIncome),
      ),
    );
  }
}

/// Chip showing the current parent (icon + breadcrumb) or the "none"
/// label; tapping opens the shared category picker.
class _ParentBox extends StatelessWidget {
  const _ParentBox({
    required this.breadcrumb,
    required this.iconCode,
    required this.isNone,
    required this.noneLabel,
    required this.onTap,
  });

  final String? breadcrumb;
  final IconCode? iconCode;
  final bool isNone;
  final String noneLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isNone && iconCode != null) ...[
              IconDisplay(
                type: IconType.category,
                size: 20,
                iconCode: iconCode,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                isNone ? noneLabel : (breadcrumb ?? noneLabel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.unfold_more, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
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
