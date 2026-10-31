import 'package:flutter/material.dart';

import '../../tokens/app/app_icons.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../atoms/busy_scope.dart';

class FlowCards extends StatelessWidget {
  const FlowCards({
    required this.from,
    this.to,
    this.onSwap,
    this.swapTooltip,
    this.caption,
    super.key,
  });

  final Widget from;
  final Widget? to;
  final VoidCallback? onSwap;
  final String? swapTooltip;

  /// One centred line under the cards saying what happens (debt mode:
  /// "จดว่าลีต้องคืนฉัน (ฉันให้ลียืมเงินออกจากกระเป๋า)").
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;
    final row = _row();
    if (caption == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        const SizedBox(height: AppSpacing.sm),
        Text(
          caption,
          key: const ValueKey('flowCaption'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _row() {
    final to = this.to;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: from),
          if (to != null) ...[
            // The money icon under the arrow says what travels between the
            // cards (owner 2026-10-23).
            Builder(
              builder: (context) {
                final scheme = Theme.of(context).colorScheme;
                final column = Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Read-only: a plain arrow, not a greyed-out button.
                    onSwap == null
                        ? Icon(
                            AppIcons.arrowForward,
                            size: 24,
                            color: scheme.onSurfaceVariant,
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.onSurface.withValues(alpha: 0.08),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Icon(
                                AppIcons.arrowForward,
                                size: 22,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                    const SizedBox(height: AppSpacing.xs),
                    Icon(
                      AppIcons.cash,
                      key: const ValueKey('flowMoney'),
                      size: 30,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                );
                // The swap takes the whole column, top to bottom.
                return SizedBox(
                  width: 64,
                  child: onSwap == null
                      ? column
                      : Semantics(
                          button: true,
                          label: swapTooltip,
                          child: BusyLock(
                            child: InkWell(
                              key: const ValueKey('flowSwap'),
                              onTap: onSwap,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: column,
                            ),
                          ),
                        ),
                );
              },
            ),
            Expanded(child: to),
          ],
        ],
      ),
    );
  }
}
