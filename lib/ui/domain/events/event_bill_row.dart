import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../atoms/app_divider.dart';
import '../../atoms/app_icon_button.dart';
import '../../atoms/select_check.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import '../icons/icon_code.dart';
import '../money/money_text.dart';
import '../people/person_mark.dart';
import 'event_tag_ref.dart';

typedef EventTagAnchorBuilder =
    Widget Function(
      BuildContext context,
      int index,
      Widget Function(VoidCallback? onTap) chip,
    );

const double _fadedOpacity = 0.55;

/// Bill rows show the person's avatar only: no 🔗 badge on a linked member.
PersonLevel _noBadge(PersonLevel level) =>
    level == PersonLevel.linked ? PersonLevel.contact : level;

/// My part not yet in my books: a light tint that stays (unlike the flash).
Color _mineTint(BuildContext context) =>
    Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);

/// What my books already hold of a bill, as ✓ mini chips in a row (✓ ลงหนี้
/// ✓ ลงรายการ): the badge of [EventBillRow] / [EventBillChildRow].
class EventBookedChips extends StatelessWidget {
  const EventBookedChips({required this.labels, super.key});

  final List<String> labels;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, t) in labels.indexed) ...[
        if (i > 0) const SizedBox(width: AppSpacing.xs),
        AppChip(
          label: t,
          icon: AppIcons.check,
          tone: AppChipTone.success,
          size: ChipSize.mini,
        ),
      ],
    ],
  );
}

/// The row's own button (⤓ ลงบัญชี): round, filled, a chip tall.
Widget _actionButton(
  BuildContext context,
  IconData icon,
  VoidCallback onTap,
  String? tooltip,
) => AppIconButton.filled(
  icon: icon,
  onPressed: onTap,
  tooltip: tooltip,
  size: ChipSize.chip.heightOf(context),
);

/// One payer of a multi-payer bill: the name and what they paid (already
/// formatted).
@immutable
class EventBillPayer {
  const EventBillPayer({
    required this.name,
    required this.amount,
    this.level = PersonLevel.name,
    this.iconCode,
  });

  final String name;
  final String amount;
  final PersonLevel level;
  final IconCode? iconCode;
}

class EventBillRow extends StatelessWidget {
  const EventBillRow({
    required this.title,
    required this.amount,
    this.tone = MoneyTone.signed,
    this.symbol,
    this.marked = false,
    this.onTickTap,
    this.tickTooltip,
    this.tick = true,
    this.leading,
    this.tags = const [],
    this.onTagTap,
    this.tagAnchorBuilder,
    this.payerName,
    this.payerVerb,
    this.payerLevel = PersonLevel.name,
    this.payerIconCode,
    this.payers = const [],
    this.caption,
    this.summary,
    this.badge,
    this.amountColor,
    this.linked = false,
    this.locked = false,
    this.onTap,
    this.children = const [],
    this.highlighted = false,
    this.mine = false,
    this.onAction,
    this.actionIcon = AppIcons.bookIn,
    this.actionTooltip,
    super.key,
  });

  /// My part (I paid) isn't in my books yet: the row keeps a light tint.
  final bool mine;

  /// A button at the end of the payer line (else of line 2): ⤓ ลงบัญชี.
  final VoidCallback? onAction;
  final IconData actionIcon;
  final String? actionTooltip;

  final String title;
  final num amount;
  final MoneyTone tone;
  final String? symbol;
  final bool marked;
  final VoidCallback? onTickTap;
  final String? tickTooltip;

  /// False: no tick box (the event book shows a [badge] instead).
  final bool tick;
  final Widget? leading;
  final List<EventTagRef> tags;
  final void Function(BuildContext chipContext, int index)? onTagTap;
  final EventTagAnchorBuilder? tagAnchorBuilder;
  final String? payerName;

  /// With it, line 2 reads "**[payerName]** [payerVerb]" (ฝน จ่าย).
  final String? payerVerb;
  final PersonLevel payerLevel;
  final IconCode? payerIconCode;

  /// A multi-payer bill (2+): the payer line reads "[payerVerb]: A ฿700 |
  /// B ฿500" (each with their mark) instead of one name.
  final List<EventBillPayer> payers;
  final String? caption;
  final String? summary;

  /// After line 2's text (a mini chip: "ยังไม่ลงบัญชี").
  final Widget? badge;

  /// Paints the amount (a payback's colour); null = [tone]'s.
  final Color? amountColor;
  final bool linked;
  final bool locked;
  final VoidCallback? onTap;
  final List<Widget> children;
  final bool highlighted;

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
    final verb = payerVerb;
    // "ฝน จ่าย" is its own line under the tags, sized like the bill's people.
    final multiPayer = verb != null && payers.length > 1;
    final payerLine = verb != null && (payer.isNotEmpty || multiPayer);
    final line2Text = [
      if (payer.isNotEmpty && verb == null) payer,
      if (caption?.isNotEmpty ?? false) caption!,
      if (summary?.isNotEmpty ?? false) summary!,
    ].join(' | ');
    final hasLine2 =
        line2Text.isNotEmpty ||
        (!payerLine &&
            (linked || badge != null || payer.isNotEmpty || onAction != null));
    final action = onAction == null
        ? null
        : _actionButton(context, actionIcon, onAction!, actionTooltip);

    final line1 = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.bodyLarge,
    );

    final tagLine = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < tags.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              _tag(context, i),
            ],
          ],
        ),
      ),
    );

    TextStyle? nameStyle(PersonLevel level) => level == PersonLevel.empty
        // An empty spot reads muted, not as a name.
        ? TextStyle(color: scheme.onSurfaceVariant)
        : const TextStyle(fontWeight: FontWeight.w600);
    final muted = TextStyle(color: scheme.onSurfaceVariant);
    final payerRow = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          if (!multiPayer) ...[
            PersonMark(
              name: payer,
              level: _noBadge(payerLevel),
              iconCode: payerIconCode,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text.rich(
              TextSpan(
                children: multiPayer
                    // "จ่าย: (ลี) ลี ฿700 | (ปอนด์) ปอนด์ ฿500".
                    ? [
                        TextSpan(text: '$verb: ', style: muted),
                        for (final (i, p) in payers.indexed) ...[
                          if (i > 0) TextSpan(text: ' | ', style: muted),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              child: PersonMark(
                                name: p.name,
                                level: _noBadge(p.level),
                                iconCode: p.iconCode,
                                size: 16,
                              ),
                            ),
                          ),
                          TextSpan(text: p.name, style: nameStyle(p.level)),
                          TextSpan(text: ' ${p.amount}', style: muted),
                        ],
                      ]
                    : [
                        TextSpan(text: payer, style: nameStyle(payerLevel)),
                        TextSpan(text: ' $verb', style: muted),
                      ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
          ),
          if (linked) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(AppIcons.link, size: 14, color: scheme.onSurfaceVariant),
          ],
          if (badge != null) ...[const SizedBox(width: AppSpacing.xs), badge!],
          if (action != null) ...[const Spacer(), action],
        ],
      ),
    );

    final line2 = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          if (payer.isNotEmpty && !payerLine) ...[
            PersonMark(
              name: payer,
              level: _noBadge(payerLevel),
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
          if (linked && !payerLine) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(AppIcons.link, size: 14, color: scheme.onSurfaceVariant),
          ],
          if (badge != null && !payerLine) ...[
            const SizedBox(width: AppSpacing.xs),
            badge!,
          ],
          if (action != null && !payerLine) ...[const Spacer(), action],
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
          crossAxisAlignment: payerLine || tags.isNotEmpty
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            if (tick) ...[
              SelectCheck(
                value: marked,
                onTap: locked ? null : onTickTap,
                tooltip: tickTooltip,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  line1,
                  if (tags.isNotEmpty) tagLine,
                  if (hasLine2) line2,
                  if (payerLine) payerRow,
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            MoneyText(
              amount,
              tone: amountColor == null ? tone : MoneyTone.plain,
              symbol: symbol,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
    if (mine) row = ColoredBox(color: _mineTint(context), child: row);
    if (locked) row = IgnorePointer(child: row);
    if (locked || marked) row = Opacity(opacity: _fadedOpacity, child: row);
    row = _Flash(on: highlighted, child: row);
    if (children.isEmpty) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      // The payer above, the rest of the bill below.
      children: [row, const AppDivider.row(), ...children],
    );
  }
}

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

class EventBillChildRow extends StatelessWidget {
  const EventBillChildRow({
    required this.name,
    required this.amount,
    this.level = PersonLevel.name,
    this.iconCode,
    this.caption,
    this.tone = MoneyTone.plain,
    this.symbol,
    this.marked = false,
    this.onTickTap,
    this.tickTooltip,
    this.tick = true,
    this.badge,
    this.locked = false,
    this.onTap,
    this.mine = false,
    this.onAction,
    this.actionIcon = AppIcons.bookIn,
    this.actionTooltip,
    super.key,
  });

  static const double indent = AppSpacing.xxl;

  /// My share isn't in my books yet: the row keeps a light tint.
  final bool mine;

  /// A button left of the amount: ⤓ ลงบัญชี.
  final VoidCallback? onAction;
  final IconData actionIcon;
  final String? actionTooltip;

  /// False: no tick box.
  final bool tick;

  /// After the name (a mini chip: "ยังไม่ลงบัญชี").
  final Widget? badge;

  final String name;
  final num amount;
  final PersonLevel level;
  final IconCode? iconCode;
  final String? caption;
  final MoneyTone tone;
  final String? symbol;
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
            if (tick) ...[
              SelectCheck(
                value: marked,
                onTap: locked ? null : onTickTap,
                tooltip: tickTooltip,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            PersonMark(name: name, level: _noBadge(level), iconCode: iconCode),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: badge != null
                  ? Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        badge!,
                      ],
                    )
                  : Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: name,
                            style: level == PersonLevel.empty
                                ? TextStyle(color: scheme.onSurfaceVariant)
                                : null,
                          ),
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
            if (onAction != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _actionButton(context, actionIcon, onAction!, actionTooltip),
            ],
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
    if (mine) row = ColoredBox(color: _mineTint(context), child: row);
    if (locked) row = IgnorePointer(child: row);
    if (locked || marked) row = Opacity(opacity: _fadedOpacity, child: row);
    return row;
  }
}
