import 'package:flutter/material.dart';

import '../../molecules/app_tab_bar.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app/quick_create_mode.dart';

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
            AppTab(value: m, label: labels[m]!, icon: iconOf(m)),
      ],
    );
  }
}
