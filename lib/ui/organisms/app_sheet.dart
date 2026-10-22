import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  Widget? footer,
  bool padded = false,
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
      padded: padded,
      child: builder(ctx),
    ),
  );
}

Future<T?> showAppSheetCustom<T>(
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

class AppSheetScaffold extends StatelessWidget {
  const AppSheetScaffold({
    required this.child,
    this.title,
    this.footer,
    this.padded = false,
    super.key,
  });

  final Widget child;
  final String? title;
  final Widget? footer;

  /// The page gutter around [child] (a card shown in a sheet), so callers
  /// never pad it themselves.
  final bool padded;

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
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: padded
                  ? const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    )
                  : null,
              child: child,
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: footer!,
            ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: body,
      ),
    );
  }
}
