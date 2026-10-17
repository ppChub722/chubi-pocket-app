import '../../atoms/app_icon_button.dart';
import 'package:flutter/material.dart';

import '../../tokens/app/app_icons.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../atoms/ui_config.dart';
import 'reorder_controller.dart';

class ReorderMoveBar extends StatelessWidget {
  const ReorderMoveBar({required this.controller, super.key});

  final ReorderController controller;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final shown = controller.selectedId != null;
        return AnimatedSize(
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: shown ? _bar(context) : const SizedBox(width: double.infinity),
        );
      },
    );
  }

  Widget _bar(BuildContext context) {
    final l = UiConfig.stringsOf(context);
    final scheme = Theme.of(context).colorScheme;
    final c = controller;
    Widget button(
      IconData icon,
      String tooltip,
      bool enabled,
      VoidCallback onTap,
    ) => AppIconButton.flat(
      tooltip: tooltip,
      icon: icon,
      onPressed: enabled ? onTap : null,
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      // Hugs the bar (a bare Center would take a bottom bar's full height).
      child: Center(
        heightFactor: 1,
        child: Material(
          elevation: 3,
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (c.isTree)
                  button(
                    AppIcons.back,
                    l.reorderOutdent,
                    c.canOutdent,
                    c.outdent,
                  ),
                button(
                  AppIcons.trendUp,
                  l.reorderMoveUp,
                  c.canMoveUp,
                  c.moveUp,
                ),
                button(
                  AppIcons.trendDown,
                  l.reorderMoveDown,
                  c.canMoveDown,
                  c.moveDown,
                ),
                if (c.isTree)
                  button(
                    AppIcons.arrowForward,
                    l.reorderIndent,
                    c.canIndent,
                    c.indent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
