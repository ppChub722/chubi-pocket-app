import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../atoms/ui_config.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/preferences/presentation/cubit/money_visibility_cubit.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'money_style.dart';

/// How a [MoneyText] colours and signs its amount.
enum MoneyTone {
  /// Plain onSurface, no sign.
  plain,

  /// Income: its colour and mark follow the user's [MoneyStyle] (+฿1,000 /
  /// ฿1,000, green or not).
  income,

  /// Expense: −฿540 / (฿540) / ฿540, red or not ([MoneyStyle]).
  expense,

  /// Income or expense from the amount itself (>0 income, <0 expense, 0
  /// plain).
  signed,
}

/// Formatted money amount — the only way amounts should hit the screen.
///
/// - Formats via [CurrencyFormatter] (฿, thousands separators, 2 decimals).
/// - Colours via the theme's income / expense palette.
/// - Respects the app-wide privacy toggle ([MoneyVisibilityCubit]): when
///   hidden, renders `฿••••` (set [hideable] false for amounts that must
///   always show, e.g. inside a form the user is typing into).
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    this.tone = MoneyTone.plain,
    this.style,
    this.symbol,
    this.hideable = true,
    this.textAlign,
    super.key,
  });

  final num amount;
  final MoneyTone tone;
  final TextStyle? style;

  /// Null = the user's currency symbol from `UiConfig` (set from /me).
  final String? symbol;
  final bool hideable;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final symbol = this.symbol ?? UiConfig.stringsOf(context).currencySymbol;
    final hidden = hideable && isMoneyHidden(context);
    final palette = Theme.of(context).extension<AppColors>()!;
    final money = MoneyStyleScope.of(context);
    // negative: null = no mark (plain, or something that shows as ฿0.00).
    final (Color? tint, bool? negative) = switch (tone) {
      MoneyTone.plain => (null, null),
      MoneyTone.income => (palette.income, false),
      MoneyTone.expense => (palette.expense, true),
      MoneyTone.signed =>
        CurrencyFormatter.roundsToZero(amount)
            ? (null, null)
            : amount > 0
            ? (palette.income, false)
            : (palette.expense, true),
    };
    final color = money.colored ? tint : null;
    final magnitude = tone == MoneyTone.plain ? amount : amount.abs();
    final formatted = CurrencyFormatter.format(magnitude, symbol: symbol);
    final text = hidden
        ? '$symbol••••'
        : negative == null
        ? formatted
        : money.apply(formatted, negative: negative);
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text(
      text,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: base.copyWith(
        color: color ?? base.color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// An income / expense amount as text for captions ("เดือนนี้ +฿2,000"),
/// marked the user's way ([MoneyStyle]; no colour in a sentence).
String signedMoneyString(
  BuildContext context,
  num amount, {
  required bool negative,
  String? symbol,
}) => MoneyStyleScope.of(
  context,
).apply(_moneyString(context, amount.abs(), symbol), negative: negative);

/// An amount as plain text for captions / sentences ("คืนแล้ว ฿300 จาก
/// ฿500") — honours the 👁 privacy toggle like [MoneyText].
String moneyString(BuildContext context, num amount, {String? symbol}) =>
    _moneyString(context, amount, symbol);

String _moneyString(BuildContext context, num amount, String? symbolOrNull) {
  final symbol = symbolOrNull ?? UiConfig.stringsOf(context).currencySymbol;
  return isMoneyHidden(context)
      ? '$symbol••••'
      : CurrencyFormatter.format(amount, symbol: symbol);
}

/// Whether the 👁 money-privacy toggle is offered at all. Off for now
/// (owner 2026-10-10: show the numbers, always — a new way to turn it on
/// comes later), so every toggle renders nothing and amounts never hide.
/// The cubit / stored setting stay, untouched, for when it's back.
const bool kMoneyPrivacyEnabled = false;

/// True when the privacy toggle is on. Safe when no
/// [MoneyVisibilityCubit] is provided (tests, dev previews) → visible.
///
/// `watch`, not `select`: page helpers pass the State's context while a
/// nested Builder is the one building, and `select` asserts on that. The
/// state is a single bool, so `watch` rebuilds just as rarely.
bool isMoneyHidden(BuildContext context) {
  if (!kMoneyPrivacyEnabled) return false;
  try {
    return context.watch<MoneyVisibilityCubit>().state;
  } on ProviderNotFoundException {
    return false;
  }
}

/// 👁 toggle that flips the app-wide money privacy setting. Renders
/// nothing while [kMoneyPrivacyEnabled] is off.
class MoneyVisibilityToggle extends StatelessWidget {
  const MoneyVisibilityToggle({this.size = 20, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    if (!kMoneyPrivacyEnabled) return const SizedBox.shrink();
    final hidden = isMoneyHidden(context);
    final l = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: hidden ? l.commonShowAmounts : l.commonHideAmounts,
      iconSize: size,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        hidden ? AppIcons.hidden : AppIcons.visible,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onPressed: () => context.read<MoneyVisibilityCubit>().toggle(),
    );
  }
}
