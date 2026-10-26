import '../atoms/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../atoms/ui_config.dart';
import '../atoms/app_button.dart';

DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);

/// The body of [AppDatePicker.month].
class MonthPickerGrid extends StatefulWidget {
  const MonthPickerGrid({
    required this.selected,
    required this.onPicked,
    this.first,
    this.last,
    super.key,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onPicked;
  final DateTime? first;
  final DateTime? last;

  @override
  State<MonthPickerGrid> createState() => _MonthPickerGridState();
}

class _MonthPickerGridState extends State<MonthPickerGrid> {
  late int _year = widget.selected.year;

  bool _allowed(DateTime m) =>
      (widget.first == null || !m.isBefore(_monthOf(widget.first!))) &&
      (widget.last == null || !m.isAfter(_monthOf(widget.last!)));

  bool _yearAllowed(int year) =>
      (widget.first == null || year >= widget.first!.year) &&
      (widget.last == null || year <= widget.last!.year);

  @override
  Widget build(BuildContext context) {
    final l = UiConfig.stringsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final selected = _monthOf(widget.selected);
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    Widget yearStep(IconData icon, String tooltip, int to) =>
        AppIconButton.flat(
          icon: icon,
          tooltip: tooltip,
          onPressed: _yearAllowed(to) ? () => setState(() => _year = to) : null,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              yearStep(AppIcons.chevronLeft, l.yearPrev, _year - 1),
              Expanded(
                child: Text(
                  DateFormat.y(locale).format(DateTime(_year)),
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              yearStep(AppIcons.chevronRight, l.yearNext, _year + 1),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.6,
            children: [
              for (var i = 1; i <= 12; i++)
                _MonthCell(
                  label: DateFormat.MMM(locale).format(DateTime(_year, i)),
                  isSelected: DateTime(_year, i) == selected,
                  isCurrent: DateTime(_year, i) == thisMonth,
                  onTap: _allowed(DateTime(_year, i))
                      ? () => widget.onPicked(DateTime(_year, i))
                      : null,
                ),
            ],
          ),
          if (_allowed(thisMonth)) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l.thisMonth,
              variant: AppButtonVariant.tonal,
              expand: true,
              onPressed: () => widget.onPicked(thisMonth),
            ),
          ],
        ],
      ),
    );
  }
}

/// The twelve months with no year (Jan…Dec), one picked; [selected] and the
/// picked value are 1–12.
class MonthOfYearGrid extends StatelessWidget {
  const MonthOfYearGrid({
    required this.selected,
    required this.onPicked,
    super.key,
  });

  final int selected;
  final ValueChanged<int> onPicked;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.xs,
      crossAxisSpacing: AppSpacing.xs,
      childAspectRatio: 1.4,
      children: [
        for (var i = 1; i <= 12; i++)
          _MonthCell(
            key: ValueKey('monthOfYear$i'),
            label: DateFormat.MMM(locale).format(DateTime(2001, i)),
            isSelected: i == selected,
            isCurrent: false,
            onTap: () => onPicked(i),
          ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.isSelected,
    required this.isCurrent,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isSelected;

  /// Today's month — outlined so it's findable from any year.
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: isCurrent && !isSelected
          ? BorderSide(color: scheme.primary)
          : BorderSide.none,
    );
    return Material(
      color: isSelected ? scheme.primary : scheme.surfaceContainerHigh,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: enabled ? 1 : 0.38),
            ),
          ),
        ),
      ),
    );
  }
}
