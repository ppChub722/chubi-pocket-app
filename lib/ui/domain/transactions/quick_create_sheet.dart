import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui.dart';

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
    this.deleteLabel,
    this.saving = false,
    this.dirty = false,
    this.onSave,
    this.onSaveDraft,
    this.onDelete,
    this.subtitle,
    this.headerBar,
    this.tint,
    this.barActionLabel,
    this.onBarAction,
    this.barActionIcon,
    this.draftIcon,
    this.saveIcon,
    super.key,
  });

  /// A plain extra action at the bottom left (ข้าม / ยกเลิกจ่ายแล้ว).
  final String? barActionLabel;
  final VoidCallback? onBarAction;

  /// Icons on the bottom buttons (null = text only).
  final IconData? barActionIcon;
  final IconData? draftIcon;
  final IconData? saveIcon;

  final String title;

  /// The modal route's own background: clear, because the shell paints the
  /// sheet (so its colour can follow the mode).
  static const Color modalBackground = Colors.transparent;

  /// The create mode's colour: the whole sheet takes a wash of it, so what is
  /// being made reads at a glance. Null = the plain sheet.
  final Color? tint;

  /// Muted, under the title ("แก้เฉพาะงวดนี้").
  final String? subtitle;

  /// Fixed between the header and the scrolling body: the sheet's own extra
  /// actions (ข้าม / จ่ายแล้ว / ผูกกับรายการที่มีอยู่).
  final Widget? headerBar;

  final Widget body;

  final GlobalKey? heroKey;

  /// The title-row summary (amount · category) shown instead of [title] while
  /// the hero is scrolled away; the callback scrolls the list back to the top.
  final Widget Function(VoidCallback scrollToTop)? summaryBuilder;

  final String saveLabel;

  final String? draftLabel;

  final String? deleteTooltip;

  /// Set: the delete is a button at the bottom left, not the title-row icon.
  final String? deleteLabel;
  final String closeTooltip;

  /// A save / delete is in flight: dims the sheet, blocks input, the save
  /// button spins, closing is allowed through without the question.
  final bool saving;

  final bool dirty;

  final VoidCallback? onSave;
  final VoidCallback? onSaveDraft;

  final VoidCallback? onDelete;

  final VoidCallback onCloseBlocked;

  @override
  State<QuickCreateSheetShell> createState() => _QuickCreateSheetShellState();
}

class _QuickCreateSheetShellState extends State<QuickCreateSheetShell> {
  final _scroll = ScrollController();
  final _listKey = GlobalKey();

  double _drag = 0;
  bool _dragging = false;

  bool _collapsed = false;

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

  bool _amountHidden() {
    if (widget.summaryBuilder == null) return false;
    final hero = widget.heroKey?.currentContext?.findRenderObject();
    final list = _listKey.currentContext?.findRenderObject();
    if (hero is! RenderBox || list is! RenderBox) return false;
    if (!hero.attached || !list.attached) return false;
    final amountBottom = hero
        .localToGlobal(Offset(0, hero.size.height - AppSpacing.md))
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

  Future<void> _revealFocus() async {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (!mounted || focused == null || !_scroll.hasClients) return;
    if (Scrollable.maybeOf(focused)?.position != _scroll.position) return;
    final animate = !MediaQuery.disableAnimationsOf(context);
    await Scrollable.ensureVisible(
      focused,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      duration: animate ? const Duration(milliseconds: 180) : Duration.zero,
    );
    if (!mounted || !_scroll.hasClients || !focused.mounted) return;
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

  void _onDragUpdate(DragUpdateDetails d) => setState(() {
    _dragging = true;
    _drag = math.max(0, _drag + d.delta.dy);
  });

  void _onDragEnd(DragEndDetails d) {
    final close = _drag > 120 || (d.primaryVelocity ?? 0) > 700;
    setState(() {
      _dragging = false;
      if (!close || (widget.dirty && !widget.saving)) _drag = 0;
    });
    if (close) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base =
        Theme.of(context).bottomSheetTheme.backgroundColor ??
        scheme.surfaceContainerLow;
    final tint = widget.tint;
    final sheetColor = tint == null
        ? base
        : Color.alphaBlend(
            tint.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.12,
            ),
            base,
          );
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    if (insets > _lastInsets) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealFocus());
    }
    _lastInsets = insets;
    final summary = widget.summaryBuilder;
    // Offline: the delete can't reach the server.
    final onDelete = widget.saving || ConnectionScope.isOffline(context)
        ? null
        : widget.onDelete;
    final deleteButton = widget.onDelete == null || widget.deleteLabel == null
        ? null
        : AppButton(
            label: widget.deleteLabel!,
            icon: AppIcons.delete,
            variant: AppButtonVariant.destructiveOutlined,
            onPressed: onDelete,
          );

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
        child: Material(
          color: sheetColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          animationDuration: const Duration(milliseconds: 250),
          child: SavingOverlay(
            saving: widget.saving,
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.94,
              child: Padding(
                padding: EdgeInsets.only(bottom: insets),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: _onDragUpdate,
                      onVerticalDragEnd: _onDragEnd,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
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
                              AppSpacing.lg,
                              AppSpacing.xs,
                              AppSpacing.xs,
                              0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 200),
                                    layoutBuilder: (current, previous) => Stack(
                                      alignment:
                                          AlignmentDirectional.centerStart,
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
                                if (widget.onDelete != null &&
                                    deleteButton == null)
                                  AppIconButton.flat(
                                    icon: AppIcons.delete,
                                    tooltip: widget.deleteTooltip,
                                    color: scheme.error,
                                    onPressed: onDelete,
                                  ),
                                AppIconButton.close(
                                  tooltip: widget.closeTooltip,
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                ),
                              ],
                            ),
                          ),
                          if (widget.subtitle != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  widget.subtitle!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.headerBar != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          0,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: widget.headerBar,
                        ),
                      ),
                    Expanded(
                      child: ListView(
                        key: _listKey,
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xs,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        children: [widget.body],
                      ),
                    ),
                    if (widget.draftLabel == null &&
                        deleteButton == null &&
                        widget.barActionLabel == null)
                      PinnedBar(
                        child: AppButton(
                          label: widget.saveLabel,
                          icon: widget.saveIcon,
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
                            if (deleteButton != null) ...[
                              deleteButton,
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            if (widget.barActionLabel != null) ...[
                              AppButton(
                                label: widget.barActionLabel!,
                                icon: widget.barActionIcon,
                                variant: AppButtonVariant.outlined,
                                onPressed: widget.saving
                                    ? null
                                    : widget.onBarAction,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            if (widget.draftLabel != null) ...[
                              AppButton(
                                label: widget.draftLabel!,
                                icon: widget.draftIcon,
                                variant: AppButtonVariant.outlined,
                                submits: true,
                                onPressed: widget.onSaveDraft,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Expanded(
                              child: AppButton(
                                label: widget.saveLabel,
                                icon: widget.saveIcon,
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
      ),
    );
  }
}
