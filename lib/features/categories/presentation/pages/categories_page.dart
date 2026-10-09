import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/shell_chrome.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../shared/widgets/ui.dart';
import '../widgets/categories_list_skeleton.dart';
import '../../../../shared/widgets/reorder_drop_line.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/reorder_mode_tilt.dart';
import '../../domain/category.dart';
import '../../domain/category_reorder_logic.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../cubit/categories_cubit.dart';

/// Categories management with smart drag-and-drop reorder.
///
/// **Browse mode**:
/// - Tap row → edit form. Long-press → enter reorder mode.
/// - Chevron toggles collapse/expand for parents with children.
/// - A dashed "+ เพิ่มหมวดหมู่" tile ends the list (also the empty CTA).
/// - Bottom nav stays visible (`MainBottomNav` reused).
///
/// **Reorder mode** (entered via long-press):
/// - Each row visibly tilts ~2° + gets a corner mark, signalling
///   draggable.
/// - 350 ms long-press starts a drag. The dragged proxy floats with the
///   cursor; the original row dims.
/// - **Column-based depth lanes** — horizontal cursor position chooses
///   the target depth (1 / 2 / 3). Vertical position picks the anchor
///   row (the row directly above the cursor). Together they resolve to
///   a `(parentId, insertIdx)` plan via [CategoryDropResolver].
/// - Pre-validation: the drop indicator goes red when the resolver
///   rejects the move (cycle / depth overflow / level skip). User sees
///   red → can't drop. No more snackbar-after-rejection.
/// - Auto-scroll: when the cursor enters the top/bottom 100 dp band
///   while dragging, the list scrolls automatically. Speed ramps with
///   how deep into the band the cursor sits.
/// - Drop indicator is a horizontal line under the anchor row at the
///   chosen depth's indent.
/// - Bottom bar: Cancel · Undo · Save (in-mode undo, max 5).
/// - Back arrow doubles as Cancel.
///
/// Hover state lives in a single page-level [ValueNotifier] — only the
/// drop-line widget rebuilds as the cursor moves, everything else stays
/// painted (see `RepaintBoundary` wrappers below).
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  bool _reorderMode = false;

  /// Which type's tree the list is showing — toggled by the top tab bar.
  CategoryType _listType = CategoryType.expense;
  List<Category>? _staged;
  bool _dirty = false;
  bool _savingReorder = false;

  static const int _inModeUndoLimit = 5;
  final List<List<Category>> _inModeUndoStack = [];

  /// Shell chrome controller — lets reorder mode hide the shell's bottom
  /// nav so the [ReorderActionBar] replaces it instead of stacking under
  /// it. Grabbed in [didChangeDependencies].
  ShellChromeController? _shellChrome;

  /// Set of parent ids whose children are hidden in the list. Persists
  /// across mode switches so the user's collapse choices survive.
  final Set<String> _collapsedIds = <String>{};

  /// Locked while a drag is active so the chevron toggle can't fire
  /// mid-drag (which would yank rows out from under the pointer).
  bool _draggingNow = false;

  /// Single source of truth for hover state — the drop-line widget is
  /// the only thing that listens, so cursor moves don't rebuild the
  /// whole list.
  final ValueNotifier<_HoverState> _hover = ValueNotifier<_HoverState>(
    _HoverState.empty,
  );

  /// Throttle hover updates to ~one frame at 60 Hz. Without this,
  /// `onMove`'s firing rate (sub-millisecond) janks even with a
  /// ValueNotifier.
  DateTime _lastHoverUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  double _autoScrollSpeed = 0;

  /// Browse-mode search. Non-empty → the tree shows only matches plus
  /// their ancestors (auto-expanded) and long-press reorder is off.
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Cold-start fetch — idempotent, safe to re-enter the page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoriesCubit>().loadIfNeeded();
    });
  }

  /// Ids to show while searching: every match plus all its ancestors, so
  /// results keep their place in the tree. Null = not searching.
  Set<String>? _visibleIds(List<Category> users) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return null;
    final byId = {for (final c in users) c.id: c};
    final visible = <String>{};
    for (final c in users) {
      if (!c.name.toLowerCase().contains(q)) continue;
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
    // Safety net: if we somehow leave while reorder mode is still active,
    // restore the shell's chrome so the nav doesn't stay hidden.
    if (_reorderMode) _shellChrome?.show();
    _hover.dispose();
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  // ── Mode lifecycle ──────────────────────────────────────────────────

  void _enterReorder(List<Category> current) {
    HapticFeedback.lightImpact();
    _shellChrome?.hide(); // action bar replaces the shell nav
    setState(() {
      _reorderMode = true;
      _staged = List<Category>.from(current);
      _inModeUndoStack.clear();
      _dirty = false;
    });
  }

  void _cancelReorder() {
    _shellChrome?.show(); // restore the shell nav
    setState(() {
      _reorderMode = false;
      _staged = null;
      _inModeUndoStack.clear();
      _dirty = false;
      _draggingNow = false;
      _savingReorder = false;
      _hover.value = _HoverState.empty;
    });
    _stopAutoScroll();
  }

  Future<void> _saveReorder() async {
    if (_staged == null) {
      _cancelReorder();
      return;
    }
    final cubit = context.read<CategoriesCubit>();
    final l = AppLocalizations.of(context)!;
    setState(() => _savingReorder = true);
    try {
      await cubit.saveReorder(_staged!);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      _cancelReorder();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingReorder = false);
      showAppSnackBar(
        context,
        '${l.categoriesReorderSave}: ${e.message}',
        tone: Tone.danger,
      );
    }
  }

  void _undoLastDrag() {
    if (_inModeUndoStack.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _staged = _inModeUndoStack.removeLast();
      _dirty = _inModeUndoStack.isNotEmpty;
    });
  }

  void _pushInModeUndo() {
    _inModeUndoStack.add(List<Category>.unmodifiable(_staged!));
    if (_inModeUndoStack.length > _inModeUndoLimit) {
      _inModeUndoStack.removeAt(0);
    }
  }

  void _toggleCollapse(String id) {
    if (_draggingNow) return; // C1: lock collapse during drag
    setState(() {
      if (_collapsedIds.contains(id)) {
        _collapsedIds.remove(id);
      } else {
        _collapsedIds.add(id);
      }
    });
  }

  // ── Drag lifecycle ──────────────────────────────────────────────────

  /// IDs of the dragged item's **descendants** (not including the root
  /// itself). These rows are never valid drop anchors — dropping a
  /// parent into its own descendant would be a cycle. The root is
  /// tracked separately in [_draggedRoot] because it IS a valid anchor
  /// (drop-on-self enables in-place level change).
  final Set<String> _draggedDescendantIds = <String>{};

  /// The ROOT of the currently-dragged subtree.
  Category? _draggedRoot;

  /// True when the dragged root is **collapsed** at drag start — in
  /// that case the whole subtree travels with it as a block. False
  /// when expanded — only the root row moves; descendants stay where
  /// they are and get re-parented by the outliner rebuild.
  bool _dragsAsBlock = false;

  void _onDragStarted(Category dragged) {
    setState(() {
      _draggingNow = true;
      _draggedRoot = dragged;
      _dragsAsBlock = _collapsedIds.contains(dragged.id);
      _draggedDescendantIds
        ..clear()
        ..addAll(
          CategoryReorderLogic.subtreeIds(
            dragged.id,
            _staged!,
          ).where((id) => id != dragged.id),
        );
    });
    HapticFeedback.mediumImpact();
  }

  void _onDragEnded() {
    setState(() {
      _draggingNow = false;
      _draggedRoot = null;
      _dragsAsBlock = false;
      _draggedDescendantIds.clear();
    });
    _hover.value = _HoverState.empty;
    _stopAutoScroll();
  }

  /// Called from each row's `DragTarget.onMove`. Resolves the anchor
  /// based on the cursor's *vertical* position within the row:
  /// - **Upper portion** (~top 30%) → anchor = the row directly above
  ///   in the flat list. For the first row of a section, that's
  ///   `null` (= top-of-section drop).
  /// - **Lower portion** → anchor = this row (existing behavior).
  ///
  /// This generalizes "drop above" to every row, not just the first,
  /// and removes the need for a dedicated top-of-section widget that
  /// claims layout space.
  void _onPointerOverRow({
    required Category dragged,
    required Category thisRow,
    required Offset globalOffset,
    required RenderBox rowBox,
  }) {
    // Throttle: skip if last update < 16 ms ago.
    final now = DateTime.now();
    if (now.difference(_lastHoverUpdate).inMilliseconds < 16) return;
    _lastHoverUpdate = now;

    final local = rowBox.globalToLocal(globalOffset);
    final localX = local.dx.clamp(0.0, rowBox.size.width);
    final localY = local.dy;

    // Top 30% of the row = "drop above this row"; the rest = "drop
    // after this row". 30% feels right for finger taps without
    // accidentally triggering the upper region while aiming at body.
    final inUpperPortion = localY < rowBox.size.height * 0.3;

    final anchor = inUpperPortion ? _previousInFlat(thisRow) : thisRow;

    final laneWidth = (rowBox.size.width / 3).clamp(60.0, 120.0);
    final cursorCol = (localX / laneWidth).floor().clamp(0, 2) + 1;

    final _HoverState next;
    if (anchor == null) {
      // Top-of-section drop — always L1, signalled by null anchor
      // and `endType` so the section's top-line widget can find it.
      next = _HoverState(
        anchorRowId: null,
        depth: 1,
        isValid: true,
        isEnd: true,
        endType: thisRow.type,
      );
    } else {
      final level = CategoryReorderLogic.effectiveLevel(
        cursorCol: cursorCol,
        anchor: anchor,
        all: _staged!,
      );
      next = _HoverState(
        anchorRowId: anchor.id,
        depth: level,
        isValid: true,
        isEnd: false,
      );
    }

    if (next != _hover.value) {
      _hover.value = next;
      HapticFeedback.selectionClick();
    }

    _maybeAutoScroll(globalOffset);
  }

  /// Returns the row directly above [thisRow] in the user's flat list
  /// of [thisRow.type], or null when [thisRow] is the first.
  Category? _previousInFlat(Category thisRow) {
    final flat = CategoryReorderLogic.flatten(_staged!, thisRow.type);
    final idx = flat.indexWhere((r) => r.category.id == thisRow.id);
    if (idx <= 0) return null;
    return flat[idx - 1].category;
  }

  /// Resolves a category id back to its [Category] from the staged
  /// state. Used by [_commitFromHover] to convert the hover state's
  /// anchor id into the object [_commitDropOnRow] needs.
  Category? _findById(String id) {
    for (final c in _staged!) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Single dispatcher used by every row's `DragTarget.onAccept`.
  /// Reads the live hover state and routes to either the
  /// top-of-section commit or the row-anchored commit.
  void _commitFromHover(Category dragged) {
    final state = _hover.value;
    if (state.depth == null) return;
    if (state.anchorRowId == null) {
      _commitDropAtTop(state.endType ?? dragged.type, dragged);
      return;
    }
    final anchor = _findById(state.anchorRowId!);
    if (anchor == null) return;
    _commitDropOnRow(dragged: dragged, anchor: anchor, level: state.depth!);
  }

  void _onPointerLeftAllRows() {
    _hover.value = _HoverState.empty;
    _stopAutoScroll();
  }

  /// Commits the drop after a row body release. The current hover state
  /// already carries the clamped effective level — we trust it instead
  /// of recomputing.
  void _commitDropOnRow({
    required Category dragged,
    required Category anchor,
    required int level,
  }) {
    setState(() {
      _pushInModeUndo();
      _staged = CategoryReorderLogic.applyMove(
        all: _staged!,
        dragged: dragged,
        anchor: anchor,
        targetLevel: level,
        dragOnlyRoot: !_dragsAsBlock,
      );
      _dirty = true;
    });
    HapticFeedback.heavyImpact();
  }

  /// Commits a drop on the top-of-section zone.
  void _commitDropAtTop(CategoryType type, Category dragged) {
    if (dragged.type != type) return;
    setState(() {
      _pushInModeUndo();
      _staged = CategoryReorderLogic.applyMove(
        all: _staged!,
        dragged: dragged,
        anchor: null,
        targetLevel: 1,
        dragOnlyRoot: !_dragsAsBlock,
      );
      _dirty = true;
    });
    HapticFeedback.heavyImpact();
  }

  // ── Auto-scroll near edges ─────────────────────────────────────────

  void _maybeAutoScroll(Offset globalOffset) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalOffset).dy;
    final viewportHeight = box.size.height;
    const edge = 100.0;

    double speed = 0;
    if (local < edge) {
      speed = -((edge - local) / edge) * 8.0;
    } else if (local > viewportHeight - edge) {
      speed = ((local - (viewportHeight - edge)) / edge) * 8.0;
    }

    if (speed == 0) {
      _stopAutoScroll();
      return;
    }
    _autoScrollSpeed = speed;
    _autoScrollTimer ??= Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _tickAutoScroll(),
    );
  }

  void _tickAutoScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final next = (pos.pixels + _autoScrollSpeed).clamp(
      0.0,
      pos.maxScrollExtent,
    );
    if (next == pos.pixels) return;
    _scrollController.jumpTo(next);
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollSpeed = 0;
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final all = state.categories;
        final source = _reorderMode ? (_staged ?? all) : all;
        final users = source.where((c) => !c.isSystem).toList();
        final typeUsers = users.where((c) => c.type == _listType).toList();
        final visible = _reorderMode ? null : _visibleIds(typeUsers);
        return PopScope(
          canPop: !_reorderMode,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_reorderMode) _cancelReorder();
          },
          child: Scaffold(
            // The bar floats over the body; the pinned column below starts
            // with a spacer of its height.
            extendBodyBehindAppBar: true,
            appBar: AppTopBar(
              title: _reorderMode
                  ? l.categoriesReorderEnter
                  : l.categoriesTitle,
              showBack: true,
              editing: _reorderMode,
              onBack: _reorderMode ? _cancelReorder : null,
            ),
            body: AsyncStateView(
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
                  child: const LoadingView(skeleton: CategoriesListSkeleton()),
                ),
              ),
              // Per-type empty lives under the tabs ([_listOrEmpty]).
              builder: (context) => Column(
                children: [
                  // Clear the transparent top bar.
                  SizedBox(height: MediaQuery.paddingOf(context).top),
                  AppTabBar<CategoryType>(
                    selected: _listType,
                    onChanged: (t) => setState(() => _listType = t),
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
                  // Hidden (not just disabled) in reorder mode so the
                  // tree can't be filtered mid-drag.
                  if (!_reorderMode && typeUsers.isNotEmpty)
                    AppSearchBar(
                      hint: l.categoriesSearchHint,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  Expanded(child: _listOrEmpty(l, typeUsers, all, visible)),
                ],
              ),
            ),
            // Browse: the shell's nav shows through. Reorder: this bar
            // replaces it (ShellChrome.hide on entry).
            bottomNavigationBar: _reorderMode
                ? ModeActionBar(
                    canUndo: _inModeUndoStack.isNotEmpty && !_savingReorder,
                    canSave: _dirty && !_savingReorder,
                    saving: _savingReorder,
                    cancelLabel: l.categoriesReorderCancel,
                    saveLabel: l.categoriesReorderSave,
                    undoTooltip: l.categoriesUndo,
                    onCancel: _savingReorder ? () {} : _cancelReorder,
                    onUndo: _undoLastDrag,
                    onSave: _saveReorder,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _listOrEmpty(
    AppLocalizations l,
    List<Category> typeUsers,
    List<Category> all,
    Set<String>? visible,
  ) {
    if (typeUsers.isEmpty) {
      return EmptyView(
        icon: AppIcons.category,
        title: l.categoriesEmptyTitle,
        message: l.categoriesEmptyMessage,
        cta: _reorderMode
            ? null
            : AddTile(label: l.categoriesAddNew, onTap: () => _add(l)),
      );
    }
    if (visible != null && visible.isEmpty) {
      return EmptyView(
        icon: AppIcons.search,
        title: l.categoriesSearchNoMatch,
        message: '',
      );
    }
    final body = _ListBody(
      users: typeUsers,
      type: _listType,
      reorderMode: _reorderMode,
      visibleIds: visible,
      collapsedIds: _collapsedIds,
      draggedRootId: _draggedRoot?.id,
      draggedDescendantIds: _draggedDescendantIds,
      dragsAsBlock: _dragsAsBlock,
      hover: _hover,
      scrollController: _scrollController,
      onLongPressEnter: () => _enterReorder(all),
      onToggleCollapse: _toggleCollapse,
      onDragStarted: _onDragStarted,
      onDragEnded: _onDragEnded,
      onPointerOverRow: _onPointerOverRow,
      onPointerLeftAllRows: _onPointerLeftAllRows,
      onCommit: _commitFromHover,
      addLabel: l.categoriesAddNew,
      // The add tile ends the list in browse mode only.
      onAdd: _reorderMode ? null : () => _add(l),
    );
    if (_reorderMode) return body;
    return PullToRefresh(
      onRefresh: () => context.read<CategoriesCubit>().load(),
      child: body,
    );
  }

  void _add(AppLocalizations l) {
    if (!context.read<CategoriesCubit>().canAddMore) {
      showAppSnackBar(context, l.categoriesLimitReached, tone: Tone.warning);
      return;
    }
    context.push('/categories/new');
  }
}

// ────────────────────────────────────────────────────────────────────
// Hover state
// ────────────────────────────────────────────────────────────────────

/// Single source of truth for "which row + which depth lane is the
/// drag pointer over right now". Consumed by the drop-line indicator
/// (which is the only widget rebuilding on cursor move).
class _HoverState {
  const _HoverState({
    this.anchorRowId,
    this.depth,
    this.isValid = false,
    this.isEnd = false,
    this.endType,
  });

  final String? anchorRowId;
  final int? depth;
  final bool isValid;
  final bool isEnd;
  final CategoryType? endType;

  static const empty = _HoverState();

  @override
  bool operator ==(Object other) =>
      other is _HoverState &&
      other.anchorRowId == anchorRowId &&
      other.depth == depth &&
      other.isValid == isValid &&
      other.isEnd == isEnd &&
      other.endType == endType;

  @override
  int get hashCode => Object.hash(anchorRowId, depth, isValid, isEnd, endType);
}

// ────────────────────────────────────────────────────────────────────
// List body — handles browse + reorder, tree walking, collapse
// ────────────────────────────────────────────────────────────────────

class _ListBody extends StatelessWidget {
  const _ListBody({
    required this.users,
    required this.type,
    required this.reorderMode,
    required this.visibleIds,
    required this.collapsedIds,
    required this.draggedRootId,
    required this.draggedDescendantIds,
    required this.dragsAsBlock,
    required this.hover,
    required this.scrollController,
    required this.onLongPressEnter,
    required this.onToggleCollapse,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onPointerOverRow,
    required this.onPointerLeftAllRows,
    required this.onCommit,
    required this.addLabel,
    this.onAdd,
  });

  final List<Category> users;

  /// The single type this list renders (driven by the top tab bar).
  final CategoryType type;

  final bool reorderMode;

  /// Search result ids (matches + ancestors); null = show everything.
  final Set<String>? visibleIds;

  final Set<String> collapsedIds;

  /// Id of the dragged subtree's root, or null when no drag is active.
  /// The root always fades (it's the row being moved).
  final String? draggedRootId;

  /// Descendants of the dragged root. Faded only when [dragsAsBlock] is
  /// true (collapsed parent travels with subtree); when false (expanded
  /// parent), descendants stay solid because they aren't moving.
  final Set<String> draggedDescendantIds;

  /// True = drag a collapsed parent's whole subtree as one block.
  /// False = drag only the dragged row; descendants stay in place and
  /// get re-parented by the outliner walk during reconstruction.
  final bool dragsAsBlock;

  final ValueNotifier<_HoverState> hover;
  final ScrollController scrollController;
  final VoidCallback onLongPressEnter;
  final void Function(String id) onToggleCollapse;
  final void Function(Category dragged) onDragStarted;
  final VoidCallback onDragEnded;
  final void Function({
    required Category dragged,
    required Category thisRow,
    required Offset globalOffset,
    required RenderBox rowBox,
  })
  onPointerOverRow;
  final VoidCallback onPointerLeftAllRows;

  /// Single commit dispatcher. Reads the live hover state to decide
  /// between top-of-section drops (anchor null) and row-anchored drops.
  final void Function(Category dragged) onCommit;

  /// The dashed "+ เพิ่มหมวดหมู่" tile after the last row (add lives in
  /// the body, not the top bar). Null hides it (reorder mode).
  final String addLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final roots =
        users.where((c) => c.type == type && c.parentId == null).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        if (reorderMode) _TopOfSectionLine(type: type, hover: hover),
        for (final parent in roots)
          if (visibleIds?.contains(parent.id) ?? true)
            ..._renderSubtree(parent, depth: 0),
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

  List<Widget> _renderSubtree(Category category, {required int depth}) {
    final children = users.where((c) => c.parentId == category.id).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    // Searching forces matches + ancestors open.
    final isCollapsed =
        visibleIds == null && collapsedIds.contains(category.id);
    // Fade rules:
    // - The dragged root always fades (it's the row being moved).
    // - Descendants fade only when the parent is collapsed at drag
    //   start (`dragsAsBlock`). When expanded, descendants stay solid
    //   because they're not moving with the drag.
    final isDraggingThis =
        category.id == draggedRootId ||
        (dragsAsBlock && draggedDescendantIds.contains(category.id));

    // Color inheritance — every row's display color comes from its L1
    // ancestor. Override the color field once here so every downstream
    // widget (icon circle, drag proxy, etc.) picks it up without prop
    // drilling.
    final inheritedIconCode = CategoryTree.resolveIconCode(category, users);
    final renderCategory = inheritedIconCode == category.iconCode
        ? category
        : category.copyWith(iconCode: inheritedIconCode);

    return [
      RepaintBoundary(
        child: Opacity(
          opacity: isDraggingThis ? 0.3 : 1.0,
          child: _Row(
            category: renderCategory,
            depth: depth,
            reorderMode: reorderMode,
            hasChildren: children.isNotEmpty,
            isCollapsed: isCollapsed,
            hover: hover,
            dragEnabled: reorderMode || visibleIds == null,
            onLongPressEnter: onLongPressEnter,
            onToggleCollapse: onToggleCollapse,
            onDragStarted: onDragStarted,
            onDragEnded: onDragEnded,
            onPointerOverRow: onPointerOverRow,
            onPointerLeftAllRows: onPointerLeftAllRows,
            onCommit: onCommit,
          ),
        ),
      ),
      if (!isCollapsed)
        for (final c in children)
          if (visibleIds?.contains(c.id) ?? true)
            ..._renderSubtree(c, depth: depth + 1),
    ];
  }
}

// ────────────────────────────────────────────────────────────────────
// One row — used for both browse + reorder. Picks behavior from props.
// ────────────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  const _Row({
    required this.category,
    required this.depth,
    required this.reorderMode,
    required this.dragEnabled,
    required this.hasChildren,
    required this.isCollapsed,
    required this.hover,
    required this.onLongPressEnter,
    required this.onToggleCollapse,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onPointerOverRow,
    required this.onPointerLeftAllRows,
    required this.onCommit,
  });

  final Category category;
  final int depth;
  final bool reorderMode;

  /// False while searching — rows are plain taps, no long-press reorder.
  final bool dragEnabled;
  final bool hasChildren;
  final bool isCollapsed;
  final ValueNotifier<_HoverState> hover;
  final VoidCallback onLongPressEnter;
  final void Function(String id) onToggleCollapse;
  final void Function(Category dragged) onDragStarted;
  final VoidCallback onDragEnded;
  final void Function({
    required Category dragged,
    required Category thisRow,
    required Offset globalOffset,
    required RenderBox rowBox,
  })
  onPointerOverRow;
  final VoidCallback onPointerLeftAllRows;

  /// Single dispatcher invoked on drop accept. Reads the live hover
  /// state to route between top-of-section and row-anchored commits.
  final void Function(Category dragged) onCommit;

  @override
  Widget build(BuildContext context) {
    final body = _RowContent(
      category: category,
      depth: depth,
      reorderMode: reorderMode,
      hasChildren: hasChildren,
      isCollapsed: isCollapsed,
      onToggleCollapse: () => onToggleCollapse(category.id),
    );

    // The LongPressDraggable wraps every row in BOTH modes so that one
    // continuous long-press in browse mode can fall through into a drag
    // without the user having to release and long-press again. In
    // browse mode, [onDragStarted] also flips the page into reorder
    // mode in the same frame; the drag overlay keeps following the
    // pointer because Draggable's gesture stream isn't tied to the
    // rebuild cycle.
    //
    // DragTarget is also always present for symmetry, but its handlers
    // short-circuit when [reorderMode] is false. Keeping the structural
    // shape stable across mode transitions avoids gesture-recognizer
    // resets mid-press.
    if (!dragEnabled) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (rowContext) {
            return DragTarget<Category>(
              onMove: (details) {
                if (!reorderMode) return;
                final box = rowContext.findRenderObject() as RenderBox?;
                if (box == null) return;
                onPointerOverRow(
                  dragged: details.data,
                  thisRow: category,
                  globalOffset: details.offset,
                  rowBox: box,
                );
              },
              onLeave: (_) {
                if (reorderMode) onPointerLeftAllRows();
              },
              // Self-drop is allowed — the page-level handler distinguishes
              // descendants (rejected via empty hover state) from the root
              // itself (accepted, used for in-place level change).
              onWillAcceptWithDetails: (_) => reorderMode,
              onAcceptWithDetails: (d) {
                if (!reorderMode) return;
                if (hover.value.depth == null) return;
                onCommit(d.data);
              },
              builder: (context, candidate, rejected) {
                return LongPressDraggable<Category>(
                  data: category,
                  // 500 ms in browse mode — entering reorder mode is a
                  // mode switch, so the gesture should feel deliberate.
                  // 350 ms in reorder mode — the user is already
                  // committed; quicker pickup keeps successive drags
                  // snappy.
                  delay: Duration(milliseconds: reorderMode ? 350 : 500),
                  hapticFeedbackOnStart: false, // we trigger our own
                  onDragStarted: () {
                    // Browse mode: flip into reorder mode first so the
                    // staged list and tilt cue are ready by the time the
                    // user moves. The same gesture continues into the drag.
                    if (!reorderMode) onLongPressEnter();
                    onDragStarted(category);
                  },
                  onDraggableCanceled: (_, _) => onDragEnded(),
                  onDragEnd: (_) => onDragEnded(),
                  onDragCompleted: onDragEnded,
                  feedback: _DragProxy(category: category),
                  // The outer wrapper in `_renderSubtree` already applies
                  // Opacity(0.3) to the dragged root (and to descendants
                  // when [dragsAsBlock] is true). Wrapping body in another
                  // Opacity here would multiply (0.3 × 0.3 = 0.09) and
                  // make the placeholder almost invisible.
                  childWhenDragging: body,
                  child: body,
                );
              },
            );
          },
        ),
        // Drop-line indicator under this row. Always rendered so the
        // widget tree shape doesn't change when reorder mode toggles —
        // in browse mode, hover is always empty so the AnimatedSize
        // collapses to zero height.
        ValueListenableBuilder<_HoverState>(
          valueListenable: hover,
          builder: (context, state, _) {
            final anchored =
                state.anchorRowId == category.id && state.depth != null;
            return AnimatedSize(
              duration: const Duration(milliseconds: 120),
              alignment: Alignment.topCenter,
              child: anchored
                  ? ReorderDropLine(
                      depth: state.depth!,
                      isValid: state.isValid,
                      indentPerDepth: AppSpacing.xxl,
                      baseIndent: AppSpacing.lg,
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}

class _RowContent extends StatelessWidget {
  const _RowContent({
    required this.category,
    required this.depth,
    required this.reorderMode,
    required this.hasChildren,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  final Category category;
  final int depth;
  final bool reorderMode;
  final bool hasChildren;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg + depth * AppSpacing.xxl,
        right: AppSpacing.lg,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _IconCircle(category: category, reorderMode: reorderMode),
        title: Text(
          category.name,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: !category.includeInReport
            ? Text(
                l.categoryHiddenFromReport,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              )
            : null,
        trailing: _RowTrailing(
          reorderMode: reorderMode,
          hasChildren: hasChildren,
          isCollapsed: isCollapsed,
          onToggleCollapse: onToggleCollapse,
        ),
        onTap: reorderMode
            ? null
            : () => context.push('/categories/${category.id}'),
      ),
    );
  }
}

class _RowTrailing extends StatelessWidget {
  const _RowTrailing({
    required this.reorderMode,
    required this.hasChildren,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  final bool reorderMode;
  final bool hasChildren;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    if (reorderMode) {
      // Reorder-mode trailing matches browse mode: chevron toggle for
      // parents (still works mid-reorder), nothing for leaves. The
      // drag-handle icon is intentionally absent — the corner-bracket
      // overlay on the icon already signals draggability, and dropping
      // the handle keeps row width identical to browse mode.
      if (!hasChildren) return const SizedBox.shrink();
      return IconButton(
        icon: AnimatedRotation(
          turns: isCollapsed ? 0 : 0.25,
          duration: const Duration(milliseconds: 160),
          child: const Icon(AppIcons.chevronRight),
        ),
        onPressed: onToggleCollapse,
      );
    }
    if (hasChildren) {
      return IconButton(
        icon: AnimatedRotation(
          turns: isCollapsed ? 0 : 0.25,
          duration: const Duration(milliseconds: 160),
          child: const Icon(AppIcons.chevronRight),
        ),
        onPressed: onToggleCollapse,
      );
    }
    return const Icon(AppIcons.chevronRight);
  }
}

// ────────────────────────────────────────────────────────────────────
// Icon — applies tilt + corner mark in reorder mode
// ────────────────────────────────────────────────────────────────────

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.category, required this.reorderMode});

  final Category category;
  final bool reorderMode;

  @override
  Widget build(BuildContext context) {
    final circle = IconDisplay(
      type: IconType.category,
      size: 36,
      iconCode: category.iconCode,
    );
    if (!reorderMode) return circle;
    // Reorder mode visual cue is shared across reorderable surfaces.
    return ReorderModeTilt(child: circle);
  }
}

// ────────────────────────────────────────────────────────────────────
// Top-of-section drop indicator — a thin line that appears between the
// section header and the first row only when the live hover state has
// `anchorRowId == null` (cursor is in the upper portion of the first
// row). Layout cost is zero when no drop is targeted at the top, so
// reorder mode keeps the same spacing as browse mode.
// ────────────────────────────────────────────────────────────────────

class _TopOfSectionLine extends StatelessWidget {
  const _TopOfSectionLine({required this.type, required this.hover});

  final CategoryType type;
  final ValueNotifier<_HoverState> hover;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_HoverState>(
      valueListenable: hover,
      builder: (context, state, _) {
        final active =
            state.anchorRowId == null &&
            state.endType == type &&
            state.depth != null;
        return AnimatedSize(
          duration: const Duration(milliseconds: 120),
          alignment: Alignment.topCenter,
          child: active
              ? ReorderDropLine(
                  depth: state.depth!,
                  isValid: state.isValid,
                  indentPerDepth: AppSpacing.xxl,
                  baseIndent: AppSpacing.lg,
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Drag proxy (floats with cursor)
// ────────────────────────────────────────────────────────────────────

class _DragProxy extends StatelessWidget {
  const _DragProxy({required this.category});
  final Category category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppRadius.md),
      color: scheme.surfaceContainerHigh,
      child: SizedBox(
        width: 280,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              IconDisplay(
                type: IconType.category,
                size: 36,
                iconCode: category.iconCode,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const Icon(AppIcons.reorder),
            ],
          ),
        ),
      ),
    );
  }
}
