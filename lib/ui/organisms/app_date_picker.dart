import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/ui_config.dart';
import '../tokens/app_spacing.dart';
import 'app_sheet.dart';

/// What [showPpForgeDatePicker] resolves with (null = dismissed).
sealed class PpForgeDateResult {
  const PpForgeDateResult();
}

/// A day was picked.
class PpForgeDatePicked extends PpForgeDateResult {
  const PpForgeDatePicked(this.date);
  final DateTime date;
}

/// The "clear" button was pressed (only when `clearable`).
class PpForgeDateCleared extends PpForgeDateResult {
  const PpForgeDateCleared();
}

/// THE date picker (owner 2026-10-12): a bottom sheet with a calendar —
/// tapping a day picks it at once — plus "today" and, when [clearable], "clear".
/// Replaces every raw Material `showDatePicker`.
///
/// ```dart
/// final r = await showPpForgeDatePicker(context, initial: d, first: …, last: …);
/// if (r is PpForgeDatePicked) setState(() => d = r.date);
/// ```
Future<PpForgeDateResult?> showPpForgeDatePicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
  String? title,
  bool clearable = false,
}) {
  final f = first ?? DateTime(2000);
  final l = last ?? DateTime.now().add(const Duration(days: 365 * 20));
  return showPpForgeSheet<PpForgeDateResult>(
    context,
    title: title ?? PpForgeConfig.stringsOf(context).pickDate,
    builder: (ctx) => PpForgeDatePickerSheet(
      initial: initial,
      first: f,
      last: l,
      clearable: clearable,
      onResult: (r) => Navigator.of(ctx).pop(r),
    ),
  );
}

/// The picker's body (the calendar and its buttons) — [showPpForgeDatePicker]
/// puts it in a sheet; [onResult] gets the pick.
class PpForgeDatePickerSheet extends StatelessWidget {
  const PpForgeDatePickerSheet({
    required this.initial,
    required this.first,
    required this.last,
    required this.onResult,
    this.clearable = false,
    super.key,
  });

  final DateTime initial;
  final DateTime first;
  final DateTime last;
  final bool clearable;
  final ValueChanged<PpForgeDateResult> onResult;

  DateTime _clamp(DateTime d) =>
      d.isBefore(first) ? first : (d.isAfter(last) ? last : d);

  @override
  Widget build(BuildContext context) {
    final strings = PpForgeConfig.stringsOf(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final canToday = !today.isBefore(first) && !today.isAfter(last);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalendarDatePicker(
          initialDate: _clamp(initial),
          firstDate: first,
          lastDate: last,
          onDateChanged: (d) => onResult(PpForgeDatePicked(d)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PpForgeSpacing.lg,
            0,
            PpForgeSpacing.lg,
            PpForgeSpacing.lg,
          ),
          child: Row(
            children: [
              if (clearable)
                Expanded(
                  child: PpForgeButton(
                    label: strings.clear,
                    variant: PpForgeButtonVariant.outlined,
                    onPressed: () => onResult(const PpForgeDateCleared()),
                  ),
                ),
              if (clearable && canToday)
                const SizedBox(width: PpForgeSpacing.sm),
              if (canToday)
                Expanded(
                  child: PpForgeButton(
                    label: strings.today,
                    variant: PpForgeButtonVariant.tonal,
                    onPressed: () => onResult(PpForgeDatePicked(today)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
