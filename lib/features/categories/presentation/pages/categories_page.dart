import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/shell_chrome.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/category.dart';
import '../../domain/category_reorder_logic.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../cubit/categories_cubit.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  ReorderController? _reorder;
  bool _savingReorder = false;

  CategoryType _listType = CategoryType.expense;

  late final ShellNavClaim _shellNav = ShellNavClaim(
    () => mounted && _reordering,
  );

  final Set<String> _collapsedIds = <String>{};

  static const _types = [CategoryType.expense, CategoryType.income];
  late final PageController _pages = PageController(
    initialPage: _types.indexOf(_listType),
  );

  /// One per tab: both pages are built side by side, and a controller can't
  /// drive two lists.
  final Map<CategoryType, ScrollController> _scrollControllers = {
    for (final t in _types) t: ScrollController(),
  };

  final _search = TextEditingController();
  String _query = '';

  final Set<String> _filterColors = {};
  final Set<String> _filterIcons = {};

  bool get _reordering => _reorder != null;

  bool get _filtering =>
      _query.trim().isNotEmpty ||
      _filterColors.isNotEmpty ||
      _filterIcons.isNotEmpty;

  static String? _colorOf(IconCode? c) {
    if (c == null) return null;
    if (c.bgColors.isNotEmpty) return c.bgColors.first;
    return c.iconColors.isNotEmpty ? c.iconColors.first : null;
  }

  void _setListType(CategoryType t) {
    if (t == _listType) return;
    setState(() {
      _listType = t;
      _filterColors.clear();
      _filterIcons.clear();
    });
    _reorder?.select(null);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoriesCubit>().loadIfNeeded();
    });
  }

  Set<String>? _visibleIds(List<Category> users) {
    if (!_filtering) return null;
    final q = _query.trim().toLowerCase();
    final byId = {for (final c in users) c.id: c};
    final visible = <String>{};
    for (final c in users) {
      if (q.isNotEmpty && !c.name.toLowerCase().contains(q)) continue;
      final code = CategoryTree.resolveIconCode(c, users);
      if (_filterColors.isNotEmpty && !_filterColors.contains(_colorOf(code))) {
        continue;
      }
      if (_filterIcons.isNotEmpty && !_filterIcons.contains(code?.icon)) {
        continue;
      }
      Category? cursor = c;
      while (cursor != null && visible.add(cursor.id)) {
        cursor = cursor.parentId == null ? null : byId[cursor.parentId];
      }
    }
    return visible;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shellNav.attach(context);
  }

  @override
  void dispose() {
    _shellNav.dispose();
    _reorder?.dispose();
    for (final c in _scrollControllers.values) {
      c.dispose();
    }
    _pages.dispose();
    _search.dispose();
    super.dispose();
  }

  void _enterReorder(List<Category> all, {String? select}) {
    HapticFeedback.lightImpact();
    final c = ReorderController(
      items: CategoryReorderLogic.toOutline(all, types: _types),
      maxDepth: CategoryTree.maxDepth,
      collapsed: _collapsedIds,
    )..addListener(_onReorderChanged);
    if (select != null) c.select(select);
    _keepOffset(() => _reorder = c);
    _shellNav.changed();
  }

  void _keepOffset(VoidCallback change) {
    final sc = _scrollControllers[_listType]!;
    final offset = sc.hasClients ? sc.offset : null;
    setState(change);
    if (offset == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !sc.hasClients) return;
      final max = sc.position.maxScrollExtent;
      final target = offset > max ? max : offset;
      if (sc.offset != target) sc.jumpTo(target);
    });
  }

  void _onReorderChanged() => setState(() {});

  void _backInReorder() {
    if (!_savingReorder) _exitReorder();
  }

  void _exitReorder() {
    final c = _reorder;
    _keepOffset(() {
      _reorder = null;
      _savingReorder = false;
    });
    _shellNav.changed();
    WidgetsBinding.instance.addPostFrameCallback((_) => c?.dispose());
  }

  Future<void> _saveReorder(List<Category> all) async {
    final c = _reorder;
    if (c == null || !c.dirty) {
      _exitReorder();
      return;
    }
    final cubit = context.read<CategoriesCubit>();
    final l = AppLocalizations.of(context)!;
    setState(() => _savingReorder = true);
    try {
      await cubit.saveReorder(CategoryReorderLogic.fromOutline(c.items, all));
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      _exitReorder();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingReorder = false);
      showAppSnackBar(
        context,
        e.code == 'MAX_DEPTH_EXCEEDED'
            ? l.categoryErrorMaxDepth
            : '${l.categoriesReorderSave}: ${e.message}',
        tone: Tone.danger,
      );
    }
  }

  void _toggleCollapse(String id) {
    final c = _reorder;
    if (c != null) {
      c.toggleCollapsed(id); // the shared set; c notifies
      return;
    }
    setState(() {
      if (!_collapsedIds.remove(id)) _collapsedIds.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final all = state.categories;
        final users = all.where((c) => !c.isSystem).toList();
        final typeUsers = users.where((c) => c.type == _listType).toList();
        final reorder = _reorder;
        return SavingOverlay(
          saving: _savingReorder,
          child: PopScope(
            canPop: !_reordering,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && _reordering) _backInReorder();
            },
            child: Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppTopBar(
                title: l.categoriesTitle,
                showBack: true,
                editing: _reordering,
                onBack: _reordering ? _backInReorder : null,
              ),
              body: TabSwitchBody(
                child: TabbedListPageBody<CategoryType>(
                  controller: _pages,
                  selected: _listType,
                  onChanged: _setListType,
                  swipeEnabled: !_reordering,
                  headerBelowTabs: true,
                  header: typeUsers.isEmpty
                      ? const []
                      : [_header(l, typeUsers, all)],
                  tabs: [
                    AppTab(
                      value: CategoryType.expense,
                      label: l.categoryTypeExpense,
                      icon: AppIcons.expense,
                    ),
                    AppTab(
                      value: CategoryType.income,
                      label: l.categoryTypeIncome,
                      icon: AppIcons.income,
                    ),
                  ],
                  pageBuilder: (context, t) => _tab(
                    l,
                    state,
                    t == _listType
                        ? typeUsers
                        : users.where((c) => c.type == t).toList(),
                    all,
                    t,
                  ),
                ),
              ),
              bottomNavigationBar: reorder == null
                  ? null
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderMoveBar(controller: reorder),
                        ModeActionBar(
                          canUndo: reorder.canUndo && !_savingReorder,
                          canSave: reorder.dirty && !_savingReorder,
                          saving: _savingReorder,
                          cancelLabel: l.categoriesReorderCancel,
                          saveLabel: l.categoriesReorderSave,
                          undoTooltip: l.categoriesUndo,
                          onCancel: _backInReorder,
                          onUndo: reorder.undo,
                          onSave: () => _saveReorder(all),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(
    AppLocalizations l,
    List<Category> typeUsers,
    List<Category> all,
  ) {
    final browse = _filterRow(l, typeUsers, all);
    if (!_reordering) return browse;
    return Stack(
      children: [
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: browse,
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppText(
                l.categoriesReorderTapHint,
                role: AppTextRole.caption,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterRow(
    AppLocalizations l,
    List<Category> typeUsers,
    List<Category> all,
  ) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final codes = [
      for (final c in typeUsers) CategoryTree.resolveIconCode(c, typeUsers),
    ];
    final colors = {for (final c in codes) ?_colorOf(c)}.toList()..sort();
    final icons = {for (final c in codes) ?c?.icon}.toList()..sort();
    return ListToolbar(
      searchController: _search,
      searchHint: l.categoriesSearchHint,
      onSearchChanged: (v) => setState(() => _query = v),
      chips: [
        PopoverAnchor(
          builder: (context, toggle) => AppChip(
            label: l.iconMakerTabColor,
            icon: AppIcons.colorPicker,
            selected: _filterColors.isNotEmpty,
            count: _filterColors.length,
            trailing: _filterColors.isEmpty
                ? AppChipTrailing.dropdown
                : AppChipTrailing.count,
            onTap: colors.isEmpty ? null : toggle,
          ),
          contentBuilder: (context, close) => StatefulBuilder(
            builder: (context, setPopover) => ColorSwatchGrid(
              colors: [for (final t in colors) resolveColor(t, palette)],
              selected: {
                for (final (i, t) in colors.indexed)
                  if (_filterColors.contains(t)) i,
              },
              onToggle: (i) {
                final t = colors[i];
                setState(
                  () => _filterColors.contains(t)
                      ? _filterColors.remove(t)
                      : _filterColors.add(t),
                );
                setPopover(() {});
              },
              onClear: () {
                setState(_filterColors.clear);
                setPopover(() {});
              },
            ),
          ),
        ),
        PopoverAnchor(
          builder: (context, toggle) => AppChip(
            label: l.iconMakerRoleIcon,
            icon: AppIcons.iconPicker,
            selected: _filterIcons.isNotEmpty,
            count: _filterIcons.length,
            trailing: _filterIcons.isEmpty
                ? AppChipTrailing.dropdown
                : AppChipTrailing.count,
            onTap: icons.isEmpty ? null : toggle,
          ),
          contentBuilder: (context, close) => StatefulBuilder(
            builder: (context, setPopover) => IconSwatchGrid(
              glyphs: icons,
              selected: _filterIcons,
              onToggle: (g) {
                setState(
                  () => _filterIcons.contains(g)
                      ? _filterIcons.remove(g)
                      : _filterIcons.add(g),
                );
                setPopover(() {});
              },
              onClear: () {
                setState(_filterIcons.clear);
                setPopover(() {});
              },
            ),
          ),
        ),
      ],
      trailing: AppIconButton.edit(
        tooltip: l.categoriesReorderEnter,
        onPressed: typeUsers.length < 2
            ? null
            : () {
                _search.clear();
                _query = '';
                _filterColors.clear();
                _filterIcons.clear();
                _enterReorder(all);
              },
      ),
    );
  }

  Widget _tab(
    AppLocalizations l,
    CategoriesState state,
    List<Category> typeUsers,
    List<Category> all,
    CategoryType type,
  ) {
    final visible = _reordering ? null : _visibleIds(typeUsers);
    final noMatch = typeUsers.isNotEmpty && visible != null && visible.isEmpty;
    final byId = {for (final c in typeUsers) c.id: c};
    return ListPageBody(
      loading:
          (state.status == CategoriesStatus.initial ||
              state.status == CategoriesStatus.loading) &&
          typeUsers.isEmpty,
      error: typeUsers.isEmpty ? state.error : null,
      isEmpty: typeUsers.isEmpty || noMatch,
      // No refresh while reordering (the staged order would be replaced).
      refreshEnabled: !_reordering,
      onRetry: () => context.read<CategoriesCubit>().load(),
      empty: noMatch
          ? EmptyView(
              icon: AppIcons.search,
              title: l.categoriesSearchNoMatch,
              message: '',
            )
          : EmptyView(
              icon: AppIcons.category,
              title: l.categoriesEmptyTitle,
              message: l.categoriesEmptyMessage,
              cta: _reordering
                  ? null
                  : AddTile(
                      label: l.categoriesAddNew,
                      onTap: () => _add(l, type),
                    ),
            ),
      sidePadding: 0,
      builder: (context, padding) => ReorderListScope(
        controller: _reorder,
        scrollController: _scrollControllers[type]!,
        indentStep: AppSpacing.xxl,
        indentBase: AppSpacing.lg,
        dropLabel: (parentId) {
          final parent = parentId == null ? null : byId[parentId];
          return parent == null
              ? l.categoriesReorderTopLevel
              : l.categoriesReorderUnder(parent.name);
        },
        child: _ListBody(
          users: typeUsers,
          type: type,
          reorder: _reorder,
          visibleIds: visible,
          collapsedIds: _collapsedIds,
          scrollController: _scrollControllers[type]!,
          padding: padding,
          // Long-press enters the mode (not while searching / filtering — the
          // tree isn't whole then); it never starts a drag.
          onLongPress: visible != null || typeUsers.length < 2
              ? null
              : (id) => _enterReorder(all, select: id),
          onToggleCollapse: _toggleCollapse,
          addLabel: l.categoriesAddNew,
          onAdd: _reordering ? null : () => _add(l, type),
        ),
      ),
    );
  }

  void _add(AppLocalizations l, CategoryType type) {
    if (!context.read<CategoriesCubit>().canAddMore) {
      showAppSnackBar(context, l.categoriesLimitReached, tone: Tone.warning);
      return;
    }
    context.push('/categories/new?type=${type.toJson()}');
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({
    required this.users,
    required this.type,
    required this.reorder,
    required this.visibleIds,
    required this.collapsedIds,
    required this.scrollController,
    required this.padding,
    required this.onLongPress,
    required this.onToggleCollapse,
    required this.addLabel,
    this.onAdd,
  });

  final List<Category> users;
  final CategoryType type;

  final ReorderController? reorder;

  final Set<String>? visibleIds;
  final Set<String> collapsedIds;
  final ScrollController scrollController;

  final EdgeInsets padding;
  final void Function(String id)? onLongPress;
  final void Function(String id) onToggleCollapse;

  final String addLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final rows = reorder == null ? _treeRows() : _outlineRows(reorder!);
    return ListView(
      key: PageStorageKey('categories-list-${type.name}'),
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const AppDivider.row(),
          row,
        ],
        if (onAdd != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: AddTile(label: addLabel, onTap: onAdd),
          ),
      ],
    );
  }

  List<Widget> _treeRows() {
    List<Category> childrenOf(String? id) =>
        users.where((c) => c.parentId == id).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final out = <Widget>[];
    void walk(Category c, int depth) {
      if (!(visibleIds?.contains(c.id) ?? true)) return;
      final children = childrenOf(c.id);
      final collapsed = visibleIds == null && collapsedIds.contains(c.id);
      out.add(
        _row(
          c,
          depth: depth,
          hasChildren: children.isNotEmpty,
          collapsed: collapsed,
          reordering: false,
        ),
      );
      if (!collapsed) {
        for (final child in children) {
          walk(child, depth + 1);
        }
      }
    }

    for (final root in childrenOf(null)) {
      walk(root, 0);
    }
    return out;
  }

  List<Widget> _outlineRows(ReorderController c) {
    final byId = {for (final cat in users) cat.id: cat};
    return [
      for (final item in c.visible(section: type))
        if (byId[item.id] case final cat?)
          _row(
            cat,
            depth: item.level - 1,
            hasChildren: c.hasChildren(item.id),
            collapsed: c.isCollapsed(item.id),
            reordering: true,
          ),
    ];
  }

  Widget _row(
    Category c, {
    required int depth,
    required bool hasChildren,
    required bool collapsed,
    required bool reordering,
  }) {
    return ReorderRow(
      key: ValueKey(c.id),
      id: c.id,
      child: _RowContent(
        category: c,
        iconCode: CategoryTree.resolveIconCode(c, users),
        depth: depth,
        reorderMode: reordering,
        hasChildren: hasChildren,
        isCollapsed: collapsed,
        onToggleCollapse: () => onToggleCollapse(c.id),
        onLongPress: reordering || onLongPress == null
            ? null
            : () => onLongPress!(c.id),
      ),
    );
  }
}

class _RowContent extends StatelessWidget {
  const _RowContent({
    required this.category,
    required this.iconCode,
    required this.depth,
    required this.reorderMode,
    required this.hasChildren,
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.onLongPress,
  });

  final Category category;
  final IconCode? iconCode;
  final int depth;
  final bool reorderMode;
  final bool hasChildren;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hidden = !category.includeInReport;
    return AppListRow(
      indent: depth * AppSpacing.xxl,
      leading: IconDisplay(
        type: IconType.category,
        size: 36,
        iconCode: iconCode,
      ),
      title: category.name,
      status: hidden
          ? ListRowChip(l.categoryHiddenFromReport, icon: AppIcons.hidden)
          : null,
      line2: ListRowLine(parts: [category.description?.trim() ?? '']),
      actions: [
        if (hasChildren)
          ListRowAction.icon(
            isCollapsed ? AppIcons.expand : AppIcons.collapse,
            onTap: onToggleCollapse,
          ),
      ],
      onTap: reorderMode
          ? null
          : () => context.push('/categories/${category.id}'),
      onLongPress: onLongPress,
    );
  }
}
