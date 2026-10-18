import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import 'app_icon_button.dart';
import 'connection_scope.dart';

class BulkDeleteButton extends StatelessWidget {
  const BulkDeleteButton({required this.onPressed, this.tooltip, super.key});

  final VoidCallback? onPressed;

  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: AppIcons.delete,
      destructive: true,
      tooltip: tooltip,
      onPressed: ConnectionScope.isOffline(context) ? null : onPressed,
    );
  }
}
