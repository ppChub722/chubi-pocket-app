import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import 'app_icon_button.dart';
import 'connection_scope.dart';

/// The bulk-delete action of every selection bar (tags, pending, …): a red
/// trash ICON only — no label — at the right end of the bar. Pass the bar's
/// [FilterBar.trailing] / the last child of its row. [onPressed] null = dimmed
/// (nothing selected); it dims while offline too (a delete can't reach the
/// server).
class BulkDeleteButton extends StatelessWidget {
  const BulkDeleteButton({required this.onPressed, this.tooltip, super.key});

  final VoidCallback? onPressed;

  /// Accessibility label (not shown) — "ลบ".
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return PpForgeIconButton(
      icon: PpForgeIcons.delete,
      destructive: true,
      size: 32,
      tooltip: tooltip,
      onPressed: ConnectionScope.isOffline(context) ? null : onPressed,
    );
  }
}
