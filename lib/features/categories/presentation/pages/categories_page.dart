import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/main_bottom_nav.dart';
import '../../../../app/shell/more_menu_sheet.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/reorder_action_bar.dart';
import '../../../../shared/widgets/reorder_drop_line.dart';
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
  List<Category>? _staged;
  bool _dirty = false;

  static const int _inModeUndoLimit = 5;
  final List<List<Category>> _inModeUndoStack = [];

  /// Set of parent ids whose children are hidden in the list. Persists
  /// across mode switches so the user's collapse choices survive.
  final Set<String> _collapsedIds = <String>{};

  /// Locked while a drag is active so the chevron toggle can't fire
  /// mid-drag (which would yank rows out from under the pointer).
  bool _draggingNow = false;

  /// Single source of truth for hover state — the drop-line widget is
  /// the only thing that listens, so cursor moves don't rebuild the
  /// whole list.
  final ValueNotifier<_HoverState> _hover =
      ValueNotifier<_HoverState>(_HoverState.empty);

  /// Throttle hover updates to ~one frame at 60 Hz. Without this,
  /// `onMove`'s firing rate (sub-millisecond) janks even with a
  /// ValueNotifier.
  DateTime _lastHoverUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  double _autoScrollSpeed = 0;

  @override
  void dispose() {
    _hover.dispose();
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  // ── Mode lifecycle ──────────────────────────────────────────────────

  void _enterReorder(List<Category> current) {
    HapticFeedback.lightImpact();
    setState(() {
      _reorderMode = true;
      _staged = List<Category>.from(current);
      _inModeUndoStack.clear();
      _dirty = false;
    });
  }

  void _cancelReorder() {
    setState(() {
      _reorderMode = false;
      _staged = null;
      _inModeUndoStack.clear();
      _dirty = false;
      _draggingNow = false;
      _hover.value = _HoverState.empty;
    });
    _stopAutoScroll();
  }

  void _saveReorder() {
    if (_staged != null) {
      context.read<CategoriesCubit>().replaceAll(_staged!);
    }
    HapticFeedback.mediumImpact();
    _cancelReorder();
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

  /// IDs of every row currently traveling with the dragged item (the
  /// dragged subtree). Populated on drag start so the rows can fade
  /// while the drag is in flight.
  final Set<String> _draggedSubtreeIds = <String>{};

  /// The ROOT of the currently-dragged subtree. Distinct from the rest
  /// of [_draggedSubtreeIds] because the root is allowed to be its own
  /// drop anchor — hovering over the dragged row's ghost lets the user
  /// change its level in place. Descendants stay non-anchorable.
  Category? _draggedRoot;

  void _onDragStarted(Category dragged) {
    setState(() {
      _draggingNow = true;
      _draggedRoot = dragged;
      _draggedSubtreeIds
        ..clear()
        ..addAll(CategoryReorderLogic.subtreeIds(dragged.id, _staged!));
    });
    HapticFeedback.mediumImpact();
  }

  void _onDragEnded() {
    setState(() {
      _draggingNow = false;
      _draggedRoot = null;
      _draggedSubtreeIds.clear();
    });
    _hover.value = _HoverState.empty;
    _stopAutoScroll();
  }

  /// Called from each row's `DragTarget.onMove`. Computes the anchor
  /// (this row) and the effective level (cursor column with the two
  /// clamps applied: top-of-section → L1, col-3-over-L1 → L2).
  void _onPointerOverRow({
    required Category dragged,
    required Category anchor,
    required Offset globalOffset,
    required RenderBox rowBox,
  }) {
    // Descendants of the dragged subtree can't be a valid drop anchor —
    // the whole subtree is traveling with the cursor, so dropping onto
    // one of the dragged item's own descendants is meaningless. The
    // dragged root itself IS a valid anchor: hovering over its ghost
    // lets the user change its level in place without moving the row.
    final isDescendant = _draggedSubtreeIds.contains(anchor.id) &&
        anchor.id != _draggedRoot?.id;
    if (isDescendant) {
      if (_hover.value != _HoverState.empty) {
        _hover.value = _HoverState.empty;
      }
      return;
    }

    // Throttle: skip if last update < 16 ms ago.
    final now = DateTime.now();
    if (now.difference(_lastHoverUpdate).inMilliseconds < 16) return;
    _lastHoverUpdate = now;

    final localX =
        rowBox.globalToLocal(globalOffset).dx.clamp(0.0, rowBox.size.width);
    final laneWidth = (rowBox.size.width / 3).clamp(60.0, 120.0);
    final cursorCol = (localX / laneWidth).floor().clamp(0, 2) + 1;

    final level = CategoryReorderLogic.effectiveLevel(
      cursorCol: cursorCol,
      anchor: anchor,
      all: _staged!,
    );

    final next = _HoverState(
      anchorRowId: anchor.id,
      depth: level,
      isValid: true,
      isEnd: false,
    );

    if (next != _hover.value) {
      _hover.value = next;
      HapticFeedback.selectionClick();
    }

    _maybeAutoScroll(globalOffset);
  }

  /// Top-of-section drop zone — anchor is null, level is forced to 1.
  void _onPointerOverTop({
    required CategoryType type,
    required Offset globalOffset,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastHoverUpdate).inMilliseconds < 16) return;
    _lastHoverUpdate = now;
    final next = _HoverState(
      anchorRowId: null,
      depth: 1,
      isValid: true,
      isEnd: true,
      endType: type,
    );
    if (next != _hover.value) _hover.value = next;
    _maybeAutoScroll(globalOffset);
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
    final next = (pos.pixels + _autoScrollSpeed)
        .clamp(0.0, pos.maxScrollExtent);
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
    return BlocBuilder<CategoriesCubit, List<Category>>(
      builder: (context, all) {
        final source = _reorderMode ? (_staged ?? all) : all;
        final users = source.where((c) => !c.isSystem).toList();
        return PopScope(
          canPop: !_reorderMode,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_reorderMode) _cancelReorder();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: _reorderMode
                    ? l.categoriesReorderCancel
                    : l.commonBack,
                onPressed: () {
                  if (_reorderMode) {
                    _cancelReorder();
                  } else {
                    context.pop();
                  }
                },
              ),
              title: Text(l.categoriesTitle),
              actions: _reorderMode
                  ? const []
                  : _buildBrowseActions(context, l),
            ),
            body: users.isEmpty
                ? EmptyView(
                    icon: Icons.category_outlined,
                    title: l.categoriesEmptyTitle,
                    message: l.categoriesEmptyMessage,
                  )
                : _ListBody(
                    users: users,
                    reorderMode: _reorderMode,
                    collapsedIds: _collapsedIds,
                    draggedSubtreeIds: _draggedSubtreeIds,
                    hover: _hover,
                    scrollController: _scrollController,
                    onLongPressEnter: () => _enterReorder(all),
                    onToggleCollapse: _toggleCollapse,
                    onDragStarted: _onDragStarted,
                    onDragEnded: _onDragEnded,
                    onPointerOverRow: _onPointerOverRow,
                    onPointerOverTop: _onPointerOverTop,
                    onPointerLeftAllRows: _onPointerLeftAllRows,
                    onCommitDropOnRow: _commitDropOnRow,
                    onCommitDropAtTop: _commitDropAtTop,
                  ),
            bottomNavigationBar: _reorderMode
                ? ReorderActionBar(
                    canUndo: _inModeUndoStack.isNotEmpty,
                    canSave: _dirty,
                    cancelLabel: l.categoriesReorderCancel,
                    saveLabel: l.categoriesReorderSave,
                    undoTooltip: l.categoriesUndo,
                    onCancel: _cancelReorder,
                    onUndo: _undoLastDrag,
                    onSave: _saveReorder,
                  )
                : MainBottomNav(
                    currentIndex: -1,
                    onTabSelected: (i) {
                      switch (i) {
                        case 0:
                          context.go('/');
                        case 1:
                          context.go('/accounts');
                        case 2:
                          context.go('/projects');
                      }
                    },
                    onAddPressed: () => _showAddTransactionStub(context, l),
                    onMorePressed: () => MoreMenuSheet.show(context),
                  ),
            floatingActionButton: _reorderMode
                ? null
                : FloatingActionButton(
                    tooltip: l.navAddTransaction,
                    onPressed: () => _showAddTransactionStub(context, l),
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add),
                  ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          ),
        );
      },
    );
  }

  List<Widget> _buildBrowseActions(
      BuildContext context, AppLocalizations l) {
    final cubit = context.read<CategoriesCubit>();
    return [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: cubit.canUndo
            ? IconButton(
                key: const ValueKey('undo'),
                tooltip: l.categoriesUndo,
                icon: const Icon(Icons.undo),
                onPressed: cubit.undo,
              )
            : const SizedBox.shrink(key: ValueKey('no-undo')),
      ),
      IconButton(
        tooltip: l.categoriesAddNew,
        icon: const Icon(Icons.add),
        onPressed: () {
          if (!cubit.canAddMore) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                  SnackBar(content: Text(l.categoriesLimitReached)));
            return;
          }
          context.push('/categories/new');
        },
      ),
    ];
  }

  void _showAddTransactionStub(BuildContext context, AppLocalizations l) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l.addTransactionComingSoon)),
      );
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
    required this.reorderMode,
    required this.collapsedIds,
    required this.draggedSubtreeIds,
    required this.hover,
    required this.scrollController,
    required this.onLongPressEnter,
    required this.onToggleCollapse,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onPointerOverRow,
    required this.onPointerOverTop,
    required this.onPointerLeftAllRows,
    required this.onCommitDropOnRow,
    required this.onCommitDropAtTop,
  });

  final List<Category> users;
  final bool reorderMode;
  final Set<String> collapsedIds;
  final Set<String> draggedSubtreeIds;
  final ValueNotifier<_HoverState> hover;
  final ScrollController scrollController;
  final VoidCallback onLongPressEnter;
  final void Function(String id) onToggleCollapse;
  final void Function(Category dragged) onDragStarted;
  final VoidCallback onDragEnded;
  final void Function({
    required Category dragged,
    required Category anchor,
    required Offset globalOffset,
    required RenderBox rowBox,
  }) onPointerOverRow;
  final void Function({
    required CategoryType type,
    required Offset globalOffset,
  }) onPointerOverTop;
  final VoidCallback onPointerLeftAllRows;
  final void Function({
    required Category dragged,
    required Category anchor,
    required int level,
  }) onCommitDropOnRow;
  final void Function(CategoryType type, Category dragged) onCommitDropAtTop;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final expense = users
        .where((c) => c.type == CategoryType.expense && c.parentId == null)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final income = users
        .where((c) => c.type == CategoryType.income && c.parentId == null)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        _SectionHeader(label: l.categoriesSectionExpense),
        if (reorderMode)
          _TopZone(
            type: CategoryType.expense,
            hover: hover,
            onPointerOverTop: onPointerOverTop,
            onAccept: (dragged) =>
                onCommitDropAtTop(CategoryType.expense, dragged),
          ),
        for (final parent in expense)
          ..._renderSubtree(parent, depth: 0),
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(label: l.categoriesSectionIncome),
        if (reorderMode)
          _TopZone(
            type: CategoryType.income,
            hover: hover,
            onPointerOverTop: onPointerOverTop,
            onAccept: (dragged) =>
                onCommitDropAtTop(CategoryType.income, dragged),
          ),
        for (final c in income) ..._renderSubtree(c, depth: 0),
        const SizedBox(height: 96),
      ],
    );
  }

  List<Widget> _renderSubtree(Category category, {required int depth}) {
    final children = users.where((c) => c.parentId == category.id).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final isCollapsed = collapsedIds.contains(category.id);
    final isDraggingThis = draggedSubtreeIds.contains(category.id);

    // Color inheritance — every row's display color comes from its L1
    // ancestor. Override the color field once here so every downstream
    // widget (icon circle, drag proxy, etc.) picks it up without prop
    // drilling.
    final inheritedColor = CategoryTree.resolveColor(category, users);
    final renderCategory = inheritedColor.id == category.color.id
        ? category
        : category.copyWith(color: inheritedColor);

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
            onLongPressEnter: onLongPressEnter,
            onToggleCollapse: onToggleCollapse,
            onDragStarted: onDragStarted,
            onDragEnded: onDragEnded,
            onPointerOverRow: onPointerOverRow,
            onPointerLeftAllRows: onPointerLeftAllRows,
            onCommitDropOnRow: onCommitDropOnRow,
          ),
        ),
      ),
      if (!isCollapsed)
        for (final c in children)
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
    required this.hasChildren,
    required this.isCollapsed,
    required this.hover,
    required this.onLongPressEnter,
    required this.onToggleCollapse,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onPointerOverRow,
    required this.onPointerLeftAllRows,
    required this.onCommitDropOnRow,
  });

  final Category category;
  final int depth;
  final bool reorderMode;
  final bool hasChildren;
  final bool isCollapsed;
  final ValueNotifier<_HoverState> hover;
  final VoidCallback onLongPressEnter;
  final void Function(String id) onToggleCollapse;
  final void Function(Category dragged) onDragStarted;
  final VoidCallback onDragEnded;
  final void Function({
    required Category dragged,
    required Category anchor,
    required Offset globalOffset,
    required RenderBox rowBox,
  }) onPointerOverRow;
  final VoidCallback onPointerLeftAllRows;
  final void Function({
    required Category dragged,
    required Category anchor,
    required int level,
  }) onCommitDropOnRow;

  @override
  Widget build(BuildContext context) {
    final body = _RowContent(
      category: category,
      depth: depth,
      reorderMode: reorderMode,
      hasChildren: hasChildren,
      isCollapsed: isCollapsed,
      onLongPressEnter: onLongPressEnter,
      onToggleCollapse: () => onToggleCollapse(category.id),
    );

    if (!reorderMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [body],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(builder: (rowContext) {
          return DragTarget<Category>(
            onMove: (details) {
              final box = rowContext.findRenderObject() as RenderBox?;
              if (box == null) return;
              onPointerOverRow(
                dragged: details.data,
                anchor: category,
                globalOffset: details.offset,
                rowBox: box,
              );
            },
            onLeave: (_) => onPointerLeftAllRows(),
            // Self-drop is allowed — the page-level handler distinguishes
            // descendants (rejected via empty hover state) from the root
            // itself (accepted, used for in-place level change).
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (d) {
              final state = hover.value;
              if (state.anchorRowId != category.id || state.depth == null) {
                return;
              }
              onCommitDropOnRow(
                dragged: d.data,
                anchor: category,
                level: state.depth!,
              );
            },
            builder: (context, candidate, rejected) {
              return LongPressDraggable<Category>(
                data: category,
                delay: const Duration(milliseconds: 350),
                hapticFeedbackOnStart: false, // we trigger our own
                onDragStarted: () => onDragStarted(category),
                onDraggableCanceled: (_, _) => onDragEnded(),
                onDragEnd: (_) => onDragEnded(),
                onDragCompleted: onDragEnded,
                feedback: _DragProxy(category: category),
                childWhenDragging:
                    Opacity(opacity: 0.3, child: body),
                child: body,
              );
            },
          );
        }),
        // Drop-line indicator under this row. Only rebuilds when the
        // cursor anchors here; otherwise renders an empty zero-height
        // placeholder.
        ValueListenableBuilder<_HoverState>(
          valueListenable: hover,
          builder: (context, state, _) {
            if (state.anchorRowId != category.id || state.depth == null) {
              return const SizedBox(height: 4);
            }
            return ReorderDropLine(
              depth: state.depth!,
              isValid: state.isValid,
              indentPerDepth: AppSpacing.xxl,
              baseIndent: AppSpacing.lg,
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
    required this.onLongPressEnter,
    required this.onToggleCollapse,
  });

  final Category category;
  final int depth;
  final bool reorderMode;
  final bool hasChildren;
  final bool isCollapsed;
  final VoidCallback onLongPressEnter;
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
        leading: _IconCircle(
          category: category,
          reorderMode: reorderMode,
        ),
        title: Text(category.name,
            style: Theme.of(context).textTheme.titleSmall),
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
            : () => context.push('/categories/${category.id}/edit'),
        onLongPress: reorderMode ? null : onLongPressEnter,
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
      // In reorder mode, parent rows still get a collapse chevron so
      // users can shrink the tree before dragging. The drag handle stays
      // as the visual cue that the row itself is grabbable.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasChildren)
            IconButton(
              icon: AnimatedRotation(
                turns: isCollapsed ? 0 : 0.25,
                duration: const Duration(milliseconds: 160),
                child: const Icon(Icons.chevron_right),
              ),
              onPressed: onToggleCollapse,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                  minWidth: 36, minHeight: 36),
              visualDensity: VisualDensity.compact,
            ),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.drag_handle),
          ),
        ],
      );
    }
    if (hasChildren) {
      return IconButton(
        icon: AnimatedRotation(
          turns: isCollapsed ? 0 : 0.25,
          duration: const Duration(milliseconds: 160),
          child: const Icon(Icons.chevron_right),
        ),
        onPressed: onToggleCollapse,
      );
    }
    return const Icon(Icons.chevron_right);
  }
}

// ────────────────────────────────────────────────────────────────────
// Icon — applies tilt + corner mark in reorder mode
// ────────────────────────────────────────────────────────────────────

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.category,
    required this.reorderMode,
  });

  final Category category;
  final bool reorderMode;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: category.color.color,
        shape: BoxShape.circle,
      ),
      child: Icon(category.icon.icon, color: Colors.white, size: 20),
    );
    if (!reorderMode) return circle;
    // Reorder mode visual cue is shared across reorderable surfaces.
    return ReorderModeTilt(child: circle);
  }
}

// ────────────────────────────────────────────────────────────────────
// Top-of-section drop zone — drops here always land at L1 as the first
// row of the section. Replaces the old end-of-section zone now that
// reorder follows the outliner model (anchor = row above, top of
// section means anchor = null).
// ────────────────────────────────────────────────────────────────────

class _TopZone extends StatelessWidget {
  const _TopZone({
    required this.type,
    required this.hover,
    required this.onPointerOverTop,
    required this.onAccept,
  });

  final CategoryType type;
  final ValueNotifier<_HoverState> hover;
  final void Function({
    required CategoryType type,
    required Offset globalOffset,
  }) onPointerOverTop;
  final void Function(Category) onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Category>(
      onMove: (details) =>
          onPointerOverTop(type: type, globalOffset: details.offset),
      onLeave: (_) {
        if (hover.value.isEnd && hover.value.endType == type) {
          hover.value = _HoverState.empty;
        }
      },
      onWillAcceptWithDetails: (d) => d.data.type == type,
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, candidate, rejected) {
        return ValueListenableBuilder<_HoverState>(
          valueListenable: hover,
          builder: (context, state, _) {
            final hovered = state.isEnd && state.endType == type;
            final scheme = Theme.of(context).colorScheme;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: hovered ? 56 : 24,
              margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: hovered
                    ? scheme.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: hovered
                    ? Border.all(color: scheme.primary, width: 1)
                    : null,
              ),
            );
          },
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
      borderRadius: BorderRadius.circular(12),
      color: scheme.surfaceContainerHigh,
      child: SizedBox(
        width: 280,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: category.color.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon.icon,
                    color: Colors.white, size: 20),
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
              const Icon(Icons.drag_handle),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Section header
// ────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
