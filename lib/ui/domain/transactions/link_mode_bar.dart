import 'package:flutter/material.dart';

import '../../molecules/app_tab_bar.dart';
import '../../tokens/app_spacing.dart';

/// "ผูกกับ" and its pill tabs on ONE row (owner 2026-10-21): [label] then an
/// [AppTabBar] taking the rest (ส่วนตัว / แบ่ง / จ่ายแทน / อีเวนต์). With 4
/// tabs only the selected tab shows its icon, and only when it fits (a
/// 320-wide phone drops it).
class LinkModeBar<T> extends StatelessWidget {
  const LinkModeBar({
    required this.label,
    required this.tabs,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String label;
  final List<AppTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: AppTabBar<T>(
          tabs: tabs,
          selected: selected,
          onChanged: onChanged,
        ),
      ),
    ],
  );
}

/// The whole ผูกกับ block (0.4.0-3): an optional [recurring] row, the
/// [bar] (a [LinkModeBar]), then the picked tab's [card] — stacked with the
/// kit's small gap, so the feature only wires them.
class LinkSectionFrame extends StatelessWidget {
  const LinkSectionFrame({
    required this.bar,
    this.recurring,
    this.card,
    super.key,
  });

  final Widget bar;
  final Widget? recurring;
  final Widget? card;

  @override
  Widget build(BuildContext context) {
    final recurring = this.recurring;
    final card = this.card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (recurring != null) ...[
          recurring,
          const SizedBox(height: AppSpacing.sm),
        ],
        bar,
        if (card != null) ...[const SizedBox(height: AppSpacing.sm), card],
      ],
    );
  }
}
