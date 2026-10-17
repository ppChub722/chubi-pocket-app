import 'package:flutter/material.dart';

import '../molecules/detail_rows.dart';

import '../atoms/app_icon_button.dart';
import '../atoms/app_divider.dart';

import '../tokens/app_spacing.dart';
import '../atoms/ui_config.dart';

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
    final strings = UiConfig.stringsOf(context);
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
                AppIconButton.close(
                  tooltip: strings.close,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          const AppDivider(),
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
      child: SectionCard(
        first: true,
        title: title,
        leading: icon == null
            ? null
            : Icon(icon, size: 18, color: scheme.primary),
        dividers: false,
        children: [child],
      ),
    );
  }
}
