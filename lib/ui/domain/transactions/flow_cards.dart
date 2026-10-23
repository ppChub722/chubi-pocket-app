import 'package:flutter/material.dart';

import '../../atoms/app_icon_button.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';

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
              builder: (context) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Read-only: a plain arrow, not a greyed-out button.
                  if (onSwap == null)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Icon(
                        AppIcons.arrowForward,
                        size: 22,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    AppIconButton.flat(
                      tooltip: swapTooltip,
                      dense: true,
                      icon: AppIcons.arrowForward,
                      onPressed: onSwap,
                    ),
                  Icon(
                    AppIcons.cash,
                    key: const ValueKey('flowMoney'),
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            Expanded(child: to),
          ],
        ],
      ),
    );
  }
}
