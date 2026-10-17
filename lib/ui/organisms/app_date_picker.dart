import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/ui_config.dart';
import '../tokens/app_spacing.dart';
import 'app_sheet.dart';

sealed class AppDateResult {
  const AppDateResult();
}

class AppDatePicked extends AppDateResult {
  const AppDatePicked(this.date);
  final DateTime date;
}

class AppDateCleared extends AppDateResult {
  const AppDateCleared();
}

Future<AppDateResult?> showAppDatePicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
  String? title,
  bool clearable = false,
}) {
  final f = first ?? DateTime(2000);
  final l = last ?? DateTime.now().add(const Duration(days: 365 * 20));
  return showAppSheet<AppDateResult>(
    context,
    title: title ?? UiConfig.stringsOf(context).pickDate,
    builder: (ctx) => AppDatePickerSheet(
      initial: initial,
      first: f,
      last: l,
      clearable: clearable,
      onResult: (r) => Navigator.of(ctx).pop(r),
    ),
  );
}

class AppDatePickerSheet extends StatelessWidget {
  const AppDatePickerSheet({
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
  final ValueChanged<AppDateResult> onResult;

  DateTime _clamp(DateTime d) =>
      d.isBefore(first) ? first : (d.isAfter(last) ? last : d);

  @override
  Widget build(BuildContext context) {
    final strings = UiConfig.stringsOf(context);
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
          onDateChanged: (d) => onResult(AppDatePicked(d)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              if (clearable)
                Expanded(
                  child: AppButton(
                    label: strings.clear,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => onResult(const AppDateCleared()),
                  ),
                ),
              if (clearable && canToday) const SizedBox(width: AppSpacing.sm),
              if (canToday)
                Expanded(
                  child: AppButton(
                    label: strings.today,
                    variant: AppButtonVariant.tonal,
                    onPressed: () => onResult(AppDatePicked(today)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
