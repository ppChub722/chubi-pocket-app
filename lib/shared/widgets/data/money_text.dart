import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/preferences/presentation/cubit/money_visibility_cubit.dart';
import '../../../l10n/gen/app_localizations.dart';

/// How a [MoneyText] colours and signs its amount.
enum MoneyTone {
  /// Plain onSurface, no sign.
  plain,

  /// Always income colour, `+` prefix.
  income,

  /// Always expense colour, `−` prefix.
  expense,

  /// Colour + sign from the amount itself (>0 income, <0 expense, 0 plain).
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
    this.symbol = '฿',
    this.hideable = true,
    this.textAlign,
    super.key,
  });

  final num amount;
  final MoneyTone tone;
  final TextStyle? style;
  final String symbol;
  final bool hideable;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final hidden = hideable && isMoneyHidden(context);
    final palette = Theme.of(context).extension<AppColors>()!;
    final (Color? color, String sign) = switch (tone) {
      MoneyTone.plain => (null, ''),
      MoneyTone.income => (palette.income, '+'),
      MoneyTone.expense => (palette.expense, '−'),
      MoneyTone.signed =>
        amount > 0
            ? (palette.income, '+')
            : amount < 0
            ? (palette.expense, '−')
            : (null, ''),
    };
    final magnitude = tone == MoneyTone.plain ? amount : amount.abs();
    final text = hidden
        ? '$symbol••••'
        : '$sign${CurrencyFormatter.format(magnitude, symbol: symbol)}';
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

/// An amount as plain text for captions / sentences ("คืนแล้ว ฿300 จาก
/// ฿500") — honours the 👁 privacy toggle like [MoneyText].
String moneyString(BuildContext context, num amount, {String symbol = '฿'}) =>
    isMoneyHidden(context)
    ? '$symbol••••'
    : CurrencyFormatter.format(amount, symbol: symbol);

/// True when the privacy toggle is on. Safe when no
/// [MoneyVisibilityCubit] is provided (tests, dev previews) → visible.
///
/// `watch`, not `select`: page helpers pass the State's context while a
/// nested Builder is the one building, and `select` asserts on that. The
/// state is a single bool, so `watch` rebuilds just as rarely.
bool isMoneyHidden(BuildContext context) {
  try {
    return context.watch<MoneyVisibilityCubit>().state;
  } on ProviderNotFoundException {
    return false;
  }
}

/// 👁 toggle that flips the app-wide money privacy setting.
class MoneyVisibilityToggle extends StatelessWidget {
  const MoneyVisibilityToggle({this.size = 20, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
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
