import 'package:flutter/material.dart';

import '../../atoms/app_icon_button.dart';
import '../../tokens/app/app_icons.dart';

class FlowCards extends StatelessWidget {
  const FlowCards({
    required this.from,
    this.to,
    this.onSwap,
    this.swapTooltip,
    super.key,
  });

  final Widget from;
  final Widget? to;
  final VoidCallback? onSwap;
  final String? swapTooltip;

  @override
  Widget build(BuildContext context) {
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
