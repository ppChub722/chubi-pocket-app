import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/shell_chrome.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/color_token.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/category.dart';
import '../../domain/category_reorder_logic.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../cubit/categories_cubit.dart';
import '../widgets/categories_list_skeleton.dart';

/// Categories management.
///
/// **Browse mode** — the library list shared with tags / contacts (owner
/// 2026-10-10):
/// - Expense / income tabs; swipe sideways to switch ([AppTabPager] —
///   the content follows the finger).
/// - Search, then [สี▾][ไอคอน▾] … (✏️) — ✏️ enters reorder mode (owner
///   2026-10-11: on a list page ✏️ = the list's edit mode).
/// - [ListRow]s on the tree's indent: icon · name · description, then
///   "ซ่อนจากรายงาน" and ▾/▴ (parents only — toggles collapse).
/// - Tap row → the category's detail page. Long-press → reorder mode with
///   that row selected (no drag starts from that press).
/// - A dashed "+ เพิ่มหมวดหมู่" tile ends the list (also the empty CTA),
///   creating on the tab's type.
///
/// **Reorder mode** — the kit's [ReorderController] / [ReorderListScope]:
/// ⠿ handles drag at once with smart sideways depth; tap a row → the
/// ← ↑ ↓ → bar; ยกเลิก / ↶ / บันทึก at the bottom; back = cancel. Entering
/// keeps the layout where it is: the search + filter rows keep their space
/// (a hint shows there) and the expand state is untouched.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  /// Non-null while reordering.
  ReorderController? _reorder;
  bool _savingReorder = false;

  /// Which type's tree the list is showing — toggled by the top tab bar.
  CategoryType _listType = CategoryType.expense;

  /// Shell chrome controller — lets reorder mode hide the shell's bottom
  /// nav so the [ModeActionBar] replaces it instead of stacking under
  /// it. Grabbed in [didChangeDependencies].
  ShellChromeController? _shellChrome;

  /// Parent ids whose children are hidden. Shared with the reorder
  /// controller, so collapse choices carry over between the modes.
  final Set<String> _collapsedIds = <String>{};

  /// The tabs, in bar order — one [AppTabPager] page each.
  static const _types = [CategoryType.expense, CategoryType.income];
  late final PageController _pages = PageController(
    initialPage: _types.indexOf(_listType),
  );

  /// One per tab: both pages are built side by side, and a controller
  /// can't drive two lists. The same list (and offset) serves both modes.
  final Map<CategoryType, ScrollController> _scrollControllers = {
    for (final t in _types) t: ScrollController(),
  };

  /// Browse-mode search. Non-empty → the tree shows only matches plus
  /// their ancestors (auto-expanded) and long-press reorder is off.
  final _search = TextEditingController();
  String _query = '';

  /// Browse-mode colour / icon filters (the filter row under the search).
  final Set<String> _filterColors = {};
  final Set<String> _filterIcons = {};

  bool get _reordering => _reorder != null;

  bool get _filtering =>
      _query.trim().isNotEmpty ||
      _filterColors.isNotEmpty ||
      _filterIcons.isNotEmpty;

  /// A row's colour key: its accent slot (bg first, else the glyph tint).
  static String? _colorOf(IconCode? c) {
    if (c == null) return null;
    if (c.bgColors.isNotEmpty) return c.bgColors.first;
    return c.iconColors.isNotEmpty ? c.iconColors.first : null;
  }

  void _setListType(CategoryType t) {
    if (t == _listType) return;
    setState(() {
      _listType = t;
      // The other tab has its own colours / icons.
      _filterColors.clear();
      _filterIcons.clear();
    });
    // The move bar belongs to a row on the tab being left.
    _reorder?.select(null);
  }

  @override
  void initState() {
    super.initState();
    // Cold-start fetch — idempotent, safe to re-enter the page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoriesCubit>().loadIfNeeded();
    });
  }

  /// Ids to show while searching / filtering: every match plus all its
  /// ancestors, so results keep their place in the tree. Null = showing
  /// everything.
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
    _shellChrome = ShellChrome.of(context);
  }

  @override
  void dispose() {
    // Safety net: leaving while reordering restores the shell's nav.
    if (_reordering) _shellChrome?.show();
    _reorder?.dispose();
    for (final c in _scrollControllers.values) {
      c.dispose();
    }
    _pages.dispose();
    _search.dispose();
    super.dispose();
  }

  // ── Mode lifecycle ──────────────────────────────────────────────────

  /// [select] — the long-pressed row, selected on entry so its ← ↑ ↓ →
  /// bar is right there.
  void _enterReorder(List<Category> all, {String? select}) {
    HapticFeedback.lightImpact();
    _shellChrome?.hide(); // the action bar replaces the shell nav
    final c = ReorderController(
      items: CategoryReorderLogic.toOutline(all, types: _types),
      maxDepth: CategoryTree.maxDepth,
      collapsed: _collapsedIds,
    )..addListener(_onReorderChanged);
    if (select != null) c.select(select);
    _keepOffset(() => _reorder = c);
  }

  /// Switches mode without moving the list under the finger (QA F1): the
  /// rows come back at the same offset. The list's [PageStorageKey]
  /// restores it; this puts it back if that didn't.
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

  /// ยกเลิก, ← and system back in reorder mode — one behaviour (owner
  /// 2026-10-10): drop the staged order, no prompt; nothing while saving.
  void _backInReorder() {
    if (!_savingReorder) _exitReorder();
  }

  void _exitReorder() {
    _shellChrome?.show(); // restore the shell nav
    final c = _reorder;
    _keepOffset(() {
      _reorder = null;
      _savingReorder = false;
    });
    // After the frame: the scopes stop listening first.
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

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final all = state.categories;
        final users = all.where((c) => !c.isSystem).toList();
        final typeUsers = users.where((c) => c.type == _listType).toList();
        final reorder = _reorder;
        return PopScope(
          canPop: !_reordering,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _reordering) _backInReorder();
          },
          child: Scaffold(
            // The bar floats over the body; the pinned column below starts
            // with a spacer of its height.
            extendBodyBehindAppBar: true,
            appBar: AppTopBar(
              // The title never changes with the mode (owner, QA T1) — the
              // action bar and the hint say it's reorder mode.
              title: l.categoriesTitle,
              showBack: true,
              editing: _reordering,
              onBack: _reordering ? _backInReorder : null,
            ),
            body: TabSwitchBody(
              child: AsyncStateView(
                loading:
                    state.status == CategoriesStatus.initial ||
                    state.status == CategoriesStatus.loading,
                error: state.error,
                isEmpty: all.isEmpty,
                onRetry: context.read<CategoriesCubit>().load,
                skeleton: Builder(
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top,
                    ),
                    child: const LoadingView(
                      skeleton: CategoriesListSkeleton(),
                    ),
                  ),
                ),
                // Per-type empty lives under the tabs ([_listOrEmpty]).
                builder: (context) => Column(
                  children: [
                    // Clear the transparent top bar.
                    SizedBox(height: MediaQuery.paddingOf(context).top),
                    AppTabBar<CategoryType>(
                      selected: _listType,
                      onChanged: _setListType,
                      pager: _pages,
                      tabs: [
                        AppTab(
                          value: CategoryType.expense,
                          label: l.categoryTypeExpense,
                        ),
                        AppTab(
                          value: CategoryType.income,
                          label: l.categoryTypeIncome,
                        ),
                      ],
                    ),
                    // An empty tab has nothing to search or filter.
                    if (typeUsers.isNotEmpty) _header(l, typeUsers, all),
                    Expanded(
                      // Swipe sideways = the other tab, following the finger
                      // (off while reordering — a sideways drag there picks
                      // a level).
                      child: AppTabPager<CategoryType>(
                        controller: _pages,
                        values: _types,
                        selected: _listType,
                        onChanged: _setListType,
                        enabled: !_reordering,
                        builder: (context, t) {
                          final rows = t == _listType
                              ? typeUsers
                              : users.where((c) => c.type == t).toList();
                          return _listOrEmpty(l, rows, all, t);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Browse: the shell's nav shows through. Reorder: the move bar
            // (while a row is selected) over this bar replaces it.
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
        );
      },
    );
  }

  /// Search + `[สี▾][ไอคอน▾] … (✏️)`. In reorder mode they keep their
  /// space (invisible, so nothing under the finger moves — QA F1) and a
  /// hint takes it.
  Widget _header(
    AppLocalizations l,
    List<Category> typeUsers,
    List<Category> all,
  ) {
    final browse = Column(
      children: [
        AppSearchBar(
          controller: _search,
          hint: l.categoriesSearchHint,
          onChanged: (v) => setState(() => _query = v),
        ),
        _filterRow(l, typeUsers, all),
      ],
    );
    if (!_reordering) return browse;
    final scheme = Theme.of(context).colorScheme;
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
              child: Text(
                l.categoriesReorderTapHint,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// `[สี▾][ไอคอน▾] … (✏️)` — filters left, the list's edit mode right
  /// (the top bar carries no page actions; add is the dashed tile ending
  /// the list).
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
    return FilterBar(
      chips: [
        PopoverAnchor(
          builder: (context, toggle) => FilterDropdownChip(
            label: l.iconMakerTabColor,
            icon: AppIcons.colorPicker,
            count: _filterColors.length,
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
          builder: (context, toggle) => FilterDropdownChip(
            label: l.iconMakerRoleIcon,
            icon: AppIcons.iconPicker,
            count: _filterIcons.length,
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
      trailing: AppIconButton(
        icon: AppIcons.edit,
        size: 36,
        tooltip: l.categoriesReorderEnter,
        onPressed: typeUsers.length < 2
            ? null
            : () {
                // Reorder shows the whole tree — drop search / filters.
                _search.clear();
                _query = '';
                _filterColors.clear();
                _filterIcons.clear();
                _enterReorder(all);
              },
      ),
    );
  }

  Widget _listOrEmpty(
    AppLocalizations l,
    List<Category> typeUsers,
    List<Category> all,
    CategoryType type,
  ) {
    if (typeUsers.isEmpty) {
      return EmptyView(
        icon: AppIcons.category,
        title: l.categoriesEmptyTitle,
        message: l.categoriesEmptyMessage,
        cta: _reordering
            ? null
            : AddTile(label: l.categoriesAddNew, onTap: () => _add(l, type)),
      );
    }
    final visible = _reordering ? null : _visibleIds(typeUsers);
    if (visible != null && visible.isEmpty) {
      return EmptyView(
        icon: AppIcons.search,
        title: l.categoriesSearchNoMatch,
        message: '',
      );
    }
    final byId = {for (final c in typeUsers) c.id: c};
    final body = ReorderListScope(
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
        // Long-press enters the mode (not while searching / filtering —
        // the tree isn't whole then); it never starts a drag.
        onLongPress: visible != null || typeUsers.length < 2
            ? null
            : (id) => _enterReorder(all, select: id),
        onToggleCollapse: _toggleCollapse,
        addLabel: l.categoriesAddNew,
        onAdd: _reordering ? null : () => _add(l, type),
      ),
    );
    // Kept (off) while reordering: the same widgets above the list in both
    // modes keep its scroll offset when the mode switches.
    return PullToRefresh(
      enabled: !_reordering,
      onRefresh: () => context.read<CategoriesCubit>().load(),
      child: body,
    );
  }

  /// Create on [type] — the tab the add tile is on (QA F3).
  void _add(AppLocalizations l, CategoryType type) {
    if (!context.read<CategoriesCubit>().canAddMore) {
      showAppSnackBar(context, l.categoriesLimitReached, tone: Tone.warning);
      return;
    }
    context.push('/categories/new?type=${type.toJson()}');
  }
}

// ────────────────────────────────────────────────────────────────────
// List body — one ListView for both modes (so its offset survives the
// switch): browse walks the tree, reorder walks the controller's outline.
// ────────────────────────────────────────────────────────────────────

class _ListBody extends StatelessWidget {
  const _ListBody({
    required this.users,
    required this.type,
    required this.reorder,
    required this.visibleIds,
    required this.collapsedIds,
    required this.scrollController,
    required this.onLongPress,
    required this.onToggleCollapse,
    required this.addLabel,
    this.onAdd,
  });

  /// This tab's user categories.
  final List<Category> users;
  final CategoryType type;

  /// Non-null while reordering.
  final ReorderController? reorder;

  /// Search result ids (matches + ancestors); null = show everything.
  final Set<String>? visibleIds;
  final Set<String> collapsedIds;
  final ScrollController scrollController;
  final void Function(String id)? onLongPress;
  final void Function(String id) onToggleCollapse;

  /// The dashed "+ เพิ่มหมวดหมู่" tile after the last row (add lives in
  /// the body, not the top bar). Null hides it (reorder mode).
  final String addLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final rows = reorder == null ? _treeRows() : _outlineRows(reorder!);
    return ListView(
      // Restores the offset when the mode switch rebuilds the list.
      key: PageStorageKey('categories-list-${type.name}'),
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: AppSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        // Hairline-separated, as on the other library lists.
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const RowDivider(),
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
        const SizedBox(height: 96),
      ],
    );
  }

  /// Browse: the tree by sort order, collapsed parents closed, search
  /// results forced open.
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

  /// Reorder: the staged outline's visible rows for this tab.
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
        // Every level shows its own icon (owner 2026-10-11).
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

/// One category on the list — [ListRow] on the tree's indent: icon ·
/// name · description, then "ซ่อนจากรายงาน" and ▾/▴ (parents only).
/// In reorder mode the tap belongs to the [ReorderRow] (select); ▾/▴
/// keeps working.
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
    return ListRow(
      indent: depth * AppSpacing.xxl,
      leading: IconDisplay(
        type: IconType.category,
        size: 40,
        iconCode: iconCode,
      ),
      title: category.name,
      subtitle: category.description?.trim(),
      trailing: hidden || hasChildren
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hidden)
                  LabelPill(
                    label: l.categoryHiddenFromReport,
                    icon: AppIcons.hidden,
                  ),
                if (hasChildren)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      isCollapsed ? AppIcons.expand : AppIcons.collapse,
                    ),
                    onPressed: onToggleCollapse,
                  ),
              ],
            )
          : null,
      onTap: reorderMode
          ? null
          : () => context.push('/categories/${category.id}'),
      onLongPress: onLongPress,
    );
  }
}
