import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

/// One tab of an [AppTabBar].
class AppTab<T> {
  const AppTab({required this.value, required this.label, this.badgeCount = 0});

  final T value;
  final String label;
  final int badgeCount;
}

/// Equal-width underline tab bar (categories' expense/income tabs style).
/// Value-driven — no `TabController` needed; the page swaps its body on
/// [onChanged].
class AppTabBar<T> extends StatelessWidget {
  const AppTabBar({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<AppTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [for (final t in tabs) _tab(context, scheme, t)],
      ),
    );
  }

  Widget _tab(BuildContext context, ColorScheme scheme, AppTab<T> t) {
    final active = t.value == selected;
    final label = Text(
      t.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: active ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
    );
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(t.value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md, horizontal: AppSpacing.xs),
              child: t.badgeCount > 0
                  ? Badge(
                      label: Text('${t.badgeCount}'),
                      offset: const Offset(14, -6),
                      child: label,
                    )
                  : label,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2.5,
              color: active ? scheme.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
