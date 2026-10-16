import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/tokens/spacing` — the spacing steps, as bars and in context.
Widget buildSpacingPage(BuildContext context) {
  const steps = <(String, double)>[
    ('xxs', PpForgeSpacing.xxs),
    ('xs', PpForgeSpacing.xs),
    ('sm', PpForgeSpacing.sm),
    ('md', PpForgeSpacing.md),
    ('lg', PpForgeSpacing.lg),
    ('xl', PpForgeSpacing.xl),
    ('xxl', PpForgeSpacing.xxl),
    ('xxxl', PpForgeSpacing.xxxl),
    ('huge', PpForgeSpacing.huge),
  ];
  final scheme = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubDemo(
        title: 'PpForgeSpacing',
        note:
            'The only gaps and paddings. No hand-sized numbers in features: '
            'a gap is a step name.',
        child: Column(
          children: [
            for (final (name, v) in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: PpForgeSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: PpForgeText(
                        '$name · ${v.toInt()}',
                        role: PpForgeTextRole.caption,
                      ),
                    ),
                    Container(
                      width: v * 4,
                      height: 12,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(PpForgeRadius.xs),
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
        child: PpForgeCard(
          child: Padding(
            padding: const EdgeInsets.all(PpForgeSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PpForgeText('lg padding', role: PpForgeTextRole.title),
                const SizedBox(height: PpForgeSpacing.md),
                const PpForgeText(
                  'md between rows',
                  role: PpForgeTextRole.body,
                ),
                const SizedBox(height: PpForgeSpacing.sm),
                Row(
                  children: const [
                    PpForgeChip(label: 'sm'),
                    SizedBox(width: PpForgeSpacing.sm),
                    PpForgeChip(label: 'between controls'),
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
    ('xs', PpForgeRadius.xs),
    ('sm', PpForgeRadius.sm),
    ('md', PpForgeRadius.md),
    ('lg', PpForgeRadius.lg),
    ('xl', PpForgeRadius.xl),
    ('xxl', PpForgeRadius.xxl),
    ('pill', PpForgeRadius.pill),
  ];
  final scheme = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubDemo(
        title: 'PpForgeRadius',
        child: HubRow(
          cells: [
            for (final (name, r) in radii)
              HubCell(
                caption: '$name · ${r.toInt()}',
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
        title: 'PpForgeDurations',
        note:
            'Motion lengths. Every animation also respects the device’s '
            '“reduce motion” setting (zero duration).',
        child: Column(
          children: [
            for (final (name, d) in <(String, Duration)>[
              ('instant', PpForgeDurations.instant),
              ('fast', PpForgeDurations.fast),
              ('normal', PpForgeDurations.normal),
              ('slow', PpForgeDurations.slow),
              ('chrome', PpForgeDurations.chrome),
            ])
              _DurationBar(name: name, duration: d),
          ],
        ),
      ),
    ],
  );
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
        padding: const EdgeInsets.symmetric(vertical: PpForgeSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: PpForgeText(
                '${widget.name} · ${widget.duration.inMilliseconds} ms',
                role: PpForgeTextRole.caption,
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 20,
                child: AnimatedAlign(
                  duration: reduce ? Duration.zero : widget.duration,
                  curve: PpForgeDurations.chromeCurve,
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
            'mini 20 · dense list rows. chip 28 · display chips in cards, '
            'rows and detail sections. control 40 · anything the user '
            'operates, and every chip in a hero’s top row. One control height (40) across the app: control chips, ✏️ / top-bar buttons, the search capsule, top-bar pills, hero controls, dense inputs.',
        child: HubRow(
          cells: [
            for (final s in ChipSize.values)
              HubCell(
                caption: '${s.name} · ${s.height.toInt()}',
                child: PpForgeChip(
                  label: 'Label',
                  icon: PpForgeIcons.tag,
                  size: s,
                ),
              ),
          ],
        ),
      ),
      HubDemo(
        title: 'PpForgeIconSize',
        note: 'xs 12 · sm 16 · md 20 · lg 24 · xl 32 · hero 56.',
        child: HubRow(
          cells: [
            for (final (name, v) in <(String, double)>[
              ('xs', PpForgeIconSize.xs),
              ('sm', PpForgeIconSize.sm),
              ('md', PpForgeIconSize.md),
              ('lg', PpForgeIconSize.lg),
              ('xl', PpForgeIconSize.xl),
              ('hero', PpForgeIconSize.hero),
            ])
              HubCell(
                caption: '$name · ${v.toInt()}',
                child: PpForgeIcon(
                  PpForgeIcons.wallet,
                  size: v,
                  color: scheme.primary,
                ),
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
            borderRadius: BorderRadius.circular(PpForgeRadius.sm),
          ),
          alignment: Alignment.center,
          child: PpForgeChip(
            label: 'Tap near me',
            size: ChipSize.chip,
            onTap: () => showPpForgeSnackBar(context, 'Tapped'),
          ),
        ),
      ),
    ],
  );
}
