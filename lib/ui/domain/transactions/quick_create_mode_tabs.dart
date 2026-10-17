import 'package:flutter/material.dart';

import '../../molecules/app_tab_bar.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app/quick_create_mode.dart';

/// The quick create's mode switch at the very top of the sheet (owner
/// 2026-10-17): `รายการ · หนี้ · ออม` as the app's underline tabs, each with
/// its icon, in its mode's colour ([QuickCreateModeColors] — the same colour
/// as the shell's + — so the selected tab matches the button that opened it).
/// Tap only: the pages don't swipe (the three forms hold typed input).
class QuickCreateModeTabs extends StatelessWidget {
  const QuickCreateModeTabs({
    required this.mode,
    required this.labels,
    this.onChanged,
    super.key,
  });

  final QuickCreateMode mode;

  /// One label per mode, e.g. `{tx: 'รายการ', debt: 'หนี้'}`.
  final Map<QuickCreateMode, String> labels;

  /// Null = read-only (the mode is fixed: editing an existing entry).
  final ValueChanged<QuickCreateMode>? onChanged;

  static IconData iconOf(QuickCreateMode m) => switch (m) {
    QuickCreateMode.tx => AppIcons.transactions,
    QuickCreateMode.debt => AppIcons.debt,
    QuickCreateMode.saving => AppIcons.quickSaving,
  };

  @override
  Widget build(BuildContext context) {
    return AppTabBar<QuickCreateMode>(
      selected: mode,
      onChanged: (m) {
        if (onChanged != null && m != mode) onChanged!(m);
      },
      tabs: [
        for (final m in QuickCreateMode.values)
          if (labels[m] != null)
            AppTab(
              value: m,
              label: labels[m]!,
              icon: iconOf(m),
              color: QuickCreateModeColors.of(context, m),
            ),
      ],
    );
  }
}
