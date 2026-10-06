import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

/// Opens the app's standard bottom sheet: drag handle, optional [title]
/// row, safe-area + keyboard padding, scrolls when tall.
///
/// [footer] stays pinned under the scrolling body (confirm buttons).
Future<T?> showAppSheet<T>(
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
    builder: (ctx) => AppSheetScaffold(
      title: title,
      footer: footer,
      child: builder(ctx),
    ),
  );
}

/// Layout used by [showAppSheet] — exposed so custom sheets (stateful
/// pickers) can share the same chrome.
class AppSheetScaffold extends StatelessWidget {
  const AppSheetScaffold({
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
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            Flexible(child: SingleChildScrollView(child: child)),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}
