import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Opens a full-height panel that slides in from the **right** over a
/// scrim — for settings of the screen behind it (the transactions list's
/// filters, owner 2026-10-10). About [widthFactor] of a phone's width,
/// capped at [maxWidth] on wide screens. Tap the scrim, swipe the panel
/// right, ✕ or back to close; resolves what the panel pops with.
///
/// Lay the panel out with [SideSheetScaffold] (title · scrolling body ·
/// pinned footer).
Future<T?> showSideSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double widthFactor = 0.85,
  double maxWidth = 420,
  bool useRootNavigator = true,
}) {
  final l = MaterialLocalizations.of(context);
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: true,
    barrierLabel: l.modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, _) => _SideSheetPanel(
      widthFactor: widthFactor,
      maxWidth: maxWidth,
      child: Builder(builder: builder),
    ),
    transitionBuilder: (ctx, animation, _, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      ),
      child: child,
    ),
  );
}

/// The panel: pinned to the right edge, full height, follows a rightward
/// drag and closes past a third of its width (or on a fling).
class _SideSheetPanel extends StatefulWidget {
  const _SideSheetPanel({
    required this.widthFactor,
    required this.maxWidth,
    required this.child,
  });

  final double widthFactor;
  final double maxWidth;
  final Widget child;

  @override
  State<_SideSheetPanel> createState() => _SideSheetPanelState();
}

class _SideSheetPanelState extends State<_SideSheetPanel> {
  double _drag = 0;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * widget.widthFactor).clamp(
      0.0,
      widget.maxWidth,
    );
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => setState(
          () => _drag = (_drag + (d.primaryDelta ?? 0)).clamp(0.0, width),
        ),
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v > 300 || _drag > width / 3) {
            Navigator.of(context).maybePop();
          } else {
            setState(() => _drag = 0);
          }
        },
        child: Transform.translate(
          offset: Offset(_drag, 0),
          child: SizedBox(
            width: width,
            height: double.infinity,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 8,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A side sheet's layout: title row with ✕, the [body] scrolling, the
/// [footer] (actions) pinned at the bottom clear of the gesture bar.
class SideSheetScaffold extends StatelessWidget {
  const SideSheetScaffold({
    required this.title,
    required this.body,
    this.footer,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      left: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: l.commonClose,
                  icon: const Icon(AppIcons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(child: SingleChildScrollView(child: body)),
          if (footer != null)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

/// A titled block inside a side sheet's body ("ประเภท", "กระเป๋า", …),
/// [icon] in front of the title — so the rows under it start flush left.
class SideSheetSection extends StatelessWidget {
  const SideSheetSection({
    required this.title,
    required this.child,
    this.icon,
    super.key,
  });

  final String title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
