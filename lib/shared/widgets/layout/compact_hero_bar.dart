import 'package:flutter/material.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_spacing.dart';

/// A detail page's hero in one row (owner 2026-10-11), pinned right under
/// the floating top bar once the hero has scrolled away:
///
/// ```
/// [ ← │ หมวดหมู่ › อาหาร ]                   [⏳][🔔][👤]
/// ┌──────────────────────────────────────────────────┐
/// │ [leading]  title (one line, ellipsis)  [trailing]│
/// └──────────────────────────────────────────────────┘
/// ```
///
/// Slots: [leading] (an icon / a small chip), [title] (one line, the first
/// thing to give way), [trailing] (an amount / a small chip). Detail pages
/// only — never quick create. Let [CompactHeroScope] place it and decide
/// when it shows.
///
/// Comes and goes with a short slide + fade (none with animations off);
/// while hidden it ignores taps.
class CompactHeroBar extends StatelessWidget {
  const CompactHeroBar({
    required this.title,
    this.leading,
    this.trailing,
    this.visible = true,
    this.onTap,
    super.key,
  });

  final Widget? leading;

  /// Styled as titleSmall bold, one line, ellipsis, by default.
  final Widget title;
  final Widget? trailing;
  final bool visible;

  /// e.g. scroll back to the hero.
  final VoidCallback? onTap;

  /// The bar's height (text scaling can grow it).
  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDurations.chrome;
    final bar = Material(
      color: scheme.surfaceContainerHigh,
      elevation: 1.5,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(height / 2),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: height),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: title,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -0.5),
        duration: duration,
        curve: AppDurations.chromeCurve,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: duration,
          curve: AppDurations.chromeCurve,
          child: bar,
        ),
      ),
    );
  }
}

/// Puts a [CompactHeroBar] over a detail page's scrolling body, right under
/// the floating top bar, and shows it while the hero (the widget carrying
/// [heroKey]) is scrolled away under that line — hidden again once any of
/// the hero is back below it.
///
/// ```dart
/// body: CompactHeroScope(
///   heroKey: _heroKey,
///   bar: CompactHeroBar(leading: …, title: Text(name), trailing: …),
///   child: ListView(children: [HeaderCard(key: _heroKey, …), …]),
/// ),
/// ```
///
/// It listens to the [child]'s own scroll (depth 0); a hero that's been
/// built away (a lazy list scrolled far) counts as away.
class CompactHeroScope extends StatefulWidget {
  const CompactHeroScope({
    required this.heroKey,
    required this.bar,
    required this.child,
    this.top,
    super.key,
  });

  final GlobalKey heroKey;

  /// Its [CompactHeroBar.visible] is set here.
  final CompactHeroBar bar;

  /// The page's scrollable.
  final Widget child;

  /// Where the bar sits, from this widget's top. Null = under the floating
  /// top bar (`MediaQuery.paddingOf(context).top`, as on a page with
  /// `extendBodyBehindAppBar`).
  final double? top;

  @override
  State<CompactHeroScope> createState() => _CompactHeroScopeState();
}

class _CompactHeroScopeState extends State<CompactHeroScope> {
  bool _away = false;

  /// The latest scroll offset, while a check waits for the frame's end.
  double? _pending;

  double get _line => widget.top ?? MediaQuery.paddingOf(context).top;

  bool _onScroll(Notification n) {
    final double pixels;
    if (n is ScrollNotification && n.depth == 0) {
      pixels = n.metrics.pixels;
    } else if (n is ScrollMetricsNotification && n.depth == 0) {
      pixels = n.metrics.pixels;
    } else {
      return false;
    }
    // Measured after the frame: metrics notifications come mid-layout,
    // when a lazy list may be dropping the hero.
    final waiting = _pending != null;
    _pending = pixels;
    if (!waiting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final p = _pending;
        _pending = null;
        if (mounted && p != null) _check(p);
      });
    }
    return false;
  }

  void _check(double pixels) {
    final me = context.findRenderObject() as RenderBox?;
    if (me == null || !me.attached) return;
    final hero =
        widget.heroKey.currentContext?.findRenderObject() as RenderBox?;
    // Built away (a lazy list scrolled far) = away.
    final away = hero == null || !hero.attached
        ? pixels > 0
        : hero.localToGlobal(Offset(0, hero.size.height), ancestor: me).dy <=
              _line;
    if (away != _away) setState(() => _away = away);
  }

  @override
  Widget build(BuildContext context) {
    final bar = widget.bar;
    return Stack(
      children: [
        NotificationListener<Notification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
        Positioned(
          top: _line + AppSpacing.xs,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: CompactHeroBar(
            key: bar.key,
            leading: bar.leading,
            title: bar.title,
            trailing: bar.trailing,
            onTap: bar.onTap,
            visible: _away,
          ),
        ),
      ],
    );
  }
}
