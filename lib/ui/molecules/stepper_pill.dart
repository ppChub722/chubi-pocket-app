import '../tokens/chip_size.dart';
import '../atoms/app_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../atoms/ui_config.dart';
import '../organisms/app_date_picker.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/hero_colors.dart';

enum StepperUnit { week, month, year }

class StepperPill extends StatelessWidget {
  const StepperPill({
    required this.label,
    this.onPrev,
    this.onNext,
    this.onTap,
    this.prevTooltip,
    this.nextTooltip,
    this.size,
    this.caret = true,
    super.key,
  }) : _unit = null,
       _value = null,
       _onValue = null,
       _first = null,
       _last = null;

  const StepperPill.month({
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
    DateTime? first,
    DateTime? last,
    this.onTap,
    this.size,
    this.caret = true,
    super.key,
  }) : _unit = StepperUnit.month,
       _value = value,
       _onValue = onChanged,
       _first = first,
       _last = last,
       label = '',
       onPrev = null,
       onNext = null,
       prevTooltip = null,
       nextTooltip = null;

  const StepperPill.period({
    required StepperUnit unit,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
    DateTime? first,
    DateTime? last,
    this.onTap,
    this.size,
    this.caret = true,
    super.key,
  }) : _unit = unit,
       _value = value,
       _onValue = onChanged,
       _first = first,
       _last = last,
       label = '',
       onPrev = null,
       onNext = null,
       prevTooltip = null,
       nextTooltip = null;

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onTap;
  final String? prevTooltip;
  final String? nextTooltip;

  final ChipSize? size;

  /// False = no ▾ after a tappable label (it still opens the picker).
  final bool caret;

  final StepperUnit? _unit;
  final DateTime? _value;
  final ValueChanged<DateTime>? _onValue;
  final DateTime? _first;
  final DateTime? _last;

  static DateTime startOf(StepperUnit unit, DateTime d) => switch (unit) {
    StepperUnit.week => DateTime(d.year, d.month, d.day - (d.weekday - 1)),
    StepperUnit.month => DateTime(d.year, d.month),
    StepperUnit.year => DateTime(d.year),
  };

  static DateTime shift(StepperUnit unit, DateTime start, int n) =>
      switch (unit) {
        StepperUnit.week => DateTime(
          start.year,
          start.month,
          start.day + 7 * n,
        ),
        StepperUnit.month => DateTime(start.year, start.month + n),
        StepperUnit.year => DateTime(start.year + n),
      };

  static String _labelOf(
    StepperUnit unit,
    DateTime start,
    String locale,
  ) => switch (unit) {
    StepperUnit.month => DateFormat.yMMMM(locale).format(start),
    StepperUnit.year => DateFormat.y(locale).format(start),
    StepperUnit.week =>
      '${DateFormat.MMMd(locale).format(start)} – '
          '${DateFormat.yMMMd(locale).format(shift(StepperUnit.week, start, 0).add(const Duration(days: 6)))}',
  };

  @override
  Widget build(BuildContext context) {
    final unit = _unit;
    if (unit == null) {
      return _pill(
        context,
        label: label,
        onPrev: onPrev,
        onNext: onNext,
        onTap: onTap,
        prevTooltip: prevTooltip,
        nextTooltip: nextTooltip,
      );
    }
    final strings = UiConfig.stringsOf(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = startOf(unit, _value!);
    final prev = shift(unit, start, -1);
    final next = shift(unit, start, 1);
    final canPrev = _first == null || !prev.isBefore(startOf(unit, _first));
    final canNext = _last == null || !next.isAfter(startOf(unit, _last));
    final change = _onValue!;
    final isMonth = unit == StepperUnit.month;
    return _pill(
      context,
      label: _labelOf(unit, start, locale),
      onPrev: canPrev ? () => change(prev) : null,
      onNext: canNext ? () => change(next) : null,
      prevTooltip: isMonth ? strings.monthPrev : strings.periodPrev,
      nextTooltip: isMonth ? strings.monthNext : strings.periodNext,
      onTap:
          onTap ??
          (isMonth
              ? () async {
                  final picked = await AppDatePicker.month(
                    context,
                    selected: start,
                    first: _first,
                    last: _last,
                  );
                  if (picked != null && picked != start) change(picked);
                }
              : null),
      tapTooltip: isMonth ? strings.monthPickerTitle : null,
    );
  }

  Widget _pill(
    BuildContext context, {
    required String label,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
    required VoidCallback? onTap,
    String? prevTooltip,
    String? nextTooltip,
    String? tapTooltip,
  }) {
    final scheme = Theme.of(context).colorScheme;
    // Inside a hero the pill takes the card's colors (the inset fill the
    // boxes in the card use — white on light — the card's line, accent
    // arrows) and sits flat like the other chips there.
    final hero = HeroColors.maybeOf(context);
    final arrows = onPrev != null || onNext != null;
    final chipSize = size ?? ChipSizeScope.of(context) ?? ChipSize.control;
    final height = chipSize.heightOf(context);

    Widget step(IconData icon, String? tooltip, VoidCallback? onStep) {
      final button = InkResponse(
        onTap: onStep,
        radius: 20,
        child: SizedBox.square(
          dimension: height,
          child: Icon(
            icon,
            size: chipSize.icon + 4,
            color: onStep == null
                ? scheme.onSurface.withValues(alpha: 0.38)
                : hero?.accent ?? scheme.onSurface,
          ),
        ),
      );
      return tooltip == null
          ? button
          : Tooltip(message: tooltip, child: button);
    }

    Widget labelButton = InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: arrows ? AppSpacing.xs : AppSpacing.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (onTap != null && caret)
              Icon(
                AppIcons.dropdown,
                size: chipSize.icon + 4,
                color: hero?.muted ?? scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
    if (tapTooltip != null) {
      labelButton = Tooltip(message: tapTooltip, child: labelButton);
    }

    return Material(
      color: hero?.insetOrSoft ?? scheme.surfaceContainerHigh,
      elevation: hero == null ? 1.5 : 0,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: StadiumBorder(
        side: BorderSide(color: hero?.line ?? scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (arrows) step(AppIcons.chevronLeft, prevTooltip, onPrev),
          Flexible(child: labelButton),
          if (arrows) step(AppIcons.chevronRight, nextTooltip, onNext),
        ],
      ),
    );
  }
}
