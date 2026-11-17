import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/recurring.dart';

/// The item form's การเตือน (0.4.3): each reminder as when (before it's due /
/// starts / ends), how many days before and at what time; + เพิ่มการเตือน.
/// A daily BE job writes the notices.
class RecurringRemindersForm extends StatelessWidget {
  const RecurringRemindersForm({
    required this.reminders,
    required this.onChanged,
    this.hasEnd = false,
    super.key,
  });

  final List<RecurringReminder> reminders;
  final ValueChanged<List<RecurringReminder>> onChanged;

  /// "ก่อนสิ้นสุด" only for an item with an end.
  final bool hasEnd;

  static const _days = [0, 1, 2, 3, 5, 7, 14];
  static const _times = ['07:00', '09:00', '12:00', '18:00', '20:00'];

  String _anchor(AppLocalizations l, ReminderAnchor a) => switch (a) {
    ReminderAnchor.due => l.recurringReminderAnchorDue,
    ReminderAnchor.start => l.recurringReminderAnchorStart,
    ReminderAnchor.end => l.recurringReminderAnchorEnd,
  };

  String _dayText(AppLocalizations l, int n) =>
      n == 0 ? l.recurringReminderSameDay : l.recurringReminderDays(n);

  void _set(int i, RecurringReminder r) => onChanged([...reminders]..[i] = r);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SectionCard(
      key: const ValueKey('remindersSection'),
      title: l.recurringRemindersSection,
      children: [
        for (final (i, r) in reminders.indexed) ...[
          SettingDropdownRow<ReminderAnchor>(
            key: ValueKey('reminderAnchor-$i'),
            label: _anchor(l, r.anchor),
            value: _dayText(l, r.daysBefore),
            selected: r.anchor,
            submits: false,
            onSelected: (a) => _set(i, r.copyWith(anchor: a)),
            options: [
              for (final a in ReminderAnchor.values)
                if (a != ReminderAnchor.end || hasEnd)
                  SheetOption(value: a, label: _anchor(l, a)),
            ],
          ),
          SettingDropdownRow<int>(
            key: ValueKey('reminderDays-$i'),
            label: l.recurringReminderDays(r.daysBefore),
            value: _dayText(l, r.daysBefore),
            selected: r.daysBefore,
            submits: false,
            onSelected: (d) => _set(i, r.copyWith(daysBefore: d)),
            options: [
              for (final d in _days)
                SheetOption(value: d, label: _dayText(l, d)),
            ],
          ),
          SettingDropdownRow<String>(
            key: ValueKey('reminderTime-$i'),
            label: r.time,
            value: r.time,
            selected: r.time,
            submits: false,
            // The empty value is the menu's ลบ: it removes this reminder.
            onSelected: (t) => t.isEmpty
                ? onChanged([...reminders]..removeAt(i))
                : _set(i, r.copyWith(time: t)),
            options: [
              for (final t in {..._times, r.time})
                SheetOption(value: t, label: t),
              SheetOption(
                value: '',
                label: l.commonDelete,
                leading: const PpForgeIcon(AppIcons.delete),
              ),
            ],
          ),
        ],
        // The BE keeps at most 5.
        if (reminders.length < 5)
          AddTile(
            key: const ValueKey('reminderAdd'),
            label: l.recurringReminderAdd,
            onTap: () => onChanged([...reminders, const RecurringReminder()]),
          ),
      ],
    );
  }
}
