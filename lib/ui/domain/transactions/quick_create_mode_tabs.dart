import 'package:flutter/material.dart';

import '../../tokens/app/app_icons.dart';
import '../../tokens/app/quick_create_mode.dart';
import '../../tokens/app_spacing.dart';

/// The quick-create mode switch (รายการ | หนี้ | ออม): the active mode is a
/// wide pill filled with ITS colour, icon and bold label; the others are
/// plain text on the track, so what is being made reads at a glance.
class QuickCreateModeTabs extends StatelessWidget {
  const QuickCreateModeTabs({
    required this.mode,
    required this.labels,
    this.onChanged,
    super.key,
  });

  final QuickCreateMode mode;

  final Map<QuickCreateMode, String> labels;

  final ValueChanged<QuickCreateMode>? onChanged;

  static const double height = 52;

  /// The active pill's share of the track; the rest is split evenly.
  static const double _activeShare = 0.44;

  static const _inset = 4.0;

  static IconData iconOf(QuickCreateMode m) => switch (m) {
    QuickCreateMode.tx => AppIcons.transactions,
    QuickCreateMode.debt => AppIcons.debt,
    QuickCreateMode.saving => AppIcons.quickSaving,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final modes = [
      for (final m in QuickCreateMode.values)
        if (labels[m] != null) m,
    ];
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Container(
      height: height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final active = box.maxWidth * _activeShare;
          final rest = modes.length > 1
              ? (box.maxWidth - active) / (modes.length - 1)
              : box.maxWidth;
          return Row(
            children: [
              for (final m in modes)
                _segment(
                  context,
                  m,
                  selected: m == mode,
                  width: m == mode ? active : rest,
                  animate: animate,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    QuickCreateMode m, {
    required bool selected,
    required double width,
    required bool animate,
  }) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final color = QuickCreateModeColors.of(context, m);
    final on = QuickCreateModeColors.onOf(context, m);
    final label = Text(
      labels[m]!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: selected
          ? text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: on)
          : text.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (onChanged != null && m != mode) onChanged!(m);
        },
        child: AnimatedContainer(
          key: ValueKey('quickMode-${m.name}'),
          duration: animate ? const Duration(milliseconds: 250) : Duration.zero,
          curve: Curves.easeOutCubic,
          width: width,
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular((height - _inset * 2) / 2),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: selected
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconOf(m), size: 22, color: on),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(child: label),
                  ],
                )
              : label,
        ),
      ),
    );
  }
}
