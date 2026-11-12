import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/tokens/spacing` — the spacing steps, as bars and in context.
Widget buildSpacingPage(BuildContext context) {
  const steps = <(String, double)>[
    ('xxs', AppSpacing.xxs),
    ('xs', AppSpacing.xs),
    ('sm', AppSpacing.sm),
    ('md', AppSpacing.md),
    ('lg', AppSpacing.lg),
    ('xl', AppSpacing.xl),
    ('xxl', AppSpacing.xxl),
    ('xxxl', AppSpacing.xxxl),
    ('huge', AppSpacing.huge),
  ];
  final scheme = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubDemo(
        title: 'AppSpacing',
        note:
            'The only gaps and paddings. No hand-sized numbers in features: '
            'a gap is a step name.',
        child: Column(
          children: [
            for (final (name, v) in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: AppText(
                        '$name | ${v.toInt()}',
                        role: AppTextRole.caption,
                      ),
                    ),
                    Container(
                      width: v * 4,
                      height: 12,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      HubDemo(
        title: 'In context',
        note:
            'A detail page: 16 at the sides, 12 between rows, 8 between controls.',
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText('lg padding', role: AppTextRole.title),
                const SizedBox(height: AppSpacing.md),
                const AppText('md between rows', role: AppTextRole.body),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: const [
                    AppChip(label: 'sm'),
                    SizedBox(width: AppSpacing.sm),
                    AppChip(label: 'between controls'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

/// `/dev/tokens/radius-duration` — corner radii and motion durations.
Widget buildRadiusDurationPage(BuildContext context) {
  const radii = <(String, double)>[
    ('xs', AppRadius.xs),
    ('sm', AppRadius.sm),
    ('md', AppRadius.md),
    ('lg', AppRadius.lg),
    ('xl', AppRadius.xl),
    ('xxl', AppRadius.xxl),
    ('pill', AppRadius.pill),
  ];
  final scheme = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubDemo(
        title: 'AppRadius',
        child: HubRow(
          cells: [
            for (final (name, r) in radii)
              HubCell(
                caption: '$name | ${r.toInt()}',
                child: Container(
                  width: 64,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(r),
                    border: Border.all(color: scheme.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
      HubDemo(
        title: 'AppDurations',
        note:
            'Motion lengths. Every animation also respects the device’s '
            '“reduce motion” setting (zero duration). Arriving and leaving '
            'pages and sheets are NOT here: see AppMotion below.',
        child: Column(
          children: [
            for (final (name, d) in <(String, Duration)>[
              ('instant', AppDurations.instant),
              ('fast', AppDurations.fast),
              ('normal', AppDurations.normal),
              ('slow', AppDurations.slow),
              ('chrome', AppDurations.chrome),
            ])
              _DurationBar(name: name, duration: d),
          ],
        ),
      ),
      const HubDemo(
        title: 'AppMotion — arriving and leaving',
        note:
            'THE one motion of coming and going (owner 2026-11-12), used by '
            'everything: a push and a tab’s first page (AppMotion.enterShift '
            '/ enterOpacity), every back in a tab or across tabs '
            '(AppPageTransitionsBuilder.popDuration / popCurve, the TabBackSlide), '
            'bottom sheets (AppMotion.sheetStyle) and the side sheet. 150 ms, '
            'easeOutQuart; a page enters sliding in from the right, fading '
            'in, starting 80 % of the way to where it lands (slideFrom 0.2), '
            'and leaves sliding off to the right, the page under it held in '
            'place. A sheet closes through the flipped curve (fast first). '
            'Change AppMotion and all of it changes. Dialogs and popup menus '
            'keep Flutter’s own. Tap the buttons to play it.',
        child: _MotionDemo(),
      ),
    ],
  );
}

/// The live sample of [AppMotion]: a page stage that enters and leaves through
/// the real functions, and the two sheets.
class _MotionDemo extends StatefulWidget {
  const _MotionDemo();

  @override
  State<_MotionDemo> createState() => _MotionDemoState();
}

class _MotionDemoState extends State<_MotionDemo>
    with SingleTickerProviderStateMixin {
  // 0 = off the right edge... landed = 1 (the arrival's own t).
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppMotion.duration,
    value: 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _ctrl,
    curve: AppMotion.curve,
  );
  bool _leaving = false;

  @override
  void dispose() {
    _curve.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _enter() {
    setState(() => _leaving = false);
    _ctrl.forward(from: 0);
  }

  void _leave() {
    setState(() => _leaving = true);
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          'duration ${AppMotion.duration.inMilliseconds} ms | curve '
          'easeOutQuart | slideFrom ${AppMotion.slideFrom}',
          role: AppTextRole.caption,
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRect(
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: AnimatedBuilder(
              animation: _curve,
              builder: (context, child) {
                final t = _curve.value;
                // Entering: the shared shift and fade. Leaving: the page
                // goes off to the right by the same curve.
                final shift = _leaving ? t : AppMotion.enterShift(t);
                final opacity = _leaving ? 1.0 : AppMotion.enterOpacity(t);
                return Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: FractionalTranslation(
                    translation: Offset(shift, 0),
                    child: child,
                  ),
                );
              },
              child: Container(
                color: scheme.primaryContainer,
                alignment: Alignment.center,
                child: const AppText('a page', role: AppTextRole.body),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              label: 'Enter',
              variant: AppButtonVariant.outlined,
              onPressed: _enter,
            ),
            AppButton(
              label: 'Leave',
              variant: AppButtonVariant.outlined,
              onPressed: _leave,
            ),
            AppButton(
              label: 'Bottom sheet',
              variant: AppButtonVariant.outlined,
              onPressed: () => showAppSheet<void>(
                context,
                title: 'AppMotion.sheetStyle',
                builder: (_) => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AppText('In and out through AppMotion.'),
                ),
              ),
            ),
            AppButton(
              label: 'Side sheet',
              variant: AppButtonVariant.outlined,
              onPressed: () => showSideSheet<void>(
                context,
                builder: (_) => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AppText('In and out through AppMotion.'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DurationBar extends StatefulWidget {
  const _DurationBar({required this.name, required this.duration});

  final String name;
  final Duration duration;

  @override
  State<_DurationBar> createState() => _DurationBarState();
}

class _DurationBarState extends State<_DurationBar> {
  bool _right = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return InkWell(
      onTap: () => setState(() => _right = !_right),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: AppText(
                '${widget.name} | ${widget.duration.inMilliseconds} ms',
                role: AppTextRole.caption,
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 20,
                child: AnimatedAlign(
                  duration: reduce ? Duration.zero : widget.duration,
                  curve: AppDurations.chromeCurve,
                  alignment: _right
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `/dev/tokens/sizes` — chip sizes, control heights, icon sizes, tap target.
Widget buildSizesPage(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubDemo(
        title: 'ChipSize — the three chip sizes',
        note:
            'mini 20 | dense list rows. chip 28 | display chips in cards, '
            'rows and detail sections. control 36 | anything the user '
            'operates, and every chip in a hero’s top row. One control height (36, from ControlSizes in the theme) across the app: control chips, ✏️ / top-bar buttons, the search capsule, top-bar pills, hero controls, dense inputs.',
        child: HubRow(
          cells: [
            for (final s in ChipSize.values)
              HubCell(
                caption: '${s.name} | ${s.heightOf(context).toInt()}',
                child: AppChip(label: 'Label', icon: AppIcons.tag, size: s),
              ),
          ],
        ),
      ),
      HubDemo(
        title: 'AppIconSize',
        note: 'xs 12 | sm 16 | md 20 | lg 24 | xl 32 | hero 56.',
        child: HubRow(
          cells: [
            for (final (name, v) in <(String, double)>[
              ('xs', AppIconSize.xs),
              ('sm', AppIconSize.sm),
              ('md', AppIconSize.md),
              ('lg', AppIconSize.lg),
              ('xl', AppIconSize.xl),
              ('hero', AppIconSize.hero),
            ])
              HubCell(
                caption: '$name | ${v.toInt()}',
                child: AppIcon(AppIcons.wallet, size: v, color: scheme.primary),
              ),
          ],
        ),
      ),
      HubDemo(
        title: 'Tap target',
        note:
            'A short interactive chip answers taps in a 44-high band (the '
            'layout is unchanged). The dashed band shows the target.',
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: AppChip(
            label: 'Tap near me',
            size: ChipSize.chip,
            onTap: () => showAppSnackBar(context, 'Tapped'),
          ),
        ),
      ),
    ],
  );
}
