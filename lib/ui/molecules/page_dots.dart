import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class PageDots extends StatelessWidget {
  const PageDots({
    required this.count,
    required this.index,
    this.padding = const EdgeInsets.only(
      top: AppSpacing.lg,
      bottom: AppSpacing.sm,
    ),
    super.key,
  });

  final int count;

  final int index;
  final EdgeInsetsGeometry padding;

  static const double dot = 6;
  static const double pill = 18;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Semantics(
        label: '${index + 1} / $count',
        excludeSemantics: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpacing.xs),
                child: AnimatedContainer(
                  key: ValueKey(i == index ? 'pageDotCurrent' : 'pageDot$i'),
                  duration: const Duration(milliseconds: 200),
                  width: i == index ? pill : dot,
                  height: dot,
                  decoration: BoxDecoration(
                    color: i == index ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(dot),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PageDotsScope extends InheritedWidget {
  const PageDotsScope({
    required this.count,
    required this.index,
    required super.child,
    super.key,
  });

  final int count;
  final int index;

  static PageDotsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageDotsScope>();

  @override
  bool updateShouldNotify(PageDotsScope old) =>
      old.count != count || old.index != index;
}

class PageDotsFooter extends StatelessWidget {
  const PageDotsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PageDotsScope.maybeOf(context);
    if (scope == null || scope.count < 2) return const SizedBox.shrink();
    return PageDots(count: scope.count, index: scope.index);
  }
}
