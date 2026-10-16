import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui.dart';

/// The presentational shell of the `+` quick create sheet (an organism): the
/// modal frame and nothing of the form's logic. The feature wrapper owns the
/// cubits / repos / saving paths and passes the form as [body]; this draws
///
///  * a drag handle + title row — drag either down to close (the shell drags
///    itself, so closing always goes through `maybePop` and the discard
///    question; the route's own drag must be off: `enableDrag: false`),
///  * the title row: [title], or — once the hero's amount has scrolled out of
///    view (the [heroKey] widget inside [body]) — whatever [summaryBuilder]
///    returns (cross-fades; the builder gets a "scroll back to top" callback),
///  * an optional delete button ([onDelete]) and the close ✕,
///  * the scrolling [body] (a ListView; the focused field is brought into
///    view, clear of the pinned bar, when the keyboard opens),
///  * the pinned bar: one button ([draftLabel] null) or "save as draft" +
///    "save" ([onSaveDraft] / [onSave]; a null callback = disabled),
///  * the saving overlay ([saving]).
///
/// Closing: back / ✕ / barrier / drag go through a `PopScope` — when [dirty]
/// (and not [saving]) the pop is blocked and [onCloseBlocked] runs instead
/// (the wrapper asks "keep / discard?" and pops itself). Hosted in a modal
/// bottom sheet (`isScrollControlled`, `useSafeArea`).
class QuickCreateSheetShell extends StatefulWidget {
  const QuickCreateSheetShell({
    required this.title,
    required this.body,
    required this.saveLabel,
    required this.closeTooltip,
    required this.onCloseBlocked,
    this.heroKey,
    this.summaryBuilder,
    this.draftLabel,
    this.deleteTooltip,
    this.saving = false,
    this.dirty = false,
    this.onSave,
    this.onSaveDraft,
    this.onDelete,
    super.key,
  });

  /// The plain title ("New transaction", "Edit draft", ...).
  final String title;

  /// The form — placed inside the scrolling list.
  final Widget body;

  /// Key of the hero card inside [body]; its bottom edge scrolling above the
  /// list's top is the "amount hidden" signal for [summaryBuilder].
  final GlobalKey? heroKey;

  /// The title-row summary (amount · category) shown instead of [title] while
  /// the hero is scrolled away; the callback scrolls the list back to the
  /// top. Null = the title never changes.
  final Widget Function(VoidCallback scrollToTop)? summaryBuilder;

  /// The (primary) save button's label.
  final String saveLabel;

  /// The "save as draft" button's label; null = a single save button only.
  final String? draftLabel;

  /// Tooltip of the delete button (shown only with [onDelete]).
  final String? deleteTooltip;
  final String closeTooltip;

  /// A save / delete is in flight: dims the sheet, blocks input, the save
  /// button spins, closing is allowed through without the question.
  final bool saving;

  /// Closing is worth asking about.
  final bool dirty;

  /// Null = the button is disabled.
  final VoidCallback? onSave;
  final VoidCallback? onSaveDraft;

  /// Non-null = a delete button beside ✕ (off while [saving]).
  final VoidCallback? onDelete;

  /// A close was attempted while [dirty]: ask the discard question.
  final VoidCallback onCloseBlocked;

  @override
  State<QuickCreateSheetShell> createState() => _QuickCreateSheetShellState();
}

class _QuickCreateSheetShellState extends State<QuickCreateSheetShell> {
  final _scroll = ScrollController();
  final _listKey = GlobalKey();

  /// How far the sheet is dragged down by its handle / title row.
  double _drag = 0;
  bool _dragging = false;

  /// The hero's amount is scrolled out of view.
  bool _collapsed = false;

  /// The keyboard height last build — growing means it just opened.
  double _lastInsets = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final c = _amountHidden();
      if (c != _collapsed) setState(() => _collapsed = c);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The hero's amount has scrolled up past the list's top edge. The
  /// amount ends the card's content (inline layout), so its bottom minus
  /// the card's padding is the line to watch.
  bool _amountHidden() {
    if (widget.summaryBuilder == null) return false;
    final hero = widget.heroKey?.currentContext?.findRenderObject();
    final list = _listKey.currentContext?.findRenderObject();
    if (hero is! RenderBox || list is! RenderBox) return false;
    if (!hero.attached || !list.attached) return false;
    final amountBottom = hero
        .localToGlobal(Offset(0, hero.size.height - PpForgeSpacing.md))
        .dy;
    return amountBottom < list.localToGlobal(Offset.zero).dy;
  }

  void _scrollToTop() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Scrolls the focused field into the list's view with room under it
  /// (a split row's amount sat half under the buttons on device).
  Future<void> _revealFocus() async {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (!mounted || focused == null || !_scroll.hasClients) return;
    // Only fields inside this list.
    if (Scrollable.maybeOf(focused)?.position != _scroll.position) return;
    final animate = !MediaQuery.disableAnimationsOf(context);
    await Scrollable.ensureVisible(
      focused,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      duration: animate ? const Duration(milliseconds: 180) : Duration.zero,
    );
    if (!mounted || !_scroll.hasClients || !focused.mounted) return;
    // A little more when it ended up at the very bottom, so the whole row
    // (and what's under it) shows.
    final field = focused.findRenderObject();
    final viewport = Scrollable.maybeOf(focused)?.context.findRenderObject();
    if (field is! RenderBox || viewport is! RenderBox) return;
    final gap =
        viewport.localToGlobal(Offset(0, viewport.size.height)).dy -
        field.localToGlobal(Offset(0, field.size.height)).dy;
    const room = 56.0;
    if (gap >= room) return;
    final p = _scroll.position;
    final to = (p.pixels + room - gap).clamp(
      p.minScrollExtent,
      p.maxScrollExtent,
    );
    if (to == p.pixels) return;
    if (animate) {
      await _scroll.animateTo(
        to,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(to);
    }
  }

  // The route's own drag would pop straight past PopScope (losing what
  // was typed), so the sheet drags itself and closes through maybePop —
  // the same unsaved-changes question as ✕ and back.

  void _onDragUpdate(DragUpdateDetails d) => setState(() {
    _dragging = true;
    _drag = math.max(0, _drag + d.delta.dy);
  });

  void _onDragEnd(DragEndDetails d) {
    final close = _drag > 120 || (d.primaryVelocity ?? 0) > 700;
    setState(() {
      _dragging = false;
      // Staying (or about to ask) → spring back; leaving → exit from here.
      if (!close || (widget.dirty && !widget.saving)) _drag = 0;
    });
    if (close) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    // The keyboard came up (or grew): bring the focused field back into
    // view, clear of it and of the pinned buttons.
    if (insets > _lastInsets) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealFocus());
    }
    _lastInsets = insets;
    final summary = widget.summaryBuilder;

    return PopScope(
      canPop: !widget.dirty || widget.saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onCloseBlocked();
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _drag),
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, dy, sheet) =>
            Transform.translate(offset: Offset(0, dy), child: sheet),
        // A save / delete in flight dims the sheet and blocks input.
        child: SavingOverlay(
          saving: widget.saving,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.94,
            child: Padding(
              padding: EdgeInsets.only(bottom: insets),
              child: Column(
                children: [
                  // Handle + title row: drag down to close.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: PpForgeSpacing.sm,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: ColoredBox(
                              color: scheme.outlineVariant,
                              child: const SizedBox(width: 36, height: 4),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            PpForgeSpacing.lg,
                            PpForgeSpacing.xs,
                            PpForgeSpacing.xs,
                            0,
                          ),
                          child: Row(
                            children: [
                              // The title — or, once the hero's amount has
                              // scrolled away, the summary (tap: back to the
                              // top). Cross-fades in place.
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 200),
                                  layoutBuilder: (current, previous) => Stack(
                                    alignment: AlignmentDirectional.centerStart,
                                    children: [...previous, ?current],
                                  ),
                                  child: _collapsed && summary != null
                                      ? KeyedSubtree(
                                          key: const ValueKey('summary'),
                                          child: summary(_scrollToTop),
                                        )
                                      : Text(
                                          key: const ValueKey('title'),
                                          widget.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                ),
                              ),
                              if (widget.onDelete != null)
                                PpForgeIconButton.flat(
                                  icon: PpForgeIcons.delete,
                                  tooltip: widget.deleteTooltip,
                                  color: scheme.error,
                                  // Offline: the delete can't reach the
                                  // server.
                                  onPressed:
                                      widget.saving ||
                                          ConnectionScope.isOffline(context)
                                      ? null
                                      : widget.onDelete,
                                ),
                              PpForgeIconButton.close(
                                tooltip: widget.closeTooltip,
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      key: _listKey,
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                        PpForgeSpacing.lg,
                        PpForgeSpacing.xs,
                        PpForgeSpacing.lg,
                        PpForgeSpacing.xxl,
                      ),
                      children: [widget.body],
                    ),
                  ),
                  // Pinned above the keyboard. Pinned bars clear the gesture
                  // bar themselves — the sheet's useSafeArea only covers the
                  // top.
                  if (widget.draftLabel == null)
                    PinnedBar(
                      child: PpForgeButton(
                        label: widget.saveLabel,
                        expand: true,
                        loading: widget.saving,
                        submits: true,
                        onPressed: widget.onSave,
                      ),
                    )
                  else
                    PinnedBar(
                      child: Row(
                        children: [
                          Expanded(
                            child: PpForgeButton(
                              label: widget.draftLabel!,
                              variant: PpForgeButtonVariant.outlined,
                              expand: true,
                              submits: true,
                              onPressed: widget.onSaveDraft,
                            ),
                          ),
                          const SizedBox(width: PpForgeSpacing.sm),
                          Expanded(
                            flex: 3,
                            child: PpForgeButton(
                              label: widget.saveLabel,
                              expand: true,
                              loading: widget.saving,
                              submits: true,
                              onPressed: widget.onSave,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
