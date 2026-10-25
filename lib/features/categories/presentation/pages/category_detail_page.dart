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
import '../category_errors.dart';
import '../cubit/categories_cubit.dart';
import '../widgets/category_chip_path.dart';
import '../widgets/category_picker.dart';
import '../widgets/category_preview_card.dart';

class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({
    this.editingId,
    this.initialType,
    this.popOnCreate = false,
    super.key,
  });

  CategoryDetailPage.create({String? type, Key? key})
    : this(
        initialType: type == CategoryType.income.toJson()
            ? CategoryType.income
            : CategoryType.expense,
        key: key,
      );

  final String? editingId;

  final CategoryType? initialType;

  final bool popOnCreate;

  bool get isCreate => editingId == null;

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

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

  Category? _persisted;
  bool _notFound = false;

  bool get _isCreate => widget.isCreate && _persisted == null;

  CategoryDetail? _detail;

  num _monthSpent = 0;
  int _monthCount = 0;

  Category? _pickedParent;
  var _pickedParentChain = const <CategoryPathItem>[];

  String? _nameServerError;
  String? _nameServerErrorFor;

  static String _nameKey(String name, String? parentId) =>
      '${parentId ?? ''}|${name.trim()}';

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

  /// The cubit's list changed (first load, pull-to-refresh, an edit elsewhere):
  /// rebase on the fresh row unless an edit is in progress.
  void _syncFromCubit(CategoriesState state) {
    final id = _persisted?.id ?? widget.editingId;
    if (id == null) return;
    Category? fresh;
    for (final c in state.categories) {
      if (c.id == id) fresh = c;
    }
    if (fresh == null) {
      // Never had it, and the list is in: it doesn't exist.
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

  /// One call ([LiveSetting] shows it at once, puts it back on a failure).
  Future<bool> _setFeeCategory(bool on) async {
    final id = _persisted?.id;
    if (id == null) return false;
    final me = await context.read<UsersRepository>().setFeeCategory(
      on ? id : null,
    );
    if (!mounted) return true;
    context.read<AuthCubit>().updateUser(me);
    setState(() => _detail = _detail?.withFee(on));
    return true;
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
      if (isCategoryNameDuplicate(e)) {
        _nameServerError = l.categoryFormNameDuplicate;
        _nameServerErrorFor = _nameKey(w.name, w.parentId);
        _formKey.currentState?.validate();
        return;
      }
      showAppSnackBarOn(pageMessenger!, _errorText(e, l), tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    commitSaved(working.trimmed());
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final c = _persisted!;
    final cubit = context.read<CategoriesCubit>();
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

  Category _previewCategory() => Category(
    id: _persisted?.id ?? 'preview',
    name: working.name,
    type: working.type,
    iconCode: _resolvedDisplayIconCode(),
    parentId: working.parentId,
    includeInReport: working.includeInReport,
  );

  IconCode? _resolvedDisplayIconCode() {
    if (working.iconCode != null || working.parentId == null) {
      return working.iconCode;
    }
    final all = context.read<CategoriesCubit>().state.categories;
    final parent = context.read<CategoriesCubit>().byId(working.parentId!);
    return parent == null ? null : CategoryTree.resolveIconCode(parent, all);
  }

  List<CategoryPathItem>? _parentChain() {
    final id = working.parentId;
    if (id == null) return null;
    final row = _detail ?? _persisted;
    if (row != null && row.parentId == id && row.path.isNotEmpty) {
      return row.path;
    }
    return _pickedParent?.id == id ? _pickedParentChain : null;
  }

  String? _parentBreadcrumb() => _parentChain()?.map((p) => p.name).join(' › ');

  Future<void> _openIconMaker() async {
    final l = AppLocalizations.of(context)!;
    final breadcrumb = _parentBreadcrumb();
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
    final result = await CategoryPicker.one(
      context,
      types: {working.type},
      selectedId: selectedParent?.id,
      allowNone: true,
      noneLabel: l.categoryFormParentNone,
      title: l.categoryFormParentLabel,
      maxDepth: deepestParent < 1 ? 0 : deepestParent - 1,
      excludeIds: exclude,
    );
    if (!mounted || result == null) return;
    if (result is CategoryPicked) {
      final picked = result.category;
      setState(() {
        _pickedParent = picked;
        _pickedParentChain = [
          ...picked.path,
          CategoryPathItem(
            id: picked.id,
            name: picked.name,
            iconCode: CategoryTree.resolveIconCode(picked, all),
          ),
        ];
      });
      applyChange(working.copyWith(parentId: picked.id));
    } else if (result is CategoryPickedNone) {
      applyChange(working.copyWith(clearParent: true));
    }
  }

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
    return QuickCreatePresetScope(
      preset: QuickCreatePreset(category: _persisted),
      child: editScope(_scaffold(l)),
    );
  }

  Widget _scaffold(AppLocalizations l) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        title: _title(l),
        showBack: true,
        editing: isEditing,
        onBack: handleBack,
      ),
      body: BlocBuilder<CategoriesCubit, CategoriesState>(
        // This context sits inside the Scaffold body, so it sees the bar height
        // in its top padding.
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

  String _title(AppLocalizations l) {
    if (_isCreate) return l.categoryFormTitleNew;
    final name = _persisted?.name ?? '';
    return name.isEmpty ? l.categoriesTitle : name;
  }

  /// View mode: one call with only the switch ([LiveSetting] shows it at once
  /// and puts it back on a failure).
  Future<bool> _setIncludeLive(bool v) async {
    final row = _persisted;
    if (row == null) return false;
    final saved = await context.read<CategoriesCubit>().setIncludeInReport(
      row.id,
      v,
    );
    if (!mounted) return true;
    setState(() {
      _persisted = saved;
      _detail = saved.withFee(_detail?.isFeeCategory ?? saved.isFeeCategory);
    });
    resetDraft(_CategoryDraft.fromCategory(saved));
    return true;
  }

  String _failedText(Object e, AppLocalizations l) =>
      e is ApiException ? _errorText(e, l) : l.errorUnknownMessage;

  String _monthLabel(AppLocalizations l, bool income) {
    final month = DateFormat.MMM(
      Localizations.localeOf(context).toString(),
    ).format(DateTime.now());
    return income
        ? l.categoryMonthEarnedLabel(month, _monthCount)
        : l.categoryMonthSpentLabel(month, _monthCount);
  }

  VoidCallback? _openMonthTransactions() {
    final c = _persisted;
    if (c == null) return null;
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final q = Uri(
      path: '/browse',
      queryParameters: {
        'category': c.id,
        'title': c.name,
        'month': month,
        'type': c.type.name,
      },
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
    final breadcrumb = _parentBreadcrumb();
    final chain = _parentChain();
    final canDelete = !_isCreate && !(_persisted?.isSystem ?? true);
    return DetailLayout(
      onRefresh: _isCreate ? null : _loadDetail,
      physics: const AlwaysScrollableScrollPhysics(),
      topInset: topInset + AppSpacing.lg,
      bottomInset: AppSpacing.huge + bottomInset,
      hero: _hero(l, all, editing),
      info: InfoBox(
        rows: [
          InfoRow(
            label: l.categoryFormParentLabel,
            valueChip: chain == null
                ? null
                : categoryPathItemsChipPath(context, chain),
            value: chain == null
                ? (breadcrumb ?? l.categoryFormParentNone)
                : null,
            showChevron: true,
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
          // Edit / create: part of the form. View: saves at once.
          if (editing || _persisted == null)
            SettingToggleRow(
              label: l.categoryFormIncludeInReportLabel,
              caption: l.categoryFormIncludeInReportHelper,
              value: working.includeInReport,
              submits: false,
              onChanged: (v) =>
                  applyChange(working.copyWith(includeInReport: v)),
            )
          else
            LiveSetting<bool>(
              value: working.includeInReport,
              save: _setIncludeLive,
              failedMessage: (e) => _failedText(e, l),
              builder: (context, value, onChanged) => SettingToggleRow(
                label: l.categoryFormIncludeInReportLabel,
                caption: l.categoryFormIncludeInReportHelper,
                value: value,
                onChanged: onChanged,
              ),
            ),
          if (_persisted != null && working.type == CategoryType.expense)
            LiveSetting<bool>(
              value: _detail?.isFeeCategory ?? false,
              save: _setFeeCategory,
              failedMessage: (_) => l.categoryFeeSwitchFailed,
              builder: (context, value, onChanged) => SettingToggleRow(
                label: l.categoryFeeSwitchLabel,
                caption: l.categoryFeeSwitchHelper,
                value: value,
                onChanged: onChanged,
              ),
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
          hint: l.categoryNoteHint,
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
      return AppHeroCard(
        style: style,
        mode: HeroCardMode.edit,
        header: HeroHeader(leading: [typeChip]),
        content: [
          HeroIdentity(
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
              validator: _validateName,
            ),
            description: description,
          ),
        ],
      );
    }
    return AppHeroCard(
      style: style,
      header: HeroHeader(leading: [typeChip], onEdit: enterEdit),
      content: [
        HeroIdentity(
          icon: EditableCircle(
            size: HeroIdentity.iconSize,
            onLongPress: _enterEditThenOpenMaker,
            child: IconDisplay(
              type: IconType.category,
              size: HeroIdentity.iconSize,
              iconCode: iconCode,
            ),
          ),
          description: description,
        ),
        _persisted == null
            ? null
            : HeroNumber(
                label: _monthLabel(l, isIncome),
                onLabelTap: _openMonthTransactions(),
                color: typeColor,
                value: MoneyText(_monthSpent),
              ),
      ],
    );
  }

  String? _validateName(String? v) {
    final l = AppLocalizations.of(context)!;
    final name = v?.trim() ?? '';
    if (name.isEmpty) return l.categoryFormNameRequired;
    if (name.length > TextLimits.name) return l.categoryFormNameTooLong;
    if (_nameServerError != null &&
        _nameServerErrorFor == _nameKey(name, working.parentId)) {
      return _nameServerError;
    }
    return null;
  }
}

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
