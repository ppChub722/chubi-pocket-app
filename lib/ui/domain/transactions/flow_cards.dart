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
            AppIconButton.flat(
              tooltip: onSwap == null ? null : swapTooltip,
              dense: true,
              icon: AppIcons.arrowForward,
              onPressed: onSwap,
            ),
            Expanded(child: to),
          ],
        ],
      ),
    );
  }
}
