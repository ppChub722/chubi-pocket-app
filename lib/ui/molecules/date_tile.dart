import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../atoms/app_chip.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/hero_colors.dart';

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// A tear-off calendar sheet: the month on a coloured strip, the day big and
/// the weekday under it (a recurring item's next date in its hero).
class CalendarTile extends StatelessWidget {
  const CalendarTile({
    required this.date,
    this.color,
    this.width = 64,
    super.key,
  });

  final DateTime date;

  /// The strip; defaults to the card's accent.
  final Color? color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hero = HeroColors.maybeOf(context);
    final accent = color ?? hero?.accent ?? scheme.primary;
    final locale = _locale(context);
    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: hero?.line ?? scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: accent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Text(
                DateFormat.MMM(locale).format(date),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: text.labelMedium?.copyWith(
                  color: AppChip.readableOn(accent, Colors.white),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Text(
            '${date.day}',
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: hero?.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              DateFormat.EEEE(locale).format(date),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: hero?.muted ?? scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row's date: the day number over its month ("3" / "ต.ค."), with the short
/// year when it isn't this year ("ม.ค. 27"), or over the weekday for a
/// month's list ([weekday]). [inline]: the two on one line ("3 ศ."), end
/// aligned so a column of them lines up.
class DateTile extends StatelessWidget {
  const DateTile({
    required this.date,
    this.caption,
    this.weekday = false,
    this.inline = false,
    this.color,
    this.today,
    super.key,
  });

  final DateTime date;

  /// Replaces the month / weekday line ("พรุ่งนี้").
  final String? caption;
  final bool weekday;
  final bool inline;

  /// The day number's colour.
  final Color? color;

  /// Decides "this year"; defaults to now.
  final DateTime? today;

  static const double minWidth = 38;
  static const double inlineWidth = 48;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final locale = _locale(context);
    final now = today ?? DateTime.now();
    final month = DateFormat.MMM(locale).format(date);
    final line =
        caption ??
        (weekday
            ? DateFormat.E(locale).format(date)
            : date.year == now.year
            ? month
            : '$month ${DateFormat('yy').format(date)}');
    final lineColor =
        HeroColors.maybeOf(context)?.muted ?? scheme.onSurfaceVariant;
    if (inline) {
      return SizedBox(
        width: inlineWidth,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${date.day}',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(
                text: ' $line',
                style: text.labelSmall?.copyWith(color: lineColor),
              ),
            ],
          ),
          maxLines: 1,
          textAlign: TextAlign.end,
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: minWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${date.day}',
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            line,
            maxLines: 1,
            style: text.labelSmall?.copyWith(color: lineColor),
          ),
        ],
      ),
    );
  }
}
