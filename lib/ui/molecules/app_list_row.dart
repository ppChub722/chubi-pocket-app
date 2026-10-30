import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_icon_button.dart';
import '../atoms/select_check.dart';
import '../organisms/option_sheet.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import '../tokens/tone.dart';
import 'app_row.dart';
import 'option_menu.dart';
import 'split_row.dart';

/// The one data row of every list: leading | title + chips / line 2 / alert |
/// trailing value | actions. It knows no domain: money, wallets, tags and
/// due dates come in as widgets, strings and [ListRowChip]s. Built on
/// [AppRow] (density list).
class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.leading,
    this.title = '',
    this.titleField,
    this.titleMark,
    this.titleStrong = false,
    this.titleMaxLines = 1,
    this.titleChips = const [],
    this.status,
    this.line2,
    this.line3,
    this.trailing,
    this.actions = const [],
    this.alert,
    this.footer,
    this.dimmed = false,
    this.highlighted = false,
    this.accent,
    this.checked,
    this.onCheck,
    this.checkTooltip,
    this.indent = 0,
    this.onTap,
    this.onLongPress,
    this.loading = false,
    super.key,
  });

  static const double chipMaxWidth = 120;

  /// A small circle before the title, as tall as its letters: where the row
  /// came from (รายการประจำ / ผ่อน / อีเวนต์ …).
  final ListRowMark? titleMark;

  final Widget leading;
  final String title;

  /// In place of [title] while the row is edited in place (an input).
  final Widget? titleField;

  /// The title in w600 (an unread item).
  final bool titleStrong;
  final int titleMaxLines;
  final List<ListRowChip> titleChips;
  final ListRowChip? status;
  final ListRowLine? line2;

  /// Under line 2, the same style (a money row's tags).
  final ListRowLine? line3;
  final ListRowTrailing? trailing;

  /// Taps here never reach [onTap].
  final List<ListRowAction> actions;
  final ListRowAlert? alert;

  /// Under the title and value, from the title's left edge to the row's
  /// right (a progress bar); taps and dims with the row.
  final Widget? footer;
  final bool dimmed;
  final bool highlighted;

  /// The row's own colour (its item's): pieces inside that follow a hero's
  /// colours (a footer chain or bar) take it, as in an [AppHeroCard].
  final Color? accent;

  /// Non-null = select mode: a check before [leading].
  final bool? checked;

  /// Falls back to [onTap].
  final VoidCallback? onCheck;
  final String? checkTooltip;
  final double indent;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// The tapped row while its call runs ([AppRow.loading]).
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final small = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final line = line2?._build(context, small);
    final third = line3?._build(context, small);
    final alert = this.alert;
    final trailing = this.trailing;
    final status = this.status;
    final titleField = this.titleField;

    // The chips give way on a narrow row (under half of it each) so the
    // title keeps room; at normal widths the cap is above the chip's own max
    // width.
    final titleRow = LayoutBuilder(
      builder: (context, box) {
        Widget chip(Widget c) => ConstrainedBox(
          constraints: BoxConstraints(maxWidth: box.maxWidth * 0.45),
          child: c,
        );
        return Row(
          children: [
            if (titleMark case final mark?) ...[
              mark._build(context, textTheme.bodyLarge),
              const SizedBox(width: AppSpacing.xs),
            ],
            if (titleField != null)
              Expanded(child: titleField)
            else
              Flexible(
                child: Text(
                  title,
                  maxLines: titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: titleStrong
                      ? textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        )
                      : textTheme.bodyLarge,
                ),
              ),
            for (final c in titleChips) ...[
              const SizedBox(width: AppSpacing.xs),
              chip(c._build()),
            ],
            if (status != null) ...[
              const SizedBox(width: AppSpacing.xs),
              chip(status._build()),
            ],
          ],
        );
      },
    );

    // Line 2 and 3 sit 2 px apart, the alert 4 px under what is above it;
    // the shell puts the first one 2 px under the title.
    final below = <Widget>[
      ?line,
      if (third != null)
        Padding(
          padding: EdgeInsets.only(top: line == null ? 0 : 2),
          child: third,
        ),
      if (alert != null)
        Padding(
          padding: EdgeInsets.only(
            top: line == null && third == null ? AppSpacing.xxs : AppSpacing.xs,
          ),
          child: alert._build(context),
        ),
    ];

    return AppRow(
      title: titleRow,
      subtitle: below.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: below,
            ),
      selector: checked == null
          ? null
          : SelectCheck(
              value: checked,
              tooltip: checkTooltip,
              onTap: onCheck ?? onTap,
            ),
      leading: leading,
      trailing: trailing?._build(context, small),
      actions: [for (final a in actions) a._build(context)],
      footer: footer,
      accent: accent,
      highlighted: (checked ?? false) || highlighted,
      dimmed: dimmed,
      indent: indent,
      onTap: onTap,
      onLongPress: onLongPress,
      loading: loading,
    );
  }
}

/// A chip of an [AppListRow]; always drawn as a mini [AppChip].
@immutable
class ListRowChip {
  const ListRowChip(
    this.label, {
    this.icon,
    this.leading,
    this.tone,
    this.selected = false,
    this.fill,
    this.onFill,
    this.color,
    this.bare = false,
  });

  final String label;
  final IconData? icon;
  final Widget? leading;
  final Tone? tone;
  final bool selected;
  final Color? fill;
  final Color? onFill;

  /// The tint in place of [tone]; with [bare] the icon and label colour.
  final Color? color;

  /// See [AppChip.bare].
  final bool bare;

  Widget _build() => AppChip(
    label: label,
    icon: icon,
    leading: leading,
    tone: tone == null ? null : AppChipTone.fromTone(tone!),
    color: color,
    selected: selected,
    fill: fill,
    onFill: onFill,
    bare: bare,
    size: ChipSize.mini,
    maxWidth: AppListRow.chipMaxWidth,
  );
}

/// The row's second line, always one text line tall: a mini chip in it
/// overflows evenly instead of growing the row.
@immutable
class ListRowLine {
  const ListRowLine({
    this.lead,
    this.icon,
    this.parts = const [],
    this.spans = const [],
    this.glyphs = const [],
    this.tone,
  }) : custom = null;

  /// For a line that doesn't fit lead / parts / spans / glyphs.
  const ListRowLine.custom(Widget this.custom)
    : lead = null,
      icon = null,
      parts = const [],
      spans = const [],
      glyphs = const [],
      tone = null;

  final ListRowChip? lead;

  /// The text in this tone, semibold (an overdue age in warning).
  final Tone? tone;

  /// Before the text (↻ ทุกเดือน).
  final IconData? icon;

  /// Joined with " | ".
  final List<String> parts;

  /// After [parts]: the first after " | ", the rest after a space.
  final List<InlineSpan> spans;
  final List<ListRowGlyph> glyphs;
  final Widget? custom;

  Widget? _build(BuildContext context, TextStyle? small) {
    final shown = [
      for (final p in parts)
        if (p.isNotEmpty) p,
    ];
    final lead = this.lead;
    final custom = this.custom;
    final hasText = shown.isNotEmpty || spans.isNotEmpty;
    final icon = this.icon;
    if (custom == null &&
        lead == null &&
        icon == null &&
        !hasText &&
        glyphs.isEmpty) {
      return null;
    }
    final Widget content;
    if (custom != null) {
      content = DefaultTextStyle.merge(style: small, child: custom);
    } else {
      // The chip and the glyphs share the room that is left (55% / 45% at
      // most) so the line never overflows; at normal widths the caps are above
      // the chip's own max width and change nothing.
      content = LayoutBuilder(
        builder: (context, box) {
          // What is left after the fixed bits (the gaps and the icon, 20 px).
          final room = (box.maxWidth - 24).clamp(0.0, double.infinity);
          return Row(
            children: [
              if (lead != null) ...[
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: room * 0.55),
                  child: lead._build(),
                ),
                if (hasText || icon != null)
                  const SizedBox(width: AppSpacing.xs),
              ],
              if (icon != null) ...[
                Icon(icon, size: 14, color: small?.color),
                if (hasText) const SizedBox(width: AppSpacing.xxs),
              ],
              if (hasText)
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (shown.isNotEmpty) TextSpan(text: shown.join(' | ')),
                        for (final (i, s) in spans.indexed) ...[
                          if (i > 0 || shown.isNotEmpty)
                            TextSpan(text: i == 0 ? ' | ' : ' '),
                          s,
                        ],
                      ],
                    ),
                    style: tone == null
                        ? small
                        : small?.copyWith(
                            color: tone!.color(context),
                            fontWeight: FontWeight.w600,
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (glyphs.isNotEmpty)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: room * 0.45),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final g in glyphs) ...[
                          const SizedBox(width: AppSpacing.sm),
                          g._build(small),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }
    final height = (TextPainter(
      text: TextSpan(text: 'Ag', style: small),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout()).height;
    return SizedBox(
      height: height,
      child: OverflowBox(
        maxHeight: double.infinity,
        alignment: AlignmentDirectional.centerStart,
        child: content,
      ),
    );
  }
}

/// [AppListRow.titleMark]: the glyph alone in its colour (no disc), a little
/// larger than the title's letters (text scale included).
@immutable
class ListRowMark {
  const ListRowMark(this.icon, {required this.color, this.tooltip});

  final IconData icon;
  final Color color;
  final String? tooltip;

  Widget _build(BuildContext context, TextStyle? title) {
    final size = MediaQuery.textScalerOf(
      context,
    ).scale((title?.fontSize ?? 16) * 1.15);
    final mark = Icon(icon, size: size, color: color);
    final tip = tooltip;
    return tip == null ? mark : Tooltip(message: tip, child: mark);
  }
}

/// A small icon on line 2 (↻, 🔗, split), with an optional short text.
@immutable
class ListRowGlyph {
  const ListRowGlyph(this.icon, {this.text});

  final IconData icon;
  final String? text;

  Widget _build(TextStyle? small) {
    final text = this.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: small?.color),
        if (text != null && text.isNotEmpty) ...[
          const SizedBox(width: 2),
          Text(text, style: small, maxLines: 1),
        ],
      ],
    );
  }
}

/// The value at the right, with an optional caption under it.
sealed class ListRowTrailing {
  const ListRowTrailing({this.caption, this.captionTone});

  /// [child] gets the row's number style (a money widget, a count).
  const factory ListRowTrailing.value(
    Widget child, {
    String? caption,
    Tone? captionTone,
  }) = _ValueTrailing;

  /// Muted, or in [tone] ("รอใส่ยอด" in warning).
  const factory ListRowTrailing.text(
    String text, {
    Tone? tone,
    String? caption,
    Tone? captionTone,
  }) = _TextTrailing;

  final String? caption;
  final Tone? captionTone;

  Widget _value(BuildContext context, TextStyle? style);

  Widget _build(BuildContext context, TextStyle? small) {
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final caption = this.caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _value(context, style),
        if (caption != null && caption.isNotEmpty)
          Text(
            caption,
            maxLines: 1,
            style: captionTone == null
                ? small
                : small?.copyWith(color: captionTone!.color(context)),
          ),
      ],
    );
  }
}

class _ValueTrailing extends ListRowTrailing {
  const _ValueTrailing(this.child, {super.caption, super.captionTone});

  final Widget child;

  @override
  Widget _value(BuildContext context, TextStyle? style) =>
      DefaultTextStyle.merge(style: style, child: child);
}

class _TextTrailing extends ListRowTrailing {
  const _TextTrailing(this.text, {this.tone, super.caption, super.captionTone});

  final String text;
  final Tone? tone;

  @override
  Widget _value(BuildContext context, TextStyle? style) => Text(
    text,
    maxLines: 1,
    style: style?.copyWith(
      fontWeight: tone == null ? FontWeight.w400 : null,
      color:
          tone?.color(context) ??
          Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// Something to type in or press at the row's far right.
sealed class ListRowAction {
  const ListRowAction();

  /// A compact [ShareAmountField] (as wide as ฿99,999); [key] keeps what is
  /// typed when the list rebuilds.
  const factory ListRowAction.amount({
    Key? key,
    required double? value,
    required ValueChanged<double?>? onChanged,
    String hint,
    bool enabled,
  }) = _AmountAction;

  /// A round, filled icon button the height of a chip (✓).
  /// A plain icon button (expand / collapse, remove).
  const factory ListRowAction.icon(
    IconData icon, {
    required VoidCallback? onTap,
    String? tooltip,
    bool loading,
  }) = _IconAction;

  const factory ListRowAction.button(
    IconData icon, {
    required VoidCallback? onTap,
    String? tooltip,
    bool loading,
  }) = _ButtonAction;

  /// ⋯ that opens [options] in a popover menu.
  static ListRowAction menu<T>({
    required List<SheetOption<T>> options,
    required ValueChanged<T> onSelected,
    String? tooltip,
  }) => _MenuAction<T>(
    options: options,
    onSelected: onSelected,
    tooltip: tooltip,
  );

  Widget _build(BuildContext context);
}

class _IconAction extends ListRowAction {
  const _IconAction(
    this.icon, {
    required this.onTap,
    this.tooltip,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool loading;

  @override
  Widget _build(BuildContext context) => AppIconButton.flat(
    icon: icon,
    tooltip: tooltip,
    dense: true,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    onPressed: onTap,
    loading: loading,
  );
}

class _MenuAction<T> extends ListRowAction {
  const _MenuAction({
    required this.options,
    required this.onSelected,
    this.tooltip,
  });

  final List<SheetOption<T>> options;
  final ValueChanged<T> onSelected;
  final String? tooltip;

  @override
  Widget _build(BuildContext context) => OptionMenuAnchor<T>(
    options: options,
    onSelected: onSelected,
    builder: (context, toggle) =>
        AppIconButton.more(onPressed: toggle, tooltip: tooltip, dense: true),
  );
}

class _AmountAction extends ListRowAction {
  const _AmountAction({
    this.key,
    required this.value,
    required this.onChanged,
    this.hint = '0',
    this.enabled = true,
  });

  final Key? key;
  final double? value;
  final ValueChanged<double?>? onChanged;
  final String hint;
  final bool enabled;

  @override
  Widget _build(BuildContext context) => ShareAmountField(
    key: key,
    value: value,
    onChanged: onChanged,
    hint: hint,
    enabled: enabled,
    compact: true,
  );
}

class _ButtonAction extends ListRowAction {
  const _ButtonAction(
    this.icon, {
    required this.onTap,
    this.tooltip,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool loading;

  @override
  Widget _build(BuildContext context) => AppIconButton.filled(
    icon: icon,
    onPressed: onTap,
    tooltip: tooltip,
    loading: loading,
    size: ChipSize.chip.heightOf(context),
  );
}

/// A warning line under the row.
@immutable
class ListRowAlert {
  const ListRowAlert(this.text, {this.tone = Tone.warning});

  final String text;
  final Tone tone;

  Widget _build(BuildContext context) {
    final color = tone.color(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(AppIcons.warning, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
