import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Opens the app's standard bottom sheet: drag handle, optional [title]
/// row, safe-area + keyboard padding, scrolls when tall.
///
/// [footer] stays pinned under the scrolling body (confirm buttons).
Future<T?> showPpForgeSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  Widget? footer,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    useRootNavigator: useRootNavigator,
    builder: (ctx) =>
        PpForgeSheetScaffold(title: title, footer: footer, child: builder(ctx)),
  );
}

/// [showPpForgeSheet] for a sheet that builds its own [PpForgeSheetScaffold]
/// (stateful sheets: a form with its own buttons, a picker with search) —
/// same route (drag handle, safe area, root navigator, keyboard), no
/// second scaffold around it.
Future<T?> showPpForgeSheetCustom<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    useRootNavigator: useRootNavigator,
    builder: builder,
  );
}

/// Layout used by [showPpForgeSheet] — exposed so custom sheets (stateful
/// pickers) can share the same chrome (open them with
/// [showPpForgeSheetCustom]). It pads for the keyboard itself, so content
/// inside must not add `viewInsets` again.
class PpForgeSheetScaffold extends StatelessWidget {
  const PpForgeSheetScaffold({
    required this.child,
    this.title,
    this.footer,
    super.key,
  });

  final Widget child;
  final String? title;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final body = SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PpForgeSpacing.lg,
                0,
                PpForgeSpacing.lg,
                PpForgeSpacing.md,
              ),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          Flexible(child: SingleChildScrollView(child: child)),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PpForgeSpacing.lg,
                PpForgeSpacing.sm,
                PpForgeSpacing.lg,
                PpForgeSpacing.md,
              ),
              child: footer!,
            ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      // The keyboard is handled right here — below this, viewInsets read
      // zero, so a sheet's own content can't pad for it a second time (a
      // double gap above the keyboard).
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: body,
      ),
    );
  }
}
