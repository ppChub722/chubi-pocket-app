import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/icon_color_picker_sheet.dart';
import '../../domain/category.dart';
import '../../domain/category_icon_preset.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../cubit/categories_cubit.dart';
import '../widgets/category_preview_card.dart';

/// Create / edit a single category. Routed at `/categories/new` and
/// `/categories/:id/edit` outside the shell — owns its own Scaffold +
/// AppBar with a back button.
///
/// Phase 0 mock: Save adds / updates the category in [CategoriesCubit] in
/// memory and pops back. Phase 1a will hit `POST /v1/categories` /
/// `PUT /v1/categories/:id` with the same shape.
///
/// Sections (top to bottom):
/// - Live preview ([CategoryPreviewCard]) — tap icon → unified picker
/// - Type chips (immutable on edit, per spec §3.4)
/// - Name (1–100, unique among siblings of same type)
/// - Parent dropdown (filtered by [CategoryTree.eligibleParents])
/// - Description (~200, optional)
/// - Note (~200, optional)
/// - Include in reports switch
class CategoryFormPage extends StatefulWidget {
  const CategoryFormPage({this.editingId, super.key});

  /// When non-null, the form is in edit mode; values are prefilled from
  /// [CategoriesCubit.byId] and Save calls `update()` instead of `add()`.
  final String? editingId;

  bool get isEdit => editingId != null;

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  CategoryType _type = CategoryType.expense;
  String? _parentId;
  CategoryIconPreset _icon = CategoryIconPreset.category;
  CategoryColor _color = CategoryColor.blue;
  bool _includeInReport = true;

  Category? _initial;

  @override
  void initState() {
    super.initState();
    if (widget.editingId != null) {
      // Read the cubit synchronously here — the form clones the values
      // into its controllers and never reads from the cubit again until
      // Save. This keeps editing-experience stable even if other widgets
      // emit on the same cubit.
      final existing =
          context.read<CategoriesCubit>().byId(widget.editingId!);
      if (existing != null) {
        _initial = existing;
        _nameController.text = existing.name;
        _descriptionController.text = existing.description ?? '';
        _noteController.text = existing.note ?? '';
        _type = existing.type;
        _parentId = existing.parentId;
        _icon = existing.icon;
        _color = existing.color;
        _includeInReport = existing.includeInReport;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _dirty {
    if (_initial == null) {
      // Create mode — dirty if anything has been entered beyond defaults.
      return _nameController.text.isNotEmpty ||
          _descriptionController.text.isNotEmpty ||
          _noteController.text.isNotEmpty ||
          _parentId != null ||
          _icon != CategoryIconPreset.category ||
          _color.id != CategoryColor.blue.id ||
          _includeInReport != true ||
          _type != CategoryType.expense;
    }
    final i = _initial!;
    return _nameController.text != i.name ||
        _descriptionController.text != (i.description ?? '') ||
        _noteController.text != (i.note ?? '') ||
        _parentId != i.parentId ||
        _icon != i.icon ||
        _color.id != i.color.id ||
        _includeInReport != i.includeInReport;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard(context, l);
        if (ok && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEdit ? l.categoryFormTitleEdit : l.categoryFormTitleNew,
          ),
        ),
        body: Form(
          key: _formKey,
          child: BlocBuilder<CategoriesCubit, CategoriesState>(
            builder: (context, state) {
              final all = state.categories;
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.huge,
                ),
                children: [
                  _SectionLabel(text: l.categoryFormPreviewLabel),
                  CategoryPreviewCard(
                    category: _previewCategory(),
                    parentPath: _parentBreadcrumb(all),
                    onIconTap: () => _openIconPicker(context, l),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(text: l.categoryFormTypeLabel),
                  _TypeChips(
                    selected: _type,
                    onSelected: widget.isEdit
                        ? null
                        : (t) => setState(() {
                              _type = t;
                              _parentId = null; // type change resets parent
                            }),
                  ),
                  if (widget.isEdit) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l.categoryFormTypeImmutableHelper,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _nameController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: l.categoryFormNameLabel,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final name = v?.trim() ?? '';
                      if (name.isEmpty) return l.categoryFormNameRequired;
                      if (name.length > 100) return l.categoryFormNameTooLong;
                      if (CategoryTree.hasSiblingWithName(
                        name: name,
                        parentId: _parentId,
                        type: _type,
                        all: all,
                        excludeId: _initial?.id,
                      )) {
                        return l.categoryFormNameDuplicate;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ParentDropdown(
                    all: all,
                    self: _initial,
                    type: _type,
                    selected: _parentId,
                    onChanged: (id) => setState(() => _parentId = id),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descriptionController,
                    maxLength: 200,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l.categoryFormDescriptionLabel,
                      helperText: l.categoryFormDescriptionHelper,
                      helperMaxLines: 2,
                    ),
                    validator: (v) =>
                        (v != null && v.length > 200)
                            ? l.categoryFormDescriptionTooLong
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _noteController,
                    maxLength: 200,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l.categoryFormNoteLabel,
                      helperText: l.categoryFormNoteHelper,
                      helperMaxLines: 2,
                    ),
                    validator: (v) => (v != null && v.length > 200)
                        ? l.categoryFormNoteTooLong
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _includeInReport,
                    onChanged: (v) =>
                        setState(() => _includeInReport = v),
                    title: Text(l.categoryFormIncludeInReportLabel),
                    subtitle: Text(l.categoryFormIncludeInReportHelper),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l.categoryFormSave),
            ),
          ),
        ),
      ),
    );
  }

  Category _previewCategory() {
    return Category(
      id: _initial?.id ?? 'preview',
      name: _nameController.text,
      type: _type,
      icon: _icon,
      color: _resolvedDisplayColor(),
      parentId: _parentId,
      includeInReport: _includeInReport,
    );
  }

  /// Color the preview row should display. L1 (no parent) shows the
  /// user-picked color; L2/L3 inherits from the L1 ancestor — matches
  /// the inheritance rule used in the categories list.
  CategoryColor _resolvedDisplayColor() {
    if (_parentId == null) return _color;
    final all = context.read<CategoriesCubit>().state.categories;
    String? cursor = _parentId;
    while (cursor != null) {
      final parent = all.firstWhere(
        (c) => c.id == cursor,
        orElse: () => Category(
          id: cursor!,
          name: '',
          type: _type,
          icon: _icon,
          color: _color,
        ),
      );
      if (parent.parentId == null) return parent.color;
      cursor = parent.parentId;
    }
    return _color;
  }

  /// True when the form's color picker should be available — only L1
  /// rows own their color; L2/L3 inherit and shouldn't have an
  /// independently editable color.
  bool get _isColorEditable => _parentId == null;

  String? _parentBreadcrumb(List<Category> all) {
    if (_parentId == null) return null;
    final parent =
        all.firstWhere((c) => c.id == _parentId, orElse: () => _previewCategory());
    final ancestors = CategoryTree.breadcrumb(parent, all);
    return ancestors.isEmpty ? parent.name : '$ancestors › ${parent.name}';
  }

  Future<void> _openIconPicker(
      BuildContext context, AppLocalizations l) async {
    final basePreview = _previewCategory();
    final all = context.read<CategoriesCubit>().state.categories;
    final breadcrumb = _parentBreadcrumb(all);

    // For L2/L3 categories, color is inherited from the L1 ancestor —
    // hide the swatch row in the picker and lock the color to the
    // resolved display color so the icon-grid tiles render in the right
    // tint.
    final lockedColor = _resolvedDisplayColor();

    final result = await showIconColorPickerSheet(
      context: context,
      iconOptions: [
        for (final p in CategoryIconPreset.values)
          IconPickerOption(id: p.id, icon: p.icon),
      ],
      swatches: [
        for (final c in CategoryColor.all)
          IconPickerSwatch(id: c.id, color: c.color),
      ],
      initialIconId: _icon.id,
      initialSwatchId: lockedColor.id,
      iconSectionLabel: l.categoryFormIconLabel,
      colorSectionLabel: l.categoryFormColorLabel,
      showColorSection: _isColorEditable,
      previewBuilder: (icon, swatch) => CategoryPreviewCard(
        category: basePreview.copyWith(
          icon: CategoryIconPreset.byId(icon.id),
          color: CategoryColor.byId(swatch.id),
        ),
        parentPath: breadcrumb,
      ),
    );
    if (!mounted || result == null) return;
    if (result is IconColorPickerSelected) {
      setState(() {
        _icon = CategoryIconPreset.byId(result.iconId);
        // Only persist the color when the user actually picked it. For
        // child categories (color section hidden) we leave _color alone
        // so it stays valid if they later detach from the parent.
        if (_isColorEditable) {
          _color = CategoryColor.byId(result.swatchId);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<CategoriesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context)!;

    if (!widget.isEdit && !cubit.canAddMore) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.categoriesLimitReached)));
      return;
    }

    final description = _descriptionController.text.trim();
    final note = _noteController.text.trim();

    try {
      if (widget.isEdit) {
        final updated = _initial!.copyWith(
          name: _nameController.text.trim(),
          parentId: _parentId,
          clearParent: _parentId == null,
          icon: _icon,
          color: _color,
          description: description.isEmpty ? null : description,
          note: note.isEmpty ? null : note,
          includeInReport: _includeInReport,
        );
        await cubit.update(updated);
      } else {
        // Server assigns id + sort_order on create. The local id placeholder
        // here ("draft") never reaches the wire — toCreateJson() drops it.
        final draft = Category(
          id: 'draft',
          name: _nameController.text.trim(),
          type: _type,
          icon: _icon,
          color: _color,
          parentId: _parentId,
          description: description.isEmpty ? null : description,
          note: note.isEmpty ? null : note,
          includeInReport: _includeInReport,
        );
        await cubit.add(draft);
      }
    } on CategoryLimitExceeded {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.categoriesLimitReached)));
      return;
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    context.pop();
  }

  Future<bool> _confirmDiscard(
      BuildContext context, AppLocalizations l) async {
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _TypeChips extends StatelessWidget {
  const _TypeChips({required this.selected, required this.onSelected});

  final CategoryType selected;

  /// Null disables all chips (used in edit mode where type is immutable).
  final ValueChanged<CategoryType>? onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: CategoryType.values.map((t) {
        return ChoiceChip(
          label: Text(_labelFor(l, t)),
          selected: t == selected,
          onSelected:
              onSelected == null ? null : (_) => onSelected!(t),
        );
      }).toList(),
    );
  }

  String _labelFor(AppLocalizations l, CategoryType t) {
    switch (t) {
      case CategoryType.expense:
        return l.categoryTypeExpense;
      case CategoryType.income:
        return l.categoryTypeIncome;
    }
  }
}

class _ParentDropdown extends StatelessWidget {
  const _ParentDropdown({
    required this.all,
    required this.self,
    required this.type,
    required this.selected,
    required this.onChanged,
  });

  final List<Category> all;
  final Category? self;
  final CategoryType type;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final eligible = CategoryTree.eligibleParents(
      all: all,
      self: self,
      type: type,
    );
    // Sort eligible parents by their depth so the dropdown reads top-down:
    // roots first, then children, then grandchildren.
    eligible.sort(
      (a, b) => CategoryTree.depthOf(a, all).compareTo(
        CategoryTree.depthOf(b, all),
      ),
    );
    // Don't pin a stale value if our [selected] is no longer eligible
    // (e.g. user just switched type). The form rebuilds and we'll fall
    // through to "no parent" until the user picks a new one.
    final currentValue = selected != null &&
            eligible.any((c) => c.id == selected)
        ? selected
        : null;
    return DropdownButtonFormField<String?>(
      initialValue: currentValue,
      decoration: InputDecoration(
        labelText: l.categoryFormParentLabel,
        helperText: l.categoryFormParentDepthHint,
        helperMaxLines: 2,
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(l.categoryFormParentNone)),
        for (final c in eligible)
          DropdownMenuItem(
            value: c.id,
            child: Text(_labelFor(c)),
          ),
      ],
      onChanged: onChanged,
    );
  }

  String _labelFor(Category c) {
    final breadcrumb = CategoryTree.breadcrumb(c, all);
    return breadcrumb.isEmpty ? c.name : '$breadcrumb › ${c.name}';
  }
}
