import 'package:flutter/material.dart';

import '../atoms/app_card.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../atoms/dashed_rect_border.dart';

/// A big tappable card holding one picked value — category, wallet, … —
/// that opens its picker on tap. Same look as the wallet / เพิ่มเติม cards:
/// a soft wash of the value's own [accent] colour, hairline accent border.
///
/// `[icon]  label`
/// `        Value`
/// `        subtitle`
///
/// - [value] null → empty state: dashed outline, [placeholder] in muted text
///   (an optional field the user left blank, e.g. "ไม่ระบุหมวด").
/// - No ✕ (unless [trailing] adds one): the whole card opens the picker,
///   and the picker offers the
///   "none" option for optional fields (owner 2026-10-09). No › either
///   (owner 2026-10-10): the tinted / dashed card already reads as
///   tappable, and half-width cards need the room for the value.
/// - Two side by side: wrap the [Row] in an [IntrinsicHeight] with
///   `CrossAxisAlignment.stretch` — both cards take the taller one's
///   height and centre their content. [dense] tightens the insets.
/// - [errorText] → error border + message under the card.
/// - ONE height per variant, whatever the state (owner 2026-10-12):
///   ONE height per variant, whatever the state: picking never adds a line
///   or moves the layout. With [reserveSubtitle] it is the 3-line variant
///   (label / value / subtitle, the third line kept when empty), without it
///   the 2-line one. The error then goes INSIDE the card — red on the
///   subtitle line (3-line) or in place of the label (2-line) — and nothing is
///   added below it.
class PickCard extends StatelessWidget {
  const PickCard({
    required this.label,
    required this.leading,
    required this.onTap,
    this.value,
    this.placeholder,
    this.subtitle,
    this.accent,
    this.errorText,
    this.watermark,
    this.dense = false,
    this.reserveSubtitle = false,
    this.trailing,
    this.editable = false,
    this.onLongPress,
    super.key,
  });

  /// In an edit form: the card can be changed. A picked one then wears the
  /// "chosen and still changeable" border — a dashed edge with a thin solid
  /// line 3 px inside (no layout change); an empty one is dashed already.
  final bool editable;

  /// View mode: a long-press enters edit mode on this field (and opens its
  /// picker).
  final VoidCallback? onLongPress;

  /// With [fixedHeight]: keep the third (subtitle) line even when there is
  /// nothing to put on it, so the card is as tall empty as it is picked.
  final bool reserveSubtitle;

  /// At the end of the row — e.g. a ✕ on an optional value that clears in
  /// place. Most cards have none: the
  /// picker offers "none" instead.
  final Widget? trailing;

  /// Large faded glyph in the bottom-right corner once a value is picked
  /// (the wallet's type icon, as on the wallet cards).
  final IconData? watermark;

  /// Small caption above the value ("หมวดหมู่", "กระเป๋า").
  final String label;
  final Widget leading;
  final String? value;
  final String? placeholder;

  /// Extra line under the value (parent path, balance, …).
  final Widget? subtitle;

  /// The value's colour; null = neutral.
  final Color? accent;

  /// Null = read-only (no ripple).
  final VoidCallback? onTap;
  final String? errorText;

  /// Tighter insets / gap — for two cards side by side on a phone.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final empty = value == null;
    final tint = empty ? null : accent;
    final hasError = errorText != null;
    // Nothing picked → a flat card inside a dashed outline ("not chosen
    // yet"), like the dashed add tiles; picked → solid accent card.
    // Nothing picked → a flat slot inside a dashed outline ("not chosen
    // yet"), like the dashed add tiles; picked → an AppCard (tinted when it
    // has an accent colour, plain otherwise).
    final Widget card = AppCard(
      style: empty
          ? AppCardStyle.flat
          : tint == null
          ? AppCardStyle.plain
          : AppCardStyle.tinted,
      color: tint,
      glyph: empty ? null : watermark,
      glyphSize: 72,
      // Editable + picked: the dashed / inset lines below are the border.
      borderColor: empty
          ? null
          : hasError
          ? scheme.error
          : editable
          ? Colors.transparent
          : tint == null
          ? scheme.outlineVariant
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: EdgeInsets.symmetric(
            // 12 inside.
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Opacity(opacity: empty ? 0.6 : 1, child: leading),
              SizedBox(width: dense ? AppSpacing.sm : AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // The 2-line variant has no subtitle line: the error
                      // takes the label's place.
                      hasError && !reserveSubtitle ? errorText! : label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: hasError && !reserveSubtitle
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      value ?? placeholder ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // The same line height empty and picked (no jump).
                      strutStyle: StrutStyle.fromTextStyle(
                        textTheme.titleMedium!,
                        forceStrutHeight: true,
                      ),
                      style: empty
                          ? textTheme.titleSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            )
                          : textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                    ),
                    if (reserveSubtitle || (!empty && subtitle != null))
                      if (hasError)
                        Text(
                          errorText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                        )
                      else if (!empty && subtitle != null)
                        DefaultTextStyle.merge(
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: subtitle!,
                        )
                      else
                        // The reserved line, empty: same height as picked.
                        Text(' ', style: textTheme.bodySmall),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );

    if (empty) {
      return DashedRectBorder(
        color: hasError ? scheme.error : scheme.outline,
        borderRadius: const Radius.circular(AppRadius.lg),
        child: card,
      );
    }
    if (editable && !hasError) {
      final line = tint ?? scheme.outline;
      return Stack(
        children: [
          card,
          // The dashed edge, then the thin solid line 3 px inside it.
          Positioned.fill(
            child: IgnorePointer(
              child: DashedRectBorder(
                color: line,
                strokeWidth: 1,
                dashLength: 4,
                gapLength: 3,
                borderRadius: const Radius.circular(AppRadius.lg),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg - 3),
                    border: Border.all(color: line),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return card;
  }
}

/// Muted round placeholder icon for a [PickCard] with nothing picked.
class PickCardEmptyIcon extends StatelessWidget {
  const PickCardEmptyIcon(this.icon, {this.size = 40, super.key});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.55, color: scheme.onSurfaceVariant),
    );
  }
}
