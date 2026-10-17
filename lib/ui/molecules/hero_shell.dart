import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';

abstract final class HeroSpacing {
  static const double padding = AppSpacing.lg;

  static const EdgeInsets tight = EdgeInsets.all(AppSpacing.md);

  static const double rowGap = AppSpacing.md;

  static const double itemGap = AppSpacing.sm;

  static const double controlHeight = ChipHeight.control;

  static const double after = AppSpacing.lg;
}

class HeroContent extends StatelessWidget {
  const HeroContent({
    required this.rows,
    this.padding = const EdgeInsets.all(HeroSpacing.padding),
    this.rowGap = HeroSpacing.rowGap,
    super.key,
  });

  final List<Widget?> rows;
  final EdgeInsetsGeometry padding;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    final shown = rows.whereType<Widget>().toList();
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, r) in shown.indexed) ...[
            if (i > 0)
              SizedBox(
                height:
                    (r is HeroRow ? r.gapBefore : null) ??
                    (shown[i - 1] is HeroRow
                        ? (shown[i - 1] as HeroRow).gapAfter
                        : null) ??
                    rowGap,
              ),
            r,
          ],
        ],
      ),
    );
  }
}

class HeroRow extends StatelessWidget {
  const HeroRow({
    required this.child,
    this.gapBefore,
    this.gapAfter,
    super.key,
  });

  final Widget child;
  final double? gapBefore;
  final double? gapAfter;

  @override
  Widget build(BuildContext context) => child;
}

class HeroTopRow extends StatelessWidget {
  const HeroTopRow({
    this.leading = const [],
    this.trailing = const [],
    super.key,
  });

  final List<Widget> leading;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: HeroSpacing.controlHeight),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: HeroSpacing.itemGap,
              runSpacing: HeroSpacing.itemGap,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: leading,
            ),
          ),
          for (final t in trailing) ...[
            const SizedBox(width: HeroSpacing.itemGap),
            t,
          ],
        ],
      ),
    );
  }
}
