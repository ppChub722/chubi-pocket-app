import 'package:flutter/material.dart';

import '../atoms/add_tile.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_input.dart';
import '../molecules/detail_rows.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import 'app_sheet.dart';

/// The words of [DescriptionPickerSheet] — the caller passes its localised
/// strings (the kit never reads the app's l10n).
class DescriptionPickerLabels {
  const DescriptionPickerLabels({
    required this.title,
    required this.hint,
    required this.pastHeading,
    required this.useLabel,
  });

  final String title;

  final String hint;

  final String pastHeading;

  final String Function(String typed) useLabel;
}

Future<String?> showDescriptionPickerSheet(
  BuildContext context, {
  required List<String> suggestions,
  required DescriptionPickerLabels labels,
  String current = '',
  bool useRootNavigator = true,
}) => showAppSheet<String>(
  context,
  title: labels.title,
  useRootNavigator: useRootNavigator,
  builder: (ctx) => DescriptionPickerSheet(
    current: current,
    suggestions: suggestions,
    labels: labels,
    onPicked: (v) => Navigator.of(ctx).pop(v),
  ),
);

class DescriptionPickerSheet extends StatefulWidget {
  const DescriptionPickerSheet({
    required this.current,
    required this.suggestions,
    required this.labels,
    required this.onPicked,
    this.maxLength = 200,
    super.key,
  });

  final String current;
  final List<String> suggestions;
  final DescriptionPickerLabels labels;
  final ValueChanged<String> onPicked;
  final int maxLength;

  @override
  State<DescriptionPickerSheet> createState() => _DescriptionPickerSheetState();
}

class _DescriptionPickerSheetState extends State<DescriptionPickerSheet> {
  late final _text = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final q = _text.text.trim();
    final lower = q.toLowerCase();
    final matches = widget.suggestions
        .where((d) => lower.isEmpty || d.toLowerCase().contains(lower))
        .toList();
    final exact = widget.suggestions.any((d) => d.toLowerCase() == lower);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppInput(
              controller: _text,
              autofocus: true,
              hint: labels.hint,
              prefixIcon: AppIcons.note,
              maxLength: widget.maxLength,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) => widget.onPicked(v.trim()),
            ),
          ),
          if (q.isNotEmpty && !exact)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: AddTile(
                label: labels.useLabel(q),
                variant: AddTileVariant.row,
                onTap: () => widget.onPicked(q),
              ),
            ),
          if (matches.isNotEmpty)
            SectionCard(
              title: labels.pastHeading,
              children: [
                for (final d in matches)
                  AppDetailRow(
                    leading: const AppIcon(AppIcons.history),
                    label: d,
                    onTap: () => widget.onPicked(d),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
