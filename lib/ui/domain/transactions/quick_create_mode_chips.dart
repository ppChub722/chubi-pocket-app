import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../tokens/quick_create_mode.dart';
import '../../tokens/app_spacing.dart';

/// The quick create's mode switch at the very top of the sheet, above the
/// EntryCard (owner 2026-10-12): `[รายการ] [หนี้]`. Each chip takes its
/// mode's colour from [QuickCreateModeColors] — the same colour as the
/// shell's + — so the selected one matches the button that opened it.
///
/// TODO(debt-mode): not in the sheet yet — debt mode waits on the BE's
/// person-entry API. Until then the + opens tx mode on every page.
class QuickCreateModeChips extends StatelessWidget {
  const QuickCreateModeChips({
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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: PpForgeSpacing.xs,
      children: [
        for (final m in QuickCreateMode.values)
          if (labels[m] != null)
            PpForgeChip(
              label: labels[m]!,
              color: QuickCreateModeColors.of(context, m),
              selected: m == mode,
              onTap: onChanged == null || m == mode
                  ? null
                  : () => onChanged!(m),
            ),
      ],
    );
  }
}
