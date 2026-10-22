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
