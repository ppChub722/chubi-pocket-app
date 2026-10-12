import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

/// Demo of [showDescriptionPickerSheet] for the hub: buttons that open it
/// with sample data (English only).
Widget buildDescriptionPickerSheetDemo(BuildContext context) =>
    const _DescriptionPickerSheetDemo();

const _labels = DescriptionPickerLabels(
  title: 'Description',
  hint: 'What was it for?',
  pastHeading: 'Used before',
  useLabel: _use,
);

String _use(String typed) => 'Use "$typed"';

class _DescriptionPickerSheetDemo extends StatefulWidget {
  const _DescriptionPickerSheetDemo();

  @override
  State<_DescriptionPickerSheetDemo> createState() =>
      _DescriptionPickerSheetDemoState();
}

class _DescriptionPickerSheetDemoState
    extends State<_DescriptionPickerSheetDemo> {
  String _result = 'nothing picked yet';

  Future<void> _open({
    required List<String> suggestions,
    String current = '',
  }) async {
    final r = await showDescriptionPickerSheet(
      context,
      suggestions: suggestions,
      labels: _labels,
      current: current,
    );
    if (r != null && mounted) setState(() => _result = '"$r"');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              label: 'With suggestions',
              variant: AppButtonVariant.outlined,
              onPressed: () => _open(
                suggestions: const ['Dinner', 'Taxi', 'Hotel', 'Tickets'],
              ),
            ),
            AppButton(
              label: 'Pre-filled text',
              variant: AppButtonVariant.outlined,
              onPressed: () => _open(
                suggestions: const ['Dinner', 'Taxi', 'Hotel'],
                current: 'Din',
              ),
            ),
            AppButton(
              label: 'No suggestions',
              variant: AppButtonVariant.outlined,
              onPressed: () => _open(suggestions: const []),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppText('Result: $_result'),
      ],
    );
  }
}
