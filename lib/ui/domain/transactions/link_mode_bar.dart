import 'package:flutter/material.dart';

import '../../atoms/app_switch.dart';
import '../../tokens/app_spacing.dart';
import 'split_event_section.dart';

/// The ผูกกับ choice as a row like the others (โน้ต, รายการประจำ): the label
/// ("แบ่ง") and a switch. Off = a plain transaction, on = the bill with
/// people.
class LinkSwitchRow extends StatelessWidget {
  const LinkSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => DraftFieldRow(
    label: label,
    dense: true,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppSwitch(
        value: value,
        onChanged: onChanged,
        semanticLabel: label,
      ),
    ),
  );
}

/// The whole ผูกกับ block (0.4.0-3): an optional [recurring] row, the
/// [bar] (a [LinkSwitchRow]), then the picked tab's [card] — stacked with the
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
