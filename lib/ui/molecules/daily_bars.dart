import 'package:flutter/material.dart';

import '../tokens/app/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/hero_colors.dart';

enum DailyBarKind { past, today, future }

@immutable
class DailyBar {
  const DailyBar({
    required this.value,
    this.kind = DailyBarKind.past,
    this.semanticLabel,
  });

  final double value;
  final DailyBarKind kind;
  final String? semanticLabel;
}

class DailyBars extends StatelessWidget {
  const DailyBars({
    required this.bars,
    this.startLabel,
    this.centerLabel,
    this.endLabel,
    this.onTap,
    this.height = 34,
    super.key,
  });

  final List<DailyBar> bars;
  final String? startLabel;
  final String? centerLabel;
  final String? endLabel;
  final ValueChanged<int>? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final text = Theme.of(context).textTheme;
    final max = bars.fold<double>(0, (m, b) => b.value > m ? b.value : m);
    // Inside a hero the bars take the card's color; alone, the expense red.
    final hero = HeroColors.maybeOf(context);
    final fill = hero?.accent ?? palette.expense;
    final caption = text.bodySmall?.copyWith(
      color: hero?.muted ?? scheme.onSurfaceVariant,
    );
    Color colorOf(DailyBarKind k) => switch (k) {
      DailyBarKind.past => fill.withValues(alpha: 0.35),
      DailyBarKind.today => fill,
      DailyBarKind.future => hero?.track ?? scheme.surfaceContainerHighest,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, b) in bars.indexed)
                Expanded(
                  child: Semantics(
                    label: b.semanticLabel,
                    button: onTap != null,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTap == null ? null : () => onTap!(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: b.kind == DailyBarKind.future
                                ? 0.12
                                : (max <= 0
                                      ? 0.08
                                      : (b.value / max).clamp(0.08, 1.0)),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colorOf(b.kind),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.xs),
                                ),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (startLabel != null || centerLabel != null || endLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    startLabel ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: caption,
                  ),
                ),
                if (centerLabel != null)
                  Flexible(
                    flex: 2,
                    child: Text(
                      centerLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: caption,
                    ),
                  ),
                Expanded(
                  child: Text(
                    endLabel ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: caption,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
