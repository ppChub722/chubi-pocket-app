import 'package:flutter/material.dart';

import '../../molecules/app_tab_bar.dart';
import '../../tokens/app_spacing.dart';

/// The ผูกกับ pill tabs (ส่วนตัว / แบ่ง / อีเวนต์) across the full width, with
/// no label of their own; a [label] puts it before them on one row.
class LinkModeBar<T> extends StatelessWidget {
  const LinkModeBar({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    this.label,
    super.key,
  });

  final String? label;
  final List<AppTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    final bar = AppTabBar<T>(
      tabs: tabs,
      selected: selected,
      onChanged: onChanged,
    );
    if (label == null) return bar;
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: bar),
      ],
    );
  }
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
