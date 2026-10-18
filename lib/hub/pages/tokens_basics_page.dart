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
                        '$name · ${v.toInt()}',
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
        title: 'AppDurations',
        note:
            'Motion lengths. Every animation also respects the device’s '
            '“reduce motion” setting (zero duration).',
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: AppText(
                '${widget.name} · ${widget.duration.inMilliseconds} ms',
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
            'mini 20 · dense list rows. chip 28 · display chips in cards, '
            'rows and detail sections. control 36 · anything the user '
            'operates, and every chip in a hero’s top row. One control height (36, from ControlSizes in the theme) across the app: control chips, ✏️ / top-bar buttons, the search capsule, top-bar pills, hero controls, dense inputs.',
        child: HubRow(
          cells: [
            for (final s in ChipSize.values)
              HubCell(
                caption: '${s.name} · ${s.heightOf(context).toInt()}',
                child: AppChip(label: 'Label', icon: AppIcons.tag, size: s),
              ),
          ],
        ),
      ),
      HubDemo(
        title: 'AppIconSize',
        note: 'xs 12 · sm 16 · md 20 · lg 24 · xl 32 · hero 56.',
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
                caption: '$name · ${v.toInt()}',
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
