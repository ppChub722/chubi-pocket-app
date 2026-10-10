import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

/// The one set of spacing rules for every hero / header card (owner
/// 2026-10-10) — the transaction hero, the wallet hero, [HeaderCard] on
/// the detail pages:
///
/// ```
/// ┌──────────────────────────────── 16 ─┐
/// │ [pill]·8·[pill]          [date]·8·✏️│  ← one row, controls 32 high
/// │                12                   │
/// │ title / amount row                  │
/// │                12                   │
/// │ [nested card 12 inside]·8·[card]    │
/// └─────────────────────────────────────┘
///                  16                     ← to the next block
/// ```
///
/// [HeroContent] lays the rows; [HeroTopRow] lays a row of controls.
abstract final class HeroSpacing {
  /// Inside the card, all sides.
  static const double padding = AppSpacing.lg;

  /// Between rows inside the card.
  static const double rowGap = AppSpacing.md;

  /// Between buttons / pills / chips in a row.
  static const double itemGap = AppSpacing.sm;

  /// Every control in the card's top row is this tall (date chip, ✏️,
  /// type / shared pills — `PillSize.control`).
  static const double controlHeight = 32;

  /// Inside a card nested in the hero (category / wallet [PickCard]s).
  static const double nestedPadding = AppSpacing.md;

  /// Between nested cards side by side.
  static const double nestedGap = AppSpacing.sm;

  /// From the card to the next block on the page.
  static const double after = AppSpacing.lg;
}

/// A hero card's inside: [HeroSpacing.padding] all round, [rows] stacked
/// with [HeroSpacing.rowGap] between them (null rows skipped).
class HeroContent extends StatelessWidget {
  const HeroContent({required this.rows, super.key});

  final List<Widget?> rows;

  @override
  Widget build(BuildContext context) {
    final shown = rows.whereType<Widget>().toList();
    return Padding(
      padding: const EdgeInsets.all(HeroSpacing.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, r) in shown.indexed) ...[
            if (i > 0) const SizedBox(height: HeroSpacing.rowGap),
            r,
          ],
        ],
      ),
    );
  }
}

/// A hero's row of controls: [leading] from the left (wrapping), [trailing]
/// on the right — [HeroSpacing.itemGap] between every item, the row at
/// least [HeroSpacing.controlHeight] tall so it doesn't jump when a control
/// comes or goes (✏️ in view mode only).
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
