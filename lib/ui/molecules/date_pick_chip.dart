import 'package:flutter/material.dart';

import '../../core/utils/date_formatter.dart';
import '../atoms/app_chip.dart';
import '../atoms/ui_config.dart';
import '../tokens/app/app_icons.dart';

/// An optional date as a chip: none = dashed "+ เลือกวันที่", set = the day
/// with ✕. A null [onPick] shows just the day (view mode).
class DatePickChip extends StatelessWidget {
  const DatePickChip({
    required this.date,
    this.onPick,
    this.onClear,
    this.emptyLabel,
    this.format,
    super.key,
  });

  final DateTime? date;
  final VoidCallback? onPick;

  /// The ✕ on a set day.
  final VoidCallback? onClear;

  /// Null = the kit's "pick a date".
  final String? emptyLabel;

  /// Null = a medium date (e.g. 11 พ.ย. 2026).
  final String Function(DateTime date)? format;

  @override
  Widget build(BuildContext context) {
    final d = date;
    if (d == null) {
      return AppChip(
        label: emptyLabel ?? UiConfig.stringsOf(context).pickDate,
        icon: AppIcons.add,
        tone: AppChipTone.primary,
        selected: true,
        dashed: true,
        onTap: onPick,
      );
    }
    final label =
        format?.call(d) ??
        DateFormatter.medium(
          d,
          locale: Localizations.localeOf(context).toLanguageTag(),
        );
    if (onPick == null) return AppChip(label: label, icon: AppIcons.date);
    return AppChip(
      label: label,
      icon: AppIcons.date,
      selected: true,
      dashed: true,
      inset: true,
      trailing: onClear == null ? AppChipTrailing.none : AppChipTrailing.remove,
      onRemove: onClear,
      onTap: onPick,
    );
  }
}
