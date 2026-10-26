import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/ui_config.dart';
import '../molecules/month_picker.dart';
import '../tokens/app_spacing.dart';
import 'app_date_range_picker.dart';
import 'app_sheet.dart';
import 'period_picker_sheet.dart';

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

/// The app's one date picker; every page picks a date through it:
/// - [show]: one day,
/// - [range]: a from–to range,
/// - [month]: a month,
/// - [period]: a day, week, month or year, everything, or a range.
/// [title] names the field (วันที่ครบกำหนด); none = the kit's default.
abstract final class AppDatePicker {
  /// A calendar where a tap on a day picks it and closes, plus วันนี้ (when
  /// today is in range) and ล้าง ([clearable]).
  static Future<AppDateResult?> show(
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

  /// One month calendar where two taps mark the start and the end, optional
  /// [presets] above it, then save.
  static Future<DateTimeRange?> range(
    BuildContext context, {
    DateTimeRange? initial,
    DateTime? first,
    DateTime? last,
    String? title,
    List<AppDateRangePreset> presets = const [],
  }) {
    final f = first ?? DateTime(2000);
    final l = last ?? DateTime.now().add(const Duration(days: 365 * 20));
    return showAppSheet<DateTimeRange>(
      context,
      title: title ?? UiConfig.stringsOf(context).pickDate,
      builder: (ctx) => AppDateRangePickerSheet(
        initial: initial,
        first: f,
        last: l,
        presets: presets,
        onResult: (r) => Navigator.of(ctx).pop(r),
      ),
    );
  }

  /// A year of month cells (‹ year ›) plus เดือนนี้; a tap picks and closes.
  static Future<DateTime?> month(
    BuildContext context, {
    required DateTime selected,
    DateTime? first,
    DateTime? last,
    String? title,
  }) {
    return showAppSheet<DateTime>(
      context,
      title: title ?? UiConfig.stringsOf(context).monthPickerTitle,
      builder: (ctx) => MonthPickerGrid(
        selected: selected,
        first: first,
        last: last,
        onPicked: (m) => Navigator.of(ctx).pop(m),
      ),
    );
  }

  /// The unit chips (วัน / สัปดาห์ / เดือน / ปี / ทั้งหมด / กำหนดเอง) over
  /// the picker of that unit; "กำหนดเอง" opens [range].
  static Future<PeriodPick?> period(
    BuildContext context, {
    required PeriodPick current,
    required PeriodPickerLabels labels,
    DateTime? last,
  }) => showAppSheet<PeriodPick>(
    context,
    title: labels.title,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: PeriodPickerSheet(
        current: current,
        labels: labels,
        last: last,
        onPicked: (p) => Navigator.of(ctx).pop(p),
      ),
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
