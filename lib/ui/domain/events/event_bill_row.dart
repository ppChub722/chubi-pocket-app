import 'package:flutter/material.dart';

import '../../atoms/select_check.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../icons/icon_code.dart';
import '../money/money_text.dart';
import '../people/person_mark.dart';
import 'event_card.dart';

/// Wraps one of [EventBillRow]'s tag chips — e.g. in an `OptionMenuAnchor`
/// so the tag opens a popover anchored to itself:
///
/// ```dart
/// tagAnchorBuilder: (context, i, chip) => OptionMenuAnchor(
///   options: …, onSelected: …,
///   builder: (context, toggle) => chip(toggle),
/// ),
/// ```
///
/// [chip] builds the tag's mini chip with the given tap.
typedef EventTagAnchorBuilder =
    Widget Function(
      BuildContext context,
      int index,
      Widget Function(VoidCallback? onTap) chip,
    );

/// The fade of a marked (resolved) or locked bill row.
const double _fadedOpacity = 0.55;

/// One bill on an event's board (owner 2026-10-12), same geometry as a
/// [TxRow] (`TxRow` height, no children):
///
///   [☐] (icon)  title [tag] [tag]                            −฿540
///               (payer) payer · date · summary  🔗
///     ↳ [☐] (p) name  ติด ฿120                                 ฿120
///
/// - The leading tick is the resolve STATE ([marked]) in the square
///   [SelectCheck] look; [onTickTap] null = inert. A marked row fades.
/// - [leading]: an optional type glyph after the tick.
/// - [title]: decided by the caller (description ?? tags ?? "—").
/// - [tags]: the event's tags as mini chips, each its own tap target:
///   [onTagTap] gets the CHIP's context, or [tagAnchorBuilder] wraps each
///   chip (a popover anchor) — the builder wins when both are set.
/// - Line 2: the payer's mini [PersonMark] + [payerName], then [caption]
///   (the date) and [summary] (the split summary); [linked] adds 🔗 (the
///   bill is in my book).
/// - [amount] with [tone] (signed by default: the caller signs it by type).
/// - [locked]: inert and faded — no tap anywhere (tick, tags, row).
/// - [children]: the split lines ([EventBillChildRow]) under the row.
/// - [highlighted]: the bill a link pointed at (tx detail "อยู่ในอีเวนต์ ›"):
///   a brief primary tint that fades out, played when it turns on.
class EventBillRow extends StatelessWidget {
  const EventBillRow({
    required this.title,
    required this.amount,
    this.tone = MoneyTone.signed,
    this.symbol = '฿',
    this.marked = false,
    this.onTickTap,
    this.tickTooltip,
    this.leading,
    this.tags = const [],
    this.onTagTap,
    this.tagAnchorBuilder,
    this.payerName,
    this.payerLevel = PersonLevel.name,
    this.payerIconCode,
    this.caption,
    this.summary,
    this.linked = false,
    this.locked = false,
    this.onTap,
    this.children = const [],
    this.highlighted = false,
    super.key,
  });

  final String title;
  final num amount;
  final MoneyTone tone;
  final String symbol;
  final bool marked;
  final VoidCallback? onTickTap;
  final String? tickTooltip;
  final Widget? leading;
  final List<EventTagRef> tags;
  final void Function(BuildContext chipContext, int index)? onTagTap;
  final EventTagAnchorBuilder? tagAnchorBuilder;
  final String? payerName;
  final PersonLevel payerLevel;
  final IconCode? payerIconCode;
  final String? caption;
  final String? summary;
  final bool linked;
  final bool locked;
  final VoidCallback? onTap;
  final List<Widget> children;
  final bool highlighted;

  /// The most of line 1 the tag chips may take (the title keeps the rest).
  static const double tagsMaxShare = 0.6;

  Widget _tag(BuildContext context, int i) {
    final ref = tags[i];
    if (locked) return ref.chip(context, maxWidth: 96);
    if (tagAnchorBuilder != null) {
      return tagAnchorBuilder!(
        context,
        i,
        (tap) => ref.chip(context, onTap: tap, maxWidth: 96),
      );
    }
    final tap = onTagTap;
    if (tap == null) return ref.chip(context, maxWidth: 96);
    return Builder(
      builder: (chipContext) =>
          ref.chip(chipContext, onTap: () => tap(chipContext, i), maxWidth: 96),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final small = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final payer = payerName?.trim() ?? '';
    final line2Text = [
      if (payer.isNotEmpty) payer,
      if (caption?.isNotEmpty ?? false) caption!,
      if (summary?.isNotEmpty ?? false) summary!,
    ].join(' · ');
    final hasLine2 = line2Text.isNotEmpty || linked;

    // The tags take what they need, up to [tagsMaxShare] of the line; the
    // title ellipsises in the rest. More tags than fit clip at the edge.
    final line1 = LayoutBuilder(
      builder: (context, box) => Row(
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyLarge,
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: box.maxWidth * tagsMaxShare,
              ),
              child: UnconstrainedBox(
                alignment: Alignment.centerLeft,
                constrainedAxis: Axis.vertical,
                clipBehavior: Clip.hardEdge,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < tags.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.xs),
                      _tag(context, i),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final line2 = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          if (payer.isNotEmpty) ...[
            PersonMark(
              name: payer,
              level: payerLevel,
              iconCode: payerIconCode,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          if (line2Text.isNotEmpty)
            Flexible(
              child: Text(
                line2Text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: small,
              ),
            ),
          if (linked) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(AppIcons.link, size: 14, color: scheme.onSurfaceVariant),
          ],
        ],
      ),
    );

    Widget row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SelectCheck(
              value: marked,
              onTap: locked ? null : onTickTap,
              tooltip: tickTooltip,
            ),
            const SizedBox(width: AppSpacing.sm),
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [line1, if (hasLine2) line2],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            MoneyText(
              amount,
              tone: tone,
              symbol: symbol,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
    if (locked) row = IgnorePointer(child: row);
    if (locked || marked) row = Opacity(opacity: _fadedOpacity, child: row);
    row = _Flash(on: highlighted, child: row);
    if (children.isEmpty) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [row, ...children],
    );
  }
}

/// [EventBillRow.highlighted]: a primary tint behind [child] that holds a
/// moment, then fades out — replayed each time [on] turns true. Instant
/// (nothing) under reduced motion.
class _Flash extends StatefulWidget {
  const _Flash({required this.on, required this.child});

  final bool on;
  final Widget child;

  static const duration = Duration(milliseconds: 1600);

  @override
  State<_Flash> createState() => _FlashState();
}

class _FlashState extends State<_Flash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _Flash.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.on) _play();
  }

  @override
  void didUpdateWidget(_Flash old) {
    super.didUpdateWidget(old);
    if (widget.on && !old.on) _play();
  }

  void _play() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
        return;
      }
      _c.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Holds for the first third, then fades.
        final t = _c.value;
        final alpha = !_c.isAnimating
            ? 0.0
            : t < 0.33
            ? 0.16
            : 0.16 * (1 - (t - 0.33) / 0.67);
        return DecoratedBox(
          decoration: BoxDecoration(color: tint.withValues(alpha: alpha)),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// One split line under an [EventBillRow], indented:
///
///     [☐] (p) name  ติด ฿120                                  ฿120
///
/// Its own resolve tick ([marked], [onTickTap] null = inert); the row fades
/// when marked. [caption] is a muted note after the name (what they owe).
/// [locked]: inert and faded, like the bill row.
class EventBillChildRow extends StatelessWidget {
  const EventBillChildRow({
    required this.name,
    required this.amount,
    this.level = PersonLevel.name,
    this.iconCode,
    this.caption,
    this.tone = MoneyTone.plain,
    this.symbol = '฿',
    this.marked = false,
    this.onTickTap,
    this.tickTooltip,
    this.locked = false,
    this.onTap,
    super.key,
  });

  /// How far the line sits right of its bill row's content.
  static const double indent = AppSpacing.xxl;

  final String name;
  final num amount;
  final PersonLevel level;
  final IconCode? iconCode;
  final String? caption;
  final MoneyTone tone;
  final String symbol;
  final bool marked;
  final VoidCallback? onTickTap;
  final String? tickTooltip;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    Widget row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg + indent,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            SelectCheck(
              value: marked,
              onTap: locked ? null : onTickTap,
              tooltip: tickTooltip,
            ),
            const SizedBox(width: AppSpacing.sm),
            PersonMark(
              name: name,
              level: level,
              iconCode: iconCode,
              reserveLinkSlot: true,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: name),
                    if (caption?.isNotEmpty ?? false)
                      TextSpan(
                        text: '  ${caption!}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            MoneyText(
              amount,
              tone: tone,
              symbol: symbol,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
    if (locked) row = IgnorePointer(child: row);
    if (locked || marked) row = Opacity(opacity: _fadedOpacity, child: row);
    return row;
  }
}
