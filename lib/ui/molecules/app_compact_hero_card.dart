import '../tokens/hero_metrics.dart';
import 'package:flutter/material.dart';

import '../tokens/app_durations.dart';
import '../tokens/app_spacing.dart';
import 'hero_style.dart';

class AppCompactHeroCard extends StatelessWidget {
  const AppCompactHeroCard({
    required this.title,
    this.leading,
    this.trailing,
    this.visible = true,
    this.onTap,
    this.style = const HeroStyle.plain(),
    super.key,
  });

  final HeroStyle style;

  final Widget? leading;

  final Widget title;
  final Widget? trailing;
  final bool visible;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final height = HeroMetrics.of(context).compactHeight;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDurations.chrome;
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
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
    );
    final radius = BorderRadius.circular(height / 2);
    final bar = Material(
      color: scheme.surface,
      elevation: 1.5,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: HeroSurface(
        style: style,
        radius: radius,
        glyphSize: 56,
        onTap: onTap,
        child: content,
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

class CompactHeroScope extends StatefulWidget {
  const CompactHeroScope({
    required this.heroKey,
    required this.bar,
    required this.child,
    this.top,
    super.key,
  });

  final GlobalKey heroKey;

  final AppCompactHeroCard bar;

  final Widget child;

  final double? top;

  @override
  State<CompactHeroScope> createState() => _CompactHeroScopeState();
}

class _CompactHeroScopeState extends State<CompactHeroScope> {
  bool _away = false;

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
          child: AppCompactHeroCard(
            key: bar.key,
            style: bar.style,
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
