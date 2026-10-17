import 'package:flutter/material.dart';

import '../../atoms/app_icon_button.dart';
import '../../tokens/app/app_icons.dart';

/// Where the money goes, as cards in three columns (owner 2026-10-17):
///
///   [ from ]  →  [ to ]
///
/// the arrow in the middle column. Used by quick create's transfer (wallet →
/// wallet), debt (wallet → person when I paid, person → wallet when they paid
/// me) and saving (wallet → goal). Each side is a two-line pick card (a small
/// caption over the name, no row icon), picking from the full picker — no
/// "suggested" chips. [onSwap] makes the arrow a button (a transfer swaps its
/// wallets, a debt flips Paid / Received); null = a plain arrow. [to] null =
/// one card alone, no arrow (a debt written to the ledger only has no wallet).
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
