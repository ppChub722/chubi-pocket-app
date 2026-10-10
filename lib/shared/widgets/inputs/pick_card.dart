import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../dashed_rect_border.dart';

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
    this.trailing,
    super.key,
  });

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
    final borderColor = hasError
        ? scheme.error
        : tint?.withValues(alpha: 0.25) ?? scheme.outlineVariant;

    // Nothing picked → a flat card inside a dashed outline ("not chosen
    // yet"), like the dashed add tiles; picked → solid accent card.
    final Widget card = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: empty ? 0 : null,
      color: empty ? Colors.transparent : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: empty ? BorderSide.none : BorderSide(color: borderColor),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: tint == null
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tint.withValues(alpha: 0.16),
                    tint.withValues(alpha: 0.03),
                  ],
                ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              // Big faded glyph in the corner, like the wallet cards.
              if (!empty && watermark != null)
                Positioned(
                  right: -10,
                  bottom: -16,
                  child: Icon(
                    watermark,
                    size: 72,
                    color: (tint ?? scheme.onSurfaceVariant).withValues(
                      alpha: 0.10,
                    ),
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    // A nested card (12 inside — HeroSpacing.nestedPadding).
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
                              label,
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              value ?? placeholder ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: empty
                                  ? textTheme.titleSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    )
                                  : textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                            ),
                            if (!empty && subtitle != null)
                              DefaultTextStyle.merge(
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                child: subtitle!,
                              ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final framed = empty
        ? DashedRectBorder(
            color: hasError ? scheme.error : scheme.outline,
            borderRadius: const Radius.circular(AppRadius.lg),
            child: card,
          )
        : card;

    if (!hasError) return framed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        framed,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            0,
          ),
          child: Text(
            errorText!,
            style: textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ),
      ],
    );
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
