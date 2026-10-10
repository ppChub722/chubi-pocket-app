import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'reorder_controller.dart';

/// The floating ← ↑ ↓ → bar of reorder mode, shown while a row is
/// selected (owner 2026-10-11). Put it right above the page's
/// [ModeActionBar]:
///
/// ```dart
/// bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
///   ReorderMoveBar(controller: c),
///   ModeActionBar(...),
/// ]),
/// ```
///
/// ↑ ↓ move one visible slot (across parents, keeping the depth); ← / →
/// outdent / indent (trees only — a flat list shows ↑ ↓). A move that
/// isn't possible is dimmed. Each press is one undo step.
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
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final c = controller;
    Widget button(
      IconData icon,
      String tooltip,
      bool enabled,
      VoidCallback onTap,
    ) => IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
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
